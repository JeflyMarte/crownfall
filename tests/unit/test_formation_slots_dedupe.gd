extends GutTest

## 陣形スロット初期化で同一メンバーが複製されないこと。

const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()


func test_init_formation_does_not_duplicate_when_slots_conflict() -> void:
	## A=slot0, B=slot2 のとき、空き埋めが party index 直埋めすると [A,B,B,…] になる旧バグ。
	assert_gte(GameState.roster.size(), 2)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	GameState.party_members = [a, b]
	GameState.set_member_formation_slot(a, 0)
	GameState.set_member_formation_row(a, GameState.FORMATION_FRONT)
	GameState.set_member_formation_slot(b, 2)
	GameState.set_member_formation_row(b, GameState.FORMATION_BACK)

	var scene: Node = load(ROSTER_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a, b]
	scene._init_formation_slots_from_party()

	var seen: Dictionary = {}
	var count: int = 0
	for slot in scene._formation_slots:
		if slot == null:
			continue
		count += 1
		assert_false(seen.has(slot), "同一メンバーが複数スロットに入らない")
		seen[slot] = true
	assert_eq(count, 2)
	assert_true(seen.has(a))
	assert_true(seen.has(b))


func test_dedupe_clears_duplicate_slot_refs() -> void:
	assert_gte(GameState.roster.size(), 1)
	var a: Resource = GameState.roster[0]
	var scene: Node = load(ROSTER_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._formation_slots = [a, a, null, null]
	scene._dedupe_formation_slots_local()
	assert_eq(scene._formation_slots[0], a)
	assert_eq(scene._formation_slots[1], null)


func test_sync_preserves_back_only_two_member_party() -> void:
	## 前列空き＋後列2人を sync しても前列へ詰めないこと。
	assert_gte(GameState.roster.size(), 2)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	var scene: Node = load(ROSTER_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a, b]
	scene._formation_slots = [null, null, a, b]
	scene._sync_formation_slots_from_selection()
	assert_eq(scene._formation_slots[0], null)
	assert_eq(scene._formation_slots[1], null)
	assert_eq(scene._formation_slots[2], a)
	assert_eq(scene._formation_slots[3], b)
	assert_eq(GameState.get_member_formation_row(a), GameState.FORMATION_BACK)
	assert_eq(GameState.get_member_formation_row(b), GameState.FORMATION_BACK)
	assert_eq(GameState.get_member_formation_slot(a), 2)
	assert_eq(GameState.get_member_formation_slot(b), 3)


func test_back_preset_places_two_members_in_back_row() -> void:
	assert_gte(GameState.roster.size(), 2)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	var scene: Node = load(ROSTER_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a, b]
	scene._formation_slots = [a, b, null, null]
	scene._on_formation_preset_pressed("back")
	assert_eq(scene._formation_slots[0], null)
	assert_eq(scene._formation_slots[1], null)
	assert_true(scene._formation_slots[2] != null)
	assert_true(scene._formation_slots[3] != null)
	assert_eq(GameState.get_member_formation_row(scene._formation_slots[2]), GameState.FORMATION_BACK)
	assert_eq(GameState.get_member_formation_row(scene._formation_slots[3]), GameState.FORMATION_BACK)


func test_dedupe_prefers_back_slot_for_back_row_overflow() -> void:
	assert_gte(GameState.roster.size(), 2)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	GameState.party_members = [a, b]
	GameState.set_member_formation_slot(a, 2)
	GameState.set_member_formation_row(a, GameState.FORMATION_BACK)
	GameState.set_member_formation_slot(b, 2)
	GameState.set_member_formation_row(b, GameState.FORMATION_BACK)
	GameState._dedupe_formation_slots()
	assert_eq(GameState.get_member_formation_slot(a), 2)
	assert_eq(GameState.get_member_formation_slot(b), 3)
	assert_eq(GameState.get_member_formation_row(b), GameState.FORMATION_BACK)
