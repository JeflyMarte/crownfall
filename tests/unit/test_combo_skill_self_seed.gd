extends GutTest

## P3-BAL-ALLY-FIX-001-3B — 連携技は自己付与＋温存解除で1枠運用可能。


func _assert_self_seed(skill_id: String, status_id: String) -> void:
	var skill: Resource = DataRegistry.get_skill_data(skill_id)
	assert_not_null(skill, skill_id)
	assert_eq(str(skill.reserve_condition), "", "%s reserve cleared" % skill_id)
	assert_eq(str(skill.apply_status_id), status_id, skill_id)
	assert_gt(float(skill.apply_status_chance), 0.0, skill_id)


func test_combo_skills_self_seed_without_reserve() -> void:
	_assert_self_seed("fear_chain", "fear")
	_assert_self_seed("vulnerable_surge", "vulnerable")
	## SW/RG の旧連携技はキット分化で別方向へ（多段／貫通）。残データは自己付与を要求しない。
	_assert_self_seed("venom_burst", "poison")
	var venom: Resource = DataRegistry.get_skill_data("venom_burst")
	assert_eq(str(venom.apply_status_id2), "vulnerable")
	assert_gt(float(venom.apply_status_chance2), 0.0)


func test_diverge_skills_are_not_status_self_seed() -> void:
	var dance: Resource = DataRegistry.get_skill_data("blade_dance")
	assert_true(str(dance.apply_status_id).is_empty())
	var pierce: Resource = DataRegistry.get_skill_data("piercing_shot")
	assert_true(str(pierce.apply_status_id).is_empty())

