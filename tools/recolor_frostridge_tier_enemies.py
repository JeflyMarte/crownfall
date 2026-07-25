#!/usr/bin/env python3
"""Recolor Frostridge enemy sheets for Hard / Nightmare tiers only.

Normal sheets are never overwritten. Hard/NM assets are used only on those tiers.
Mirrors tools/recolor_blackshore_tier_enemies.py (P3-ENEMY-TIER-VAR-006).

Hard = 緋霜／血氷（crimson frost）
Nightmare = 蒼月／虚寒（moon void frost）
"""
from __future__ import annotations

import colorsys
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ANIM_DIR = ROOT / "resources/animation"
PREVIEW_DIR = Path("/tmp/crownfall_fr_tier_recolor_preview")
ENEMY_DIR = ROOT / "assets/battle/enemies"
BOSS_DIR = ROOT / "assets/battle/bosses"

# (stem, enemy_id, asset_prefix ENM|BOSS, sheet_dir, preview_cell)
ENTRIES: list[tuple[str, str, str, Path, int]] = [
	("FrostClawRaptor", "frost_claw_raptor", "ENM", ENEMY_DIR, 96),
	("Vergaron", "vergaron", "ENM", ENEMY_DIR, 96),
	("StormJoe", "storm_joe", "ENM", ENEMY_DIR, 96),
	("Oldrex", "oldrex", "ENM", ENEMY_DIR, 96),
	("Greios", "greios", "ENM", ENEMY_DIR, 96),
	("GlacierWarden", "glacier_warden", "ENM", ENEMY_DIR, 96),
	("WindRipper", "wind_ripper", "ENM", ENEMY_DIR, 96),
	("Eldion", "eldion", "BOSS", BOSS_DIR, 96),
]


def clamp01(x: float) -> float:
	return 0.0 if x < 0.0 else (1.0 if x > 1.0 else x)


def rgb_to_hsl(r: int, g: int, b: int) -> tuple[float, float, float]:
	return colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)


def hsl_to_rgb(h: float, l: float, s: float) -> tuple[int, int, int]:
	r, g, b = colorsys.hls_to_rgb(h % 1.0, clamp01(l), clamp01(s))
	return int(round(r * 255)), int(round(g * 255)), int(round(b * 255))


def chroma(r: int, g: int, b: int) -> int:
	return max(r, g, b) - min(r, g, b)


def lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t


def mix_rgb(r: int, g: int, b: int, tr: int, tg: int, tb: int, t: float) -> tuple[int, int, int]:
	t = clamp01(t)
	return (
		int(round(lerp(r, tr, t))),
		int(round(lerp(g, tg, t))),
		int(round(lerp(b, tb, t))),
	)


