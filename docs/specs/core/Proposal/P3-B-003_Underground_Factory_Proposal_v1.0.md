# P3-B-003 — 地下工廠（Underground Factory）Proposal v1.0

**Status:** Proposal（DevelopmentHQ 起草 — **Adopted** 2026-06-25）  
**Version:** v1.0  
**Created:** 2026-06-25  
**SSOT Baseline:** ProjectDocs **v3.5.62**  
**Phase:** Phase3-B — Content Expansion（P3-D025）  
**Type:** Scope Definition（実装は本 Proposal 承認後 **P3-B-004** として発行）

---

## Document Status

| 項目 | 内容 |
|---|---|
| 本書の位置づけ | 3 ダンジョン目の正式 Scope **提案**。承認前は SSOT ではない |
| 整合対象 | `05_ダンジョン.md` / `12_モンスター.md` / `27_状態異常と属性.md` / P2-Task023 パターン |
| 前提完了 | P3-B-001（墓地バランス）/ P3-B-002（王都跡イベント） |
| 実装 Task 名（案） | **P3-B-004** — 地下工廠プレイアブル追加 |

---

# 1. Purpose

Phase3-B の **3 ダンジョン目**として「地下工廠」を追加し、**感電 + 機械系**ビルドフック（P3-D024g）をプレイ可能にする。

### 達成したいこと

- Base から **3 つ目のダンジョン**を選択・完走できる
- 王都跡（属性弱点）・白骸墓地（状態異常）に続く **第 3 のビルド軸**を体験できる
- 既存 Multi-Dungeon 基盤（Task021〜023）を **破壊せず**拡張する

### Core 体験（1 周）

```
地下工廠を選択 → 10 部屋完走（分岐あり）
        ↓
敵の感電 on_hit / 電気弱点ビルドが効く
        ↓
工廠専用イベント 3 件 + ボス「炉心の巨人」
```

---

# 2. Dungeon Design

## 2.1 基本パラメータ（提案）

| 項目 | 値 | 根拠 |
|---|---|---|
| id | `underground_factory` | `05_ダンジョン.md` 既存 id |
| display_name | 地下工廠 | SSOT 表記 |
| difficulty | **3** | 王都 1 → 墓地 2 → 工廠 3 |
| room_count | 10 | 既存 DG 同一 |
| branch_enabled | **true** | 墓地と同型。最難 DG は分岐で厚み |
| boss_id | `furnace_giant` | Enemy Bible |
| drop_table_id | `underground_factory_drops` | 命名規約踏襲 |

## 2.2 ビルドフック

| 軸 | 王都跡 | 白骸墓地 | **地下工廠** |
|---|---|---|---|
| テーマ | 属性弱点 | 毒・冷却・Affix | **感電 + 機械** |
| 推奨ビルド | fire / thunder 武器 | septic / chilling Affix | **shocking Affix / static_strike / thunder 弱点** |
| 敵 on_hit | ignite 等 | poison / chill | **shock**（複数敵） |

## 2.3 難易度目安

- 白骸墓地（P3-B-001）比 **+8〜12%**（HP / ATK）
- 1 周 **6〜8 分**（分岐あり。Alpha 目標 5〜7 分は実装後プレイテストで微調整）
- ボス `furnace_giant` 初期案: HP **680** / ATK **40**（墓守 630/38 比 +8% 前後）

## 2.4 敵プール

Enemy Bible（`12_モンスター.md` / archives Enemy Bible）の ID を **そのまま**使用。

| id | 表示名 | enemy_type | プール | 役割 |
|---|---|---|---|---|
| broken_automaton | 壊れた自動人形 | NORMAL | enemy | 標準機械兵・感電入門 |
| furnace_worker | 炉心作業兵 | NORMAL | enemy | 炎上 on_hit（炉テーマ） |
| iron_hound | 鉄の番犬 | NORMAL | enemy + elite | 高速・感電 |
| mass_golem | 量産型ゴーレム | ELITE | elite | 高耐久エリート |
| furnace_giant | 炉心の巨人 | BOSS | boss | 感電 + thunder 弱点 |

```text
enemy_pool  = [broken_automaton, furnace_worker, iron_hound]
elite_pool  = [mass_golem, iron_hound]
```

**注:** 通常敵は Bible 上 3 体のみ。4 体目の追加は **本 Task スコープ外**（将来拡張）。

## 2.5 敵ステータス案（初版・Impl 微調整可）

| id | max_hp | attack | defense | on_hit | weakness |
|---|---:|---:|---:|---|---|
| broken_automaton | 100 | 15 | 7 | shock 25% | thunder, holy |
| furnace_worker | 88 | 16 | 5 | ignite 25% | ice |
| iron_hound | 75 | 16 | 8 | shock 20% | thunder |
| mass_golem | 185 | 17 | 24 | shock 30% | thunder, holy |
| furnace_giant | 680 | 40 | 22 | shock 30% | thunder, ice |

EXP / Gold は墓地同型敵比 +10% 前後で平行移動（Impl 時に `bone_walker` / `gravekeeper` 比で設定）。

## 2.6 専用イベント（`EVENTS_UNDERGROUND_FACTORY`）3 件

`_get_event_pool()` で `EVENTS` + 工廠プールを結合（王都跡・墓地と同パターン）。

