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
