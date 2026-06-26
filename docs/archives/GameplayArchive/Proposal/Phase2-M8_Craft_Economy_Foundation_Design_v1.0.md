# Phase2-M8 Craft & Economy Foundation — Design Document v1.0

**Status:** Proposal
**Type:** Pre-Implementation Design
**Phase:** Phase2-M8（未着手）
**Created:** 2026-06-22
**Author:** DevelopmentHQ

**関連文書:**
- `docs/specs/core/05_Backlog.md`（M8 候補一覧）
- `docs/specs/core/04_Development_Master_Plan.md`（M8 定義）
- `docs/archives/GameplayArchive/Completed/Special_Room_Bible_v1.0.md`（Merchant / Economy 基盤）
- `scripts/data/MaterialData.gd`
- `scripts/autoload/GameState.gd`（`material_inventory`）

---

## 1. 設計目的

M8 の目標は **Material 消費ループの完成** と **Blacksmith による Gold/Material 双方のシンク確立** にある。

- M3〜M6 で Material 取得経路（Event / Elite Room）は実装済み。
- M8 で **使い道** を提供し、Economy ループを閉じる。
- Weapon は Blacksmith でも排出しない（Special Room Bible 原則を継承）。
  ただし CraftData スキーマは将来の Weapon クラフト拡張に対応できる設計にする。

---

## 2. CraftData — Resource Schema

### 2-1. 設計方針

- CraftData は 1 レシピ = 1 Resource ファイル（`.tres`）。
- `DataRegistry` に登録し、`BlacksmithScene` が一覧取得する。
- MVP では Armor / Accessory のみ出力。Weapon は `output_type = "weapon"` として将来予約。

### 2-2. フィールド定義

| フィールド | 型 | 説明 |
|---|---|---|
| `id` | String | レシピ ID（例: `craft_leather_armor`） |
| `display_name` | String | 表示名（例: 「革鎧の作成」） |
| `required_materials` | Dictionary | `{ material_id: quantity }`（複数素材対応） |
| `gold_cost` | int | 消費 Gold（`GameState.gold` から即時減算） |
| `output_type` | String | `"armor"` / `"accessory"` / `"weapon"`（将来） |
| `output_id` | String | 生成する Data の id（例: `leather_armor`） |
| `unlock_condition` | String | `""` = 常時解放 / 将来: `"discovery:room/merchant"` など |

### 2-3. MVP レシピ案（暫定 3 件）

| id | display_name | required_materials | gold_cost | output_type | output_id |
|---|---|---|---|---|---|
| `craft_leather_armor` | 革鎧の作成 | `{relic_shard: 2}` | 50G | armor | `leather_armor` |
| `craft_silver_ring` | 銀の指輪の作成 | `{relic_shard: 3, elite_relic_shard: 1}` | 80G | accessory | `silver_ring` |
| `craft_bone_armor` | 骨鎧の作成 | `{ancient_bone: 3}` | 40G | armor | `leather_armor` |

**注意:** 出力 Instance は未鑑定状態で生成し、AppraisalScene で鑑定する（既存フロー互換）。

### 2-4. GDScript スキーマ（実装参考）

```gdscript
class_name CraftData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var required_materials: Dictionary = {}  # { material_id: int }
@export var gold_cost: int = 0
@export var output_type: String = ""  # "armor" | "accessory" | "weapon"
@export var output_id: String = ""
@export var unlock_condition: String = ""
```

---

## 3. RecipeData — 設計方針

RecipeData は CraftData の「カテゴリ別ビュー」として機能する。M8 MVP では CraftData に統合し、独立 Resource は不要。

### 3-1. カテゴリ別出力対象

| output_type | 対象 Data | 出力 Instance | 実装状態 |
|---|---|---|---|
| armor | ArmorData | ArmorInstance（未鑑定） | M8 対象 |
| accessory | AccessoryData | AccessoryInstance（未鑑定） | M8 対象 |
| weapon | WeaponData | WeaponInstance（未鑑定） | 将来 Phase |

### 3-2. Instance 生成フロー

