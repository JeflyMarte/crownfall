extends GutTest

## P3-BAL-DAILY-TREASURE-GOLD-001 — 日課 Gold 底上げ（魔晶石据置）。


func _load_mission(mission_id: String) -> Resource:
	return load("res://resources/daily_missions/%s.tres" % mission_id)


func test_daily_gold_boost_keeps_tokens() -> void:
	var cases: Array = [
		["daily_dismantle_item", 120, 0],
		["daily_alchemy_item", 150, 0],
		["daily_enhance_item", 150, 0],
		["daily_kill_enemies", 150, 15],
		["daily_kill_elite", 180, 0],
		["daily_clear_run", 200, 0],
		["daily_kill_boss", 250, 0],
		["daily_craft_item", 100, 50],
	]
	for row in cases:
		var m: Resource = _load_mission(str(row[0]))
		assert_not_null(m, str(row[0]))
		assert_eq(int(m.reward_gold), int(row[1]), str(row[0]) + " gold")
		assert_eq(int(m.reward_gacha_token), int(row[2]), str(row[0]) + " token")


func test_kill_enemies_material_unchanged() -> void:
	var m: Resource = _load_mission("daily_kill_enemies")
	assert_eq(str(m.reward_material_id), "relic_shard")
	assert_eq(int(m.reward_material_qty), 2)
