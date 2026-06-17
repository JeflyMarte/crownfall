# 01_Godotアーキテクチャ

## エンジン

- Godot 4.x
- 2D
- GDScript
- Resource中心設計

## 基本方針

- データはResource
- 状態はGameState Autoload
- UIとロジックを分離
- シーン遷移はSceneManager経由
- マジックナンバー禁止
- 巨大Manager乱立禁止

## Autoload

### GameState

保持するもの

- gold
- party_members
- inventory
- current_dungeon_id
- dungeon_progress
- tutorial_flags

### DataRegistry

Resourceデータの参照管理。

- WeaponData
- EnemyData
- DungeonData
- SkillData
- AffixData

### SceneRouter

シーン遷移管理。

## 主要シーン

```text
BootScene
↓
BaseScene
↓
DungeonScene
↓
ResultScene
↓
BaseScene
```

## レイヤー構成

- Core
- Data
- Domain
- Dungeon
- Combat
- UI
- Save
