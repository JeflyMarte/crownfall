# Phase2-M8 Task Proposal v1.0

**Status:** Proposal（未採番・DevelopmentHQ 確認待ち）
**Type:** Task Candidate List
**Created:** 2026-06-22
**Requires:** DevelopmentHQ Decision before Task 化

**Design Input:** `Phase2-M8_Craft_Economy_Foundation_Design_v1.0.md`

---

## 概要

Phase2-M8 Craft & Economy Foundation の実装 Task 候補。

Task 番号は **提案のみ**。Decision 採番は DevelopmentHQ が行う。

---

## 候補 Task 一覧

### P2-Task039 — CraftData Resource Foundation

**目的:** CraftData を実装の最小単位として定義し、DataRegistry に登録する。

**スコープ:**
- `CraftData.gd` Resource スクリプト作成
- MVP レシピ `.tres` ファイル作成（3 件）:
  - `craft_leather_armor.tres`
  - `craft_silver_ring.tres`
  - `craft_bone_armor.tres`
- `DataRegistry.gd` — `get_craft_data(id)` / `get_all_craft_data()` 追加
- `Constants.gd` — `CRAFT_DATA_PATH` 追加

**変更ファイル予想（5 以下）:**
- `scripts/data/CraftData.gd`（新規）
- `resources/crafts/*.tres`（新規 3 件）
- `scripts/autoload/DataRegistry.gd`
- `scripts/core/Constants.gd`
- `docs/specs/implementation/CODEMAP.md`（更新）

**依存 Task:** なし（MaterialData / DataRegistry 実装済み）
**コード変更:** あり（Data 定義のみ、gameplay 変更なし）

---

### P2-Task040 — Material Consumption Logic

**目的:** Blacksmith の「作成」に先立ち、Material 消費ロジックを安全に実装する。

**スコープ:**
- `GameState` — `consume_materials(recipe: CraftData) -> bool` 追加（素材・Gold 充足チェック + 消費）
- `SaveManager` — craft 後の save_game 呼び出し確認（既存フローで対応可能な場合は変更なし）
- 単体テスト相当の動作確認ログ（GDScript print で代替）

**変更ファイル予想（3 以下）:**
- `scripts/autoload/GameState.gd`
- `scripts/save/SaveManager.gd`（確認のみ、変更なしの可能性）
- `docs/specs/implementation/CODEMAP.md`（更新）

**依存 Task:** P2-Task039（CraftData 定義必要）
**コード変更:** あり（GameState のみ、gameplay 変更なし）

---

### P2-Task041 — BlacksmithScene Foundation

**目的:** BaseScene から遷移できる Blacksmith 画面を実装する。最小 UI でレシピ一覧を表示する。

**スコープ:**
- `scenes/blacksmith/BlacksmithScene.tscn` — 新規シーン
- `scripts/blacksmith/BlacksmithScene.gd` — レシピ一覧表示・「作成」ボタン・「戻る」ボタン
- `scenes/base/BaseScene.tscn` — 「鍛冶屋」ボタン追加
- `scripts/base/BaseScene.gd` — 遷移ロジック追加

**UI 要件:**
- VBoxContainer: レシピ名 / 素材（所持数 / 必要数）/ Gold コスト
- 「作成」: 素材・Gold 充足時のみ有効
- 「戻る」: BaseScene へ遷移
- 所持 Gold 表示

**変更ファイル予想（6 以下）:**
- `scenes/blacksmith/BlacksmithScene.tscn`（新規）
- `scripts/blacksmith/BlacksmithScene.gd`（新規）
- `scenes/base/BaseScene.tscn`（Button 追加）
- `scripts/base/BaseScene.gd`（遷移追加）
- `docs/specs/implementation/CODEMAP.md`
- `docs/specs/implementation/04_シーン構成.md`（更新）

**依存 Task:** P2-Task039（CraftData）、P2-Task040（消費ロジック）
**コード変更:** あり（新規シーン + BaseScene 追加）

---

### P2-Task042 — Craft Output Integration

**目的:** 「作成」ボタン押下で Instance を生成し、Inventory に追加する。Economy ループを完成させる。

**スコープ:**
- `BlacksmithScene.gd` — `_on_craft_pressed()` 実装
- `consume_materials()` → Instance 生成 → `[type]_inventory.append()` → `save_game()`
- 出力: 未鑑定 ArmorInstance / AccessoryInstance（既存生成パターン準拠）
- 作成後 UI 更新（素材数・Gold・ボタン有効/無効）

