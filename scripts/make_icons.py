#!/usr/bin/env python3
"""Generate LastWave AppIcon set (no third-party deps)."""
from __future__ import annotations

import math
import os
import struct
import zlib

ROOT = os.path.join(os.path.dirname(__file__), "..", "LastWave", "Assets.xcassets", "AppIcon.appiconset")
os.makedirs(ROOT, exist_ok=True)

SIZES = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]


def png(w: int, h: int, pixels: bytes) -> bytes:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = b""
    row = w * 4
    for y in range(h):
        raw += b"\x00" + pixels[y * row : (y + 1) * row]
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def icon(size: int) -> bytes:
    pix = bytearray(size * size * 4)
    cx = cy = size / 2.0
    for y in range(size):
        for x in range(size):
            nx = (x + 0.5) / size
            ny = (y + 0.5) / size
            # true-black field
            r, g, b = 8, 9, 12
            # radial silver glow
            d = math.hypot(nx - 0.5, ny - 0.42)
            glow = max(0.0, 1.0 - d * 1.7)
            r += int(40 * glow)
            g += int(48 * glow)
            b += int(58 * glow)
            # sine wave band
            wave = 0.58 + 0.08 * math.sin(nx * math.pi * 3.2)
            dist = abs(ny - wave)
            band = max(0.0, 1.0 - dist * size * 0.18)
            r = min(255, r + int(180 * band))
            g = min(255, g + int(190 * band))
            b = min(255, b + int(210 * band))
            # second quieter wave
            wave2 = 0.66 + 0.05 * math.sin(nx * math.pi * 2.4 + 0.8)
            dist2 = abs(ny - wave2)
            band2 = max(0.0, 1.0 - dist2 * size * 0.22) * 0.45
            r = min(255, r + int(90 * band2))
            g = min(255, g + int(100 * band2))
            b = min(255, b + int(120 * band2))
            i = (y * size + x) * 4
            pix[i : i + 4] = bytes((r, g, b, 255))
    _ = (cx, cy)
    return png(size, size, bytes(pix))


contents = {
    "images": [],
    "info": {"author": "xcode", "version": 1},
}

for s in SIZES:
    name = f"icon-{s}.png"
    with open(os.path.join(ROOT, name), "wb") as f:
        f.write(icon(s))
    contents["images"].append({"filename": name, "idiom": "universal", "platform": "ios", "size": f"{s}x{s}"})

# Xcode 14+ single 1024 is enough if we also provide the modern idiom
contents = {
    "images": [
        {"filename": "icon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
    ],
    "info": {"author": "xcode", "version": 1},
}
import json

with open(os.path.join(ROOT, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

# catalog root
cat = os.path.join(os.path.dirname(ROOT), "Contents.json")
with open(cat, "w") as f:
    json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)

print("icons written", ROOT)
