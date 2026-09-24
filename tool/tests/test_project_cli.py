from __future__ import annotations

import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CLI = ['python3', 'tool/project.py']


class ProjectCliTest(unittest.TestCase):
    def run_cli(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [*CLI, *arguments],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_plan_validates(self) -> None:
        result = self.run_cli('validate')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Plan is valid', result.stdout)

    def test_next_matches_canonical_ready_agent_state(self) -> None:
        plan = json.loads((ROOT / 'project' / 'plan.json').read_text())
        by_id = {task['id']: task for task in plan['tasks']}
        ready = [
            task
            for task in plan['tasks']
            if task['status'] == 'ready'
            and task['executor'] == 'agent'
            and all(by_id[dep]['status'] == 'done' for dep in task.get('dependsOn', []))
        ]

        result = self.run_cli('next', '--json')
        if not ready:
            self.assertEqual(result.returncode, 2, result.stderr)
            self.assertIn('No ready agent task.', result.stdout)
            return

        self.assertEqual(result.returncode, 0, result.stderr)
        selected = json.loads(result.stdout)
        self.assertEqual(selected['id'], ready[0]['id'])

    def test_status_mentions_current_milestone(self) -> None:
        result = self.run_cli('status')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('M4 — Lifetime purchase', result.stdout)
        self.assertIn('Ready agent tasks:', result.stdout)

    def test_unknown_task_fails_cleanly(self) -> None:
        result = self.run_cli('show', 'M99-T99')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Unknown task', result.stderr)


if __name__ == '__main__':
    unittest.main()
