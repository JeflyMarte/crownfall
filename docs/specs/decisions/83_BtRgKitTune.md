# BT／RG キット調整（獣医ドレイン・野営全体・つつき自己除外・RG順入替）

**ID:** P3-BAL-BT-RG-KIT-TUNE-001  
**日付:** 2026-08-07  
**状態:** 承認（オーナー「推奨案で」）  
**Overrides:** `78_HealHierarchy.md`／`43_BtRgSupportHeal.md`／`42_HealMaxHpFraction.md`／`82_RgBtSkillOrder.md`（該当行）

## 要旨

1. **獣医の手当て**を回復から **ドレイン攻撃**へ（敵 power **1.1**、自己回復＝与ダメ **50%**、CD9.5／**即時** ※旧詠唱1は誤残で撤去）  
2. **つつき介抱**は **自己非対象**、回復 **8%**  
3. RG 習得順: Lv8＝**斉射**／Lv30＝**スネア**（入替）  
4. **野営の一滴**は **味方全体各員 8%**

## 確定

| 項目 | 値 |
|---|---|
| `beast_vet_care` | `effect_type=damage`／`target_type=enemy`／power **1.1**／tags `ranged,pierce,drain,support`／CD **9.5**／cast **0**／自己回復＝与ダメ×`SKILL_DRAIN_HEAL_RATIO`(**0.5**) |
| `pet_pounce` | 最傷1（`exclude_self`）／**8%**／CD **10.0** |
| `camp_draught` | `all_party`／各 **8%**／CD **10.0**／reserve `ally_injured` |
| RG Lv8 | `volley_shot` |
| RG Lv30 | `snare_shot` |

## SSOT

- `resources/skills/{beast_vet_care,camp_draught,pet_pounce}.tres`
- `resources/jobs/ranger.tres`
- `BalanceConfig.HEAL_FRAC_CAMP_DRAUGHT`／`HEAL_FRAC_PET_POUNCE`／`SKILL_DRAIN_HEAL_RATIO`
- 戦闘: `DungeonScene._apply_member_lifesteal`（drain タグ加算）／`CombatController.get_most_injured_member_index(exclude)`
