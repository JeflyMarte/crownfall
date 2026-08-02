# CODEMAP — 現行実装マップ

**目的:** リポジトリに**実在する**ファイル・ディレクトリを記録する。

> **警告:** `02_ディレクトリ構成.md` や `05_実装ロードマップ.md` は将来/target 構成を含む。Task が明示的に要求しない限り、そこに記載された未実装ファイルを**作成・参照してはならない**。本ファイルが現行実装の正。

**最終確認:** 2026-07-11（**P3-CMD-001 / P3-EVT-WEEK-002 Closeout** — 指揮官・6週野外ローテ）

> **SSOT 注記:** … **P3-SKILL Closeout**（基本5職 Lv50 習得10・`skill_unlocks`・レジェンド武器スキル・P3-SKILL-001〜006）。

---

## フェーズ

Phase 3-B-M2 — Status/Element **完了**。UI-2+ **Closeout**。**Combat System v1.0** **完了**（P3-D119）。**P3-SKILL**（基本5職 Lv50 習得10）**完了**（P3-SKILL-001〜006）。次焦点 = **P3-BETA-001**（2本目DG 設計）/ Alpha 実機確認。詳細は `docs/project/CurrentState.md`。

---

## Autoload（登録済み）

| 名前 | パス |
|---|---|
| GameState | `scripts/autoload/GameState.gd` |
| DataRegistry | `scripts/autoload/DataRegistry.gd` |
| SceneRouter | `scripts/autoload/SceneRouter.gd` |
| EventBus | `scripts/autoload/EventBus.gd` |
| AudioManager | `scripts/audio/AudioManager.gd`（**P3-AUDIO-SE-001/002**・**BGM-001**・`SfxCatalog`/`BgmCatalog`） |
| DailyMissionSystem | `scripts/autoload/DailyMissionSystem.gd`（**P3-DAILY-002** プールから毎日3件抽選） |
| EventSystem | `scripts/autoload/EventSystem.gd`（**P3-EVT-FIELD-001** 30分スロット・重み付き野外速報・`EventWeekRotation` SSOT） |
| GachaSystem | `scripts/autoload/GachaSystem.gd` |

**危険度ティア（P3-DG-TIER / P3-DG-TIER-002）:** `DungeonTierConfig.gd` — Hard/NM はメイン5キャンペーン周回帯。解放=ノーマル全クリア／ハード全クリア。敵Lvボーナス= N5-5 cap / 2×cap。UI=`DungeonSelectScene` TabsRow。  
**ボス開幕オーラ（P3-BAL-BOSS-AURA-A-001）:** 入場時 `boss_*_hex` 状態を味方全員へ。BOSS速度は人数係数、ATK×1.22、hex CD6。
**ティア遭遇圧（P3-BAL-TIER-ENC-A-001）:** 群れ率 H×1.35／NM×1.75。NMエリート=双エリート薄護衛 or 単＋護衛2〜3。本編ボス単体。無限ボス編成=`AbyssDungeonConfig.boss_pack_kind`（33群／66エリート／99+抽選）。  
**ティア見た目／呼称（P3-ENEMY-TIER-VAR）:** `EnemyTierVariantConfig.gd` — 同IDの Hard/NM 表示名＋個性上書き（ベース数値据置）。スプライトは `DungeonScene.ENEMY_SPRITE_MAP_BY_TIER` / `BOSS_*_BY_TIER`（①〜④：モーンゲート／ウィスパーウッド／ミストフェン／ブラックショア）。  
**初期5ストーリー（P3-STORY-STARTER）:** `StarterPickScene` / `StarterRecruitment` — 開始1人選択、メイン章5（×-5）ノーマル初回で候補確定。実加入は拠点 `StarterJoinOverlay`（セリフ→ガチャ入手リビール）。`pending_starter_recruit_id` セーブ。`STARTER_RECRUIT_BETA_EXTRA=false`。

---

## シーン（.tscn）

