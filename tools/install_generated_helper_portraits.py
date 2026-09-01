#!/usr/bin/env python3
"""Install generated helper bust portraits into assets/gacha/portraits.

Removes baked checkerboard/white margins via border flood, resizes to 512² RGBA.

Usage:
  python3 tools/install_generated_helper_portraits.py \\
    helper_q:/path/to/q.png helper_r:/path/to/r.png helper_s:/path/to/s.png
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "gacha" / "portraits"
TARGET = 512
WHITE_HARD = 248
WHITE_SOFT = 235


def passable_bg(r: int, g: int, b: int) -> bool:
	m = max(r, g, b)
	if m >= WHITE_HARD:
		return True
	if m >= WHITE_SOFT and max(r, g, b) - min(r, g, b) <= 12:
		return True
	return False


def flood_alpha(rgb: np.ndarray) -> np.ndarray:
	h, w, _ = rgb.shape
	passable = np.zeros((h, w), dtype=bool)
	for y in range(h):
		for x in range(w):
			r, g, b = (int(v) for v in rgb[y, x])
			passable[y, x] = passable_bg(r, g, b)
	reached = np.zeros((h, w), dtype=bool)
	stack: list[tuple[int, int]] = []
	for x in range(w):
		if passable[0, x]:
			stack.append((0, x))
		if passable[h - 1, x]:
			stack.append((h - 1, x))
	for y in range(h):
		if passable[y, 0]:
			stack.append((y, 0))
		if passable[y, w - 1]:
			stack.append((y, w - 1))
	for y, x in stack:
		reached[y, x] = True
	while stack:
		y, x = stack.pop()
		for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
			if 0 <= ny < h and 0 <= nx < w and passable[ny, nx] and not reached[ny, nx]:
				reached[ny, nx] = True
				stack.append((ny, nx))
	alpha = np.where(reached, 0, 255).astype(np.uint8)
	return alpha


def process(src: Path, helper_id: str) -> Path:
	im = Image.open(src).convert("RGB")
	rgb = np.array(im, dtype=np.uint8)
	alpha = flood_alpha(rgb)
	rgba = np.dstack([rgb, alpha])
	out_im = Image.fromarray(rgba, mode="RGBA")
	if out_im.size != (TARGET, TARGET):
		out_im = out_im.resize((TARGET, TARGET), Image.Resampling.LANCZOS)
	out = OUT_DIR / f"ART_HELPER_{helper_id}.png"
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	out_im.save(out, format="PNG", optimize=True)
	old_imp = out.with_suffix(out.suffix + ".import")
	if old_imp.exists():
		old_imp.unlink()
	print(f"  {src.name} → {out.relative_to(ROOT)} ({out_im.size[0]}x{out_im.size[1]})")
	return out


def patch_tres(helper_id: str) -> None:
	tres = ROOT / "resources" / "gacha_helpers" / f"{helper_id}.tres"
	text = tres.read_text(encoding="utf-8")
	path = f"res://assets/gacha/portraits/ART_HELPER_{helper_id}.png"
	key = "portrait_resource_path"
	if f'{key} = "' in text:
		start = text.index(f'{key} = "') + len(f'{key} = "')
		end = text.index('"', start)
		text = text[:start] + path + text[end:]
	else:
		needle = "sprite_resource_path"
		idx = text.index(needle)
		line_end = text.index("\n", idx)
		text = text[: line_end + 1] + f'portrait_resource_path = "{path}"\n' + text[line_end + 1 :]
	tres.write_text(text, encoding="utf-8")
	print(f"  patched {tres.relative_to(ROOT)}")


def main() -> int:
	if len(sys.argv) < 2:
		print(__doc__)
		return 1
	for arg in sys.argv[1:]:
		if ":" not in arg:
			raise SystemExit(f"bad arg (want helper_id:path): {arg}")
		helper_id, src_s = arg.split(":", 1)
		src = Path(src_s)
		if not src.is_file():
			raise SystemExit(f"missing: {src}")
		print(f"== {helper_id} ==")
		process(src, helper_id)
		patch_tres(helper_id)
	print("\nDONE — run Godot --import")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
