# Task Index

## 注記

Task番号は2系統存在する。

- **ロードマップTask（001〜050）**: 05_実装ロードマップ.md に定義された設計上のTask
- **実装Task（IMPL-035〜IMPL-048）**: MVP 期間に Cursor へ依頼・実施した Task。ロードマップの Task 番号とは一致しない

---

## ロードマップTask（001〜050）

| Task | 概要 | 状態 |
|---|---|---|
| Task001〜034 | 05_実装ロードマップ.md 参照 | 実施済み（詳細はロードマップ参照） |
| Task035〜050 | 05_実装ロードマップ.md 参照 | ロードマップ定義のみ（下記実装Taskに置き換わった） |

---

## 実装Task（IMPL-035〜IMPL-048）— 完了済み

ロードマップのPhase8〜10を短縮したMVPショートカットパス。

| 実装Task | 内容 | 変更ファイル |
|---|---|---|
| IMPL-035 | ProjectDocs監査・SaveManager完全化（Gold/Party/Inventory/Equipment/Progress） | SaveManager.gd |
| IMPL-036 | MVP UIテーマ作成（mvp_theme.tres）・全シーン適用 | assets/ui/mvp_theme.tres, 各.tscn |
| IMPL-037 | WeaponData/WeaponInstance/GameState.inventory/ドロップ実装 | WeaponData.gd, WeaponInstance.gd, DungeonController.gd |
| IMPL-038 | AppraisalScene作成（ナビゲーション・表示のみ） | AppraisalScene.tscn, AppraisalScene.gd |
| IMPL-039 | 鑑定ロジック実装（100G消費・is_appraised=true・セーブ） | AppraisalController.gd |
| IMPL-040 | EquipmentScene作成・装備ロジック・セーブ/ロード | EquipmentScene.tscn, EquipmentScene.gd, EquipmentController.gd |
| IMPL-041 | MVPループ結合・バグ修正（ラムダキャプチャ修正） | DungeonScene.gd, ResultScene.gd, 各シーン |
| IMPL-042 | BaseScene MVP完成（Gold/装備表示・Equipmentボタン追加） | BaseScene.tscn, BaseScene.gd |
| IMPL-043 | MVPバランス調整（Gold報酬を1周100G以上に引き上げ） | 各enemy.tres |
| IMPL-044 | MVP UI/UX最小整備（仮テキスト除去・部屋タイプ表示・テキスト統一） | DungeonScene.gd, 各シーン |
| IMPL-045 | Save/Load監査・null guard追加・壊れたセーブ耐性確認 | SaveManager.gd |
| IMPL-046 | End-to-End QA・ボタン多重押し修正・EXIT部屋修正 | DungeonScene.gd, ResultScene.gd |
| IMPL-047 | コードクリーンアップ・party_members安全化・誤記修正 | BaseScene.gd, GameState.gd |
| IMPL-048 | ProjectDocs/Decision更新（本Task） | docs/specs/ 各ファイル |

---

## Phase2 Task（P2-Task005〜012）— Completed

Phase2-M1 Equipment Complete スコープ。

| Task | 内容 | 主な変更ファイル |
|---|---|---|
| P2-Task005 | Weapon System Expansion（attack_speed / critical_rate / knockback / stun_power / attack_range / weight 追加） | WeaponData.gd, WeaponInstance.gd, 各.tres |
| P2-Task006 | Weapon Parameter Combat Integration（rolled_attack・critical_rate を戦闘へ接続） | DungeonScene.gd |
| P2-Task007 | Armor System（ArmorData / ArmorInstance / GameState / SaveManager / EquipmentScene / BaseScene） | ArmorData.gd, ArmorInstance.gd, SaveManager.gd, EquipmentScene.gd, BaseScene.gd |
| P2-Task008 | Armor Loot & Appraisal Integration（30%ドロップ・ResultScene表示・Appraisal対応） | DungeonController.gd, ResultScene.gd, AppraisalController.gd, AppraisalScene.gd |
| P2-Task009 | Armor Combat Effect Integration（防御計算・HP Bonus・隊HP表示・Combat Log） | DungeonScene.gd |
| P2-Task010 | Accessory System（AccessoryData / AccessoryInstance / GameState / SaveManager / Equipment / BaseScene） | AccessoryData.gd, AccessoryInstance.gd, SaveManager.gd, EquipmentScene.gd, BaseScene.gd |
| P2-Task011 | Accessory Loot & Appraisal（20%ドロップ・silver_ring.tres・ResultScene・Appraisal統合） | DungeonController.gd, AppraisalController.gd, AppraisalScene.gd |
| P2-Task012 | Accessory Effect Integration（全効果戦闘接続・_get_effective_stats・Equipment効果表示） | DungeonScene.gd, EquipmentScene.gd |