| シーン | パス | スクリプト |
|---|---|---|
| BootScene | `scenes/boot/BootScene.tscn` | `scripts/boot/BootScene.gd`（→ Title。起動時ロードなし） |
| TitleScene | `scenes/title/TitleScene.tscn` | `scripts/title/TitleScene.gd`（**P3-UI-TITLE-001** / **P3-INTRO-001**） |
| IntroLore / Name / Nina | `scenes/intro/*.tscn` | `scripts/intro/*`（P3-INTRO-001/002・SCROLL-001 自動クロール・ニーナ文字送り・`IntroUiAssets`） |
| StarterPickScene | `scenes/roster/StarterPickScene.tscn` | `scripts/roster/StarterPickScene.gd`（導入BG＋枠） |
| BaseScene | `scenes/base/BaseScene.tscn` | `scripts/base/BaseScene.gd` |
| DungeonSelectScene | `scenes/dungeon/DungeonSelectScene.tscn` | `scripts/dungeon/DungeonSelectScene.gd` |
| DungeonScene | `scenes/dungeon/DungeonScene.tscn` | `scripts/dungeon/DungeonScene.gd` |
| ResultScene | `scenes/result/ResultScene.tscn` | `scripts/result/ResultScene.gd` |
| AppraisalScene | `scenes/appraisal/AppraisalScene.tscn` | `scripts/appraisal/AppraisalScene.gd` |
| EquipmentScene | `scenes/equipment/EquipmentScene.tscn` | `scripts/equipment/EquipmentScene.gd`（**P3-UX-EQUIP-SCROLL-PERF-001** スクロール軽量化／**P3-UX-CHR-STAT-PAGES-001** ステ3ページ／**P3-UX-CHR-EFFECT-PAGES-001** 装備効果3ページ／**P3-UX-EQUIP-MAX-FILTER-001** MAXありフィルタ） |
| BlacksmithScene | `scenes/blacksmith/BlacksmithScene.tscn` | `scripts/blacksmith/BlacksmithScene.gd` |
| CodexScene | `scenes/codex/CodexScene.tscn` | `scripts/codex/CodexScene.gd` |
| GachaScene | `scenes/gacha/GachaScene.tscn` | `scripts/gacha/GachaScene.gd`（**P3-UI-GACHA** モック chrome・Reveal・DetailOverlay・招き／封蔵部屋ガイド） |
| EventScene | `scenes/event/EventScene.tscn` | `scripts/event/EventScene.gd`（**P3-EVT-FIELD-001** ギルド情報誌／いまの野外詳細） |
| ShowcaseScene | `scenes/showcase/ShowcaseScene.tscn` | `scripts/showcase/ShowcaseScene.gd`（**P3-SHOWCASE-001** 展示室・自慢キャラ） |
| SurveyScene | `scenes/survey/SurveyScene.tscn` | `scripts/survey/SurveyScene.gd`（**P3-HUB-SURVEY-001** 調査室。スタッフ＝`SurveyStaff`。ノノカは **P3-SURVEY-NONOKA-JOIN-001** で③クリア後合流） |
| CommanderScene | `scenes/commander/CommanderScene.tscn` | `scripts/commander/CommanderScene.gd`（**P3-CMD-001** 隊長台帳・**P3-CMD-RANK-CURVE-003** 閾値D0/C400/B900/A1500/S2200・豪華到達手当・称号枠）・**P3-CMD-RANKUP-001** `CommanderRankUpOverlay`（拠点ランクアップ祝辞） |
| SettingsScene | `scenes/settings/SettingsScene.tscn` | `scripts/settings/SettingsScene.gd`（設定 MVP・`SettingsPrefs`・特典コード P3-UX-REDEEM-001） |

**遷移:** Boot → Title →（Continue: load→ Base / Pick｜New Game: reset→ Pick→ Base）→ Dungeon → Result →（Equipment / **Blacksmith** / **Codex**）→ Base

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
- `MenuOverlay` — ≡ メニュー（設定／リタイア確認）
- 浮動ダメージ数字: `DamageNumbers`（CanvasLayer layer=10）上に `_spawn_damage_number()` が Label を動的生成
- `DiscoveryToastLayer`（CanvasLayer layer=20）— Codex 初見トースト（P3-UI2-015）
- `HeaderBar` — CT プレビュー（P3-D084）・x1/x2/pause・**周回トグル**（クリア済み DG のみ・P3-D118）
- 戦闘ロジック配線（`DungeonScene.gd`）— CT/ATB・5 スロット戦術（P3-D084〜086）・Threat/陣形（P3-D104/106）・混成/個別ターゲット（P3-D110/111）・詠唱（P3-D112）・スキルローテ（P3-D113）・遺物トリガ（P3-D114）・連携（P3-D115）・ボスフェーズ（P3-D116）・探索スキル（P3-D117）・戦闘スキップ（P3-D118）・**必殺チャージ＋下ゲージ2段（P3-COMBAT-GAUGE-001）**・**必殺カットイン（P3-UX-ULTIMATE-002）**

- 状態異常アイコン: ルート直下 HBox（敵 + Chr0〜2 + 群れ行）— HP バー上に追従（P3-UI2-013 / P3-D110 群れ行）。`StatusResolver.get_active_status_list()`

