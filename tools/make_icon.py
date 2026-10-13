"""Render the Drift app icon (1024x1024 PNG) with only the standard library."""
import math, struct, sys, zlib

N = 1024
C = [  # corner colors: TL, TR, BL, BR
    (22, 18, 64), (24, 150, 160), (122, 70, 210), (250, 168, 128)
]

def lerp(a, b, t):
    return a + (b - a) * t

def wave_alpha(x, y):
    a = 0.0
    for i, (amp, off, width, op) in enumerate([(38, 430, 15, 0.95), (30, 520, 11, 0.7), (24, 600, 8, 0.45)]):
        cy = off + amp * math.sin(x / N * 2 * math.pi * 1.15 + i * 0.9)
        # derivative to get approx perpendicular distance
        d = 2 * math.pi * 1.15 / N * amp * math.cos(x / N * 2 * math.pi * 1.15 + i * 0.9)
        dist = abs(y - cy) / math.sqrt(1 + d * d)
        edge = max(0.0, min(1.0, width / 2 + 0.75 - dist))
        fade = min(1.0, min(x - 150, 874 - x) / 80) if 150 < x < 874 else 0.0
        a = max(a, edge * op * fade)
    return a

rows = []
for y in range(N):
    row = bytearray([0])
    v = y / (N - 1)
    for x in range(N):
        u = x / (N - 1)
        wu = u + 0.08 * math.sin(v * 3.1 + 0.5)
        wv = v + 0.08 * math.sin(u * 2.7 + 1.3)
        wu = min(1, max(0, wu)); wv = min(1, max(0, wv))
        px = []
        for k in range(3):
            top = lerp(C[0][k], C[1][k], wu)
            bot = lerp(C[2][k], C[3][k], wu)
            px.append(lerp(top, bot, wv))
        # soft glow
        g = math.exp(-((u - 0.3) ** 2 + (v - 0.25) ** 2) * 6) * 0.25
        px = [p + (255 - p) * g for p in px]
        a = wave_alpha(x, y)
        px = [p + (255 - p) * a for p in px]
        row += bytes(int(max(0, min(255, p))) for p in px)
    rows.append(bytes(row))

def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b"")
open(sys.argv[1], "wb").write(png)