---

## Phase2-M1 Milestone

**Phase2-M1 Equipment Complete**
**Status:** Completed
**完了日:** 2026-06-19

スコープ:

- Weapon System（パラメータ拡張・戦闘接続）
- Armor System（ドロップ・鑑定・装備・戦闘防御・HP Bonus）
- Accessory System（ドロップ・鑑定・装備・全効果戦闘接続）
- Equipment（武器 / 防具 / 装飾品 3枠完全対応）
- Loot（Weapon 毎回 / Armor 30% / Accessory 20%）
- Appraisal（3カテゴリ統合 duck typing）
- Combat Integration（ATK / DEF / HP / CRT 全効果接続）
- Save / Load（全装備・全インベントリ後方互換）

---

## Phase2-M2 Combat Spec Alignment Tasks — 完了済み

| Task | 内容 | 主な変更ファイル |
|---|---|---|
| P2-Task009（M2） | Dungeon Combat Spec Alignment（自動戦闘化・冒険者個別HP・全滅判定） | CombatController.gd, DungeonScene.gd, DungeonScene.tscn |
| P2-Task011（M2） | ProjectDocs v3.3 Update（07_武器_装備・08_戦闘_AI・Decision Log・Task Index・Roadmap） | docs/specs/ 各ファイル |

**注:** Phase2-M1には `P2-Task009`（Armor Combat Effect Integration）が存在する。M2の `P2-Task009` とはスコープが異なる別Taskである。

### Phase2-M2 Milestone

**Phase2-M2 Combat Spec Alignment**
**Status:** Completed
**完了日:** 2026-06-21

スコープ:

- 自動戦闘（CombatTimer 1.5s）
- 冒険者3人個別HP（CombatController管理）
- 死亡判定・全滅判定・ResultScene遷移
- Weapon/Critical接続の維持
- ProjectDocs v3.3 更新

---

## Phase2-M3 Room System Tasks

### 完了（ProjectDocs v3.4 反映済）

| Task | 内容 | 主な変更ファイル |
|---|---|---|
| P2-Task011（impl） | EnemyData パラメータ拡張・EnemyType enum・5敵.tres更新 | EnemyData.gd, Enums.gd, 各enemy.tres |
| P2-Task012 | Branch Route System（Safe/Dangerous/Unknown・branch_enabled） | DungeonController.gd, DungeonScene.gd, DungeonData.gd |
| P2-Task013 | HEAL Room（生存メンバー+10回復） | CombatController.gd, DungeonScene.gd |
| P2-Task014 | Treasure Room（Gold+30・Accessory 20%抽選） | DungeonController.gd, DungeonScene.gd |
| P2-Task015 | Merchant Room（防具/装飾品/回復薬・Gold購入・武器非販売） | DungeonController.gd, DungeonScene.gd |
| P2-Task016 | Event Room（5種2択・heal/gold/buff/material/lore） | DungeonController.gd, DungeonScene.gd |
| P2-Task017 | Elite Room（elite_pool・x1.5報酬・ボーナスドロップ） | DungeonController.gd, DungeonScene.gd, 各enemy.tres |
| P2-Task018 | Discovery System（discovery_registry・5カテゴリ登録） | DiscoveryRegistry.gd, GameState.gd, SaveManager.gd, DungeonScene.gd |
| P2-Task019 | SkillData Resource（最小スキーマ・slash_attack サンプル） | SkillData.gd, slash_attack.tres |
| P2-Task020 | DataRegistry（6 カテゴリ lookup SSOT） | DataRegistry.gd, Constants.gd |

### Phase2-M4 World Expansion（完了）