**BaseScene ノード（P3-UI-Base-A / 003_01 Phase A）:**
- `HubView` — 城背景・`TopBar`（**指揮官カード** P3-CMD-001 + **SP進捗バー** P3-CMD-RANK-REWARD-001 + Gold/魔晶石）・`LeftMenuPanel`（調査室はオミット）・**NinaNavPanel**（**P3-UI-NINA-NAV-001** 右上顔＋吹き出し・10秒／タップ。吹き出し下に調査室ショートカット）・**FieldSurveyBanner**（**P3-EVT-FIELD-001** ギルド情報誌・30分スロット・タップで EventScene）＋右上クリック誘導ロゴ（拡縮点滅・タップ可）・`CurrencyStrip`・`DailyMissionPanel`（ジャンルアイコン）。初回のみ **HubSimpleGuideOverlay**（P3-UI-HUB-GUIDE-001）
- `DungeonSelectScene` — ルートタブ（メイン／イベント／無限）。**DungeonRouteGuideOverlay**（P3-DG-ROUTE-GUIDE-001: イベント／降臨／無限の手引きボタン＋初回P分け）
- 同オーバーレイで拠点部屋ガイド（**P3-HUB-ROOM-GUIDE-001**: 調査室／招き／封蔵／展示室・初回＋「？」。SSOT `decisions/34_HubRoomGuides.md`）
- `MenuGridView` — 003_02 系 3×3 メニュー（下ナビ「メニュー」で切替）
- `BottomNav` — 6タブ（ホーム/パーティ/冒険/強化/ショップ/メニュー）・`BottomNavHelper` + `NavIconHelper`
- 検証: `tools/verify_base_hub.gd` / `tools/verify_bottom_nav.gd`

**EquipmentScene ノード（UI-2+ / Combat v1.0）:**
- `CharacterCard` — 肖像◀▶（`MemberSelectRow` 非表示）・★/Lv/職アイコン・`StatsGrid` 2列・`EquipSlotsGrid` 2×2+足具🔒（P3-UI2-019c）
- `TabEquip/InventoryHeaderRow` — ソート・装備状態フィルタ（P3-UI2-019d）・一覧は全装備+装備者ミニアイコン
- `TabAwaken` / `TabProfile` — disabled+準備中（P3-UI2-019e）
- `ContentVBox/BuildChipRow` — 同上 + `LabelBuildSummary`（Task037）
- スキルタブ — 行動方針7択・陣形行・**🔒Lv解放表示**（P3-SKILL-001）・武器スキル行（P3-SKILL-004）・探索スキル一覧（P3-D117）・連携 hint（P3-D115）

**DungeonSelectScene** — `scenes/dungeon/DungeonSelectScene.tscn` / `scripts/dungeon/DungeonSelectScene.gd`（P3-D080・**P3-UI-DG-001** Featuredバナー+Biome直列カード+Event Footer・**P3-DG-TIER** TabsRow・**P3-UX-EVENT-TITLE-TWOTONE-001** 降臨名2色=`EventDungeonTitleHelper`）

**GuildScene** — `scenes/guild/GuildScene.tscn` / `scripts/guild/GuildScene.gd`（P3-D052 手動認定・**P3-UI2-024** Header/BottomNav・認定カードリスト）

`scenes/ui/` は `.gitkeep` のみ（未実装）。

---

## スクリプト（.gd）

### autoload/
`GameState.gd`, `DataRegistry.gd`, `SceneRouter.gd`, `EventBus.gd`

### core/
`Constants.gd`（RESOURCE_*_PATH 含む）, `Enums.gd`

### data/
`WeaponData.gd`, …, **`DailyMissionData.gd`**（P3-DAILY）, **`EventData.gd`**（P3-EVT-HUB — `modifier_type` / 日付境界）

### domain/
`Adventurer.gd`（**equipped_weapon/armor/accessory**）, `Stats.gd`, `WeaponData.gd`, `ArmorInstance.gd`, `AccessoryInstance.gd`, **`StatusInstance.gd`**

