# Crownfall 世界観資料（World）

**Status:** 構成確定（オーナー決定 2026-06-27）/ 各文書は ChatGPT 執筆待ち（Draft）
**入口:** `00_Overview.md`

世界観・ロアの SSOT 置き場。数値・スキーマ・実装ルールは `docs/specs/game/` / `docs/specs/implementation/` に置く。

---

## 構成（4 層 + 運用）

| # | 文書 | 層 | 移行元（現 live SSOT） |
|---|---|---|---|
| 00 | Overview（マスター） | 入口 | `game/03` + `game/29` |
| 01 | History（歴史） | 過去 | `game/37`（歴史部） |
| 02 | Relics（遺産） | 過去 | `game/37`（遺産部） |
| 03 | Ecology（生態総論） | 現在の自然 | `game/29` |
| 04 | Classification（分類） | 現在の自然 | `game/30` |
| 05 | Biomes（生態系各論） | 現在の自然 | `game/32` |
| 06 | MonsterNaming（命名） | 現在の自然 | `game/34` |
| 07 | Geography（地理） | 現在の人類 | `game/35` |
| 08 | SeekersGuild（組織） | 現在の人類 | `game/31` |
| 09 | Jobs（職・世界観面） | 現在の人類 | `game/36`（世界観面のみ） |
| 10 | LoreDelivery（開示ガイド） | 運用 | 新規 |
| 11 | Glossary（用語・正典索引） | 運用 | `game/37` + `game/35` |

---

## 設計ルール

1. **1 文書 1 責務** — 重複・ドリフトを構造で防ぐ。
2. **世界観↔仕様の分離** — Jobs/Codex 等の両面文書は、世界観面を `world/`、数値・仕様面を `game/` に置く。図鑑（旧 `game/33`）はシステム仕様として `game/` に置く（`world/` には作らない）。
3. **正典の一元化** — 固有名詞は `11_Glossary` を正とし、各文書を一致させる。

---

## 移行（cutover）手順

現行 `game/29`〜`37` は **本資料完成まで live SSOT として残す**（二重 SSOT 回避のため Draft と明記）。

1. ChatGPT が各 `world/NN` を執筆。
2. HQ がレビュー・正典整合を確認。
3. 参照を `game/29`〜`37` → `world/NN` へ切替（`CatalogHelper.gd` の History パス、各 spec のリンク、`package_chatgpt_worldlore.sh` 等）。
4. 旧 `game/29`〜`37` を削除（git 履歴に保持）。
5. smoke test。
