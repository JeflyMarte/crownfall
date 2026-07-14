class_name EnemyTierVariantConfig
extends RefCounted

## ハード／ナイトメア限定の同一 enemy_id に対する表示名・個性上書き（ベース数値は据置）。
## ノーマル(T0) では一切適用しない — 色替え敵は Hard/NM 限定。
## 数値強化は DungeonTierConfig の敵Lvボーナスに任せ、二重加算しない。
## Decision: P3-ENEMY-TIER-VAR-001 / 002

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")

## enemy_id → tier(1=Hard, 2=Nightmare) → 上書きフィールド
## ※ TIER_NORMAL キーは持たない（ノーマルでは色替え・別名を出さない）
const VARIANTS: Dictionary = {
	"grave_bell_bat": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血鐘バット",
			"skill_use_chance": 0.32,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月鐘バット",
			"skill_use_chance": 0.36,
			"element_resist": ["dark"],
		},
	},
	"crystal_scorpion": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紫晶スコーピオン",
			"on_hit_status_chance": 0.28,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "熔晶スコーピオン",
			"attack_element": "fire",
			"element_weakness": ["water"],
			"on_hit_status_id": "ignite",
			"on_hit_status_chance": 0.28,
		},
	},
	"skullface_mantis": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血面マンティス",
			"on_hit_status_chance": 0.32,
			"critical_rate": 0.14,
			"skill_use_chance": 0.34,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "屍面マンティス",
			"attack_element": "dark",
			"on_hit_status_id": "poison",
			"on_hit_status_chance": 0.32,
			"skill_use_chance": 0.38,
		},
	},
	"sepia_hound": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "錆影ハウンド",
			"skill_use_chance": 0.28,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "幽嗅ハウンド",
			"skill_use_chance": 0.32,
			"element_resist": ["dark"],
		},
	},
	"rune_roach": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "朱紋ローチ",
			"skill_use_chance": 0.26,
			"element_resist": ["dark"],
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼紋ローチ",
			"attack_element": "ice",
			"skill_use_chance": 0.30,
			"element_resist": ["dark"],
		},
	},
	"crown_eater_rat": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "貪冠ネズミ",
			"skill_use_chance": 0.30,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "奪冠ネズミ",
			"attack_element": "dark",
			"skill_use_chance": 0.34,
		},
	},
	"crystal_hedgehog": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅晶ハリネズミ",
			"on_hit_status_chance": 0.32,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "黒晶ハリネズミ",
			"on_hit_status_id": "chill",
			"on_hit_status_chance": 0.32,
		},
	},
	"clock_moth": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血刻モス",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.40,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "停時モス",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.42,
			"element_resist": ["dark"],
		},
	},
	"serdion": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅骸セルディオン",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.46,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼骸セルディオン",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.50,
			"element_resist": ["dark"],
		},
	},
}


static func apply_for_current_tier(enemy: Resource) -> Resource:
	if enemy == null:
		return null
	return apply(enemy, GameState.current_dungeon_tier)


static func apply(enemy: Resource, tier: int) -> Resource:
	if enemy == null:
		return null
	var t: int = _DungeonTierConfig.clamp_tier(tier)
	## ノーマル: 色替え・別名・個性差分を一切かけない
	if t <= _DungeonTierConfig.TIER_NORMAL:
		return enemy
	var enemy_id: String = str(enemy.id)
	var by_enemy: Variant = VARIANTS.get(enemy_id, null)
	if by_enemy == null or not (by_enemy is Dictionary):
		return enemy
	var overrides: Variant = (by_enemy as Dictionary).get(t, null)
	if overrides == null or not (overrides is Dictionary) or (overrides as Dictionary).is_empty():
		return enemy
	var clone: Resource = enemy.duplicate(true)
	for key: Variant in (overrides as Dictionary).keys():
		var field: String = str(key)
		var value: Variant = (overrides as Dictionary)[key]
		if field == "element_weakness" or field == "element_resist":
			var arr: Array[String] = []
			for item: Variant in value as Array:
				arr.append(str(item))
			clone.set(field, arr)
		else:
			clone.set(field, value)
	return clone


static func display_name_for(enemy_id: String, tier: int, fallback: String = "") -> String:
	var t: int = _DungeonTierConfig.clamp_tier(tier)
	if t <= _DungeonTierConfig.TIER_NORMAL:
		return fallback
	var by_enemy: Variant = VARIANTS.get(enemy_id, null)
	if by_enemy is Dictionary:
		var overrides: Variant = (by_enemy as Dictionary).get(t, null)
		if overrides is Dictionary and (overrides as Dictionary).has("display_name"):
			return str((overrides as Dictionary)["display_name"])
	return fallback