### 機能別
| ディレクトリ | ファイル |
|---|---|
| `discovery/` | `DiscoveryRegistry.gd`（`get_display_label` / `get_category_label` — P3-UI2-015） |
| `appraisal/` | `AppraisalController.gd`, `AppraisalScene.gd` |
| `base/` | `BaseScene.gd`（**P3-UI-Base-A** Hub/MenuGrid・日課報酬表示・**EventBanner** P3-EVT-HUB・**NinaNav** P3-UI-NINA-NAV-001・**HubSimpleGuide** P3-UI-HUB-GUIDE-001） |
| `event/` | **`EventScene.gd`**・**`EventScheduleHelper.gd`**（JST 日付境界） |
| `boot/` | `BootScene.gd`（Title へ委譲） |
| `title/` | `TitleScene.gd`（**P3-UI-TITLE-001**） |
| `combat/` | **コア:** `CombatController.gd`（`class_name`・CT/ATB・Threat・群れ/混成・個別ターゲット・詠唱・ボスフェーズ index）, `SkillExecutor.gd`, `StatusResolver.gd`, `StatusInstance.gd`, `ElementResolver.gd`, **`DamageCalculator.gd`**（ダメージ式 SSOT・シーン非依存 static・P3-REF-001）, **`BalanceConfig.gd`**（グローバルバランス定数 SSOT・P3-BAL-005） |
| | **戦術/AI:** `CombatTactics.gd`（行動方針7・重み付きルーレット・旧IDマップ）, `CombatGambit.gd`（条件ラベル等・カスタム実行はオミット） |
| | **バランス:** `BalanceConfig.gd`（STAT_SCALE・成長・Threat・**P3-BAL-OPENING-001** 敵グローバル倍率／味方ボーナス圧縮・**P3-BAL-CLEAR-EXP-001** CLEAR時EXP+25%） |
| | **パッシブ/シナジー:** `CombatPassives.gd`, **`AbyssWeaponEffects.gd`**（深層レジェンド戦闘状態 P3-DG-ABYSS-001-C）, `CombatSynergy.gd`, `CombatTags.gd`, `CombatCombos.gd`（P3-D109）, **`EnemyResistTelop.gd`**（T6/T7 初回軽減テロップ）, 敵トリッキー第2波=`haste`/`silence`/`summon`＋`lifesteal_ratio`（`36_EnemyTrickyWave2.md`）, **群れ人数連動**=`BalanceConfig.swarm_density_*`（`37_SwarmDensitySoloPressure.md`）, **ELITE護衛／ボス個別hex**=`ELITE_ESCORT_*`＋`boss_*_hex`（`38_EliteBossPressure.md`）、**ボス開幕オーラ**=`45_BossOpeningAura.md`／`BOSS_ATK_MULT`、**必殺圧力**=`ULTIMATE_CHARGE_PRESSURE_*`（`39_UltimateChargePressure.md`）、**必殺役割**=VG防御バフ／SW全体／AL全体回復／BTデバフ（`41_UltimateRoleSplit.md`）、**回復maxHP％**=`HEAL_FRAC_*`（`42_HealMaxHpFraction.md`） |
| | **メタ/周回:** `CombatPassives.gd`（レリック定義 SSOT・P3-RELIC-PASSIVE）, `CombatRelics.gd`（表示/互換ファサード）, `CombatLinks.gd`（連鎖3種・P3-D115）, `CombatBossPhases.gd`（P3-D116）, `ExplorationSkills.gd`（P3-D117・**P3-BAL-TRAP-TIER-001** 罠ティア）, `CombatFastRun.gd`（P3-D118）, `CombatWeather.gd`（天候・P3-D101 / W1-A / **Biome偏り P3-WEATHER-BIOME-BIAS-001**） |
| `dungeon/` | `DungeonController.gd`, `DungeonScene.gd`（生態素材ドロップ・図鑑方針ボーナス P3-D128）・**`DungeonTierConfig.gd`**（危険度ティア P3-D164）・**`AbyssDungeonConfig.gd`**（深層階数帯／**敵Lv絶対表 P3-DG-ABYSS-LV-001**）・**`AbyssMilestoneRewards.gd`**／**`AbyssLegendaryWeapons.gd`**／**`AbyssLegendaryDrop.gd`**（深層マイルストーン・レジェンド付与・低確率天井）・**`EventExclusiveRewards.gd`**（降臨セット装備ドロップ P3-DG-EVENT-SET-001）・**`EventDungeonSchedule.gd`**（曜日開放＋時間帯降臨 chronos 0/3/6/9・valgard 1/4/7/10）・**`EnemyTierVariantConfig.gd`**（Hard/NM 呼称・個性 P3-ENEMY-TIER-VAR）・**`WanderingEnemyConfig.gd`**（遍在希少種 P3-D166） |
| `equipment/` | **状態付与一本化**（`EquipmentRandomMods`／P3-EQ-STATUS-UNIFY-001: 専用炎上付与等→`on_hit_status`）／**焼直し**（`EquipmentReforgeHelper`／P3-FORGE-REFORGE-001）／**装備総合力**（`EquipmentPower`／P3-EQ-POWER-RECOMMEND-002・主ステ寄り・非表示・おすすめ比較） | `EquipmentController.gd`, `EquipmentScene.gd`, **`EquipmentUiHelper.gd`**（P3-UI2-019）, **`EquipmentUiTokens.gd`**（装備 chrome）, **`BuildTagHelper.gd`**（P3-UI2-016）, **`EquipmentRandomMods.gd`**（P3-EQ-DIABLO-001）, **`EquipmentReforgeHelper.gd`**, **`EquipmentPower.gd`**, **`EquipmentRecommendHelper.gd`**, **`AffixRoller.gd`**（レガシー）, **`AffixStatCalculator.gd`**, **`AffixDisplayFormatter.gd`**, **`JobStatCalculator.gd`** |

