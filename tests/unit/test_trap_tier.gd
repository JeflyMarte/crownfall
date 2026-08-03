extends GutTest

## P3-BAL-TRAP-TIER-001 — 罠の N/H/NM 段階化。

const _TrapPresentation = preload("res://scripts/dungeon/TrapPresentation.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")


func test_trap_damage_fractions_by_tier() -> void:
	assert_almost_eq(BalanceConfig.trap_max_hp_frac_combat_single(0), 0.10, 0.0001)
	assert_almost_eq(BalanceConfig.trap_max_hp_frac_combat_single(1), 0.15, 0.0001)
	assert_almost_eq(BalanceConfig.trap_max_hp_frac_combat_single(2), 0.22, 0.0001)
	assert_almost_eq(BalanceConfig.trap_max_hp_frac_room_single(0), 0.15, 0.0001)
	assert_almost_eq(BalanceConfig.trap_max_hp_frac_room_single(1), 0.25, 0.0001)
	assert_almost_eq(BalanceConfig.trap_max_hp_frac_room_single(2), 0.35, 0.0001)
	assert_almost_eq(BalanceConfig.trap_max_hp_frac_combat_aoe(0), 0.05, 0.0001)
	assert_almost_eq(BalanceConfig.trap_max_hp_frac_room_aoe(2), 0.18, 0.0001)


func test_trap_chance_tables_by_tier() -> void:
	assert_almost_eq(BalanceConfig.trap_explore_chance(0), 0.08, 0.0001)
	assert_almost_eq(BalanceConfig.trap_explore_chance(1), 0.20, 0.0001)
	assert_almost_eq(BalanceConfig.trap_explore_chance(2), 0.28, 0.0001)
	assert_almost_eq(BalanceConfig.trap_aoe_chance(0), 0.25, 0.0001)
	assert_almost_eq(BalanceConfig.trap_aoe_chance(1), 0.35, 0.0001)
	assert_almost_eq(BalanceConfig.trap_aoe_chance(2), 0.45, 0.0001)
	assert_almost_eq(BalanceConfig.trap_room_trigger_chance(0), 0.35, 0.0001)
	assert_almost_eq(BalanceConfig.trap_room_trigger_chance(1), 0.65, 0.0001)
	assert_almost_eq(BalanceConfig.trap_room_trigger_chance(2), 0.80, 0.0001)
	assert_almost_eq(_TrapPresentation.trigger_chance(1), 0.65, 0.0001)


func test_trap_status_chance_by_tier() -> void:
	assert_almost_eq(BalanceConfig.trap_status_chance(0), 0.0, 0.0001)
	assert_almost_eq(BalanceConfig.trap_status_chance(1), 0.40, 0.0001)
	assert_almost_eq(BalanceConfig.trap_status_chance(2), 0.60, 0.0001)
	assert_eq(ExplorationSkills.roll_trap_status(0), "")


func test_trap_damage_numbers_normal_vs_hard() -> void:
	## ノーマル既定
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(800, false, false, 0), 80)
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(800, true, false, 0), 120)
	## ハード ≈ 旧 NONCOMBAT
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(800, false, false, 1), 120)
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(800, true, false, 1), 200)
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(1000, true, true, 1), 120)
	## ナイトメア
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(1000, true, false, 2), 350)


func test_hard_aliases_match_hard_tier() -> void:
	assert_almost_eq(
		BalanceConfig.TRAP_MAX_HP_FRAC_ROOM_SINGLE,
		BalanceConfig.trap_max_hp_frac_room_single(_DungeonTierConfig.TIER_HARD),
		0.0001
	)
	assert_almost_eq(
		BalanceConfig.TRAP_AOE_CHANCE,
		BalanceConfig.trap_aoe_chance(_DungeonTierConfig.TIER_HARD),
		0.0001
	)
	assert_almost_eq(
		_TrapPresentation.TRIGGER_CHANCE,
		BalanceConfig.trap_room_trigger_chance(_DungeonTierConfig.TIER_HARD),
		0.0001
	)


func test_roll_trap_status_hard_can_return_pool() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen_status: bool = false
	for _i: int in 80:
		var sid: String = ExplorationSkills.roll_trap_status(1, rng)
		if sid.is_empty():
			continue
		assert_true(sid == "poison" or sid == "bleed")
		seen_status = true
		break
	assert_true(seen_status)
