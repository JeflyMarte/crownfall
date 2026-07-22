# CHANGELOG — ProjectDocs

## v3.5.47 — 2026-07-22

**P3-OPS-CURSOR-001** — HQ / Impl とも Cursor 一本化

### 確定内容

- 実装・HQ とも Cursor のみ。外部 Impl / コピペ司令塔の運用ルールを削除
- 入口は `AGENTS.md`。依頼テンプレを `10_Impl依頼テンプレート.md` / `06_Impl運用ルール.md` に改名
- 削除: Claude Code キャラ定義、ChatGPT 世界観パッケージ README、`package_chatgpt_worldlore.sh` 等

---

## v3.5.46 — 2026-06-25

Phase3-A Closeout — Visual Production 完了（P3-D008〜010）

### 確定内容

- Phase3-A 正式完了（P3-A-009）。EC-1〜7 PASS
- EC-8 P2 defer: `FX_Hit_Critical`、RoyalRuins 補完タイル 3 件（P3-D008）
- `.import` は git 非コミット・`smoke_test.sh --import-only` が正規フロー（P3-D010）
- Impl: P3-A-007 Tile / P3-A-008 CHR+Gravekeeper / IconPaths batch7
- PA: Batch 5〜7 全納品・検証完了

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/project/CurrentState.md` / `CurrentSprint.md` | Phase3-A 完了 |
| `docs/specs/core/03_Decision_Log.md` | P3-D008〜010 |
| `docs/specs/implementation/11_TASK_INDEX.md` | P3-A Task 全完了 |
| `tools/smoke_test.sh` | ローカル Godot パス検出 |

---

## v3.5.44 — 2026-06-23

Phase2-M9 Closeout — Codex & Discovery Foundation 完了（P2-D176〜178）

### 確定内容

- Phase2-M9 正式完了（P2-Task050）
- EC-6 dungeon/weapon フックは Phase3-B へ Defer（P3-Prep-002 で先行対応可）
- Phase3-A Visual Production 開始
- Claude Code 2 並行運用（P2-D177）

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/archives/.../Phase2_M9_Closeout_Completed_v1.0.md` | 新規 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | Phase3 移行 |
| `docs/specs/core/02_Roadmap.md` | M9 完了 |
| `docs/specs/core/03_Decision_Log.md` | P2-D176〜178 |

---

## v3.5.43 — 2026-06-23

Status & Element Combat — 正式採用（P2-D171〜175）

### 確定内容

- `27_状態異常と属性.md` v1.0 SSOT 化
- 属性 5 種、Tier1 状態異常（bleed/poison/slow）、Tier3 保留
- Phase3-B-M1 Status & Element Foundation を Milestone 候補として計画

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/game/27_状態異常と属性.md` | Proposal → SSOT v1.0 |
| `docs/specs/core/03_Decision_Log.md` | P2-D171〜175 |
| `docs/archives/.../Phase3B_Status_Element_Combat_Completed_v1.0.md` | 新規 |

---

## v3.5.42 — 2026-06-23

設計フロー v1.1 + 状態異常・属性 Proposal（P2-D169/170）

### 確定内容

- `06_DevelopmentHQ_Operations.md` v1.1 — 設計パイプライン・戦闘設計フロー・文書レイヤー
- `Phase3B_Status_Element_Combat_Proposal_v1.0.md` — 属性5種・Tier1状態異常3種案
- `27_状態異常と属性.md` — Proposal ミラー（未承認）
- Backlog / `08_戦闘_AI.md` 参照更新

---

## v3.5.41 — 2026-06-23

Combat Vision — 戦闘設計 SSOT 採用（P2-D166〜168）

### 確定内容

- `26_CombatVision.md` 新設 — シームレス戦闘・AI 自律・武器/ジョブ identity・位置システム
- `08_戦闘_AI.md` — Vision 要約・実装ギャップ表追加
- `06_キャラクター_ジョブ.md` / `07_武器_装備.md` / `01_ゲーム概要.md` / `04_シーン構成.md` 参照更新
- 現行 CombatTimer 抽象戦闘は Alpha 过渡期、Vision は長期不変

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/game/26_CombatVision.md` | 新規 SSOT |
| `docs/specs/game/08_戦闘_AI.md` | Vision 統合・ギャップ |
| `docs/specs/core/03_Decision_Log.md` | P2-D166〜168 |

---

## v3.5.40 — 2026-06-23

World Assets Bible v1.1 — 正式採用（P2-D159〜165）

### 確定内容

- `25_WorldAssetsBible.md` を SSOT として採用（12 World Pillars A-01〜A-12）
- 九王時代 / 九王戦争の時系列統一
- A-10 灯火、命名改訂（レガート / ヴェルド / トレンチャ / シルヴァーン）
- 五王国正・Phase9 叙事詩はゲームスコープ外
- `03_世界観.md` / `17_WorldBible.md` 参照更新

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/game/25_WorldAssetsBible.md` | 新規 SSOT |
| `docs/specs/game/03_世界観.md` | 時代区分・謎・参照更新 |
| `docs/specs/game/17_WorldBible.md` | ドキュメント構成表更新 |
| `docs/specs/core/03_Decision_Log.md` | P2-D159〜165 |
| `docs/archives/WorldArchive/Completed/World_Assets_Bible_Completed_v1.1.md` | 新規 |

---

## v3.5.39 — 2026-06-23

Repository Refresh — DevelopmentHQ Cursor Migration

### 確定内容（P2-D154〜158）

- DevelopmentHQ を Cursor HQ セッションへ移行
- `docs/specs/core/06_DevelopmentHQ_Operations.md` 新設
- ChatGPT コピペ報告フロー廃止 → HQ リポジトリ直接レビュー
- Phase3 順序: 3-A Visual → 3-B Content を正式採用
- ルート ProjectDocs ZIP 9 件削除、`.gitignore` に `*.zip` 追加
- `Phase 0 — World Assets.md` → `docs/archives/WorldArchive/Proposal/Phase0_World_Assets_v1.0.md` へ移動

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/core/06_DevelopmentHQ_Operations.md` | 新規 — HQ 運用 SSOT |
| `docs/specs/core/03_Decision_Log.md` | P2-D154〜158 追加 |
| `docs/specs/core/02_Roadmap.md` | M9 Task 状態同期 |
| `AGENTS.md`, `CLAUDE.md`, `README.md` | Cursor 運用へ更新 |
| `.cursor/rules/developmenthq-operations.mdc` | 新規（旧 report-format 置換） |
| `docs/specs/implementation/06_Claude運用ルール.md` | Impl セッション向けに更新 |
| `docs/project/CurrentState.md`, `CurrentSprint.md` | ダッシュボード更新 |
| `.gitignore` | `*.zip` 除外 |

---

P2-Task049 History / Dungeon Bible Link — Codex Detail に Bible 由来情報を接続。

### 確定内容

