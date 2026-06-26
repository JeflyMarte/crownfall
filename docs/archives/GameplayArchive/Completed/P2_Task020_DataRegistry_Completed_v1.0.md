# P2_Task020_DataRegistry_Completed_v1.0

**Status:** Completed
**Task:** P2-Task020
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.4.6

---

## 概要

Phase2-M3 最終 Task。DataRegistry をコア Data Resource の正規 lookup 層として SSOT 確定。
一括リファクタ・エディタ UI・hot reload は対象外。

---

## 検証結果

| カテゴリ | メソッド | 検証 id | 結果 |
|---|---|---|---|
| Skill | get_skill_data | slash_attack | OK |
| Weapon | get_weapon_data | iron_sword, rusted_blade | OK |
| Armor | get_armor_data | leather_armor | OK |
| Accessory | get_accessory_data | silver_ring | OK |
| Enemy | get_enemy_data | fallen_soldier 他 4 体 | OK |
| Dungeon | get_dungeon_data | royal_ruins | OK |

規約: `load(Constants.RESOURCE_*_PATH + id + ".tres")`

---

## 実装

- `scripts/autoload/DataRegistry.gd` — 6 lookup メソッド
- `scripts/core/Constants.gd` — RESOURCE_*_PATH 定数
- `project.godot` — Autoload 登録済

---

## inline load() 併存（意図的）

以下は M3 では変更せず、将来 Task で DataRegistry へ段階移行:

- `DungeonController.gd` — enemy / loot load
- `DungeonScene.gd` — accessory load
- `EquipmentScene.gd` — accessory load

---

## 非実装

- AffixData / JobData lookup
- drop_table Resource
- エディタ UI / hot reload
- 全システムの registry 強制化

---

## Decision

P2-D042〜P2-D044

---

## 参照 SSOT

- docs/specs/implementation/03_Resource設計.md — DataRegistry 節
- docs/specs/implementation/01_Godotアーキテクチャ.md — DataRegistry 節

---

## Milestone

**Phase2-M3 Room System — Complete**
