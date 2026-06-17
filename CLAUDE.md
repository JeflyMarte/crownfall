# Crownfall — CLAUDE.md

Godot 4に精通したシニアゲームエンジニアとして実装する。

---

## プロジェクト概要

- タイトル: Crownfall（仮）
- ジャンル: スマホ向け2D見下ろし型・自動探索ハクスラRPG
- エンジン: Godot 4.6.3 Standard / GDScript
- ターゲット: iOS優先、Android対応
- 画面: Landscape固定 / 1280×720
- 目標FPS: 60

プレイヤーは冒険者を直接操作しない。探索隊の指揮官として、方針・装備・編成を決める。

---

## 仕様書の場所

```
docs/specs/core/          プロジェクト憲章・設計原則・ロードマップ
docs/specs/game/          ゲーム仕様（ゲームループ・戦闘・装備・ドロップ等）
docs/specs/implementation/ Godotアーキテクチャ・ディレクトリ構成・実装ロードマップ
docs/specs/decisions/     確定済みMVP方針（元仕様書を補完・上書きする）
```

実装前に必ず参照するファイル：

1. `docs/specs/decisions/01_MVP方針決定.md` ← 元仕様書との差分はここ
2. `docs/specs/game/02_MVP設計.md`
3. `docs/specs/implementation/01_Godotアーキテクチャ.md`
4. `docs/specs/implementation/05_実装ロードマップ.md`

---

## アーキテクチャ原則

- データは Resource
- 状態は Autoload（GameState）
- UIとロジックを分離する
- シーン遷移は SceneRouter 経由
- マジックナンバー禁止
- 巨大Singleton禁止

### Autoload 一覧

| 名前 | 役割 |
|---|---|
| GameState | gold / party_members / inventory / dungeon_progress / tutorial_flags |
| DataRegistry | WeaponData / EnemyData / DungeonData / SkillData / AffixData の参照管理 |
| SceneRouter | シーン遷移管理 |
| EventBus | シグナルバス |

### シーン遷移フロー

```
BootScene → BaseScene → DungeonScene → ResultScene → BaseScene
```

---

## ディレクトリ構成

```
res://
  scenes/
    boot/       BootScene.tscn
    base/       BaseScene.tscn
    dungeon/    DungeonScene.tscn, RoomNode.tscn, CharacterUnit.tscn, EnemyUnit.tscn
    result/     ResultScene.tscn
    ui/         HUD.tscn, PolicyButtons.tscn, InventoryPanel.tscn, EquipmentPanel.tscn, IdentifyPanel.tscn
  scripts/
    autoload/   GameState.gd, DataRegistry.gd, SceneRouter.gd, EventBus.gd
    core/       Constants.gd, Enums.gd, RandomUtil.gd
    data/       WeaponData.gd, EnemyData.gd, DungeonData.gd, SkillData.gd, AffixData.gd, JobData.gd
    domain/     Adventurer.gd, Stats.gd, ItemInstance.gd, WeaponInstance.gd, AffixInstance.gd
    dungeon/    DungeonController.gd, DungeonGenerator.gd, RoomController.gd, ExplorationController.gd
    combat/     CombatController.gd, UnitController.gd, SkillExecutor.gd, DamageCalculator.gd, TargetSelector.gd
    loot/       DropManager.gd, AffixRoller.gd, IdentifyService.gd
    ui/         BaseUIController.gd, HUDController.gd, InventoryUI.gd, EquipmentUI.gd, ResultUI.gd
    save/       SaveManager.gd
  resources/
    weapons/    enemies/    dungeons/    skills/    affixes/    jobs/
  assets/
    sprites/    ui/    audio/
  saves/
```

---

## コーディングルール

### 命名

| 種別 | 規則 | 例 |
|---|---|---|
| Script / Class | PascalCase | `GameState.gd`, `DungeonController.gd` |
| 変数 | snake_case | `current_hp`, `attack_power` |
| 定数 | UPPER_SNAKE_CASE | `MAX_PARTY_SIZE`, `DEFAULT_CRIT_RATE` |

### 禁止事項

- マジックナンバー（Constants.gd / Enums.gd を使う）
- Nodeパス直書き乱用
- UIから直接ゲームロジックを変更する
- 1ファイル1000行超え
- 仕様にない機能の追加

### 推奨

- enum 使用
- signal 使用
- Resource 使用
- Controller 分離
- 関数は短くする

---

## MVP確定仕様（重要）

### 装備枠（MVP）
武器 / 防具 / 装飾品（3枠）。王遺産はMVPに含まない。

### 戦闘
- 全自動戦闘
- 1人死亡しても探索継続。**3人全滅で探索失敗**
- 自動探索はリアルタイムではなく**部屋単位のステップ進行**

### セーブタイミング
帰還時 / 鑑定完了時 / 装備変更時

### ゴールド用途（MVP）
鑑定費用のみ

### 宝箱（MVP）
内容物：武器・防具・装飾品・ゴールド・素材
レアリティ：通常敵よりRare以上が出やすい

### イベント（MVP仮仕様）
崩れた祭壇 / 古文書 / 封印扉（詳細は後のTaskで追記）

### 中ボス（MVP）
HPとドロップが高いエリートとして扱う。固有行動なし。

### クリティカルビルド（MVP）
クリ率 / クリダメ / 攻撃速度 / クリティカル時バフのみ

### ArmorData / AccessoryData（MVP）
ArmorData：HP・防御中心の簡易構造
AccessoryData：Affix中心の簡易構造

---

## Task運用ルール

- **指定されたTask番号の範囲のみ実装する。範囲外のTaskには手を付けない**
- **仕様にない機能を勝手に追加しない**
- **1回の依頼は1〜5Taskまで**
- 変更ファイル数は1依頼で10以下
- 仕様が不足・不明な場合は推測せず質問する
- 既存仕様と矛盾する変更をしない
- MVPを優先し、正式版要素は実装しない

### Task完了後の報告フォーマット

```
■ 変更ファイル一覧
■ 実装内容
■ テスト方法
■ 懸念点
```

### 依頼テンプレート

```
Task番号：TaskXXX〜TaskYYY

実装してほしいこと：
-

実装しないこと：
-

完了条件：
-
```

---

## 現在の状態

Phase 0 Task001 実施済み（Godotプロジェクト空初期化・git init・仕様書配置）。

次は Task002（基本ディレクトリ作成）から開始する。
