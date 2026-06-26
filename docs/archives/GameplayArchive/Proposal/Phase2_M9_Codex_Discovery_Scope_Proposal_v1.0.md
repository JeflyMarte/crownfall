# Phase2-M9 Codex & Discovery Foundation — Scope Proposal v1.0

**Status:** Proposal → **Adopted**（DevelopmentHQ 2026-06-22 — P2-D148）  
**Version:** v1.0  
**Created:** 2026-06-22  
**SSOT Baseline:** ProjectDocs **v3.5.33**  
**Milestone:** Phase2-M9 — Codex & Discovery Foundation  
**Type:** Scope Definition（実装・Decision Log 更新は本 Proposal 承認後）

---

## Document Status

| 項目 | 内容 |
|---|---|
| 本書の位置づけ | M9 正式 Scope の **提案**。承認前は SSOT ではない |
| 整合対象 | `04_Development_Master_Plan.md` v1.5 / `CurrentState.md` / M8 Closeout |
| M8 | **完了**（Task039〜044） |
| M9 | **未着手**（Next Milestone） |
| 更新禁止（本 Task） | Decision Log / Roadmap / Master Plan / CurrentState / CurrentSprint / Code |

---

# 1. Purpose

Phase2-M9 **Codex & Discovery Foundation** の正式 Scope を提案する。

## 1.1 達成したいこと

**`GameState.discovery_registry` に蓄積された発見情報を、プレイヤーが Base から閲覧できる Codex UI へ接続する。**

M3 で実装済みの Discovery 登録（戦闘・イベント・部屋・素材・lore）を **可視化レイヤー** として完成させ、探索の蓄積感をプレイヤーに返す。

## 1.2 M9 で成立させる Core 体験

```
探索中に DiscoveryRegistry.register() で登録
        ↓
discovery_registry に "category:entry_id" 蓄積（既存 Save 互換）
        ↓
Base → Codex UI でカテゴリ別一覧・詳細閲覧
        ↓
未発見エントリはシルエット / 「？？？」表示
```

## 1.3 Design Constraints

| 原則 | M9 での解釈 |
|---|---|
| **既存 Registry 優先** | 新 Save フィールド禁止。`discovery_registry` Dictionary のみ |
| **Read-Only UI** | Codex は閲覧専用。報酬付与・Unlock 実行なし |
| **Data SSOT 尊重** | 表示テキストは Resource / Bible SSOT から取得。UI に Lore 直書き禁止 |
| **MVP 最小 UI** | `mvp_theme.tres` ベース。演出・Cutscene なし |
| **コンテンツ追加なし** | 新 Enemy / Dungeon / Weapon Resource 作成は M9 外 |

---

# 2. MVP Codex Scope

## 2.1 In Scope — カテゴリ（5 件）

| Codex Tab | 表示対象 | カタログ SSOT | Discovery 連携 |
|---|---|---|---|
| **Enemy** | 登場敵 | `EnemyData`（`resources/enemies/`） | 既存 `"enemy:{id}"` — 戦闘部屋入室時登録済 |
| **Dungeon** | 探索ダンジョン | `DungeonData`（`resources/dungeons/`） | **新規登録提案** `"dungeon:{id}"` — 初回探索開始時 |
| **Material** | 素材 | `MaterialData`（`resources/materials/`） | 既存 `"material:{id}"` — Event/Elite 等 |
| **Weapon** | 武器種 | `WeaponData`（`resources/weapons/`） | **新規登録提案** `"weapon:{id}"` — 初回ドロップ/インベントリ追加時 |
| **History** | 歴史条目 | `16_HistoryBible.md`（HE-xxx） | 既存 `"lore:{id}"` + Bible entry_id マッピング |

## 2.2 MVP カタログ規模（現行プレイアブル）

| カテゴリ | MVP 表示件数（目安） | 備考 |
|---|---|---|
| Enemy | 11 | DataRegistry 全 EnemyData |
| Dungeon | 2 | royal_ruins / graveyard |
| Material | 5 | relic_shard 等 |
| Weapon | 2 | rusted_blade / iron_sword |
| History | サブセット | 発見済み lore に紐づく HE 条目 + 固定スターター 4 件（時代区分） |

## 2.3 Out of Scope — Codex タブ外（M9 非表示）

