extends GutTest
## 敵バフ剥がし（P3-BAL-ENEMY-DISPEL-001）。


func test_beneficial_status_ids() -> void:
	assert_true(StatusResolver.is_beneficial_status("guard"))
	assert_true(StatusResolver.is_beneficial_status("empower"))
	assert_true(StatusResolver.is_beneficial_status("regen"))
	assert_false(StatusResolver.is_beneficial_status("poison"))
	assert_false(StatusResolver.is_beneficial_status("heal_block"))


func test_remove_beneficial_keeps_debuffs() -> void:
	var r: StatusResolver = StatusResolver.new()
	assert_true(r.apply_status("party_0", "guard", 1, 0))
	assert_true(r.apply_status("party_0", "empower", 1, 0))
	assert_true(r.apply_status("party_0", "bleed", 1, 100))
	var removed: PackedStringArray = r.remove_beneficial_statuses("party_0")
	assert_true("guard" in removed)
	assert_true("empower" in removed)
	assert_eq(r.get_status_stacks("party_0", "guard"), 0)
	assert_eq(r.get_status_stacks("party_0", "empower"), 0)
	assert_gt(r.get_status_stacks("party_0", "bleed"), 0)


func test_dispel_skill_resources() -> void:
	for sid: String in [
		"enemy_buff_break",
		"enemy_buff_break_howl",
		"enemy_buff_break_row",
		"enemy_buff_break_chrono",
		"boss_buff_break_all",
	]:
		var sk: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(sk, sid)
		assert_eq(str(sk.effect_type), "dispel", sid)


func test_carriers_have_dispel_skills() -> void:
	assert_true(DataRegistry.get_enemy_data("bone_picker").skill_ids.has("enemy_buff_break"))
	assert_true(DataRegistry.get_enemy_data("vergaron").skill_ids.has("enemy_buff_break_howl"))
	assert_true(DataRegistry.get_enemy_data("greios").skill_ids.has("enemy_buff_break_row"))
	assert_true(DataRegistry.get_enemy_data("clock_moth").skill_ids.has("enemy_buff_break_chrono"))
	assert_true(DataRegistry.get_enemy_data("nightfen").skill_ids.has("enemy_buff_break"))
	assert_true(DataRegistry.get_enemy_data("serdion").skill_ids.has("boss_buff_break_all"))
	assert_true(DataRegistry.get_enemy_data("moldgar").skill_ids.has("boss_buff_break_all"))
	assert_true(DataRegistry.get_enemy_data("nereion").skill_ids.has("boss_buff_break_all"))
