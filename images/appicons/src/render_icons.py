"""Renders logo.svg's geometry (circle + two round-capped strokes) into every app icon variation.

Run from the project root, then regenerate the launcher icons:
    python3 images/appicons/src/render_icons.py && dart run flutter_launcher_icons
Needs Pillow. If logo.svg changes, update LEAF and STEM to its paths.
"""
from pathlib import Path

from PIL import Image, ImageDraw

DIR = Path(__file__).resolve().parent.parent  # images/appicons
BG = (53, 84, 66)  # #355442
STROKE = 2.8
# The two leaf paths from logo.svg, as cubic Bézier segments in its 64-unit viewBox.
LEAF = [(22.3, 40.5), [((16.5, 33.5), (18.5, 24.5), (26.5, 21)), ((32.5, 18.5), (38, 18.8), (43.8, 16.8)),
                       ((44.6, 25.5), (42.5, 33), (37.5, 37.3)), ((33, 41), (27, 42.3), (22.3, 40.5))]]
STEM = [(17.6, 47.4), [((19.8, 41.5), (24.5, 36), (32.3, 32.2))]]
OUT, SS = 1024, 4  # output size, supersampling
N = OUT * SS


def points(path, steps=400):
    start, curves = path
    pts, p0 = [start], start
    for c1, c2, p3 in curves:
        for i in range(1, steps + 1):
            t = i / steps; u = 1 - t
            pts.append((u**3 * p0[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t**3 * p3[0],
                        u**3 * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t**3 * p3[1]))
        p0 = p3
    return pts


def leaf_mask():
    m = Image.new('L', (N, N), 0)
    d = ImageDraw.Draw(m)
    k = N / 64
    r = STROKE / 2 * k
    for path in (LEAF, STEM):
        pts = [(x * k, y * k) for x, y in points(path)]
        d.line(pts, fill=255, width=round(2 * r))
        for x, y in pts:  # round caps and joins
            d.ellipse((x - r, y - r, x + r, y + r), fill=255)
    return m


def layer(color, mask):
    im = Image.new('RGBA', (N, N), color + (0,))
    im.putalpha(mask)
    return im


def save(im, name, size=OUT, opaque=False):
    im = im.resize((size, size), Image.LANCZOS)
    (im.convert('RGB') if opaque else im).save(DIR / name, optimize=True)


white = (255, 255, 255)
leaf = leaf_mask()

# Round: the SVG as drawn (older Android launchers).
circle = Image.new('L', (N, N), 0)
ImageDraw.Draw(circle).ellipse((0, 0, N - 1, N - 1), fill=255)
round_icon = layer(BG, circle); round_icon.alpha_composite(layer(white, leaf))
save(round_icon, 'icon_round.png')

# Square, full bleed: iOS and the Play Store mask the corners themselves.
square = Image.new('RGBA', (N, N), BG + (255,)); square.alpha_composite(layer(white, leaf))
save(square, 'appstore.png', opaque=True)
save(square, 'playstore.png', 512, opaque=True)

# Android adaptive foreground and themed-icon monochrome: the leaf on transparent.
save(layer(white, leaf), 'icon_foreground.png')
save(layer(white, leaf), 'icon_monochrome.png')

# iOS 18 dark (light brand green on transparent) and tinted (white on black, iOS tints it).
save(layer((143, 201, 160), leaf), 'icon_ios_dark.png')
tinted = Image.new('RGBA', (N, N), (0, 0, 0, 255)); tinted.alpha_composite(layer(white, leaf))
save(tinted, 'icon_ios_tinted.png', opaque=True)
