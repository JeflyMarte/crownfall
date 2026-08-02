extends GutTest

## P3-BAL-NONCOMBAT-001 — 非戦闘緊張感の定数。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _TrapPresentation = preload("res://scripts/dungeon/TrapPresentation.gd")


func test_trap_damage_fractions_raised() -> void:
	## ハード帯エイリアス＝旧 NONCOMBAT 据置（P3-BAL-TRAP-TIER-001）。
	assert_almost_eq(BalanceConfig.TRAP_MAX_HP_FRAC_COMBAT_SINGLE, 0.15, 0.0001)
	assert_almost_eq(BalanceConfig.TRAP_MAX_HP_FRAC_ROOM_SINGLE, 0.25, 0.0001)
	assert_almost_eq(BalanceConfig.TRAP_MAX_HP_FRAC_COMBAT_AOE, 0.08, 0.0001)
	assert_almost_eq(BalanceConfig.TRAP_MAX_HP_FRAC_ROOM_AOE, 0.12, 0.0001)


func test_trap_room_damage_numbers() -> void:
	## ハード帯で旧数値を維持。
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(800, false, false, 1), 120)
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(800, true, false, 1), 200)
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(1000, true, true, 1), 120)


func test_trap_trigger_chance_raised() -> void:
	## ハード帯エイリアス（旧 70% → ティア別 65%）。
	assert_almost_eq(_TrapPresentation.TRIGGER_CHANCE, 0.65, 0.0001)
	assert_almost_eq(_TrapPresentation.trigger_chance(1), 0.65, 0.0001)


func test_treasure_success_rewards() -> void:
	assert_eq(_DungeonController.TREASURE_GOLD, 120)
	assert_almost_eq(_DungeonController.TREASURE_ACCESSORY_CHANCE, 0.35, 0.0001)
	assert_almost_eq(BalanceConfig.TREASURE_WEAPON_CHANCE, 0.12, 0.0001)


func test_heal_room_percent_floor() -> void:
	assert_almost_eq(BalanceConfig.ROOM_HEAL_MAX_HP_FRAC, 0.18, 0.0001)
	assert_eq(BalanceConfig.ROOM_HEAL_AMOUNT, 80)


func test_fail_penalty_fractions() -> void:
	## 罠以外を緩和（罠部屋割合は TRAP_* 据置）。
	assert_almost_eq(BalanceConfig.NONCOMBAT_FAIL_TREASURE_HP_FRAC, 0.08, 0.0001)
	assert_almost_eq(BalanceConfig.NONCOMBAT_FAIL_HEAL_HP_FRAC, 0.07, 0.0001)
	assert_almost_eq(BalanceConfig.NONCOMBAT_FAIL_LORE_HP_FRAC, 0.05, 0.0001)


func test_lore_bonus_gold() -> void:
	assert_eq(BalanceConfig.LORE_FIRST_GOLD, 20)
	assert_eq(BalanceConfig.LORE_REPEAT_GOLD, 10)


func test_lore_floor_blessing_mult() -> void:
	assert_almost_eq(BalanceConfig.LORE_FLOOR_BLESSING_MULT, 1.1, 0.0001)
	assert_eq(BalanceConfig.LORE_FLOOR_BLESSING_KINDS.size(), 3)


func test_lore_floor_blessing_applies_on_next_room_only() -> void:
	var dc = _DungeonController.new()
	dc.current_room_index = 2
	dc.floor_blessing_kind = ""
	dc.floor_blessing_room_index = -1
	var granted: Dictionary = dc.grant_lore_floor_blessing()
	assert_false(granted.is_empty())
	assert_eq(int(dc.floor_blessing_room_index), 3)
	assert_almost_eq(dc.floor_blessing_mult_for(str(granted["kind"])), 1.0, 0.0001)
	dc.current_room_index = 3
	assert_almost_eq(dc.floor_blessing_mult_for(str(granted["kind"])), 1.1, 0.0001)
	assert_almost_eq(dc.floor_blessing_mult_for("nope"), 1.0, 0.0001)
	dc.current_room_index = 4
	dc._expire_floor_blessing_if_needed()
	assert_eq(dc.floor_blessing_kind, "")
	dc.free()
