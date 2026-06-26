# CODEMAP — 現行実装マップ

**目的:** リポジトリに**実在する**ファイル・ディレクトリを記録する。

> **警告:** `02_ディレクトリ構成.md` や `05_実装ロードマップ.md` は将来/target 構成を含む。Task が明示的に要求しない限り、そこに記載された未実装ファイルを**作成・参照してはならない**。本ファイルが現行実装の正。

**最終確認:** 2026-06-25（ProjectDocs v3.5.60）

> **SSOT 注記:** Phase EQ-1 **完了**（P3-D020）。Phase3-B-M2 **完了**（P3-D023）。Phase UI-2 **Closeout**（P3-D015）。**UI-2+ Closeout**（P3-UI2-013〜016）。

---

## フェーズ

Phase 3-B-M2 — Status/Element **完了**。UI-2+ **Closeout**。詳細は `docs/project/CurrentState.md`。

---

## Autoload（登録済み）

| 名前 | パス |
|---|---|
| GameState | `scripts/autoload/GameState.gd` |
| DataRegistry | `scripts/autoload/DataRegistry.gd` |
| SceneRouter | `scripts/autoload/SceneRouter.gd` |
| EventBus | `scripts/autoload/EventBus.gd` |

---

## シーン（.tscn）

| シーン | パス | スクリプト |
|---|---|---|
| BootScene | `scenes/boot/BootScene.tscn` | `scripts/boot/BootScene.gd` |
| BaseScene | `scenes/base/BaseScene.tscn` | `scripts/base/BaseScene.gd` |
| DungeonScene | `scenes/dungeon/DungeonScene.tscn` | `scripts/dungeon/DungeonScene.gd` |
| ResultScene | `scenes/result/ResultScene.tscn` | `scripts/result/ResultScene.gd` |
| AppraisalScene | `scenes/appraisal/AppraisalScene.tscn` | `scripts/appraisal/AppraisalScene.gd` |
| EquipmentScene | `scenes/equipment/EquipmentScene.tscn` | `scripts/equipment/EquipmentScene.gd` |
| BlacksmithScene | `scenes/blacksmith/BlacksmithScene.tscn` | `scripts/blacksmith/BlacksmithScene.gd` |
| CodexScene | `scenes/codex/CodexScene.tscn` | `scripts/codex/CodexScene.gd` |

**遷移:** Boot → Base → Dungeon → Result →（Appraisal / Equipment / **Blacksmith** / **Codex**）→ Base

**DungeonScene ノード（Phase UI-2 実装済み）:**
- `MainVBox` — HeaderBar / BattlefieldArea / **BattleLogPanel** / **NarrativePanel** / BottomZone
  - `BattleLogPanel`（PanelContainer）— 戦闘中のみ表示（P3-UI2-012）
    - `BattleLogScroll`（ScrollContainer）— `custom_minimum_size` height=200
      - `BattleLogContent`（VBoxContainer）— ログ Label を動的追加（`_append_log`）
  - `NarrativePanel`（PanelContainer）— 非戦闘時のみ表示（P3-UI2-012）
    - `LabelNarrative` — `_set_narrative()`。高さ 200、font 18 + outline
- `BattlefieldArea/RoomTileBg` — `BATTLE_BG_MAP` 背景（royal_ruins v3 / graveyard v2）
- `BattlefieldArea/CombatTierFrame` — エリート/中ボス/ボス戦闘枠（P3-UI2-014）
- `HpBarChr0〜2` / `HpBarEnemy` — 頭上 HP（ルート直下、スプライト position に追従: P3-UI2-005）
- `ChrSprite0〜2`（110,700 / 250,660 / 390,620, scale=5）/ `EnemySprite`（540,480, scale=4）/ `BossSprite`（500,420, scale=4）/ `HitVfxSprite`（540,480）/ `HealVfxSprite`（250,660） — P3-UI2-008
- `HeaderBar/LabelRoom` — `B1 — 部屋 n/m [種別]`（P3-UI2-011）
- `MenuOverlay` — ≡ メニュー（探索終了のみ）
- 浮動ダメージ数字: `DamageNumbers`（CanvasLayer layer=10）上に `_spawn_damage_number()` が Label を動的生成
- `DiscoveryToastLayer`（CanvasLayer layer=20）— Codex 初見トースト（P3-UI2-015）

