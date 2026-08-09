#!/usr/bin/env python3
"""Stabilize enemy battle-sheet anims by dropping zoom-pulse frames.

PixelLab ENM strips sometimes shrink the body toward the feet (looks like
scale pulse). Upscaling fattens the silhouette; instead, replace unstable
cells by cycling stable early frames (height within --max-dh of that
anim's frame 0).

IMPORTANT: Prefer --anims idle only. Applying a tight --max-dh to attack/hurt
collapses motion into near-static frames (Oldrex regression).

Sheet layout: horizontal 96x96 cells
  idle   = 0..8
  attack = 9..17
  hurt   = 18..26
  death  = 27..35  (left alone by default — intentional shrink)

Usage:
  python3 tools/stabilize_enemy_sheet_scale.py ENM_Oldrex --all-tiers --max-dh 2
  python3 tools/stabilize_enemy_sheet_scale.py ENM_WindRipper --all-tiers --max-dh 10
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

DEFAULT_CELL = 96
DEFAULT_BAND_LEN = 9
DEFAULT_MAX_DH = 1
BATTLE_DIR = Path(__file__).resolve().parents[1] / "assets" / "battle" / "enemies"

ANIM_BANDS: dict[str, int] = {
	"idle": 0,
	"attack": 9,
	"hurt": 18,
	"death": 27,
}


def used_h(cell: Image.Image) -> int:
	bb = cell.split()[-1].getbbox()
	return 0 if bb is None else bb[3] - bb[1]


def stabilize_band(
	cells: list[Image.Image],
	*,
	start: int,
	count: int,
	max_dh: int,
	freeze: bool,
	label: str,
) -> int:
	if start + count > len(cells):
		print(f"  skip {label}: not enough cells", file=sys.stderr)
		return 0
	ref_h = used_h(cells[start])
	if ref_h <= 0:
		print(f"  skip {label}: empty frame 0", file=sys.stderr)
		return 0
	heights = [used_h(cells[start + i]) for i in range(count)]
	if freeze:
		stable = [0]
	else:
		stable = [i for i in range(count) if abs(heights[i] - ref_h) <= max_dh]
		if not stable:
			stable = [0]
	print(
		f"  {label}: ref_h={ref_h} max_dh={max_dh} freeze={freeze} "
		f"h={heights} stable={stable}"
	)
	changed = 0
	for i in range(count):
		src = stable[i % len(stable)]
		if i == src and not freeze:
			continue
		if freeze and i == 0:
			continue
		print(f"    {label}[{i}] <- {label}[{src}] (was h={heights[i]})")
		cells[start + i] = cells[start + src].copy()
		changed += 1
	return changed


def stabilize_sheet(
	path: Path,
	*,
	cell: int,
	band_len: int,
	max_dh: int,
	dry_run: bool,
	freeze: bool,
	anims: list[str],
) -> int:
	im = Image.open(path).convert("RGBA")
	w, h = im.size
	if h != cell:
		print(f"unexpected height {h} (want {cell}): {path}", file=sys.stderr)
		return 1
	n_cells = w // cell
	cells = [im.crop((i * cell, 0, (i + 1) * cell, cell)) for i in range(n_cells)]
	print(f"{path.name}: anims={anims}")
	changed = 0
	for name in anims:
		if name not in ANIM_BANDS:
			print(f"  unknown anim {name}", file=sys.stderr)
			return 1
		changed += stabilize_band(
			cells,
			start=ANIM_BANDS[name],
			count=band_len,
			max_dh=max_dh,
			freeze=freeze,
			label=name,
		)
	if dry_run:
		print(f"  would replace {changed} cells dry_run=True")
		return 0
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	for i, c in enumerate(cells):
		out.paste(c, (i * cell, 0))
	out.save(path)
	print(f"  wrote {path} (replaced {changed})")
	return 0


def enemy_stem(basename: str) -> str:
	stem = basename
	if stem.endswith(".png"):
		stem = stem[: -len(".png")]
	for suffix in ("_Nightmare_Sheet", "_Hard_Sheet", "_Sheet"):
		if stem.endswith(suffix):
			return stem[: -len(suffix)]
	return stem


def resolve_paths(arg: str, all_tiers: bool) -> list[Path]:
	base = Path(arg).name
	if all_tiers:
		stem = enemy_stem(base)
		cands = [
			BATTLE_DIR / f"{stem}_Sheet.png",
			BATTLE_DIR / f"{stem}_Hard_Sheet.png",
			BATTLE_DIR / f"{stem}_Nightmare_Sheet.png",
		]
		found = [p for p in cands if p.is_file()]
		if found:
			return found
	p = Path(arg)
	if not p.is_file():
		candidate = base if base.endswith(".png") else f"{base}.png"
		p = BATTLE_DIR / candidate
		if not p.is_file() and not candidate.endswith("_Sheet.png"):
			p = BATTLE_DIR / f"{enemy_stem(base)}_Sheet.png"
	return [p] if p.is_file() else []


def main() -> int:
	ap = argparse.ArgumentParser(description=__doc__)
	ap.add_argument("sheet", help="Sheet basename or path (e.g. ENM_Oldrex)")
	ap.add_argument("--all-tiers", action="store_true")
	ap.add_argument("--cell", type=int, default=DEFAULT_CELL)
	ap.add_argument("--band-len", type=int, default=DEFAULT_BAND_LEN)
	ap.add_argument(
		"--max-dh",
		type=int,
		default=DEFAULT_MAX_DH,
		help="Keep frames whose body height is within this many px of that anim's frame 0",
	)
	ap.add_argument(
		"--anims",
		default="idle",
		help="Comma list: idle,attack,hurt,death (default: idle)",
	)
	ap.add_argument(
		"--freeze",
		action="store_true",
		help="Replace all band cells with an exact copy of that band's frame 0",
	)
	ap.add_argument("--dry-run", action="store_true")
	args = ap.parse_args()
	anims = [a.strip() for a in str(args.anims).split(",") if a.strip()]
	if not anims:
		print("no anims", file=sys.stderr)
		return 1
	paths = resolve_paths(args.sheet, args.all_tiers)
	if not paths:
		print(f"no sheets found for {args.sheet}", file=sys.stderr)
		return 1
	rc = 0
	for path in paths:
		rc |= stabilize_sheet(
			path,
			cell=args.cell,
			band_len=args.band_len,
			max_dh=0 if args.freeze else args.max_dh,
			dry_run=args.dry_run,
			freeze=args.freeze,
			anims=anims,
		)
	return rc


if __name__ == "__main__":
	raise SystemExit(main())
