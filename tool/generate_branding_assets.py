#!/usr/bin/env python3
"""Generate deterministic Photo Cut launcher icons using only the Python stdlib."""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _png_bytes(size: int) -> bytes:
    width = height = size
    pixels = bytearray(width * height * 4)

    def put(x: int, y: int, rgba: tuple[int, int, int, int]) -> None:
        if 0 <= x < width and 0 <= y < height:
            i = (y * width + x) * 4
            pixels[i : i + 4] = bytes(rgba)

    def blend(x: int, y: int, rgba: tuple[int, int, int, int]) -> None:
        if not (0 <= x < width and 0 <= y < height):
            return
        i = (y * width + x) * 4
        a = rgba[3] / 255.0
        inv = 1.0 - a
        pixels[i] = int(rgba[0] * a + pixels[i] * inv)
        pixels[i + 1] = int(rgba[1] * a + pixels[i + 1] * inv)
        pixels[i + 2] = int(rgba[2] * a + pixels[i + 2] * inv)
        pixels[i + 3] = 255

    # Premium navy -> electric blue diagonal background.
    for y in range(height):
        for x in range(width):
            t = min(1.0, max(0.0, (x + y) / (2 * max(1, size - 1))))
            r = int(7 + (18 - 7) * t)
            g = int(27 + (92 - 27) * t)
            b = int(74 + (255 - 74) * t)
            put(x, y, (r, g, b, 255))

    # Subtle cyan glow toward top-right.
    cx, cy = size * 0.78, size * 0.18
    glow_radius = size * 0.7
    for y in range(height):
        for x in range(width):
            d = math.hypot(x - cx, y - cy)
            if d < glow_radius:
                alpha = int(50 * (1.0 - d / glow_radius) ** 2)
                blend(x, y, (36, 215, 244, alpha))

    def fill_round_rect(x0: int, y0: int, x1: int, y1: int, radius: int, color: tuple[int, int, int, int]) -> None:
        for yy in range(y0, y1):
            for xx in range(x0, x1):
                dx = max(x0 + radius - xx, 0, xx - (x1 - radius - 1))
                dy = max(y0 + radius - yy, 0, yy - (y1 - radius - 1))
                if dx * dx + dy * dy <= radius * radius:
                    put(xx, yy, color)

    # Photo frame.
    p0, p1 = int(size * 0.25), int(size * 0.75)
    frame_r = max(2, int(size * 0.07))
    fill_round_rect(p0, p0, p1, p1, frame_r, (244, 251, 255, 255))
    inset = max(2, int(size * 0.035))
    i0, i1 = p0 + inset, p1 - inset
    fill_round_rect(i0, i0, i1, i1, max(1, int(size * 0.04)), (62, 154, 235, 255))

    # Mountains.
    def triangle(ax: float, ay: float, bx: float, by: float, cx_: float, cy_: float, color: tuple[int, int, int, int]) -> None:
        min_x, max_x = int(min(ax, bx, cx_)), int(max(ax, bx, cx_))
        min_y, max_y = int(min(ay, by, cy_)), int(max(ay, by, cy_))
        denom = (by - cy_) * (ax - cx_) + (cx_ - bx) * (ay - cy_)
        if denom == 0:
            return
        for yy in range(min_y, max_y + 1):
            for xx in range(min_x, max_x + 1):
                w1 = ((by - cy_) * (xx - cx_) + (cx_ - bx) * (yy - cy_)) / denom
                w2 = ((cy_ - ay) * (xx - cx_) + (ax - cx_) * (yy - cy_)) / denom
                w3 = 1 - w1 - w2
                if w1 >= 0 and w2 >= 0 and w3 >= 0:
                    put(xx, yy, color)

    triangle(i0, i1, i0 + (i1 - i0) * 0.46, i0 + (i1 - i0) * 0.40, i0 + (i1 - i0) * 0.83, i1, (6, 52, 143, 255))
    triangle(i0 + (i1 - i0) * 0.38, i1, i0 + (i1 - i0) * 0.70, i0 + (i1 - i0) * 0.52, i1, i1, (42, 119, 218, 255))

    # Sun.
    sx, sy, sr = int(i0 + (i1 - i0) * 0.76), int(i0 + (i1 - i0) * 0.24), max(1, int(size * 0.055))
    for yy in range(sy - sr, sy + sr + 1):
        for xx in range(sx - sr, sx + sr + 1):
            if (xx - sx) ** 2 + (yy - sy) ** 2 <= sr * sr:
                put(xx, yy, (248, 253, 255, 255))

    # Crop brackets + midpoint ticks.
    line = max(2, int(size * 0.055))
    lo, hi, arm = int(size * 0.14), int(size * 0.86), int(size * 0.14)

    def rect(x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int, int]) -> None:
        for yy in range(max(0, y0), min(height, y1)):
            for xx in range(max(0, x0), min(width, x1)):
                put(xx, yy, color)

    crop = (183, 244, 255, 255)
    cyan = (36, 215, 244, 255)
    # top-left / top-right / bottom-left / bottom-right Ls
    rect(lo, lo, lo + arm, lo + line, crop); rect(lo, lo, lo + line, lo + arm, crop)
    rect(hi - arm, lo, hi, lo + line, crop); rect(hi - line, lo, hi, lo + arm, crop)
    rect(lo, hi - line, lo + arm, hi, crop); rect(lo, hi - arm, lo + line, hi, crop)
    rect(hi - arm, hi - line, hi, hi, crop); rect(hi - line, hi - arm, hi, hi, crop)
    mid = size // 2
    tick = max(2, int(size * 0.025))
    rect(mid - tick // 2, int(size * 0.095), mid + tick // 2 + 1, int(size * 0.19), cyan)
    rect(mid - tick // 2, int(size * 0.81), mid + tick // 2 + 1, int(size * 0.905), cyan)
    rect(int(size * 0.095), mid - tick // 2, int(size * 0.19), mid + tick // 2 + 1, cyan)
    rect(int(size * 0.81), mid - tick // 2, int(size * 0.905), mid + tick // 2 + 1, cyan)

    # Encode RGBA PNG.
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        start = y * width * 4
        raw.extend(pixels[start : start + width * 4])

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload) & 0xFFFFFFFF)

    return (
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
        + chunk(b'IDAT', zlib.compress(bytes(raw), 9))
        + chunk(b'IEND', b'')
    )


def _write(path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(_png_bytes(size))


def generate() -> None:
    android = {
        'mipmap-mdpi/ic_launcher.png': 48,
        'mipmap-hdpi/ic_launcher.png': 72,
        'mipmap-xhdpi/ic_launcher.png': 96,
        'mipmap-xxhdpi/ic_launcher.png': 144,
        'mipmap-xxxhdpi/ic_launcher.png': 192,
    }
    for relative, size in android.items():
        _write(ROOT / 'android/app/src/main/res' / relative, size)

    ios = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }
    icon_root = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for name, size in ios.items():
        _write(icon_root / name, size)


if __name__ == '__main__':
    generate()
    print('Photo Cut branding assets generated.')
