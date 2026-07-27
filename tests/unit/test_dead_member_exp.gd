extends GutTest

## 撃破時点の死者は以降の撃破EXPを受け取らない。


func before_each() -> void:
	GameState.seed_all_starters_unlocked()
	GameState.last_run_exp_by_member = {}
	GameState.last_run_exp_reward = 0


func test_accumulate_exp_only_listed_members() -> void:
	var dc: Node = load("res://scripts/dungeon/DungeonController.gd").new()
	add_child_autofree(dc)
	dc.run_exp_by_member = {}
	dc.accumulate_exp_for_members(40, ["adventurer_0", "adventurer_1"])
	dc.accumulate_exp_for_members(25, ["adventurer_1"])
	assert_eq(dc.get_member_run_exp("adventurer_0"), 40)
	assert_eq(dc.get_member_run_exp("adventurer_1"), 65)
	assert_eq(dc.get_member_run_exp("adventurer_2"), 0)


func test_grant_exp_by_member_skips_zero() -> void:
	assert_true(GameState.party_members.size() >= 2)
	var a: Resource = GameState.party_members[0]
	var b: Resource = GameState.party_members[1]
	var a_lv: int = int(a.level)
	var a_exp: int = int(a.exp)
	var b_lv: int = int(b.level)
	var b_exp: int = int(b.exp)
	var by_member: Dictionary = {
		str(a.id): 30,
		str(b.id): 0,
	}
	LevelSystem.grant_exp_by_member(by_member)
	assert_true(int(a.exp) > a_exp or int(a.level) > a_lv, "生存者はEXPを得る")
	assert_eq(int(b.level), b_lv)
	assert_eq(int(b.exp), b_exp)


func test_snapshot_uses_per_member_amounts() -> void:
	const _ExpRunSnapshot := preload("res://scripts/result/ExpRunSnapshot.gd")
	assert_true(not GameState.party_members.is_empty())
	var mid: String = str(GameState.party_members[0].id)
	var snaps: Dictionary = _ExpRunSnapshot.build_party_snapshots_by_member({mid: 55})
	assert_true(snaps.has(mid))
	assert_eq(int(snaps[mid].get("exp_gained", 0)), 55)
	for other: Resource in GameState.party_members:
		var oid: String = str(other.id)
		if oid == mid:
			continue
		if snaps.has(oid):
			assert_eq(int(snaps[oid].get("exp_gained", -1)), 0)
