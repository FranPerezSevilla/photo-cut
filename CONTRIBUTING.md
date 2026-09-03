# Contributing

Read [`AGENTS.md`](AGENTS.md) before making any change.

## Workflow

1. Select the next task with `python3 tool/project.py next`.
2. Create `task/<TASK_ID>-short-description`.
3. Keep the diff within that task's acceptance criteria.
4. Run `python3 tool/project.py verify <TASK_ID>` plus relevant tests.
5. Update the task state only when justified.
6. Open a PR using the repository template.

The roadmap in `project/plan.json` replaces an external project board. GitHub
issues may discuss bugs or ideas, but they are not implementation state.

## Design changes

Create an ADR in `project/decisions/` when changing any of these:

- framework or state-management strategy;
- data ownership or privacy model;
- PDF geometry conventions;
- monetisation model;
- supported platforms or OS minimums;
- backend/no-backend boundary;
- a major third-party dependency.
