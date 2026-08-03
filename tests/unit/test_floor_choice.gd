extends GutTest

## P3-DG-FLOOR-CHOICE-001

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")


func _make_dc(seq_vals: Array) -> Node:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	var seq: Array[int] = []
	for v in seq_vals:
		seq.append(int(v))
	dc.room_sequence = seq
	dc.current_room_index = 0
	dc.current_room_type = seq[0]
	return dc


func test_floor_choice_constants() -> void:
	assert_almost_eq(BalanceConfig.FLOOR_CHOICE_DAMAGE_MULT, 1.5, 0.0001)
	assert_almost_eq(BalanceConfig.FLOOR_CHOICE_HARVEST_MULT, 1.35, 0.0001)
	assert_almost_eq(BalanceConfig.FLOOR_CHOICE_ASSAULT_MULT, 1.25, 0.0001)
	assert_eq(BalanceConfig.FLOOR_CHOICE_HARVEST_PICKS, 2)
	assert_eq(BalanceConfig.FLOOR_CHOICE_REWARD_KINDS.size(), 4)
	assert_eq(BalanceConfig.FLOOR_CHOICE_SHORT_FLOOR_COUNT, 9)
	assert_eq(BalanceConfig.FLOOR_CHOICE_MAX_SHORT_RUN, 1)
	assert_eq(BalanceConfig.FLOOR_CHOICE_MAX_PER_RUN, 2)


func test_floor_choice_max_short_vs_ten_floor() -> void:
	## ≤9F → 1回、10F → 2回。
	var short_seq: Array = []
	for _i: int in 9:
		short_seq.append(Enums.RoomType.COMBAT)
	var dc9: Node = _make_dc(short_seq)
	assert_eq(dc9.floor_choice_max_for_run(), 1)
	var long_seq: Array = []
	for _j: int in 10:
		long_seq.append(Enums.RoomType.COMBAT)
	var dc10: Node = _make_dc(long_seq)
	assert_eq(dc10.floor_choice_max_for_run(), 2)


func test_floor_choice_abyss_once_per_ten_floors() -> void:
	## 無限は 10F チャンクごとに1回。
	var seq: Array = []
	for _i: int in 25:
		seq.append(Enums.RoomType.COMBAT)
	var dc: Node = _make_dc(seq)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("abyss_mourngate")
	assert_not_null(dc.current_dungeon_data)
	assert_true(dc.is_abyss_run())
	dc.current_room_index = 0
	assert_eq(dc.floor_choice_max_for_run(), 1)
	dc.current_room_index = 9
	assert_eq(dc.floor_choice_max_for_run(), 1)
	dc.current_room_index = 10
	assert_eq(dc.floor_choice_max_for_run(), 2)
	dc.current_room_index = 19
	assert_eq(dc.floor_choice_max_for_run(), 2)
	dc.current_room_index = 20
	assert_eq(dc.floor_choice_max_for_run(), 3)
	dc.floor_choice_count = 1
	dc.current_room_index = 5
	assert_false(dc.can_offer_floor_choice())
	dc.current_room_index = 12
	assert_true(dc.can_offer_floor_choice())


func test_floor_choice_power_damage_next_room_only() -> void:
	var dc: Node = _make_dc([
		Enums.RoomType.COMBAT,
		Enums.RoomType.COMBAT,
		Enums.RoomType.COMBAT,
		Enums.RoomType.BOSS,
	])
	dc.run_damage_multiplier = 1.0
	dc.grant_floor_choice_power()
	assert_eq(dc.floor_choice_count, 1)
	assert_almost_eq(dc.get_effective_run_damage_multiplier(), 1.0, 0.0001)
	dc.current_room_index = 1
	assert_almost_eq(dc.get_effective_run_damage_multiplier(), 1.5, 0.0001)
	dc.current_room_index = 2
	dc._expire_floor_choice_if_needed()
	assert_almost_eq(dc.get_effective_run_damage_multiplier(), 1.0, 0.0001)


