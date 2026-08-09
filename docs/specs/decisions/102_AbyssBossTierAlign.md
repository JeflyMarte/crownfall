# 無限ボス階の合成ティア整合（P3-BAL-ABYSS-BOSS-TIER-ALIGN-001）

**ID:** P3-BAL-ABYSS-BOSS-TIER-ALIGN-001  
**日付:** 2026-08-09  
**状態:** 承認（オーナー GO）  
**上書き:** `09_BiomeAbyss` 難度帯／`25_AbyssFloorLevelCurve` の色替え開始階（33/66）

## 要旨

33Fボスがいきなり Hard 見た目・補正になっていた。ボス階を各難度帯の締めにする。

## 確定

| 階 | ボス合成ティア |
|---|---|
| **33F** | Normal |
| **66F** | Hard |
| **99F** | Nightmare |

帯（雑魚含む）:

- 1–33 ≈ Normal  
- 34–66 ≈ Hard  
- 67– ≈ Nightmare  

ボス編成パック（33=薄／66=エリート／99+=厚）は据置。

## SSOT

- `AbyssDungeonConfig.FLOOR_HARD_START = 34`
- `AbyssDungeonConfig.FLOOR_NIGHTMARE_START = 67`
- `synthetic_tier_for_floor`／`boss_pack_kind`
