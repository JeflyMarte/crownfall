#!/usr/bin/env bash
# Crownfall — Headless Unit Tests (GUT)
#
# Usage:
#   bash tools/run_tests.sh
#
# Godot 4.6 binary の検索順は tools/smoke_test.sh と同一:
#   1. PATH 内の godot4
#   2. PATH 内の godot
#   3. macOS /Applications/Godot*.app/Contents/MacOS/Godot
#   4. Repo-local tools/godot/Godot.app

set -uo pipefail

# ── Binary detection（smoke_test.sh と同一ロジック） ──────────────────────────

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
    echo "  Tried: godot4, godot in PATH, /Applications/Godot*.app, tools/godot/" >&2
    exit 1
}

echo "Godot   : $GODOT"
echo "Version : $("$GODOT" --version 2>&1 | head -1 || echo 'unknown')"
echo ""

# ── Project root ──────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"
echo "Project : $PROJECT_ROOT"
echo ""

# ── Import（初回のみ。.godot が無いと GUT のスクリプトロードに失敗する） ──────

if [[ ! -d "$PROJECT_ROOT/.godot" ]]; then
    echo "=== Import (first run) ==="
    "$GODOT" --headless --editor --quit 2>&1 || true
    echo ""
fi

# ── GUT 実行 ──────────────────────────────────────────────────────────────────

echo "=== Unit Tests (GUT) ==="
TEST_EXIT=0
"$GODOT" --headless -s res://addons/gut/gut_cmdln.gd \
    -gdir=res://tests/unit \
    -ginclude_subdirs \
    -gprefix=test_ \
    -gexit \
    2>&1 || TEST_EXIT=$?

echo ""
echo "=== Result ==="
if [[ $TEST_EXIT -eq 0 ]]; then
    echo "PASS  (exit 0)"
else
    echo "FAIL  (exit $TEST_EXIT)"
fi

exit $TEST_EXIT
