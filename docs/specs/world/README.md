# Crownfall 世界観資料（World）

**Status:** 採用（正式 SSOT / cutover 完了 2026-06-27 P3-D041b）。12 文書 v1.0 執筆済み
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

## 非公開（HQ 内部限定）

| 文書 | 内容 |
|---|---|
| `CANON_INTERNAL.md` | 中核の謎の作者向け真相（正史）。**プレイヤー非開示 / ChatGPT 配布除外 / 図鑑非掲載**（P3-D043） |

---

## 設計ルール

1. **1 文書 1 責務** — 重複・ドリフトを構造で防ぐ。
2. **世界観↔仕様の分離** — Jobs/Codex 等の両面文書は、世界観面を `world/`、数値・仕様面を `game/` に置く。図鑑（旧 `game/33`）はシステム仕様として `game/` に置く（`world/` には作らない）。
3. **正典の一元化** — 固有名詞は `11_Glossary` を正とし、各文書を一致させる。

---

## 移行（cutover）— 完了（2026-06-27 / P3-D041b）

`game/29`〜`32`・`34`〜`37` は削除済み（git 履歴に保持）。`33_EcologyCodex` は図鑑システム仕様として `game/` に存置。`world/01_History` 末尾に HE-001〜004 機械可読ブロックを移管し、`CatalogHelper.gd` の History パスを `world/01` へ切替済み。smoke PASS。

> 上表「移行元」列は来歴記録（旧ファイルは削除済み）。