- CatalogHelper: History Bible parse（era / related_entries）
- CatalogHelper: Dungeon Bible parse（location / exploration_theme / related_history）
- ゲーム DG id → Bible マップ（royal_ruins→Dungeon-001, graveyard→Dungeon-002）
- CodexScene Detail: Era / Location / Theme / Related 表示
- Bible 欠落時フォールバック（既存 Entry のみ、クラッシュなし）
- Save / Discovery 登録 / Gameplay **未変更**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/codex/CatalogHelper.gd` | Bible parse + Entry 拡張 |
| `scripts/codex/CodexScene.gd` | Bible Detail 表示 |
| `scenes/codex/CodexScene.tscn` | Detail ラベル追加 |
| `docs/archives/.../Phase2_M9_Task049_History_Dungeon_Bible_Link_Completed_v1.0.md` | 新規 |

---

## v3.5.37 — 2026-06-22

P2-Task048 Discovery Detail View — CodexScene 詳細パネル強化。

### 確定内容

- Detail: Entry ID / Name / Status / Category / Description
- Discovery Status: Discovered / Undiscovered
- Icon placeholder（`[Icon]`）。`entry.icon` あり且つ load 成功時のみ TextureRect 表示
- 未発見: ID・Name・Description `???`、Category は現在タブ名を表示
- CatalogHelper のみ / Save / Discovery 登録 / Gameplay **未変更**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/codex/CodexScene.gd` | Detail 強化 |
| `scenes/codex/CodexScene.tscn` | DetailPanel ノード追加 |
| `docs/archives/.../Phase2_M9_Task048_Discovery_Detail_View_Completed_v1.0.md` | 新規 |

---

## v3.5.36 — 2026-06-22

P2-Task047 Codex UI Foundation — CodexScene 最小 UI。

### 確定内容

- `scenes/codex/CodexScene.tscn` + `scripts/codex/CodexScene.gd`
- 5 カテゴリタブ（Enemy / Dungeon / Material / Weapon / History）
- Entry List + Detail Panel（名前・説明）
- BaseScene「図鑑」→ CodexScene → 戻る
- 未発見: 表示名・説明 `???`
- データ取得: CatalogHelper のみ
- Save / Discovery 登録 / Gameplay **未変更**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scenes/codex/CodexScene.tscn` | 新規 |
| `scripts/codex/CodexScene.gd` | 新規 |
| `scenes/base/BaseScene.tscn` | ButtonCodex |
| `scripts/base/BaseScene.gd` | Codex 遷移 |
| `docs/archives/.../Phase2_M9_Task047_Codex_UI_Foundation_Completed_v1.0.md` | 新規 |

---

## v3.5.35 — 2026-06-22

P2-Task046 Codex Data Foundation — CatalogHelper 実装。

### 確定内容

- `scripts/codex/CatalogHelper.gd` — 5 カテゴリ Entry 取得 + is_discovered
- DataRegistry: get_all_enemy/dungeon/material/weapon_data()
- Entry 形式: id / display_name / icon / description / discovered
- 未発見 display_name = `???`
- History Bible Read-only parse（HE-xxx）
- UI / Save / Discovery 登録 **未変更**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/codex/CatalogHelper.gd` | 新規 |
| `scripts/autoload/DataRegistry.gd` | 一覧 API |
| `docs/archives/.../Phase2_M9_Task046_Codex_Data_Foundation_Completed_v1.0.md` | 新規 |

---

## v3.5.34 — 2026-06-22

Phase2-M9 Scope Adoption — Codex & Discovery Foundation 正式採用。

### 確定内容

- Phase2-M9 Scope 正式採用（P2-D148）
- Codex 5 カテゴリ（P2-D149）
- discovery_registry 形式不変 / category 拡張（P2-D150）
- Codex Read-Only（P2-D151）
- History Bible サブセット（P2-D152）
- Task045〜050 登録（P2-D153）
- **コード変更なし**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/core/03_Decision_Log.md` | P2-D148〜153 |
| `docs/specs/core/02_Roadmap.md` | M9 進行中 |
| `docs/specs/core/04_Development_Master_Plan.md` | v1.6 |
| `docs/archives/.../Phase2_M9_Scope_Adoption_Completed_v1.0.md` | 新規 |

---

## v3.5.33 — 2026-06-22

Phase2-M8 Closeout — Craft & Economy Foundation 正式完了。

### 確定内容

- Phase2-M8 **Completed**（P2-Task039〜044）
- Current Milestone → **Phase2-M9 Codex & Discovery Foundation**
- Roadmap / Master Plan v1.5 同期
- **コード変更なし**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/project/CurrentState.md` | M8 完了 / M9 次 |
| `docs/project/CurrentSprint.md` | M8 Sprint 完了 |
| `docs/specs/core/02_Roadmap.md` | M8 完了 / M9 追加 |
| `docs/specs/core/04_Development_Master_Plan.md` | v1.5 M8 Closeout |
| `docs/specs/implementation/11_TASK_INDEX.md` | Task044 完了 |
| `docs/archives/.../Phase2_M8_Closeout_Completed_v1.0.md` | 新規 |

---

## v3.5.32 — 2026-06-22

P2-Task043 Economy Integration — Merchant Material Shop 接続。

### 確定内容

- Merchant 商品候補に Material を追加（MaterialShopData / DataRegistry 経由）
- MVP: relic_shard 20G / ancient_bone 20G
- 購入: gold 減算 → add_material(id, 1) → purchased フラグ
- armor / accessory / heal 既存挙動維持
- weapon 販売なし / Save Format 変更なし / Blacksmith 未変更

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/dungeon/DungeonController.gd` | _build_merchant_catalog / material 購入 |
| `scripts/dungeon/DungeonScene.gd` | Material 表示ラベル |
| `docs/archives/.../Phase2_M8_Task043_Economy_Integration_Completed_v1.0.md` | 新規 |

---

## v3.5.31 — 2026-06-22

P2-Task042 Craft Output Integration — Blacksmith から armor / accessory 生成。

### 確定内容

- 各 CraftData 行に「作成」ボタン
- 検証: required_materials / gold_cost / output_type（armor|accessory のみ）
- 成功時: gold 減算 → consume_materials → 未鑑定 Instance → inventory → save_game
- 失敗時: 何も消費しない（gold / material / invalid output）
- weapon craft 禁止
- affix roll なし / Save Format 変更なし

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/blacksmith/BlacksmithScene.gd` | Craft 実行ループ |
| `docs/specs/implementation/03_Resource設計.md` | Craft Output 節 |
| `docs/archives/.../Phase2_M8_Task042_Craft_Output_Integration_Completed_v1.0.md` | 新規 |

---

## v3.5.30 — 2026-06-22

P2-Task041 BlacksmithScene Foundation — CraftData 一覧表示 + BaseScene 遷移。

