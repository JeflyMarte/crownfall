# Phase2-M8 Task040 Material Consumption Logic Completed v1.0

Status: Completed
Date: 2026-06-22
ProjectDocs: v3.5.29
Milestone: Phase2-M8 — Craft & Economy Foundation

---

## Purpose

CraftData を利用した Material 消費処理を GameState に実装した。
UI / Blacksmith / 装備生成は対象外。ロジック層のみ。

---

## Implementation

scripts/autoload/GameState.gd に consume_materials() を追加。

```gdscript
func consume_materials(required_materials: Dictionary) -> bool:
    for mat_id in required_materials:
        if get_material_quantity(mat_id) < int(required_materials[mat_id]):
            return false
    for mat_id in required_materials:
        material_inventory[mat_id] = get_material_quantity(mat_id) - int(required_materials[mat_id])
    print("[GameState] consume_materials: ", required_materials)
    return true
```

---

## Validation

素材十分 → true、全素材を一括消費
素材不足（1件でも） → false、material_inventory 変更なし（途中消費なし）
負数にならない: チェックパスで充足確認済みのみ消費
不明 material_id: get_material_quantity() が 0 返却 → 不足判定で false（クラッシュなし）
ログ: print("[GameState] consume_materials: ...") のみ（UI なし）

---

## Regression Check

Combat: 変更なし
Save Format: material_inventory 構造そのまま（SaveManager 変更なし）
Appraisal / Equipment / Dungeon: 変更なし

---

## Files Changed

- scripts/autoload/GameState.gd: consume_materials() 追加
- docs/specs/implementation/11_TASK_INDEX.md: P2-Task040 完了
- docs/project/CurrentState.md: Task040 完了、v3.5.29
- docs/project/CurrentSprint.md: Task040 完了
- CHANGELOG.md: v3.5.29
- 本文書（新規）

---

## Next

P2-Task041 — BlacksmithScene Foundation（新規シーン + BaseScene 遷移 + consume_materials 使用）
