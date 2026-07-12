#!/usr/bin/env python3
"""Apply description fields to weapon/armor .tres from tools/data/equipment_descriptions.json."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "tools/data/equipment_descriptions.json"
WEAPONS_DIR = ROOT / "resources/weapons"
ARMORS_DIR = ROOT / "resources/armors"


def _escape_godot_string(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def _set_or_insert_description(content: str, description: str) -> str:
    line = f'description = "{_escape_godot_string(description)}"'
    if re.search(r"^description = ", content, flags=re.M):
        return re.sub(r'^description = ".*"$', line, content, count=1, flags=re.M)
    # Insert after display_name for readability.
    return re.sub(
        r'^(display_name = ".*"\n)',
        r"\1" + line + "\n",
        content,
        count=1,
        flags=re.M,
    )


def _apply_file(path: Path, item_id: str, description: str) -> None:
    text = path.read_text(encoding="utf-8")
    if item_id not in text:
        raise ValueError(f"{path}: id {item_id} not found")
    updated = _set_or_insert_description(text, description)
    if updated != text:
        path.write_text(updated, encoding="utf-8")


def main() -> int:
    data = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    weapons: dict = data.get("weapons", {})
    armors: dict = data.get("armors", {})

    weapon_files = {p.stem: p for p in WEAPONS_DIR.glob("*.tres")}
    armor_files = {p.stem: p for p in ARMORS_DIR.glob("*.tres")}

    missing_weapon = sorted(set(weapon_files) - set(weapons))
    missing_armor = sorted(set(armor_files) - set(armors))
    extra_weapon = sorted(set(weapons) - set(weapon_files))
    extra_armor = sorted(set(armors) - set(armor_files))
    if missing_weapon or missing_armor or extra_weapon or extra_armor:
        print("Mismatch:", file=sys.stderr)
        if missing_weapon:
            print("  weapons missing descriptions:", missing_weapon, file=sys.stderr)
        if missing_armor:
            print("  armors missing descriptions:", missing_armor, file=sys.stderr)
        if extra_weapon:
            print("  extra weapon ids:", extra_weapon, file=sys.stderr)
        if extra_armor:
            print("  extra armor ids:", extra_armor, file=sys.stderr)
        return 1

    for item_id, desc in weapons.items():
        _apply_file(weapon_files[item_id], item_id, desc)
    for item_id, desc in armors.items():
        _apply_file(armor_files[item_id], item_id, desc)

    print(f"Applied {len(weapons)} weapon and {len(armors)} armor descriptions.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