- 状態異常アイコン: ルート直下 HBox（敵 + Chr0〜2）— HP バー上に追従（P3-UI2-013）。`StatusResolver.get_active_status_list()`

**BaseScene ノード（UI-2+）:**
- `VBoxContainer/BuildChipRow` — `BuildTagHelper.populate_chip_row()`（P3-UI2-016）

**EquipmentScene ノード（UI-2+）:**
- `ContentVBox/BuildChipRow` — 同上 + `LabelBuildSummary`（Task037）

`scenes/ui/` は `.gitkeep` のみ（未実装）。

---

## スクリプト（.gd）

### autoload/
`GameState.gd`, `DataRegistry.gd`, `SceneRouter.gd`, `EventBus.gd`

### core/
`Constants.gd`（RESOURCE_*_PATH 含む）, `Enums.gd`

### data/
`WeaponData.gd`, `ArmorData.gd`, `AccessoryData.gd`, `EnemyData.gd`, `DungeonData.gd`, `SkillData.gd`, `MaterialData.gd`, `JobData.gd`, `AffixData.gd`, `CraftData.gd`, `RecipeData.gd`, `MaterialShopData.gd`

### domain/
`Adventurer.gd`（**equipped_weapon/armor/accessory**）, `Stats.gd`, `WeaponData.gd`, `ArmorInstance.gd`, `AccessoryInstance.gd`, **`StatusInstance.gd`**

### 機能別
| ディレクトリ | ファイル |
|---|---|
| `discovery/` | `DiscoveryRegistry.gd`（`get_display_label` / `get_category_label` — P3-UI2-015） |
| `appraisal/` | `AppraisalController.gd`, `AppraisalScene.gd` |
| `base/` | `BaseScene.gd` |
| `boot/` | `BootScene.gd` |
| `combat/` | `CombatController.gd`, `SkillExecutor.gd`, **`StatusResolver.gd`**, **`StatusInstance.gd`**, **`ElementResolver.gd`** |
| `dungeon/` | `DungeonController.gd`, `DungeonScene.gd` |
| `equipment/` | `EquipmentController.gd`, `EquipmentScene.gd`, **`BuildTagHelper.gd`**（P3-UI2-016）, **`AffixRoller.gd`**, **`AffixStatCalculator.gd`**, **`AffixDisplayFormatter.gd`**, **`JobStatCalculator.gd`** |
| `blacksmith/` | `BlacksmithScene.gd`（Craft 実行: 検証 → Gold/素材消費 → Instance 生成 → Save） |
| `codex/` | **`CatalogHelper.gd`**（P2-Task046/049 — Bible parse + Entry）, **`CodexScene.gd`**（P2-Task047/048/049 — Detail + Bible fields） |
| `result/` | `ResultScene.gd` |
| `save/` | `SaveManager.gd` |
| `ui/` | **`IconPaths.gd`**（Phase3-A — static class、ICON_MAP による `category:id` → `ICO_*.png` 解決） |

### プレースホルダのみ（.gitkeep、コードなし）
`scripts/loot/`

---

## 未実装（target ドキュメントに記載あり・**現リポジトリに存在しない**）

Task 明示指示がない限り作成しない:

