#!/usr/bin/env python3
"""
Generate ReadRise iOS app icon (1024×1024 PNG).
Design: ink (#1a1a2e) background, amber (#e8923a) open-book icon.
Matches the BookOpen brand mark used across the web app.

Usage:
    python3 scripts/make_icon.py
Output:
    ReadRise/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
"""
import struct, zlib, math, os

SIZE = 1024

# ── Palette ────────────────────────────────────────────────────────────────
INK   = (26,  26,  46,  255)   # #1a1a2e  sidebar / app bg
AMBER = (232, 146,  58,  255)  # #e8923a  primary accent
AMBER_DIM = (185, 108,  30, 255)  # slightly darker amber for text lines

def sc(v: float) -> int:
    """Scale a 1024-baseline value to SIZE."""
    return round(v * SIZE / 1024)

# ── PNG helpers ────────────────────────────────────────────────────────────

def png_chunk(tag: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', crc)

def make_png(buf: bytearray, size: int) -> bytes:
    ihdr = struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)
    rows = bytearray()
    stride = size * 4
    for y in range(size):
        rows += b'\x00'                      # filter: None
        rows += buf[y * stride:(y + 1) * stride]
    idat = zlib.compress(bytes(rows), 6)
    return (b'\x89PNG\r\n\x1a\n'
            + png_chunk(b'IHDR', ihdr)
            + png_chunk(b'IDAT', idat)
            + png_chunk(b'IEND', b''))

# ── Drawing helpers ─────────────────────────────────────────────────────────

def fill_hline(buf: bytearray, y: int, x1: int, x2: int, color):
    """Fill a horizontal run of pixels."""
    if y < 0 or y >= SIZE: return
    x1, x2 = max(0, x1), min(SIZE, x2)
    if x1 >= x2: return
    r, g, b, a = color
    seg = bytes([r, g, b, a]) * (x2 - x1)
    start = (y * SIZE + x1) * 4
    buf[start:start + len(seg)] = seg

def fill_rect(buf: bytearray, y1: int, y2: int, x1: int, x2: int, color):
    for y in range(max(0, y1), min(SIZE, y2)):
        fill_hline(buf, y, x1, x2, color)

def rounded_rect(buf: bytearray, y1: int, y2: int, x1: int, x2: int,
                 rad: int, color, bg_color=INK):
    """Filled rectangle with rounded corners."""
    fill_rect(buf, y1, y2, x1, x2, color)
    # Erase corners (restore bg)
    r, g, b, a = bg_color
    for dy in range(rad + 1):
        for dx in range(rad + 1):
            dist = math.hypot(dy - rad, dx - rad)
            if dist > rad:
                for cy, cx in [
                    (y1 + dy,     x1 + dx),
                    (y1 + dy,     x2 - dx - 1),
                    (y2 - dy - 1, x1 + dx),
                    (y2 - dy - 1, x2 - dx - 1),
                ]:
                    if 0 <= cy < SIZE and 0 <= cx < SIZE:
                        i = (cy * SIZE + cx) * 4
                        buf[i] = r; buf[i+1] = g; buf[i+2] = b; buf[i+3] = a

# ── Build the icon ──────────────────────────────────────────────────────────

def build_icon() -> bytearray:
    # Background: all ink
    r, g, b, a = INK
    buf = bytearray(bytes([r, g, b, a]) * (SIZE * SIZE))

    # ── Book geometry (designed on 1024 grid) ──
    SPINE_GAP  = sc(40)   # gap between pages at spine
    PAGE_Y1    = sc(268)
    PAGE_Y2    = sc(756)
    PAGE_H     = PAGE_Y2 - PAGE_Y1
    CENTER_X   = sc(512)
    LEFT_X1    = sc(186)
    RIGHT_X2   = sc(838)
    CORNER_R   = sc(26)

    left_x2   = CENTER_X - SPINE_GAP // 2
    right_x1  = CENTER_X + SPINE_GAP // 2

    # Draw pages
    rounded_rect(buf, PAGE_Y1, PAGE_Y2, LEFT_X1, left_x2, CORNER_R, AMBER)
    rounded_rect(buf, PAGE_Y1, PAGE_Y2, right_x1, RIGHT_X2, CORNER_R, AMBER)

    # ── Text lines (darker amber, representing lines of text) ──
    LINE_H   = sc(18)
    LINE_GAP = sc(64)
    MARGIN_X = sc(44)
    MARGIN_Y = sc(60)

    line_ys = [PAGE_Y1 + MARGIN_Y + i * LINE_GAP for i in range(5)]

    # Left page lines
    lx1 = LEFT_X1 + MARGIN_X
    lx2 = left_x2 - MARGIN_X
    for i, ly in enumerate(line_ys):
        x2 = lx2 if i < 4 else lx1 + int((lx2 - lx1) * 0.6)  # last line shorter
        fill_rect(buf, ly, ly + LINE_H, lx1, x2, AMBER_DIM)

    # Right page lines (mirrored)
    rx1 = right_x1 + MARGIN_X
    rx2 = RIGHT_X2 - MARGIN_X
    for i, ly in enumerate(line_ys):
        x2 = rx2 if i < 4 else rx1 + int((rx2 - rx1) * 0.6)
        fill_rect(buf, ly, ly + LINE_H, rx1, x2, AMBER_DIM)

    return buf

# ── Main ────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    out_dir = os.path.join(
        os.path.dirname(__file__), '..',
        'ReadRise', 'Resources', 'Assets.xcassets',
        'AppIcon.appiconset'
    )
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, 'AppIcon-1024.png')

    print(f'Generating {SIZE}×{SIZE} icon…')
    buf = build_icon()
    png = make_png(buf, SIZE)

    with open(out_path, 'wb') as f:
        f.write(png)

    print(f'Written {len(png):,} bytes → {out_path}')
