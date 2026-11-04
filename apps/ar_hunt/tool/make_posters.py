#!/usr/bin/env python3
"""Draws the start-point posters: the images the AR view looks for, and an A4
PDF to print. Same seed, same posters, so a reprint still works.

    python3 -m venv /tmp/posters && /tmp/posters/bin/pip install pillow
    /tmp/posters/bin/python tool/make_posters.py

Changing the art means every phone needs a new build and every poster a
reprint. AR needs lots of sharp, uneven detail and no repeating pattern, which
is why these look busy on purpose.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

APP = Path(__file__).resolve().parent.parent
FONT = str(APP / "assets/google_fonts/Poppins-Bold.ttf")
FONT_REGULAR = str(APP / "assets/google_fonts/Poppins-Medium.ttf")

SIZE = 1024
# A4 at 300 dpi. The artwork must print at the width in hunt_models.dart.
DPI = 300
PAGE = (round(210 / 25.4 * DPI), round(297 / 25.4 * DPI))
ARTWORK = round(180 / 25.4 * DPI)

NIGHT = (20, 8, 31)
GOLD = (245, 184, 61)
SAFFRON = (255, 122, 26)
YELLOW = (255, 210, 31)
RED = (227, 36, 27)
CREAM = (255, 244, 220)
MAGENTA = (216, 27, 140)
TEAL = (31, 181, 166)
PLUM = (42, 18, 64)
MAROON = (74, 20, 36)
INK = (10, 4, 16)
PALETTE = [GOLD, SAFFRON, YELLOW, RED, CREAM, MAGENTA, TEAL, INK, PLUM, MAROON]

ZONES = {"a": 4101, "b": 4102, "c": 4103, "d": 4104}


def blob(draw, rng):
    """One sharp, uneven polygon. Corners are what AR tracks."""
    x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
    radius = rng.uniform(14, 120)
    sides = rng.randint(3, 9)
    start = rng.uniform(0, math.tau)
    points = [
        (
            x + rng.uniform(0.35, 1) * radius * math.cos(start + i * math.tau / sides),
            y + rng.uniform(0.35, 1) * radius * math.sin(start + i * math.tau / sides),
        )
        for i in range(sides)
    ]
    draw.polygon(points, fill=rng.choice(PALETTE))


def petals(draw, rng):
    """A lopsided flower, for a festive look without a repeating pattern."""
    x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
    count = rng.randint(5, 11)
    colour = rng.choice(PALETTE)
    for i in range(count):
        angle = i * math.tau / count + rng.uniform(-0.15, 0.15)
        length = rng.uniform(26, 92)
        width = rng.uniform(0.18, 0.5)
        draw.polygon(
            [
                (x, y),
                (x + length * 0.6 * math.cos(angle - width), y + length * 0.6 * math.sin(angle - width)),
                (x + length * math.cos(angle), y + length * math.sin(angle)),
                (x + length * 0.6 * math.cos(angle + width), y + length * 0.6 * math.sin(angle + width)),
            ],
            fill=colour,
            outline=rng.choice(PALETTE),
        )


def scatter(draw, rng):
    x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
    for _ in range(rng.randint(4, 12)):
        r = rng.uniform(2, 11)
        dx, dy = rng.uniform(-70, 70), rng.uniform(-70, 70)
        draw.ellipse((x + dx - r, y + dy - r, x + dx + r, y + dy + r), fill=rng.choice(PALETTE))


def artwork(letter, seed):
    rng = random.Random(seed)
    image = Image.new("RGB", (SIZE, SIZE), NIGHT)
    draw = ImageDraw.Draw(image)
    # Bold shapes first: they are what a phone can still make out from afar.
    for _ in range(260):
        blob(draw, rng)
    for _ in range(70):
        petals(draw, rng)
    for _ in range(80):
        scatter(draw, rng)
    for _ in range(14):
        draw.line(
            [(rng.uniform(0, SIZE), rng.uniform(0, SIZE)) for _ in range(2)],
            fill=rng.choice(PALETTE),
            width=rng.randint(6, 12),
        )

    # The letter sits somewhere different on each poster, which also makes the
    # four easier to tell apart from each other.
    corner = {"a": (150, 150), "b": (874, 190), "c": (190, 860), "d": (830, 830)}[letter]
    radius = 118
    draw.ellipse(
        (corner[0] - radius, corner[1] - radius, corner[0] + radius, corner[1] + radius),
        fill=INK,
        outline=GOLD,
        width=10,
    )
    font = ImageFont.truetype(FONT, 170)
    draw.text(corner, letter.upper(), font=font, fill=YELLOW, anchor="mm")
    return image


def page(letter, art):
    """One A4 sheet with the artwork at its exact printed size."""
    sheet = Image.new("RGB", PAGE, (255, 255, 255))
    draw = ImageDraw.Draw(sheet)
    title = ImageFont.truetype(FONT, 150)
    subtitle = ImageFont.truetype(FONT_REGULAR, 66)
    note = ImageFont.truetype(FONT_REGULAR, 44)
    centre = PAGE[0] / 2
    draw.text((centre, 200), "Habba Hunt", font=title, fill=INK, anchor="mm")
    draw.text((centre, 340), f"Start point {letter.upper()}", font=subtitle, fill=RED, anchor="mm")
    draw.text(
        (centre, 440),
        "Point your camera at the picture to start",
        font=note,
        fill=INK,
        anchor="mm",
    )
    left = (PAGE[0] - ARTWORK) // 2
    top = 530
    sheet.paste(art.resize((ARTWORK, ARTWORK), Image.LANCZOS), (left, top))

    # A ruler, so whoever prints this can check nothing was scaled.
    ruler_y = top + ARTWORK + 70
    draw.line((left, ruler_y, left + ARTWORK, ruler_y), fill=INK, width=6)
    for x in (left, left + ARTWORK):
        draw.line((x, ruler_y - 22, x, ruler_y + 22), fill=INK, width=6)
    draw.text(
        (centre, ruler_y + 70),
        "This line must measure exactly 18 cm. Print at 100% (Actual size).",
        font=note,
        fill=INK,
        anchor="mm",
    )
    draw.text(
        (centre, ruler_y + 150),
        "Stick it flat on a wall at eye level, in good light. Do not move it afterwards.",
        font=note,
        fill=INK,
        anchor="mm",
    )
    return sheet


def main():
    out = APP / "assets/ar/posters"
    out.mkdir(parents=True, exist_ok=True)
    sheets = []
    for letter, seed in ZONES.items():
        art = artwork(letter, seed)
        art.save(out / f"{letter}.png", optimize=True)
        sheets.append(page(letter, art))
    (APP / "posters").mkdir(exist_ok=True)
    sheets[0].save(
        APP / "posters/habba_hunt_posters.pdf",
        save_all=True,
        append_images=sheets[1:],
        resolution=DPI,
    )


if __name__ == "__main__":
    main()
