class_name WanderingEnemyConfig
extends RefCounted

## 遍在希少種（放浪個体）の出現・報酬 SSOT（P3-WANDER-001 / P3-D166）。

const ID_WAYFARER_SPARROW: String = "wayfarer_sparrow"
const ID_RELIQUARY_BEETLE: String = "reliquary_beetle"

## COMBAT 部屋で放浪個体が差し込まれる合計確率（2.5% + 1.5%）。
const SPAWN_CHANCE_WAYFARER: float = 0.025
const SPAWN_CHANCE_RELIQUARY: float = 0.015

## 聖遺甲虫の武器レア度重み（★2〜3 寄り）。
const RELIQUARY_WEAPON_WEIGHTS: Dictionary = {
	Enums.Rarity.COMMON: 10,
	Enums.Rarity.RARE: 20,
	Enums.Rarity.EPIC: 45,
	Enums.Rarity.LEGENDARY: 25,
}

static func try_roll_wandering_id(rng: RandomNumberGenerator = null) -> String:
	return wandering_id_for_roll(_randf(rng))

static func wandering_id_for_roll(roll: float) -> String:
	if roll < SPAWN_CHANCE_WAYFARER:
		return ID_WAYFARER_SPARROW
	if roll < SPAWN_CHANCE_WAYFARER + SPAWN_CHANCE_RELIQUARY:
		return ID_RELIQUARY_BEETLE
	return ""

static func weapon_rarity_weights_for(enemy_data: Resource) -> Dictionary:
	if enemy_data == null or enemy_data.weapon_rarity_weights.is_empty():
		return {}
	return enemy_data.weapon_rarity_weights

static func _randf(rng: RandomNumberGenerator) -> float:
	if rng != null:
		return rng.randf()
	return randf()
