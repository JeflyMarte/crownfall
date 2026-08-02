extends GutTest
## T6/T7 軽減テロップ（戦闘内1回）。

const _EnemyResistTelop = preload("res://scripts/combat/EnemyResistTelop.gd")


func test_message_basic_vs_skill() -> void:
	assert_eq(_EnemyResistTelop.message(true), "通常攻撃が通りにくい")
	assert_eq(_EnemyResistTelop.message(false), "スキルが通りにくい")


func test_should_announce_once_per_key() -> void:
	var announced: Dictionary = {}
	assert_true(_EnemyResistTelop.should_announce(announced, 0, 0.2, true))
	_EnemyResistTelop.mark_announced(announced, 0, true)
	assert_false(_EnemyResistTelop.should_announce(announced, 0, 0.2, true))
	## スキル側は別キー。
	assert_true(_EnemyResistTelop.should_announce(announced, 0, 0.2, false))
	## 別スロットも別キー。
	assert_true(_EnemyResistTelop.should_announce(announced, 1, 0.2, true))


func test_full_mult_skips() -> void:
	var announced: Dictionary = {}
	assert_false(_EnemyResistTelop.should_announce(announced, 0, 1.0, true))
	assert_false(_EnemyResistTelop.should_announce(announced, -1, 0.2, true))
