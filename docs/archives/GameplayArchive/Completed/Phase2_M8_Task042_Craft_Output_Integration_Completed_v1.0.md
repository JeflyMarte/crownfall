# Phase2_M8_Task042_Craft_Output_Integration_Completed_v1.0

**Status:** Completed
**Task:** P2-Task042
**Milestone:** Phase2-M8 — Craft & Economy Foundation
**Version:** v1.0
**ProjectDocs:** v3.5.31
**Completed Date:** 2026-06-22

---

## 概要

BlacksmithScene から CraftData を選択し、素材・Gold を消費して armor / accessory Instance を未鑑定で生成する最小 Craft 実行ループ。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| 「作成」ボタン + 検証 | Weapon craft |
| gold / material 消費 | Affix roll |
| ArmorInstance / AccessoryInstance 生成 | Appraisal 変更 |
| inventory 追加 + save_game | Save Format 変更 |
| 最小ステータスログ | Combat / Dungeon 変更 |

---

## Craft Flow

```
_on_craft_pressed(craft)
  1. output_type ∈ {armor, accessory} ?
  2. output_id 非空 + DataRegistry に存在 ?
  3. gold >= gold_cost ?
  4. required_materials 充足 ?
  5. gold 減算
  6. consume_materials(required_materials)
  7. _spawn_armor / _spawn_accessory（is_appraised = false）
  8. SaveManager.save_game()
  9. UI 更新 + "Craft Success: {output_id}"
```

---

## Generated Output

| output_type | Instance | inventory | 状態 |
|---|---|---|---|
| armor | ArmorInstance（rolled_defense 等は DungeonController 同型） | armor_inventory | 未鑑定 |
| accessory | AccessoryInstance | accessory_inventory | 未鑑定 |

MVP レシピ:

| craft_id | output_id | type |
|---|---|---|
| craft_leather_armor | leather_armor | armor |
| craft_bone_armor | bone_armor | armor |
| craft_silver_ring | silver_ring | accessory |

---

## Failure Behavior

| 条件 | 消費 | ログ |
|---|---|---|
| invalid output_type / output_id | なし | Craft Failed: invalid output |
| weapon output_type | なし | Craft Failed: weapon crafting unavailable |
| gold 不足 | なし | Craft Failed: not enough gold |
| material 不足 | なし | Craft Failed: not enough materials |
| weapon output | ボタン押下で拒否 | Craft Failed: weapon crafting unavailable |

---

## Files

- `scripts/blacksmith/BlacksmithScene.gd`
- `scenes/blacksmith/BlacksmithScene.tscn`（LabelStatus 既存）

---

## Deferred

- P2-Task043 — Economy Integration（Merchant 素材購入）

---

## Verification

- 素材・Gold 十分 → armor / accessory 生成 ✓
- 作成品は未鑑定 ✓
- 不足時は何も減らない ✓
- weapon output → 実行されない ✓
- Save / Combat 回帰なし（Save Format 未変更）✓

---

## Next

**P2-Task043** — Economy Integration