| `blacksmith/` | `BlacksmithScene.gd`（生産／炉研ぎ／**焼直し**／**錬成**／分解 — **P3-FORGE-ALCHEMY-001**／**P3-FORGE-REFORGE-001**）・`BlacksmithUiHelper.gd`・**`ForgeUiTokens.gd`** |
| `gacha/` | **`GachaSystem.gd`**・**`GachaRarityConfig.gd`**・**`GachaLimitBreak.gd`**（**P3-GACHA-LIMIT-001**）・**`GachaRevealPresenter.gd`**（**P3-GACHA-REVEAL-001**）・**`GachaScene.gd`**（P3-UI2-020・**P3-GACHA-002/003**・**P3-UI-GACHA**・**P3-GACHA-FEATURE-IDLE-001** Featured idle・**P3-GACHA-FEATURE-BLURB-001** 特徴行・**P3-GACHA-EQ-SEAL-UI-001** 招き↔封蔵 ←→）・**`GachaEquipSystem.gd`**（封蔵の匣・灰冠27）・**`GachaUiTokens.gd`**・**`GachaUiHelper.gd`** |
| `pets/` | **`PetSystem.gd`**・**`PetData.gd`**（ジャック／色変え・**P3-PET-SURVEY-UNLOCK-001** WW/BS調査100%解放） |
| `survey/` | **`SurveySystem`**／**`SurveyConfig`**／**`SurveyScene`**／**`SurveyClaimResultOverlay`**（サイクル受取＝鍛冶分解同型ポップ＋派遣EXP表示）／**`SurveyCompleteRewards`**（完全調査100%ごと景品→0%・ペット初回のみ・P3-SURVEY-COMPLETE-001）。派遣EXP＝P3-SURVEY-DISPATCH-EXP-001。DISPATCH素材＝Biome重み／武器＝派遣先`weapon_pool`（P3-SURVEY-REWARD-VAR-001） |
| `tickets/` | **`TicketIds`**／**`TicketInventory`**／**`TicketSystem`**（無料ガチャ・**封蔵開封券**・LB★2/3/4） |

| `equipment/MythicLoot.gd` | 神話ドロップ SSOT（**P3-EQ-MYTHIC-001**） |
| `equipment/EquipmentSetBonuses.gd` | 降臨セット加護・3部位判定（**P3-DG-EVENT-SET-001**） |
| `guild/` | **`GuildScene.gd`**（P3-D052 ジョブ認定・**P3-UI2-024** polish。βは `JOB_EVOLUTION_PLAYABLE=false` でオミット案内のみ／P3-JOB-EVO-OMIT-001） |
| `crafting/` | **`CraftHelper.gd`**（`can_craft` / `get_craftable_recipes` — P3-D141／入手解放・`last_run_craft_unlocks` — P3-CRAFT-DISCOVER-001 / P3-UX-RESULT-CRAFT-UNLOCK-001） |
| `codex/` | **`CatalogHelper.gd`**（歴史／断片は `resources/codex/*.json` bake 優先・`tools/bake_codex_bible.py`）／**`GuideCatalog.gd`**／**`CharacterCodexProfiles.gd`**（初期5人物録）／**`CodexRichText.gd`**, **`CodexScene.gd`**（タブ＝敵／装備／歴史／**世界観**／**キャラ**／手引き。実績は `CODEX_ACHIEVE_PLAYABLE` でオミット可） |
| `result/` | `WipeCauseHelper.gd`（全滅敗因スナップショット・**P3-UX-WIPE-CAUSE-002** 群れ／状態／天候ヒント） |
| `result/` | `ResultScene.gd`（**P3-UX-WIPE-CAUSE-002** 全滅敗因2〜3行・素材アイコン P3-D135・**生産レシピ解放＝今回のみ** P3-UX-RESULT-CRAFT-UNLOCK-001・**P3-UI2-023** パネル/フッター polish・**P3-UX-SKILL-LEARN-PERSIST-001** 習得を名横に常時表示・**P3-BAL-CLEAR-EXP-001** クリアボーナス行） |
| `save/` | `SaveManager.gd` |
| `systems/` | **`LevelSystem.gd`**（**Lv99上限** P3-LV-099・Lv51+逓減成長）・**`SkillProgression.gd`**・**`WeaponSkillHelper.gd`**・`JobEvolution.gd`／**`EvolutionTraits.gd`**／`EvolutionVisual.gd`（到達形・βは `JOB_EVOLUTION_PLAYABLE=false`／P3-JOB-EVO-OMIT-001） |
| `ui/` | **`IconPaths.gd`** …（Phase3-A — static class、ICON_MAP による `category:id` → `ICO_*.png` 解決）・**`AccessoryIconHelper.gd`**（装飾品形カテゴリ汎用 Ring/Charm/Talisman/Seal）・**`CurrencyHelper.gd`**（魔晶石表示 SSOT）・**`HeaderCurrencyHelper.gd`**（右上ゴールド／魔晶石をホーム TopBar 基準で統一・**P3-UX-CURRENCY-CHROME-001**）・**`BottomNavHelper.gd`**（全拠点系6タブ遷移・**P3-UI-Base-A**）・**`NavIconHelper.gd`**（下ナビ/左メニューアイコン）・**`UiTypography.gd`**・**`StatusEffectLinkHelper.gd`**（説明文の状態異常タップ→効果ポップ）・**`SkillEffectOneLineHelper.gd`**（必殺カットイン効果1行・**P3-UX-ULTIMATE-EFFECT-001**） |
| `audio/` | **`AudioManager.gd`**（Autoload）・**`SfxCatalog.gd`**（武器別ヒット `combat_hit_bow`/`staff`・**P3-UX-COMBAT-VFX-001**）・**`BgmCatalog.gd`**（**P3-AUDIO-SE-001/002 / BGM-001**） |

