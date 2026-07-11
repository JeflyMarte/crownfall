#!/usr/bin/env python3
"""Import owner-drawn equipment inventory cell frames.

Reads WIP PNGs from assets/ui/equipment_ui/_wip/ and writes normalized frames to
assets/ui/equipment_ui/ at EquipmentUiTokens.INV_CELL_DESIGN_PX (144).

Expected filenames:
  UI_Equip_InvCell_N.png
  UI_Equip_InvCell_R.png
  UI_Equip_InvCell_SR.png
  UI_Equip_InvCell_SSR.png

Usage:
  python3 tools/import_equipment_inv_cell_frames.py
  python3 tools/import_equipment_inv_cell_frames.py --only R
"""
from __future__ import annotations

import argparse
import sys
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
WIP = ROOT / "assets/ui/equipment_ui/_wip"
OUT = ROOT / "assets/ui/equipment_ui"
TARGET_PX = 144
LABELS = ("N", "R", "SR", "SSR")


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
    # 透過プレビューの市松模様（#CCC / #FFF 付近）
    if max(r, g, b) - min(r, g, b) < 12 and 175 < min(r, g, b) < 252:
        return True
    return False


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


def normalize_frame(img: Image.Image, size: int = TARGET_PX) -> Image.Image:
    img = strip_edge_background(img.convert("RGBA"))
    img = strip_enclosed_dark_matte(img)
    if img.size != (size, size):
        img = img.resize((size, size), Image.Resampling.LANCZOS)
    return img


def import_label(label: str) -> bool:
    name = f"UI_Equip_InvCell_{label}.png"
    src = WIP / name
    if not src.exists():
        print(f"  skip missing: {name}")
        return False
    img = normalize_frame(Image.open(src))
    dst = OUT / name
    img.save(dst, optimize=True)
    print(f"  {name} -> {TARGET_PX}x{TARGET_PX}")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--only",
        nargs="+",
        choices=LABELS,
        help="Import only the given rarity labels (e.g. --only R)",
    )
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    WIP.mkdir(parents=True, exist_ok=True)
    labels = args.only if args.only else LABELS
    ok = sum(1 for label in labels if import_label(label))
    print(f"done: {ok} files processed")
    return 0 if ok > 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
