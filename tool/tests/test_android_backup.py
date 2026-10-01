#!/usr/bin/env python3
"""Regression tests for scoped Android backup of Photo Cut free-use state."""

from __future__ import annotations

import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'android/app/src/main/AndroidManifest.xml'
BACKUP_RULES = ROOT / 'android/app/src/main/res/xml/backup_rules.xml'
DATA_EXTRACTION_RULES = (
    ROOT / 'android/app/src/main/res/xml/data_extraction_rules.xml'
)
MAIN_ACTIVITY = (
    ROOT
    / 'android/app/src/main/kotlin/com/frainzzel/photocut/MainActivity.kt'
)

ANDROID_NS = '{http://schemas.android.com/apk/res/android}'


class AndroidBackupTest(unittest.TestCase):
    def test_manifest_enables_scoped_backup_rules(self) -> None:
        root = ET.parse(MANIFEST).getroot()
        application = root.find('application')
        self.assertIsNotNone(application)

        assert application is not None
        self.assertEqual(application.get(f'{ANDROID_NS}allowBackup'), 'true')
        self.assertEqual(
            application.get(f'{ANDROID_NS}fullBackupContent'),
            '@xml/backup_rules',
        )
        self.assertEqual(
            application.get(f'{ANDROID_NS}dataExtractionRules'),
            '@xml/data_extraction_rules',
        )

    def test_legacy_backup_includes_only_dedicated_free_use_preferences(self) -> None:
        root = ET.parse(BACKUP_RULES).getroot()
        includes = [
            (node.get('domain'), node.get('path'))
            for node in root.findall('include')
        ]
        self.assertEqual(
            includes,
            [('sharedpref', 'photo_cut_free_use.xml')],
        )

    def test_android_12_backup_and_transfer_include_only_free_use_preferences(self) -> None:
        root = ET.parse(DATA_EXTRACTION_RULES).getroot()
        for section_name in ('cloud-backup', 'device-transfer'):
            section = root.find(section_name)
            self.assertIsNotNone(section)
            assert section is not None
            includes = [
                (node.get('domain'), node.get('path'))
                for node in section.findall('include')
            ]
            self.assertEqual(
                includes,
                [('sharedpref', 'photo_cut_free_use.xml')],
            )

    def test_lifetime_cache_is_not_in_backup_rules(self) -> None:
        combined = (
            BACKUP_RULES.read_text(encoding='utf-8')
            + DATA_EXTRACTION_RULES.read_text(encoding='utf-8')
        )
        self.assertNotIn('photo_cut_entitlement', combined)
        self.assertNotIn('lifetime_unlocked', combined)

    def test_main_activity_splits_and_migrates_free_use_state(self) -> None:
        activity = MAIN_ACTIVITY.read_text(encoding='utf-8')

        self.assertIn(
            'FREE_USE_PREFS_NAME = "photo_cut_free_use"',
            activity,
        )
        self.assertIn(
            'ENTITLEMENT_PREFS_NAME = "photo_cut_entitlement"',
            activity,
        )
        self.assertIn('readAndMigrateFreeUse(', activity)
        self.assertIn(
            '.remove(FREE_FINAL_PDF_CONSUMED)',
            activity,
        )
        self.assertIn(
            '.putBoolean(LIFETIME_UNLOCKED, lifetimeUnlocked)',
            activity,
        )


if __name__ == '__main__':
    unittest.main()
