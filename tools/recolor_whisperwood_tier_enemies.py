#!/usr/bin/env python3
"""Recolor Whisperwood enemy sheets for Hard / Nightmare tiers only.

Normal sheets are never overwritten. Hard/NM assets are used only on those tiers.
Mirrors tools/recolor_mourngate_tier_enemies.py (P3-ENEMY-TIER-VAR).
"""
from __future__ import annotations

import colorsys
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ANIM_DIR = ROOT / "resources/animation"
PREVIEW_DIR = Path("/tmp/crownfall_ww_tier_recolor_preview")
ENEMY_DIR = ROOT / "assets/battle/enemies"
BOSS_DIR = ROOT / "assets/battle/bosses"

# (stem, enemy_id, asset_prefix ENM|BOSS, sheet_dir, preview_cell)
ENTRIES: list[tuple[str, str, str, Path, int]] = [
	("MossBoar", "moss_boar", "ENM", ENEMY_DIR, 96),
	("MossShell", "moss_shell", "ENM", ENEMY_DIR, 96),
	("IronHorn", "iron_horn", "ENM", ENEMY_DIR, 96),
	("SporeWidow", "spore_widow", "ENM", ENEMY_DIR, 96),
	("BloodBloom", "blood_bloom", "ENM", ENEMY_DIR, 96),
	("RuneCarcinos", "rune_carcinos", "ENM", ENEMY_DIR, 96),
	("MistWyvern", "mist_wyvern", "ENM", ENEMY_DIR, 96),
	("MirrorBoa", "mirror_boa", "ENM", ENEMY_DIR, 96),
	("Granvel", "granvel", "BOSS", BOSS_DIR, 96),
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


def push_rot_crimson(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Hard — verdant / bark bodies toward rot crimson & amber sap."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# greens / moss
	if g >= r + 6 and g >= b and ch >= 12 and l > 0.18:
		return (*hsl_to_rgb(0.02, clamp01(l * 0.9), min(0.75, s + 0.28)), a)
	# yellow-green foliage
	if 0.15 < h < 0.45 and ch >= 14 and l > 0.22:
		return (*hsl_to_rgb(0.05, clamp01(l * 0.92), min(0.7, s + 0.2)), a)
	# bark / brown
	if ch >= 10 and r >= g >= b and l > 0.12:
		return (*hsl_to_rgb(0.04, clamp01(l * 0.95), min(0.6, s + 0.12)), a)
	if l < 0.2:
		return (*mix_rgb(r, g, b, 28, 10, 12, 0.4), a)
	return (*mix_rgb(r, g, b, 56, 24, 22, 0.14), a)


def push_moon_spore(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Nightmare — cold spore mist / moon-blue forest."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if g >= r + 4 and g >= b - 4 and ch >= 10 and l > 0.18:
		return (*hsl_to_rgb(0.55, clamp01(l * 0.95), min(0.55, s + 0.18)), a)
	if 0.15 < h < 0.45 and ch >= 12:
		return (*hsl_to_rgb(0.58, clamp01(l * 0.92), min(0.5, s + 0.15)), a)
	if ch >= 12 and l > 0.18:
		return (*hsl_to_rgb(0.66, clamp01(l * 0.92), min(0.55, s + 0.12)), a)
	if l < 0.22:
		return (*mix_rgb(r, g, b, 12, 16, 36, 0.45), a)
	return (*mix_rgb(r, g, b, 56, 64, 96, 0.2), a)


def recolor_boar_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_rot_crimson(r, g, b, a)


def recolor_boar_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_moon_spore(r, g, b, a)


def recolor_shell_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""緋殻 — shell rims warmer, moss blotches crimson."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.45 and ch < 40:
		return (*mix_rgb(r, g, b, 220, 170, 150, 0.35), a)
	return push_rot_crimson(r, g, b, a)


def recolor_shell_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼殻 — pale cyan shell."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.45 and ch < 40:
		return (*mix_rgb(r, g, b, 180, 210, 230, 0.4), a)
	return push_moon_spore(r, g, b, a)


def recolor_horn_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""錆刃 — metal edges to copper-rust."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and ch < 45:
		return (*hsl_to_rgb(0.08, clamp01(l * 0.92), min(0.55, s + 0.25)), a)
	return push_rot_crimson(r, g, b, a)


def recolor_horn_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""霜刃 — steel-blue blades."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and ch < 45:
		return (*mix_rgb(r, g, b, 170, 200, 230, 0.45), a)
	return push_moon_spore(r, g, b, a)


def recolor_widow_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""朱胞 — spore sacs / abdomen crimson."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.35 and ch >= 14:
		return (*hsl_to_rgb(0.0, clamp01(l * 0.9), min(0.8, s + 0.35)), a)
	return push_rot_crimson(r, g, b, a)


def recolor_widow_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""月胞 — violet-spore glow."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.35 and ch >= 12:
		return (*hsl_to_rgb(0.72, clamp01(l * 0.95), min(0.65, s + 0.25)), a)
	return push_moon_spore(r, g, b, a)


def recolor_bloom_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""紅咲 — deepen existing blood petals."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 18 and r > g + 8 and r > b:
		nr, ng, nb = hsl_to_rgb(0.0, clamp01(l * 0.88), min(0.9, s + 0.2))
		if l > 0.55:
			nr, ng, nb = mix_rgb(nr, ng, nb, 255, 80, 100, 0.35)
		return nr, ng, nb, a
	if g > r + 6 and g >= b:
		return (*hsl_to_rgb(0.02, clamp01(l * 0.9), min(0.7, s + 0.2)), a)
	return push_rot_crimson(r, g, b, a)


def recolor_bloom_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""幽咲 — petals to pale moon lilac."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 16 and r > g and r > b:
		return (*hsl_to_rgb(0.75, clamp01(0.35 + l * 0.45), min(0.55, s + 0.1)), a)
	return push_moon_spore(r, g, b, a)


def recolor_carcinos_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""朱紋 — dark carapace forced toward rust + crimson flecks."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# low-chroma stone shell dominates — force warm rust
	if ch < 28:
		if l > 0.35:
			return (*mix_rgb(r, g, b, 180, 64, 48, 0.55), a)
		if l > 0.18:
			return (*mix_rgb(r, g, b, 120, 36, 28, 0.5), a)
		return (*mix_rgb(r, g, b, 48, 12, 12, 0.55), a)
	if l > 0.42:
		return (*hsl_to_rgb(0.0, clamp01(l * 0.92), min(0.85, s + 0.35)), a)
	return push_rot_crimson(r, g, b, a)


def recolor_carcinos_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼紋 — cyan rune shell on ink carapace."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 28:
		if l > 0.35:
			return (*mix_rgb(r, g, b, 72, 140, 200, 0.55), a)
		if l > 0.18:
			return (*mix_rgb(r, g, b, 32, 72, 128, 0.5), a)
		return (*mix_rgb(r, g, b, 12, 20, 48, 0.55), a)
	if l > 0.42:
		return (*hsl_to_rgb(0.52, clamp01(l * 0.98), min(0.7, s + 0.3)), a)
	return push_moon_spore(r, g, b, a)


def recolor_wyvern_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血霧 — mist body warmer, wing membranes crimson."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# icy / pale mist → blood haze
	if l > 0.4 and (b >= g - 5) and ch < 50:
		return (*mix_rgb(r, g, b, 200, 120, 130, 0.4), a)
	if ch >= 14 and b > r:
		return (*hsl_to_rgb(0.98, clamp01(l * 0.9), min(0.55, s + 0.15)), a)
	return push_rot_crimson(r, g, b, a)


def recolor_wyvern_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""月霧 — deeper void-cyan mist."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and ch < 50:
		return (*mix_rgb(r, g, b, 150, 190, 230, 0.45), a)
	if ch >= 12 and b >= r - 5:
		return (*hsl_to_rgb(0.58, clamp01(l * 0.95), min(0.6, s + 0.2)), a)
	return push_moon_spore(r, g, b, a)


def recolor_boa_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血鏡 — reflective scales forced crimson (sheet is near-grey)."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 30:
		if l > 0.4:
			return (*mix_rgb(r, g, b, 210, 110, 120, 0.5), a)
		if l > 0.2:
			return (*mix_rgb(r, g, b, 140, 48, 56, 0.48), a)
		return (*mix_rgb(r, g, b, 40, 10, 16, 0.5), a)
	if l > 0.45:
		return (*mix_rgb(r, g, b, 220, 150, 150, 0.4), a)
	return push_rot_crimson(r, g, b, a)


def recolor_boa_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""幽鏡 — silver-violet scales (sheet is near-grey)."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 30:
		if l > 0.4:
			return (*mix_rgb(r, g, b, 170, 190, 240, 0.5), a)
		if l > 0.2:
			return (*mix_rgb(r, g, b, 72, 80, 140, 0.48), a)
		return (*mix_rgb(r, g, b, 16, 16, 40, 0.5), a)
	if l > 0.45:
		return (*mix_rgb(r, g, b, 190, 200, 230, 0.45), a)
	return push_moon_spore(r, g, b, a)


def recolor_granvel_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""紅樹 — flora / moss → blood blossom."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	# flower / pink accents deepen
	if ch >= 20 and r > g + 10 and r > b:
		nr, ng, nb = hsl_to_rgb(0.0, clamp01(0.3 + l * 0.5), min(0.9, max(0.4, s)))
		if l > 0.55:
			nr, ng, nb = mix_rgb(nr, ng, nb, 255, 96, 120, 0.35)
		return nr, ng, nb, a
	if g > r + 4 and g >= b and ch >= 12:
		return (*hsl_to_rgb(0.02, clamp01(l * 0.9), min(0.7, s + 0.25)), a)
	if l > 0.4 and ch < 35:
		return (*mix_rgb(r, g, b, 220, 190, 170, 0.18), a)
	return push_rot_crimson(r, g, b, a)


def recolor_granvel_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼樹 — moonlit flora."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 18 and r > g and r > b:
		return (*hsl_to_rgb(0.72, clamp01(0.35 + l * 0.4), min(0.55, s + 0.1)), a)
	if g > r + 4 and g >= b and ch >= 12:
		return (*hsl_to_rgb(0.55, clamp01(l * 0.95), min(0.55, s + 0.2)), a)
	if l > 0.4 and ch < 35:
		return (*mix_rgb(r, g, b, 200, 210, 230, 0.3), a)
	if l < 0.25:
		return (*mix_rgb(r, g, b, 16, 20, 40, 0.35), a)
	return push_moon_spore(r, g, b, a)


RECOLORERS = {
	("MossBoar", "Hard"): recolor_boar_hard,
	("MossBoar", "Nightmare"): recolor_boar_nightmare,
	("MossShell", "Hard"): recolor_shell_hard,
	("MossShell", "Nightmare"): recolor_shell_nightmare,
	("IronHorn", "Hard"): recolor_horn_hard,
	("IronHorn", "Nightmare"): recolor_horn_nightmare,
	("SporeWidow", "Hard"): recolor_widow_hard,
	("SporeWidow", "Nightmare"): recolor_widow_nightmare,
	("BloodBloom", "Hard"): recolor_bloom_hard,
	("BloodBloom", "Nightmare"): recolor_bloom_nightmare,
	("RuneCarcinos", "Hard"): recolor_carcinos_hard,
	("RuneCarcinos", "Nightmare"): recolor_carcinos_nightmare,
	("MistWyvern", "Hard"): recolor_wyvern_hard,
	("MistWyvern", "Nightmare"): recolor_wyvern_nightmare,
	("MirrorBoa", "Hard"): recolor_boa_hard,
	("MirrorBoa", "Nightmare"): recolor_boa_nightmare,
	("Granvel", "Hard"): recolor_granvel_hard,
	("Granvel", "Nightmare"): recolor_granvel_nightmare,
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