### プレースホルダのみ（.gitkeep、コードなし）
`scripts/loot/`

---

## テスト / CI（P3-TEST-001）

| パス | 内容 |
|---|---|
| `addons/gut/` | GUT 9.7.0（ユニットテストフレームワーク・`project.godot` の `[editor_plugins]` に登録） |
| `.gutconfig.json` | GUT 既定設定（`res://tests/unit`・prefix `test_`） |
| `tests/unit/test_save_manager.gd` | SaveManager テスト（ラウンドトリップ / job・dungeon マイグレーション / 破損セーブ耐性 / **save_version**（P3-SAVE-001）。実セーブは before_all/after_all で退避・復元） |
| `tests/unit/test_damage_calculator.gd` | DamageCalculator 純粋関数テスト（防御逓減・Biome相性・属性解決 — P3-REF-001） |
| `tests/unit/test_run_modifiers.gd` | ラン補正カウンタ（Result「効いた戦闘要素」— P3-UX-001） |
| `tests/unit/test_event_system.gd` | 期間バフイベント（日付境界・週次ローテ — P3-EVT-HUB） |
| `tests/unit/test_dungeon_tier.gd` | 危険度ティア解放・敵Lv/レア補正（P3-DG-TIER） |
| `tests/unit/test_level_system.gd` | Lv99上限・逓減成長・スキル習得据置（P3-LV-099） |
| `tools/run_tests.sh` | headless GUT 実行（バイナリ検出は `smoke_test.sh` と同一・exit code 伝播） |
| `tools/smoke_test.sh` | 既存受理ゲート（import + 120frame 起動） |
| `tools/ui_audit.gd` | **UI 監査**（P3-UI3-001/003・**P3-UI-GACHA**）。ハブ7画面＋鍛冶屋生産/強化＋図鑑6タブ＋召喚所 detail/reveal を実レンダでスクショ（`user://ui_audit/`）。ヘッドレス不可 |
| `tools/generate_forge_ui_assets.py` | 鍛冶屋 UI chrome 14枚プロシージャル生成 → `assets/ui/forge/` |
| `tools/generate_equipment_ui_assets.py` | 装備画面 UI chrome 生成 → `assets/ui/equipment_ui/` |
| `tools/generate_gacha_ui_assets.py` | 招待状 UI chrome 17枚プロシージャル生成 → `assets/ui/gacha_ui/`（**P3-UI-GACHA**） |
| `tools/generate_gacha_invite_assets.py` | 開封リビール用 Invite スプライト生成（**P3-GACHA-REVEAL-001**） |
| `tools/ui_audit_run.gd` | **UI 監査 戦闘・リザルト編**（P3-UI3-002）。DungeonScene 実走4時点＋ResultScene clear/wipe を撮影。ヘッドレス不可 |
| `tools/generate_enemy_battle_assets.py` | 図鑑肖像→戦闘シート96×14＋`SpriteFrames` `.tres`＋`DungeonScene.gd` マップ自動更新 |
| `tools/generate_all_skill_icons.py` | 全スキル `.tres` からプロシージャルアイコン生成＋`IconPaths` 一括更新 |
| `tools/verify_icon_paths.py` | `IconPaths.gd` と resources/実ファイルの整合検証 |
| `tools/balance_sim.sh` / `tools/balance_sim.gd` | **バランスシミュレーションハーネス v2**（P3-BAL-005/006）。実データで N ラン一括シミュ→勝率/全滅箇所/TTK/与ダメ内訳。通常攻撃＋装備スキル①②（damage/heal・CD準拠）。`--runs= --dungeon= --party-level= --sweep --enemy-scale= --boss-scale= --hp-per-level= --atk-per-level= --gear-atk= --gear-def= --gear-hp=` |
| `.github/workflows/ci.yml` | GitHub Actions: Godot 4.6.3 linux headless で `smoke_test.sh` → `run_tests.sh` |

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
| `resources/animation/CHR_*.tres` | 冒険者スプライト（メイン5職・P3-ART-CHR-002。`idle`＝walk。取込=`tools/import_job_chr_sprites.py`）。ガチャ助っ人は `CHR_Helper_{a,b,c,e,f,i}.tres`（`tools/import_gacha_helper_sprites.py` → `GachaHelperData.sprite_resource_path`） |
| `resources/animation/BossGravekeeper.tres` | 白骸墓地ボス — P3-A 後半（PNG 未納品） |