```text
CraftData.output_id → DataRegistry.get_[type]_data(id)
  → [Type]Instance.new()
  → Instance.is_appraised = false
  → GameState.[type]_inventory.append(Instance)
  → SaveManager.save_game()
```

- 既存の Loot 生成フロー（`DungeonController.generate_loot()`）と同一パターンを踏む。
- アーキテクチャの整合性を保つため、専用の `CraftController.gd` か `BlacksmithScene` 内のロジックで実装する。

### 3-3. Material スキーマ互換性

現行 `MaterialData` フィールドとの対応:

| MaterialData | CraftData 用途 |
|---|---|
| `id` | `required_materials` の Dictionary キー |
| `display_name` | Blacksmith UI での素材名表示 |
| `rarity` | 将来: レシピ品質判定 |
| `category` | 将来: カテゴリフィルタ |
| `value` | 将来: Merchant での素材買取価格 |

---

## 4. Blacksmith Design

### 4-1. 設計方針

- Blacksmith は **BaseScene に常設** の施設。
- ボタン 1 つで BlacksmithScene へ遷移（Appraisal / Equipment と同列）。
- 戦闘中・ダンジョン探索中はアクセス不可。

### 4-2. UI Flow

```text
BaseScene
  → 「鍛冶屋」ボタン（ButtonBlacksmith）
  → BlacksmithScene
    ├─ レシピ一覧（VBoxContainer: 各 RecipeRow）
    │   ├─ display_name
    │   ├─ required_materials（所持数 / 必要数）
    │   └─ gold_cost（現在 Gold / 消費 Gold）
    ├─ 「作成」ボタン（条件充足時のみ有効）
    └─ 「戻る」ボタン → BaseScene
```

### 4-3. Craft Flow

```text
1. 入場 → DataRegistry.get_all_craft_data() → レシピ一覧表示
2. レシピ選択 → 素材チェック（has_enough_materials）+ Gold チェック
3. 「作成」ボタン押下
4. consume_materials()  — GameState.material_inventory から減算
5. GameState.gold -= gold_cost
6. generate_craft_output()  — Instance 生成・Inventory 追加
7. SaveManager.save_game()
8. UI 更新（所持数・Gold・作成可否）
```

### 4-4. Gold Sink

| 消費タイミング | 消費先 |
|---|---|
| 作成確定時 | `GameState.gold`（Appraisal / Merchant と共通の永続 Gold） |

**設計意図:** Blacksmith はダンジョン外の唯一の能動的 Gold 消費先（Appraisal は自動フロー）。プレイヤーが「いつ使うか」を選べる。

### 4-5. Material Consumption

```gdscript
# 素材消費（実装参考）
func consume_materials(recipe: CraftData) -> void:
    for mat_id in recipe.required_materials:
        var qty: int = recipe.required_materials[mat_id]
        var current: int = GameState.get_material_quantity(mat_id)
        GameState.material_inventory[mat_id] = current - qty
```

`GameState.add_material()` / `get_material_quantity()` は実装済み。消費は差分演算で実装する。

### 4-6. Future Upgrade Hook

| フィールド | 将来用途 |
|---|---|
| `CraftData.unlock_condition` | Discovery 達成 / ボス撃破 / Dungeon 解放 などの条件接続 |
| `CraftData.output_type = "weapon"` | Weapon クラフト実装時の拡張口 |
| `MaterialData.category` | レシピのカテゴリフィルタ / カタログ表示 |
| `MaterialData.value` | Merchant での素材買取（将来 Task） |

---

## 5. Economy Design

### 5-1. 現行 Gold Economy（M7 完了時点）

**Gold 供給源（Gold Sources）:**

| 源泉 | 金額 | 条件 |
|---|---|---|
| 戦闘報酬（COMBAT） | 可変（`run_gold_reward` 累積） | 敵撃破ごと |
| ELITE 報酬 | 通常 × 1.5（`ELITE_REWARD_MULTIPLIER`） | Elite Room 撃破 |
| TREASURE Room | +30G（`TREASURE_GOLD`） | Treasure Room 入室 |
| EVENT（gold type） | +25G | Event Room・gold イベント選択 |

**Gold 消費先（Gold Sinks）:**

