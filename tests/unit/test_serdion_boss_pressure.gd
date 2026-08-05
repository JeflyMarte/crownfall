extends GutTest
## P3-BAL-BOSS-PRESSURE-001 — ボス／エリート F1/F2 横展開。


const _BOSS_INSTANT_AOE := {
	"serdion": "enemy_serdion_roar",
	"granvel": "enemy_granvel_verdant_wave",
	"moldgar": "enemy_moldgar_abyss_surge",
	"nereion": "enemy_nereion_tidal_wail",
	"eldion": "enemy_eldion_glacial_breath",
	"chronos_wave": "enemy_chronos_wave_resonance",
	"valgard": "enemy_valgard_rampart",
	"skarpedion": "enemy_skarpedion_iron_molt",
	"mycolga_ancient": "enemy_mycolga_spore_field",
	"karna_smoke": "enemy_karna_ash_veil",
	"nereion_depths": "enemy_nereion_depths_tide_pull",
	"forgedormient": "enemy_forgedormient_slag_breath",
	"albark": "enemy_albark_white_silence",
}

const _BOSS_CAST_SPECTACLE := {
	"serdion": "boss_decree_wave",
	"forgedormient": "enemy_forgedormient_furnace_quake",
	"nereion_depths": "enemy_nereion_depths_abyss_roar",
}


func test_all_boss_pressure_aoe_instant() -> void:
	for boss_id: String in _BOSS_INSTANT_AOE.keys():
		var skill_id: String = _BOSS_INSTANT_AOE[boss_id]
		var skill: Resource = DataRegistry.get_skill_data(skill_id)
		assert_not_null(skill, skill_id)
		assert_eq(str(skill.target_type), "all_party", skill_id)
		assert_lte(float(skill.cast_time), 0.0, skill_id)
		assert_lte(float(skill.cooldown), 6.0, skill_id)


func test_dual_aoe_bosses_keep_heavy_cast() -> void:
	for boss_id: String in _BOSS_CAST_SPECTACLE.keys():
		var skill_id: String = _BOSS_CAST_SPECTACLE[boss_id]
		var skill: Resource = DataRegistry.get_skill_data(skill_id)
		assert_not_null(skill, skill_id)
		assert_eq(str(skill.target_type), "all_party", skill_id)
		assert_gte(float(skill.cast_time), 1.0, skill_id)


func test_serdion_decree_wave_power_2() -> void:
	var skill: Resource = DataRegistry.get_skill_data("boss_decree_wave")
	assert_not_null(skill)
	assert_almost_eq(float(skill.power_multiplier), 2.0, 0.001)
	assert_eq(str(skill.target_type), "all_party")
	assert_gte(float(skill.cast_time), 1.0)


func test_serdion_plan_a_pressure_numbers() -> void:
	## P3-BAL-SERDION-A-001: ATK145／爪×1.7／咆哮×0.75。
	var boss: Resource = DataRegistry.get_enemy_data("serdion")
	assert_not_null(boss)
	assert_eq(int(boss.attack), 145)
	var roar: Resource = DataRegistry.get_skill_data("enemy_serdion_roar")
	assert_not_null(roar)
	assert_almost_eq(float(roar.power_multiplier), 0.75, 0.001)
	assert_lte(float(roar.cast_time), 0.0)


func test_serdion_basic_attack_variants() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("serdion")
	assert_not_null(boss)
	var ids: Array = boss.basic_attack_skill_ids
	assert_eq(ids.size(), 2)
	assert_true("enemy_serdion_claw" in ids)
	assert_true("enemy_serdion_cleave" in ids)
	## 通常攻撃バリエーションは skill_ids（スキル枠）に混ぜない。
	for sid: Variant in ids:
		assert_false(str(sid) in boss.skill_ids, str(sid))
	var claw: Resource = DataRegistry.get_skill_data("enemy_serdion_claw")
	assert_not_null(claw)
	assert_eq(str(claw.target_type), "party")
	assert_almost_eq(float(claw.power_multiplier), 1.7, 0.001)
	assert_lte(float(claw.cast_time), 0.0)
	assert_eq(str(claw.apply_status_id), "bleed")
	var cleave: Resource = DataRegistry.get_skill_data("enemy_serdion_cleave")
	assert_not_null(cleave)
	assert_eq(str(cleave.target_type), "all_party")
	assert_almost_eq(float(cleave.power_multiplier), 1.0, 0.001)
	assert_lte(float(cleave.cast_time), 0.0)


func test_all_bosses_base_skill_use_raised() -> void:
	for boss_id: String in _BOSS_INSTANT_AOE.keys():
		var enemy: Resource = DataRegistry.get_enemy_data(boss_id)
		assert_not_null(enemy, boss_id)
		assert_gte(float(enemy.skill_use_chance), 0.55, boss_id)


func test_all_boss_phase1_weights_favor_pressure_over_enrage() -> void:
	for boss_id: String in _BOSS_INSTANT_AOE.keys():
		var def: Dictionary = CombatBossPhases.phase_def(boss_id, 0)
		assert_gte(float(def.get("skill_use_chance", 0.0)), 0.55, boss_id)
		var weights: Dictionary = def.get("skill_weight", {})
		assert_false(weights.is_empty(), boss_id)
		var instant_id: String = _BOSS_INSTANT_AOE[boss_id]
		assert_gt(
			float(weights.get(instant_id, 0.0)),
			float(weights.get("boss_enrage", 0.0)),
			boss_id
		)


func test_elites_skill_use_raised() -> void:
	var elite_ids: Array[String] = [
		"clock_moth", "mist_wyvern", "great_claw", "greios", "anchor_lord",
		"ninja_octopus", "nightfen", "mirror_boa", "polar_tricera",
	]
	for eid: String in elite_ids:
		var enemy: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(enemy, eid)
		assert_gte(float(enemy.skill_use_chance), 0.45, eid)


func test_clock_moth_chrono_resonance_instant() -> void:
	var skill: Resource = DataRegistry.get_skill_data("enemy_chrono_resonance")
	assert_not_null(skill)
	assert_lte(float(skill.cast_time), 0.0)
