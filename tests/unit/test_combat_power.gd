extends GutTest

## P3-UI-COMBAT-POWER-001: HP+DEF+ATK×速度×(1+会心×(会心ダメ−1))


func test_combat_power_from_stats_includes_speed_and_crit() -> void:
	var base: Dictionary = {
		"hp": 800,
		"attack": 120,
		"defense": 90,
		"speed": 1.2,
		"crit_rate": 0.2,
		"crit_damage": 1.5,
	}
	## 800 + 90 + 120*1.2*(1+0.2*0.5) = 890 + 158.4 → 1048
	assert_eq(RosterUiHelper.combat_power_from_stats(base), 1048)


func test_combat_power_higher_than_flat_hp_atk_def_when_speed_crit() -> void:
	var stats: Dictionary = {
		"hp": 100,
		"attack": 100,
		"defense": 100,
		"speed": 2.0,
		"crit_rate": 0.5,
		"crit_damage": 2.0,
	}
	var flat: int = 100 + 100 + 100
	var power: int = RosterUiHelper.combat_power_from_stats(stats)
	## 100+100+100*2*(1+0.5*1) = 200 + 300 = 500
	assert_eq(power, 500)
	assert_gt(power, flat)


func test_combat_power_clamps_crit_rate_and_floors_crit_damage() -> void:
	var stats: Dictionary = {
		"hp": 0,
		"attack": 100,
		"defense": 0,
		"speed": 1.0,
		"crit_rate": 2.0,
		"crit_damage": 0.5,
	}
	## crit_rate→1.0, crit_damage→1.0 → offense = 100*1*(1+1*0) = 100
	assert_eq(RosterUiHelper.combat_power_from_stats(stats), 100)


func test_party_combat_power_sums_members() -> void:
	GameState.seed_all_starters_unlocked()
	var members: Array = []
	for m in GameState.party_members:
		if m != null:
			members.append(m)
	if members.is_empty():
		pending("no party members after seed")
		return
	var expected: int = 0
	for m in members:
		expected += RosterUiHelper.compute_member_combat_power(m)
	assert_eq(RosterUiHelper.compute_combat_power(members), expected)


func test_format_combat_power_commas() -> void:
	assert_eq(RosterUiHelper.format_combat_power(12), "12")
	assert_eq(RosterUiHelper.format_combat_power(1234), "1,234")
	assert_eq(RosterUiHelper.format_combat_power(1234567), "1,234,567")
