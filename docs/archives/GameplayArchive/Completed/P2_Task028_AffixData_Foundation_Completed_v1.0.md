# P2_Task028_AffixData_Foundation_Completed_v1.0

**Status:** Completed
**Task:** P2-Task028
**Milestone:** Phase2-M6 — Equipment Depth Foundation
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.12
**Completed Date:** 2026-06-21

---

## 概要

Affix_Bible_Completed_v1.0 を実装可能な AffixData 基盤へ落とし込み。DataRegistry lookup のみ。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| AffixData.gd | Affix Roll |
| 6 サンプル affix.tres | Appraisal 連携 |
| get_affix_data | UI |
| RESOURCE_AFFIXES_PATH | Weapon 接続 / Save / Loot / Battle |

---

## AffixData Schema

id, display_name, description, affix_category, rarity, stat_type, value, tags

---

## Sample Affixes

| id | display_name | affix_category | stat_type |
|---|---|---|---|
| sharp | 鋭利 | prefix | Attack |
| swift | 敏捷 | prefix | Attack Speed |
| heavy | 重厚 | prefix | Defense |
| blessed | 祝福 | prefix | Healing |
| fortune | 幸運 | prefix | Gold Gain |
| protection | 守護 | prefix | Defense |

---

## DataRegistry

```gdscript
DataRegistry.get_affix_data("sharp")
→ load("res://resources/affixes/sharp.tres")
```

---

## Decision

P2-D085〜P2-D088

---

## Deferred

- AffixRoller
- Appraisal Affix reveal
- AffixInstance on WeaponInstance
- Combat stat application

---

## 参照

- `scripts/data/AffixData.gd`
- `docs/archives/GameplayArchive/Completed/Affix_Bible_Completed_v1.0.md`
- `docs/specs/implementation/03_Resource設計.md`
