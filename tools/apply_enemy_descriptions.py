#!/usr/bin/env python3
"""Apply description fields to enemy .tres from tools/data/enemy_descriptions.json."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "tools/data/enemy_descriptions.json"
ENEMIES_DIR = ROOT / "resources/enemies"


def _escape_godot_string(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def _set_or_insert_description(content: str, description: str) -> str:
    line = f'description = "{_escape_godot_string(description)}"'
    if re.search(r"^description = ", content, flags=re.M):
        return re.sub(r'^description = ".*"$', line, content, count=1, flags=re.M)
    return re.sub(
        r'^(display_name = ".*"\n)',
        r"\1" + line + "\n",
        content,
        count=1,
        flags=re.M,
    )


def main() -> int:
    data = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    enemies: dict = data.get("enemies", {})
    enemy_files = {p.stem: p for p in ENEMIES_DIR.glob("*.tres")}

    missing = sorted(set(enemy_files) - set(enemies))
    extra = sorted(set(enemies) - set(enemy_files))
    if missing or extra:
        print("Mismatch:", file=sys.stderr)
        if missing:
            print("  enemies missing descriptions:", missing, file=sys.stderr)
        if extra:
            print("  extra enemy ids:", extra, file=sys.stderr)
        return 1

    for item_id, desc in enemies.items():
        path = enemy_files[item_id]
        text = path.read_text(encoding="utf-8")
        if item_id not in text:
            raise ValueError(f"{path}: id {item_id} not found")
        updated = _set_or_insert_description(text, desc)
        if updated != text:
            path.write_text(updated, encoding="utf-8")

    print(f"Applied {len(enemies)} enemy descriptions.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
