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

    def test_next_reports_no_ready_agent_task(self) -> None:
        result = self.run_cli('next', '--json')
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn('No ready agent task.', result.stdout)

    def test_status_mentions_current_milestone(self) -> None:
        result = self.run_cli('status')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('M4 — Lifetime purchase', result.stdout)
        self.assertIn('M4-H01', result.stdout)

    def test_unknown_task_fails_cleanly(self) -> None:
        result = self.run_cli('show', 'M99-T99')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Unknown task', result.stderr)


if __name__ == '__main__':
    unittest.main()
