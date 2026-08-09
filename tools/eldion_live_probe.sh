#!/usr/bin/env bash
# Crownfall — Eldion live probe（DungeonScene 本番戦闘経路）
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"
GODOT="$(command -v godot4 || command -v godot)"
exec "$GODOT" --path "$PROJECT_ROOT" --headless -s res://tools/eldion_live_probe.gd -- "$@"
