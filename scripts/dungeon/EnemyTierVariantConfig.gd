class_name EnemyTierVariantConfig
extends RefCounted

## ハード／ナイトメア限定の同一 enemy_id に対する表示名・個性上書き（ベース数値は据置）。
## ノーマル(T0) では一切適用しない — 色替え敵は Hard/NM 限定。
## 数値強化は DungeonTierConfig の敵Lvボーナスに任せ、二重加算しない。
## Decision: P3-ENEMY-TIER-VAR-001 / 002 / 003 / 004 / 005 / 006

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
			"skill_use_chance": 0.5,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "停時モス",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.52,
			"element_resist": ["dark"],
		},
	},
	"serdion": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅骸セルディオン",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.6,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼骸セルディオン",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.65,
			"element_resist": ["dark"],
		},
	},
	## ── ウィスパーウッド（P3-ENEMY-TIER-VAR-003）──
	"moss_boar": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血苔ボア",
			"critical_rate": 0.08,
			"on_hit_status_id": "poison",
			"on_hit_status_chance": 0.18,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月苔ボア",
			"critical_rate": 0.08,
			"on_hit_status_id": "chill",
			"on_hit_status_chance": 0.18,
			"element_resist": ["dark"],
		},
	},
	"moss_shell": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "緋殻シェル",
			"on_hit_status_id": "poison",
			"on_hit_status_chance": 0.16,
			"element_resist": ["dark"],
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼殻シェル",
			"on_hit_status_id": "chill",
			"on_hit_status_chance": 0.16,
			"element_resist": ["ice", "dark"],
		},
	},
	"iron_horn": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "錆刃甲虫",
			"critical_rate": 0.10,
			"skill_use_chance": 0.28,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "霜刃甲虫",
			"critical_rate": 0.12,
			"attack_element": "ice",
			"on_hit_status_id": "chill",
			"on_hit_status_chance": 0.22,
		},
	},
	"spore_widow": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "朱胞ウィドウ",
			"on_hit_status_chance": 0.28,
			"critical_rate": 0.10,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月胞ウィドウ",
			"on_hit_status_id": "poison",
			"on_hit_status_chance": 0.30,
			"attack_element": "dark",
			"element_resist": ["dark"],
		},
	},
	"blood_bloom": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅咲ブルーム",
			"on_hit_status_chance": 0.32,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "幽咲ブルーム",
			"on_hit_status_id": "bleed",
			"on_hit_status_chance": 0.28,
			"attack_element": "dark",
			"element_resist": ["dark"],
		},
	},
	"rune_carcinos": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "朱紋カルキノス",
			"skill_use_chance": 0.30,
			"element_resist": ["dark"],
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼紋カルキノス",
			"skill_use_chance": 0.34,
			"attack_element": "ice",
			"element_resist": ["dark", "ice"],
		},
	},
	"mist_wyvern": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血霧ワイバーン",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.5,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月霧ワイバーン",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.52,
			"element_resist": ["ice", "dark"],
		},
	},
	"mirror_boa": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血鏡ボア",
			"on_hit_status_chance": 0.28,
			"critical_rate": 0.14,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "幽鏡ボア",
			"on_hit_status_id": "poison",
			"on_hit_status_chance": 0.30,
			"attack_element": "dark",
			"critical_rate": 0.14,
		},
	},
	"granvel": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅樹グランヴェル",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.6,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼樹グランヴェル",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.65,
			"element_resist": ["dark", "ice"],
		},
	},
	## ── ミストフェン（P3-ENEMY-TIER-VAR-004）──
	"blood_leech": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血蛭ヒル",
			"on_hit_status_chance": 0.32,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月蛭ヒル",
			"on_hit_status_id": "bleed",
			"on_hit_status_chance": 0.30,
			"attack_element": "dark",
			"element_resist": ["dark"],
		},
	},
	"dead_poison_frog": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅毒の大蛙",
			"on_hit_status_chance": 0.32,
			"skill_use_chance": 0.32,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼毒の大蛙",
			"on_hit_status_id": "poison",
			"on_hit_status_chance": 0.32,
			"skill_use_chance": 0.34,
			"attack_element": "ice",
			"element_resist": ["ice"],
		},
	},
	"mist_mantis": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血霧マンティス",
			"on_hit_status_chance": 0.28,
			"critical_rate": 0.10,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月霧マンティス",
			"on_hit_status_id": "poison",
			"on_hit_status_chance": 0.28,
			"attack_element": "dark",
			"critical_rate": 0.10,
		},
	},
	"marsh_king": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血沼の王",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.30,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月沼の王",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.34,
			"element_resist": ["dark", "ice"],
		},
	},
	"bone_picker": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血骨拾い",
			"on_hit_status_chance": 0.28,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "幽骨拾い",
			"on_hit_status_id": "bleed",
			"on_hit_status_chance": 0.28,
			"attack_element": "dark",
			"element_resist": ["dark"],
		},
	},
	"mire_strider_spider": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血脚スパイダー",
			"on_hit_status_chance": 0.28,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月脚スパイダー",
			"on_hit_status_id": "poison",
			"on_hit_status_chance": 0.30,
			"attack_element": "dark",
		},
	},
	"spore_needle_wasp": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "朱針ワスプ",
			"on_hit_status_chance": 0.36,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼針ワスプ",
			"attack_element": "ice",
			"on_hit_status_id": "chill",
			"on_hit_status_chance": 0.30,
		},
	},
	"great_claw": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血爪刀",
			"on_hit_status_chance": 0.32,
			"skill_use_chance": 0.5,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月爪刀",
			"on_hit_status_chance": 0.30,
			"skill_use_chance": 0.52,
			"attack_element": "dark",
			"element_resist": ["dark", "ice"],
		},
	},
	"nightfen": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血夜沼",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.5,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月夜沼",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.52,
			"element_resist": ["dark", "ice"],
		},
	},
	"moldgar": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅泥モルドガル",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.6,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼泥モルドガル",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.65,
			"element_resist": ["dark", "ice"],
		},
	},
	## ── ブラックショア（P3-ENEMY-TIER-VAR-005）──
	"ship_eater_crab": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血殻船喰らい",
			"on_hit_status_id": "bleed",
			"on_hit_status_chance": 0.18,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼殻船喰らい",
			"on_hit_status_id": "chill",
			"on_hit_status_chance": 0.18,
			"element_resist": ["ice"],
		},
	},
	"skull_turtle": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血骸タートル",
			"on_hit_status_id": "bleed",
			"on_hit_status_chance": 0.16,
			"element_resist": ["dark"],
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月骸タートル",
			"on_hit_status_id": "chill",
			"on_hit_status_chance": 0.16,
			"element_resist": ["ice", "dark"],
		},
	},
	"undertaker_shark": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血葬テイカー",
			"on_hit_status_chance": 0.32,
			"skill_use_chance": 0.28,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月葬テイカー",
			"on_hit_status_chance": 0.30,
			"skill_use_chance": 0.30,
			"attack_element": "dark",
			"element_resist": ["dark"],
		},
	},
	"samurai_fish": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血冠シャーク",
			"on_hit_status_chance": 0.32,
			"skill_use_chance": 0.30,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月冠シャーク",
			"on_hit_status_chance": 0.30,
			"skill_use_chance": 0.32,
			"attack_element": "ice",
			"on_hit_status_id": "chill",
		},
	},
	"black_tide_shark": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血潮ジョー",
			"on_hit_status_chance": 0.32,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月潮ジョー",
			"on_hit_status_id": "bleed",
			"on_hit_status_chance": 0.30,
			"attack_element": "dark",
		},
	},
	"abyssal_squid": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血虚テンタクル",
			"on_hit_status_chance": 0.32,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月虚テンタクル",
			"on_hit_status_chance": 0.30,
			"attack_element": "dark",
			"element_resist": ["dark"],
		},
	},
	"tide_lamp": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血潮灯",
			"on_hit_status_chance": 0.36,
			"attack_element": "fire",
			"on_hit_status_id": "ignite",
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月潮灯",
			"on_hit_status_chance": 0.34,
			"attack_element": "ice",
			"on_hit_status_id": "chill",
			"element_resist": ["ice"],
		},
	},
	"ninja_octopus": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血海司祭",
			"on_hit_status_chance": 0.36,
			"skill_use_chance": 0.5,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月海司祭",
			"on_hit_status_chance": 0.34,
			"skill_use_chance": 0.52,
			"attack_element": "dark",
			"element_resist": ["dark", "ice"],
		},
	},
	"anchor_lord": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "錆錨ロード",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.5,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "霜錨ロード",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.52,
			"attack_element": "ice",
			"on_hit_status_id": "chill",
			"element_resist": ["ice"],
		},
	},
	"nereion": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅潮ネレイオン",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.6,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼潮ネレイオン",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.65,
			"element_resist": ["fire", "ice"],
		},
	},
	"nereion_depths": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅脈ネレイオン",
			"on_hit_status_chance": 0.32,
			"skill_use_chance": 0.6,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼脈ネレイオン",
			"on_hit_status_chance": 0.32,
			"skill_use_chance": 0.65,
			"element_resist": ["fire", "ice", "dark"],
		},
	},
	## ── フロストリッジ（P3-ENEMY-TIER-VAR-006）──
	"frost_claw_raptor": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血爪ラプター",
			"on_hit_status_chance": 0.30,
			"critical_rate": 0.12,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月爪ラプター",
			"on_hit_status_chance": 0.28,
			"attack_element": "ice",
			"on_hit_status_id": "chill",
			"element_resist": ["ice"],
		},
	},
	"vergaron": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血狼ヴェルガロン",
			"on_hit_status_chance": 0.30,
			"skill_use_chance": 0.22,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月狼ヴェルガロン",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.26,
			"element_resist": ["ice"],
		},
	},
	"storm_joe": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血嵐ジョー",
			"on_hit_status_chance": 0.26,
			"skill_use_chance": 0.28,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月嵐ジョー",
			"on_hit_status_chance": 0.26,
			"skill_use_chance": 0.30,
			"element_resist": ["ice"],
		},
	},
	"oldrex": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血甲オルドレクス",
			"on_hit_status_chance": 0.26,
			"skill_use_chance": 0.26,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼甲オルドレクス",
			"on_hit_status_chance": 0.26,
			"skill_use_chance": 0.28,
			"attack_element": "ice",
			"on_hit_status_id": "chill",
			"element_resist": ["ice"],
		},
	},
	"greios": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血翼グレイオス",
			"on_hit_status_chance": 0.34,
			"skill_use_chance": 0.5,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月翼グレイオス",
			"on_hit_status_chance": 0.34,
			"skill_use_chance": 0.52,
			"element_resist": ["ice"],
		},
	},
	"glacier_warden": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血晶マンモス",
			"on_hit_status_chance": 0.30,
			"skill_use_chance": 0.22,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月晶マンモス",
			"on_hit_status_chance": 0.28,
			"skill_use_chance": 0.26,
			"element_resist": ["ice"],
		},
	},
	"wind_ripper": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "血雪ストーム",
			"on_hit_status_chance": 0.30,
			"skill_use_chance": 0.24,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "月雪ストーム",
			"on_hit_status_chance": 0.30,
			"skill_use_chance": 0.28,
			"element_resist": ["ice"],
		},
	},
	"eldion": {
		_DungeonTierConfig.TIER_HARD: {
			"display_name": "紅始祖エルディオン",
			"on_hit_status_chance": 0.30,
			"skill_use_chance": 0.6,
		},
		_DungeonTierConfig.TIER_NIGHTMARE: {
			"display_name": "蒼始祖エルディオン",
			"on_hit_status_chance": 0.30,
			"skill_use_chance": 0.65,
			"element_resist": ["ice", "dark"],
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
