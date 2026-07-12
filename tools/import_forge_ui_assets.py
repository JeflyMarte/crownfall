#!/usr/bin/env python3
"""Normalize AI-generated forge UI chrome to game-friendly 9-slice sizes.

Reads WIP PNGs from assets/ui/forge/_wip/ and writes to assets/ui/forge/.

Usage:
  python3 tools/import_forge_ui_assets.py
"""
from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
WIP = ROOT / "assets/ui/forge/_wip"
OUT = ROOT / "assets/ui/forge"

# width, height — tuned for 720×1280 viewport 9-slice
TARGETS: dict[str, tuple[int, int]] = {
	"UI_Forge_Btn_Produce.png": (600, 100),
	"UI_Forge_ListCard_Normal.png": (720, 168),
	"UI_Forge_ListCard_Selected.png": (720, 168),
	"UI_Forge_Tab_Active.png": (220, 88),
	"UI_Forge_HeroGlow.png": (800, 800),
}

# AI 生成原画は白背景が焼き込まれるため、エッジからの flood-fill で透過化する。
STRIP_TRANSPARENCY = {
	"UI_Forge_Btn_Produce.png",
	"UI_Forge_ListCard_Normal.png",
	"UI_Forge_ListCard_Selected.png",
	"UI_Forge_Tab_Active.png",
	"UI_Forge_CraftChip_Normal.png",
	"UI_Forge_CraftChip_Selected.png",
	"UI_Forge_ItemCell_Normal.png",
	"UI_Forge_ItemCell_Selected.png",
	"UI_Forge_MaterialCell.png",
	"UI_Forge_HeroGlow.png",
}


def _is_background_pixel(
    r: int, g: int, b: int, a: int, light_threshold: int, dark_threshold: int = 32
) -> bool:
    if a < 10:
        return True
    if r <= dark_threshold and g <= dark_threshold and b <= dark_threshold:
        return True
    if r >= light_threshold and g >= light_threshold and b >= light_threshold:
        return True
    if max(r, g, b) - min(r, g, b) < 18 and min(r, g, b) > 195:
        return True
    return False


def strip_enclosed_dark_matte(img: Image.Image, threshold: int = 36) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if r <= threshold and g <= threshold and b <= threshold:
                px[x, y] = (r, g, b, 0)
    return img


def strip_edge_background(img: Image.Image, light_threshold: int = 235) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    q: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if (x, y) in seen or x < 0 or y < 0 or x >= w or y >= h:
            continue
        seen.add((x, y))
        r, g, b, a = px[x, y]
        if not _is_background_pixel(r, g, b, a, light_threshold):
            continue
        px[x, y] = (r, g, b, 0)
        q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    return img


def prepare_forge_image(name: str, img: Image.Image) -> Image.Image:
    if name not in STRIP_TRANSPARENCY:
        return img
    img = strip_edge_background(img)
    if "CraftChip" in name or "ItemCell" in name or "MaterialCell" in name:
        img = strip_enclosed_dark_matte(img)
    return img


def import_one(name: str, size: tuple[int, int] | None = None) -> bool:
    src = WIP / name
    if not src.exists():
        src = OUT / name
    if not src.exists():
        print(f"  skip missing: {name}")
        return False
    img = Image.open(src).convert("RGBA")
    if size is not None and img.size != size:
        img = img.resize(size, Image.Resampling.LANCZOS)
    img = prepare_forge_image(name, img)
    dst = OUT / name
    img.save(dst, optimize=True)
    if size is not None:
        print(f"  {name} -> {size[0]}x{size[1]}")
    else:
        print(f"  {name} -> {img.size[0]}x{img.size[1]} (transparency fix)")
    return True


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    WIP.mkdir(parents=True, exist_ok=True)
    ok = 0
    for name, size in TARGETS.items():
        if import_one(name, size):
            ok += 1
    for extra in sorted(STRIP_TRANSPARENCY - TARGETS.keys()):
        if import_one(extra):
            ok += 1
    print(f"done: {ok} files processed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
