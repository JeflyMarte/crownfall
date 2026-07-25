#!/usr/bin/env python3
"""Recolor Blackshore enemy sheets for Hard / Nightmare tiers only.

Normal sheets are never overwritten. Hard/NM assets are used only on those tiers.
Mirrors tools/recolor_mistfen_tier_enemies.py (P3-ENEMY-TIER-VAR).

Note: some enemy_ids map to different sheet stems (VoidTentacle / DreadJaw).
"""
from __future__ import annotations

import colorsys
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ANIM_DIR = ROOT / "resources/animation"
PREVIEW_DIR = Path("/tmp/crownfall_bs_tier_recolor_preview")
ENEMY_DIR = ROOT / "assets/battle/enemies"
BOSS_DIR = ROOT / "assets/battle/bosses"

# (stem, enemy_id, asset_prefix ENM|BOSS, sheet_dir, preview_cell)
ENTRIES: list[tuple[str, str, str, Path, int]] = [
	("ShipEaterCrab", "ship_eater_crab", "ENM", ENEMY_DIR, 96),
	("SkullTurtle", "skull_turtle", "ENM", ENEMY_DIR, 96),
	("UndertakerShark", "undertaker_shark", "ENM", ENEMY_DIR, 96),
	("SamuraiFish", "samurai_fish", "ENM", ENEMY_DIR, 96),
	("DreadJaw", "black_tide_shark", "ENM", ENEMY_DIR, 96),
	("VoidTentacle", "abyssal_squid", "ENM", ENEMY_DIR, 96),
	("TideLamp", "tide_lamp", "ENM", ENEMY_DIR, 96),
	("NinjaOctopus", "ninja_octopus", "ENM", ENEMY_DIR, 96),
	("AnchorLord", "anchor_lord", "ENM", ENEMY_DIR, 96),
	("Nereion", "nereion", "BOSS", BOSS_DIR, 96),
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


def push_blood_tide(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Hard — deep-sea blues toward blood tide / rust coral."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 24:
		if l > 0.35:
			return (*mix_rgb(r, g, b, 170, 56, 64, 0.45), a)
		if l > 0.18:
			return (*mix_rgb(r, g, b, 110, 32, 40, 0.42), a)
		return (*mix_rgb(r, g, b, 36, 10, 16, 0.45), a)
	# cyan / teal water
	if b >= r and g + 10 >= r and ch >= 12 and l > 0.2:
		return (*hsl_to_rgb(0.02, clamp01(l * 0.9), min(0.7, s + 0.25)), a)
	# purple ink
	if b > r + 6 and b >= g and ch >= 14:
		return (*hsl_to_rgb(0.98, clamp01(l * 0.92), min(0.7, s + 0.18)), a)
	if ch >= 12 and r >= g and l > 0.14:
		return (*hsl_to_rgb(0.02, clamp01(l * 0.95), min(0.65, s + 0.12)), a)
	if l < 0.2:
		return (*mix_rgb(r, g, b, 24, 8, 14, 0.4), a)
	return (*mix_rgb(r, g, b, 56, 24, 32, 0.14), a)


def push_moon_abyss(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Nightmare — cold abyss / silver tide."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 24:
		if l > 0.35:
			return (*mix_rgb(r, g, b, 72, 130, 200, 0.45), a)
		if l > 0.18:
			return (*mix_rgb(r, g, b, 28, 64, 120, 0.42), a)
		return (*mix_rgb(r, g, b, 10, 16, 40, 0.45), a)
	if b >= r and ch >= 12 and l > 0.18:
		return (*hsl_to_rgb(0.55, clamp01(l * 0.95), min(0.6, s + 0.18)), a)
	if b > r + 4 and ch >= 14:
		return (*hsl_to_rgb(0.68, clamp01(l * 0.92), min(0.55, s + 0.15)), a)
	if l < 0.22:
		return (*mix_rgb(r, g, b, 10, 14, 36, 0.45), a)
	return (*mix_rgb(r, g, b, 48, 64, 110, 0.2), a)


def recolor_crab_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_blood_tide(r, g, b, a)


def recolor_crab_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_moon_abyss(r, g, b, a)


def recolor_turtle_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血骸 — bone shell stained."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.42 and ch < 45:
		return (*mix_rgb(r, g, b, 220, 170, 160, 0.4), a)
	return push_blood_tide(r, g, b, a)


def recolor_turtle_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.42 and ch < 45:
		return (*mix_rgb(r, g, b, 190, 210, 230, 0.4), a)
	return push_moon_abyss(r, g, b, a)


def recolor_shark_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_blood_tide(r, g, b, a)


def recolor_shark_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_moon_abyss(r, g, b, a)


def recolor_samurai_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_blood_tide(r, g, b, a)


def recolor_samurai_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_moon_abyss(r, g, b, a)


def recolor_dread_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_blood_tide(r, g, b, a)


def recolor_dread_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_moon_abyss(r, g, b, a)


def recolor_void_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血虚 — ink tentacles warmer crimson."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 28:
		if l > 0.3:
			return (*mix_rgb(r, g, b, 150, 40, 56, 0.5), a)
		return (*mix_rgb(r, g, b, 48, 12, 20, 0.5), a)
	return push_blood_tide(r, g, b, a)


def recolor_void_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 28:
		if l > 0.3:
			return (*mix_rgb(r, g, b, 64, 100, 180, 0.5), a)
		return (*mix_rgb(r, g, b, 12, 20, 48, 0.5), a)
	return push_moon_abyss(r, g, b, a)


def recolor_lamp_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血潮灯 — cyan glow → blood amber glow."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and (b >= g - 5) and ch >= 20:
		nr, ng, nb = hsl_to_rgb(0.05, clamp01(0.4 + l * 0.4), min(0.9, max(0.45, s)))
		if l > 0.65:
			nr, ng, nb = mix_rgb(nr, ng, nb, 255, 180, 96, 0.4)
		return nr, ng, nb, a
	return push_blood_tide(r, g, b, a)


def recolor_lamp_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""月潮灯 — deepen cyan to moon silver."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and ch >= 16:
		nr, ng, nb = hsl_to_rgb(0.55, clamp01(0.4 + l * 0.4), min(0.75, max(0.35, s)))
		if l > 0.65:
			nr, ng, nb = mix_rgb(nr, ng, nb, 210, 235, 255, 0.4)
		return nr, ng, nb, a
	return push_moon_abyss(r, g, b, a)


def recolor_octopus_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血海 — purple body → blood violet."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 18 and b > g and (b > r - 10):
		return (*hsl_to_rgb(0.98, clamp01(l * 0.9), min(0.8, s + 0.2)), a)
	return push_blood_tide(r, g, b, a)


def recolor_octopus_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 18 and b > g:
		return (*hsl_to_rgb(0.6, clamp01(l * 0.95), min(0.65, s + 0.15)), a)
	return push_moon_abyss(r, g, b, a)


def recolor_anchor_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""錆錨 — metal to copper rust."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.35 and ch < 40:
		return (*hsl_to_rgb(0.08, clamp01(l * 0.92), min(0.55, s + 0.25)), a)
	return push_blood_tide(r, g, b, a)


def recolor_anchor_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""霜錨 — steel frost."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.35 and ch < 40:
		return (*mix_rgb(r, g, b, 170, 200, 230, 0.45), a)
	return push_moon_abyss(r, g, b, a)


def recolor_nereion_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""紅潮 — blue royalty → blood tide king."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 20 and b > g and b >= r - 5:
		nr, ng, nb = hsl_to_rgb(0.0, clamp01(0.28 + l * 0.5), min(0.85, max(0.4, s)))
		if l > 0.55:
			nr, ng, nb = mix_rgb(nr, ng, nb, 255, 96, 130, 0.35)
		return nr, ng, nb, a
	if l > 0.4 and ch < 40:
		return (*mix_rgb(r, g, b, 210, 170, 170, 0.25), a)
	return push_blood_tide(r, g, b, a)


def recolor_nereion_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼潮 — deepen to moon abyss royalty."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 18 and b > g:
		nr, ng, nb = hsl_to_rgb(0.55, clamp01(0.32 + l * 0.45), min(0.75, max(0.35, s)))
		if l > 0.55:
			nr, ng, nb = mix_rgb(nr, ng, nb, 190, 230, 255, 0.4)
		return nr, ng, nb, a
	if l > 0.4 and ch < 40:
		return (*mix_rgb(r, g, b, 180, 205, 235, 0.3), a)
	if l < 0.25:
		return (*mix_rgb(r, g, b, 10, 16, 40, 0.4), a)
	return push_moon_abyss(r, g, b, a)


RECOLORERS = {
	("ShipEaterCrab", "Hard"): recolor_crab_hard,
	("ShipEaterCrab", "Nightmare"): recolor_crab_nightmare,
	("SkullTurtle", "Hard"): recolor_turtle_hard,
	("SkullTurtle", "Nightmare"): recolor_turtle_nightmare,
	("UndertakerShark", "Hard"): recolor_shark_hard,
	("UndertakerShark", "Nightmare"): recolor_shark_nightmare,
	("SamuraiFish", "Hard"): recolor_samurai_hard,
	("SamuraiFish", "Nightmare"): recolor_samurai_nightmare,
	("DreadJaw", "Hard"): recolor_dread_hard,
	("DreadJaw", "Nightmare"): recolor_dread_nightmare,
	("VoidTentacle", "Hard"): recolor_void_hard,
	("VoidTentacle", "Nightmare"): recolor_void_nightmare,
	("TideLamp", "Hard"): recolor_lamp_hard,
	("TideLamp", "Nightmare"): recolor_lamp_nightmare,
	("NinjaOctopus", "Hard"): recolor_octopus_hard,
	("NinjaOctopus", "Nightmare"): recolor_octopus_nightmare,
	("AnchorLord", "Hard"): recolor_anchor_hard,
	("AnchorLord", "Nightmare"): recolor_anchor_nightmare,
	("Nereion", "Hard"): recolor_nereion_hard,
	("Nereion", "Nightmare"): recolor_nereion_nightmare,
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
