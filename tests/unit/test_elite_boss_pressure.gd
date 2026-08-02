extends GutTest
## P3-BAL-ELITE-BOSS-PRESSURE-001 — エリート護衛＋ボス全体呪い／F1状態。


const _BOSS_IDS := [
	"serdion", "granvel", "moldgar", "nereion", "eldion", "chronos_wave",
	"valgard", "skarpedion", "mycolga_ancient", "karna_smoke", "nereion_depths",
	"forgedormient", "albark",
]

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


func test_boss_party_curse_skill() -> void:
	var skill: Resource = DataRegistry.get_skill_data("boss_party_curse")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_party")
	assert_eq(str(skill.apply_status_id), "curse")
	assert_almost_eq(float(skill.apply_status_chance), 1.0, 0.001)
	assert_lte(float(skill.cast_time), 0.0)
	assert_lte(float(skill.cooldown), 8.0)


func test_all_bosses_have_party_curse() -> void:
	for boss_id: String in _BOSS_IDS:
		var enemy: Resource = DataRegistry.get_enemy_data(boss_id)
		assert_not_null(enemy, boss_id)
		assert_true("boss_party_curse" in enemy.skill_ids, boss_id)


func test_boss_phase1_curse_between_enrage_and_pressure() -> void:
	for boss_id: String in _BOSS_IDS:
		var def: Dictionary = CombatBossPhases.phase_def(boss_id, 0)
		var weights: Dictionary = def.get("skill_weight", {})
		assert_gt(
			float(weights.get("boss_party_curse", 0.0)),
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
