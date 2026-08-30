extends GutTest

## P3-BAL-BOSS-PRESSURE-A-001 — 全ボス通常2種＋即時全体を案A同型。


const _BOSS_IDS: Array[String] = [
	"serdion",
	"granvel",
	"moldgar",
	"nereion",
	"eldion",
	"chronos_wave",
	"valgard",
	"skarpedion",
	"mycolga_ancient",
	"karna_smoke",
	"nereion_depths",
	"forgedormient",
	"albark",
]

const _INSTANT_AOE := {
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

const _HEAVY_SKILLS := {
	"serdion": "boss_decree_wave",
	"granvel": "enemy_granvel_bramble_crush",
	"moldgar": "enemy_moldgar_mire_maw",
	"nereion": "enemy_nereion_breach",
	"eldion": "enemy_eldion_crevasse",
	"chronos_wave": "enemy_chronos_wave_gear_crush",
	"valgard": "enemy_valgard_boundary_spear",
	"skarpedion": "enemy_skarpedion_carapace_ram",
	"mycolga_ancient": "enemy_mycolga_root_bind",
	"karna_smoke": "enemy_karna_magma_lance",
	"nereion_depths": "enemy_nereion_depths_abyss_roar",
	"forgedormient": "enemy_forgedormient_furnace_quake",
	"albark": "enemy_albark_mapless_charge",
}


func test_all_bosses_have_dual_basic_attacks() -> void:
	for boss_id: String in _BOSS_IDS:
		var boss: Resource = DataRegistry.get_enemy_data(boss_id)
		assert_not_null(boss, boss_id)
		var ids: Array = boss.basic_attack_skill_ids
		assert_eq(ids.size(), 2, boss_id)
		var saw_single := false
		var saw_cleave := false
		for sid: Variant in ids:
			assert_false(str(sid) in boss.skill_ids, "%s basic in skill_ids" % boss_id)
			var skill: Resource = DataRegistry.get_skill_data(str(sid))
			assert_not_null(skill, str(sid))
			assert_true(skill.tags.has("basic"), str(sid))
			assert_lte(float(skill.cast_time), 0.0, str(sid))
			assert_eq(str(skill.effect_type), "damage", str(sid))
			if str(skill.target_type) == "party":
				saw_single = true
				## エルディオンはソロ圧力で単体×2.2（他ボスは案Aの×1.7）。
				var expect_single: float = 2.2 if boss_id == "eldion" else 1.7
				assert_almost_eq(float(skill.power_multiplier), expect_single, 0.001, str(sid))
			elif str(skill.target_type) == "all_party":
				saw_cleave = true
				var expect_cleave: float = 1.4 if boss_id == "eldion" else 1.0
				assert_almost_eq(float(skill.power_multiplier), expect_cleave, 0.001, str(sid))
		assert_true(saw_single, boss_id)
		assert_true(saw_cleave, boss_id)


## P3-BAL-GRANVEL-B-LATER-001: グランヴェル以降メイン梯子の即時全体 ×0.6。
const _LATER_MAIN_INSTANT_AOE_06 := [
	"granvel", "moldgar", "nereion", "eldion", "chronos_wave",
]


func test_instant_pressure_aoe_power() -> void:
	for boss_id: String in _INSTANT_AOE.keys():
		var sid: String = _INSTANT_AOE[boss_id]
		var skill: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(skill, sid)
		assert_eq(str(skill.target_type), "all_party", sid)
		var expect_power := 0.6 if boss_id in _LATER_MAIN_INSTANT_AOE_06 else 0.75
		## エルディオン吐息はソロ圧力で ×1.15。
		if boss_id == "eldion":
			expect_power = 1.15
		## P3-DG-APEX-BOSS-001: アルバーク白静寂＝時環共鳴同型 ×0.60（F1重みはヴァル同型据置）。
		if boss_id == "albark":
			expect_power = 0.6
		assert_almost_eq(float(skill.power_multiplier), expect_power, 0.001, sid)
		assert_lte(float(skill.cast_time), 0.0, sid)


func test_heavy_skills_are_two() -> void:
	for boss_id: String in _HEAVY_SKILLS.keys():
		var sid: String = _HEAVY_SKILLS[boss_id]
		var skill: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(skill, sid)
		var expect_heavy: float = 2.5 if boss_id == "eldion" else 2.0
		assert_almost_eq(float(skill.power_multiplier), expect_heavy, 0.001, sid)


const _HEX := {
	"serdion": "boss_serdion_hex",
	"granvel": "boss_granvel_hex",
	"moldgar": "boss_moldgar_hex",
	"nereion": "boss_nereion_hex",
	"eldion": "boss_eldion_hex",
	"chronos_wave": "boss_chronos_wave_hex",
	"valgard": "boss_valgard_hex",
	"skarpedion": "boss_skarpedion_hex",
	"mycolga_ancient": "boss_mycolga_hex",
	"karna_smoke": "boss_karna_hex",
	"nereion_depths": "boss_nereion_depths_hex",
	"forgedormient": "boss_forgedormient_hex",
	"albark": "boss_albark_hex",
}


func test_hex_remains_quarter() -> void:
	for boss_id: String in _HEX.keys():
		var hex_id: String = _HEX[boss_id]
		var skill: Resource = DataRegistry.get_skill_data(hex_id)
		assert_not_null(skill, hex_id)
		assert_almost_eq(float(skill.power_multiplier), 0.25, 0.001, hex_id)


func test_boss_atk_scaled_with_serdion_ratio() -> void:
	## セルディオン以外は旧ATK×(145/120)。グランヴェル以降メイン梯子は P3-BAL-GRANVEL-B-LATER-001（×175/203）。
	var expect := {
		"serdion": 145,
		"granvel": 175,
		"moldgar": 175,
		"nereion": 191,
		"eldion": 300,
		"chronos_wave": 250,
		"valgard": 254,
		"skarpedion": 184,
		"mycolga_ancient": 193,
		"karna_smoke": 203,
		"nereion_depths": 242,
		"forgedormient": 251,
		"albark": 248,
	}
	for boss_id: String in expect.keys():
		var boss: Resource = DataRegistry.get_enemy_data(boss_id)
		assert_not_null(boss, boss_id)
		assert_eq(int(boss.attack), int(expect[boss_id]), boss_id)


func test_later_main_boss_f1_instant_weight() -> void:
	## P3-BAL-GRANVEL-B-LATER-001: F1 即時全体重み 1.6（エルディオンは開幕補強で 1.8）。
	for boss_id: String in _LATER_MAIN_INSTANT_AOE_06:
		var def: Dictionary = CombatBossPhases.phase_def(boss_id, 0)
		var weights: Dictionary = def.get("skill_weight", {})
		var sid: String = _INSTANT_AOE[boss_id]
		var expect_w: float = 1.8 if boss_id == "eldion" else 1.6
		assert_almost_eq(float(weights.get(sid, 0.0)), expect_w, 0.001, boss_id)
