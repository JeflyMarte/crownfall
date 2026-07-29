# 装備状態付与の一本化（P3-EQ-STATUS-UNIFY-001）

**Status:** Decision 承認済（2026-07-29 オーナー GO・案B）  
**関連:** `30_装備ステータス定義.md`／`EquipmentRandomMods`／`AffixStatCalculator`

---

## 1. 背景

武器詳細に **炎上付与** と **状態付与 炎上** が並び、効果が重複して見えた。  
実体は別系統（専用 `*_chance` 行 ＋ `on_hit_status`）で、抽選・戦闘判定も別だった。

---

## 2. 確定

| # | 項目 | 決定 |
|---|---|---|
| 1 | 正 | **状態付与**（`on_hit_status`）のみ |
| 2 | 廃止 | 武器ランダムの `冷却／感電／炎上／毒付与`（`*_chance`）専用行 |
| 3 | Affix | `Chill/Shock/Ignite/Poison` は移行時に `状態付与` へ変換 |
| 4 | 既存個体 | sanitize で専用行→状態付与へ統合。同一状態は高い確率を残す |
| 5 | 戦闘 | 武器は `on_hit_status` 経路のみ（専用 chance の Affix 加算はしない） |

---

## 3. 実装メモ

- プール: `EquipmentRandomMods._weapon_pool_ids` から `KIND_CHILL/SHOCK/IGNITE/POISON` を除外
- 統合: `_unify_status_chance_mods`（`get_mods`／sanitize 時）
- アイコン: `on_hit_status`＋status_id で既存 CHILL/SHOCK/IGNITE/POISON アイコンを流用