func test_floor_choice_harvest_two_kinds() -> void:
	var dc: Node = _make_dc([Enums.RoomType.COMBAT, Enums.RoomType.COMBAT, Enums.RoomType.COMBAT])
	dc.grant_floor_choice_harvest(["exp", "material"])
	dc.current_room_index = 1
	assert_almost_eq(dc.floor_blessing_mult_for("exp"), 1.35, 0.0001)
	assert_almost_eq(dc.floor_blessing_mult_for("material"), 1.35, 0.0001)
	assert_almost_eq(dc.floor_blessing_mult_for("gold"), 1.0, 0.0001)


func test_floor_choice_roll_harvest_kinds_random_two() -> void:
	var seen: Dictionary = {}
	for _i: int in 40:
		var kinds: Array[String] = FloorChoiceOverlay.roll_harvest_kinds()
		assert_eq(kinds.size(), 2)
		assert_ne(kinds[0], kinds[1])
		for k: String in kinds:
			assert_true(k in BalanceConfig.FLOOR_CHOICE_REWARD_KINDS)
			seen[k] = true
	assert_gte(seen.size(), 2)


func test_floor_choice_title_bbcode_emphasizes_name() -> void:
	var bb: String = FloorChoiceOverlay._panel_text_bbcode(
		"戦力強化",
		FloorChoiceOverlay.TITLE_COLOR_POWER,
		"与ダメ ×1.5"
	)
	assert_true(bb.contains("[color=#"))
	assert_true(bb.contains("戦力強化"))
	assert_true(bb.contains("与ダメ ×1.5"))
	assert_true(bb.contains("[font_size=%d]" % FloorChoiceOverlay.TITLE_FONT_SIZE))
	var overlay := FloorChoiceOverlay.new()
	add_child_autofree(overlay)
	overlay.open(false)
	assert_true(str(overlay._text_labels[0].text).contains("戦力強化"))
	assert_true(str(overlay._text_labels[1].text).contains("収穫強化"))
	assert_true(str(overlay._text_labels[2].text).contains("強襲ルート"))
	overlay.open(true)
	assert_true(str(overlay._text_labels[0].text).contains("応急手当"))



func test_floor_choice_assault_forces_elite() -> void:
	var dc: Node = _make_dc([Enums.RoomType.COMBAT, Enums.RoomType.COMBAT, Enums.RoomType.TREASURE])
	dc.grant_floor_choice_assault()
	assert_eq(dc.room_sequence[1], Enums.RoomType.ELITE)
	dc.current_room_index = 1
	assert_almost_eq(dc.floor_blessing_mult_for("equip"), 1.25, 0.0001)
	assert_almost_eq(dc.floor_blessing_mult_for("gold"), 1.25, 0.0001)


func test_floor_choice_offer_gates() -> void:
	var dc: Node = _make_dc([
		Enums.RoomType.COMBAT,
		Enums.RoomType.COMBAT,
		Enums.RoomType.BOSS,
	])
	assert_true(dc.can_offer_floor_choice())
	dc.current_room_index = 1
	assert_false(dc.can_offer_floor_choice())
	dc.current_room_index = 0
	dc.floor_choice_count = dc.floor_choice_max_for_run()
	assert_false(dc.can_offer_floor_choice())


func test_lore_and_choice_stack_on_same_kind() -> void:
	var dc: Node = _make_dc([Enums.RoomType.COMBAT, Enums.RoomType.COMBAT])
	dc.floor_blessing_kind = "exp"
	dc.floor_blessing_room_index = 1
	dc.grant_floor_choice_harvest(["exp", "gold"])
	dc.current_room_index = 1
	assert_almost_eq(
		dc.floor_blessing_mult_for("exp"),
		BalanceConfig.LORE_FLOOR_BLESSING_MULT * BalanceConfig.FLOOR_CHOICE_HARVEST_MULT,
		0.0001
	)
