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


func test_duplicate_does_not_mutate_registry() -> void:
	var registry: Resource = DataRegistry.get_enemy_data("sepia_hound")
	var _v: Resource = _EnemyTierVariantConfig.apply(registry, _DungeonTierConfig.TIER_HARD)
	assert_eq(str(registry.display_name), "セピアハウンド")
