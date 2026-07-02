#!/usr/bin/env bash
# Crownfall — Headless Smoke Test
#
# Usage:
#   bash tools/smoke_test.sh              # import + smoke test
#   bash tools/smoke_test.sh --import-only  # import only (no smoke run)
#
# Godot 4.6 binary は以下の順で検索:
#   1. PATH 内の godot4
#   2. PATH 内の godot
#   3. macOS /Applications/Godot*.app/Contents/MacOS/Godot

set -uo pipefail

# ── Binary detection ──────────────────────────────────────────────────────────

find_godot() {
    local bin
    for bin in godot4 godot; do
        if command -v "$bin" &>/dev/null; then
            command -v "$bin"
            return 0
        fi
    done
    # macOS: versioned Godot.app (e.g. /Applications/Godot_v4.6.app)
    local candidate
    for candidate in /Applications/Godot*.app/Contents/MacOS/Godot; do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    # Repo-local Godot (HQ / CI bootstrap; not committed)
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
    echo "  Tried: godot4, godot in PATH, /Applications/Godot*.app" >&2
    echo "" >&2
    echo "  Fix options:" >&2
    echo "    export PATH=\"/path/to/godot4:\$PATH\"" >&2
    echo "    or install Godot 4.6 to /Applications/" >&2
    exit 1
}

echo "Godot   : $GODOT"
echo "Version : $("$GODOT" --version 2>&1 | head -1 || echo 'unknown')"
echo ""

# ── Project root (one level up from this script's directory) ─────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"
echo "Project : $PROJECT_ROOT"
echo ""

# ── Step 1: Asset Import ──────────────────────────────────────────────────────

echo "=== Step 1: Asset Import ==="
IMPORT_EXIT=0
"$GODOT" --headless --editor --quit 2>&1 || IMPORT_EXIT=$?

if [[ $IMPORT_EXIT -ne 0 ]]; then
    echo "(--editor --quit exited $IMPORT_EXIT; retrying with --quit-after 1)"
    IMPORT_EXIT=0
    "$GODOT" --headless --quit-after 1 2>&1 || IMPORT_EXIT=$?
fi

if [[ $IMPORT_EXIT -eq 0 ]]; then
    echo "Import : OK"
else
    echo "Import : exited $IMPORT_EXIT (non-fatal — may still proceed)"
fi
echo ""

if [[ "${1:-}" == "--import-only" ]]; then
    echo "Done (--import-only)."
    exit 0
fi

# ── Step 2: Smoke Test ────────────────────────────────────────────────────────

echo "=== Step 2: Smoke Test (120 frames) ==="
SMOKE_EXIT=0
SMOKE_OUTPUT="$("$GODOT" --headless --quit-after 120 2>&1)" || SMOKE_EXIT=$?
echo "$SMOKE_OUTPUT"
echo ""

# SCRIPT ERROR はゲート失敗（P3-FIX-005）。
# exit 0 でも Parse/Compile エラーを見逃していた穴を塞ぐ。
SCRIPT_ERROR_COUNT=$(echo "$SMOKE_OUTPUT" | grep -c "SCRIPT ERROR" || true)
if [[ $SMOKE_EXIT -eq 0 && $SCRIPT_ERROR_COUNT -gt 0 ]]; then
    SMOKE_EXIT=1
    echo "SCRIPT ERROR detected: $SCRIPT_ERROR_COUNT line(s) — treating as FAIL"
    echo ""
fi

echo "=== Result ==="
if [[ $SMOKE_EXIT -eq 0 ]]; then
    echo "PASS  (exit 0)"
else
    echo "FAIL  (exit $SMOKE_EXIT)"
    echo ""
    echo "Diagnostics:"
    echo "  - Look for 'SCRIPT ERROR' or 'ERROR:' in the output above"
    echo "  - Common causes:"
    echo "      Autoload failure (missing .gd or bad syntax)"
    echo "      .import not generated for PNG assets (run --import-only first)"
    echo "      Broken .tres resource reference"
fi

exit $SMOKE_EXIT
