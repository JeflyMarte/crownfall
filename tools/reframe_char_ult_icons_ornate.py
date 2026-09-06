#!/usr/bin/env python3
"""Align added character ultimate icons to the ornate initial-5 frame.

Extracts the rim+stud chrome from a reference ultimate (DeadEye by default)
and composites unframed interiors from the original art commit onto it.

Does NOT touch initial-5 or engineer ultimates.
"""
from __future__ import annotations

import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "assets/ui/skills"
SIZE = 128
INSET = 14
FEATHER = 3
SRC_COMMIT = "86311c4c"
REF_NAME = "ICO_SKILL_DeadEye.png"

TARGETS = [
	"ICO_SKILL_BreakEdge.png",
	"ICO_SKILL_CriticalStorm.png",
	"ICO_SKILL_MarkShot.png",
	"ICO_SKILL_SilenceWeb.png",
	"ICO_SKILL_IronAura.png",
	"ICO_SKILL_VgGateCounter.png",
	"ICO_SKILL_Heartbeat.png",
	"ICO_SKILL_CurseBurst.png",
	"ICO_SKILL_ElementalBoost.png",
	"ICO_SKILL_PetCommand.png",
	"ICO_SKILL_BloodDrain.png",
]

# Protected — never rewrite
SKIP = {
	"ICO_SKILL_OugaRetsudan.png",
	"ICO_SKILL_TitanRoar.png",
	"ICO_SKILL_GrandElixir.png",
	"ICO_SKILL_DeadEye.png",
	"ICO_SKILL_BeastDominion.png",
	"ICO_SKILL_EngFullArmCascade.png",
	"ICO_SKILL_EngBlazeOverload.png",
	"ICO_SKILL_EngArmorGekigeki.png",
}


def load_git_png(commit: str, rel: str) -> Image.Image:
	blob = subprocess.check_output(["git", "-C", str(ROOT), "show", f"{commit}:{rel}"])
	tmp = Path("/tmp") / f"_ult_src_{Path(rel).name}"
	tmp.write_bytes(blob)
	return Image.open(tmp).convert("RGBA")


def extract_frame(ref: Image.Image, inset: int = INSET) -> Image.Image:
	frame = ref.convert("RGBA").copy()
	px = frame.load()
	w, h = frame.size
	for y in range(h):
		for x in range(w):
			dx = 0
			if x < inset:
				dx = inset - x
			elif x >= w - inset:
				dx = x - (w - inset - 1)
			dy = 0
			if y < inset:
				dy = inset - y
			elif y >= h - inset:
				dy = y - (h - inset - 1)
			if dx == 0 and dy == 0:
				depth = min(
					x - inset,
					y - inset,
					(w - inset - 1) - x,
					(h - inset - 1) - y,
				)
				r, g, b, a = px[x, y]
				if depth >= FEATHER:
					px[x, y] = (r, g, b, 0)
				else:
					fa = int(a * (1.0 - (depth + 1) / (FEATHER + 1)))
					px[x, y] = (r, g, b, fa)
	return frame


def content_from_src(src: Image.Image, inset: int = INSET) -> Image.Image:
	src = src.convert("RGBA")
	_resample = getattr(getattr(Image, "Resampling", Image), "LANCZOS", Image.LANCZOS)
	if src.size != (SIZE, SIZE):
		src = src.resize((SIZE, SIZE), _resample)
	bbox = src.split()[-1].getbbox()
	content = src.crop(bbox) if bbox else src
	inner = SIZE - 2 * inset
	cw, ch = content.size
	scale = min(inner / max(cw, 1), inner / max(ch, 1))
	nw = max(1, int(round(cw * scale)))
	nh = max(1, int(round(ch * scale)))
	resized = content.resize((nw, nh), _resample)
	canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	plate = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	draw = ImageDraw.Draw(plate)
	draw.rounded_rectangle(
		(inset - 2, inset - 2, SIZE - inset + 1, SIZE - inset + 1),
		radius=5,
		fill=(18, 20, 26, 255),
	)
	canvas = Image.alpha_composite(canvas, plate)
	ox = inset + (inner - nw) // 2
	oy = inset + (inner - nh) // 2
	canvas.alpha_composite(resized, (ox, oy))
	return canvas


def main() -> None:
	ref = Image.open(SKILLS / REF_NAME).convert("RGBA")
	frame = extract_frame(ref)
	for name in TARGETS:
		if name in SKIP:
			print(f"SKIP protected: {name}")
			continue
		rel = f"assets/ui/skills/{name}"
		src = load_git_png(SRC_COMMIT, rel)
		out = Image.alpha_composite(content_from_src(src), frame)
		out_path = SKILLS / name
		out.save(out_path, "PNG")
		print(f"reframed {name} ({out_path.stat().st_size} bytes)")


if __name__ == "__main__":
	main()
