# P2_Task032_Equipment_Detail_UI_Completed_v1.0

**Status:** Completed
**Task:** P2-Task032
**Milestone:** Phase2-M6 — Equipment Depth Foundation
**Approved By:** —（実装完了・DevelopmentHQ レビュー待ち）
**Version:** v1.0
**ProjectDocs:** v3.5.16
**Completed Date:** 2026-06-21

---

## 概要

EquipmentScene に鑑定済み装備の Affix 名称・効果を最小表示。`AffixDisplayFormatter` で整形。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| AffixDisplayFormatter.gd | UI 全面リデザイン |
| EquipmentScene 表示 | sort / filter / tooltip |
| 未鑑定 conceal | rarity color / compare popup |
| 欠落 AffixData 安全処理 | reroll / blacksmith UI |

---

## Display Format

```
rusted_blade  ATK 12  SPD 1.0  CRT 0%
Affix: 鋭利 / 偉力
Attack +3 / Attack +2
```

Gold Gain 例: `Gold Gain +10%`

---

## Rules

- `is_appraised == false` → Affix 行なし
- リストは従来どおり鑑定済みのみ（EquipmentController）
- gameplay / stat 計算 **未変更**

---

## Decision

P2-D101〜P2-D104

---

## Deferred

- Affix tooltip / compare popup
- Rarity color system
- Sort / filter

---

## Files

- `scripts/equipment/AffixDisplayFormatter.gd`
- `scripts/equipment/EquipmentScene.gd`
- `scripts/appraisal/AppraisalController.gd`（reveal 共通化のみ）
