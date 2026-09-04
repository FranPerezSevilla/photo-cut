#!/usr/bin/env python3
"""Normalise generated Flutter platform files to repository product settings."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID_ID = 'com.frainzzel.photocut'
IOS_ID = 'com.frainzzel.photocut'
IOS_TARGET = '15.0'
ANDROID_MIN_SDK = '24'
DISPLAY_NAME = 'Photo Cut'
ANDROID_KOTLIN_ROOT = ROOT / 'android/app/src/main/kotlin'
ANDROID_MAIN_ACTIVITY = (
    ANDROID_KOTLIN_ROOT.joinpath(*ANDROID_ID.split('.')) / 'MainActivity.kt'
)


def replace_file(path: Path, transforms: list[tuple[str, str, int]]) -> bool:
    if not path.exists():
        return False

    original = path.read_text(encoding='utf-8')
    updated = original
    for pattern, replacement, flags in transforms:
        updated = re.sub(pattern, replacement, updated, flags=flags)

    if updated != original:
        path.write_text(updated, encoding='utf-8')
        return True
    return False


def _remove_empty_parents(path: Path, *, stop: Path) -> None:
    current = path
    while current != stop and current.is_relative_to(stop):
        try:
            current.rmdir()
        except OSError:
            return
        current = current.parent


def normalise_android_entry_point() -> None:
    if not ANDROID_KOTLIN_ROOT.exists():
        return

    candidates = sorted(ANDROID_KOTLIN_ROOT.rglob('MainActivity.kt'))
    source: Path | None
    if ANDROID_MAIN_ACTIVITY in candidates:
        source = ANDROID_MAIN_ACTIVITY
    elif len(candidates) == 1:
        source = candidates[0]
    else:
        source = None

    if source is None:
        return

    original_parent = source.parent
    content = source.read_text(encoding='utf-8')
    content = re.sub(
        r'^\s*package\s+[^\s]+\s*$',
        f'package {ANDROID_ID}',
        content,
        count=1,
        flags=re.MULTILINE,
    )

    ANDROID_MAIN_ACTIVITY.parent.mkdir(parents=True, exist_ok=True)
    ANDROID_MAIN_ACTIVITY.write_text(content, encoding='utf-8')

    for candidate in candidates:
        if candidate != ANDROID_MAIN_ACTIVITY and candidate.exists():
            candidate.unlink()
            _remove_empty_parents(candidate.parent, stop=ANDROID_KOTLIN_ROOT)

    if original_parent != ANDROID_MAIN_ACTIVITY.parent:
        _remove_empty_parents(original_parent, stop=ANDROID_KOTLIN_ROOT)


def expected_problems() -> list[str]:
    problems: list[str] = []

    android_build = ROOT / 'android/app/build.gradle.kts'
    if not android_build.exists():
        problems.append('android/app/build.gradle.kts is missing')
    else:
        content = android_build.read_text(encoding='utf-8')
        if f'namespace = "{ANDROID_ID}"' not in content:
            problems.append(f'Android namespace is not {ANDROID_ID}')
        if f'applicationId = "{ANDROID_ID}"' not in content:
            problems.append(f'Android applicationId is not {ANDROID_ID}')
        if f'minSdk = {ANDROID_MIN_SDK}' not in content:
            problems.append(f'Android minSdk is not {ANDROID_MIN_SDK}')

    manifest = ROOT / 'android/app/src/main/AndroidManifest.xml'
    if not manifest.exists():
        problems.append('AndroidManifest.xml is missing')
    elif f'android:label="{DISPLAY_NAME}"' not in manifest.read_text(encoding='utf-8'):
        problems.append(f'Android display label is not {DISPLAY_NAME}')

    activities = (
        sorted(ANDROID_KOTLIN_ROOT.rglob('MainActivity.kt'))
        if ANDROID_KOTLIN_ROOT.exists()
        else []
    )
    if not ANDROID_MAIN_ACTIVITY.exists():
        problems.append(
            'Android MainActivity path does not match the namespace: '
            f'{ANDROID_MAIN_ACTIVITY.relative_to(ROOT)}'
        )
    else:
        activity_content = ANDROID_MAIN_ACTIVITY.read_text(encoding='utf-8')
        if not re.search(
            rf'^\s*package\s+{re.escape(ANDROID_ID)}\s*$',
            activity_content,
            flags=re.MULTILINE,
        ):
            problems.append(f'Android MainActivity package is not {ANDROID_ID}')

    stale_activities = [path for path in activities if path != ANDROID_MAIN_ACTIVITY]
    if stale_activities:
        relative = ', '.join(str(path.relative_to(ROOT)) for path in stale_activities)
        problems.append(f'Unexpected duplicate Android MainActivity files: {relative}')

    pbxproj = ROOT / 'ios/Runner.xcodeproj/project.pbxproj'
    if not pbxproj.exists():
        problems.append('ios/Runner.xcodeproj/project.pbxproj is missing')
    else:
        content = pbxproj.read_text(encoding='utf-8')
        if f'PRODUCT_BUNDLE_IDENTIFIER = {IOS_ID};' not in content:
            problems.append(f'iOS bundle identifier is not {IOS_ID}')
        targets = set(re.findall(r'IPHONEOS_DEPLOYMENT_TARGET = ([^;]+);', content))
        if targets != {IOS_TARGET}:
            problems.append(
                f'iOS deployment targets are {sorted(targets)}, expected only {IOS_TARGET}'
            )

    info_plist = ROOT / 'ios/Runner/Info.plist'
    if not info_plist.exists():
        problems.append('ios/Runner/Info.plist is missing')
    else:
        content = info_plist.read_text(encoding='utf-8')
        pattern = (
            rf'<key>CFBundleDisplayName</key>\s*'
            rf'<string>{re.escape(DISPLAY_NAME)}</string>'
        )
        if not re.search(pattern, content):
            problems.append(f'iOS display name is not {DISPLAY_NAME}')

    if not (ROOT / '.metadata').exists():
        problems.append('.metadata is missing')

    return problems


def normalise() -> None:
    android_build = ROOT / 'android/app/build.gradle.kts'
    replace_file(
        android_build,
        [
            (r'namespace\s*=\s*"[^"]+"', f'namespace = "{ANDROID_ID}"', 0),
            (
                r'applicationId\s*=\s*"[^"]+"',
                f'applicationId = "{ANDROID_ID}"',
                0,
            ),
            (
                r'minSdk\s*=\s*(?:flutter\.minSdkVersion|\d+)',
                f'minSdk = {ANDROID_MIN_SDK}',
                0,
            ),
        ],
    )

    replace_file(
        ROOT / 'android/app/src/main/AndroidManifest.xml',
        [(r'android:label="[^"]+"', f'android:label="{DISPLAY_NAME}"', 0)],
    )
    normalise_android_entry_point()

    replace_file(
        ROOT / 'ios/Runner.xcodeproj/project.pbxproj',
        [
            (
                r'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;',
                f'PRODUCT_BUNDLE_IDENTIFIER = {IOS_ID};',
                0,
            ),
            (
                r'IPHONEOS_DEPLOYMENT_TARGET = [^;]+;',
                f'IPHONEOS_DEPLOYMENT_TARGET = {IOS_TARGET};',
                0,
            ),
        ],
    )

    replace_file(
        ROOT / 'ios/Runner/Info.plist',
        [
            (
                r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]+(</string>)',
                rf'\g<1>{DISPLAY_NAME}\g<2>',
                0,
            )
        ],
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--check',
        action='store_true',
        help='Only verify; do not modify files.',
    )
    args = parser.parse_args()

    if not args.check:
        normalise()

    problems = expected_problems()
    if problems:
        for problem in problems:
            print(f'ERROR: {problem}', file=sys.stderr)
        return 1

    print('Platform configuration is normalised.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
