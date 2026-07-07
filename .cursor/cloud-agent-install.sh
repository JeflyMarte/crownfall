#!/usr/bin/env bash
# Crownfall — Cloud Agent 起動時の依存セットアップ
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Crownfall Cloud Agent Install ==="
echo "Project: $ROOT"
echo "Godot  : $(godot --version 2>&1 | head -1)"

if [[ ! -d "$ROOT/.godot" ]]; then
    echo "=== Godot import (first run) ==="
    godot --headless --import --quit-after 300 2>&1 || true
fi

echo "=== Smoke test ==="
bash tools/smoke_test.sh

echo "=== Install complete ==="
