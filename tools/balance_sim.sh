#!/usr/bin/env bash
# Crownfall — Headless Balance Simulation（P3-BAL-005）
#
# Usage:
#   bash tools/balance_sim.sh                              # 既定: mourngate 300回 Lv1
#   bash tools/balance_sim.sh --runs=1000 --party-level=5
#   bash tools/balance_sim.sh --dungeon=mourngate --runs=500
#
# Godot バイナリ検出は smoke_test.sh と同一。

set -uo pipefail

find_godot() {
    local bin
    for bin in godot4 godot; do
        if command -v "$bin" &>/dev/null; then
            command -v "$bin"
            return 0
        fi
    done
    local candidate
    for candidate in /Applications/Godot*.app/Contents/MacOS/Godot; do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    local script_dir project_godot
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    project_godot="$script_dir/godot/Godot.app/Contents/MacOS/Godot"
    if [[ -x "$project_godot" ]]; then
        echo "$project_godot"
        return 0
    fi
    return 1
}

GODOT="$(find_godot)" || {
    echo "ERROR: Godot 4 binary not found." >&2
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

exec "$GODOT" --headless -s res://tools/balance_sim.gd -- "$@"
