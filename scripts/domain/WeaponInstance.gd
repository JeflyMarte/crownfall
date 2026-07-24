class_name WeaponInstance
extends Resource

@export var instance_id: String = ""
@export var weapon_id: String = ""
@export var is_appraised: bool = false
@export var rolled_attack: int = 0
## 個体属性（空=無属性）。未設定レガシーはマスタへフォールバック（WeaponStatResolver）。
@export var element: String = ""
## 属性値。無属性時は 0。未設定=-1 でマスタ参照。
@export var element_power: int = -1
## 生態特効（空=なし）。
@export var bane_class: String = ""
@export var bane_multiplier: float = 0.0
@export var attack_speed: float = 0.0
@export var critical_rate: float = 0.0
## 会心ダメ倍率。0=デフォルト(1.5)。
@export var critical_damage: float = 0.0
## 通常攻撃時の状態付与（poison/chill/shock/ignite/curse。stun 不可）。
@export var on_hit_status_id: String = ""
@export var on_hit_status_chance: float = 0.0
@export var knockback: float = 0.0
@export var stagger_power: float = 0.0
## 射程: CombatRange がカテゴリ解決に使用（P3-D106f）。UI 非表示。
@export var attack_range: float = 1.0
@export var weight: float = 1.0
@export var prefix_ids: Array[String] = []
@export var suffix_ids: Array[String] = []
## P3-EQ-DIABLO-001: 統合ランダムステ（Dictionary 配列）。
@export var random_mods: Array = []
## 炉研ぎ段階（0〜5）。実効 ATK = レベル補正後 + enhance×EQUIP_FORGE_FLAT（P3-D152 / P3-EQ-LVL-001）。
@export var enhance_level: int = 0
## 装備レベル（1〜99）。ドロップ時 Biome 連動・戦闘で成長（P3-EQ-LVL-001）。
@export var equip_level: int = 1
@export var equip_exp: int = 0
## ドロップ時に付与したランダムステータス id 一覧。
@export var rolled_bonus_stats: Array[String] = []
## ランダムステータスで最高値を引いた数（表示名⭐️用）。
@export var perfect_roll_count: int = 0