| Task | 内容 | 主な変更ファイル |
|---|---|---|
| P2-Task021 | Multi-Dungeon Foundation | GameState.gd, DungeonController.gd, DungeonScene.gd, BaseScene.gd, SaveManager.gd |
| P2-Task022 | Base Dungeon Select | BaseScene.tscn, BaseScene.gd, Constants.gd |
| P2-Task023 | Graveyard Dungeon + Enemy 6 体 | graveyard.tres, 6 enemy.tres, DungeonController.gd, DungeonScene.gd |
| P2-Task024 | MaterialData Foundation | MaterialData.gd, 4 material.tres, GameState, SaveManager, DataRegistry |

**Phase2-M4 Milestone**
**Status:** **完了**
**ProjectDocs:** v3.5.5（2026-06-21）

### Phase2-M5 Combat Depth（完了）

| Task | 内容 | 主な変更ファイル |
|---|---|---|
| P2-Task025 | SkillExecutor + slash_attack 戦闘接続 | SkillExecutor.gd, DungeonScene.gd, Constants.gd |
| P2-Task026 | Weapon Skill Link（fixed_skill_id） | WeaponData.gd, iron_sword.tres, DungeonScene.gd |
| P2-Task027 | Job Foundation（JobData + DataRegistry） | JobData.gd, 3 job.tres, DataRegistry.gd |

**Phase2-M5 Milestone**
**Status:** **完了**
**ProjectDocs:** v3.5.9（2026-06-21）

### Phase2-M6 Equipment Depth（完了）

| Task | 内容 | 主な変更ファイル |
|---|---|---|
| P2-Task028 | AffixData Foundation | AffixData.gd, 7 affix.tres, DataRegistry.gd |
| P2-Task029 | Affix Roll System | AffixRoller.gd |
| P2-Task030 | Affix Appraisal Integration | AppraisalController.gd, *Instance.gd, SaveManager.gd |
| P2-Task031 | Affix Stat Application | AffixStatCalculator.gd, DungeonScene.gd, CombatController.gd |
| P2-Task032 | Equipment Detail UI | AffixDisplayFormatter.gd, EquipmentScene.gd |

**Phase2-M6 Milestone**
**Status:** **完了**
**ProjectDocs:** v3.5.17（2026-06-21）

### Phase2-M7 Job & Build Foundation（進行中）

| Task | 内容 | 状態 | 主な変更ファイル（予定） |
|---|---|---|---|
| P2-Task033 | Party Job Alignment + JobStatCalculator | **完了** | JobStatCalculator.gd, GameState.gd |
| P2-Task034 | Job Modifier Combat Integration | **完了** | DungeonScene.gd, CombatController.gd |
| P2-Task035 | starting_skill_ids Combat Link | **完了** | DungeonScene.gd |
| P2-Task036 | Job UI | **完了** | BaseScene.gd, DataRegistry.gd |
| P2-Task037 | Build Summary UI | **完了** | EquipmentScene.gd, EquipmentScene.tscn |
| P2-Task038 | Phase2-M7 Closeout | **完了** | ProjectDocs 一式同期 |

**Scope SSOT:** `docs/specs/core/Proposal/Phase2-M7_Scope_Proposal_v1.0.md`（P2-D113）

**Phase2-M7 Milestone**
**Status:** **完了**（2026-06-22）
**ProjectDocs:** v3.5.27（2026-06-22）

| Task | 内容 | 主な変更ファイル |
|---|---|---|
| — | AI Context Optimization Phase A / A.1 | AGENTS.md, CODEMAP.md, 10_Impl依頼テンプレート.md |
| — | ProjectDocs v3.4 Update | docs/specs/, docs/project/, CHANGELOG.md |
| — | Product Vision Completed | Crownfall_Product_Vision_Completed_v1.0.md |
| — | M8 Craft Resource Pack（Parallel Task） | CraftData.gd, RecipeData.gd, resources/crafting/ ×3, resources/recipes/ ×3, leather.tres, Constants.gd, DataRegistry.gd |
| — | M8 Merchant Material Shop Foundation（Parallel Task） | MaterialShopData.gd, resources/material_shop/ ×2, Constants.gd, DataRegistry.gd |

---

### Phase2-M8 Craft & Economy Foundation（**完了** 2026-06-22）

