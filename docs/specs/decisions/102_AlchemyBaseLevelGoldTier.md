# 錬成 Gold に主材Lv帯を乗せる（P3-BAL-ALCHEMY-BASE-TIER-001）

**Status:** Decision 承認済（2026-08-11 — オーナー GO・案A）  
**上書き:** `91_AlchemyRarityGoldReforgeMatch.md` の「帯＝素材Lvのみ」

---

## 1. 問題

高Lv主材に低レア・低Lv素材を流すと、コストが安いまま装備Lvを伸ばせた。

## 2. 式（案A）

| 項目 | 内容 |
|---|---|
| 単価 | 180／実上昇（据置） |
| 素材帯 | 1–20×1.5／21–50×2／51+×3（据置） |
| **主材帯** | **同上を主材Lvにも適用（乗算）** |
| レア倍率 | 主材レア・炉研ぎ同表（据置） |
| 式 | `ceil(180 × 実上昇 × 素材帯 × 主材帯 × レア倍率)` |

## 3. SSOT

- `EquipmentEnhancer.alchemy_gold_cost`（第4引数 `base_level`）
- `alchemy_gold_tier_mult`（主材・素材で共用）
