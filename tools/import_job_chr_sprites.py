#!/usr/bin/env python3
"""Import job dungeon sprites from Desktop character zips (P3-ART-CHR-002).

Sources (first existing wins):
  - Desktop/キャラドット/*.zip  （キャラ名: リーヴァ／ガレン …）
  - Desktop/アイコン/キャラクター/*.zip  （職名: レンジャー／ヴァンガード …）

Source anim folders: walk / atack|attack / hurt / death / idle|Idle
Game SpriteFrames: idle(=walk loop), attack, hurt, death
Idle source frames are kept as idle_*.png for later UI use (not the combat loop).
"""
from __future__ import annotations

import argparse
import shutil
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "assets" / "characters"
ANIM_ROOT = ROOT / "resources" / "animation"
WORK = Path("/tmp/crownfall_chr_import")
TARGET = 232
PAD_RATIO = 0.08
## 職ごとに枠内の見た目サイズを微調整（1.0=標準。>1 でドットを大きく・端はクリップ可）。
JOB_FILL_SCALE = {
	"vanguard": 1.12,
}

DESKTOP_CANDIDATES = [
	Path("/Users/marte/Desktop/キャラドット"),
	Path("/Users/marte/Desktop/アイコン/キャラクター"),
]

## zip stem（NFC）→ (job_id, SpriteFrames stem)
ZIP_MAP = {
	"リーヴァ": ("ranger", "CHR_Ranger"),
	"ガレン": ("vanguard", "CHR_Vanguard"),
	"アルド": ("swordsman", "CHR_Swordsman"),
	"エリアス": ("alchemist", "CHR_Alchemist"),
	"ミレイ": ("beast_tamer", "CHR_BeastTamer"),
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


def nfc(s: str) -> str:
	return unicodedata.normalize("NFC", s)


def resolve_desktop() -> Path:
	for p in DESKTOP_CANDIDATES:
		if p.is_dir() and any(p.glob("*.zip")):
			return p
	raise FileNotFoundError(
		"Desktop zip folder not found. Tried:\n  " + "\n  ".join(str(p) for p in DESKTOP_CANDIDATES)
	)


def extract_zips(desktop: Path, only: set[str] | None) -> Path:
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)
	for zpath in sorted(desktop.glob("*.zip")):
		name = nfc(zpath.stem)
		if only is not None and name not in only:
			continue
		if name not in ZIP_MAP:
			print(f"skip unknown zip: {name}")
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
		prefs = ["north-east", "north", "south", "south-east", "east"]
	for pref in prefs:
		if pref in by_name:
			return by_name[pref]
	return dirs[0]


def fit_square(
	im: Image.Image, size: int = TARGET, pad_ratio: float = PAD_RATIO, fill_scale: float = 1.0
) -> Image.Image:
	im = im.convert("RGBA")
	alpha = im.split()[-1]
	bbox = alpha.getbbox()
	if bbox is None:
		return Image.new("RGBA", (size, size), (0, 0, 0, 0))
	cropped = im.crop(bbox)
	cw, ch = cropped.size
	pad = int(max(cw, ch) * pad_ratio)
	side = max(cw, ch) + pad * 2
	square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	square.paste(cropped, ((side - cw) // 2, (side - ch) // 2), cropped)
	out_side = max(1, int(round(float(size) * max(0.5, fill_scale))))
	scaled = square.resize((out_side, out_side), Image.Resampling.NEAREST)
	if out_side == size:
		return scaled
	canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	ox = (size - out_side) // 2
	oy = (size - out_side) // 2
	canvas.paste(scaled, (ox, oy), scaled)
	return canvas


def write_import(png_path: Path, job_id: str) -> None:
	rel = f"{job_id}/{png_path.name}"
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
	fill_scale: float = float(JOB_FILL_SCALE.get(job_id, 1.0))
	for i, fp in enumerate(frames):
		im = fit_square(Image.open(fp), fill_scale=fill_scale)
		name = f"{anim_key}_{i}.png"
		out = out_dir / name
		im.save(out)
		write_import(out, job_id)
		written.append(name)
	print(f"  {job_id}/{anim_key}: {len(written)} from {direction.name} (fill={fill_scale})")
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
	if not job_src.exists():
		raise FileNotFoundError(f"extracted folder missing: {folder_name}")
	print(f"\n== {folder_name} → {job_id} ==")
	counts = {}
	for key in ("walk", "attack", "hurt", "death", "idle"):
		names = export_anim(job_src, job_id, key)
		counts[key] = len(names)
	write_sprite_frames(job_id, tres_stem, counts)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument(
		"--only",
		nargs="+",
		default=None,
		help="Import only these zip stems (NFC), e.g. リーヴァ ガレン",
	)
	parser.add_argument(
		"--desktop",
		type=Path,
		default=None,
		help="Override Desktop zip folder",
	)
	args = parser.parse_args()
	desktop = args.desktop if args.desktop is not None else resolve_desktop()
	only = {nfc(x) for x in args.only} if args.only else None
	print(f"desktop: {desktop}")
	extract_zips(desktop, only)
	targets = only if only is not None else set(ZIP_MAP.keys())
	for folder in sorted(targets):
		if folder not in ZIP_MAP:
			raise SystemExit(f"unknown character/job zip: {folder}")
		job_id, tres_stem = ZIP_MAP[folder]
		src = WORK / folder
		if not src.exists():
			# skip missing when importing all from mixed desktop
			if only is None:
				print(f"skip missing extract: {folder}")
				continue
			raise FileNotFoundError(f"zip not extracted: {folder}")
		process_job(folder, job_id, tres_stem)
	print("\nDONE")


if __name__ == "__main__":
	main()
