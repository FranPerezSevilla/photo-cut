#!/usr/bin/env python3
"""Dependency-free CLI for Photo Cut's repository-owned implementation plan."""

from __future__ import annotations

import argparse
import json
import platform
import shutil
import subprocess
import sys
from collections import Counter
from datetime import date
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PLAN_PATH = ROOT / 'project/plan.json'
ALLOWED_STATUSES = {'backlog', 'ready', 'blocked', 'awaiting_human', 'done'}
ALLOWED_EXECUTORS = {'agent', 'human'}
ALLOWED_RUNNERS = {'any', 'linux', 'macos', 'windows'}
REQUIRED_FILES = [
    ROOT / 'AGENTS.md',
    ROOT / 'project/product.md',
    ROOT / 'project/architecture.md',
    PLAN_PATH,
    ROOT / 'pubspec.yaml',
]


class PlanError(RuntimeError):
    pass


def load_plan() -> dict[str, Any]:
    try:
        return json.loads(PLAN_PATH.read_text(encoding='utf-8'))
    except FileNotFoundError as error:
        raise PlanError(f'Missing plan: {PLAN_PATH}') from error
    except json.JSONDecodeError as error:
        raise PlanError(f'Invalid JSON in {PLAN_PATH}: {error}') from error


def save_plan(plan: dict[str, Any]) -> None:
    plan['updatedAt'] = date.today().isoformat()
    PLAN_PATH.write_text(
        json.dumps(plan, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )


def task_map(plan: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {task['id']: task for task in plan.get('tasks', [])}


def validate_plan(plan: dict[str, Any]) -> list[str]:
    errors: list[str] = []

    if plan.get('schemaVersion') != 1:
        errors.append('schemaVersion must be 1')
    if plan.get('project') != 'photo-cut':
        errors.append('project must be photo-cut')

    milestones = plan.get('milestones')
    tasks = plan.get('tasks')
    if not isinstance(milestones, list) or not milestones:
        errors.append('milestones must be a non-empty list')
        milestones = []
    if not isinstance(tasks, list) or not tasks:
        errors.append('tasks must be a non-empty list')
        tasks = []

    milestone_ids = [item.get('id') for item in milestones if isinstance(item, dict)]
    duplicate_milestones = sorted(key for key, count in Counter(milestone_ids).items() if count > 1)
    if duplicate_milestones:
        errors.append(f'duplicate milestone IDs: {duplicate_milestones}')
    if plan.get('currentMilestone') not in set(milestone_ids):
        errors.append('currentMilestone does not reference a known milestone')

    ids: list[str] = []
    for index, task in enumerate(tasks):
        prefix = f'tasks[{index}]'
        if not isinstance(task, dict):
            errors.append(f'{prefix} must be an object')
            continue
        task_id = task.get('id')
        if not isinstance(task_id, str) or not task_id:
            errors.append(f'{prefix}.id must be a non-empty string')
            continue
        ids.append(task_id)
        if task.get('milestone') not in set(milestone_ids):
            errors.append(f'{task_id}: unknown milestone {task.get("milestone")!r}')
        if task.get('status') not in ALLOWED_STATUSES:
            errors.append(f'{task_id}: invalid status {task.get("status")!r}')
        if task.get('executor') not in ALLOWED_EXECUTORS:
            errors.append(f'{task_id}: invalid executor {task.get("executor")!r}')
        if task.get('status') in {'blocked', 'awaiting_human'} and not task.get('statusReason'):
            errors.append(f'{task_id}: {task.get("status")} requires statusReason')
        for field in ('title', 'objective'):
            if not isinstance(task.get(field), str) or not task[field].strip():
                errors.append(f'{task_id}: {field} must be a non-empty string')
        acceptance = task.get('acceptance')
        if not isinstance(acceptance, list) or not acceptance or not all(isinstance(item, str) and item for item in acceptance):
            errors.append(f'{task_id}: acceptance must be a non-empty string list')
        dependencies = task.get('dependsOn')
        if not isinstance(dependencies, list) or not all(isinstance(item, str) for item in dependencies):
            errors.append(f'{task_id}: dependsOn must be a string list')
        checks = task.get('checks')
        if not isinstance(checks, list):
            errors.append(f'{task_id}: checks must be a list')
        else:
            for check_index, check in enumerate(checks):
                if not isinstance(check, dict):
                    errors.append(f'{task_id}: checks[{check_index}] must be an object')
                    continue
                if not isinstance(check.get('command'), str) or not check['command'].strip():
                    errors.append(f'{task_id}: checks[{check_index}].command is invalid')
                if check.get('runner') not in ALLOWED_RUNNERS:
                    errors.append(f'{task_id}: checks[{check_index}].runner is invalid')
        evidence = task.get('evidence')
        if not isinstance(evidence, list) or not all(isinstance(item, str) for item in evidence):
            errors.append(f'{task_id}: evidence must be a string list')

    duplicate_tasks = sorted(key for key, count in Counter(ids).items() if count > 1)
    if duplicate_tasks:
        errors.append(f'duplicate task IDs: {duplicate_tasks}')

    by_id = {task.get('id'): task for task in tasks if isinstance(task, dict) and isinstance(task.get('id'), str)}
    for task_id, task in by_id.items():
        dependencies = task.get('dependsOn', [])
        for dependency in dependencies:
            if dependency not in by_id:
                errors.append(f'{task_id}: unknown dependency {dependency}')
            if dependency == task_id:
                errors.append(f'{task_id}: cannot depend on itself')
        if task.get('status') in {'ready', 'done'}:
            undone = [dependency for dependency in dependencies if by_id.get(dependency, {}).get('status') != 'done']
            if undone:
                errors.append(f'{task_id}: status {task.get("status")} but dependencies are not done: {undone}')
        if task.get('executor') == 'agent' and task.get('status') == 'awaiting_human':
            errors.append(f'{task_id}: awaiting_human task must have executor human')

    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(task_id: str, path: list[str]) -> None:
        if task_id in visiting:
            errors.append(f'dependency cycle: {" -> ".join(path + [task_id])}')
            return
        if task_id in visited or task_id not in by_id:
            return
        visiting.add(task_id)
        for dependency in by_id[task_id].get('dependsOn', []):
            visit(dependency, path + [task_id])
        visiting.remove(task_id)
        visited.add(task_id)

    for task_id in by_id:
        visit(task_id, [])

    return errors


def require_valid_plan() -> dict[str, Any]:
    plan = load_plan()
    errors = validate_plan(plan)
    if errors:
        raise PlanError('\n'.join(f'- {error}' for error in errors))
    return plan


def current_runner() -> str:
    system = platform.system().lower()
    if system == 'darwin':
        return 'macos'
    if system == 'linux':
        return 'linux'
    if system == 'windows':
        return 'windows'
    return system


def dependencies_done(task: dict[str, Any], by_id: dict[str, dict[str, Any]]) -> bool:
    return all(by_id[dependency]['status'] == 'done' for dependency in task.get('dependsOn', []))


def next_tasks(plan: dict[str, Any]) -> list[dict[str, Any]]:
    by_id = task_map(plan)
    return [
        task
        for task in plan['tasks']
        if task['status'] == 'ready'
        and task['executor'] == 'agent'
        and dependencies_done(task, by_id)
    ]


def cmd_validate(_: argparse.Namespace) -> int:
    plan = load_plan()
    errors = validate_plan(plan)
    if errors:
        print('Plan is invalid:', file=sys.stderr)
        for error in errors:
            print(f'  - {error}', file=sys.stderr)
        return 1
    print(f'Plan is valid: {len(plan["milestones"])} milestones, {len(plan["tasks"])} tasks.')
    return 0


def cmd_doctor(args: argparse.Namespace) -> int:
    failures: list[str] = []
    warnings: list[str] = []

    for path in REQUIRED_FILES:
        if not path.exists():
            failures.append(f'missing {path.relative_to(ROOT)}')

    for command in ('git', 'python3'):
        if shutil.which(command) is None:
            failures.append(f'{command} is not available')

    flutter = shutil.which('flutter')
    dart = shutil.which('dart')
    if flutter is None:
        message = f'flutter is not available (expected {read_expected_flutter_version()})'
        (failures if args.strict else warnings).append(message)
    if dart is None:
        message = 'dart is not available (normally provided by Flutter)'
        (failures if args.strict else warnings).append(message)

    try:
        require_valid_plan()
    except PlanError as error:
        failures.append(f'plan validation failed: {error}')

    if flutter is not None:
        result = subprocess.run(
            [flutter, '--version', '--machine'],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            failures.append('flutter --version --machine failed')
        else:
            try:
                actual = json.loads(result.stdout).get('frameworkVersion')
                expected = read_expected_flutter_version()
                if actual != expected:
                    failures.append(f'Flutter version is {actual}, expected {expected}')
            except json.JSONDecodeError:
                failures.append('Flutter returned invalid version JSON')

    for warning in warnings:
        print(f'WARN: {warning}')
    for failure in failures:
        print(f'ERROR: {failure}', file=sys.stderr)

    if failures:
        return 1
    print('Repository doctor passed.')
    return 0


def read_expected_flutter_version() -> str:
    path = ROOT / '.flutter-version'
    return path.read_text(encoding='utf-8').strip() if path.exists() else 'unknown'


def cmd_status(_: argparse.Namespace) -> int:
    plan = require_valid_plan()
    counts = Counter(task['status'] for task in plan['tasks'])
    milestone = next(item for item in plan['milestones'] if item['id'] == plan['currentMilestone'])
    print(f'Project: {plan["project"]}')
    print(f'Current milestone: {milestone["id"]} — {milestone["title"]}')
    print('States: ' + ', '.join(f'{status}={counts.get(status, 0)}' for status in sorted(ALLOWED_STATUSES)))

    available = next_tasks(plan)
    if available:
        print('Ready agent tasks:')
        for task in available:
            print(f'  {task["id"]}: {task["title"]}')
    else:
        print('Ready agent tasks: none')

    human = [task for task in plan['tasks'] if task['status'] == 'awaiting_human']
    if human:
        print('Awaiting human:')
        for task in human:
            print(f'  {task["id"]}: {task["title"]}')
    return 0


def cmd_next(args: argparse.Namespace) -> int:
    plan = require_valid_plan()
    available = next_tasks(plan)
    if not available:
        print('No ready agent task.')
        return 2
    task = available[0]
    if args.json:
        print(json.dumps(task, ensure_ascii=False, indent=2))
    else:
        print(f'{task["id"]}: {task["title"]}')
        print(task['objective'])
        print(f'Open with: python3 tool/project.py show {task["id"]}')
    return 0


def get_task(plan: dict[str, Any], task_id: str) -> dict[str, Any]:
    try:
        return task_map(plan)[task_id]
    except KeyError as error:
        raise PlanError(f'Unknown task: {task_id}') from error


def cmd_show(args: argparse.Namespace) -> int:
    plan = require_valid_plan()
    task = get_task(plan, args.task_id)
    print(f'{task["id"]} — {task["title"]}')
    print(f'Status: {task["status"]} | Executor: {task["executor"]} | Milestone: {task["milestone"]}')
    if task.get('dependsOn'):
        print('Depends on: ' + ', '.join(task['dependsOn']))
    if task.get('statusReason'):
        print('Reason: ' + task['statusReason'])
    print('\nObjective\n---------')
    print(task['objective'])
    print('\nAcceptance\n----------')
    for item in task['acceptance']:
        print(f'- {item}')
    print('\nChecks\n------')
    if not task['checks']:
        print('- none (human evidence task)')
    for check in task['checks']:
        print(f'- [{check["runner"]}] {check["command"]}')
    print('\nEvidence\n--------')
    for item in task['evidence']:
        print(f'- {item}')
    return 0


def evidence_exists(pattern: str) -> bool:
    if any(character in pattern for character in '*?[]'):
        return any(ROOT.glob(pattern))
    return (ROOT / pattern).exists()


def verify_task(task: dict[str, Any]) -> tuple[bool, list[str]]:
    messages: list[str] = []
    runner = current_runner()
    applicable = [check for check in task['checks'] if check['runner'] in {'any', runner}]
    skipped = [check for check in task['checks'] if check['runner'] not in {'any', runner}]
    success = True

    if skipped:
        success = False
        for check in skipped:
            messages.append(f'SKIP [{check["runner"]}] {check["command"]}')

    for check in applicable:
        messages.append(f'RUN  [{check["runner"]}] {check["command"]}')
        result = subprocess.run(check['command'], cwd=ROOT, shell=True, check=False)
        if result.returncode != 0:
            success = False
            messages.append(f'FAIL exit={result.returncode}: {check["command"]}')
        else:
            messages.append(f'PASS {check["command"]}')

    missing_evidence = [item for item in task['evidence'] if not evidence_exists(item)]
    for item in missing_evidence:
        success = False
        messages.append(f'MISSING evidence: {item}')

    if not task['checks'] and task['executor'] == 'human':
        success = False
        messages.append('Human task cannot be completed by automated verification.')

    return success, messages


def cmd_verify(args: argparse.Namespace) -> int:
    plan = require_valid_plan()
    task = get_task(plan, args.task_id)
    by_id = task_map(plan)
    undone = [dependency for dependency in task['dependsOn'] if by_id[dependency]['status'] != 'done']
    if undone:
        print(f'Cannot verify; dependencies are not done: {undone}', file=sys.stderr)
        return 1

    success, messages = verify_task(task)
    for message in messages:
        print(message)
    if not success:
        print('Task verification is incomplete or failed.', file=sys.stderr)
        return 1
    print('Task verification passed on this runner.')
    return 0


def cmd_set_status(args: argparse.Namespace) -> int:
    plan = require_valid_plan()
    task = get_task(plan, args.task_id)
    by_id = task_map(plan)

    if args.status in {'blocked', 'awaiting_human'} and not args.reason:
        raise PlanError(f'{args.status} requires --reason')
    if args.status in {'ready', 'done'} and not dependencies_done(task, by_id):
        raise PlanError('all dependencies must be done before setting ready/done')
    if args.status == 'done':
        if task['executor'] == 'human':
            raise PlanError('human tasks must be completed by editing evidence and reviewed status change')
        success, messages = verify_task(task)
        for message in messages:
            print(message)
        if not success:
            raise PlanError('verification did not fully pass on this runner')

    task['status'] = args.status
    if args.reason:
        task['statusReason'] = args.reason
    else:
        task.pop('statusReason', None)
    save_plan(plan)
    print(f'{task["id"]} -> {args.status}')
    return 0


def render_status(plan: dict[str, Any]) -> str:
    by_milestone: dict[str, list[dict[str, Any]]] = {
        milestone['id']: [] for milestone in plan['milestones']
    }
    for task in plan['tasks']:
        by_milestone[task['milestone']].append(task)

    lines = [
        '# Photo Cut implementation status',
        '',
        f'Generated from `project/plan.json` on {date.today().isoformat()}.',
        '',
    ]
    for milestone in plan['milestones']:
        marker = ' ← current' if milestone['id'] == plan['currentMilestone'] else ''
        lines.extend([f'## {milestone["id"]} — {milestone["title"]}{marker}', '', milestone['goal'], ''])
        lines.append('| Task | State | Executor | Title |')
        lines.append('|---|---|---|---|')
        for task in by_milestone[milestone['id']]:
            lines.append(f'| `{task["id"]}` | `{task["status"]}` | `{task["executor"]}` | {task["title"]} |')
        lines.append('')
    return '\n'.join(lines) + '\n'


def cmd_render_status(args: argparse.Namespace) -> int:
    plan = require_valid_plan()
    rendered = render_status(plan)
    if args.stdout:
        print(rendered, end='')
    else:
        path = ROOT / 'STATUS.generated.md'
        path.write_text(rendered, encoding='utf-8')
        print(f'Wrote {path.relative_to(ROOT)}')
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest='command', required=True)

    validate = subparsers.add_parser('validate', help='Validate the canonical plan.')
    validate.set_defaults(function=cmd_validate)

    doctor = subparsers.add_parser('doctor', help='Check repository and tool prerequisites.')
    doctor.add_argument('--strict', action='store_true', help='Fail when Flutter/Dart are unavailable.')
    doctor.set_defaults(function=cmd_doctor)

    status = subparsers.add_parser('status', help='Show milestone and task-state summary.')
    status.set_defaults(function=cmd_status)

    next_command = subparsers.add_parser('next', help='Show the next ready agent task.')
    next_command.add_argument('--json', action='store_true')
    next_command.set_defaults(function=cmd_next)

    show = subparsers.add_parser('show', help='Show one task in full.')
    show.add_argument('task_id')
    show.set_defaults(function=cmd_show)

    verify = subparsers.add_parser('verify', help='Run applicable checks and verify evidence.')
    verify.add_argument('task_id')
    verify.set_defaults(function=cmd_verify)

    set_status = subparsers.add_parser('set-status', help='Safely update a task state.')
    set_status.add_argument('task_id')
    set_status.add_argument('status', choices=sorted(ALLOWED_STATUSES))
    set_status.add_argument('--reason')
    set_status.set_defaults(function=cmd_set_status)

    render = subparsers.add_parser('render-status', help='Render a human-readable plan snapshot.')
    render.add_argument('--stdout', action='store_true')
    render.set_defaults(function=cmd_render_status)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return int(args.function(args))
    except PlanError as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print('Interrupted.', file=sys.stderr)
        return 130


if __name__ == '__main__':
    raise SystemExit(main())
