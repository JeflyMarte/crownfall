extends GutTest
## 敵トリッキー横展開案A（章ごと+2〜3）。


func test_sepia_hound_lifesteal() -> void:
	var data: Resource = DataRegistry.get_enemy_data("sepia_hound")
	assert_almost_eq(float(data.lifesteal_ratio), 0.3, 0.001)


func test_moss_boar_summon() -> void:
	var data: Resource = DataRegistry.get_enemy_data("moss_boar")
	assert_true(data.skill_ids.has("enemy_boar_call"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_boar_call")
	assert_eq(str(skill.effect_type), "summon")
	assert_true(skill.tags.has("once_per_combat"))
	assert_gte(float(skill.cooldown), 9999.0)


func test_iron_horn_haste() -> void:
	var data: Resource = DataRegistry.get_enemy_data("iron_horn")
	assert_true(data.skill_ids.has("enemy_iron_haste"))
	assert_eq(str(DataRegistry.get_skill_data("enemy_iron_haste").effect_type), "haste")


func test_rune_carcinos_basic_resist() -> void:
	var data: Resource = DataRegistry.get_enemy_data("rune_carcinos")
	assert_almost_eq(float(data.incoming_basic_mult), 0.2, 0.001)
	## 自己 carapace は据置（T3 ローチと役割分離）。
	assert_true(data.skill_ids.has("enemy_rune_carapace"))


func test_dead_poison_frog_t1() -> void:
	var skill: Resource = DataRegistry.get_skill_data("enemy_mire_miasma")
	assert_eq(str(skill.target_type), "all_party")
	assert_lt(float(skill.power_multiplier), 0.25)
	assert_gte(float(skill.apply_status_chance), 0.5)
	var data: Resource = DataRegistry.get_enemy_data("dead_poison_frog")
	assert_true(data.skill_ids.has("enemy_mire_miasma"))


func test_spore_needle_wasp_explode() -> void:
	var data: Resource = DataRegistry.get_enemy_data("spore_needle_wasp")
	assert_true(data.skill_ids.has("enemy_spore_burst"))
	assert_eq(str(DataRegistry.get_skill_data("enemy_spore_burst").effect_type), "explode")


func test_bone_picker_flee() -> void:
	var data: Resource = DataRegistry.get_enemy_data("bone_picker")
	assert_true(data.skill_ids.has("enemy_bone_flee"))
	assert_eq(str(DataRegistry.get_skill_data("enemy_bone_flee").effect_type), "flee")


func test_ship_eater_ally_buff() -> void:
	var data: Resource = DataRegistry.get_enemy_data("ship_eater_crab")
	assert_true(data.skill_ids.has("enemy_hull_ward"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_hull_ward")
	assert_eq(str(skill.effect_type), "buff")
	assert_eq(str(skill.apply_status_id), "enrage")


func test_ninja_octopus_skill_resist() -> void:
	var data: Resource = DataRegistry.get_enemy_data("ninja_octopus")
	assert_almost_eq(float(data.incoming_skill_mult), 0.2, 0.001)


func test_storm_joe_silence() -> void:
	var data: Resource = DataRegistry.get_enemy_data("storm_joe")
	assert_true(data.skill_ids.has("enemy_gale_silence"))
	assert_eq(str(DataRegistry.get_skill_data("enemy_gale_silence").effect_type), "silence")


func test_oldrex_heal() -> void:
	var data: Resource = DataRegistry.get_enemy_data("oldrex")
	assert_true(data.skill_ids.has("enemy_ancient_mend"))
	assert_eq(str(DataRegistry.get_skill_data("enemy_ancient_mend").effect_type), "heal")


func test_frost_claw_haste() -> void:
	var data: Resource = DataRegistry.get_enemy_data("frost_claw_raptor")
	assert_true(data.skill_ids.has("enemy_frost_haste"))
	assert_eq(str(DataRegistry.get_skill_data("enemy_frost_haste").effect_type), "haste")