| 既存 category | 例 | 移管 |
|---|---|---|
| `room` | heal / merchant / elite | M9 外（将来 Special Room Codex 候補） |
| `event` | fallen_altar 等 | M9 外 |
| `lore`（生 id） | royal_ruins_inscription | **History タブへ統合表示**（Task049） |

---

# 3. Codex UI Structure

## 3.1 シーン構成（提案）

```
BaseScene
  └─ ButtonCodex → CodexScene（新規）
       ├─ CategoryTabs（HBox / TabButton × 5）
       ├─ EntryList（ScrollContainer + VBox）
       ├─ EntryDetail（Label 群 — 選択 entry）
       └─ ButtonBack → BaseScene
```

## 3.2 最小 UI 要素

| 要素 | 要件 |
|---|---|
| **Category Tabs** | Enemy / Dungeon / Material / Weapon / History |
| **Entry List** | カテゴリ内全 entry を id 順または display_name 順 |
| **Entry Detail** | display_name / description（または Bible 抜粋）/ 発見状態 |
| **Discovered** | 発見済: 名称 + 説明表示 |
| **Undiscovered** | 未発見: `？？？` + 説明非表示（id は非表示） |
| **進捗（任意・最小）** | タブ見出しに `3/11` 形式（Task047 で実装可） |

## 3.3 遷移

```
Boot → Base → Codex → Base
（Dungeon / Blacksmith / Equipment フローは変更しない）
```

---

# 4. Discovery Rules

## 4.1 保存形式（変更禁止）

```gdscript
# GameState.discovery_registry — 既存
# Key: "category:entry_id"  Value: true
```

- **新規 Save フィールド禁止**
- SaveManager の serialize / deserialize **フォーマット変更禁止**

## 4.2 既存 DiscoveryRegistry（現状）

```gdscript
const CATEGORIES: Array[String] = ["room", "enemy", "event", "lore", "material"]
```

| 関数 | 役割 |
|---|---|
| `register(category, entry_id)` | 初回のみ true 登録 |
| `is_discovered(category, entry_id)` | Codex 表示判定 |
| `count_by_category(category)` | 進捗表示 |

## 4.3 M9 提案 — Category 拡張（最小）

Codex MVP 達成のため、**同一 Dictionary 形式** で category 追加を提案:

| 追加 category | 登録タイミング | 変更ファイル（予定） |
|---|---|---|
| `dungeon` | `DungeonController.start_dungeon()` 初回 | DungeonController.gd |
| `weapon` | 武器 Instance が inventory に初追加 | DungeonController.gd または Drop 経路 |

> **Note:** `DiscoveryRegistry.CATEGORIES` への追加は Save 形式に影響しない（key 文字列拡張のみ）。

## 4.4 History / Lore マッピング（提案）

| discovery_registry key | Codex History 表示 |
|---|---|
| `lore:royal_ruins_inscription` | HE-xxx（Task049 で SSOT マップ定義） |
| Event outcome `lore` type | 同上 |

- History Bible 全 66 件を一度に表示しない
- **Codex カタログ = MVP 表示対象 HE リスト**（Resource または Constants）を Task046 で定義
- 未発見 History は `？？？`

---

# 5. Data Sources

## 5.1 Gameplay Resource（Codex カタログ）

| SSOT | パス | Codex 取得フィールド |
|---|---|---|
| EnemyData | `resources/enemies/{id}.tres` | id, display_name（description 追加は M9 外） |
| DungeonData | `resources/dungeons/{id}.tres` | id, display_name |
| MaterialData | `resources/materials/{id}.tres` | id, display_name, description, lore_id |
| WeaponData | `resources/weapons/{id}.tres` | id, display_name |
| DataRegistry | `scripts/autoload/DataRegistry.gd` | get_*_data / 一覧走査 API（Task046 追加） |

## 5.2 Lore SSOT（Codex History / Dungeon フレーバー）

| SSOT | パス | 用途 |
|---|---|---|
| History Bible | `docs/specs/game/16_HistoryBible.md` | History タブ本文（HE-xxx） |
| Dungeon Bible | `docs/specs/game/22_DungeonBible.md` | Dungeon タブ補足説明（Dungeon-001〜013 ↔ playable id マップ） |

## 5.3 現行 discovery 登録箇所

