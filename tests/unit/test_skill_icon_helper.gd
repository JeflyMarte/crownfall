extends GutTest

const _SkillIconHelper = preload("res://scripts/ui/SkillIconHelper.gd")


func test_player_skill_mapping_covers_expected_ids() -> void:
	var expected: Array[String] = [
		"slash_attack", "guard_strike", "quick_shot", "hunter_mark", "hex_bolt",
		"toxin_dart", "snare_shot", "mend", "empower", "ultimate_strike",
		"ouga_retsudan", "titan_roar", "grand_elixir", "dead_eye", "beast_dominion",
	]
	for skill_id in expected:
		assert_false(_SkillIconHelper.get_base_id(skill_id).is_empty(), skill_id)


func test_unknown_skill_has_no_base() -> void:
	assert_eq(_SkillIconHelper.get_base_id("enemy_claw_guillotine"), "")
	assert_eq(_SkillIconHelper.resolve_base_id("enemy_claw_guillotine"), "")


func test_make_icon_uses_base_texture_when_art_exists() -> void:
	if not _SkillIconHelper.has_base_art("hex"):
		pass_test("hex base art not installed")
		return
	var member := Adventurer.new()
	member.id = "adventurer_3"
	member.job_id = "vanguard"
	var icon: Control = _SkillIconHelper.make_icon("hex_bolt", member)
	assert_not_null(icon)
	assert_true(icon is TextureRect)


func test_ultimate_falls_back_to_slash_base() -> void:
	if not _SkillIconHelper.has_base_art("slash"):
		pass_test("slash base art not installed")
		return
	assert_eq(_SkillIconHelper.resolve_base_id("ultimate_strike"), "slash")
	var member := Adventurer.new()
	member.job_id = "swordsman"
	assert_not_null(_SkillIconHelper.make_icon("ultimate_strike", member))


func test_job_ultimate_uses_base_texture() -> void:
	if not _SkillIconHelper.has_base_art("slash"):
		pass_test("slash base art not installed")
		return
	var member := Adventurer.new()
	member.job_id = "swordsman"
	var icon: Control = _SkillIconHelper.make_icon("ouga_retsudan", member)
	assert_not_null(icon)
	assert_true(icon is TextureRect)


func test_make_unique_icon_uses_individual_texture_for_ultimates() -> void:
	var ultimate_ids: Array[String] = [
		"ouga_retsudan", "titan_roar", "grand_elixir", "dead_eye", "beast_dominion",
	]
	for skill_id in ultimate_ids:
		var icon: Control = _SkillIconHelper.make_unique_icon(skill_id, Vector2(96, 96))
		assert_not_null(icon, skill_id)
		assert_true(icon is TextureRect, skill_id)
