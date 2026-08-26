extends GutTest
## P3-BUG-SAVED-PARTY-FORM-001 — 保存パーティに陣形を残す。


func before_each() -> void:
	GameState.seed_all_starters_unlocked()
	GameState.saved_parties.clear()


func test_save_party_preset_stores_formation_slots() -> void:
	assert_gte(GameState.party_members.size(), 2)
	var a: Resource = GameState.party_members[0]
	var b: Resource = GameState.party_members[1]
	GameState.set_member_formation_slot(a, 0)
	GameState.set_member_formation_row(a, GameState.FORMATION_FRONT)
	GameState.set_member_formation_slot(b, 3)
	GameState.set_member_formation_row(b, GameState.FORMATION_BACK)
	GameState.save_party_preset(0, [a, b])
	var preset: Dictionary = GameState.saved_parties[0] as Dictionary
	assert_true(preset.has("formations"))
	var formations: Array = preset["formations"] as Array
	assert_eq(formations.size(), 2)
	var by_id: Dictionary = {}
	for e: Variant in formations:
		by_id[str((e as Dictionary).get("id", ""))] = e
	assert_eq(int((by_id[str(a.id)] as Dictionary).get("formation_slot", -1)), 0)
	assert_eq(int((by_id[str(b.id)] as Dictionary).get("formation_slot", -1)), 3)


func test_apply_saved_party_restores_formation() -> void:
	assert_gte(GameState.party_members.size(), 4)
	var m0: Resource = GameState.party_members[0]
	var m1: Resource = GameState.party_members[1]
	var m2: Resource = GameState.party_members[2]
	var m3: Resource = GameState.party_members[3]
	## プリセット: m0 後衛右(3) / m1 前衛左(0) / m2 前衛右(1) / m3 後衛左(2)
	GameState.set_member_formation_slot(m0, 3)
	GameState.set_member_formation_row(m0, GameState.FORMATION_BACK)
	GameState.set_member_formation_slot(m1, 0)
	GameState.set_member_formation_row(m1, GameState.FORMATION_FRONT)
	GameState.set_member_formation_slot(m2, 1)
	GameState.set_member_formation_row(m2, GameState.FORMATION_FRONT)
	GameState.set_member_formation_slot(m3, 2)
	GameState.set_member_formation_row(m3, GameState.FORMATION_BACK)
	GameState.save_party_preset(1, [m0, m1, m2, m3])
	## 別陣形に崩す
	GameState.set_member_formation_slot(m0, 0)
	GameState.set_member_formation_slot(m1, 1)
	GameState.set_member_formation_slot(m2, 2)
	GameState.set_member_formation_slot(m3, 3)
	var reason: String = GameState.apply_saved_party(1)
	assert_eq(reason, "")
	assert_eq(GameState.get_member_formation_slot(m0), 3)
	assert_eq(GameState.get_member_formation_row(m0), GameState.FORMATION_BACK)
	assert_eq(GameState.get_member_formation_slot(m1), 0)
	assert_eq(GameState.get_member_formation_slot(m2), 1)
	assert_eq(GameState.get_member_formation_slot(m3), 2)


func test_legacy_preset_without_formations_still_applies() -> void:
	assert_gte(GameState.party_members.size(), 2)
	var a: Resource = GameState.party_members[0]
	var b: Resource = GameState.party_members[1]
	GameState.saved_parties = [{
		"name": "旧",
		"member_ids": [str(a.id), str(b.id)],
	}]
	var reason: String = GameState.apply_saved_party(0)
	assert_eq(reason, "")
	assert_eq(GameState.party_members.size(), 2)
