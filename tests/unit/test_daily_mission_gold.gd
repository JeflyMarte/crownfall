extends GutTest

## P3-BAL-DAILY-REWARD-VARIETY-001 — 日課報酬バラエティ（最大2種・Gold偏り削減）。


func _load_mission(mission_id: String) -> Resource:
	return load("res://resources/daily_missions/%s.tres" % mission_id)


func _reward_kind_count(m: Resource) -> int:
	var n: int = 0
	if int(m.reward_gold) > 0:
		n += 1
	if int(m.reward_gacha_token) > 0:
		n += 1
	if not str(m.reward_material_id).is_empty() and int(m.reward_material_qty) > 0:
		n += 1
	if bool(m.get("reward_equip")):
		n += 1
	return n


func test_daily_reward_table_variety() -> void:
	var cases: Array = [
		## id, gold, token, mat_id, mat_qty, equip, epic_bias
		["daily_clear_run", 120, 0, "", 0, true, false],
		["daily_kill_enemies", 0, 20, "base_ore", 8, false, false],
		["daily_kill_elite", 80, 0, "ancient_bone", 3, false, false],
		["daily_kill_boss", 0, 25, "", 0, true, true],
		["daily_craft_item", 0, 40, "base_ore", 5, false, false],
		["daily_enhance_item", 60, 0, "base_ore", 10, false, false],
		["daily_alchemy_item", 60, 0, "relic_shard", 3, false, false],
		["daily_dismantle_item", 0, 0, "base_ore", 12, false, false],
	]
	for row in cases:
		var mid: String = str(row[0])
		var m: Resource = _load_mission(mid)
		assert_not_null(m, mid)
		assert_eq(int(m.reward_gold), int(row[1]), mid + " gold")
		assert_eq(int(m.reward_gacha_token), int(row[2]), mid + " token")
		assert_eq(str(m.reward_material_id), str(row[3]), mid + " mat_id")
		assert_eq(int(m.reward_material_qty), int(row[4]), mid + " mat_qty")
		assert_eq(bool(m.get("reward_equip")), bool(row[5]), mid + " equip")
		assert_eq(bool(m.get("reward_equip_epic_bias")), bool(row[6]), mid + " epic_bias")
		assert_lte(_reward_kind_count(m), 2, mid + " max 2 reward kinds")


func test_claim_grants_equip_or_gold_fallback() -> void:
	GameState.reset_for_new_game()
	## 日課は常に3件（`_entries_valid`）。クリアを先頭にして claim。
	GameState.daily_mission_state = {
		"day_key": DailyMissionSystem.current_day_key(),
		"entries": [
			{"mission_id": "daily_clear_run", "progress": 1, "claimed": false},
			{"mission_id": "daily_dismantle_item", "progress": 0, "claimed": false},
			{"mission_id": "daily_enhance_item", "progress": 0, "claimed": false},
		],
	}
	var before_gold: int = GameState.gold
	var before_inv: int = GameState.equipment_inventory_count()
	var result: Dictionary = DailyMissionSystem.claim(0)
	assert_true(bool(result.get("ok", false)), "claim ok")
	var granted: bool = bool(result.get("equip_granted", false))
	var fallback: int = int(result.get("equip_fallback_gold", 0))
	if granted:
		assert_eq(GameState.equipment_inventory_count(), before_inv + 1, "equip added")
		assert_true(str(result.get("equip_id", "")) != "", "equip id")
		assert_eq(fallback, 0, "no fallback when granted")
	else:
		assert_gt(fallback, 0, "fallback gold when bag/pool fail")
		assert_gte(GameState.gold, before_gold + 120 + fallback, "gold includes fallback")
