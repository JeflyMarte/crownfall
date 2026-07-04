#!/usr/bin/env python3
"""Generate battle sprite sheets and SpriteFrames from codex portraits."""
from __future__ import annotations

import re
from pathlib import Path

from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
CODEX_DIR = ROOT / "assets/codex/enemies"
BATTLE_DIR = ROOT / "assets/battle/enemies"
BOSS_DIR = ROOT / "assets/battle/bosses"
ANIM_DIR = ROOT / "resources/animation"

FRAME = 96
IDLE_FRAMES = 4
ATTACK_FRAMES = 4
HURT_FRAMES = 2
DEATH_FRAMES = 4
TOTAL_FRAMES = IDLE_FRAMES + ATTACK_FRAMES + HURT_FRAMES + DEATH_FRAMES

BOSSES = {"serdion", "granvel", "moldgar", "nereion", "eldion"}

SKIP_EXISTING_SHEETS = {
    ROOT / "assets/dungeon/mourngate/ENM_SepiaHound_Sheet.png",
    ROOT / "assets/dungeon/mourngate/ENM_RuneRoach_Sheet.png",
    ROOT / "assets/dungeon/mourngate/ENM_CrystalHedgehog_Sheet.png",
    ROOT / "assets/dungeon/mourngate/ENM_CrownEaterRat_Sheet.png",
    ROOT / "assets/dungeon/mourngate/ENM_ClockMoth_Sheet.png",
}


def snake_to_pascal(snake: str) -> str:
    return "".join(part.capitalize() for part in snake.split("_"))


def codex_portrait_path(enemy_id: str) -> Path | None:
    if enemy_id in BOSSES:
        path = CODEX_DIR / f"ART_BOSS_{snake_to_pascal(enemy_id)}.png"
    else:
        path = CODEX_DIR / f"ART_ENM_{snake_to_pascal(enemy_id)}.png"
    return path if path.exists() else None


def remove_black_bg(img: Image.Image, threshold: int = 28) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r <= threshold and g <= threshold and b <= threshold:
                px[x, y] = (r, g, b, 0)
    return img


def fit_frame(src: Image.Image, scale: float = 1.0, offset_y: int = 0, tint: tuple[int, int, int] | None = None) -> Image.Image:
    frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    sw, sh = src.size
    target = int(min(FRAME * 0.82, FRAME * 0.82 / max(sw, sh) * max(sw, sh)) * scale)
    ratio = target / max(sw, sh)
    nw, nh = max(1, int(sw * ratio)), max(1, int(sh * ratio))
    resized = src.resize((nw, nh), Image.Resampling.LANCZOS)
    if tint:
        tr, tg, tb = tint
        px = resized.load()
        for y in range(nh):
            for x in range(nw):
                r, g, b, a = px[x, y]
                if a > 0:
                    px[x, y] = (
                        min(255, int(r * tr / 255)),
                        min(255, int(g * tg / 255)),
                        min(255, int(b * tb / 255)),
                        a,
                    )
    ox = (FRAME - nw) // 2
    oy = (FRAME - nh) // 2 + offset_y
    frame.paste(resized, (ox, oy), resized)
    return frame


def build_frames(portrait: Image.Image) -> list[Image.Image]:
    base = remove_black_bg(portrait)
    frames: list[Image.Image] = []
    for i in range(IDLE_FRAMES):
        bob = (i % 2) * 2 - 1
        frames.append(fit_frame(base, scale=1.0, offset_y=bob))
    for i in range(ATTACK_FRAMES):
        lean = i * 3
        scale = 1.0 + i * 0.04
        frames.append(fit_frame(base, scale=scale, offset_y=lean))
    for i in range(HURT_FRAMES):
        frames.append(fit_frame(base, scale=0.96, offset_y=2, tint=(255, 180, 180)))
    for i in range(DEATH_FRAMES):
        fade = ImageEnhance.Brightness(base).enhance(max(0.35, 1.0 - i * 0.18))
        frames.append(fit_frame(fade, scale=1.0 - i * 0.08, offset_y=6 + i * 4))
    return frames


def sheet_path_for(enemy_id: str) -> Path:
    pascal = snake_to_pascal(enemy_id)
    if enemy_id in BOSSES:
        return BOSS_DIR / f"BOSS_{pascal}_Sheet.png"
    return BATTLE_DIR / f"ENM_{pascal}_Sheet.png"


def tres_path_for(enemy_id: str) -> Path:
    pascal = snake_to_pascal(enemy_id)
    if enemy_id in BOSSES:
        return ANIM_DIR / f"BOSS_{pascal}.tres"
    return ANIM_DIR / f"ENM_{pascal}.tres"


def existing_sheet_res_path(enemy_id: str) -> str | None:
    pascal = snake_to_pascal(enemy_id)
    legacy = ROOT / f"assets/dungeon/mourngate/ENM_{pascal}_Sheet.png"
    if legacy.exists():
        return f"res://assets/dungeon/mourngate/ENM_{pascal}_Sheet.png"
    path = sheet_path_for(enemy_id)
    if path.exists():
        rel = path.relative_to(ROOT)
        return f"res://{rel.as_posix()}"
    return None


def write_sheet(frames: list[Image.Image], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * FRAME, 0), frame)
    sheet.save(out_path, "PNG")


