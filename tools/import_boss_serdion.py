#!/usr/bin/env python3
"""Import Crystal Bonewyrm boss animations into BOSS_Serdion sheet + SpriteFrames."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = Path(
    "/Users/marte/Desktop/名称未設定フォルダ/ボス/"
    "Crystal_Bonewyrm_A_colossal_undead_crystal_dragon/animations"
)
OUT_SHEET = ROOT / "assets/battle/bosses/BOSS_Serdion_Sheet.png"
OUT_TRES = ROOT / "resources/animation/BOSS_Serdion.tres"

FRAME = 128
DIRECTION = "south-west"
ANIMATIONS: list[tuple[str, str, bool, int]] = [
    ("Idle", "idle", True, 9),
    ("Atack", "attack", False, 9),
    ("Hit", "hurt", False, 9),
    ("Death", "death", False, 9),
]


def fit_frame(src: Image.Image, size: int) -> Image.Image:
    img = src.convert("RGBA")
    bbox = img.getbbox()
    if bbox is None:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cropped = img.crop(bbox)
    cw, ch = cropped.size
    margin = int(size * 0.08)
    target = size - margin * 2
    ratio = min(target / cw, target / ch)
    nw, nh = max(1, int(cw * ratio)), max(1, int(ch * ratio))
    resized = cropped.resize((nw, nh), Image.Resampling.NEAREST)
    frame = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ox = (size - nw) // 2
    oy = size - nh - margin
    frame.paste(resized, (ox, oy), resized)
    return frame


def load_frames(anim_name: str, count: int) -> list[Image.Image]:
    folder = SRC_ROOT / anim_name / DIRECTION
    frames: list[Image.Image] = []
    for i in range(count):
        path = folder / f"frame_{i:03d}.png"
        if not path.exists():
            raise FileNotFoundError(path)
        frames.append(fit_frame(Image.open(path), FRAME))
    return frames


def build_sheet() -> tuple[Image.Image, list[tuple[str, bool, int, int]]]:
    all_frames: list[Image.Image] = []
    meta: list[tuple[str, bool, int, int]] = []
    for src_name, anim_id, loop, count in ANIMATIONS:
        start = len(all_frames)
        all_frames.extend(load_frames(src_name, count))
        meta.append((anim_id, loop, start, count))
    sheet = Image.new("RGBA", (FRAME * len(all_frames), FRAME), (0, 0, 0, 0))
    for i, frame in enumerate(all_frames):
        sheet.paste(frame, (i * FRAME, 0), frame)
    return sheet, meta


def write_tres(meta: list[tuple[str, bool, int, int]]) -> None:
    total = sum(item[3] for item in meta)
    lines = [
        '[gd_resource type="SpriteFrames" load_steps=2 format=3]',
        "",
        f'[ext_resource type="Texture2D" path="res://assets/battle/bosses/BOSS_Serdion_Sheet.png" id="1_sheet"]',
        "",
    ]
    idx = 0
    atlas_ids: list[str] = []
    for _ in range(total):
        lines.extend(
            [
                f'[sub_resource type="AtlasTexture" id="f{idx}"]',
                'atlas = ExtResource("1_sheet")',
                f"region = Rect2({idx * FRAME}, 0, {FRAME}, {FRAME})",
                "",
            ]
        )
        atlas_ids.append(f"f{idx}")
        idx += 1

    anim_entries: list[str] = []
    cursor = 0
    for anim_id, loop, _start, count in meta:
        frame_refs = ", ".join(
            f'{{"duration": 1.0, "texture": SubResource("{atlas_ids[cursor + i]}")}}'
            for i in range(count)
        )
        anim_entries.append(
            f'{{"frames": [{frame_refs}], "loop": {"true" if loop else "false"}, '
            f'"name": &"{anim_id}", "speed": 8.0}}'
        )
        cursor += count

    lines.append("[resource]")
    lines.append(f"animations = [{', '.join(anim_entries)}]")
    lines.append("")
    OUT_TRES.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    if not SRC_ROOT.exists():
        raise SystemExit(f"Source animations not found: {SRC_ROOT}")
    sheet, meta = build_sheet()
    OUT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT_SHEET)
    write_tres(meta)
    print(f"Wrote {OUT_SHEET} ({sheet.size[0]}x{sheet.size[1]})")
    print(f"Wrote {OUT_TRES}")


if __name__ == "__main__":
    main()
