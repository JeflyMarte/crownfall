# 装備レア表示の統一（P3-UI-RARITY-NREL-001）

**Status:** Decision 承認済（2026-07-28 オーナー GO・案B）  
**Scope:** 装備レアの**プレイヤー向け呼称／UI表示**のみ。ドロップ率・ステ数値は変更しない。

---

## 1. 方針（案B）

| 対象 | 表示 |
|---|---|
| **装備**（武・防・飾） | **N＜R＜E＜L**（＋拡張帯） |
| **キャラ／助っ人** | 従来どおり **★個数**（★★★ 等） |
| ダンジョン難度の ★／☆ | **対象外**（難度表示のまま） |

ダンジョン難度の「ノーマル」と装備 **N** は別物。装備側は短いコード文字で区別する。

---

## 2. 対応表

| コード | 内部 `Enums.Rarity` | 旧宝石記号（廃止） |
|---|---|---|
| **N** | COMMON | ◇ |
| **R** | RARE | ◆ |
| **E** | EPIC | ✦ |
| **L** | LEGENDARY | ★（宝石1文字） |
| **M** | MYTHIC | ❖ |
| **セット** | SET | ▣（アイコン隅文字は空・緑枠） |

旧「装備を★個数で表す」（COMMON=★1…）は廃止。鍛冶の旧短号 SR／SSR も **E／L** に置換。

---

## 3. SSOT

- `EquipmentUiHelper.rarity_code` / `rarity_label_text` / `rarity_stars_text`（隅バッジ）
- `BlacksmithUiHelper.rarity_short_label`
- `CodexContentHelper.rarity_label`

キャラ用は `RosterUiHelper.stars_text`／`EquipmentUiHelper.stars_text`（変更なし）。

---

## 4. やらないこと

- ガチャ助っ人の★帯ルール変更
- 装備ステ・ドロップ重みの変更
- 難度ティア（ノーマル／ハード／ナイトメア）の改名