| トリガー | category | entry_id 例 |
|---|---|---|
| Special Room 入室 | room | heal / merchant / elite |
| 戦闘開始 | enemy | fallen_soldier |
| Event 選択 | event | fallen_altar |
| Event material | material | relic_shard |
| Event lore | lore | royal_ruins_inscription |
| Elite material | material | elite_relic_shard |

## 5.4 Playable ↔ Bible 対応（MVP 提案）

| DungeonData.id | display_name | Dungeon Bible（参考） |
|---|---|---|
| royal_ruins | 王都跡 | Dungeon-001 White Capital 系 |
| graveyard | 白骸墓地 | Dungeon-002 Royal Mausoleum 系 |

> Bible 全文は Codex に載せない。**1 ダンジョンあたり Overview 1 段落** を Task049 で抽出表示。

---

# 6. Task Plan（P2-Task045〜050）

## 6.1 概要

| Task | 名称 | Purpose | 依存 |
|---|---|---|---|
| **P2-Task045** | Codex Scope Adoption | 本 Proposal 正式採用。Decision Log / ProjectDocs 同期 | 本 Proposal |
| **P2-Task046** | Codex Data Foundation | CodexCatalogHelper / category 拡張 / DataRegistry 一覧 API | Task045 |
| **P2-Task047** | Codex UI Foundation | CodexScene + BaseScene 遷移 + Tabs + List | Task046 |
| **P2-Task048** | Discovery Detail View | Entry Detail / Discovered-Undiscovered 表示 | Task047 |
| **P2-Task049** | History / Dungeon Bible Link | History・Dungeon タブに Bible 抜粋接続 | Task046, Task048 |
| **P2-Task050** | Phase2-M9 Closeout | Milestone 完了宣言 / ProjectDocs 同期 | Task045〜049 |

## 6.2 P2-Task045 — Codex Scope Adoption

- Decision 候補: M9 Scope 採用 / Codex 5 カテゴリ / Save 形式不変 / category 拡張方針
- 更新: Decision Log, Roadmap, Master Plan, CurrentState, CurrentSprint, Task Index
- **コード変更なし**

## 6.3 P2-Task046 — Codex Data Foundation

**Output（提案）:**

- `scripts/codex/CodexCatalogHelper.gd`（class_name + static API）
- `DiscoveryRegistry.CATEGORIES` に `dungeon` / `weapon` 追加（要 Decision）
- `DataRegistry.get_all_enemy_data()` 等 — 一覧取得（既存 get_all_craft_data 同型）
- `dungeon` / `weapon` 初回 register フック（最小 diff）

**API 案:**

```gdscript
CodexCatalogHelper.get_entries(category: String) -> Array[Dictionary]
# { "entry_id", "display_name", "discovered", "description", "extra" }

CodexCatalogHelper.get_progress(category: String) -> Dictionary
# { "discovered": int, "total": int }
```

## 6.4 P2-Task047 — Codex UI Foundation

**Output（提案）:**

- `scenes/codex/CodexScene.tscn` + `scripts/codex/CodexScene.gd`
- `BaseScene` — 「図鑑」ボタン + SceneRouter 遷移
- Category Tabs + Entry List（Detail は Task048）

## 6.5 P2-Task048 — Discovery Detail View

- リスト選択 → Detail パネル更新
- Discovered: 名称 + description
- Undiscovered: `？？？` + 説明ロック
- 既存 `DiscoveryRegistry.is_discovered()` 使用

## 6.6 P2-Task049 — History / Dungeon Bible Link

- History タブ: HE-xxx 条目表示（発見済みのみ本文、未発見は `？？？`）
- Dungeon タブ: DungeonData + Bible Overview 1 段落
- **Bible ファイルは Read-only 参照** — Runtime parse または Task046 で定義した CodexHistoryEntry Resource サブセット
- MaterialData.lore_id → History entry リンク（任意 MVP）

## 6.7 P2-Task050 — Phase2-M9 Closeout

- Exit Criteria 確認
- Completed Archive + CHANGELOG + ZIP
- Next Milestone 候補: Phase3-A Visual Production または Phase2 残 Defer 整理

---

# 7. Exclusions（M9 非対象）

