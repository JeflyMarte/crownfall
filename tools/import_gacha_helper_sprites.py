#!/usr/bin/env python3
"""Import gacha helper dungeon sprites from ~/Downloads zips.

Same pipeline as import_job_chr_sprites.py (P3-ART-CHR-002):
  walk/attack/hurt/death/idle → assets/characters/{helper_id}/
  SpriteFrames idle(=walk) → resources/animation/CHR_Helper_{suffix}.tres

Optional portrait: ~/Downloads/{名前}.PNG|png → assets/gacha/portraits/ART_HELPER_{id}.png

Usage:
  python3 tools/import_gacha_helper_sprites.py           # all HELPER_MAP with zips present
  python3 tools/import_gacha_helper_sprites.py ホダカ    # one helper only
"""
from __future__ import annotations

import shutil
import sys
import unicodedata
import zipfile
from pathlib import Path

from PIL import Image

DOWNLOADS = Path.home() / "Downloads"
DOWNLOADS_VER2 = DOWNLOADS / "アップデートVer2"
ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "assets" / "characters"
ANIM_ROOT = ROOT / "resources" / "animation"
HELPERS_ROOT = ROOT / "resources" / "gacha_helpers"
PORTRAIT_ROOT = ROOT / "assets" / "gacha" / "portraits"
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
	"レノール": ("helper_k", "CHR_Helper_k"),
	"シアン": ("helper_m", "CHR_Helper_m"),
	"ボルグ": ("helper_n", "CHR_Helper_n"),
	"ネリ": ("helper_o", "CHR_Helper_o"),
	"ホダカ": ("helper_p", "CHR_Helper_p"),
	"トリム": ("helper_q", "CHR_Helper_q"),
	"ブラン": ("helper_r", "CHR_Helper_r"),
	"オルソ": ("helper_s", "CHR_Helper_s"),
}

## 戦闘 idle(=walk) の FPS。既定 8。カクつきやすい個体は上げる。
# 既定 walk speed は 8.0。個別上書きが必要なときだけ追加。
WALK_SPEED_BY_HELPER: dict[str, float] = {}

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


def find_helper_zip(folder_name: str) -> Path | None:
	for base in (DOWNLOADS, DOWNLOADS_VER2):
		if not base.is_dir():
			continue
		for zpath in base.glob("*.zip"):
			if nfc(zpath.stem) == folder_name:
				return zpath
	return None


def extract_zips(only: set[str] | None = None) -> Path:
	if WORK.exists():
		shutil.rmtree(WORK)
	WORK.mkdir(parents=True)
	for folder_name in HELPER_MAP:
		if only is not None and folder_name not in only:
			continue
		zpath = find_helper_zip(folder_name)
		if zpath is None:
			continue
		dest = WORK / folder_name
		dest.mkdir(parents=True, exist_ok=True)
		with zipfile.ZipFile(zpath) as zf:
			zf.extractall(dest)
		print(f"extracted {folder_name} from {zpath.parent.name}")
	return WORK


def find_anim_dir(job_dir: Path, anim_key: str) -> Path | None:
	anims = list(job_dir.rglob("animations"))
	if not anims:
		return None
	root = anims[0]
	unmapped: list[Path] = []
	for child in root.iterdir():
		if not child.is_dir():
			continue
		mapped = ANIM_MAP.get(nfc(child.name).lower())
		if mapped == anim_key:
			return child
		if mapped is None:
			unmapped.append(child)
	## PixelLab が Idle を説明文フォルダ名にする場合（例: シアン）のフォールバック。
	if anim_key == "idle" and unmapped:
		return sorted(unmapped, key=lambda p: p.name)[0]
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