| 消費先 | 金額 | 条件 |
|---|---|---|
| 鑑定（Appraisal） | 100G / 武器 | AppraisalScene |
| Merchant — armor | 40G | Merchant Room |
| Merchant — accessory | 60G | Merchant Room |
| Merchant — heal | 35G | Merchant Room |

**Gold 循環評価（M7 時点）:**
- 供給: Treasure / Elite / COMBAT / EVENT
- 消費: Appraisal（強制的）、Merchant（任意）
- **課題:** Merchant は run 中のみ消費可能。永続 Gold の積極的消費先が Appraisal のみ。

### 5-2. M8 追加後の Gold Economy

| 追加 Sink | 金額（目安） | 条件 |
|---|---|---|
| Blacksmith（armor craft） | 40〜80G | BaseScene・任意 |
| Blacksmith（accessory craft） | 60〜100G | BaseScene・任意 |

**M8 後の循環:**
```
COMBAT / ELITE / TREASURE / EVENT → Gold 取得
  → Appraisal（鑑定消費・ランダム）
  → Merchant（ラン中・任意）
  → Blacksmith（ベース・任意）  ← M8 新規
```

### 5-3. 現行 Material Economy（M7 完了時点）

**Material 供給源（Material Sources）:**

| 源泉 | 素材 | 確率 | ダンジョン |
|---|---|---|---|
| EVENT（material type） | `relic_shard` × 1 | 1/5 Events | 王都跡 |
| ELITE 報酬 | `elite_relic_shard` × 1 | 15% | 全 DG |
| （未実装）白骸墓地 | `ancient_bone` | 将来 Task | 白骸墓地 |
| （未実装）呪いの鉄 | `cursed_iron` | 将来 Task | TBD |

**Material 消費先（Material Sinks）:**

| 消費先 | 状態 |
|---|---|
| なし | **M7 時点では消費経路ゼロ** |

**M8 後の Material 循環:**
```
Event Room / Elite Room → Material 取得
  → material_inventory（永続保存済み）
  → Blacksmith クラフト消費  ← M8 新規
```

### 5-4. Economy 設計原則（M8）

| 原則 | 内容 |
|---|---|
| Gold 循環完成 | 獲得（run）→ 消費（Appraisal / Merchant / Blacksmith）の 3 経路 |
| Material 循環開始 | 取得（Event/Elite）→ 消費（Blacksmith）の最小ループ |
| Weapon 不介入 | Blacksmith は Weapon を生成しない（MVP） |
| 過剰 Sink 防止 | クラフトコストを Appraisal（100G）と比較して均衡を保つ |

### 5-5. Merchant Expansion（将来 Task — M8 候補）

| 追加機能 | 内容 |
|---|---|
| Materials 購入 | `relic_shard` / `ancient_bone` を Merchant で購入可能に |
| Materials 価格 | `MaterialData.value` を基準に設定 |
| 武器 | 引き続き販売禁止（Special Room Bible 原則） |

---

## 6. 互換性メモ

| 既存システム | 互換状態 |
|---|---|
| `GameState.material_inventory` | CraftData 消費の直接対象。`add_material()` / `get_material_quantity()` 実装済み |
| `SaveManager` | `material_inventory` は保存済み。Blacksmith 後に `save_game()` 呼び出しで対応 |
| `DataRegistry` | `get_craft_data(id)` / `get_all_craft_data()` を M8 で追加 |
| ArmorInstance / AccessoryInstance | 生成パターンは既存 Loot フローに準拠 |
| AppraisalScene | Blacksmith 出力（未鑑定 Instance）は既存フロー通り鑑定可能 |
| Special Room Bible | Weapon 不排出原則を継承 |

---

## 7. Future Considerations

| 機能 | 対象 Phase |
|---|---|
| Weapon クラフト | 将来 Decision 後（M8 以降） |
| Materials 買取（Merchant） | 将来 Task |
| Craft unlock_condition 接続 | M9 Discovery 連携候補 |
| レシピ解放演出 | Phase3-A Visual Production |
| Affix 付与クラフト（強化） | Phase3-B Content Expansion |
