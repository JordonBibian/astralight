#!/usr/bin/env python3
"""Render Astralight's four-point star assets. Requires Pillow."""
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Limelight/Images.xcassets"
DESIGN = ROOT / "Design"
# The four-point silhouette from the original Astralight UI reference.
STAR = [(0, -11), (3, -3), (11, 0), (3, 3),
        (0, 11), (-3, 3), (-11, 0), (-3, -3)]
STAR_COLOR = (187, 200, 255)
BACKGROUND_START = (28, 60, 126)
BACKGROUND_END = (81, 40, 120)


def star_mask(size, radius):
    mask = Image.new("L", (size, size))
    points = [(size / 2 + x * radius / 11, size / 2 + y * radius / 11)
              for x, y in STAR]
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def generate():
    # Supersampling keeps the narrow points clean at Home Screen sizes.
    size = 2048
    icon = Image.new("RGB", (size, size))
    pixels = icon.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            pixels[x, y] = tuple(round(a + (b - a) * t)
                                 for a, b in zip(BACKGROUND_START, BACKGROUND_END))
    icon.paste(STAR_COLOR, mask=star_mask(size, size * 0.33))

    appicon = ASSETS / "AppIcon.appiconset"
    contents = json.loads((appicon / "Contents.json").read_text())
    for entry in contents["images"]:
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"][0])
        pixels = round(points * scale)
        if "filename" not in entry:
            entry["filename"] = f"Icon-App-{points:g}x{points:g}@{scale}x.png"
        icon.resize((pixels, pixels), Image.Resampling.LANCZOS).save(appicon / entry["filename"])
    (appicon / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")

    mark_dir = ASSETS / "AstralightMark.imageset"
    mark_dir.mkdir(exist_ok=True)
    mark = Image.new("RGBA", (384, 384), STAR_COLOR + (0,))
    mark.putalpha(star_mask(384, 176))
    images = []
    for scale in (1, 2, 3):
        filename = f"AstralightMark@{scale}x.png"
        mark.resize((24 * scale, 24 * scale), Image.Resampling.LANCZOS).save(mark_dir / filename)
        images.append({"idiom": "universal", "filename": filename, "scale": f"{scale}x"})
    (mark_dir / "Contents.json").write_text(json.dumps({
        "images": images,
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "template"}
    }, indent=2) + "\n")
    icon.resize((256, 256), Image.Resampling.LANCZOS).save(DESIGN / "astralight-icon-preview.png")


if __name__ == "__main__":
    generate()