確定内容:
- BlacksmithScene 新規作成（scenes/blacksmith/ + scripts/blacksmith/）
- CraftData 一覧: display_name / required_materials（所持数/必要数）/ gold_cost / output_type / output_id を表示
- 所持素材一覧表示（material_inventory）
- 戻るボタン → BaseScene
- BaseScene に「鍛冶屋」ボタン（ButtonBlacksmith）追加
- Craft 実行・Material 消費・Gold 消費・装備生成 なし
- CraftData 0 件 / required_materials 空でもクラッシュなし
- Headless 検証エラーなし

変更ファイル:
- scenes/blacksmith/BlacksmithScene.tscn（新規）
- scripts/blacksmith/BlacksmithScene.gd（新規）
- scenes/base/BaseScene.tscn: ButtonBlacksmith 追加
- scripts/base/BaseScene.gd: _on_blacksmith_button_pressed 追加
- docs/specs/implementation/CODEMAP.md: BlacksmithScene 追加
- docs/specs/implementation/11_TASK_INDEX.md: P2-Task041 完了
- docs/project/CurrentState.md: Task041 完了
- docs/project/CurrentSprint.md: Task041 完了
- CHANGELOG.md: 本エントリ
- docs/archives/.../Phase2_M8_Task041_BlacksmithScene_Completed_v1.0.md: 新規

**Faction Bible Adoption（追記）:**
- 23_FactionBible.md を ProjectDocs SSOT として正式採用（P2-D147）
- 独立ファクション 7 件（F-001〜F-007）+ 王国内行政機関 14 件収録。既存 Lore のみ。Gameplay 仕様記載なし
- docs/specs/game/23_FactionBible.md: 新規（SSOT）
- docs/archives/WorldArchive/Completed/Faction_Bible_v1.0.md: 新規（アーカイブ）
- docs/specs/core/03_Decision_Log.md: P2-D147 追加

---

## v3.5.29 — 2026-06-22

P2-Task040 Material Consumption Logic — GameState.consume_materials() 実装。

確定内容:
- GameState.consume_materials(required_materials: Dictionary) -> bool 追加
- 2パス処理: 先に全素材充足確認 → 全充足のみ一括消費（途中消費なし）
- 不足時 false、成功時 true、消費後 print ログ
- 不明 material_id でもクラッシュなし（get_material_quantity が 0 返却）
- Craft UI / Combat / Save Format 未変更

変更ファイル:
- scripts/autoload/GameState.gd: consume_materials() 追加
- docs/specs/implementation/11_TASK_INDEX.md: P2-Task040 完了
- docs/project/CurrentState.md: Task040 完了
- docs/project/CurrentSprint.md: Task040 完了
- CHANGELOG.md: 本エントリ
- docs/archives/.../Phase2_M8_Task040_Material_Consumption_Completed_v1.0.md: 新規

**Dungeon Bible Adoption（追記）:**
- 22_DungeonBible.md を ProjectDocs SSOT として正式採用（P2-D146）
- 13 ダンジョン定義収録。既存 Lore のみ。Gameplay 仕様記載なし
- docs/specs/game/22_DungeonBible.md: 新規（SSOT）
- docs/archives/WorldArchive/Completed/Dungeon_Bible_v1.0.md: 新規（アーカイブ）
- docs/specs/core/03_Decision_Log.md: P2-D146 追加

---

## v3.5.28 — 2026-06-22

Phase2-M8 Scope Adoption — Craft & Economy Foundation 正式採用。

確定内容:
- Phase2-M8「Craft & Economy Foundation」正式 Scope 採用（P2-D139）
- CraftData スキーマ（7 フィールド）SSOT 確定（P2-D140）
- MVP レシピ 3 件採用（P2-D141）
- Weapon クラフト MVP 不可確定（P2-D142）
- consume_materials() は GameState 配置（P2-D143）
- Merchant Materials 購入を P2-Task043 として計画（P2-D144）
- P2-Task039 は Craft Resource Pack で完了済み（P2-D145）
- コード変更なし

変更ファイル:
- docs/specs/core/03_Decision_Log.md: P2-D139〜145 追加
- docs/specs/core/02_Roadmap.md: M8 進行中・Task 一覧追加
- docs/specs/core/04_Development_Master_Plan.md: v1.5、M8 全 scope 記載
- docs/specs/implementation/11_TASK_INDEX.md: Phase2-M8 Section 追加
- docs/project/CurrentState.md: M8 進行中・Next Task 更新
- docs/project/CurrentSprint.md: M8 Sprint 開始
- CHANGELOG.md: 本エントリ
- docs/archives/.../Phase2_M8_Scope_Adoption_Completed_v1.0.md: 新規

---

## v3.5.27 — 2026-06-22

Phase2-M7 Closeout — Job & Build Foundation 完了。

確定内容:
- Phase2-M7 を Completed とする（P2-D137）
- 次マイルストーン候補: Phase2-M8 Craft & Economy Foundation（P2-D138）
- Roadmap: M7 → Completed、M8 → Next Milestone 候補
- Development Master Plan v1.4: M7 完了・M8 候補・Current Position 更新
- Decision Log: P2-D137〜138 追加
- Completed Document 作成
- コード変更なし

変更ファイル:
- docs/specs/core/03_Decision_Log.md: P2-D137〜138
- docs/specs/core/02_Roadmap.md: M7 Completed、M8 Next候補
- docs/specs/core/04_Development_Master_Plan.md: v1.4
- docs/specs/implementation/11_TASK_INDEX.md: P2-Task038 完了
- docs/project/CurrentState.md: M7 完了、M8 未着手
- docs/project/CurrentSprint.md: M7 Sprint 完了
- CHANGELOG.md: 本エントリ
- docs/archives/.../Phase2_M7_Closeout_Completed_v1.0.md: 新規

---

## v3.5.26 — 2026-06-22

P2-Task037 Build Summary UI — EquipmentScene に Build Summary 1 ブロック追加。

確定内容:
- EquipmentScene に LabelBuildSummary ノード追加
- Weapon / Armor / Accessory / 鑑定済み Affix / Jobs / Build tag を 1 ブロック表示
- Build tag: Affix stat_type と Job role からタグ推定（Attack / Critical / Survival / Exploration）
- 未装備 → None、未鑑定 Affix → 非表示、JobData 欠落 → job_id 表示
- Combat / Save / Affix 計算 未変更（表示のみ）

変更ファイル:
- scenes/equipment/EquipmentScene.tscn: LabelBuildSummary ノード追加
- scripts/equipment/EquipmentScene.gd: _update_build_summary / _collect_affix_lines / _collect_job_lines / _estimate_build_tags 追加
- docs/specs/implementation/11_TASK_INDEX.md: P2-Task037 完了
- docs/specs/implementation/CODEMAP.md: v3.5.26 同期
- docs/project/CurrentState.md: Task037 完了、Task038 次
- docs/project/CurrentSprint.md: Task037 完了
- docs/archives/.../Phase2_M7_Task037_Build_Summary_UI_Completed_v1.0.md: 新規

---

## v3.5.25 — 2026-06-22

P2-Task036 Job UI — BaseScene 読み取り専用 Job 表示。

### 確定内容

