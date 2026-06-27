#!/usr/bin/env bash
# Crownfall — ChatGPT 世界観 ZIP 再生成
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="v3.5.45"
STAGING="$ROOT/.tmp_chatgpt_worldlore"
OUT="$ROOT/Crownfall_WorldLore_ChatGPT_${VERSION}.zip"

GAME="$ROOT/docs/specs/game"
CORE="$ROOT/docs/specs/core"

rm -rf "$STAGING"
mkdir -p "$STAGING/core"

cp "$ROOT/docs/project/ChatGPT_WorldLore_README.md" "$STAGING/README.md"

FILES=(
  "01_ゲーム概要.md"
  "03_世界観.md"
  "04_ゲームループ.md"
  "12_モンスター.md"
  "26_CombatVision.md"
  "27_状態異常と属性.md"
  "29_PostwarEcology.md"
  "30_EcologyClassification.md"
  "31_SeekersGuild.md"
  "32_BiomeBible.md"
  "33_EcologyCodex.md"
  "34_MonsterNamingGuide.md"
  "35_WorldGeography.md"
  "36_JobBible.md"
  "37_RelicsHistoryCore.md"
)

for f in "${FILES[@]}"; do
  cp "$GAME/$f" "$STAGING/$f"
done

cp "$CORE/01_Design_Principles.md" "$STAGING/core/01_Design_Principles.md"

rm -f "$OUT"
(cd "$STAGING" && zip -rq "$OUT" .)
rm -rf "$STAGING"

echo "Created: $OUT"
unzip -l "$OUT"