| 想定パス | 備考 |
|---|---|
| `scripts/combat/UnitController.gd`, `DamageCalculator.gd`, `TargetSelector.gd` | 未作成 |
| `scripts/dungeon/DungeonGenerator.gd`, `RoomController.gd`, `ExplorationController.gd` | 未作成 |
| `scripts/loot/*.gd` | ディレクトリのみ |
| `scripts/domain/ItemInstance.gd`, `AffixInstance.gd` | 未作成 |
| `scripts/core/RandomUtil.gd` | 未作成 |
| `scenes/dungeon/RoomNode.tscn` 等 | 未作成 |
| `scenes/ui/*.tscn` | 未作成 |
| `resources/animation/CHR_*.tres` | 冒険者スプライト — P3-A-008（CHR PNG 未納品） |
| `resources/animation/BossGravekeeper.tres` | 白骸墓地ボス — P3-A 後半（PNG 未納品） |

---

## リソース（.tres）

### 武器 / 防具 / 装飾品 / ダンジョン / スキル / 素材 / Affix / ジョブ / クラフト

| 種別 | パス |
|---|---|
| 武器 | `resources/weapons/iron_sword.tres`, `rusted_blade.tres` |
| 防具 | `resources/armors/leather_armor.tres`, `bone_armor.tres` |
| 装飾品 | `resources/accessories/silver_ring.tres` |
| 敵 | 王都跡 5 + 白骸墓地 6（`resources/enemies/`） |
| ダンジョン | `resources/dungeons/royal_ruins.tres`, `graveyard.tres` |
| スキル | `resources/skills/slash_attack.tres` |
| 素材 | `resources/materials/` — relic_shard, elite_relic_shard, ancient_bone, cursed_iron, leather |
| Affix | `resources/affixes/` — 7 サンプル + **AffixRoller** |
| ジョブ | `resources/jobs/` — warrior, guardian, scout |
| クラフト | `resources/crafting/` — craft_leather_armor, craft_bone_armor, craft_silver_ring |
| レシピ | `resources/recipes/` — recipe_leather_armor, recipe_bone_armor, recipe_silver_ring |
| 素材ショップ | `resources/material_shop/` — relic_shard, ancient_bone |

### animation/（Phase3-A — SpriteFrames）

| ファイル | ダンジョン | 内容 |
|---|---|---|
| `BossRoyalGuardCaptain.tres` | 王都跡 | idle×6 / attack×8 / hurt×3 / death×8（64×64 strip） |
| `ENM_FallenSoldier.tres` | 王都跡 | idle×4 / attack×4 / hurt×2 / death×4（32×32 strip） |
| `ENM_RuinedGuard.tres` | 王都跡 | 同上 |
| `ENM_RuinsLooter.tres` | 王都跡 | 同上（PNG .import 未生成） |
| `ENM_RustedKnight.tres` | 王都跡 elite | 同上（PNG .import 未生成） |
| `ENM_BoneWalker.tres` | 白骸墓地 | 同上（PNG .import 未生成） |
| `ENM_GraveBat.tres` | 白骸墓地 | 同上（PNG .import 未生成） |
| `ENM_HollowGravedigger.tres` | 白骸墓地 | 同上（PNG .import 未生成） |
| `ENM_PaleHound.tres` | 白骸墓地 | 同上（PNG .import 未生成） |
| `ENM_OssuaryKnight.tres` | 白骸墓地 elite | 同上（PNG .import 未生成） |

> **注:** `.import` 未生成ファイルは Godot Editor 初回起動で自動生成される。`_show_enemy_sprite()` 内の `ResourceLoader.exists` + null ガードで graceful fallback 済み。

---

## アセット

### assets/ui/

