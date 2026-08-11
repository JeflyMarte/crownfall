# 錬成 Gold レア倍率＋焼直し＝炉研ぎ（P3-BAL-ALCHEMY-RARITY-GOLD-001 / P3-BAL-REFORGE-MATCH-FORGE-001）

**Status:** Decision 承認済（2026-08-08 — オーナー指示）  
**上書き:**
- `P3-BAL-ALCHEMY-GOLD-AB-001` の「レア倍率なし・単価120」
- `P3-BAL-FORGE-GOLD-HEAVY-001-4` の焼直し固定 Gold 表  
**後続上書き（帯）:** `102_AlchemyBaseLevelGoldTier.md`（主材Lv帯を追加乗算）

---

## 1. 錬成 Gold

| 項目 | 内容 |
|---|---|
| 単価 | **180**／実上昇（旧 120） |
| 帯 | 1–20×1.5／21–50×2／51+×3（据置）→ **素材帯×主材帯** は `102` |
| レア倍率 | 炉研ぎと同表（◇1／◆1.25／✦1.6／★3／SET3.5／ミシック4）※主材レア |
| 式 | `ceil(180 × 実上昇 × 帯 × レア倍率)` → 現行式は `102` |

---

## 2. 焼直しコスト＝炉研ぎ

| 項目 | 内容 |
|---|---|
| Gold | `EquipmentEnhancer.get_gold_cost(次段, レア)` |
| 素材 | `get_material_cost(次段, レア)` |
| 次段 | `enhance_level+1`（既に +5 なら +5 相当） |

---

## 3. SSOT

- `EquipmentEnhancer.alchemy_gold_cost` / `ALCHEMY_GOLD_PER_GAIN` / `FORGE_GOLD_RARITY_MULT`
- `EquipmentReforgeHelper.get_gold_cost` / `get_material_cost`（item 引数）
- 主材帯: `102_AlchemyBaseLevelGoldTier.md`
