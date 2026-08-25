# 装備袋所持上限（P3-EQ-INV-CAP-001 / 002）

**Status:** Decision 承認済（2026-08-08 GO 合計200 → **2026-08-26 GO 合計400**）  
**上書き:** 装備インベントリ無制限（既往の暗黙前提）

---

## 1. 方針

武・防・飾の所持は **合計 400** をハード上限とする。レリックは解放型のまま別枠。

| 項目 | 内容 |
|---|---|
| 上限 | `Constants.MAX_EQUIPMENT_INVENTORY = 400`（武+防+飾合算） |
| 表示 | 装備品一覧 `LabelCount` を `現在/400件`（所持合計。フィルタ非連動） |
| 満杯時 | 新規入手不可（ドロップ付与スキップ／生産・封蔵は拒否。消費しない） |
| 既存超過 | セーブはそのまま。分解で減るまで新規不可 |
| 例外 | 初期武器付与・デバッグ全所持は `ignore_cap` |
| 性能（002） | 着脱時は装備スロット即更新＋一覧セル差分パッチ。`find_item_equipped_owner` は instance_id キャッシュ |

---

## 2. SSOT

- `Constants.MAX_EQUIPMENT_INVENTORY`
- `GameState.equipment_inventory_count` / `can_add_equipment` / `try_add_*_instance` / `equipment_inventory_count_label`
- `GameState.mark_equipped_item_owner_cache_dirty` / `rebuild_equipped_item_owner_cache`
- 入手経路は `try_add_*` 経由（Dungeon／Event／Abyss／Survey／Craft／Gacha）
