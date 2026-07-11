#!/usr/bin/env python3
"""Generate tinted mourngate enemy variants from base sheets and portraits."""
from __future__ import annotations

import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MOURNGATE_DIR = ROOT / "assets/dungeon/mourngate"
CODEX_DIR = ROOT / "assets/codex/enemies"
ANIM_DIR = ROOT / "resources/animation"

FRAME = 96
TOTAL_FRAMES = 14

VARIANTS: dict[str, dict] = {
	"corrosion_death_hound": {
		"source": "sepia_hound",
		"tint": (220, 140, 90),
	},
	"bone_roach": {
		"source": "rune_roach",
		"tint": (240, 235, 220),
	},
	"acid_crystal_needle_rat": {
		"source": "crystal_hedgehog",
		"tint": (170, 220, 110),
	},
	"ancient_tome_giant_rat": {
		"source": "crown_eater_rat",
		"tint": (225, 205, 145),
	},
	"old_clock_moth": {
		"source": "clock_moth",
		"tint": (200, 155, 115),
	},
}


def snake_to_pascal(snake: str) -> str:
	return "".join(part.capitalize() for part in snake.split("_"))


def tint_image(img: Image.Image, tint: tuple[int, int, int]) -> Image.Image:
	out = img.convert("RGBA")
	px = out.load()
	tr, tg, tb = tint
	w, h = out.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a > 0:
				px[x, y] = (
					min(255, int(r * tr / 255)),
					min(255, int(g * tg / 255)),
					min(255, int(b * tb / 255)),
					a,
				)
	return out


def source_sheet_path(source_id: str) -> Path:
	return MOURNGATE_DIR / f"ENM_{snake_to_pascal(source_id)}_Sheet.png"


def source_portrait_path(source_id: str) -> Path:
	return CODEX_DIR / f"ART_ENM_{snake_to_pascal(source_id)}.png"


def write_spriteframes(sheet_res: str, tres_path: Path) -> None:
	regions: list[tuple[str, int]] = []
	idx = 0
	for anim, count in (("idle", 4), ("attack", 4), ("hurt", 2), ("death", 4)):
		for _ in range(count):
			regions.append((anim, idx))
			idx += 1

	lines = [
		'[gd_resource type="SpriteFrames" load_steps=2 format=3]',
		"",
		f'[ext_resource type="Texture2D" path="{sheet_res}" id="1_sheet"]',
		"",
	]
	sub_ids: list[str] = []
	for i in range(TOTAL_FRAMES):
		sub_ids.append(f"i{i}")
		x = i * FRAME
		lines.extend(
			[
				f'[sub_resource type="AtlasTexture" id="{sub_ids[-1]}"]',
				'atlas = ExtResource("1_sheet")',
				f"region = Rect2({x}, 0, {FRAME}, {FRAME})",
				"",
			]
		)

	anims: dict[str, list[str]] = {"idle": [], "attack": [], "hurt": [], "death": []}
	for anim, frame_idx in regions:
		anims[anim].append(sub_ids[frame_idx])

	anim_blocks = []
	for name, speed, loop in (("idle", 6.0, True), ("attack", 10.0, False), ("hurt", 8.0, False), ("death", 6.0, False)):
		frame_objs = ", ".join(
			f'{{"duration": 1.0, "texture": SubResource("{sid}") }}' for sid in anims[name]
		)
		anim_blocks.append(
			f'{{"frames": [{frame_objs}], "loop": {"true" if loop else "false"}, "name": &"{name}", "speed": {speed}}}'
		)

	lines.append("[resource]")
	lines.append("animations = [" + ", ".join(anim_blocks) + "]")
	lines.append("")
	tres_path.write_text("\n".join(lines), encoding="utf-8")


def generate_variant(variant_id: str, config: dict) -> str:
	source_id: str = str(config["source"])
	tint: tuple[int, int, int] = tuple(config["tint"])
	pascal = snake_to_pascal(variant_id)

	sheet_src = source_sheet_path(source_id)
	if not sheet_src.exists():
		raise FileNotFoundError(sheet_src)
	sheet_out = MOURNGATE_DIR / f"ENM_{pascal}_Sheet.png"
	tint_image(Image.open(sheet_src), tint).save(sheet_out, "PNG")
	print(f"  sheet {variant_id} <- {source_id}")

	portrait_src = source_portrait_path(source_id)
	if portrait_src.exists():
		portrait_out = CODEX_DIR / f"ART_ENM_{pascal}.png"
		tint_image(Image.open(portrait_src), tint).save(portrait_out, "PNG")
		print(f"  portrait {variant_id}")

	tres = ANIM_DIR / f"ENM_{pascal}.tres"
	sheet_res = f"res://assets/dungeon/mourngate/ENM_{pascal}_Sheet.png"
	write_spriteframes(sheet_res, tres)
	return f"res://resources/animation/ENM_{pascal}.tres"


def update_enemy_sprite_map(entries: dict[str, str]) -> None:
	path = ROOT / "scripts/dungeon/DungeonScene.gd"
	text = path.read_text(encoding="utf-8")
	match = re.search(r"(const ENEMY_SPRITE_MAP: Dictionary = \{)([\s\S]*?)(\n\})", text)
	if match is None:
		raise RuntimeError("ENEMY_SPRITE_MAP not found")
	body = match.group(2)
	for enemy_id, tres in sorted(entries.items()):
		line = f'\t"{enemy_id}": "{tres}",'
		if f'"{enemy_id}"' not in body:
			body += f"\n{line}"
	text = text[: match.start(2)] + body + text[match.start(3) :]
	path.write_text(text, encoding="utf-8")


def update_icon_paths(entries: dict[str, str]) -> None:
	path = ROOT / "scripts/ui/IconPaths.gd"
	text = path.read_text(encoding="utf-8")
	for enemy_id, icon_path in sorted(entries.items()):
		key = f'"enemy:{enemy_id}"'
		line = f'\t{key}: "{icon_path}",'
		if key not in text:
			anchor = '\t"enemy:clock_moth"'
			if anchor in text:
				text = text.replace(anchor, f"{line}\n{anchor}", 1)
			else:
				text = text.rstrip() + f"\n{line}\n"
	path.write_text(text, encoding="utf-8")


def main() -> None:
	anim_paths: dict[str, str] = {}
	icon_paths: dict[str, str] = {}
	for variant_id, config in VARIANTS.items():
		anim_paths[variant_id] = generate_variant(variant_id, config)
		pascal = snake_to_pascal(variant_id)
		icon_paths[variant_id] = f"res://assets/codex/enemies/ART_ENM_{pascal}.png"
	update_enemy_sprite_map(anim_paths)
	update_icon_paths(icon_paths)
	print(f"Generated {len(VARIANTS)} mourngate variants")


if __name__ == "__main__":
	main()
