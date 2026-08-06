class_name BossSummonLayout
extends RefCounted

## ボス専用スプライト据置のまま、呼び出し敵を左右＋手前へ置く（P3-UX-BOSS-SUMMON-LAYOUT-001）。
## add_index = 召喚連れの 0 始まり（swarm slot - 1）。

const X_MIN_RATIO: float = 0.42
const X_MAX_RATIO: float = 0.92
const Y_MIN_RATIO: float = 0.28
const Y_MAX_RATIO: float = 0.72
## ボス z_index（DungeonScene の BossSprite）より手前へ。
const BOSS_Z: int = 12
const ADD_Z_ABOVE_BOSS: int = 3


static func position_ratio(boss_ratio: Vector2, add_index: int) -> Vector2:
	var side: float = -1.0 if (add_index % 2) == 0 else 1.0
	var ring: int = int(add_index / 2)
	var x_off: float = side * (0.17 + float(ring) * 0.09)
	var y_off: float = 0.12 + float(ring) * 0.035
	return Vector2(
		clampf(boss_ratio.x + x_off, X_MIN_RATIO, X_MAX_RATIO),
		clampf(boss_ratio.y + y_off, Y_MIN_RATIO, Y_MAX_RATIO)
	)


static func add_z_index(add_index: int) -> int:
	var ring: int = int(add_index / 2)
	return BOSS_Z + ADD_Z_ABOVE_BOSS + ring


static func is_boss_lead_enemy(data: Resource) -> bool:
	if data == null:
		return false
	return int(data.enemy_type) == Enums.EnemyType.BOSS