- `BaseScene._format_member_job_line` — Job 名 / role / non-default modifier（HP/ATK/DEF）を 1 行表示
- warrior: `戦士 / Job: 戦士 / Role: dps / ATK x1.10`
- guardian: `守護者 / Job: 守護者 / Role: tank / HP x1.20 DEF x1.20`
- scout: `斥候 / Job: 斥候 / Role: scout`
- job_id 空 → `Job: -`、JobData 欠落 → `Job: {job_id}`（クラッシュなし）
- `DataRegistry.get_job_data` に `ResourceLoader.exists()` guard 追加（旧セーブ thief/mage コンソールエラー抑制）
- Job 変更 UI なし（P2-D120）
- Combat / Save **未変更**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/base/BaseScene.gd` | `_format_member_job_line` 追加、`_update_party_display` 更新 |
| `scripts/autoload/DataRegistry.gd` | `get_job_data` に ResourceLoader.exists() guard |
| `docs/specs/implementation/11_TASK_INDEX.md` | P2-Task036 完了 |
| `docs/specs/implementation/CODEMAP.md` | v3.5.25 同期 |
| `docs/project/CurrentState.md` | Task036 完了、Task037 次 |
| `docs/project/CurrentSprint.md` | Task036 完了 |
| `docs/archives/.../Phase2_M7_Task036_Job_UI_Completed_v1.0.md` | 新規 |

---

## v3.5.24 — 2026-06-22

P2-Task035 starting_skill_ids Combat Link。

### 確定内容

- `DungeonScene._get_job_skill_data` — メンバー job の `starting_skill_ids[0]` を SkillData として解決
- `DungeonScene._try_cast_secondary_skill` — Primary と異なる id のみ Secondary 実行（P2-D117）
- warrior + slash_attack 武器 → Primary のみ（重複なし）。guardian / scout → Secondary なし（正常系）
- P2-D134〜136
- Save / UI / Equipment / Affix **未変更**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/dungeon/DungeonScene.gd` | `_get_job_skill_data` / `_try_cast_secondary_skill` 追加、`_do_party_attack` 修正 |
| `docs/specs/core/03_Decision_Log.md` | P2-D134〜136 |
| `docs/specs/implementation/11_TASK_INDEX.md` | P2-Task035 完了 |
| `docs/specs/implementation/CODEMAP.md` | v3.5.24 同期 |
| `docs/project/CurrentState.md` | Task035 完了、Task036 次 |
| `docs/project/CurrentSprint.md` | Task035 完了 |
| `docs/archives/.../Phase2_M7_Task035_starting_skill_ids_Completed_v1.0.md` | 新規 |

---

## v3.5.23 — 2026-06-22

Special Room Bible v1.0 — DevelopmentHQ 承認 Proposal の公式アーカイブ登録。

### 確定内容

- `Special_Room_Bible_v1.1.md`（Proposal）を `GameplayArchive/Proposal/` へ配置
- `Special_Room_Bible_v1.0.md`（Completed）を `GameplayArchive/Completed/` へ作成
- Special Room 設計原則・全 5 Room 仕様・Economy 設計・Discovery 連携・Future Phase を正式文書化
- `docs/specs/game/05_ダンジョン.md` — Special Room 仕様は実装時に反映済み（変更なし）

### 対象実装

Phase2-M3: P2-Task013〜018（Heal / Treasure / Merchant / Event / Elite / Discovery）

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/archives/GameplayArchive/Proposal/Special_Room_Bible_v1.1.md` | 新規（Proposal 配置） |
| `docs/archives/GameplayArchive/Completed/Special_Room_Bible_v1.0.md` | 新規（Completed 文書） |
| `docs/project/CurrentState.md` | GameplayArchive Status 更新 |
| `CHANGELOG.md` | 本エントリ追加 |

---

## v3.5.22 — 2026-06-21

Phase3 Split Adoption — Visual Production / Content Expansion。

### 確定内容

- Phase3 を **Phase3-A（Visual Production）** + **Phase3-B（Content Expansion）** へ分割（P2-D129）
- Phase4 = Polish、Phase5 = Release Preparation（P2-D132）
- Master Plan v1.3、Roadmap、Backlog 再分類
- **gameplay / コード変更なし**

### Decision

P2-D129〜P2-D133

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/core/03_Decision_Log.md` | P2-D129〜133 |
| `docs/specs/core/04_Development_Master_Plan.md` | v1.3 Phase 再編 |
| `docs/specs/core/02_Roadmap.md` | Phase3-A/B タイムライン |
| `docs/specs/core/05_Backlog.md` | Future Task 再分類 |
| `docs/project/CurrentState.md` | Future Roadmap のみ |
| `docs/archives/.../Phase3_Split_Adoption_Completed_v1.0.md` | 新規 |

---

## v3.5.21 — 2026-06-21

P2-Task034 Job Modifier Combat Integration。

### 確定内容

- `CombatController._init_party_hp` — per-member HP × job hp_mult
- `DungeonScene` — per-member ATK / DEF × job modifier（P2-D115 順序）
- P2-D126〜128
- SkillExecutor / Save / UI **未変更**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/combat/CombatController.gd` | HP job 接続 |
| `scripts/dungeon/DungeonScene.gd` | ATK/DEF job 接続 |
| `docs/archives/.../P2_Task034_Job_Modifier_Combat_Integration_Completed_v1.0.md` | 新規 |

---

## v3.5.20 — 2026-06-21

P2-Task033 Party Job Alignment + JobStatCalculator Foundation。

### 確定内容

- パーティ初期 job_id = warrior / guardian / scout（P2-D123）
- `JobStatCalculator.gd` — modifier Dictionary 取得、安全 fallback
- 戦闘 stat **未反映**（P2-D125）
- gameplay 戦闘数値 **変更なし**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/equipment/JobStatCalculator.gd` | 新規 |
| `scripts/autoload/GameState.gd` | party job_id 整合 |
| `docs/specs/core/03_Decision_Log.md` | P2-D123〜125 |
| `docs/archives/.../P2_Task033_Party_Job_Alignment_Completed_v1.0.md` | 新規 |

---

## v3.5.19 — 2026-06-21

Phase2-M7 Scope Adoption — Job & Build Foundation 正式 Scope 採用。

### 確定内容

