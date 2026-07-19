class_name WanderingEnemyConfig
extends RefCounted

## 遍在希少種（放浪個体）の出現・報酬 SSOT（P3-WANDER-001 / P3-WANDER-002）。

const ID_COSMIC_DUCK: String = "cosmic_duck"
const ID_CROWN_RAVEN: String = "crown_raven"

## 旧ID（セーブ／図鑑エイリアス）
const ID_WAYFARER_SPARROW: String = "wayfarer_sparrow"
const ID_RELIQUARY_BEETLE: String = "reliquary_beetle"

const ENEMY_ID_ALIASES: Dictionary = {
	ID_WAYFARER_SPARROW: ID_COSMIC_DUCK,
	ID_RELIQUARY_BEETLE: ID_CROWN_RAVEN,
}

## COMBAT 部屋で放浪個体が差し込まれる合計確率（2.5% + 1.5%）。
const SPAWN_CHANCE_COSMIC_DUCK: float = 0.025
const SPAWN_CHANCE_CROWN_RAVEN: float = 0.015

## 互換エイリアス（旧定数名）
const SPAWN_CHANCE_WAYFARER: float = SPAWN_CHANCE_COSMIC_DUCK
const SPAWN_CHANCE_RELIQUARY: float = SPAWN_CHANCE_CROWN_RAVEN

## 宝冠レイヴンの装備レア度重み（★2〜3 寄り。伝説も有意な枠）。
const CROWN_RAVEN_RARITY_WEIGHTS: Dictionary = {
	Enums.Rarity.COMMON: 10,
	Enums.Rarity.RARE: 20,
	Enums.Rarity.EPIC: 40,
	Enums.Rarity.LEGENDARY: 30,
}

## 宝冠レイヴンの装備種別重み。
const CROWN_RAVEN_CATEGORY_WEIGHTS: Dictionary = {
	"weapon": 40,
	"armor": 35,
	"accessory": 25,
}

## 撃破装備ドロップ成功時に神話を抽選する確率（ボス再クリアと同程度）。
const CROWN_RAVEN_MYTHIC_CHANCE: float = 0.01


static func is_crown_raven(enemy_data: Resource) -> bool:
	if enemy_data == null:
		return false
	return str(enemy_data.id) == ID_CROWN_RAVEN


static func canonical_enemy_id(enemy_id: String) -> String:
	if enemy_id.is_empty():
		return ""
	return str(ENEMY_ID_ALIASES.get(enemy_id, enemy_id))


static func try_roll_wandering_id(rng: RandomNumberGenerator = null) -> String:
	return wandering_id_for_roll(_randf(rng))


static func wandering_id_for_roll(roll: float) -> String:
	if roll < SPAWN_CHANCE_COSMIC_DUCK:
		return ID_COSMIC_DUCK
	if roll < SPAWN_CHANCE_COSMIC_DUCK + SPAWN_CHANCE_CROWN_RAVEN:
		return ID_CROWN_RAVEN
	return ""


static func weapon_rarity_weights_for(enemy_data: Resource) -> Dictionary:
	if enemy_data == null or enemy_data.weapon_rarity_weights.is_empty():
		return {}
	return enemy_data.weapon_rarity_weights


static func _randf(rng: RandomNumberGenerator) -> float:
	if rng != null:
		return rng.randf()
	return randf()
