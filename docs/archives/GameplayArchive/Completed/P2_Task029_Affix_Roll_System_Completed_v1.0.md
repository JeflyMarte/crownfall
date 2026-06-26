# P2_Task029_Affix_Roll_System_Completed_v1.0

**Status:** Completed
**Task:** P2-Task029
**Milestone:** Phase2-M6 — Equipment Depth Foundation
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.13
**Completed Date:** 2026-06-21

---

## 概要

Affix Bible MVP スロット規則に従う最小 AffixRoller。鑑定・装備保存は未接続。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| AffixRoller.gd | Appraisal |
| MVP slot rules | WeaponInstance |
| Category / rarity filter | Save / Combat / UI |
| Roll result Dictionary | Reroll / Legendary / Curse |

---

## MVP Slot Rules

| Category | Prefix | Suffix |
|---|---|---|
| weapon | 1 | 1 |
| armor | 1 | 0 |
| accessory | 1 | 0 |

---

## Rarity Weights

COMMON 70 / RARE 25 / EPIC 4 / LEGENDARY 1

---

## Roll Result Format

```gdscript
{
  "equipment_category": "weapon",
  "item_rarity": 0,
  "prefix_ids": ["sharp"],
  "suffix_ids": ["of_might"],
  "prefixes": [AffixData],
  "suffixes": [AffixData],
}
```

Invalid: `{ "error": "invalid_category", ... }`

---

## Sample Addition

`of_might` — weapon suffix（suffix プール検証用）

---

## Decision

P2-D089〜P2-D092

---

## Deferred

- Appraisal reveal
- AffixInstance on equipment
- Drop pipeline integration

---

## 参照

- `scripts/equipment/AffixRoller.gd`
- `docs/archives/GameplayArchive/Completed/Affix_Bible_Completed_v1.0.md`