**変更ファイル予想（3 以下）:**
- `scripts/blacksmith/BlacksmithScene.gd`
- `scripts/autoload/GameState.gd`（minor 修正の可能性）
- `docs/specs/implementation/CODEMAP.md`

**依存 Task:** P2-Task041（BlacksmithScene）
**コード変更:** あり（クラフトロジック本体）

---

### P2-Task043 — Economy Integration（Merchant 拡張）

**目的:** Materials を Merchant で購入可能にし、Gold/Material 循環を接続する。

**スコープ:**
- `DungeonScene.gd` or `DungeonController.gd` — Merchant 商品カタログに Material 行を追加
- 価格: `MaterialData.value` 基準（relic_shard: 20G / ancient_bone: 20G）
- UI: Merchant Container に Material 行追加
- 購入 → `GameState.add_material(id, 1)` → `save_game()`

**変更ファイル予想（4 以下）:**
- `scripts/dungeon/DungeonScene.gd` or `DungeonController.gd`
- `scenes/dungeon/DungeonScene.tscn`（UI 追加）
- `docs/specs/game/05_ダンジョン.md`（Merchant カタログ更新）
- `docs/specs/implementation/CODEMAP.md`

**依存 Task:** P2-Task042（Blacksmith 完成後に Materials 需要が生じるため）
**コード変更:** あり（Merchant 拡張・gameplay 変化あり）

---

### P2-Task044 — Phase2-M8 Closeout

**目的:** M8 完了を確認し、ProjectDocs を更新して M9 候補を準備する。

**スコープ:**
- M8 Exit Criteria 確認（Craft ループ動作・Economy 循環確認）
- `docs/specs/` 更新（CraftData スキーマ・Blacksmith フロー・Economy 表）
- `CHANGELOG.md` — M8 完了エントリ
- `CurrentState.md` / `CurrentSprint.md` — M8 完了・M9 Next
- `docs/specs/core/03_Decision_Log.md` — M8 Decision 採番（DevelopmentHQ 決定後）
- `GameplayArchive/Completed/` — M8 Completed 文書

**変更ファイル予想（8 以下）:**
- `docs/specs/game/07_武器_装備.md` or 新規 `craft` spec（Craft 仕様追記）
- `docs/specs/implementation/CODEMAP.md`
- `docs/specs/implementation/11_TASK_INDEX.md`
- `docs/specs/core/02_Roadmap.md`（M8 完了・M9 候補）
- `CHANGELOG.md`
- `docs/project/CurrentState.md`
- `docs/project/CurrentSprint.md`
- `docs/archives/GameplayArchive/Completed/Phase2-M8_Completed_v1.0.md`（新規）

**依存 Task:** P2-Task039〜043
**コード変更:** なし（docs 更新のみ）

---

## M8 Exit Criteria（案）

| 確認項目 | 内容 |
|---|---|
| CraftData 定義 | DataRegistry から 3 件以上のレシピが取得できる |
| Material 消費 | `consume_materials()` が素材と Gold を正しく減算する |
| Instance 生成 | 作成後に未鑑定 Instance が inventory に追加される |
| Save/Load | クラフト後に Save → Load で inventory が保持される |
| Economy 循環 | Event/Elite で取得した Materials が Blacksmith で消費できる |
| UI 表示 | 素材不足・Gold 不足時に「作成」ボタンが無効になる |

---

## Task 依存関係

```text
Task039 CraftData Foundation
  ↓
Task040 Material Consumption Logic
  ↓
Task041 BlacksmithScene Foundation
  ↓
Task042 Craft Output Integration
  ↓
Task043 Economy Integration（Merchant 拡張）
  ↓
Task044 Phase2-M8 Closeout
```

---

## Suggested Decisions（採番なし）

| 項目 | 内容 | 理由 |
|---|---|---|
| CraftData スキーマ採用 | `Phase2-M8_Craft_Economy_Foundation_Design_v1.0.md §2-2` の確定 | 実装前に SSOT 化が必要 |
| MVP レシピ 3 件承認 | `craft_leather_armor` / `craft_silver_ring` / `craft_bone_armor` | 素材バランスの確認 |
| Weapon クラフト可否の意思決定 | MVP では不可を継続するか確認 | Special Room Bible 原則との整合 |
| Merchant Materials 価格帯承認 | relic_shard: 20G / ancient_bone: 20G | Economy バランスの確認 |
| `consume_materials()` の配置 | GameState に追加するか CraftController を別途作成するか | アーキテクチャ判断 |

---

## Next Recommendation

1. DevelopmentHQ で本 Proposal をレビューし、Suggested Decisions を採番する
2. M7 完了（Task036〜038）後に M8 Scope Adoption を実施
3. P2-Task039 から着手
