#!/usr/bin/env python3
"""Import gacha screen BG / title art from Desktop into res://assets/ui/gacha_ui/.

SSOT paths (do not regenerate via generate_gacha_ui_assets.py):
  Desktop/CrownFall設定画像/背景/ガチャ背景.png   → UI_BG_Gacha.png
  Desktop/CrownFall設定画像/背景/ガチャタイトル.png → UI_Gacha_Title.png + UI_Gacha_Catch.png

Usage:
  python3 tools/import_gacha_screen_art.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/gacha_ui"
DESKTOP_BG = Path.home() / "Desktop" / "CrownFall設定画像" / "背景"
SRC_BG = DESKTOP_BG / "ガチャ背景.png"
SRC_TITLE = DESKTOP_BG / "ガチャタイトル.png"
TARGET_W, TARGET_H = 720, 1280


def cover_fit(img: Image.Image, tw: int, th: int) -> Image.Image:
    img = img.convert("RGB")
    scale = max(tw / img.width, th / img.height)
    nw, nh = int(img.width * scale + 0.5), int(img.height * scale + 0.5)
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    l = (nw - tw) // 2
    t = (nh - th) // 2
    return img.crop((l, t, l + tw, t + th))


def strip_near_black(img: Image.Image, threshold: int = 18) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r < threshold and g < threshold and b < threshold:
                px[x, y] = (0, 0, 0, 0)
    return img


def content_bbox(im: Image.Image, y0: int, y1: int):
    sub = im.crop((0, y0, im.width, y1))
    bbox = sub.split()[-1].getbbox()
    if not bbox:
        return None
    x0, sy0, x1, sy1 = bbox
    return (x0, y0 + sy0, x1, y0 + sy1)


def split_title_sheet(sheet: Image.Image) -> tuple[Image.Image, Image.Image]:
    sheet = strip_near_black(sheet)
    w, h = sheet.size
    px = sheet.load()
    mid = h // 2
    empty_rows = [
        y
        for y in range(h)
        if not any(px[x, y][3] > 20 for x in range(w))
    ]
    split_y = mid
    best = None
    for y in empty_rows:
        dist = abs(y - mid)
        if best is not None and dist >= best:
            continue
        above = any(px[x, yy][3] > 20 for yy in range(0, y, 4) for x in range(0, w, 16))
        below = any(px[x, yy][3] > 20 for yy in range(y + 1, h, 4) for x in range(0, w, 16))
        if above and below:
            best = dist
            split_y = y
    top_box = content_bbox(sheet, 0, split_y)
    bot_box = content_bbox(sheet, split_y, h)
    if not top_box or not bot_box:
        raise RuntimeError("failed to split gacha title sheet into two banners")
    pad = 8

    def crop(box):
        x0, y0, x1, y1 = box
        return sheet.crop(
            (
                max(0, x0 - pad),
                max(0, y0 - pad),
                min(w, x1 + pad),
                min(h, y1 + pad),
            )
        )

    return crop(top_box), crop(bot_box)


def main() -> int:
    if not SRC_BG.is_file():
        raise SystemExit(f"missing source: {SRC_BG}")
    if not SRC_TITLE.is_file():
        raise SystemExit(f"missing source: {SRC_TITLE}")
    OUT.mkdir(parents=True, exist_ok=True)

    bg = cover_fit(Image.open(SRC_BG), TARGET_W, TARGET_H)
    bg_path = OUT / "UI_BG_Gacha.png"
    bg.save(bg_path, optimize=True)
    print(f"wrote {bg_path} {bg.size} ({bg_path.stat().st_size} bytes)")
    # Legacy alias used by older imports / docs
    summon = ROOT / "assets/ui/UI_BG_Summon.png"
    bg.save(summon, optimize=True)
    print(f"wrote {summon}")

    title, catch = split_title_sheet(Image.open(SRC_TITLE))
    for name, img in (("UI_Gacha_Title.png", title), ("UI_Gacha_Catch.png", catch)):
        path = OUT / name
        img.save(path, optimize=True)
        print(f"wrote {path} {img.size} ({path.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
