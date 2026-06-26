# P2_Task030_Affix_Appraisal_Integration_Completed_v1.0

**Status:** Completed
**Task:** P2-Task030
**Milestone:** Phase2-M6 — Equipment Depth Foundation
**Approved By:** —（実装完了・DevelopmentHQ レビュー待ち）
**Version:** v1.0
**ProjectDocs:** v3.5.14
**Completed Date:** 2026-06-21

---

## 概要

鑑定フローに AffixRoller を接続。未鑑定装備の鑑定完了時に Affix を Roll し、`prefix_ids` / `suffix_ids` を instance に保存。Reveal で Affix 名を表示。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| AppraisalController → AffixRoller | 戦闘 stat 反映 |
| Instance prefix_ids / suffix_ids | Equipment Detail UI 全面改修 |
| Save serialize affix IDs | Affix reroll |
| Reveal 表示 | Legendary / Curse |

---

## Flow

```
未鑑定装備 → appraise_next()
  → is_appraised = true
  → AffixRoller.roll_for_equipment(category, rarity)
  → prefix_ids / suffix_ids を instance に保存
  → SaveManager.save_game()
  → LabelLog に Reveal
```

Roll 失敗時: 鑑定は完了、affix 配列は空。

---

## MVP Slot Rules（継承 P2-D090）

| Category | Prefix | Suffix |
|---|---|---|
| weapon | 1 | 1 |
| armor | 1 | 0 |
| accessory | 1 | 0 |

---

## Instance Storage

```gdscript
@export var prefix_ids: Array[String] = []
@export var suffix_ids: Array[String] = []
```

Save JSON 例:

```json
{
  "weapon_id": "rusted_blade",
  "is_appraised": true,
  "prefix_ids": ["sharp"],
  "suffix_ids": ["of_might"]
}
```

---

## Reveal Example

```
鑑定完了: rusted_blade  ATK 12
【Affix】鋭利 / 偉力
```

---

## Decision

P2-D093〜P2-D096

---

## Deferred

- Combat stat application
- Equipment Detail UI
- Affix reroll

---

## Files

- `scripts/appraisal/AppraisalController.gd`
- `scripts/appraisal/AppraisalScene.gd`
- `scripts/domain/WeaponInstance.gd`
- `scripts/domain/ArmorInstance.gd`
- `scripts/domain/AccessoryInstance.gd`
- `scripts/save/SaveManager.gd`