---

## リソース（.tres）

### 武器 / 防具 / 装飾品 / ダンジョン / スキル / 素材 / Affix / ジョブ / クラフト

| 種別 | パス |
|---|---|
| 武器 | `resources/weapons/` — 61本（①〜⑤ = 13+12×4。★は各難易度2・P3-D154/D156/D160/D161） |
| 防具 | `resources/armors/` — 28（① 2 + ②〜⑤ 各5 + 寄り道3） |
| 装飾品 | `resources/accessories/` — 17（① + ②〜⑤ 各3 + 寄り道2） |
| 敵 | `resources/enemies/`（`EnemyData.basic_attack_name`＝通常攻撃頭上名・**P3-UX-ENEMY-BASIC-NAME-001**）— メイン（①〜⑤・P3-ENEMY-002 拡充）+ 征討／降臨 Boss（chronos_wave→`chronos_mausoleum` / valgard→`valgard_boundary` / skarpedion / mycolga_ancient / karna_smoke / nereion_depths / forgedormient / albark）+ 遍在希少種4（P3-WANDER-002/004: cosmic_duck / crown_raven / golden_scarab / shadow_stalker）+ ロックバイソン（P3-ENEMY-ROCK-BISON-001: 全非イベント雑魚・素材率1.75・専用ドット／図鑑／イベント `rock_stampede`） |
| ダンジョン | `resources/dungeons/` — **28本**: メイン5 + 寄り道5 + 征討8 + イベント5 + **深層5**（`abyss_*`／**P3-DG-ABYSS-001**）。`route_type`: main/side/apex/event/abyss。イベントは日次挑戦枠（DGごと）。**章データがある Biome は route 不問でバナー下にサブ章**（P3-DG-EVENT-STG-001）。イベントは各1章。深層は無限階・親Biomeクリアで解放。深層限定レジェンド武器5（`abyss_veinblade` 等／**P3-DG-ABYSS-001-C**） |
| スキル | `resources/skills/` — プレイヤー約50+（基本5職×習得7 + 必殺5 + 属性/敵/ボス）。代表: slash_attack, guard_strike, aimed_shot, hex_bolt, mend, empower + P3-SKILL-002〜006 新規。BT Lv50=`beast_vet_care`／RG Lv50=`camp_draught`（支援回復・`43_BtRgSupportHeal`）。敵エリート第2技: `enemy_mist_talon` / `enemy_mirror_glare` / `enemy_greios_wing_lance` / `enemy_claw_rake` / `enemy_nightfen_siphon` / `enemy_ink_lash` / `enemy_anchor_sweep`（P3-BAL-ENEMY-SKILL-CA-001 Phase C）。**トリッキー**=heal/flee/explode＋`incoming_*_mult`（`35_EnemyTrickySkills.md` Phase1〜3済） |
| ジョブ | `resources/jobs/` — 5職。各 **`skill_unlocks` Lv1/6/12/…/50 で習得10**（P3-SKILL-002〜006） |
| 状態異常 | `resources/status/` — bleed, poison, stun, chill, ignite, shock, slow, curse, guard, empower, enrage, **fear**, **vulnerable**, **armor_break**（P3-D107）, **mark**（P3-D120） |
| 素材 | `resources/materials/` — relic_shard, elite_relic_shard, ancient_bone（炉研ぎ用3種のみ） |
| Affix | `resources/affixes/` — 7 サンプル + **AffixRoller** |
| クラフト | `resources/crafting/` — 6レシピ（武器3/防具2/装飾1・P3-D067/D136） |
| レシピ | `resources/recipes/` — recipe_leather_armor, recipe_bone_armor, recipe_silver_ring |
| 素材ショップ | `resources/material_shop/` — relic_shard, ancient_bone |
| 日課 | `resources/daily_missions/` — プール抽選3件/日（P3-DAILY-002）。撃破・鍛冶系等。**招待日課はプール外**（P3-BAL-GACHA-001） |
| 期間イベント | `resources/events/` — `evt_week_exp` / `evt_week_gold` / `evt_week_weapon`（各7日・P3-D163） |

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
| `assets/ui/batch2/ICO_WPN_Unidentified.png` | 武器未識別 64×64 | ✅ |
| `assets/ui/batch2/ICO_ARM_LeatherArmor.png` | 防具アイコン 64×64 | ✅ |
| `assets/ui/batch2/ICO_ARM_Unidentified.png` | 防具未識別 64×64 | ✅ |
| `assets/ui/batch2/ICO_ACC_SilverRing.png` | 装飾品アイコン 64×64 | ✅ |
| `assets/ui/batch2/ICO_ACC_Unidentified.png` | 装飾品未識別 64×64 | ✅ |
| `assets/ui/batch2/ICO_Gold.png` | Gold アイコン 32×32 | ✅ |
| `assets/ui/batch2/ICO_Currency_Arcanite.png` | 魔晶石（ガチャ通貨）アイコン 64×64 | ✅ |
| `assets/ui/batch2/ICO_HP.png` | HP アイコン 32×32 | ✅ |
| `assets/ui/materials/ICO_MAT_BaseOre.png` | 基礎鉱（`base_ore`） | ✅ |
| `assets/ui/materials/ICO_MAT_RelicShard.png` | 遺跡の結晶（`relic_shard`） | ✅ |
| `assets/ui/materials/ICO_MAT_EpicOre.png` | 深層結晶（`epic_ore`） | ✅ |
| `assets/ui/materials/ICO_MAT_EliteRelicShard.png` | 王墓の欠片（`elite_relic_shard`） | ✅ |
| `assets/ui/materials/ICO_MAT_AncientBone.png` | 蒼古の骨鉱（`ancient_bone`） | ✅ |
| `assets/ui/nav/ICO_NAV_*.png` | 下ナビ/サイドメニュー金アイコン 128×128 ×8（Home/Adventure/Character/Party/Forge/Gacha/Codex/Settings — P3-UI3-001 で AI 生成・ソース復旧） | ✅ |
| `assets/ui/UI_BG_Forge.png` | 鍛冶屋背景 720×1280（P3-UI3-001） | ✅ |
| `assets/ui/forge/` | 鍛冶屋 chrome（DetailPanel／Tab／ListCard／CraftablePanel／主ボタン・`ForgeUiTokens`） | ✅ |
| `assets/ui/equipment_ui/` | 装備画面 chrome（背景/カード/タブ/スロット/一覧セル等・`EquipmentUiTokens`） | ✅ |
| `assets/ui/gacha_ui/` | 召喚所 chrome 17枚（背景/タブ/バナー/天井バー/召喚ボタン/リボン/ラインナップセル/Reveal枠等・`GachaUiTokens` — **P3-UI-GACHA**） | ✅ |
| `assets/ui/gacha_ui/UI_BG_Gacha.png` | 召喚所背景 720×1280（P3-UI3-001） | ✅ |
| `assets/ui/UI_BG_Codex.png` | 図鑑背景 720×1280（P3-UI3-001） | ✅ |