- `Phase2-M7_Scope_Proposal_v1.0.md` 正式採用（P2-D113）
- P2-D113〜P2-D122 Decision 採用
- P2-Task033〜038 を Task Index 登録
- M7 Status: Ready → **進行中**
- Review 修正: Task037 依存 = Task033 + **Task034** + Task032
- gameplay **変更なし**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/core/03_Decision_Log.md` | P2-D113〜122 |
| `docs/project/CurrentState.md` | M7 進行中、Task033 次 |
| `docs/project/CurrentSprint.md` | M7 Sprint 開始 |
| `docs/specs/core/02_Roadmap.md` | M7 Task 一覧 |
| `docs/specs/core/04_Development_Master_Plan.md` | v1.2 / M7 進行中 |
| `docs/specs/implementation/11_TASK_INDEX.md` | Task033〜038 |
| `docs/specs/core/Proposal/Phase2-M7_Scope_Proposal_v1.0.md` | Adopted v1.0.1 |
| `docs/archives/.../Phase2_M7_Scope_Adoption_Completed_v1.0.md` | 新規 |

---

## v3.5.18 — 2026-06-21

Phase2-M6 Closeout Follow-up — Development Master Plan 同期。

### 確定内容

- `04_Development_Master_Plan.md` v1.1 — M6 Completed、M7 Ready
- **Phase2-M7 正式名称:** Job & Build Foundation（P2-D111）
- Material Usage → Future Craft & Economy Foundation（P2-D112）
- Dependency: Affix Stack → Job & Build → Craft/Economy
- gameplay **変更なし**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/core/04_Development_Master_Plan.md` | v1.1 同期 |
| `docs/project/CurrentState.md` | M7 Ready |
| `docs/project/CurrentSprint.md` | M7 Job & Build |
| `docs/specs/core/02_Roadmap.md` | M7 / M8 候補 |
| `docs/specs/core/03_Decision_Log.md` | P2-D110〜P2-D112 |
| `docs/archives/.../Phase2_M6_Closeout_Master_Plan_Sync_Completed_v1.0.md` | 新規 |

---

## v3.5.17 — 2026-06-21

Phase2-M6 Closeout — Equipment Depth Foundation 完了。

### 確定内容

- **Phase2-M6 完了**（P2-Task028〜032）
- Affix ループ完成: Data → Roll → Appraisal → Instance → Stat → UI
- 次候補: **Phase2-M7 UI / UX Foundation**
- Material Usage / Affix 拡張 / Job combat 等は Defer
- gameplay **変更なし**（同期のみ）

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/project/CurrentState.md` | M6 完了・M7 候補 |
| `docs/project/CurrentSprint.md` | M6 Closeout |
| `docs/specs/core/02_Roadmap.md` | M6 完了・M7 候補節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D105〜P2-D109 |
| `docs/archives/.../Phase2_M6_Closeout_Completed_v1.0.md` | 新規 |

---

## v3.5.16 — 2026-06-21

P2-Task032 Equipment Detail UI — 鑑定済み Affix の Equipment 表示。

### 確定内容

- `AffixDisplayFormatter.gd` — Affix 名称・効果整形
- EquipmentScene: 装備中 / リストに Affix 行追加
- 未鑑定は Affix 非表示（既存リストフィルタ維持）
- 欠落 AffixData id は id フォールバック / 効果行スキップ
- gameplay **未変更**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/equipment/AffixDisplayFormatter.gd` | 新規 |
| `scripts/equipment/EquipmentScene.gd` | Affix 表示 |
| `scripts/appraisal/AppraisalController.gd` | formatter 共通化 |
| `docs/specs/core/03_Decision_Log.md` | P2-D101〜P2-D104 |
| `docs/archives/.../P2_Task032_Equipment_Detail_UI_Completed_v1.0.md` | 新規 |

---

## v3.5.15 — 2026-06-21

P2-Task031 Affix Stat Application — 鑑定済み Affix を戦闘/報酬に反映。

### 確定内容

- `AffixStatCalculator.gd` — 装備 Affix 集計ヘルパー
- 対応: Attack / Defense / HP / Critical / Gold Gain / Material Gain / Healing
- 接続: DungeonScene ダメージ、CombatController max HP、DungeonController Gold
- 未対応 stat_type は安全に無視（Attack Speed 等）
- 鑑定ロジック **未変更**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/equipment/AffixStatCalculator.gd` | 新規 |
| `scripts/dungeon/DungeonScene.gd` | affix stat 接続 |
| `scripts/dungeon/DungeonController.gd` | Gold Gain |
| `scripts/combat/CombatController.gd` | HP Affix |
| `docs/specs/core/03_Decision_Log.md` | P2-D097〜P2-D100 |
| `docs/archives/.../P2_Task031_Affix_Stat_Application_Completed_v1.0.md` | 新規 |

---

## v3.5.14 — 2026-06-21

P2-Task030 Affix Appraisal Integration — 鑑定フローに AffixRoller 接続。

### 確定内容

- 鑑定時 `AffixRoller.roll_for_equipment()` 呼び出し
- `WeaponInstance` / `ArmorInstance` / `AccessoryInstance` に `prefix_ids` / `suffix_ids`
- SaveManager が affix ID 配列を serialize（後方互換）
- Appraisal Reveal: `【Affix】display_name / …`
- Roll 失敗時も鑑定完了（空配列フォールバック）
- 戦闘 stat 反映 **未接続**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/appraisal/AppraisalController.gd` | Affix roll + reveal |
| `scripts/appraisal/AppraisalScene.gd` | affix_text 表示 |
| `scripts/domain/*Instance.gd` | prefix_ids / suffix_ids |
| `scripts/save/SaveManager.gd` | affix serialize |
| `docs/specs/core/03_Decision_Log.md` | P2-D093〜P2-D096 |
| `docs/archives/.../P2_Task030_Affix_Appraisal_Integration_Completed_v1.0.md` | 新規 |

---

## v3.5.13 — 2026-06-21

P2-Task029 Affix Roll System — AffixRoller + MVP slot rules。

### 確定内容

- `AffixRoller.gd` — weapon P+S / armor P / accessory P
- 候補フィルタ: affix_category, tags, rarity tier
- レアリティ重み 70/25/4/1
- サンプル suffix 追加: `of_might`
- Appraisal / Instance / Save / 戦闘 **未接続**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/equipment/AffixRoller.gd` | 新規 |
| `resources/affixes/of_might.tres` | suffix サンプル |
| `docs/specs/implementation/03_Resource設計.md` | AffixRoller 節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D089〜P2-D092 |
| `docs/archives/.../P2_Task029_Affix_Roll_System_Completed_v1.0.md` | 新規 |

---

## v3.5.12 — 2026-06-21

P2-Task028 AffixData Foundation — Affix Bible を data 層へ反映。

### 確定内容

- `AffixData.gd` 最小スキーマ
- サンプル 6: sharp, swift, heavy, blessed, fortune, protection
- `DataRegistry.get_affix_data(id)` + `RESOURCE_AFFIXES_PATH`
- Roll / Appraisal / 戦闘 / Save **未接続**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/data/AffixData.gd` | 新規 |
| `resources/affixes/*.tres` | 6 サンプル |
| `scripts/autoload/DataRegistry.gd` | get_affix_data |
| `scripts/core/Constants.gd` | RESOURCE_AFFIXES_PATH |
| `docs/specs/implementation/03_Resource設計.md` | AffixData 節 |
| `docs/specs/game/07_武器_装備.md` | Affix 容量・接続状況 |
| `docs/specs/core/03_Decision_Log.md` | P2-D085〜P2-D088 |
| `docs/archives/.../P2_Task028_AffixData_Foundation_Completed_v1.0.md` | 新規 |

---

## v3.5.11 — 2026-06-21