| id | 概要 | outcome A |
|---|---|---|
| sparking_panel | 火花散る配電盤。触るか？ | buff ×1.12 |
| rusted_conveyor | 停止した搬送帯に部品が残る。回収するか？ | gold +22 |
| maker_inscription | 職人の銘板。読むか？ | lore → `underground_factory_maker_mark`（Codex **HE-039**） |

`CatalogHelper.LORE_TO_HISTORY` に `underground_factory_maker_mark: HE-039` を追加。

## 2.7 Codex / Lore

| 種別 | 対応 |
|---|---|
| Dungeon タブ | `underground_factory` — 初回完走 or 入室で discovery（既存 dungeon カテゴリ） |
| History | イベント lore → HE-039 Hall of Makers |
| Dungeon Bible 行 | **本 Task では未追加**（`22_DungeonBible.md` に Dungeon-0xx 新設は P3-B-004 後続 or 別 Task） |

---

# 3. Implementation Scope（P3-B-004 案）

## 3.1 In Scope

| # | 領域 | 変更 |
|---|---|---|
| 1 | **DungeonData** | `resources/dungeons/underground_factory.tres` |
| 2 | **EnemyData ×5** | `resources/enemies/{broken_automaton,furnace_worker,iron_hound,mass_golem,furnace_giant}.tres` |
| 3 | **イベント** | `DungeonController.gd` — `EVENTS_UNDERGROUND_FACTORY` + `_get_event_pool` |
| 4 | **Codex** | `CatalogHelper.gd` — lore マップ 1 件 |
| 5 | **Base 選択** | `BaseScene` + `Constants.UNDERGROUND_FACTORY_DUNGEON_ID` + ボタン（tscn） |
| 6 | **戦闘表示** | `DungeonScene.gd` — `BATTLE_BG_MAP` / `BOSS_ANIM_MAP` **プレースホルダ**（単色 or 既存 BG 流用可） |
| 7 | **spec 同期** | `05_ダンジョン.md` / `12_モンスター.md` 実装表 |

## 3.2 Out of Scope

| 項目 | 移管 |
|---|---|
| 地下工廠 Tileset / 敵スプライト本番 | Phase 3-A / Pixel Apprentice |
| 新 Legendary 武器・工廠系ドロップテーブル本格化 | 別 Task（drop は既存 boss パターン流用で可） |
| 新 Material（forge_scrap 等） | イベントは gold / lore のみ（material は将来） |
| 敵 AI 新規（rush / ranged） | 全員 `ai_type = default` |
| 地下工廠 Merchant カタログ差分 | P3-B-002 拡張候補と統合 |
| Dungeon Bible 新規 Dungeon-0xx 行 | Lore 拡充 Task |

## 3.3 変更ファイル見積（〜12 件）

```
scripts/dungeon/DungeonController.gd
scripts/dungeon/DungeonScene.gd
scripts/base/BaseScene.gd
scripts/core/Constants.gd
scripts/codex/CatalogHelper.gd
scenes/base/BaseScene.tscn          （ボタン 1 追加）
resources/dungeons/underground_factory.tres
resources/enemies/*.tres ×5
docs/specs/game/05_ダンジョン.md
docs/specs/game/12_モンスター.md
```

**分割案:** 1 Task（12 ファイル）で収める。超過時は敵 tres を **P3-B-004a / 004b** に分割。

---

# 4. Success Criteria

| # | 基準 |
|---|---|
| SC-1 | Base で「地下工廠」を選択し探索開始できる |
| SC-2 | 10 部屋完走 → Result 遷移（クラッシュなし） |
| SC-3 | 工廠専用イベントが EVENT 部屋で出現する |
| SC-4 | 感電 on_hit 敵が戦闘ログ / 状態 UI で確認できる |
| SC-5 | 王都跡・白骸墓地の完走が **回帰しない** |
| SC-6 | `bash tools/smoke_test.sh` PASS |

---

# 5. Risks & Mitigations

| リスク | 対策 |
|---|---|
| アート未着で見た目が貧弱 | プレースホルダ BG + 既存敵スプライト色替え **禁止** — 単色 Panel / 王都 BG 暫定流用を Proposal で明示 |
| 通常敵 3 体のみで単調 | elite_pool に iron_hound 重複・感電軸で差別化。4 体目は Backlog |
| difficulty 3 が厳しすぎ | P3-B-004 完了後に **P3-B-005 バランス**を墓地 B-001 と同型で分離可能 |
| ファイル数超過 | 敵 tres 先行マージ or 2 Task 分割 |

---

# 6. Sequencing

```text
P3-B-003（本 Proposal）— オーナー GO
        ↓
P3-B-004 — Impl（データ + 選択 UI + イベント）
        ↓
P3-B-005（任意）— 工廠バランス初調整（B-001 同型）
        ↓
P3-B-002 拡張（任意）— 商人 DG 差 / 敵 pool 微調整
```

---

# 7. Owner Decision

| 選択肢 | 内容 |
|---|---|
| **A（推奨）** | 本 Proposal **GO** → P3-B-004 を Impl 発行（上記 In Scope 一式） |
| B | Proposal 修正（難易度 / branch_enabled / イベント内容） |
| C | 保留 — P3-B-002 拡張（商人・敵 pool）を先に実施 |

**推奨: A。** 3 DG 体制は Phase3-B Exit Criteria（`04_Development_Master_Plan.md`）の中核。

---

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-06-25 | 初版（HQ 起草） |