def write_spriteframes(sheet_res: str, tres_path: Path) -> None:
    regions = []
    idx = 0
    for _ in range(IDLE_FRAMES):
        regions.append(("idle", idx))
        idx += 1
    for _ in range(ATTACK_FRAMES):
        regions.append(("attack", idx))
        idx += 1
    for _ in range(HURT_FRAMES):
        regions.append(("hurt", idx))
        idx += 1
    for _ in range(DEATH_FRAMES):
        regions.append(("death", idx))
        idx += 1

    lines = [
        '[gd_resource type="SpriteFrames" load_steps=2 format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{sheet_res}" id="1_sheet"]',
        "",
    ]
    sub_ids = []
    for i in range(TOTAL_FRAMES):
        sub_ids.append(f"i{i}")
        x = i * FRAME
        lines.extend(
            [
                f'[sub_resource type="AtlasTexture" id="{sub_ids[-1]}"]',
                'atlas = ExtResource("1_sheet")',
                f"region = Rect2({x}, 0, {FRAME}, {FRAME})",
                "",
            ]
        )

    anims: dict[str, list[str]] = {"idle": [], "attack": [], "hurt": [], "death": []}
    for anim, frame_idx in regions:
        anims[anim].append(sub_ids[frame_idx])

    anim_blocks = []
    for name, speed, loop in (("idle", 6.0, True), ("attack", 10.0, False), ("hurt", 8.0, False), ("death", 6.0, False)):
        frame_objs = ", ".join(
            f'{{"duration": 1.0, "texture": SubResource("{sid}") }}' for sid in anims[name]
        )
        anim_blocks.append(
            f'{{"frames": [{frame_objs}], "loop": {"true" if loop else "false"}, "name": &"{name}", "speed": {speed}}}'
        )

    lines.append("[resource]")
    lines.append("animations = [" + ", ".join(anim_blocks) + "]")
    lines.append("")
    tres_path.write_text("\n".join(lines), encoding="utf-8")


def generate_enemy(enemy_id: str, force: bool = False) -> str | None:
    portrait = codex_portrait_path(enemy_id)
    if portrait is None:
        print(f"  skip {enemy_id}: no portrait")
        return None

    legacy = ROOT / f"assets/dungeon/mourngate/ENM_{snake_to_pascal(enemy_id)}_Sheet.png"
    if not force and enemy_id not in BOSSES and legacy in SKIP_EXISTING_SHEETS:
        sheet_res = f"res://assets/dungeon/mourngate/ENM_{snake_to_pascal(enemy_id)}_Sheet.png"
    else:
        out = sheet_path_for(enemy_id)
        if not force and out.exists():
            sheet_res = f"res://{out.relative_to(ROOT).as_posix()}"
        else:
            frames = build_frames(Image.open(portrait))
            write_sheet(frames, out)
            sheet_res = f"res://{out.relative_to(ROOT).as_posix()}"
            print(f"  sheet {enemy_id} -> {out.name}")

    tres = tres_path_for(enemy_id)
    write_spriteframes(sheet_res, tres)
    return f"res://{tres.relative_to(ROOT).as_posix()}"


def all_enemy_ids() -> list[str]:
    ids: list[str] = []
    for p in sorted((ROOT / "resources/enemies").glob("*.tres")):
        text = p.read_text(encoding="utf-8")
        m = re.search(r'^id\s*=\s*"([^"]+)"', text, re.M)
        if m:
            ids.append(m.group(1))
    return ids


def update_dungeon_scene_maps(enemy_map: dict[str, str], boss_map: dict[str, str]) -> None:
    path = ROOT / "scripts/dungeon/DungeonScene.gd"
    text = path.read_text(encoding="utf-8")

    def format_map(name: str, mapping: dict[str, str]) -> str:
        lines = [f"const {name}: Dictionary = {{"]
        for k in sorted(mapping.keys()):
            lines.append(f'\t"{k}": "{mapping[k]}",')
        lines.append("}")
        return "\n".join(lines)

    text = re.sub(
        r"const ENEMY_SPRITE_MAP: Dictionary = \{[\s\S]*?\n\}",
        format_map("ENEMY_SPRITE_MAP", enemy_map),
        text,
        count=1,
    )
    text = re.sub(
        r"const BOSS_SPRITE_MAP: Dictionary = \{[\s\S]*?\n\}",
        format_map("BOSS_SPRITE_MAP", boss_map),
        text,
        count=1,
    )
    path.write_text(text, encoding="utf-8")


def main() -> None:
    enemy_map: dict[str, str] = {}
    for eid in all_enemy_ids():
        if eid in BOSSES:
            continue
        tres = generate_enemy(eid)
        if tres:
            enemy_map[eid] = tres

    boss_map = {
        "mourngate": generate_enemy("serdion") or "",
        "whisperwood": generate_enemy("granvel") or "",
        "mistfen": generate_enemy("moldgar") or "",
        "blackshore": generate_enemy("nereion") or "",
        "frostridge": generate_enemy("eldion") or "",
        "astoria_ruins": enemy_map.get("clock_moth", generate_enemy("clock_moth") or ""),
        "green_hollow": enemy_map.get("moss_boar", ""),
        "broken_marsh": enemy_map.get("great_claw", ""),
        "westbay_flats": enemy_map.get("ship_eater_crab", ""),
        "frostwall_path": enemy_map.get("frost_claw_raptor", ""),
    }
    boss_map = {k: v for k, v in boss_map.items() if v}

    update_dungeon_scene_maps(enemy_map, boss_map)
    print(f"Enemy maps: {len(enemy_map)} enemies, {len(boss_map)} dungeons")


if __name__ == "__main__":
    main()
