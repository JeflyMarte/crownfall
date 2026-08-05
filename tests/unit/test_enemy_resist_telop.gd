extends GutTest
## P3-BAL-TRICKY-RESIST-A-001 — T6/T7 パッシブ名＋HP減。

const _EnemyResistTelop = preload("res://scripts/combat/EnemyResistTelop.gd")


func test_passive_names() -> void:
	assert_eq(_EnemyResistTelop.passive_name(true), "硬殻")
	assert_eq(_EnemyResistTelop.passive_name(false), "幻障")
	assert_eq(_EnemyResistTelop.message(true), "通常攻撃が通りにくい")
	assert_eq(_EnemyResistTelop.message(false), "スキルが通りにくい")


func test_show_on_hit_when_mitigated() -> void:
	assert_true(_EnemyResistTelop.should_show_on_hit(0.2))
	assert_false(_EnemyResistTelop.should_show_on_hit(1.0))


func test_t6_t7_hp_nerfed() -> void:
	var expect := {
		"skull_turtle": 619,
		"glacier_warden": 624,
		"rune_carcinos": 510,
		"mirror_boa": 806,
		"ninja_octopus": 962,
		"mist_mantis": 480,
	}
	for eid: String in expect.keys():
		var data: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(data, eid)
		assert_eq(int(data.max_hp), int(expect[eid]), eid)


func test_resist_mult_unchanged() -> void:
	assert_almost_eq(float(DataRegistry.get_enemy_data("skull_turtle").incoming_basic_mult), 0.2, 0.001)
	assert_almost_eq(float(DataRegistry.get_enemy_data("mirror_boa").incoming_skill_mult), 0.2, 0.001)
