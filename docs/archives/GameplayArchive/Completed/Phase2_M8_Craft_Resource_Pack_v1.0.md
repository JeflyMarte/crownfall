# Phase2-M8 Craft Resource Pack v1.0

Status: Completed
Approved By: DevelopmentHQ
Version: v1.0
Date: 2026-06-22
Task Type: Parallel Task（M7 並行実施）

Design Basis: Phase2-M8_Craft_Economy_Foundation_Design_v1.0.md

---

## Purpose

Phase2-M8 開始直後に Blacksmith 実装が進められるよう、CraftData / RecipeData Resource を先行作成した。
Gameplay への接続はなし。コード変更は Resource 登録のみ。

---

## Created Scripts

- scripts/data/CraftData.gd
- scripts/data/RecipeData.gd

---

## Created Resources

### Materials（新規追加）

- resources/materials/leather.tres（id: leather / category: hide / rarity: 0）

### CraftData（resources/crafting/）

- craft_leather_armor.tres — leather×2 + relic_shard×1 / 50G / output: leather_armor
- craft_bone_armor.tres — ancient_bone×3 / 40G / output: leather_armor
- craft_silver_ring.tres — relic_shard×3 + elite_relic_shard×1 / 80G / output: silver_ring

### RecipeData（resources/recipes/）

- recipe_leather_armor.tres — craft_leather_armor 対応・category: armor
- recipe_bone_armor.tres — craft_bone_armor 対応・category: armor
- recipe_silver_ring.tres — craft_silver_ring 対応・category: accessory

---

## Updated Code

- scripts/core/Constants.gd: RESOURCE_CRAFTING_PATH / RESOURCE_RECIPES_PATH 追加
- scripts/autoload/DataRegistry.gd: get_craft_data() / get_all_craft_data() / get_recipe_data() 追加

---

## Updated Docs

- docs/specs/implementation/CODEMAP.md: CraftData.gd / RecipeData.gd / crafting・recipes ディレクトリ追記
- docs/specs/implementation/03_Resource設計.md: CraftData / RecipeData スキーマ追記、MaterialData サンプルに leather 追加
- docs/specs/implementation/11_TASK_INDEX.md: 本 Task を登録

---

## Validation

- .tres ファイル全 7 件: GDResource format=3 準拠・script_class 正確
- id 重複なし（craft_*/recipe_* プレフィックスで分離）
- CraftData.required_materials の key は全て既存 MaterialData.id を参照
- DataRegistry.get_all_craft_data(): DirAccess で resources/crafting/ を走査
- Gameplay コード（Combat / Dungeon / Save / Merchant / UI）への変更なし

---

## Next

Phase2-M8 正式開始後、以下の Task でこの Resource を消費する。
- P2-Task040: Material Consumption Logic（GameState.consume_materials）
- P2-Task041: BlacksmithScene Foundation（DataRegistry.get_all_craft_data 使用）
- P2-Task042: Craft Output Integration