### assets/fonts/

| パス | 内容 |
|---|---|
| `NotoSansJP-VariableFont_wght.ttf` | 本文フォント（wght=700 variation） |
| `ShipporiMinchoB1-Bold.ttf` | 見出し・タイトル（OFL、`ShipporiMinchoB1-OFL.txt` 同梱 — P3-UI3-001） |
| `DelaGothicOne-Regular.ttf` | 戦闘数字・強調（`UiTypography.impact_font()`） |

### assets/dungeon/（サムネイル — P3-UI3-001）

`whisperwood/ICO_DG_Whisperwood.png`・`mistfen/ICO_DG_Mistfen.png`・`broken_marsh/ICO_DG_BrokenMarsh.png`・`blackshore/ICO_DG_Blackshore.png`・`frostridge/ICO_DG_Frostridge.png`（各 1024×1024・IconPaths `dungeon:` 登録済）

章アイコン（`*/stages/ICO_DG_*_*_*.png`）: ① Mourngate / ② Whisperwood / ③ Mistfen / ④ Blackshore / ⑤ Frostridge 各 1〜5（1024×1024・IconPaths `stage:`）。③〜⑤は Biome 別アート（Whisperwood 複製禁止。正規化は `tools/generate_biome_stage_icons.py`）

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

### assets/sprites/
用途別ディレクトリ（敵・UI・VFX 等）。詳細は各 Task 記録。

### assets/audio/
| パス | 内容 |
|---|---|
| `sfx/` | Kenney CC0・`SfxCatalog`（heal/buff/debuff 含む・**P3-AUDIO-SE-001**）。配線拡張 **P3-AUDIO-SE-002** |
| `bgm/` | オーナー制作 MP3（title / introduction / hub / forge / survey / gacha / dungeon_explore / battle / whisperwood / mistfen / blackshore / frostridge / boss / final_boss / result / result_defeat）。`BgmCatalog`（**P3-AUDIO-BGM-001**／**P3-AUDIO-BGM-EXPLORE-RESTORE-001**）。ダンジョン内は非戦闘＝探索／戦闘＝Biome 別（未登録は battle）。例外＝ボス／影狩。フロストリッジ本編ボスは final_boss。Result は勝敗で切替 |

---

## 更新ルール

新規 `.gd` / `.tscn` / 主要 `.tres` / アセットを追加した Task 完了時に、本ファイルを更新する。
