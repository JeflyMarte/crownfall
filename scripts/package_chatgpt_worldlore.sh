#!/usr/bin/env bash
# Crownfall — ChatGPT 世界観 ZIP 再生成
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="v3.5.45"
STAGING="$ROOT/.tmp_chatgpt_worldlore"
OUT="$ROOT/Crownfall_WorldLore_ChatGPT_${VERSION}.zip"

GAME="$ROOT/docs/specs/game"
WORLD="$ROOT/docs/specs/world"
CORE="$ROOT/docs/specs/core"

rm -rf "$STAGING"
mkdir -p "$STAGING/core" "$STAGING/world"

cp "$ROOT/docs/project/ChatGPT_WorldLore_README.md" "$STAGING/README.md"

# 世界観 SSOT（docs/specs/world/ 12 文書）
WORLD_FILES=(
  "00_Overview.md"
  "01_History.md"
  "02_Relics.md"
  "03_Ecology.md"
  "04_Classification.md"
  "05_Biomes.md"
  "06_MonsterNaming.md"
  "07_Geography.md"
  "08_SeekersGuild.md"
  "09_Jobs.md"
  "10_LoreDelivery.md"
  "11_Glossary.md"
)

# ゲーム仕様側（数値・システム仕様）
GAME_FILES=(
  "01_ゲーム概要.md"
  "03_世界観.md"
  "04_ゲームループ.md"
  "06_キャラクター_ジョブ.md"
  "12_モンスター.md"
  "26_CombatVision.md"
  "27_状態異常と属性.md"
  "33_EcologyCodex.md"
)

for f in "${WORLD_FILES[@]}"; do
  cp "$WORLD/$f" "$STAGING/world/$f"
done

for f in "${GAME_FILES[@]}"; do
  cp "$GAME/$f" "$STAGING/$f"
done

cp "$CORE/01_Design_Principles.md" "$STAGING/core/01_Design_Principles.md"

rm -f "$OUT"
(cd "$STAGING" && zip -rq "$OUT" .)
rm -rf "$STAGING"

echo "Created: $OUT"
unzip -l "$OUT"
