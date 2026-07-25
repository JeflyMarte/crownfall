#!/usr/bin/env python3
"""Build ENM_*_Sheet.png + ENM_*.tres from a PixelLab object export zip or frame dirs.

Expected layout after unzip:
  rotations/unknown.png  (or south.png)
  animations/<uuid_or_name>/unknown/{0..n}.png  with display names idle/attack/hurt/death
  OR flat: idle_0.png ... via --frames-dir

Usage:
  python3 tools/build_enemy_sheet_from_pixellab.py \\
    --pascal DreadJaw --zip /tmp/dreadjaw.zip
"""
from __future__ import annotations

import argparse
import json
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BATTLE = ROOT / "assets/battle/enemies"
ANIM = ROOT / "resources/animation"
FRAME = 96
ORDER = ("idle", "attack", "hurt", "death")
COUNTS = {"idle": 4, "attack": 4, "hurt": 2, "death": 4}
SPEED = {"idle": 6.0, "attack": 10.0, "hurt": 8.0, "death": 6.0}


def fit(img: Image.Image) -> Image.Image:
	img = img.convert("RGBA")
	bbox = img.getbbox()
	if bbox is None:
		return Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
	c = img.crop(bbox)
	cw, ch = c.size
	margin = int(FRAME * 0.08)
	target = FRAME - margin * 2
	ratio = min(target / cw, target / ch)
	nw, nh = max(1, int(cw * ratio)), max(1, int(ch * ratio))
	r = c.resize((nw, nh), Image.Resampling.NEAREST)
	out = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
	out.paste(r, ((FRAME - nw) // 2, FRAME - nh - margin), r)
	return out


def guess_anim_key(folder_name: str) -> str | None:
	low = folder_name.lower()
	if low in ORDER:
		return low
	# Attack before idle: descriptions may include "pulse" + "strike".
	if "attack" in low or "bite" in low or "lash" in low or "strike" in low or "smash" in low or "crush" in low:
		return "attack"
	if "hurt" in low or "flinch" in low or "hit" in low or "recoil" in low:
		return "hurt"
	if "death" in low or "collapse" in low or "defeat" in low or "sink" in low or "fade" in low:
		return "death"
	if "idle" in low or "swim" in low or "breath" in low or "pulse" in low or "float" in low or "writh" in low:
		return "idle"
	return None


def collect_from_zip(zpath: Path) -> dict[str, list[Image.Image]]:
	work = Path("/tmp/crownfall_pixellab_obj") / zpath.stem
	if work.exists():
		import shutil

		shutil.rmtree(work)
	work.mkdir(parents=True)
	with zipfile.ZipFile(zpath) as zf:
		zf.extractall(work)
	frames: dict[str, list[Image.Image]] = {k: [] for k in ORDER}
	anim_root = None
	for p in work.rglob("animations"):
		if p.is_dir():
			anim_root = p
			break
	if anim_root is None:
		raise SystemExit(f"no animations/ in {zpath}")
	for sub in sorted(anim_root.iterdir()):
		if not sub.is_dir():
			continue
		key = guess_anim_key(sub.name)
		if key is None:
			print(f"  skip unknown anim folder: {sub.name}")
			continue
		seq: list[Path] = []
		for cand in ("unknown", "south", "south-west"):
			d = sub / cand
			if d.is_dir():
				seq = sorted(
					d.glob("*.png"),
					key=lambda p: int("".join(ch for ch in p.stem if ch.isdigit()) or "0"),
				)
				break
		if not seq:
			seq = sorted(sub.rglob("*.png"), key=lambda p: p.name)
		for fp in seq:
			frames[key].append(fit(Image.open(fp)))
	if not frames["idle"]:
		for cand in work.rglob("rotations"):
			for name in ("unknown.png", "south.png", "south-west.png"):
				fp = cand / name
				if fp.exists():
					frames["idle"] = [fit(Image.open(fp))] * COUNTS["idle"]
					break
	return frames


def trim_to_counts(frames: dict[str, list[Image.Image]]) -> list[Image.Image]:
	out: list[Image.Image] = []
	for key in ORDER:
		need = COUNTS[key]
		seq = frames.get(key) or []
		if not seq:
			blank = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
			seq = [blank]
		# pick evenly
		if len(seq) >= need:
			idxs = [int(i * (len(seq) - 1) / max(1, need - 1)) for i in range(need)]
			picked = [seq[i] for i in idxs]
		else:
			picked = list(seq)
			while len(picked) < need:
				picked.append(seq[-1])
		# hurt only 2 frames in Undertaker layout
		if key == "hurt":
			picked = picked[:2]
		out.extend(picked)
	return out


def write_sheet(pascal: str, frames: list[Image.Image], *, boss: bool = False) -> Path:
	outdir = ROOT / "assets/battle/bosses" if boss else BATTLE
	outdir.mkdir(parents=True, exist_ok=True)
	sheet = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
	for i, fr in enumerate(frames):
		sheet.paste(fr, (i * FRAME, 0), fr)
	prefix = "BOSS" if boss else "ENM"
	path = outdir / f"{prefix}_{pascal}_Sheet.png"
	sheet.save(path)
	return path


def write_tres(pascal: str, n_frames: int, *, boss: bool = False) -> Path:
	"""14-frame Undertaker layout: idle4 attack4 hurt2 death4."""
	prefix = "BOSS" if boss else "ENM"
	subdir = "bosses" if boss else "enemies"
	tex_path = f"res://assets/battle/{subdir}/{prefix}_{pascal}_Sheet.png"
	lines = [
		'[gd_resource type="SpriteFrames" load_steps=2 format=3]',
		"",
		f'[ext_resource type="Texture2D" path="{tex_path}" id="1_sheet"]',
		"",
	]
	for i in range(n_frames):
		lines += [
			f'[sub_resource type="AtlasTexture" id="i{i}"]',
			"atlas = ExtResource(\"1_sheet\")",
			f"region = Rect2({i * FRAME}, 0, {FRAME}, {FRAME})",
			"",
		]
	# Build animations JSON-like Godot
	def refs(start: int, count: int) -> str:
		parts = [f'{{"duration": 1.0, "texture": SubResource("i{i}") }}' for i in range(start, start + count)]
		return "[" + ", ".join(parts) + "]"

	anims = (
		f'[{{"frames": {refs(0, 4)}, "loop": true, "name": &"idle", "speed": 6.0}}, '
		f'{{"frames": {refs(4, 4)}, "loop": false, "name": &"attack", "speed": 10.0}}, '
		f'{{"frames": {refs(8, 2)}, "loop": false, "name": &"hurt", "speed": 8.0}}, '
		f'{{"frames": {refs(10, 4)}, "loop": false, "name": &"death", "speed": 6.0}}]'
	)
	lines += ["[resource]", f"animations = {anims}", ""]
	ANIM.mkdir(parents=True, exist_ok=True)
	path = ANIM / f"{prefix}_{pascal}.tres"
	path.write_text("\n".join(lines))
	return path


def main() -> int:
	ap = argparse.ArgumentParser()
	ap.add_argument("--pascal", required=True)
	ap.add_argument("--zip", type=Path, required=True)
	ap.add_argument("--boss", action="store_true", help="Write BOSS_* under assets/battle/bosses")
	args = ap.parse_args()
	frames_map = collect_from_zip(args.zip)
	# Print what we got
	for k in ORDER:
		print(f"  {k}: {len(frames_map.get(k) or [])} frames")
	flat = trim_to_counts(frames_map)
	sheet = write_sheet(args.pascal, flat, boss=args.boss)
	tres = write_tres(args.pascal, len(flat), boss=args.boss)
	print(f"wrote {sheet} ({sheet.stat().st_size} bytes)")
	print(f"wrote {tres}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
