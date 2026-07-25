extends GutTest

## P3-ENEMY-TIER-VAR — Hard/NM 限定の表示名・個性（ノーマルでは未適用）。

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _EnemyTierVariantConfig = preload("res://scripts/dungeon/EnemyTierVariantConfig.gd")

const _ALL_VARIANT_IDS: Array[String] = [
	"grave_bell_bat",
	"crystal_scorpion",
	"skullface_mantis",
	"sepia_hound",
	"rune_roach",
	"crown_eater_rat",
	"crystal_hedgehog",
	"clock_moth",
	"serdion",
	"moss_boar",
	"moss_shell",
	"iron_horn",
	"spore_widow",
	"blood_bloom",
	"rune_carcinos",
	"mist_wyvern",
	"mirror_boa",
	"granvel",
	"blood_leech",
	"dead_poison_frog",
	"mist_mantis",
	"marsh_king",
	"bone_picker",
	"mire_strider_spider",
	"spore_needle_wasp",
	"great_claw",
	"nightfen",
	"moldgar",
	"ship_eater_crab",
	"skull_turtle",
	"undertaker_shark",
	"samurai_fish",
	"black_tide_shark",
	"abyssal_squid",
	"tide_lamp",
	"ninja_octopus",
	"anchor_lord",
	"nereion",
	"nereion_depths",
]


func before_each() -> void:
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL


func test_normal_never_applies_variant_names() -> void:
	for enemy_id: String in _ALL_VARIANT_IDS:
		var base: Resource = DataRegistry.get_enemy_data(enemy_id)
		assert_not_null(base, enemy_id)
		var applied: Resource = _EnemyTierVariantConfig.apply(base, _DungeonTierConfig.TIER_NORMAL)
		assert_eq(applied, base, enemy_id)
		assert_eq(str(applied.display_name), str(base.display_name), enemy_id)
		var renamed: String = _EnemyTierVariantConfig.display_name_for(
			enemy_id, _DungeonTierConfig.TIER_NORMAL, str(base.display_name)
		)
		assert_eq(renamed, str(base.display_name), enemy_id)


func test_hard_and_nightmare_names_are_distinct_and_exclusive() -> void:
	var expected_hard: Dictionary = {
		"grave_bell_bat": "血鐘バット",
		"crystal_scorpion": "紫晶スコーピオン",
		"skullface_mantis": "血面マンティス",
		"sepia_hound": "錆影ハウンド",
		"rune_roach": "朱紋ローチ",
		"crown_eater_rat": "貪冠ネズミ",
		"crystal_hedgehog": "紅晶ハリネズミ",
		"clock_moth": "血刻モス",
		"serdion": "紅骸セルディオン",
		"moss_boar": "血苔ボア",
		"moss_shell": "緋殻シェル",
		"iron_horn": "錆刃甲虫",
		"spore_widow": "朱胞ウィドウ",
		"blood_bloom": "紅咲ブルーム",
		"rune_carcinos": "朱紋カルキノス",
		"mist_wyvern": "血霧ワイバーン",
		"mirror_boa": "血鏡ボア",
		"granvel": "紅樹グランヴェル",
		"blood_leech": "血蛭ヒル",
		"dead_poison_frog": "紅毒の大蛙",
		"mist_mantis": "血霧マンティス",
		"marsh_king": "血沼の王",
		"bone_picker": "血骨拾い",
		"mire_strider_spider": "血脚スパイダー",
		"spore_needle_wasp": "朱針ワスプ",
		"great_claw": "血爪刀",
		"nightfen": "血夜沼",
		"moldgar": "紅泥モルドガル",
		"ship_eater_crab": "血殻船喰らい",
		"skull_turtle": "血骸タートル",
		"undertaker_shark": "血葬テイカー",
		"samurai_fish": "血冠シャーク",
		"black_tide_shark": "血潮ジョー",
		"abyssal_squid": "血虚テンタクル",
		"tide_lamp": "血潮灯",
		"ninja_octopus": "血海司祭",
		"anchor_lord": "錆錨ロード",
		"nereion": "紅潮ネレイオン",
		"nereion_depths": "紅脈ネレイオン",
	}
	var expected_nm: Dictionary = {
		"grave_bell_bat": "月鐘バット",
		"crystal_scorpion": "熔晶スコーピオン",
		"skullface_mantis": "屍面マンティス",
		"sepia_hound": "幽嗅ハウンド",
		"rune_roach": "蒼紋ローチ",
		"crown_eater_rat": "奪冠ネズミ",
		"crystal_hedgehog": "黒晶ハリネズミ",
		"clock_moth": "停時モス",
		"serdion": "蒼骸セルディオン",
		"moss_boar": "月苔ボア",
		"moss_shell": "蒼殻シェル",
		"iron_horn": "霜刃甲虫",
		"spore_widow": "月胞ウィドウ",
		"blood_bloom": "幽咲ブルーム",
		"rune_carcinos": "蒼紋カルキノス",
		"mist_wyvern": "月霧ワイバーン",
		"mirror_boa": "幽鏡ボア",
		"granvel": "蒼樹グランヴェル",
		"blood_leech": "月蛭ヒル",
		"dead_poison_frog": "蒼毒の大蛙",
		"mist_mantis": "月霧マンティス",
		"marsh_king": "月沼の王",
		"bone_picker": "幽骨拾い",
		"mire_strider_spider": "月脚スパイダー",
		"spore_needle_wasp": "蒼針ワスプ",
		"great_claw": "月爪刀",
		"nightfen": "月夜沼",
		"moldgar": "蒼泥モルドガル",
		"ship_eater_crab": "蒼殻船喰らい",
		"skull_turtle": "月骸タートル",
		"undertaker_shark": "月葬テイカー",
		"samurai_fish": "月冠シャーク",
		"black_tide_shark": "月潮ジョー",
		"abyssal_squid": "月虚テンタクル",
		"tide_lamp": "月潮灯",
		"ninja_octopus": "月海司祭",
		"anchor_lord": "霜錨ロード",
		"nereion": "蒼潮ネレイオン",
		"nereion_depths": "蒼脈ネレイオン",
	}
	for enemy_id: String in _ALL_VARIANT_IDS:
		var base: Resource = DataRegistry.get_enemy_data(enemy_id)
		var hard: Resource = _EnemyTierVariantConfig.apply(base, _DungeonTierConfig.TIER_HARD)
		var nm: Resource = _EnemyTierVariantConfig.apply(base, _DungeonTierConfig.TIER_NIGHTMARE)
		assert_eq(str(hard.display_name), str(expected_hard[enemy_id]), enemy_id)
		assert_eq(str(nm.display_name), str(expected_nm[enemy_id]), enemy_id)
		assert_ne(str(hard.display_name), str(nm.display_name), enemy_id)
		assert_ne(str(hard.display_name), str(base.display_name), enemy_id)
		## ベース数ステは据置
		assert_eq(int(hard.max_hp), int(base.max_hp), enemy_id)
		assert_eq(int(nm.attack), int(base.attack), enemy_id)


