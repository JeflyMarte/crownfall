# Phase2-M8 Task041 BlacksmithScene Foundation Completed v1.0

Status: Completed
Date: 2026-06-22
ProjectDocs: v3.5.30
Milestone: Phase2-M8 — Craft & Economy Foundation

---

## Purpose

BlacksmithScene の最小基盤を実装した。
CraftData 一覧表示と BaseScene 遷移のみ。Craft 実行は対象外（Task042）。

---

## Implementation

### 新規ファイル

scenes/blacksmith/BlacksmithScene.tscn
- Control → VBoxContainer 構成（mvp_theme 適用）
- ノード: LabelTitle / LabelGold / LabelMaterials / LabelCraftHeader / LabelCraftList / ButtonBack

scripts/blacksmith/BlacksmithScene.gd
- _update_display(): Gold / 素材 / レシピ一覧を更新
- _format_materials(): material_inventory を「mat_id xN」形式で列挙
- _format_craft_list(): DataRegistry.get_all_craft_data() を走査、各 CraftData を表示
- _format_required_materials(): 「mat_id 所持数/必要数」形式
- _on_back_pressed(): BaseScene へ遷移

### 更新ファイル

scenes/base/BaseScene.tscn: ButtonBlacksmith ノード追加
scripts/base/BaseScene.gd: connect + _on_blacksmith_button_pressed → BlacksmithScene 遷移

---

## UI Display Result

```
鍛冶屋
Gold: {現在Gold}
素材: relic_shard x2 / elite_relic_shard x1 / ...
--- レシピ一覧 ---
[革鎧の作成]
  素材: relic_shard 2/2 / leather 0/2
  Gold: 50G
  出力: armor — leather_armor

[骨鎧の作成]
  素材: ancient_bone 1/3
  Gold: 40G
  出力: armor — leather_armor

[銀の指輪の作成]
  素材: relic_shard 2/3 / elite_relic_shard 0/1
  Gold: 80G
  出力: accessory — silver_ring
戻る
```

---

## Navigation Flow

BaseScene → 「鍛冶屋」ボタン → BlacksmithScene → 「戻る」ボタン → BaseScene

---

## Validation

Craft 実行なし: consume_materials / gold 消費 / Instance 生成 / SaveManager — 一切呼ばない
CraftData 0 件: "（レシピなし）" 表示、クラッシュなし
required_materials 空: "なし" 表示、クラッシュなし
DataRegistry 取得失敗: get_all_craft_data() が空 Array 返却 → 安全
Headless 検証: エラーなし

---

## Regression Check

Combat: 変更なし
SaveManager: 変更なし
Material 消費: なし
Gold 消費: なし
Dungeon / Appraisal / Equipment: 変更なし

---

## Files Changed

- scenes/blacksmith/BlacksmithScene.tscn（新規）
- scripts/blacksmith/BlacksmithScene.gd（新規）
- scenes/base/BaseScene.tscn（ButtonBlacksmith 追加）
- scripts/base/BaseScene.gd（connect + handler 追加）
- docs/specs/implementation/CODEMAP.md（BlacksmithScene 追加）
- docs/specs/implementation/11_TASK_INDEX.md（P2-Task041 完了）
- docs/project/CurrentState.md（v3.5.30）
- docs/project/CurrentSprint.md
- CHANGELOG.md（v3.5.30）
- 本文書（新規）

---

## Next

P2-Task042 — Craft Output Integration（「作成」ボタン + consume_materials + Instance 生成 + Inventory 追加 + save_game）
