#!/usr/bin/env python3
"""Recolor Mistfen enemy sheets for Hard / Nightmare tiers only.

Normal sheets are never overwritten. Hard/NM assets are used only on those tiers.
Mirrors tools/recolor_whisperwood_tier_enemies.py (P3-ENEMY-TIER-VAR).
"""
from __future__ import annotations

import colorsys
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ANIM_DIR = ROOT / "resources/animation"
PREVIEW_DIR = Path("/tmp/crownfall_mf_tier_recolor_preview")
ENEMY_DIR = ROOT / "assets/battle/enemies"
BOSS_DIR = ROOT / "assets/battle/bosses"

# (stem, enemy_id, asset_prefix ENM|BOSS, sheet_dir, preview_cell)
ENTRIES: list[tuple[str, str, str, Path, int]] = [
	("BloodLeech", "blood_leech", "ENM", ENEMY_DIR, 96),
	("DeadPoisonFrog", "dead_poison_frog", "ENM", ENEMY_DIR, 96),
	("MistMantis", "mist_mantis", "ENM", ENEMY_DIR, 96),
	("MarshKing", "marsh_king", "ENM", ENEMY_DIR, 96),
	("BonePicker", "bone_picker", "ENM", ENEMY_DIR, 96),
	("MireStriderSpider", "mire_strider_spider", "ENM", ENEMY_DIR, 96),
	("SporeNeedleWasp", "spore_needle_wasp", "ENM", ENEMY_DIR, 96),
	("GreatClaw", "great_claw", "ENM", ENEMY_DIR, 96),
	("Nightfen", "nightfen", "ENM", ENEMY_DIR, 96),
	("Moldgar", "moldgar", "BOSS", BOSS_DIR, 96),
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


def push_mire_crimson(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Hard — swamp bodies toward blood-mire / toxic amber."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 22:
		if l > 0.35:
			return (*mix_rgb(r, g, b, 170, 56, 48, 0.45), a)
		if l > 0.18:
			return (*mix_rgb(r, g, b, 110, 32, 28, 0.42), a)
		return (*mix_rgb(r, g, b, 40, 10, 12, 0.45), a)
	# greens / olive swamp
	if g >= r + 4 and g >= b - 4 and ch >= 12 and l > 0.16:
		return (*hsl_to_rgb(0.04, clamp01(l * 0.9), min(0.75, s + 0.28)), a)
	# purple / dark accents warmer
	if b > r + 8 and b >= g and ch >= 16:
		return (*hsl_to_rgb(0.98, clamp01(l * 0.92), min(0.7, s + 0.2)), a)
	if ch >= 12 and r >= g >= b and l > 0.12:
		return (*hsl_to_rgb(0.02, clamp01(l * 0.95), min(0.65, s + 0.15)), a)
	if l < 0.2:
		return (*mix_rgb(r, g, b, 28, 8, 12, 0.4), a)
	return (*mix_rgb(r, g, b, 56, 22, 24, 0.14), a)


def push_void_mire(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""Nightmare — cold void mire / moon fog."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch < 22:
		if l > 0.35:
			return (*mix_rgb(r, g, b, 72, 110, 180, 0.45), a)
		if l > 0.18:
			return (*mix_rgb(r, g, b, 32, 56, 110, 0.42), a)
		return (*mix_rgb(r, g, b, 12, 16, 40, 0.45), a)
	if g >= r + 4 and g >= b - 4 and ch >= 12:
		return (*hsl_to_rgb(0.55, clamp01(l * 0.92), min(0.55, s + 0.2)), a)
	if b > r and ch >= 14:
		return (*hsl_to_rgb(0.7, clamp01(l * 0.95), min(0.6, s + 0.15)), a)
	if ch >= 12 and l > 0.16:
		return (*hsl_to_rgb(0.62, clamp01(l * 0.92), min(0.55, s + 0.12)), a)
	if l < 0.22:
		return (*mix_rgb(r, g, b, 10, 14, 36, 0.45), a)
	return (*mix_rgb(r, g, b, 48, 56, 96, 0.2), a)


def recolor_leech_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血蛭 — deepen existing red body."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 16 and r > g + 8 and r > b:
		nr, ng, nb = hsl_to_rgb(0.0, clamp01(l * 0.88), min(0.9, s + 0.2))
		if l > 0.5:
			nr, ng, nb = mix_rgb(nr, ng, nb, 255, 72, 96, 0.3)
		return nr, ng, nb, a
	return push_mire_crimson(r, g, b, a)


def recolor_leech_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""月蛭 — red → violet-blue blood."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 14 and r > g and r > b:
		return (*hsl_to_rgb(0.72, clamp01(0.28 + l * 0.45), min(0.6, s + 0.15)), a)
	return push_void_mire(r, g, b, a)


def recolor_frog_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""紅毒 — olive poison → crimson toxin."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if g >= r - 5 and g >= b and ch >= 14 and l > 0.2:
		return (*hsl_to_rgb(0.05, clamp01(l * 0.9), min(0.8, s + 0.3)), a)
	return push_mire_crimson(r, g, b, a)


def recolor_frog_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼毒 — olive → cyan-toxic."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if g >= r - 5 and g >= b and ch >= 14 and l > 0.2:
		return (*hsl_to_rgb(0.5, clamp01(l * 0.95), min(0.7, s + 0.25)), a)
	return push_void_mire(r, g, b, a)


def recolor_mantis_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_mire_crimson(r, g, b, a)


def recolor_mantis_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_void_mire(r, g, b, a)


def recolor_marsh_king_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_mire_crimson(r, g, b, a)


def recolor_marsh_king_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_void_mire(r, g, b, a)


def recolor_bone_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血骨 — bone pale → stained crimson."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.42 and ch < 45:
		return (*mix_rgb(r, g, b, 220, 170, 160, 0.4), a)
	return push_mire_crimson(r, g, b, a)


def recolor_bone_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""幽骨 — bone → moon pale."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.42 and ch < 45:
		return (*mix_rgb(r, g, b, 190, 210, 230, 0.4), a)
	return push_void_mire(r, g, b, a)


def recolor_spider_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_mire_crimson(r, g, b, a)


def recolor_spider_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_void_mire(r, g, b, a)


def recolor_wasp_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""朱針 — amber body hotter."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.35 and ch >= 14:
		return (*hsl_to_rgb(0.05, clamp01(l * 0.92), min(0.85, s + 0.3)), a)
	return push_mire_crimson(r, g, b, a)


def recolor_wasp_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼針 — amber → ice cyan."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.35 and ch >= 12:
		return (*hsl_to_rgb(0.52, clamp01(l * 0.95), min(0.7, s + 0.25)), a)
	return push_void_mire(r, g, b, a)


def recolor_claw_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""血爪 — blade / carapace rust-blood."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and ch < 40:
		return (*mix_rgb(r, g, b, 200, 120, 110, 0.4), a)
	return push_mire_crimson(r, g, b, a)


def recolor_claw_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""月爪 — steel-blue blades."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if l > 0.4 and ch < 40:
		return (*mix_rgb(r, g, b, 160, 190, 230, 0.4), a)
	return push_void_mire(r, g, b, a)


def recolor_nightfen_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_mire_crimson(r, g, b, a)


def recolor_nightfen_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	return push_void_mire(r, g, b, a)


def recolor_moldgar_hard(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""紅泥 — purple muck → blood crystal mud."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 24 and b > g and (b > r - 10):
		nr, ng, nb = hsl_to_rgb(0.0, clamp01(0.28 + l * 0.5), min(0.9, max(0.4, s)))
		if l > 0.55:
			nr, ng, nb = mix_rgb(nr, ng, nb, 255, 96, 120, 0.35)
		return nr, ng, nb, a
	if l > 0.4 and ch < 40:
		return (*mix_rgb(r, g, b, 210, 160, 150, 0.25), a)
	return push_mire_crimson(r, g, b, a)


def recolor_moldgar_nightmare(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
	"""蒼泥 — purple → moon cyan abyss."""
	if a < 8:
		return r, g, b, a
	h, l, s = rgb_to_hsl(r, g, b)
	ch = chroma(r, g, b)
	if ch >= 24 and b > g and (b > r - 10):
		nr, ng, nb = hsl_to_rgb(0.55, clamp01(0.32 + l * 0.45), min(0.75, max(0.35, s)))
		if l > 0.55:
			nr, ng, nb = mix_rgb(nr, ng, nb, 190, 230, 255, 0.4)
		return nr, ng, nb, a
	if l > 0.4 and ch < 40:
		return (*mix_rgb(r, g, b, 180, 200, 230, 0.3), a)
	if l < 0.25:
		return (*mix_rgb(r, g, b, 12, 16, 40, 0.4), a)
	return push_void_mire(r, g, b, a)


RECOLORERS = {
	("BloodLeech", "Hard"): recolor_leech_hard,
	("BloodLeech", "Nightmare"): recolor_leech_nightmare,
	("DeadPoisonFrog", "Hard"): recolor_frog_hard,
	("DeadPoisonFrog", "Nightmare"): recolor_frog_nightmare,
	("MistMantis", "Hard"): recolor_mantis_hard,
	("MistMantis", "Nightmare"): recolor_mantis_nightmare,
	("MarshKing", "Hard"): recolor_marsh_king_hard,
	("MarshKing", "Nightmare"): recolor_marsh_king_nightmare,
	("BonePicker", "Hard"): recolor_bone_hard,
	("BonePicker", "Nightmare"): recolor_bone_nightmare,
	("MireStriderSpider", "Hard"): recolor_spider_hard,
	("MireStriderSpider", "Nightmare"): recolor_spider_nightmare,
	("SporeNeedleWasp", "Hard"): recolor_wasp_hard,
	("SporeNeedleWasp", "Nightmare"): recolor_wasp_nightmare,
	("GreatClaw", "Hard"): recolor_claw_hard,
	("GreatClaw", "Nightmare"): recolor_claw_nightmare,
	("Nightfen", "Hard"): recolor_nightfen_hard,
	("Nightfen", "Nightmare"): recolor_nightfen_nightmare,
	("Moldgar", "Hard"): recolor_moldgar_hard,
	("Moldgar", "Nightmare"): recolor_moldgar_nightmare,
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
