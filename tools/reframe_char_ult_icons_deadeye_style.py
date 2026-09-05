#!/usr/bin/env python3
"""Re-frame character ultimate icons with DeadEye-style steel+cyan frame.

Restores art from commit before gold framing (86311c4c parent of gold commit uses
86311c4c itself = unframed originals), then applies DeadEye draw_frame.
"""
from __future__ import annotations

import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "assets/ui/skills"
SIZE = 128
INSET = 12
# Commit that added the unframed character ultimate icons
SOURCE_COMMIT = "86311c4c"

FRAME = (72, 76, 84, 255)
FRAME_HI = (190, 198, 210, 255)
CYAN = (100, 200, 230, 255)
BG = (18, 20, 26, 255)

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


def draw_deadeye_frame(draw: ImageDraw.ImageDraw) -> None:
    """Same geometry/colors as tools/generate_skill_ultimate_dead_eye.py draw_frame."""
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=8, fill=FRAME)
    draw.rounded_rectangle((3, 3, SIZE - 4, SIZE - 4), radius=7, outline=FRAME_HI, width=2)
    draw.rounded_rectangle((6, 6, SIZE - 7, SIZE - 7), radius=6, outline=CYAN, width=1)
    draw.rounded_rectangle((10, 10, SIZE - 11, SIZE - 11), radius=5, fill=BG)
    for cx, cy, dx, dy in (
        (14, 14, 1, 1),
        (114, 14, -1, 1),
        (14, 114, 1, -1),
        (114, 114, -1, -1),
    ):
        draw.polygon(
            [(cx, cy), (cx + 10 * dx, cy + 2 * dy), (cx + 2 * dx, cy + 10 * dy)],
            fill=FRAME_HI,
        )


def load_blob(commit: str, rel_path: str) -> bytes:
    return subprocess.check_output(
        ["git", "-C", str(ROOT), "show", f"{commit}:{rel_path}"],
    )


def framed_from_src(src: Image.Image) -> Image.Image:
    src = src.convert("RGBA")
    if src.size != (SIZE, SIZE):
        src = src.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    alpha = src.split()[-1]
    bbox = alpha.getbbox()
    content = src.crop(bbox) if bbox else src

    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    draw_deadeye_frame(draw)

    inner = SIZE - 2 * INSET
    cw, ch = content.size
    scale = min(inner / max(cw, 1), inner / max(ch, 1))
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = content.resize((nw, nh), Image.Resampling.LANCZOS)
    ox = INSET + (inner - nw) // 2
    oy = INSET + (inner - nh) // 2
    canvas.alpha_composite(resized, (ox, oy))
    return canvas


def main() -> None:
    for name in TARGETS:
        rel = f"assets/ui/skills/{name}"
        out = SKILLS / name
        blob = load_blob(SOURCE_COMMIT, rel)
        tmp = Path("/tmp") / f"ult_src_{name}"
        tmp.write_bytes(blob)
        src = Image.open(tmp).convert("RGBA")
        framed = framed_from_src(src)
        framed.save(out, "PNG")
        print(f"reframed {name} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
