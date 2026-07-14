#!/usr/bin/env python3
"""Recolor Mourngate enemy sheets for Hard / Nightmare tiers only.

Normal sheets are never overwritten. Hard/NM assets are used only on those tiers.
"""
from __future__ import annotations

import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ANIM_DIR = ROOT / "resources/animation"
PREVIEW_DIR = Path("/tmp/crownfall_tier_recolor_preview")

# (stem, enemy_id, asset_prefix ENM|BOSS, sheet_dir relative to ROOT, preview_cell)
ENTRIES: list[tuple[str, str, str, Path, int]] = [
	("GraveBellBat", "grave_bell_bat", "ENM", ROOT / "assets/dungeon/mourngate", 96),
	("CrystalScorpion", "crystal_scorpion", "ENM", ROOT / "assets/dungeon/mourngate", 96),
	("SkullfaceMantis", "skullface_mantis", "ENM", ROOT / "assets/dungeon/mourngate", 96),
	("SepiaHound", "sepia_hound", "ENM", ROOT / "assets/dungeon/mourngate", 96),
	("RuneRoach", "rune_roach", "ENM", ROOT / "assets/dungeon/mourngate", 96),
	("CrownEaterRat", "crown_eater_rat", "ENM", ROOT / "assets/dungeon/mourngate", 96),
	("CrystalHedgehog", "crystal_hedgehog", "ENM", ROOT / "assets/dungeon/mourngate", 96),
	("ClockMoth", "clock_moth", "ENM", ROOT / "assets/dungeon/mourngate", 96),
	("Serdion", "serdion", "BOSS", ROOT / "assets/battle/bosses", 128),
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


# ── shared palettes ──────────────────────────────────────────────


def push_crimson_accent(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Warm/rusty Hard accents on brown bodies."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.45 and ch >= 18:
		return (*hsl_to_rgb(0.02, clamp01(l * 0.9), min(0.8, s + 0.25)), a)
	if ch >= 14 and r >= g >= b and l > 0.15:
		return (*hsl_to_rgb(0.04, clamp01(l * 0.95), min(0.65, s + 0.15)), a)
	if l < 0.22:
		return (*mix_rgb(r, g, b, 28, 10, 12, 0.4), a)
	return (*mix_rgb(r, g, b, 48, 20, 18, 0.15), a)


def push_moon_cold(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Cold blue-grey Nightmare bodies."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.45 and ch >= 16:
		return (*hsl_to_rgb(0.55, clamp01(l * 1.02), min(0.5, s + 0.1)), a)
	if ch >= 12 and l > 0.18:
		return (*hsl_to_rgb(0.66, clamp01(l * 0.92), min(0.55, s + 0.12)), a)
	if l < 0.22:
		return (*mix_rgb(r, g, b, 12, 16, 36, 0.45), a)
	return (*mix_rgb(r, g, b, 56, 64, 96, 0.22), a)


# ── existing 3 ───────────────────────────────────────────────────


def recolor_grave_bell_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 28 and g > r + 8 and g >= b and l > 0.28:
		nh, ns, nl = 0.02, min(0.85, s * 1.35 + 0.15), clamp01(l * 0.88)
		nr, ng, nb = hsl_to_rgb(nh, nl, ns)
		if g > 140:
			nr, ng, nb = mix_rgb(nr, ng, nb, 192, 48, 64, 0.55)
		return nr, ng, nb, a
	if ch >= 18 and r >= g >= b and l < 0.55 and l > 0.12:
		return (*hsl_to_rgb(0.04, clamp01(l * 0.95), min(0.75, s * 1.2 + 0.1)), a)
	if l < 0.22 and ch < 40:
		return (*mix_rgb(r, g, b, 26, 8, 20, 0.45), a)
	if l < 0.4:
		return (*mix_rgb(r, g, b, 40, 16, 24, 0.18), a)
	return r, g, b, a


def recolor_grave_bell_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 28 and g > r + 8 and g >= b and l > 0.28:
		return (*hsl_to_rgb(0.52, clamp01(l * 1.05 + 0.04), min(0.55, s * 0.9 + 0.08)), a)
	if ch >= 18 and r >= g >= b and l < 0.55:
		return (*hsl_to_rgb(0.72, clamp01(l * 0.92), min(0.65, s * 1.1 + 0.12)), a)
	if l < 0.22:
		return (*mix_rgb(r, g, b, 12, 16, 40, 0.5), a)
	if l > 0.55 and ch < 35:
		return (*mix_rgb(r, g, b, 200, 210, 230, 0.35), a)
	return (*mix_rgb(r, g, b, 48, 56, 96, 0.2), a)


def _is_crystal(r: int, g: int, b: int, l: float, ch: int) -> bool:
	return (l > 0.42 and g >= b and g + 8 >= r and (ch >= 8 or l > 0.62)) or (
		ch >= 18 and g > b + 4 and g >= r - 12 and l > 0.28
	)


def recolor_scorpion_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if _is_crystal(r, g, b, l, ch):
		nr, ng, nb = hsl_to_rgb(0.78, clamp01(0.32 + l * 0.55), min(0.85, max(0.4, s + 0.4)))
		if l > 0.7:
			nr, ng, nb = mix_rgb(nr, ng, nb, 230, 190, 255, 0.45)
		return nr, ng, nb, a
	if ch >= 12 and r > b and l < 0.45 and l > 0.08:
		return (*hsl_to_rgb(0.05, clamp01(l * 0.9), min(0.55, s * 1.15 + 0.08)), a)
	if l < 0.18:
		return (*mix_rgb(r, g, b, 18, 10, 22, 0.35), a)
	return r, g, b, a


def recolor_scorpion_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if _is_crystal(r, g, b, l, ch):
		nr, ng, nb = hsl_to_rgb(0.075, clamp01(0.35 + l * 0.55), min(0.95, max(0.45, s + 0.45)))
		if l > 0.7:
			nr, ng, nb = mix_rgb(nr, ng, nb, 255, 210, 110, 0.55)
		elif l > 0.5:
			nr, ng, nb = mix_rgb(nr, ng, nb, 240, 140, 48, 0.35)
		return nr, ng, nb, a
	if l < 0.22:
		return (*mix_rgb(r, g, b, 8, 6, 10, 0.4), a)
	if ch >= 10 and l < 0.45:
		return (*mix_rgb(r, g, b, 72, 36, 20, 0.25), a)
	return r, g, b, a


def recolor_mantis_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.38 and ch < 55 and r + g + b > 180:
		nr, ng, nb = mix_rgb(r, g, b, 232, 220, 200, 0.55)
		if ch >= 20 and r > b:
			nr, ng, nb = mix_rgb(nr, ng, nb, 176, 32, 40, 0.22)
		return nr, ng, nb, a
	if 0.22 < l < 0.48 and ch >= 20 and g >= b and abs(r - g) < 40:
		band = int(l * 40) % 3
		if band == 0:
			return (*hsl_to_rgb(0.0, clamp01(l * 0.85), min(0.75, s + 0.35)), a)
		return (*hsl_to_rgb(0.22, clamp01(l * 0.75), min(0.4, s)), a)
	if l < 0.28:
		return (*mix_rgb(r, g, b, 10, 18, 12, 0.45), a)
	if ch >= 14 and r >= b:
		return (*hsl_to_rgb(0.02, clamp01(l * 0.9), min(0.55, s * 1.1)), a)
	return r, g, b, a


def recolor_mantis_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and ch < 50:
		return (*hsl_to_rgb(0.38, clamp01(l * 0.95), min(0.45, s + 0.2)), a)
	if ch >= 14:
		return (*hsl_to_rgb(0.33, clamp01(l * 0.92), min(0.7, s * 1.2 + 0.1)), a)
	if l < 0.25:
		return (*mix_rgb(r, g, b, 6, 22, 14, 0.5), a)
	return (*mix_rgb(r, g, b, 40, 72, 48, 0.3), a)


# ── new 6 ────────────────────────────────────────────────────────


def recolor_hound_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_crimson_accent(r, g, b, a)


def recolor_hound_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_moon_cold(r, g, b, a)


def recolor_roach_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""朱紋 — warm shell, rune highlights → crimson."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.42 and ch >= 16:
		return (*hsl_to_rgb(0.0, clamp01(l * 0.92), min(0.85, s + 0.35)), a)
	return push_crimson_accent(r, g, b, a)


def recolor_roach_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼紋 — ink shell + cyan rune glow."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.42 and ch >= 14:
		return (*hsl_to_rgb(0.52, clamp01(l * 0.98), min(0.7, s + 0.3)), a)
	return push_moon_cold(r, g, b, a)


def recolor_rat_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""貪冠 — copper fur, gold sparkles hotter."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# goldish flecks
	if l > 0.4 and r > g and g >= b and ch >= 20:
		return (*hsl_to_rgb(0.1, clamp01(l * 0.95), min(0.85, s + 0.25)), a)
	return push_crimson_accent(r, g, b, a)


def recolor_rat_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""奪冠 — bone-pale body, silver/black crown flecks."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and r > g and g >= b and ch >= 18:
		return (*mix_rgb(r, g, b, 200, 210, 220, 0.55), a)
	return push_moon_cold(r, g, b, a)


def recolor_hedgehog_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""紅晶 — cyan-crystal spines → ruby."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# icy cyan crystals dominate this sheet
	if l > 0.35 and (b >= r - 5) and (b + 10 >= g) and ch >= 12:
		nr, ng, nb = hsl_to_rgb(0.0, clamp01(0.3 + l * 0.5), min(0.9, max(0.45, s + 0.35)))
		if l > 0.7:
			nr, ng, nb = mix_rgb(nr, ng, nb, 255, 120, 140, 0.4)
		return nr, ng, nb, a
	if l < 0.25:
		return (*mix_rgb(r, g, b, 24, 8, 12, 0.4), a)
	return r, g, b, a


def recolor_hedgehog_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""黒晶 — spines to void crystal with cold rim."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.35 and (b >= r - 5) and (b + 10 >= g) and ch >= 12:
		# dark amethyst / ink crystal
		nr, ng, nb = hsl_to_rgb(0.75, clamp01(0.18 + l * 0.35), min(0.7, max(0.35, s + 0.2)))
		if l > 0.7:
			nr, ng, nb = mix_rgb(nr, ng, nb, 180, 200, 255, 0.35)
		return nr, ng, nb, a
	if l < 0.25:
		return (*mix_rgb(r, g, b, 8, 6, 16, 0.5), a)
	return (*mix_rgb(r, g, b, 30, 28, 40, 0.2), a)


def recolor_moth_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血刻 — copper gears / crimson dust."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and ch >= 14:
		return (*hsl_to_rgb(0.05, clamp01(l * 0.9), min(0.8, s + 0.3)), a)
	return push_crimson_accent(r, g, b, a)


def recolor_moth_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""停時 — silver gears, indigo wings, cyan dust."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.48 and ch < 40:
		return (*mix_rgb(r, g, b, 210, 220, 235, 0.5), a)
	if l > 0.35 and ch >= 14:
		return (*hsl_to_rgb(0.7, clamp01(l * 0.95), min(0.55, s + 0.2)), a)
	return push_moon_cold(r, g, b, a)


def recolor_serdion_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""紅骸 — existing purple crystals → blood crystal."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# purple / violet crystal regions (Serdion signature)
	if ch >= 30 and b > g and (b > r or h > 0.7 or h < 0.1):
		# hue near magenta/violet
		if b >= r - 20:
			nr, ng, nb = hsl_to_rgb(0.0, clamp01(0.28 + l * 0.5), min(0.9, max(0.4, s)))
			if l > 0.55:
				nr, ng, nb = mix_rgb(nr, ng, nb, 255, 96, 120, 0.35)
			return nr, ng, nb, a
	if ch >= 24 and b > r and b > g:
		return (*hsl_to_rgb(0.98, clamp01(l * 0.9), min(0.85, s + 0.15)), a)
	# bone stays, slight warm
	if l > 0.4 and ch < 35:
		return (*mix_rgb(r, g, b, 220, 200, 180, 0.15), a)
	return r, g, b, a


def recolor_serdion_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼骸 — crystals → moon cyan/silver."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 30 and b > g and (b > r - 10):
		nr, ng, nb = hsl_to_rgb(0.55, clamp01(0.35 + l * 0.45), min(0.75, max(0.35, s)))
		if l > 0.55:
			nr, ng, nb = mix_rgb(nr, ng, nb, 200, 230, 255, 0.4)
		return nr, ng, nb, a
	if ch >= 24 and b > r and b > g:
		return (*hsl_to_rgb(0.58, clamp01(l * 0.95), min(0.7, s + 0.1)), a)
	if l > 0.4 and ch < 35:
		return (*mix_rgb(r, g, b, 200, 210, 225, 0.25), a)
	if l < 0.25:
		return (*mix_rgb(r, g, b, 16, 20, 40, 0.35), a)
	return r, g, b, a


RECOLORERS = {
	("GraveBellBat", "Hard"): recolor_grave_bell_hard,
	("GraveBellBat", "Nightmare"): recolor_grave_bell_nightmare,
	("CrystalScorpion", "Hard"): recolor_scorpion_hard,
	("CrystalScorpion", "Nightmare"): recolor_scorpion_nightmare,
	("SkullfaceMantis", "Hard"): recolor_mantis_hard,
	("SkullfaceMantis", "Nightmare"): recolor_mantis_nightmare,
	("SepiaHound", "Hard"): recolor_hound_hard,
	("SepiaHound", "Nightmare"): recolor_hound_nightmare,
	("RuneRoach", "Hard"): recolor_roach_hard,
	("RuneRoach", "Nightmare"): recolor_roach_nightmare,
	("CrownEaterRat", "Hard"): recolor_rat_hard,
	("CrownEaterRat", "Nightmare"): recolor_rat_nightmare,
	("CrystalHedgehog", "Hard"): recolor_hedgehog_hard,
	("CrystalHedgehog", "Nightmare"): recolor_hedgehog_nightmare,
	("ClockMoth", "Hard"): recolor_moth_hard,
	("ClockMoth", "Nightmare"): recolor_moth_nightmare,
	("Serdion", "Hard"): recolor_serdion_hard,
	("Serdion", "Nightmare"): recolor_serdion_nightmare,
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


def write_tres_from_template(prefix: str, stem: str, tier: str, sheet_res_dir: str) -> None:
	"""sheet_res_dir: res:// path directory containing the sheet."""
	src = ANIM_DIR / f"{prefix}_{stem}.tres"
	dst = ANIM_DIR / f"{prefix}_{stem}_{tier}.tres"
	text = src.read_text(encoding="utf-8")
	# Replace whatever Sheet path is referenced with tier sheet in same logical dir as output
	# Serdion template points at battle/bosses; ENM at mourngate.
	old_name = f"{prefix}_{stem}_Sheet.png"
	new_name = f"{prefix}_{stem}_{tier}_Sheet.png"
	if old_name not in text:
		raise SystemExit(f"sheet ref missing in {src}")
	# keep directory from original ext_resource if present
	import re

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
			write_tres_from_template(prefix, stem, tier, str(sheet_dir))
	print(f"previews → {PREVIEW_DIR}")


if __name__ == "__main__":
	main()
