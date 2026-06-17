# 03_Resource設計

## WeaponData

```gdscript
class_name WeaponData
extends Resource

@export var id: String
@export var display_name: String
@export var weapon_type: String
@export var rarity: String
@export var base_attack_min: int
@export var base_attack_max: int
@export var attack_speed: float
@export var fixed_skill_id: String
@export var possible_affixes: Array[String]
@export var mark: String
@export_multiline var flavor_text: String
```

## WeaponInstance

```gdscript
class_name WeaponInstance
extends Resource

@export var instance_id: String
@export var data_id: String
@export var attack: int
@export var affixes: Array[AffixInstance]
@export var is_identified: bool
@export var level: int
```

## AffixData

```gdscript
class_name AffixData
extends Resource

@export var id: String
@export var display_name: String
@export var category: String
@export var stat_type: String
@export var min_value: float
@export var max_value: float
@export var value_type: String
@export var allowed_item_types: Array[String]
@export var allowed_rarities: Array[String]
@export var weight: int
```

## DungeonData

```gdscript
class_name DungeonData
extends Resource

@export var id: String
@export var display_name: String
@export var difficulty: int
@export var room_count: int
@export var base_duration_seconds: int
@export var enemy_pool: Array[String]
@export var boss_id: String
@export var drop_table_id: String
@export var discovery_unlocks: Dictionary
```

## SkillData

```gdscript
class_name SkillData
extends Resource

@export var id: String
@export var display_name: String
@export var cooldown: float
@export var trigger_type: String
@export var target_type: String
@export var power_multiplier: float
@export var effect_type: String
```
