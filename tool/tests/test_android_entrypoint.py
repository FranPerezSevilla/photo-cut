#!/usr/bin/env python3
"""Regression tests for the Android launcher activity package."""

from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUILD_FILE = ROOT / 'android/app/build.gradle.kts'
MANIFEST_FILE = ROOT / 'android/app/src/main/AndroidManifest.xml'
KOTLIN_ROOT = ROOT / 'android/app/src/main/kotlin'


class AndroidEntrypointTest(unittest.TestCase):
    def test_launcher_activity_matches_android_namespace(self) -> None:
        build = BUILD_FILE.read_text(encoding='utf-8')
        namespace_match = re.search(r'namespace\s*=\s*"([^"]+)"', build)
        application_id_match = re.search(r'applicationId\s*=\s*"([^"]+)"', build)

        self.assertIsNotNone(namespace_match)
        self.assertIsNotNone(application_id_match)
        namespace = namespace_match.group(1)
        application_id = application_id_match.group(1)
        self.assertEqual(namespace, application_id)

        manifest = MANIFEST_FILE.read_text(encoding='utf-8')
        self.assertIn('android:name=".MainActivity"', manifest)

        expected_activity = KOTLIN_ROOT.joinpath(*namespace.split('.')) / 'MainActivity.kt'
        self.assertTrue(
            expected_activity.exists(),
            f'Expected launcher activity at {expected_activity.relative_to(ROOT)}',
        )
        activity = expected_activity.read_text(encoding='utf-8')
        self.assertRegex(activity, rf'(?m)^\s*package\s+{re.escape(namespace)}\s*$')

        all_activities = sorted(KOTLIN_ROOT.rglob('MainActivity.kt'))
        self.assertEqual(all_activities, [expected_activity])


if __name__ == '__main__':
    unittest.main()