**Repository Cleanup Policy** — DevelopmentHQ 正式決定を SSOT 反映。

### 確定内容

- P2-D081: ProjectDocs ZIP はリポジトリ管理外（Release Artifact）
- P2-D082: Proposal は Completed 後も削除しない
- P2-D083: Lore 16/17/18 は `docs/specs/game/` 配置
- P2-D084: Git Commit は Milestone 単位分割
- `Project_Repository_Policy.md` 新規

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/core/Project_Repository_Policy.md` | 新規 SSOT |
| `docs/specs/core/03_Decision_Log.md` | P2-D081〜P2-D084 |
| `docs/project/CurrentState.md` | Policy 参照 |
| `docs/archives/.../Repository_Cleanup_Policy_Completed_v1.0.md` | 新規 |

---

## v3.5.10 — 2026-06-21

**Affix_Bible_Completed v1.0** — DevelopmentHQ 承認（Minor Revision 反映）。

### 確定内容

- MVP Affix 容量固定（Weapon P×1 S×1 / Armor P×1 / Accessory P×1）
- Affix stat_type 13 種（AffixData 登録単位）
- Legendary 哲学: new play styles, not raw numbers
- 核心ループ: Discovery → Appraisal → Affix Generation → Reveal
- Merchant should not replace exploration

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/archives/.../Affix_Bible_Completed_v1.0.md` | 新規 |
| `docs/specs/core/03_Decision_Log.md` | P2-D077〜P2-D080 |
| `docs/project/CurrentState.md` | Design Reference / Task028 次 |

---

## v3.5.9 — 2026-06-21

**Phase2-M5 Closeout** — Combat Depth Foundation マイルストーン完了。

### M5 確定サマリー

- SkillExecutor（damage + cooldown）
- Weapon fixed_skill_id → SkillExecutor
- JobData Foundation（warrior / guardian / scout）
- Job 戦闘接続 → **M6+ defer**

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/project/CurrentState.md` | M5 完了 / M6 候補 |
| `docs/project/CurrentSprint.md` | M6 プレースホルダー |
| `docs/specs/core/02_Roadmap.md` | M5 完了 / M6 節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D073〜P2-D076 |
| `docs/specs/implementation/11_TASK_INDEX.md` | M5 完了 |
| `docs/archives/.../Phase2_M5_Closeout_Completed_v1.0.md` | 新規 |

---

## v3.5.8 — 2026-06-21

P2-Task027 Job Foundation — JobData Resource + DataRegistry lookup。

### 確定内容

- `JobData.gd` 最小スキーマ
- サンプル: warrior / guardian / scout
- `DataRegistry.get_job_data(id)`
- 戦闘 / UI 未接続（データ層のみ）

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/data/JobData.gd` | 新規 |
| `resources/jobs/*.tres` | 3 ジョブ |
| `scripts/autoload/DataRegistry.gd` | get_job_data |
| `scripts/core/Constants.gd` | RESOURCE_JOBS_PATH |
| `docs/specs/implementation/03_Resource設計.md` | JobData 節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D069〜P2-D072 |
| `docs/archives/.../P2_Task027_Job_Foundation_Completed_v1.0.md` | 新規 |

---

## v3.5.7 — 2026-06-21

P2-Task026 Weapon Skill Link — 装備武器 `fixed_skill_id` → SkillExecutor 接続。

### 確定内容

- `WeaponData.fixed_skill_id` フィールド追加
- iron_sword → slash_attack
- rusted_blade → 空（フォールバック検証）
- DungeonScene `_get_player_skill_data()` 解決フロー
- 戦闘ログ: `【スキル】鉄の剣 / 斬撃: Nダメージ`

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/data/WeaponData.gd` | fixed_skill_id |
| `resources/weapons/iron_sword.tres` | slash_attack |
| `scripts/dungeon/DungeonScene.gd` | スキル解決 |
| `docs/specs/game/07_武器_装備.md` | fixed_skill_id 接続 |
| `docs/specs/game/08_戦闘_AI.md` | 解決フロー |
| `docs/specs/core/03_Decision_Log.md` | P2-D065〜P2-D068 |
| `docs/archives/.../P2_Task026_Weapon_Skill_Link_Completed_v1.0.md` | 新規 |

---

## v3.5.6 — 2026-06-21

P2-Task025 SkillExecutor — 最小スキル実行基盤 + slash_attack 戦闘接続。

### 確定内容

- `SkillExecutor.gd` — damage effect / cooldown 管理
- `slash_attack` — power_multiplier 1.5、cooldown 3.0s
- DungeonScene — 通常攻撃 + スキル追加ダメージ、戦闘ログ表示
- Constants — `COMBAT_TICK_INTERVAL` / `DEFAULT_PLAYER_SKILL_ID`

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/combat/SkillExecutor.gd` | 新規 |
| `scripts/dungeon/DungeonScene.gd` | スキル接続 |
| `scripts/core/Constants.gd` | 定数追加 |
| `docs/specs/game/08_戦闘_AI.md` | SkillExecutor 節 |
| `docs/specs/implementation/03_Resource設計.md` | SkillExecutor 節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D061〜P2-D064 |
| `docs/archives/.../P2_Task025_SkillExecutor_Completed_v1.0.md` | 新規 |

---

## v3.5.5 — 2026-06-21

**Phase2-M4 Closeout** — World Expansion Foundation マイルストーン完了。

### M4 確定サマリー

- Multi-Dungeon Foundation（GameState.current_dungeon_id + DataRegistry 起動）
- Base Dungeon Select（王都跡 / 白骸墓地）
- Graveyard Dungeon + 敵 6 体（2 DG playable）
- MaterialData Foundation（inventory + Event/Elite）
- SkillExecutor → **M5 へ移行**（M4 スコープ外）

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/project/CurrentState.md` | M4 完了 / M5 次 |
| `docs/project/CurrentSprint.md` | M5 Sprint 開始 |
| `docs/specs/core/02_Roadmap.md` | M4 完了 / M5 節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D057〜P2-D060 |
| `docs/specs/implementation/11_TASK_INDEX.md` | M4 完了 |
| `docs/archives/.../Phase2_M4_Closeout_Completed_v1.0.md` | 新規 |

---

## v3.5.4 — 2026-06-21

Crownfall Product Vision Completed v1.0 をアーカイブに追加（Design Vision reference）。

### 確定内容

- v1.0 + v1.1（§3.8 Exploration Rhythm）統合 Completed 文書
- 非 SSOT 地位・DevelopmentHQ Decision 要件を明記
- CurrentState に Design References リンク

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/archives/.../Crownfall_Product_Vision_Completed_v1.0.md` | 新規 |
| `docs/project/CurrentState.md` | Design References 節 |

---

## v3.5.3 — 2026-06-21

P2-Task024 MaterialData Foundation を SSOT に反映。

### 確定内容

