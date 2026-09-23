#!/usr/bin/env python3
"""Generate Resources/AppIcon.icns for MiniBar."""
from __future__ import annotations

import os
import shutil
import struct
import subprocess
import tempfile
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT = os.path.join(ROOT, "Resources", "AppIcon.icns")


def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(
        ">I", zlib.crc32(tag + data) & 0xFFFFFFFF
    )


def write_png(path: str, size: int, pixels: list[tuple[int, int, int, int]]) -> None:
    raw = bytearray()
    for y in range(size):
        raw.append(0)
        row = y * size
        for x in range(size):
            raw.extend(pixels[row + x])
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", ihdr))
        handle.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        handle.write(chunk(b"IEND", b""))


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def draw_icon(size: int) -> list[tuple[int, int, int, int]]:
    pixels = [(0, 0, 0, 0)] * (size * size)
    radius = size * 0.22
    margin = size * 0.08
    bar_top = size * 0.22
    bar_bottom = size * 0.38
    item_left = size * 0.62
    item_right = size * 0.78
    item_pad = size * 0.035

    for y in range(size):
        for x in range(size):
            dx = min(x - margin, size - 1 - margin - x)
            dy = min(y - margin, size - 1 - margin - y)
            inside = True
            if dx < 0 or dy < 0:
                inside = False
            elif dx < radius and dy < radius:
                inside = (radius - dx) ** 2 + (radius - dy) ** 2 <= radius ** 2
            if not inside:
                continue

            if bar_top <= y <= bar_bottom:
                color = (245, 245, 247, 255)
                if item_left <= x <= item_right and (bar_top + item_pad) <= y <= (bar_bottom - item_pad):
                    color = (10, 132, 255, 255)
            else:
                t = y / size
                color = (
                    lerp(28, 44, t),
                    lerp(28, 44, t),
                    lerp(30, 48, t),
                    255,
                )
            pixels[y * size + x] = color
    return pixels


def main() -> None:
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    iconset = tempfile.mkdtemp(prefix="AppIcon.iconset.")
    try:
        renamed = iconset + ".iconset"
        os.rename(iconset, renamed)
        sizes = {
            "icon_16x16.png": 16,
            "icon_16x16@2x.png": 32,
            "icon_32x32.png": 32,
            "icon_32x32@2x.png": 64,
            "icon_128x128.png": 128,
            "icon_128x128@2x.png": 256,
            "icon_256x256.png": 256,
            "icon_256x256@2x.png": 512,
            "icon_512x512.png": 512,
            "icon_512x512@2x.png": 1024,
        }
        master = os.path.join(renamed, "_master.png")
        write_png(master, 1024, draw_icon(1024))
        for name, edge in sizes.items():
            dest = os.path.join(renamed, name)
            subprocess.check_call(
                ["sips", "-z", str(edge), str(edge), master, "--out", dest],
                stdout=subprocess.DEVNULL,
            )
        os.remove(master)
        subprocess.check_call(["iconutil", "-c", "icns", renamed, "-o", OUTPUT])
    finally:
        shutil.rmtree(renamed, ignore_errors=True)


if __name__ == "__main__":
    main()
