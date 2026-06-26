# 01_Godotアーキテクチャ

## エンジン

- Godot 4.6.3
- 2D
- GDScript
- Resource中心設計

## 基本方針

- データはResource
- 状態はGameState Autoload
- UIとロジックを分離
- シーン遷移はSceneRouter経由
- マジックナンバー禁止
- 巨大Manager乱立禁止

## Autoload

### GameState

保持するもの

- gold
- party_members
- inventory / armor_inventory / accessory_inventory
- equipped_weapon / equipped_armor / equipped_accessory
- current_dungeon_id（P2-Task021 — 探索対象 DG。未設定時 DEFAULT_DUNGEON_ID）
- dungeon_progress
- discovery_registry（P2-Task018）
- tutorial_flags

### DataRegistry

Resource データの参照管理（Autoload 登録済み、**P2-Task020 SSOT 確定**）。

| メソッド | 対象 |
|---|---|
| get_weapon_data | WeaponData |
| get_armor_data | ArmorData |
| get_accessory_data | AccessoryData |
| get_enemy_data | EnemyData |
| get_skill_data | SkillData |
| get_dungeon_data | DungeonData |
| get_material_data | MaterialData |
| get_job_data | JobData（P2-Task027） |
| get_affix_data | AffixData（P2-Task028） |

規約・登録済 id・inline load() 併存方針: `03_Resource設計.md` DataRegistry 節。

### SceneRouter

シーン遷移管理。

### EventBus

シグナルバス。

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
AppraisalScene
↓
EquipmentScene
↓
BaseScene
```

## レイヤー構成（現行実装）

- Core（Constants, Enums）
- Data（WeaponData, ArmorData, AccessoryData, EnemyData, DungeonData, SkillData）
- Domain（Adventurer, Stats, *Instance）
- appraisal / base / boot / combat（CombatController, **SkillExecutor**）/ discovery / dungeon / equipment / result / save

未実装ディレクトリ: loot/, ui/（.gitkeep のみ）。詳細は `CODEMAP.md`。