- MaterialData Resource + 4 サンプル素材
- `GameState.material_inventory` + Save 永続化
- `DataRegistry.get_material_data`
- Event relic_shard / Elite elite_relic_shard 接続

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/data/MaterialData.gd` | 新規 |
| `resources/materials/*.tres` | 4 素材 |
| `scripts/autoload/GameState.gd` | material_inventory |
| `scripts/autoload/DataRegistry.gd` | get_material_data |
| `scripts/save/SaveManager.gd` | save/load |
| `scripts/dungeon/DungeonScene.gd` | Event/Elite 素材付与 |
| `scripts/dungeon/DungeonController.gd` | material_id on elite |
| `docs/specs/implementation/03_Resource設計.md` | MaterialData 節 |
| `docs/specs/game/05_ダンジョン.md` | Event/Elite 素材 |
| `docs/specs/core/03_Decision_Log.md` | P2-D054〜P2-D056 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | v3.5.3 |
| `docs/archives/.../P2_Task024_MaterialData_Foundation_Completed_v1.0.md` | 新規 |

---

## v3.5.2 — 2026-06-21

P2-Task023 Graveyard Dungeon + Enemy Set を SSOT に反映。**2 プレイアブル DG 達成。**

### 確定内容

- `resources/dungeons/graveyard.tres`（branch_enabled=true, difficulty=2）
- 敵 6 体: bone_walker, grave_bat, hollow_gravedigger, pale_hound, ossuary_knight, gravekeeper
- `pick_combat_enemy_data` / `boss_id` 接続
- Base 白骸墓地選択有効化

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `resources/dungeons/graveyard.tres` | 新規 |
| `resources/enemies/*.tres` | 6 体新規 |
| `scripts/dungeon/DungeonController.gd` | combat pick + DataRegistry |
| `scripts/dungeon/DungeonScene.gd` | pick_combat_enemy_data |
| `docs/specs/game/05_ダンジョン.md` / `12_モンスター.md` | Graveyard SSOT |
| `docs/specs/core/03_Decision_Log.md` | P2-D051〜P2-D053 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | v3.5.2 |
| `docs/archives/.../P2_Task023_Graveyard_Dungeon_Completed_v1.0.md` | 新規 |

---

## v3.5.1 — 2026-06-21

P2-Task022 Base Dungeon Select を SSOT に反映。

### 確定内容

- BaseScene ダンジョン選択 UI（王都跡 / 白骸墓地 placeholder）
- `Constants.GRAVEYARD_DUNGEON_ID` = graveyard
- DataRegistry 可用性チェック付き探索開始

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scenes/base/BaseScene.tscn` | DungeonSelectRow UI |
| `scripts/base/BaseScene.gd` | 選択・探索開始 |
| `scripts/core/Constants.gd` | GRAVEYARD_DUNGEON_ID |
| `docs/specs/game/05_ダンジョン.md` | Base Dungeon Select 節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D048〜P2-D050 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | v3.5.1 |
| `docs/archives/.../P2_Task022_Base_Dungeon_Select_Completed_v1.0.md` | 新規 |

---

## v3.5.0 — 2026-06-21

P2-Task021 Multi-Dungeon Foundation を SSOT に反映。**Phase2-M4 開始。**

### 確定内容

- `GameState.current_dungeon_id` + `get_active_dungeon_id()`
- `Constants.DEFAULT_DUNGEON_ID`（royal_ruins）
- `DungeonController.start_dungeon(dungeon_id)` — DataRegistry 経由
- DungeonScene hardcode 除去
- SaveManager — current_dungeon_id 永続化

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/core/Constants.gd` | DEFAULT_DUNGEON_ID |
| `scripts/autoload/GameState.gd` | get_active_dungeon_id |
| `scripts/dungeon/DungeonController.gd` | id + DataRegistry |
| `scripts/dungeon/DungeonScene.gd` | 選択 id 起動 |
| `scripts/base/BaseScene.gd` | 探索開始 id 設定 |
| `scripts/save/SaveManager.gd` | current_dungeon_id |
| `docs/specs/game/05_ダンジョン.md` | Multi-Dungeon 節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D045〜P2-D047 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | v3.5.0 M4 |
| `docs/archives/.../P2_Task021_Multi_Dungeon_Foundation_Completed_v1.0.md` | 新規 |

---

## v3.4.6 — 2026-06-21

P2-Task020 DataRegistry を SSOT に反映。**Phase2-M3 完了。**

### 確定内容

- DataRegistry 6 カテゴリ lookup（weapon/armor/accessory/enemy/skill/dungeon）
- Constants.RESOURCE_*_PATH パス定数
- inline load() 併存方針（一括置換なし）
- slash_attack 含む全登録 .tres パス検証

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/autoload/DataRegistry.gd` | Constants 参照・doc |
| `scripts/core/Constants.gd` | RESOURCE_*_PATH |
| `docs/specs/implementation/03_Resource設計.md` | DataRegistry 節 |
| `docs/specs/implementation/01_Godotアーキテクチャ.md` | DataRegistry SSOT |
| `docs/specs/core/03_Decision_Log.md` | P2-D042〜P2-D044 |
| `docs/specs/core/02_Roadmap.md` | M3 完了 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | v3.4.6 |
| `docs/archives/.../P2_Task020_DataRegistry_Completed_v1.0.md` | 新規 |

---

## v3.4.5 — 2026-06-21

P2-Task019 SkillData Resource を SSOT に反映。

### 確定内容

- SkillData 最小スキーマ（skill_type / power_multiplier / trigger_type / tags）
- サンプル: slash_attack.tres
- DataRegistry.get_skill_data 参照パス確定
- SkillExecutor / 戦闘接続は未実装（将来フェーズ）

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/data/SkillData.gd` | スキーマ finalize |
| `resources/skills/slash_attack.tres` | サンプル更新 |
| `docs/specs/implementation/03_Resource設計.md` | SkillData 節 |
| `docs/specs/game/08_戦闘_AI.md` | SkillData 節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D039〜P2-D041 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | v3.4.5 |
| `docs/archives/.../P2_Task019_SkillData_Completed_v1.0.md` | 新規 |

---

## v3.4.4 — 2026-06-21

P2-Task018 Discovery System を SSOT に反映。

### 確定内容

- discovery_registry（room/enemy/event/lore/material）
- DiscoveryRegistry.gd + Save 永続化
- 新規発見ログ表示

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/discovery/DiscoveryRegistry.gd` | 新規 |
| `scripts/autoload/GameState.gd` | discovery_registry |
| `scripts/save/SaveManager.gd` | save/load |
| `scripts/dungeon/DungeonScene.gd` | 登録フック |
| `scripts/dungeon/DungeonController.gd` | discovery_id on lore/material events |
| `docs/specs/game/05_ダンジョン.md` | Discovery System 節 |
| `docs/specs/core/03_Decision_Log.md` | P2-D034〜P2-D038 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | v3.4.4 |
| `docs/archives/.../P2_Task018_Discovery_System_Completed_v1.0.md` | 新規 |

---

## v3.4.3 — 2026-06-21

P2-Task017 Elite Room を SSOT に反映。

### 確定内容

- Elite Room（常に戦闘・elite_pool・x1.5 EXP/Gold）
- ボーナス: 防具 35% / 装飾品 25% / 素材 placeholder 15%
- DANGEROUS Pool に ELITE 追加
- elite_pool 敵 enemy_type=ELITE

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/dungeon/DungeonController.gd` | apply_elite_bonus_loot、elite 確率定数 |
| `scripts/dungeon/DungeonScene.gd` | Elite ログ・ボーナス処理 |
| `resources/enemies/rusted_knight.tres` | enemy_type=ELITE |
| `resources/enemies/ruins_looter.tres` | enemy_type=ELITE |
| `docs/specs/game/05_ダンジョン.md` | ELITE Room 仕様 |
| `docs/specs/game/08_戦闘_AI.md` | Elite 戦闘節 |
| `docs/specs/game/12_モンスター.md` | ELITE 実装済 |
| `docs/specs/core/03_Decision_Log.md` | P2-D029〜P2-D033 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | v3.4.3 |
| `docs/archives/.../P2_Task017_Elite_Room_Completed_v1.0.md` | 新規 |

---

## v3.4.2 — 2026-06-21

P2-Task016 Event Room を SSOT に反映。

### 確定内容

- Event Room（2 択・即時解決・非戦闘）
- 5 イベント: heal / gold / buff / material / lore
- Temporary buff: run_damage_multiplier x1.15
- UNKNOWN Branch Pool に EVENT 追加

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/dungeon/DungeonController.gd` | EVENTS 5種、run_damage_multiplier |
| `scripts/dungeon/DungeonScene.gd` | buff/material/lore 解決、攻撃補正 |
| `docs/specs/game/05_ダンジョン.md` | EVENT Room 仕様、Branch Pool 更新 |
| `docs/specs/implementation/04_シーン構成.md` | EventContainer |
| `docs/specs/core/03_Decision_Log.md` | P2-D024〜P2-D028 |
| `docs/specs/core/02_Roadmap.md` | Event を M3 完了に移動 |
| `docs/specs/implementation/11_TASK_INDEX.md` | P2-Task016 完了 |
| `docs/project/CurrentState.md` / `CurrentSprint.md` | v3.4.2 |
| `docs/archives/.../P2_Task016_Event_Room_Completed_v1.0.md` | 新規 |

### 延期

- material / lore 永続化
- Shrine / Discovery 連動
- イベント確率分岐

---

## v3.4.1 — 2026-06-21

P2-Task015 Merchant Room を SSOT に反映。

### 確定内容

- Merchant Room（Branch Route 経由・Gold シンク）
- 商品: 革鎧 / 銀の指輪 / 回復薬（**武器非販売** P2-D020）
- Branch Pool に MERCHANT 追加（SAFE / UNKNOWN）

### 変更ファイル

| ファイル | 変更概要 |
|---|---|
| `scripts/dungeon/DungeonController.gd` | カタログから武器削除、回復薬追加 |
| `scripts/dungeon/DungeonScene.gd` | 回復薬購入時 heal_party 接続 |
| `docs/specs/game/05_ダンジョン.md` | MERCHANT Room 仕様、Branch Pool 更新 |
| `docs/specs/game/07_武器_装備.md` | Dungeon Merchant 節追加 |
| `docs/specs/core/03_Decision_Log.md` | P2-D020〜P2-D023 追加 |
| `docs/specs/core/02_Roadmap.md` | Merchant を M3 完了に移動 |
| `docs/specs/implementation/04_シーン構成.md` | MerchantContainer 追記 |
| `docs/specs/implementation/11_TASK_INDEX.md` | P2-Task015 完了 |
| `docs/project/CurrentState.md` | v3.4.1、Next Task = Event Room |
| `docs/project/CurrentSprint.md` | P2-Task015 完了、残 5 Task |
| `docs/archives/.../P2_Task015_Merchant_Room_Completed_v1.0.md` | Completed 文書新規 |

### 延期

- Materials（素材）販売 — MaterialData 未実装

---

## v3.4 — 2026-06-21

ProjectDocs を Phase2-M3 確定スコープ（v3.4 SSOT）に同期。

### 反映済み実装スコープ

- Phase2-M2 Combat Spec Alignment（v3.3 継承）
- Branch Route System
- HEAL Room
- TREASURE Room
- Weapon Parameter Expansion（v3.3 継承）
- Critical System（v3.3 継承）
- Armor System / Armor Loot / Appraisal（v3.3 継承）
- Party Individual HP（v3.3 継承）
- Enemy Data Expansion
- AI Context Optimization（Phase A / A.1 — ドキュメントのみ）

### 更新ファイル

| ファイル | 変更概要 |
|---|---|
| `docs/specs/core/02_Roadmap.md` | M3 を進行中に更新。v3.4 完了/残タスクを明記 |
| `docs/specs/core/03_Decision_Log.md` | P2-D015〜P2-D019（Branch/HEAL/TREASURE/EnemyData）追加 |
| `docs/specs/game/05_ダンジョン.md` | Branch Route、HEAL/TREASURE Room 仕様追加。M3 残タスクを未実装として分離 |
| `docs/specs/game/12_モンスター.md` | EnemyData 拡張フィールド・EnemyType enum・王都跡 5 体を反映 |
| `docs/specs/implementation/01_Godotアーキテクチャ.md` | SceneRouter 修正、シーンループ更新、現行レイヤー反映 |
| `docs/specs/implementation/03_Resource設計.md` | EnemyData 実装スキーマ、DungeonData（branch_enabled）更新 |
| `docs/specs/implementation/04_シーン構成.md` | 自動戦闘・Branch/HEAL/TREASURE 反映。手動攻撃記述を削除 |
| `docs/specs/implementation/11_TASK_INDEX.md` | M3 を完了/未完了に分割。v3.4 エントリ追加 |
| `docs/specs/implementation/CODEMAP.md` | SSOT 注記追加（v3.4） |
| `docs/project/CurrentState.md` | v3.4、M3 進行中、Next Task 更新 |
| `docs/project/CurrentSprint.md` | Phase2-M3 アクティブスプリント、残 6 Task 優先順位 |

### v3.4 で意図的に SSOT 未反映（M3 残タスク）

- Merchant Room
- Event Room
- Elite Room
- Discovery System
- SkillData Resource（SSOT 確定）
- DataRegistry（SSOT 確定）

### 継承（v3.3 から変更なし）

- `docs/specs/game/07_武器_装備.md`
- `docs/specs/game/08_戦闘_AI.md`
- `docs/specs/decisions/01_MVP方針決定.md`
- `docs/specs/game/04_ゲームループ.md`

---

## v3.3 — 2026-06-21

- Phase2-M2 Combat Spec Alignment 反映
- 自動戦闘・個別 HP・全滅判定
- 武器/防具/装飾品戦闘接続

## v3.2 以前

CHANGELOG 開始前。詳細は `11_TASK_INDEX.md` 参照。