| Task | 内容 | 状態 | 主な変更ファイル |
|---|---|---|---|
| P2-Task039 | CraftData Foundation（Craft Resource Pack） | **完了**（P2-D145） | CraftData.gd, RecipeData.gd, crafting/*.tres, recipes/*.tres, Constants.gd, DataRegistry.gd |
| P2-Task040 | Material Consumption Logic | **完了** | GameState.gd |
| P2-Task041 | BlacksmithScene Foundation | **完了** | BlacksmithScene.tscn, BlacksmithScene.gd, BaseScene.tscn, BaseScene.gd |
| P2-Task042 | Craft Output Integration | **完了** | BlacksmithScene.gd |
| P2-Task043 | Economy Integration（Merchant 拡張） | **完了** | DungeonController.gd, DungeonScene.gd |
| P2-Task044 | Phase2-M8 Closeout | **完了** | ProjectDocs 一式 |

**Scope SSOT:** `docs/archives/GameplayArchive/Proposal/Phase2-M8_Craft_Economy_Foundation_Design_v1.0.md`（P2-D139）

**Phase2-M8 Milestone**
**Status:** **完了**
**ProjectDocs:** v3.5.33（2026-06-22）

---

### Phase2-M9 Codex & Discovery Foundation（進行中）

| Task | 内容 | 状態 | 主な変更ファイル（予定） |
|---|---|---|---|
| P2-Task045 | Codex Scope Adoption | **完了** | ProjectDocs 一式 |
| P2-Task046 | Codex Data Foundation | **完了** | CatalogHelper.gd, DataRegistry.gd |
| P2-Task047 | Codex UI Foundation | **完了** | CodexScene.tscn, CodexScene.gd, BaseScene |
| P2-Task048 | Discovery Detail View | **完了** | CodexScene.gd, CodexScene.tscn |
| P2-Task049 | History / Dungeon Bible Link | **完了** | CatalogHelper.gd, CodexScene.gd |
| P2-Task050 | Phase2-M9 Closeout | 未着手 | ProjectDocs 一式 |

**Scope SSOT:** `docs/archives/GameplayArchive/Proposal/Phase2_M9_Codex_Discovery_Scope_Proposal_v1.0.md`（P2-D148）

**Phase2-M9 Milestone**
**Status:** **進行中**（Scope Adopted 2026-06-22）
**ProjectDocs:** v3.5.38（2026-06-22）

### Phase2-M3 Milestone

**Phase2-M3 Room System**
**Status:** **完了**
**ProjectDocs:** v3.4.6（2026-06-21）

v3.4+ 確定スコープ:

- Branch Route（Safe/Dangerous/Unknown）
- HEAL Room / TREASURE Room / Merchant Room / Event Room / Elite Room
- Discovery System
- SkillData Resource
- DataRegistry
- EnemyData 拡張

---

## Phase3-A Visual Production（**進行中**）

**Scope SSOT:** `docs/archives/ArtArchive/Completed/Phase3A_Scope_Adoption_Completed_v1.1.md`（P3-D001〜007）
**開始:** 2026-06-24
**ProjectDocs:** v3.5.45

### Phase3-A Prep Tasks

| Task | 内容 | 状態 | 主な変更ファイル |
|---|---|---|---|
| P3-Prep-001 | Phase3-A Scope Adoption（P3-D001〜007 承認） | **完了** | Phase3A_Scope_Adoption_Completed_v1.1.md |
| P3-Prep-002 | Dungeon / Weapon Discovery フック | **完了**（レビュー待ち） | DungeonScene.gd |
| P3-Prep-003 | CODEMAP 同期（Phase3-A 反映） | **完了** | CODEMAP.md |
| P3-Prep-004 | CommitPlan 作成 | **完了** | docs/project/CommitPlan_Phase3A.md |
| P3-Prep-005 | Task Index 追記（Phase3-A セクション） | **完了** | 11_TASK_INDEX.md |
| P3-Prep-006 | OD-UI-001 Gap Analysis（モック vs 現行 UI） | **完了** | docs/project/Proposal/OD-UI-001_Gap_Analysis_v1.0.md |
| P3-Prep-007 | Batch 6 / Batch 7 発注書作成 | **完了** | ArtArchive/Proposal/Batch6_Request_v1.0.md, Batch7_Request_v1.0.md |
| P3-Prep-008 | Headless Smoke 手順追記 | **完了** | 12_AssetPipeline.md |
| P3-Prep-009 | Batch6 発注書 SSOT 修正（Hit: 4f/128×32, Heal: 5f/160×32） | **完了** | ArtArchive/Proposal/Pixel_Apprentice_Batch6_Request_v1.0.md |
| P3-Prep-010 | smoke_test.sh 新規（godot4/Godot.app 両対応）+ pipeline 参照リンク | **完了** | tools/smoke_test.sh, 12_AssetPipeline.md |

### Phase3-A Impl Tasks

| Task | 内容 | 状態 | EC | 主な変更ファイル |
|---|---|---|---|---|
| P3-A-001 | production_theme.tres 作成・全 7 シーン適用（BgTexture 含む） | **完了** | EC-2 | production_theme.tres, 全 .tscn ×7 |
| P3-A-Prep-Icons | `IconPaths.gd` 新規（ICON_MAP: `category:id` → `ICO_*.png`） | **完了** | — | scripts/ui/IconPaths.gd |
| P3-A-002 | IconPaths 接続（AppraisalScene / EquipmentScene / CodexScene） | **完了** | EC-4, EC-5 | AppraisalScene.gd/.tscn, EquipmentScene.gd, CodexScene.gd |
| P3-A-003 | RoomArt HBoxContainer 追加（DungeonScene — batch3 タイル動的表示） | **完了** | EC-6 | DungeonScene.tscn, DungeonScene.gd |
| P3-A-004 | BossSprite AnimatedSprite2D 接続（BossRoyalGuardCaptain） | **完了** | EC-3 | DungeonScene.tscn, DungeonScene.gd, BossRoyalGuardCaptain.tres |
| P3-A-005 | 王都跡通常敵 Sprite 接続（4 種 + elite: ENM_*.tres ×4） | **完了** | EC-3 | DungeonScene.tscn, DungeonScene.gd, ENM_*.tres ×4 |
| P3-A-006 | VFX Hit / Heal（GPUParticles2D または AnimatedSprite2D） | **完了** | EC-7 | DungeonScene.gd, assets/vfx/batch6/ |
| P3-A-007 | 白骸墓地通常敵 Sprite + Tile 接続 | **完了** | EC-8 | DungeonScene.gd, ENM_*.tres ×5 |
| P3-A-008 | CHR + Gravekeeper スプライト接続 | **完了** | EC-8 | DungeonScene.gd, CHR_*.tres ×3, BOSS_Gravekeeper.tres |
| P3-A-008b | IconPaths batch7 フルパス化 | **完了** | EC-4 | scripts/ui/IconPaths.gd |
| P3-A-009 | Phase3-A Closeout（EC-1〜7 全 PASS 確認・ProjectDocs 同期） | **完了** | Milestone | docs/project/ 一式 |

### Phase3-A Milestone

**Phase3-A Visual Production**
**Status:** **完了**（2026-06-25）
**EC 状況:** EC-1〜8 ✅（EC-8 P2 defer: P3-D008）

### Phase UI-1 Tasks — 完了

| Task | 内容 | 状態 |
|---|---|---|
| P3-UI-001〜003 | 戦闘画面 v2 レイアウト / HP bar / 背景 | **完了** |

### Phase3-B-M1 Tasks — 完了

| Task | 内容 | 状態 |
|---|---|---|
| P3-B-001〜007 | Status/Element Foundation（旧 Tier1 — P3-D023 前段） | **完了** |

### Phase EQ-1 Tasks — 完了

| Task | 内容 | 状態 |
|---|---|---|
| P3-EQ-001 | GameState / Save per-member 移行 | **完了** |
| P3-EQ-002 | 戦闘 per-member 装備 | **完了** |
| P3-EQ-003 | EquipmentScene メンバー選択 | **完了** |
| P3-EQ-004 | BaseScene パーティ装備表示 | **完了** |

### Phase3-B-M2 Tasks — 完了

| Task | 内容 | 状態 |
|---|---|---|
| P3-B-008 | StatusEffectData 拡張 + 6 status .tres | **完了** |
| P3-B-009 | StatusResolver + ElementResolver（P3-D022） | **完了** |
| P3-B-010 | DungeonScene 戦闘接続 | **完了** |
| P3-B-011 | Affix×4 / Skill×3 / Weapon×5 | **完了** |
| P3-B-012 | M2 Closeout（P3-D023） | **完了** |
