#!/usr/bin/env bash
# Crownfall — Godot 外部エディタを Cursor に設定
#
# 方法 A（推奨）: Godot エディタで EditorScript を実行
#   1. Godot で本プロジェクトを開く
#   2. tools/setup_cursor_external_editor.gd を開く
#   3. File → Run
#
# 方法 B: 本スクリプトで Godot を起動し、上記手順を案内

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

find_godot() {
    local bin candidate
    for bin in godot4 godot; do
        if command -v "$bin" &>/dev/null; then
            command -v "$bin"
            return 0
        fi
    done
    for candidate in /Applications/Godot*.app/Contents/MacOS/Godot; do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

GODOT="$(find_godot)" || {
    echo "ERROR: Godot 4 が見つかりません。" >&2
    exit 1
}

echo "=== Godot → Cursor 外部エディタ設定 ==="
echo ""
echo "Godot エディタで以下を実行してください:"
echo "  1. tools/setup_cursor_external_editor.gd を開く"
echo "  2. File → Run"
echo ""
echo "Godot エディタを起動します..."
exec "$GODOT" --path "$ROOT" --editor res://tools/setup_cursor_external_editor.gd
