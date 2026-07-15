extends GutTest
## 編成人数補正は ACTIVE_PARTY_SIZE 定数ではなく現行編成人員を見る。


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.starter_progression_v1 = false
	GameState.ensure_base_roster_complete()


func after_each() -> void:
	GameState.reset_for_new_game()


func test_party_size_balance_uses_combatant_count() -> void:
	var cc_script: GDScript = load("res://scripts/combat/CombatController.gd")
	# 4人想定: base3 より敵が強くなる
	assert_eq(GameState.combatant_count(), 4)
	var mult4: float = cc_script._party_size_balance_multiplier(0.85)
	assert_gt(mult4, 1.0)
	# 1人に絞ると base 以下扱い（倍率1.0）
	var solo: Array = [GameState.roster[0]]
	assert_true(GameState.set_active_party(solo))
	assert_eq(GameState.combatant_count(), 1)
	var mult1: float = cc_script._party_size_balance_multiplier(0.85)
	assert_eq(mult1, 1.0)
