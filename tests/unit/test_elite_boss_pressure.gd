extends GutTest
## P3-BAL-ELITE-BOSS-PRESSURE-001 — エリート護衛＋ボス個別デバフ／F1状態。


const _BOSS_HEX := {
	"serdion": {"skill": "boss_serdion_hex", "status": "fear"},
	"granvel": {"skill": "boss_granvel_hex", "status": "slow"},
	"moldgar": {"skill": "boss_moldgar_hex", "status": "slow"},
	"nereion": {"skill": "boss_nereion_hex", "status": "mark"},
	"eldion": {"skill": "boss_eldion_hex", "status": "vulnerable"},
	"chronos_wave": {"skill": "boss_chronos_wave_hex", "status": "slow"},
	"valgard": {"skill": "boss_valgard_hex", "status": "vulnerable"},
	"skarpedion": {"skill": "boss_skarpedion_hex", "status": "armor_break"},
	"mycolga_ancient": {"skill": "boss_mycolga_hex", "status": "fear"},
	"karna_smoke": {"skill": "boss_karna_hex", "status": "mark"},
	"nereion_depths": {"skill": "boss_nereion_depths_hex", "status": "slow"},
	"forgedormient": {"skill": "boss_forgedormient_hex", "status": "vulnerable"},
	"albark": {"skill": "boss_albark_hex", "status": "fear"},
}

const _BOSS_F1_STATUS := {
	"enemy_serdion_roar": "fear",
	"enemy_granvel_verdant_wave": "poison",
	"enemy_moldgar_abyss_surge": "poison",
	"enemy_nereion_tidal_wail": "chill",
	"enemy_eldion_glacial_breath": "chill",
	"enemy_chronos_wave_resonance": "shock",
	"enemy_valgard_rampart": "armor_break",
	"enemy_skarpedion_iron_molt": "bleed",
	"enemy_mycolga_spore_field": "poison",
	"enemy_karna_ash_veil": "ignite",
	"enemy_nereion_depths_tide_pull": "chill",
	"enemy_forgedormient_slag_breath": "ignite",
	"enemy_albark_white_silence": "chill",
}


func test_no_shared_boss_party_curse() -> void:
	assert_false(ResourceLoader.exists("res://resources/skills/boss_party_curse.tres"))
	for boss_id: String in _BOSS_HEX.keys():
		var enemy: Resource = DataRegistry.get_enemy_data(boss_id)
		assert_false("boss_party_curse" in enemy.skill_ids, boss_id)


func test_each_boss_has_unique_hex() -> void:
	var seen_skills: Dictionary = {}
	for boss_id: String in _BOSS_HEX.keys():
		var spec: Dictionary = _BOSS_HEX[boss_id]
		var skill_id: String = str(spec["skill"])
		var status_id: String = str(spec["status"])
		var enemy: Resource = DataRegistry.get_enemy_data(boss_id)
		assert_not_null(enemy, boss_id)
		assert_true(skill_id in enemy.skill_ids, boss_id)
		assert_false("boss_party_curse" in enemy.skill_ids, boss_id)
		var skill: Resource = DataRegistry.get_skill_data(skill_id)
		assert_not_null(skill, skill_id)
		assert_eq(str(skill.target_type), "all_party", skill_id)
		assert_eq(str(skill.apply_status_id), status_id, skill_id)
		assert_almost_eq(float(skill.apply_status_chance), 1.0, 0.001)
		assert_lte(float(skill.cast_time), 0.0, skill_id)
		assert_false(seen_skills.has(skill_id), skill_id)
		seen_skills[skill_id] = true


func test_boss_phase1_hex_between_enrage_and_pressure() -> void:
	for boss_id: String in _BOSS_HEX.keys():
		var hex_id: String = str(_BOSS_HEX[boss_id]["skill"])
		var def: Dictionary = CombatBossPhases.phase_def(boss_id, 0)
		var weights: Dictionary = def.get("skill_weight", {})
		assert_gt(
			float(weights.get(hex_id, 0.0)),
			float(weights.get("boss_enrage", 0.0)),
			boss_id
		)


func test_boss_f1_has_chapter_status() -> void:
	for skill_id: String in _BOSS_F1_STATUS.keys():
		var skill: Resource = DataRegistry.get_skill_data(skill_id)
		assert_not_null(skill, skill_id)
		assert_eq(str(skill.apply_status_id), _BOSS_F1_STATUS[skill_id], skill_id)
		assert_gte(float(skill.apply_status_chance), 0.35, skill_id)


func test_elite_escorts_one_to_two() -> void:
	assert_eq(BalanceConfig.ELITE_ESCORT_MIN, 1)
	assert_eq(BalanceConfig.ELITE_ESCORT_MAX, 2)
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mistfen")
	dc.current_room_type = Enums.RoomType.ELITE
	var saw_escorts := false
	for _i in 24:
		var group: Array = dc.pick_combat_enemy_group()
		assert_gte(group.size(), 1)
		assert_lte(group.size(), 3)
		if group.size() >= 2:
			saw_escorts = true
			var lead: Resource = group[0]
			assert_eq(int(lead.enemy_type), 1)
			for j in range(1, group.size()):
				var m: Resource = group[j]
				assert_true(bool(m.can_swarm), str(m.id))
				assert_false(bool(m.escorts_minions), str(m.id))
	assert_true(saw_escorts, "expected at least one elite with escorts")


func test_boss_group_remains_solo() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	dc.current_room_type = Enums.RoomType.BOSS
	for _i in 8:
		var group: Array = dc.pick_combat_enemy_group()
		assert_eq(group.size(), 1)


func test_polar_tricera_has_front_aoe() -> void:
	var enemy: Resource = DataRegistry.get_enemy_data("polar_tricera")
	assert_not_null(enemy)
	assert_true("enemy_tricera_trampling" in enemy.skill_ids)
	var skill: Resource = DataRegistry.get_skill_data("enemy_tricera_trampling")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "party_front")
