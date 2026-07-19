#!/usr/bin/env python3
"""Import gacha helper dungeon sprites from ~/Downloads zips.

Same pipeline as import_job_chr_sprites.py (P3-ART-CHR-002):
  walk/attack/hurt/death/idle → assets/characters/{helper_id}/
  SpriteFrames idle(=walk) → resources/animation/CHR_Helper_{suffix}.tres
"""
from __future__ import annotations

import shutil
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

DOWNLOADS = Path.home() / "Downloads"
ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "assets" / "characters"
ANIM_ROOT = ROOT / "resources" / "animation"
HELPERS_ROOT = ROOT / "resources" / "gacha_helpers"
WORK = Path("/tmp/crownfall_gacha_helper_import")
TARGET = 232
PAD_RATIO = 0.08

# NFC display name → (helper_id, tres_stem)
HELPER_MAP = {
	"ヴァルデン": ("helper_a", "CHR_Helper_a"),
	"イヴァル": ("helper_b", "CHR_Helper_b"),
	"セリン": ("helper_c", "CHR_Helper_c"),
	"ミラ": ("helper_e", "CHR_Helper_e"),
	"カイダ": ("helper_f", "CHR_Helper_f"),
	"ガルム": ("helper_i", "CHR_Helper_i"),
}

ANIM_MAP = {
	"walk": "walk",
	"atack": "attack",
	"attack": "attack",
	"hurt": "hurt",
	"death": "death",
	"idle": "idle",
}


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def extract_zips() -> Path:
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)
	for zpath in sorted(DOWNLOADS.glob("*.zip")):
		name = nfc(zpath.stem)
		if name not in HELPER_MAP:
			continue
		dest = WORK / name
		dest.mkdir(parents=True, exist_ok=True)
		with zipfile.ZipFile(zpath) as zf:
			zf.extractall(dest)
		print(f"extracted {name}")
	return WORK


def find_anim_dir(job_dir: Path, anim_key: str) -> Path | None:
	anims = list(job_dir.rglob("animations"))
	if not anims:
		return None
	root = anims[0]
	for child in root.iterdir():
		if not child.is_dir():
			continue
		mapped = ANIM_MAP.get(nfc(child.name).lower())
		if mapped == anim_key:
			return child
	return None


def pick_direction(anim_dir: Path, anim_key: str) -> Path:
	dirs = [d for d in anim_dir.iterdir() if d.is_dir()]
	if not dirs:
		raise FileNotFoundError(f"no direction under {anim_dir}")
	by_name = {d.name: d for d in dirs}
	if anim_key == "idle":
		prefs = ["south", "south-east", "north-east", "north", "east"]
	else:
		prefs = ["north-east", "north", "south", "south-east", "east", "north-west"]
	for pref in prefs:
		if pref in by_name:
			return by_name[pref]
	return dirs[0]


