#!/usr/bin/env python3
"""Generate per-dungeon treasure/exit objects and Dark/Holy/Critical hit VFX sheets."""
from __future__ import annotations

import colorsys
from pathlib import Path

from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
MG_ENV = ROOT / "assets/dungeon/mourngate/env"
VFX_DIR = ROOT / "assets/vfx/batch6"

DUNGEONS: list[tuple[str, str, float | None]] = [
    ("mourngate", "Mourngate", None),
    ("astoria_ruins", "AstoriaRuins", 0.08),
    ("whisperwood", "Whisperwood", 0.30),
    ("green_hollow", "GreenHollow", 0.33),
    ("mistfen", "Mistfen", 0.42),
    ("broken_marsh", "BrokenMarsh", 0.06),
    ("blackshore", "Blackshore", 0.54),
    ("westbay_flats", "WestbayFlats", 0.11),
    ("frostridge", "Frostridge", 0.58),
    ("frostwall_path", "FrostwallPath", 0.56),
]

CHEST_SRC = MG_ENV / "OBJ_TreasureChest_Open.png"
EXIT_SRC = MG_ENV / "OBJ_ExitGate_Mourngate.png"
HIT_SRC = VFX_DIR / "FX_Hit_Normal.png"


def remove_black_bg(img: Image.Image, threshold: int = 24) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r <= threshold and g <= threshold and b <= threshold:
                px[x, y] = (r, g, b, 0)
    return img


def tint_image(img: Image.Image, hue: float, sat_mult: float = 1.2) -> Image.Image:
    img = img.convert("RGBA")
    rgb = Image.merge("RGB", img.split()[:3])
    hsv = rgb.convert("HSV")
    h, s, v = hsv.split()
    h_data = h.load()
    s_data = s.load()
    target = int(hue * 255) % 256
    for y in range(h.size[1]):
        for x in range(h.size[0]):
            if s_data[x, y] > 10:
                h_data[x, y] = target
            s_data[x, y] = min(255, int(s_data[x, y] * sat_mult))
    tinted = Image.merge("HSV", (h, s, v)).convert("RGBA")
    tinted.putalpha(img.split()[3])
    return tinted


def gold_tint(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            lum = (r + g + b) / 3.0
            px[x, y] = (
                min(255, int(lum * 1.2 + 40)),
                min(255, int(lum * 0.95 + 20)),
                min(255, int(lum * 0.35)),
                a,
            )
    return img


def purple_tint(img: Image.Image) -> Image.Image:
    return tint_image(img, 0.78, 1.25)


def holy_tint(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            lum = (r + g + b) / 3.0
            px[x, y] = (
                min(255, int(lum * 1.1 + 30)),
                min(255, int(lum * 1.05 + 25)),
                min(255, int(lum * 0.7 + 10)),
                a,
            )
    return img


def generate_dungeon_objects() -> int:
    chest_base = remove_black_bg(Image.open(CHEST_SRC))
    exit_base = remove_black_bg(Image.open(EXIT_SRC))
    count = 0
    for dungeon_id, theme, hue in DUNGEONS:
        out_dir = ROOT / "assets/dungeon" / dungeon_id / "env"
        out_dir.mkdir(parents=True, exist_ok=True)
        if hue is None:
            continue
        chest = tint_image(chest_base, hue)
        gate = tint_image(exit_base, hue)
        if dungeon_id in ("frostridge", "frostwall_path"):
            chest = ImageEnhance.Brightness(chest).enhance(1.08)
            gate = ImageEnhance.Brightness(gate).enhance(1.08)
        if dungeon_id == "blackshore":
            chest = ImageEnhance.Color(chest).enhance(1.15)
        chest.save(out_dir / "OBJ_TreasureChest_Open.png", "PNG")
        gate.save(out_dir / f"OBJ_ExitGate_{theme}.png", "PNG")
        count += 2
        print(f"  {dungeon_id}: chest + exit")
    return count


def generate_vfx_sheets() -> None:
    base = Image.open(HIT_SRC).convert("RGBA")
    gold_tint(base).save(VFX_DIR / "FX_Hit_Critical.png", "PNG")
    purple_tint(base).save(VFX_DIR / "FX_Hit_Dark.png", "PNG")
    holy_tint(base).save(VFX_DIR / "FX_Hit_Holy.png", "PNG")
    print("  FX_Hit_Critical/Dark/Holy.png")


def write_spriteframes_tres(name: str, sheet: str, speed: float = 12.0) -> None:
    frames = []
    for i in range(4):
        frames.append(
            f"""[sub_resource type="AtlasTexture" id="f{i}"]
atlas = ExtResource("1_sheet")
region = Rect2({i * 32}, 0, 32, 32)
"""
        )
    text = f"""[gd_resource type="SpriteFrames" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://{sheet}" id="1_sheet"]

{"".join(frames)}
[resource]
animations = [{{
"frames": [{{"duration": 1.0, "texture": SubResource("f0")}}, {{"duration": 1.0, "texture": SubResource("f1")}}, {{"duration": 1.0, "texture": SubResource("f2")}}, {{"duration": 1.0, "texture": SubResource("f3")}}],
"loop": false,
"name": &"default",
"speed": {speed}
}}]
"""
    out = ROOT / "resources/animation" / f"{name}.tres"
    out.write_text(text, encoding="utf-8")
    print(f"  {out.name}")


def generate_vfx_tres() -> None:
    write_spriteframes_tres("FX_Hit_Dark", "assets/vfx/batch6/FX_Hit_Dark.png")
    write_spriteframes_tres("FX_Hit_Holy", "assets/vfx/batch6/FX_Hit_Holy.png")
    write_spriteframes_tres("FX_Hit_Critical", "assets/vfx/batch6/FX_Hit_Critical.png", 14.0)


if __name__ == "__main__":
    print("Dungeon env objects...")
    n = generate_dungeon_objects()
    print(f"Generated {n} object PNGs.")
    print("VFX sheets...")
    generate_vfx_sheets()
    generate_vfx_tres()
    print("Done.")