| パス | 内容 | import |
|---|---|---|
| `assets/ui/mvp_theme.tres` | MVP UI テーマ（ロールバック保持） | — |
| `assets/ui/production_theme.tres` | Phase3-A 本番テーマ（全 7 シーン適用済み） | — |
| `assets/ui/batch1/UI_BG_Dark.png` | シーン背景 1280×720 | ✅ |
| `assets/ui/batch1/UI_Btn_Normal.png` | ボタン通常 128×32 | ✅ |
| `assets/ui/batch1/UI_Btn_Pressed.png` | ボタン押下 128×32 | ✅ |
| `assets/ui/batch1/UI_Frame_Panel_Base.png` | 9-slice フレーム | ✅ |
| `assets/ui/batch2/ICO_WPN_IronSword.png` | 武器アイコン 64×64 | ✅ |
| `assets/ui/batch2/ICO_WPN_RustedBlade.png` | 武器アイコン 64×64 | ✅ |
| `assets/ui/batch2/ICO_WPN_Unidentified.png` | 武器未鑑定 64×64 | ✅ |
| `assets/ui/batch2/ICO_ARM_LeatherArmor.png` | 防具アイコン 64×64 | ✅ |
| `assets/ui/batch2/ICO_ARM_Unidentified.png` | 防具未鑑定 64×64 | ✅ |
| `assets/ui/batch2/ICO_ACC_SilverRing.png` | 装飾品アイコン 64×64 | ✅ |
| `assets/ui/batch2/ICO_ACC_Unidentified.png` | 装飾品未鑑定 64×64 | ✅ |
| `assets/ui/batch2/ICO_Gold.png` | Gold アイコン 32×32 | ✅ |
| `assets/ui/batch2/ICO_HP.png` | HP アイコン 32×32 | ✅ |
| `assets/ui/batch2/ICO_MAT_RelicShard.png` | 素材アイコン 64×64 | ✅ |

### assets/dungeon/royal_ruins/

| パス | 内容 | import |
|---|---|---|
| `batch3/TILE_RoyalRuins_Floor_01.png` | 床タイル 32×32 | ✅ |
| `batch3/TILE_RoyalRuins_Wall_01.png` | 壁タイル 32×32 | ✅ |
| `batch3/TILE_RoyalRuins_Corner_Inner.png` | 角タイル（内）32×32 | ✅ |
| `batch3/TILE_RoyalRuins_Corner_Outer.png` | 角タイル（外）32×32 | ✅ |
| `batch3/OBJ_TreasureChest_Closed.png` | 宝箱 32×32 | ✅ |
| `batch3/OBJ_ExitGate_RoyalRuins.png` | 出口ゲート 32×32 | ✅ |
| `batch3/BOSS_RoyalGuardCaptain_Sheet.png` | ボス SpriteSheet 64×64 | ✅ |
| `batch4/ENM_FallenSoldier_Sheet.png` | 通常敵 SpriteSheet 32×32 | ✅ |
| `batch4/ENM_RuinedGuard_Sheet.png` | 通常敵 SpriteSheet 32×32 | ✅ |
| `batch4/ENM_RuinsLooter_Sheet.png` | 通常敵 SpriteSheet 32×32 | ⚠ 未生成 |
| `batch4/ENM_RustedKnight_Sheet.png` | elite 敵 SpriteSheet 32×32 | ⚠ 未生成 |

### assets/dungeon/graveyard/

| パス | 内容 | import |
|---|---|---|
| `batch5/ENM_BoneWalker_Sheet.png` | 通常敵 SpriteSheet 32×32 | ⚠ 未生成 |
| `batch5/ENM_GraveBat_Sheet.png` | 通常敵 SpriteSheet 32×32 | ⚠ 未生成 |
| `batch5/ENM_HollowGravedigger_Sheet.png` | 通常敵 SpriteSheet 32×32 | ⚠ 未生成 |
| `batch5/ENM_PaleHound_Sheet.png` | 通常敵 SpriteSheet 32×32 | ⚠ 未生成 |
| `batch5/ENM_OssuaryKnight_Sheet.png` | elite 敵 SpriteSheet 32×32 | ⚠ 未生成 |

### assets/sprites/, assets/audio/
`.gitkeep` のみ（未実装）。

---

## 更新ルール

新規 `.gd` / `.tscn` / 主要 `.tres` / アセットを追加した Task 完了時に、本ファイルを更新する。