def export_anim(src: Path, folder_id: str, anim_key: str, file_key: str = "") -> list[str]:
	file_key = file_key if file_key else anim_key
	anim_dir = find_anim_dir(src, anim_key)
	if anim_dir is None:
		if anim_key == "death":
			print(f"  {folder_id}/death: fallback to hurt")
			return export_anim(src, folder_id, "hurt", "death")
		raise FileNotFoundError(f"{folder_id}: missing anim {anim_key}")
	direction = pick_direction(anim_dir, anim_key)
	frames = sorted(direction.glob("frame_*.png"))
	if not frames:
		raise FileNotFoundError(f"{folder_id}/{anim_key}: no frames in {direction}")
	out_dir = OUT_ROOT / folder_id
	out_dir.mkdir(parents=True, exist_ok=True)
	for old in out_dir.glob(f"{file_key}_*.png"):
		old.unlink()
	for old in out_dir.glob(f"{file_key}_*.png.import"):
		old.unlink()
	written: list[str] = []
	for i, fp in enumerate(frames):
		im = fit_square(Image.open(fp))
		name = f"{file_key}_{i}.png"
		out = out_dir / name
		im.save(out)
		written.append(name)
	print(f"  {folder_id}/{file_key}: {len(written)} from {direction.name}")
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
	walk_speed = float(WALK_SPEED_BY_HELPER.get(folder_id, 8.0))
	lines.append(f'"frames": [{walk_frames}],')
	lines.append('"loop": true,')
	lines.append('"name": &"idle",')
	lines.append(f'"speed": {walk_speed}')
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


def _set_tres_field(text: str, field: str, value: str) -> str:
	needle = f'{field} = "'
	start = text.find(needle)
	if start < 0:
		raise ValueError(f"missing {field}")
	start += len(needle)
	end = text.find('"', start)
	return text[:start] + value + text[end:]


def find_helper_tres(helper_id: str) -> Path:
	for candidate in (
		HELPERS_ROOT / f"{helper_id}.tres",
		HELPERS_ROOT / "_omitted" / f"{helper_id}.tres",
	):
		if candidate.exists():
			return candidate
	raise FileNotFoundError(f"helper tres not found: {helper_id}")


def patch_helper_tres(helper_id: str, *, sprite_path: str | None = None, portrait_path: str | None = None) -> None:
	tres_path = find_helper_tres(helper_id)
	text = tres_path.read_text(encoding="utf-8")
	if sprite_path is not None:
		text = _set_tres_field(text, "sprite_resource_path", sprite_path)
	if portrait_path is not None:
		text = _set_tres_field(text, "portrait_resource_path", portrait_path)
	tres_path.write_text(text, encoding="utf-8")
	bits: list[str] = []
	if sprite_path:
		bits.append(f"sprite={sprite_path}")
	if portrait_path:
		bits.append(f"portrait={portrait_path}")
	print(f"  patched {tres_path.relative_to(ROOT)} → {', '.join(bits)}")


def find_portrait_source(folder_name: str) -> Path | None:
	for p in DOWNLOADS.iterdir():
		if not p.is_file():
			continue
		if nfc(p.stem) != folder_name:
			continue
		if p.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp"):
			return p
	return None


def import_portrait(folder_name: str, helper_id: str) -> str | None:
	src = find_portrait_source(folder_name)
	if src is None:
		print(f"  portrait: skip (no ~/Downloads/{folder_name}.PNG)")
		return None
	PORTRAIT_ROOT.mkdir(parents=True, exist_ok=True)
	out = PORTRAIT_ROOT / f"ART_HELPER_{helper_id}.png"
	im = Image.open(src).convert("RGBA")
	im.save(out)
	# .import は Godot `--import` に任せる（手書き dest hash は壊れる）
	old_imp = out.with_suffix(out.suffix + ".import")
	if old_imp.exists():
		old_imp.unlink()
	print(f"  portrait: {src.name} → {out.relative_to(ROOT)} ({im.size[0]}x{im.size[1]})")
	return f"res://assets/gacha/portraits/{out.name}"


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
	portrait_path = import_portrait(folder_name, helper_id)
	patch_helper_tres(helper_id, sprite_path=sprite_path, portrait_path=portrait_path)


def main() -> None:
	only: set[str] | None = None
	if len(sys.argv) > 1:
		only = {nfc(a) for a in sys.argv[1:]}
		unknown = only - set(HELPER_MAP)
		if unknown:
			raise SystemExit(f"unknown helper name(s): {sorted(unknown)}")
	extract_zips(only)
	targets = only if only is not None else set(HELPER_MAP)
	present = {nfc(p.name) for p in WORK.iterdir() if p.is_dir()}
	missing = sorted(targets - present)
	if missing:
		raise SystemExit(f"missing zips/folders: {missing}")
	for folder in sorted(targets):
		helper_id, tres_stem = HELPER_MAP[folder]
		process_helper(folder, helper_id, tres_stem)
	print("\nDONE")


if __name__ == "__main__":
	main()