def fit_square(im: Image.Image, size: int = TARGET) -> Image.Image:
	im = im.convert("RGBA")
	alpha = im.split()[-1]
	bbox = alpha.getbbox()
	if bbox is None:
		return Image.new("RGBA", (size, size), (0, 0, 0, 0))
	cropped = im.crop(bbox)
	cw, ch = cropped.size
	pad = int(max(cw, ch) * PAD_RATIO)
	side = max(cw, ch) + pad * 2
	square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	square.paste(cropped, ((side - cw) // 2, (side - ch) // 2), cropped)
	return square.resize((size, size), Image.Resampling.NEAREST)


def write_import(png_path: Path, folder_id: str) -> None:
	rel = f"{folder_id}/{png_path.name}"
	uid_body = "".join(c for c in f"{folder_id}_{png_path.stem}" if c.isalnum())[:18]
	imp = png_path.with_suffix(png_path.suffix + ".import")
	imp.write_text(
		f"""[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid_body}"
path="res://.godot/imported/{png_path.name}-{uid_body}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://assets/characters/{rel}"
dest_files=["res://.godot/imported/{png_path.name}-{uid_body}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_transparent=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
""",
		encoding="utf-8",
	)


def export_anim(src: Path, folder_id: str, anim_key: str) -> list[str]:
	anim_dir = find_anim_dir(src, anim_key)
	if anim_dir is None:
		raise FileNotFoundError(f"{folder_id}: missing anim {anim_key}")
	direction = pick_direction(anim_dir, anim_key)
	frames = sorted(direction.glob("frame_*.png"))
	if not frames:
		raise FileNotFoundError(f"{folder_id}/{anim_key}: no frames in {direction}")
	out_dir = OUT_ROOT / folder_id
	out_dir.mkdir(parents=True, exist_ok=True)
	for old in out_dir.glob(f"{anim_key}_*.png"):
		old.unlink()
	for old in out_dir.glob(f"{anim_key}_*.png.import"):
		old.unlink()
	written: list[str] = []
	for i, fp in enumerate(frames):
		im = fit_square(Image.open(fp))
		name = f"{anim_key}_{i}.png"
		out = out_dir / name
		im.save(out)
		write_import(out, folder_id)
		written.append(name)
	print(f"  {folder_id}/{anim_key}: {len(written)} from {direction.name}")
	return written


def write_sprite_frames(folder_id: str, tres_stem: str, counts: dict[str, int]) -> str:
	paths: list[tuple[str, str]] = []
	ext_id = 1
	for i in range(counts["walk"]):
		paths.append((f"walk_{i}.png", str(ext_id)))
		ext_id += 1
	for anim in ("attack", "hurt", "death"):
		for i in range(counts[anim]):
			paths.append((f"{anim}_{i}.png", str(ext_id)))
			ext_id += 1

	lines = [f'[gd_resource type="SpriteFrames" load_steps={len(paths) + 1} format=3]', ""]
	for fname, eid in paths:
		lines.append(
			f'[ext_resource type="Texture2D" path="res://assets/characters/{folder_id}/{fname}" id="{eid}"]'
		)
	lines.append("")
	lines.append("[resource]")
	lines.append("animations = [{")

	walk_n = counts["walk"]
	walk_frames = ", ".join(
		f'{{"duration": 1.0, "texture": ExtResource("{i}")}}' for i in range(1, walk_n + 1)
	)
	lines.append(f'"frames": [{walk_frames}],')
	lines.append('"loop": true,')
	lines.append('"name": &"idle",')
	lines.append('"speed": 8.0')
	lines.append("}, {")

	cursor = walk_n + 1
	specs = [
		("attack", counts["attack"], 14.0, False),
		("hurt", counts["hurt"], 12.0, False),
		("death", counts["death"], 8.0, False),
	]
	for idx, (name, n, speed, loop) in enumerate(specs):
		fr = ", ".join(
			f'{{"duration": 1.0, "texture": ExtResource("{cursor + j}")}}' for j in range(n)
		)
		cursor += n
		lines.append(f'"frames": [{fr}],')
		lines.append(f'"loop": {"true" if loop else "false"},')
		lines.append(f'"name": &"{name}",')
		lines.append(f'"speed": {speed}')
		if idx < len(specs) - 1:
			lines.append("}, {")
		else:
			lines.append("}]")
	lines.append("")

	out = ANIM_ROOT / f"{tres_stem}.tres"
	out.write_text("\n".join(lines) + "\n", encoding="utf-8")
	print(f"  wrote {out.relative_to(ROOT)}")
	return f"res://resources/animation/{tres_stem}.tres"


def patch_helper_tres(helper_id: str, sprite_path: str) -> None:
	tres_path = HELPERS_ROOT / f"{helper_id}.tres"
	if not tres_path.exists():
		raise FileNotFoundError(tres_path)
	text = tres_path.read_text(encoding="utf-8")
	needle = 'sprite_resource_path = "'
	start = text.find(needle)
	if start < 0:
		raise ValueError(f"{tres_path}: missing sprite_resource_path")
	start += len(needle)
	end = text.find('"', start)
	text = text[:start] + sprite_path + text[end:]
	tres_path.write_text(text, encoding="utf-8")
	print(f"  patched {tres_path.relative_to(ROOT)} → {sprite_path}")


def process_helper(folder_name: str, helper_id: str, tres_stem: str) -> None:
	src = WORK / folder_name
	if not src.exists():
		for p in WORK.iterdir():
			if nfc(p.name) == folder_name:
				src = p
				break
	print(f"\n== {folder_name} → {helper_id} ==")
	counts: dict[str, int] = {}
	for key in ("walk", "attack", "hurt", "death", "idle"):
		names = export_anim(src, helper_id, key)
		counts[key] = len(names)
	sprite_path = write_sprite_frames(helper_id, tres_stem, counts)
	patch_helper_tres(helper_id, sprite_path)


def main() -> None:
	extract_zips()
	missing = [n for n in HELPER_MAP if not any(nfc(p.name) == n for p in WORK.iterdir())]
	if missing:
		raise SystemExit(f"missing zips/folders: {missing}")
	for folder, (helper_id, tres_stem) in HELPER_MAP.items():
		process_helper(folder, helper_id, tres_stem)
	print("\nDONE")


if __name__ == "__main__":
	main()
