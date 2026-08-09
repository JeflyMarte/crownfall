extends GutTest

## P3-BAL-BOSS-STATUS-SPEED-001 — 全ボス状態耐性0.55＋速度下限1.0。


func test_all_bosses_status_resist_and_speed_floor() -> void:
	var seen := 0
	for boss: Variant in DataRegistry.get_all_enemy_data():
		if boss == null:
			continue
		if int(boss.enemy_type) != Enums.EnemyType.BOSS:
			continue
		var eid: String = str(boss.id)
		seen += 1
		assert_almost_eq(
			float(boss.incoming_status_chance_mult), 0.55, 0.001, eid
		)
		assert_gte(float(boss.attack_speed), 1.0, eid)
	assert_gte(seen, 10, "boss count")
