#!/usr/bin/env python3
"""Generate a macOS-style rounded-corner ("squircle") app icon from a source PNG.

Follows Apple's icon grid: a rounded-rectangle body inset with a small margin on
a transparent 1024x1024 canvas, so it sits in the Dock like a native app icon.

Pure Pillow and compatible back to Pillow 6.x (ImageDraw.rounded_rectangle was
only added in 8.2, so the rounded mask is composed from rectangles + pieslices).

Usage: make-rounded-icon.py <src.png> <dest.png> [size]
"""
import sys
from PIL import Image, ImageDraw


def rounded_mask(size, radius, ss=4):
    """An anti-aliased rounded-rectangle alpha mask (white body, black outside)."""
    big, r = size * ss, radius * ss
    m = Image.new("L", (big, big), 0)
    d = ImageDraw.Draw(m)
    d.rectangle([r, 0, big - r, big], fill=255)
    d.rectangle([0, r, big, big - r], fill=255)
    d.pieslice([0, 0, 2 * r, 2 * r], 180, 270, fill=255)            # top-left
    d.pieslice([big - 2 * r, 0, big, 2 * r], 270, 360, fill=255)    # top-right
    d.pieslice([0, big - 2 * r, 2 * r, big], 90, 180, fill=255)     # bottom-left
    d.pieslice([big - 2 * r, big - 2 * r, big, big], 0, 90, fill=255)  # bottom-right
    return m.resize((size, size), Image.LANCZOS)


def main():
    if len(sys.argv) < 3:
        sys.exit("usage: make-rounded-icon.py <src.png> <dest.png> [size]")
    src, dest = sys.argv[1], sys.argv[2]
    size = int(sys.argv[3]) if len(sys.argv) > 3 else 1024

    body = round(size * 0.804)         # Apple grid: ~824 / 1024
    radius = round(body * 0.2237)      # continuous-corner ("squircle") radius
    margin = (size - body) // 2

    art = Image.open(src).convert("RGBA").resize((body, body), Image.LANCZOS)
    art.putalpha(rounded_mask(body, radius))

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(art, (margin, margin), art)
    canvas.save(dest)
    print("rounded icon -> %s (%dx%d, body %d, radius %d)" % (dest, size, size, body, radius))


if __name__ == "__main__":
    main()
