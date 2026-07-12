#!/usr/bin/env python3
"""Import main-5 job dungeon sprites from Desktop キャラクター zips (P3-ART-CHR-002).

Source anim folders: walk / atack|attack / hurt / death / idle|Idle
Game SpriteFrames: idle(=walk loop), attack, hurt, death
Idle source frames are kept as idle_*.png for later UI use (not the combat loop).
"""
from __future__ import annotations

import shutil
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

DESKTOP = Path("/Users/marte/Desktop/アイコン/キャラクター")
ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "assets" / "characters"
ANIM_ROOT = ROOT / "resources" / "animation"
WORK = Path("/tmp/crownfall_chr_import")
TARGET = 232
PAD_RATIO = 0.08

JOB_MAP = {
	"ソードマン": ("swordsman", "CHR_Swordsman"),
	"レンジャー": ("ranger", "CHR_Ranger"),
	"アルケミスト": ("alchemist", "CHR_Alchemist"),
	"ヴァンガード": ("vanguard", "CHR_Vanguard"),
	"ビーストテイマー": ("beast_tamer", "CHR_BeastTamer"),
}

# source folder name (case-insensitive) -> output stem
ANIM_MAP = {
	"walk": "walk",
	"atack": "attack",
	"attack": "attack",
	"hurt": "hurt",
	"death": "death",
	"idle": "idle",
}

IMPORT_TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid}"
path="res://.godot/imported/{name}-{uid}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://assets/characters/{rel}"
dest_files=["res://.godot/imported/{name}-{uid}.ctex"]

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
"""


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def extract_zips() -> Path:
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)
	for zpath in sorted(DESKTOP.glob("*.zip")):
		name = nfc(zpath.stem)
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
		prefs = ["north-east", "north", "south", "south-east", "east"]
	for pref in prefs:
		if pref in by_name:
			return by_name[pref]
	return dirs[0]


def fit_square(im: Image.Image, size: int = TARGET) -> Image.Image:
	im = im.convert("RGBA")
	alpha = im.split()[-1]
	bbox = alpha.getbbox()
	if bbox is None:
		canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
		return canvas
	cropped = im.crop(bbox)
	cw, ch = cropped.size
	pad = int(max(cw, ch) * PAD_RATIO)
	side = max(cw, ch) + pad * 2
	square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	square.paste(cropped, ((side - cw) // 2, (side - ch) // 2), cropped)
	# NEAREST keeps pixel edges; slight soft when non-integer scale is acceptable
	return square.resize((size, size), Image.Resampling.NEAREST)


def write_import(png_path: Path, job_id: str) -> None:
	rel = f"{job_id}/{png_path.name}"
	uid = f"chr{job_id.replace('_', '')}{png_path.stem}".lower()[:20]
	# stable-ish uid from path
	uid = "uid://c" + "".join(c for c in f"{job_id}{png_path.stem}" if c.isalnum())[:16]
	text = IMPORT_TEMPLATE.format(
		uid=uid.replace("uid://", ""),
		name=png_path.name,
		rel=rel,
	)
	# fix uid line — template embeds uid twice awkwardly; rewrite simply
	uid_body = "".join(c for c in f"{job_id}_{png_path.stem}" if c.isalnum())[:18]
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


def export_anim(job_src: Path, job_id: str, anim_key: str) -> list[str]:
	anim_dir = find_anim_dir(job_src, anim_key)
	if anim_dir is None:
		raise FileNotFoundError(f"{job_id}: missing anim {anim_key}")
	direction = pick_direction(anim_dir, anim_key)
	frames = sorted(direction.glob("frame_*.png"))
	if not frames:
		raise FileNotFoundError(f"{job_id}/{anim_key}: no frames in {direction}")
	out_dir = OUT_ROOT / job_id
	out_dir.mkdir(parents=True, exist_ok=True)
	# clear old numbered frames for this stem
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
		write_import(out, job_id)
		written.append(name)
	print(f"  {job_id}/{anim_key}: {len(written)} from {direction.name}")
	return written


def write_sprite_frames(job_id: str, tres_stem: str, counts: dict[str, int]) -> None:
	"""idle anim uses walk frames; idle_*.png kept on disk for later UI."""
	paths: list[tuple[str, str]] = []
	ext_id = 1
	# walk frames first (mapped to idle)
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
			f'[ext_resource type="Texture2D" path="res://assets/characters/{job_id}/{fname}" id="{eid}"]'
		)
	lines.append("")
	lines.append("[resource]")
	lines.append("animations = [{")

	# idle = walk
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


def process_job(folder_name: str, job_id: str, tres_stem: str) -> None:
	job_src = WORK / folder_name
	if not job_src.exists():
		# fuzzy match NFC
		for p in WORK.iterdir():
			if nfc(p.name) == folder_name:
				job_src = p
				break
	print(f"\n== {folder_name} → {job_id} ==")
	counts = {}
	for key in ("walk", "attack", "hurt", "death", "idle"):
		names = export_anim(job_src, job_id, key)
		counts[key] = len(names)
	write_sprite_frames(job_id, tres_stem, counts)


def main() -> None:
	extract_zips()
	for folder, (job_id, tres_stem) in JOB_MAP.items():
		process_job(folder, job_id, tres_stem)
	# archive old swordsman sheet (no longer referenced)
	sheet = OUT_ROOT / "CHR_Swordsman_Sheet.png"
	if sheet.exists():
		archive = OUT_ROOT / "_omitted"
		archive.mkdir(exist_ok=True)
		dest = archive / "CHR_Swordsman_Sheet.png"
		shutil.move(str(sheet), str(dest))
		imp = OUT_ROOT / "CHR_Swordsman_Sheet.png.import"
		if imp.exists():
			shutil.move(str(imp), str(archive / "CHR_Swordsman_Sheet.png.import"))
		print(f"archived {sheet.name} → _omitted/")
	print("\nDONE")


if __name__ == "__main__":
	main()