| 項目 | 理由 |
|---|---|
| Achievement | 報酬系 — M9 外 |
| Collection Rewards | 報酬系 — M9 外 |
| Hidden Boss Unlock | Gameplay 変更 — M9 外 |
| Map UI | 別 Milestone |
| Lore Cutscene | 演出 — Phase3-A 以降 |
| New Dungeon | コンテンツ — Phase3-B |
| New Enemy | コンテンツ — Phase3-B |
| New Weapon | コンテンツ — Phase3-B |
| room / event Codex タブ | MVP 5 カテゴリに含めない |
| Codex Search / Filter | UI polish — Defer |
| 発見通知 UI 改修 | 既存 LabelLog `【新規発見】` 維持 |
| Save Format 変更 | 禁止 |
| discovery_registry 以外の Collection 保存 | 禁止 |

---

# 8. Success Criteria（Exit Criteria 案）

| # | 確認項目 |
|---|---|
| EC-1 | Base から CodexScene に遷移できる |
| EC-2 | 5 カテゴリ Tab で Entry List が表示される |
| EC-3 | 発見済み entry は名称 + 詳細が見える |
| EC-4 | 未発見 entry は `？？？` でクラッシュしない |
| EC-5 | Enemy / Material は **既存 discovery 登録** で正しく Discovered になる |
| EC-6 | Dungeon / Weapon は **新規 register フック** 後に Discovered になる |
| EC-7 | History / Dungeon タブに Bible 抜粋が表示される（Task049） |
| EC-8 | Save → Load 後も discovery_registry / Codex 表示が一致 |
| EC-9 | 王都跡 / 白骸墓地 完走可能（Combat / Dungeon 回帰なし） |
| EC-10 | Achievement / 報酬 / Unlock gameplay **なし** |

---

# 9. Risks & Open Questions

| ID | リスク / 論点 | 提案対応 |
|---|---|---|
| R-1 | History Bible 66 件全文 UI 載せ不可 | MVP サブセット + 発見済みのみ本文 |
| R-2 | EnemyData / WeaponData に description なし | display_name のみ MVP。description 空は許容 |
| R-3 | `room` / `event` category は Codex 非表示 | 登録は維持。将来 Tab 追加可 |
| R-4 | Bible Runtime parse コスト | Task049: 事前抽出 Resource または Constants マップ推奨 |
| R-5 | Dungeon Bible 13 件 vs プレイ 2 件 | 未プレイ DG は `？？？` または非表示（Decision 要） |

### Decision 候補（Task045 で採番）

| 候補 ID | 内容 |
|---|---|
| P2-D148 | Phase2-M9 Scope 本 Proposal 採用 |
| P2-D149 | Codex MVP カテゴリ = Enemy / Dungeon / Material / Weapon / History |
| P2-D150 | discovery_registry 形式不変。category 拡張のみ |
| P2-D151 | Codex UI = BaseScene 遷移・閲覧専用 |
| P2-D152 | History Bible MVP = サブセット表示（全 66 件一括非表示） |
| P2-D153 | Task045〜050 を M9 正式 Task 計画とする |

---

# 10. Dependency & Sequencing

```
P2-Task045  Scope Adoption
    ↓
P2-Task046  Codex Data Foundation（Registry 拡張 + CatalogHelper）
    ↓
P2-Task047  Codex UI Foundation（Scene + Tabs + List）
    ↓
P2-Task048  Discovery Detail View
    ↓
P2-Task049  History / Dungeon Bible Link
    ↓
P2-Task050  M9 Closeout
```

**推奨:** 1 Task / 1 依頼（CLAUDE.md 運用）。Task047 と Task048 は分割し、Detail なし List-only 中間状態を避ける。

---

# 11. Relationship to Master Plan

| Master Plan 記載 | 本 Proposal |
|---|---|
| M9 Purpose: discovery_registry → 閲覧 UI | §1 Purpose 一致 |
| Major systems: Codex UI / カテゴリ閲覧 | §2〜3 |
| Exit Criteria 案: 登録 entry 閲覧 | §8 EC-1〜EC-8 |
| Deferred: Codex UI（M8 まで） | M9 で解消 |

---

# 12. Document History

| Version | Date | Note |
|---|---|---|
| v1.0 | 2026-06-22 | 初版 Proposal。ProjectDocs v3.5.33 整合 |

---

**Next Step:** DevelopmentHQ レビュー → **P2-Task045 Codex Scope Adoption**
