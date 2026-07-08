#!/usr/bin/env bash
# Crownfall — Godot AI セットアップ確認
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UV="${UV:-$HOME/.local/bin/uv}"

echo "=== Godot AI Setup Check ==="
echo "Project: $ROOT"
echo ""

if [[ ! -d "$ROOT/addons/godot_ai" ]]; then
    echo "ERROR: addons/godot_ai が見つかりません。" >&2
    exit 1
fi
echo "OK  addons/godot_ai"

if [[ ! -x "$UV" ]] && ! command -v uv &>/dev/null; then
    echo "WARN uv が未インストールです。以下を実行してください:"
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi
echo "OK  uv: $($UV --version 2>/dev/null || uv --version)"

if ! grep -q 'godot_ai/plugin.cfg' "$ROOT/project.godot"; then
    echo "WARN project.godot で Godot AI プラグインが未有効です。" >&2
    exit 1
fi
echo "OK  plugin enabled in project.godot"

if [[ -f "$ROOT/.cursor/mcp.json" ]] && grep -q 'godot-ai' "$ROOT/.cursor/mcp.json"; then
    echo "OK  Cursor MCP (.cursor/mcp.json)"
else
    echo "WARN .cursor/mcp.json に godot-ai エントリがありません。" >&2
fi

echo ""
echo "=== 次の手順 ==="
echo "1. Godot で Crownfall を開く"
echo "2. Project → Project Settings → Plugins で Godot AI が有効か確認"
echo "3. Godot AI ドックで MCP サーバー起動を確認 (http://127.0.0.1:8000/mcp)"
echo "4. Cursor を Reload Window (Cmd+Shift+P → Reload Window)"
echo "5. Godot 起動中に Cursor Agent で「シーン階層を表示して」と試す"
echo ""
echo "テレメトリ無効化（任意）:"
echo "  export GODOT_AI_DISABLE_TELEMETRY=true"