func test_nightmare_key_identity_samples() -> void:
	var scorp: Resource = _EnemyTierVariantConfig.apply(
		DataRegistry.get_enemy_data("crystal_scorpion"), _DungeonTierConfig.TIER_NIGHTMARE
	)
	assert_eq(str(scorp.attack_element), "fire")
	assert_eq(str(scorp.on_hit_status_id), "ignite")
	assert_true(scorp.element_weakness.has("water"))

	var hedgehog: Resource = _EnemyTierVariantConfig.apply(
		DataRegistry.get_enemy_data("crystal_hedgehog"), _DungeonTierConfig.TIER_NIGHTMARE
	)
	assert_eq(str(hedgehog.on_hit_status_id), "chill")
	assert_eq(str(hedgehog.attack_element), "ice")

	var roach: Resource = _EnemyTierVariantConfig.apply(
		DataRegistry.get_enemy_data("rune_roach"), _DungeonTierConfig.TIER_NIGHTMARE
	)
	assert_eq(str(roach.display_name), "蒼紋ローチ")
	assert_eq(str(roach.attack_element), "ice")

	var carcinos: Resource = _EnemyTierVariantConfig.apply(
		DataRegistry.get_enemy_data("rune_carcinos"), _DungeonTierConfig.TIER_NIGHTMARE
	)
	assert_eq(str(carcinos.display_name), "蒼紋カルキノス")
	assert_eq(str(carcinos.attack_element), "ice")

	var granvel: Resource = _EnemyTierVariantConfig.apply(
		DataRegistry.get_enemy_data("granvel"), _DungeonTierConfig.TIER_HARD
	)
	assert_eq(str(granvel.display_name), "紅樹グランヴェル")
	assert_eq(int(granvel.max_hp), int(DataRegistry.get_enemy_data("granvel").max_hp))

	var wasp: Resource = _EnemyTierVariantConfig.apply(
		DataRegistry.get_enemy_data("spore_needle_wasp"), _DungeonTierConfig.TIER_NIGHTMARE
	)
	assert_eq(str(wasp.display_name), "蒼針ワスプ")
	assert_eq(str(wasp.attack_element), "ice")
	assert_eq(str(wasp.on_hit_status_id), "chill")

	var moldgar: Resource = _EnemyTierVariantConfig.apply(
		DataRegistry.get_enemy_data("moldgar"), _DungeonTierConfig.TIER_NIGHTMARE
	)
	assert_eq(str(moldgar.display_name), "蒼泥モルドガル")
	assert_eq(int(moldgar.max_hp), int(DataRegistry.get_enemy_data("moldgar").max_hp))

	var lamp: Resource = _EnemyTierVariantConfig.apply(
		DataRegistry.get_enemy_data("tide_lamp"), _DungeonTierConfig.TIER_HARD
	)
	assert_eq(str(lamp.display_name), "血潮灯")
	assert_eq(str(lamp.attack_element), "fire")
	assert_eq(str(lamp.on_hit_status_id), "ignite")

	var nereion: Resource = _EnemyTierVariantConfig.apply(
		DataRegistry.get_enemy_data("nereion"), _DungeonTierConfig.TIER_NIGHTMARE
	)
	assert_eq(str(nereion.display_name), "蒼潮ネレイオン")
	assert_eq(int(nereion.max_hp), int(DataRegistry.get_enemy_data("nereion").max_hp))


func test_duplicate_does_not_mutate_registry() -> void:
	var registry: Resource = DataRegistry.get_enemy_data("sepia_hound")
	var _v: Resource = _EnemyTierVariantConfig.apply(registry, _DungeonTierConfig.TIER_HARD)
	assert_eq(str(registry.display_name), "セピアハウンド")
