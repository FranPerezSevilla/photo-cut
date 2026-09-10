from __future__ import annotations

import struct
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
        raise AssertionError(f'{path} is not a PNG with an IHDR header')
    return struct.unpack('>II', data[16:24])


class BrandingAssetsTest(unittest.TestCase):
    def test_android_launcher_density_sizes(self) -> None:
        expected = {
            'mipmap-mdpi/ic_launcher.png': 48,
            'mipmap-hdpi/ic_launcher.png': 72,
            'mipmap-xhdpi/ic_launcher.png': 96,
            'mipmap-xxhdpi/ic_launcher.png': 144,
            'mipmap-xxxhdpi/ic_launcher.png': 192,
        }
        root = ROOT / 'android/app/src/main/res'
        for relative, size in expected.items():
            with self.subTest(relative=relative):
                self.assertEqual(png_size(root / relative), (size, size))

    def test_ios_marketing_icon_is_1024_square(self) -> None:
        path = (
            ROOT
            / 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
        )
        self.assertEqual(png_size(path), (1024, 1024))


if __name__ == '__main__':
    unittest.main()
