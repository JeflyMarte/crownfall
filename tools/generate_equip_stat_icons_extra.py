#!/usr/bin/env python3
"""Generate missing Equipment detail stat icons (72×72, unique glyphs).

Does not overwrite hand-drawn ATK/DEF/HP/SPD/CRIT/CRITDMG/ELEMENT/BANE.
Output: assets/ui/equipment_ui/ICO_Equip_Stat_*.png

Usage:
  python3 tools/generate_equip_stat_icons_extra.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/equipment_ui"
STATUS = ROOT / "assets/ui/status"

GOLD = (235, 198, 72)
GOLD_DARK = (140, 110, 40)

# kind_file_stem -> draw function name
ICONS: dict[str, str] = {
	"ATKUP": "attack_up",
	"DEFUP": "defense_up",
	"HPUP": "hp_up",
	"ATKSPD": "attack_speed",
	"ONHIT": "on_hit",
	"GOLD": "gold_gain",
	"EXP": "exp_gain",
	"RAREDROP": "rare_drop",
	"HEAL": "healing",
	"EVADE": "evasion",
	"RESIST": "resist",
	"IMMUNE": "immunity",
	"CHILL": "chill",
	"SHOCK": "shock",
	"IGNITE": "ignite",
	"POISON": "poison",
	"FIRE": "elem_fire",
	"ICE": "elem_ice",
	"THUNDER": "elem_thunder",
	"DARK": "elem_dark",
	"HOLY": "elem_holy",
}


## 透明キャンバスのみ（手描き ATK/DEF 等と同様、枠・プレート無し）。
def canvas(size: int = 72) -> tuple[Image.Image, ImageDraw.ImageDraw]:
	img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	return img, ImageDraw.Draw(img)


def save(img: Image.Image, name: str) -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	path = OUT / name
	img.save(path, optimize=True)
	print(f"  wrote {path.relative_to(ROOT)} ({img.size[0]}x{img.size[1]})")


def _plus(draw: ImageDraw.ImageDraw, x: int, y: int, color=(255, 230, 140, 255)) -> None:
	draw.rectangle((x - 1, y - 5, x + 1, y + 5), fill=color)
	draw.rectangle((x - 5, y - 1, x + 5, y + 1), fill=color)


def draw_attack_up(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.polygon([(cx - 10, cy + 12), (cx + 10, cy + 12), (cx + 3, cy - 12), (cx - 3, cy - 12)], fill=(*GOLD, 255))
	draw.rectangle((cx - 3, cy - 18, cx + 3, cy - 10), fill=(210, 210, 220, 255))
	_plus(draw, cx + 16, cy - 14)
	return img


def draw_defense_up(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.polygon(
		[(cx, cy - 14), (cx + 14, cy - 4), (cx + 10, cy + 12), (cx - 10, cy + 12), (cx - 14, cy - 4)],
		fill=(100, 125, 170, 255),
		outline=(*GOLD, 255),
		width=2,
	)
	_plus(draw, cx + 16, cy - 14)
	return img


def draw_hp_up(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.polygon(
		[(cx, cy + 12), (cx - 14, cy - 2), (cx - 6, cy - 12), (cx, cy - 6), (cx + 6, cy - 12), (cx + 14, cy - 2)],
		fill=(200, 60, 70, 255),
	)
	_plus(draw, cx + 16, cy - 14)
	return img


def draw_attack_speed(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	# boot / dash chevrons (distinct from SPD wind streaks)
	for i, col in enumerate([(90, 190, 210, 255), (140, 220, 235, 255), (200, 245, 255, 255)]):
		ox = -10 + i * 10
		draw.polygon(
			[(cx + ox - 6, cy + 10), (cx + ox + 2, cy + 10), (cx + ox + 10, cy - 8), (cx + ox + 2, cy - 8)],
			fill=col,
		)
	draw.ellipse((cx + 10, cy + 8, cx + 22, cy + 20), outline=(*GOLD, 220), width=2)
	return img


def draw_on_hit(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.ellipse((cx - 10, cy - 14, cx + 10, cy + 10), fill=(180, 80, 200, 255), outline=(*GOLD, 200), width=2)
	draw.polygon([(cx, cy + 8), (cx - 8, cy + 20), (cx + 8, cy + 20)], fill=(180, 80, 200, 220))
	draw.line((cx - 16, cy - 4, cx - 8, cy + 2), fill=(255, 220, 120, 255), width=3)
	return img


def draw_gold_gain(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(210, 170, 50, 255), outline=(*GOLD, 255), width=2)
	draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), outline=(120, 90, 20, 255), width=2)
	draw.rectangle((cx - 2, cy - 6, cx + 2, cy + 6), fill=(255, 230, 140, 255))
	return img


def draw_exp_gain(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	# open book
	draw.polygon([(cx - 16, cy + 10), (cx, cy + 4), (cx, cy - 12), (cx - 16, cy - 6)], fill=(220, 210, 180, 255))
	draw.polygon([(cx + 16, cy + 10), (cx, cy + 4), (cx, cy - 12), (cx + 16, cy - 6)], fill=(200, 190, 160, 255))
	draw.line((cx, cy - 12, cx, cy + 4), fill=(*GOLD_DARK, 255), width=2)
	# spark
	draw.polygon([(cx, cy - 20), (cx + 3, cy - 14), (cx + 9, cy - 14), (cx + 4, cy - 10), (cx + 6, cy - 4), (cx, cy - 8),
				  (cx - 6, cy - 4), (cx - 4, cy - 10), (cx - 9, cy - 14), (cx - 3, cy - 14)], fill=(*GOLD, 255))
	return img


def draw_rare_drop(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.polygon(
		[(cx, cy - 16), (cx + 12, cy - 4), (cx + 8, cy + 14), (cx - 8, cy + 14), (cx - 12, cy - 4)],
		fill=(120, 200, 255, 255),
		outline=(*GOLD, 255),
		width=2,
	)
	draw.polygon([(cx, cy - 8), (cx + 6, cy + 2), (cx - 6, cy + 2)], fill=(230, 250, 255, 220))
	return img


def draw_healing(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.rounded_rectangle((cx - 6, cy - 16, cx + 6, cy + 14), 3, fill=(70, 180, 110, 255), outline=(*GOLD, 180), width=1)
	draw.ellipse((cx - 10, cy - 20, cx + 10, cy - 8), fill=(90, 200, 130, 255))
	_plus(draw, cx, cy, (255, 255, 240, 255))
	return img


def draw_evasion(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	# silhouette + motion trails (not SPD chevrons)
	draw.ellipse((cx - 6, cy - 16, cx + 6, cy - 4), fill=(180, 180, 200, 255))
	draw.polygon([(cx, cy - 4), (cx - 10, cy + 16), (cx + 10, cy + 16)], fill=(150, 150, 175, 255))
	for i in range(3):
		a = 120 - i * 35
		draw.arc((cx - 22 - i * 2, cy - 10, cx - 6 - i * 2, cy + 14), 200, 320, fill=(180, 200, 255, a), width=2)
	return img


def draw_resist(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.polygon(
		[(cx, cy - 16), (cx + 14, cy - 6), (cx + 10, cy + 14), (cx - 10, cy + 14), (cx - 14, cy - 6)],
		fill=(60, 70, 90, 255),
		outline=(*GOLD, 255),
		width=2,
	)
	# mini orbs (resist = shield vs elements, distinct from ELEMENT rainbow plate)
	cols = [(220, 80, 60), (80, 160, 255), (240, 220, 80)]
	for i, c in enumerate(cols):
		x = cx - 8 + i * 8
		draw.ellipse((x - 3, cy - 2, x + 3, cy + 4), fill=(*c, 255))
	return img


def draw_immunity(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), outline=(120, 220, 160, 255), width=3)
	draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(40, 50, 45, 255))
	draw.line((cx - 8, cy - 8, cx + 8, cy + 8), fill=(255, 120, 100, 255), width=3)
	draw.line((cx + 8, cy - 8, cx - 8, cy + 8), fill=(255, 120, 100, 255), width=3)
	return img


def _embed_status(stem: str, tint: tuple[int, int, int], size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	src = STATUS / f"ICO_STA_{stem}.png"
	if src.exists():
		icon = Image.open(src).convert("RGBA")
		icon = icon.resize((40, 40), Image.Resampling.NEAREST)
		img.alpha_composite(icon, (size // 2 - 20, size // 2 - 20))
	else:
		draw.ellipse((size // 2 - 12, size // 2 - 12, size // 2 + 12, size // 2 + 12), fill=(*tint, 255))
	return img


def draw_chill(size: int = 72) -> Image.Image:
	return _embed_status("Chill", (140, 200, 255), size)


def draw_shock(size: int = 72) -> Image.Image:
	return _embed_status("Shock", (240, 220, 80), size)


def draw_ignite(size: int = 72) -> Image.Image:
	return _embed_status("Ignite", (255, 120, 50), size)


def draw_poison(size: int = 72) -> Image.Image:
	return _embed_status("Poison", (120, 200, 80), size)


def draw_elem_fire(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.polygon(
		[(cx, cy - 18), (cx + 12, cy + 2), (cx + 6, cy + 14), (cx - 6, cy + 14), (cx - 12, cy + 2)],
		fill=(255, 110, 40, 255),
	)
	draw.polygon([(cx, cy - 6), (cx + 5, cy + 8), (cx - 5, cy + 8)], fill=(255, 220, 120, 255))
	return img


def draw_elem_ice(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	for ang in range(0, 360, 60):
		rad = math.radians(ang)
		x2 = cx + math.cos(rad) * 16
		y2 = cy + math.sin(rad) * 16
		draw.line((cx, cy, x2, y2), fill=(160, 210, 255, 255), width=3)
	draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(230, 245, 255, 255))
	return img


def draw_elem_thunder(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.polygon(
		[(cx + 2, cy - 18), (cx - 10, cy + 0), (cx - 2, cy + 0), (cx - 6, cy + 18), (cx + 12, cy - 2), (cx + 2, cy - 2)],
		fill=(255, 230, 80, 255),
		outline=(255, 255, 200, 255),
	)
	return img


def draw_elem_dark(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(50, 30, 70, 255), outline=(160, 100, 200, 255), width=2)
	draw.ellipse((cx - 4, cy - 10, cx + 12, cy + 8), fill=(30, 20, 45, 255))
	draw.ellipse((cx + 4, cy - 6, cx + 8, cy - 2), fill=(220, 180, 255, 255))
	return img


def draw_elem_holy(size: int = 72) -> Image.Image:
	img, draw = canvas(size)
	cx, cy = size // 2, size // 2
	draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(255, 240, 180, 60), outline=(*GOLD, 255), width=2)
	draw.rectangle((cx - 3, cy - 14, cx + 3, cy + 14), fill=(*GOLD, 255))
	draw.rectangle((cx - 14, cy - 3, cx + 14, cy + 3), fill=(*GOLD, 255))
	return img


DRAWERS = {
	"attack_up": draw_attack_up,
	"defense_up": draw_defense_up,
	"hp_up": draw_hp_up,
	"attack_speed": draw_attack_speed,
	"on_hit": draw_on_hit,
	"gold_gain": draw_gold_gain,
	"exp_gain": draw_exp_gain,
	"rare_drop": draw_rare_drop,
	"healing": draw_healing,
	"evasion": draw_evasion,
	"resist": draw_resist,
	"immunity": draw_immunity,
	"chill": draw_chill,
	"shock": draw_shock,
	"ignite": draw_ignite,
	"poison": draw_poison,
	"elem_fire": draw_elem_fire,
	"elem_ice": draw_elem_ice,
	"elem_thunder": draw_elem_thunder,
	"elem_dark": draw_elem_dark,
	"elem_holy": draw_elem_holy,
}


def main() -> int:
	print("=== generate equip stat icons (extra) ===")
	for stem, drawer_key in ICONS.items():
		fn = DRAWERS[drawer_key]
		save(fn(), f"ICO_Equip_Stat_{stem}.png")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