def push_crimson_frost(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Hard — ice blues/whites toward crimson frost / blood ice."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# snow / ice white-grey
	if ch < 28:
		if l > 0.55:
			return (*mix_rgb(r, g, b, 230, 150, 160, 0.42), a)
		if l > 0.3:
			return (*mix_rgb(r, g, b, 170, 56, 72, 0.45), a)
		return (*mix_rgb(r, g, b, 48, 14, 22, 0.48), a)
	# cyan / ice blue → crimson
	if b >= r and (b >= g - 8) and ch >= 12 and l > 0.18:
		return (*hsl_to_rgb(0.0, clamp01(l * 0.92), min(0.72, s + 0.22)), a)
	# cool purple shadow → blood violet
	if b > r + 4 and b >= g and ch >= 14:
		return (*hsl_to_rgb(0.97, clamp01(l * 0.9), min(0.7, s + 0.18)), a)
	if ch >= 12 and r >= g and l > 0.14:
		return (*hsl_to_rgb(0.02, clamp01(l * 0.95), min(0.65, s + 0.12)), a)
	if l < 0.2:
		return (*mix_rgb(r, g, b, 28, 8, 14, 0.42), a)
	return (*mix_rgb(r, g, b, 72, 28, 36, 0.16), a)


def push_moon_void_frost(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Nightmare — deepen ice into moon void / silver frost."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 28:
		if l > 0.55:
			return (*mix_rgb(r, g, b, 190, 220, 255, 0.42), a)
		if l > 0.3:
			return (*mix_rgb(r, g, b, 48, 90, 160, 0.45), a)
		return (*mix_rgb(r, g, b, 10, 16, 40, 0.48), a)
	if b >= r and ch >= 12 and l > 0.16:
		return (*hsl_to_rgb(0.58, clamp01(l * 0.95), min(0.62, s + 0.2)), a)
	if b > r + 4 and ch >= 14:
		return (*hsl_to_rgb(0.68, clamp01(l * 0.92), min(0.55, s + 0.15)), a)
	if l < 0.22:
		return (*mix_rgb(r, g, b, 8, 12, 36, 0.45), a)
	return (*mix_rgb(r, g, b, 40, 64, 120, 0.2), a)


def recolor_generic_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_crimson_frost(r, g, b, a)


def recolor_generic_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_moon_void_frost(r, g, b, a)


def recolor_eldion_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""紅始祖 — ice dragon body toward blood frost royalty."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 18 and b > g and b >= r - 8:
		nr, ng, nb = hsl_to_rgb(0.0, clamp01(0.28 + l * 0.5), min(0.85, max(0.4, s)))
		if l > 0.55:
			nr, ng, nb = mix_rgb(nr, ng, nb, 255, 110, 140, 0.35)
		return nr, ng, nb, a
	if l > 0.45 and ch < 40:
		return (*mix_rgb(r, g, b, 220, 170, 175, 0.28), a)
	return push_crimson_frost(r, g, b, a)


def recolor_eldion_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼始祖 — deepen to moon void royalty."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 16 and b > g:
		nr, ng, nb = hsl_to_rgb(0.56, clamp01(0.3 + l * 0.45), min(0.75, max(0.35, s)))
		if l > 0.55:
			nr, ng, nb = mix_rgb(nr, ng, nb, 190, 230, 255, 0.4)
		return nr, ng, nb, a
	if l > 0.45 and ch < 40:
		return (*mix_rgb(r, g, b, 175, 205, 240, 0.3), a)
	if l < 0.25:
		return (*mix_rgb(r, g, b, 8, 14, 40, 0.42), a)
	return push_moon_void_frost(r, g, b, a)


RECOLORERS = {
	("FrostClawRaptor", "Hard"): recolor_generic_hard,
	("FrostClawRaptor", "Nightmare"): recolor_generic_nightmare,
	("Vergaron", "Hard"): recolor_generic_hard,
	("Vergaron", "Nightmare"): recolor_generic_nightmare,
	("StormJoe", "Hard"): recolor_generic_hard,
	("StormJoe", "Nightmare"): recolor_generic_nightmare,
	("Oldrex", "Hard"): recolor_generic_hard,
	("Oldrex", "Nightmare"): recolor_generic_nightmare,
	("Greios", "Hard"): recolor_generic_hard,
	("Greios", "Nightmare"): recolor_generic_nightmare,
	("GlacierWarden", "Hard"): recolor_generic_hard,
	("GlacierWarden", "Nightmare"): recolor_generic_nightmare,
	("WindRipper", "Hard"): recolor_generic_hard,
	("WindRipper", "Nightmare"): recolor_generic_nightmare,
	("Eldion", "Hard"): recolor_eldion_hard,
	("Eldion", "Nightmare"): recolor_eldion_nightmare,
}


def apply_recolor(src: Image.Image, fn) -> Image.Image:
	img = src.convert("RGBA")
	px = img.load()
	w, h = img.size
	out = Image.new("RGBA", (w, h))
	opx = out.load()
	for y in range(h):
		for x in range(w):
			opx[x, y] = fn(*px[x, y])
	return out


def write_tres_from_template(prefix: str, stem: str, tier: str) -> None:
	src = ANIM_DIR / f"{prefix}_{stem}.tres"
	dst = ANIM_DIR / f"{prefix}_{stem}_{tier}.tres"
	text = src.read_text(encoding="utf-8")
	old_name = f"{prefix}_{stem}_Sheet.png"
	new_name = f"{prefix}_{stem}_{tier}_Sheet.png"
	if old_name not in text:
		raise SystemExit(f"sheet ref missing in {src}")
	m = re.search(r'path="(res://[^"]+%s)"' % re.escape(old_name), text)
	if m:
		old_full = m.group(1)
		new_full = old_full.replace(old_name, new_name)
		text = text.replace(old_full, new_full)
	else:
		text = text.replace(old_name, new_name)
	dst.write_text(text, encoding="utf-8")
	print(f"wrote {dst.relative_to(ROOT)}")


def main() -> None:
	PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
	for stem, _eid, prefix, sheet_dir, cell in ENTRIES:
		src_path = sheet_dir / f"{prefix}_{stem}_Sheet.png"
		if not src_path.exists():
			raise SystemExit(f"missing {src_path}")
		src = Image.open(src_path)
		for tier in ("Hard", "Nightmare"):
			fn = RECOLORERS[(stem, tier)]
			out = apply_recolor(src, fn)
			out_path = sheet_dir / f"{prefix}_{stem}_{tier}_Sheet.png"
			out.save(out_path, optimize=True)
			print(f"wrote {out_path.relative_to(ROOT)} size={out.size}")
			preview = out.crop((0, 0, min(cell, out.size[0]), min(cell, out.size[1])))
			preview.save(PREVIEW_DIR / f"{prefix}_{stem}_{tier}.png")
			write_tres_from_template(prefix, stem, tier)
	print(f"previews → {PREVIEW_DIR}")


if __name__ == "__main__":
	main()
