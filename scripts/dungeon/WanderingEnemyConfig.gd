class_name WanderingEnemyConfig
extends RefCounted

## 遍在希少種（放浪個体）の出現・報酬 SSOT
## （P3-WANDER-001 / P3-WANDER-002 / P3-WANDER-003 / P3-WANDER-004）。

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")

const ID_COSMIC_DUCK: String = "cosmic_duck"
const ID_CROWN_RAVEN: String = "crown_raven"
const ID_GOLDEN_SCARAB: String = "golden_scarab"
const ID_SHADOW_STALKER: String = "shadow_stalker"

## 旧ID（セーブ／図鑑エイリアス）
const ID_WAYFARER_SPARROW: String = "wayfarer_sparrow"
const ID_RELIQUARY_BEETLE: String = "reliquary_beetle"

const ENEMY_ID_ALIASES: Dictionary = {
	ID_WAYFARER_SPARROW: ID_COSMIC_DUCK,
	ID_RELIQUARY_BEETLE: ID_CROWN_RAVEN,
}

## COMBAT 部屋の基準出現率（ノーマル帯）。Hard/NM は rarity_weight_mult と同型で上昇。
## 案A（P3-WANDER-004）: 既存据置＋新2種追加。合計 ≈ 6.3%。
const SPAWN_CHANCE_COSMIC_DUCK: float = 0.025
const SPAWN_CHANCE_CROWN_RAVEN: float = 0.015
const SPAWN_CHANCE_GOLDEN_SCARAB: float = 0.015
const SPAWN_CHANCE_SHADOW_STALKER: float = 0.008

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

## 影狩りの装備レア度重み（★寄り強化・B+D）。
const SHADOW_STALKER_RARITY_WEIGHTS: Dictionary = {
	Enums.Rarity.COMMON: 0,
	Enums.Rarity.RARE: 10,
	Enums.Rarity.EPIC: 35,
	Enums.Rarity.LEGENDARY: 55,
}

## 影狩りの装備種別重み（レイヴンと同型）。
const SHADOW_STALKER_CATEGORY_WEIGHTS: Dictionary = {
	"weapon": 40,
	"armor": 35,
	"accessory": 25,
}

## 撃破装備ドロップ成功時に神話を抽選する確率（別枠）。
const CROWN_RAVEN_MYTHIC_CHANCE: float = 0.01
const SHADOW_STALKER_MYTHIC_CHANCE: float = 0.035


static func is_crown_raven(enemy_data: Resource) -> bool:
	if enemy_data == null:
		return false
	return str(enemy_data.id) == ID_CROWN_RAVEN


static func is_shadow_stalker(enemy_data: Resource) -> bool:
	if enemy_data == null:
		return false
	return str(enemy_data.id) == ID_SHADOW_STALKER


static func is_golden_scarab(enemy_data: Resource) -> bool:
	if enemy_data == null:
		return false
	return str(enemy_data.id) == ID_GOLDEN_SCARAB


## 伝説プール補完＋神話別枠の対象（レイヴン／影狩り）。
static func grants_legendary_equip_pool(enemy_data: Resource) -> bool:
	return is_crown_raven(enemy_data) or is_shadow_stalker(enemy_data)


static func mythic_chance_for(enemy_data: Resource) -> float:
	if is_shadow_stalker(enemy_data):
		return SHADOW_STALKER_MYTHIC_CHANCE
	if is_crown_raven(enemy_data):
		return CROWN_RAVEN_MYTHIC_CHANCE
	return 0.0


static func canonical_enemy_id(enemy_id: String) -> String:
	if enemy_id.is_empty():
		return ""
	return str(ENEMY_ID_ALIASES.get(enemy_id, enemy_id))


static func spawn_mult_for_tier(tier: int) -> float:
	return _DungeonTierConfig.rarity_weight_mult(tier)


static func spawn_chance_cosmic_duck(tier: int = _DungeonTierConfig.TIER_NORMAL) -> float:
	var base: float = SPAWN_CHANCE_COSMIC_DUCK * spawn_mult_for_tier(tier)
	return minf(0.45, base * EventSystem.get_wander_spawn_mult(ID_COSMIC_DUCK))


static func spawn_chance_crown_raven(tier: int = _DungeonTierConfig.TIER_NORMAL) -> float:
	var base: float = SPAWN_CHANCE_CROWN_RAVEN * spawn_mult_for_tier(tier)
	return minf(0.45, base * EventSystem.get_wander_spawn_mult(ID_CROWN_RAVEN))


static func spawn_chance_golden_scarab(tier: int = _DungeonTierConfig.TIER_NORMAL) -> float:
	var base: float = SPAWN_CHANCE_GOLDEN_SCARAB * spawn_mult_for_tier(tier)
	return minf(0.45, base * EventSystem.get_wander_spawn_mult(ID_GOLDEN_SCARAB))


static func spawn_chance_shadow_stalker(tier: int = _DungeonTierConfig.TIER_NORMAL) -> float:
	var base: float = SPAWN_CHANCE_SHADOW_STALKER * spawn_mult_for_tier(tier)
	return minf(0.45, base * EventSystem.get_wander_spawn_mult(ID_SHADOW_STALKER))


## モーンゲート 1-1〜1-3 では影狩り放浪を出さない（序盤保護）。
static func is_shadow_stalker_allowed_on_stage(biome_index: int, chapter_index: int) -> bool:
	if biome_index == 1 and chapter_index >= 1 and chapter_index <= 3:
		return false
	return true


static func try_roll_wandering_id(
	rng: RandomNumberGenerator = null,
	tier: int = _DungeonTierConfig.TIER_NORMAL,
	allow_shadow_stalker: bool = true
) -> String:
	return wandering_id_for_roll(_randf(rng), tier, allow_shadow_stalker)


static func wandering_id_for_roll(
	roll: float,
	tier: int = _DungeonTierConfig.TIER_NORMAL,
	allow_shadow_stalker: bool = true
) -> String:
	var duck_chance: float = spawn_chance_cosmic_duck(tier)
	var raven_chance: float = spawn_chance_crown_raven(tier)
	var scarab_chance: float = spawn_chance_golden_scarab(tier)
	var stalker_chance: float = (
		spawn_chance_shadow_stalker(tier) if allow_shadow_stalker else 0.0
	)
	var cursor: float = 0.0
	if roll < cursor + duck_chance:
		return ID_COSMIC_DUCK
	cursor += duck_chance
	if roll < cursor + raven_chance:
		return ID_CROWN_RAVEN
	cursor += raven_chance
	if roll < cursor + scarab_chance:
		return ID_GOLDEN_SCARAB
	cursor += scarab_chance
	if roll < cursor + stalker_chance:
		return ID_SHADOW_STALKER
	return ""


static func weapon_rarity_weights_for(enemy_data: Resource) -> Dictionary:
	if enemy_data == null or enemy_data.weapon_rarity_weights.is_empty():
		return {}
	return enemy_data.weapon_rarity_weights


static func _randf(rng: RandomNumberGenerator) -> float:
	if rng != null:
		return rng.randf()
	return randf()
