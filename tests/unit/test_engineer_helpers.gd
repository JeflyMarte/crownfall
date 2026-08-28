extends GutTest

## 機巧士ガチャ助っ人3＋パッシブ＋必殺（P3-JOB-ENGINEER-001 §6）。


func test_gacha_pool_includes_engineer_helpers() -> void:
	var pool: Array = DataRegistry.get_all_gacha_helper_data()
	assert_eq(pool.size(), 14)
	var ids: Dictionary = {}
	for h: Resource in pool:
		ids[str(h.id)] = true
	assert_true(ids.has("helper_q"))
	assert_true(ids.has("helper_r"))
	assert_true(ids.has("helper_s"))


func test_engineer_helper_tres_wired() -> void:
	var trim: Resource = DataRegistry.get_gacha_helper_data("helper_q")
	assert_not_null(trim)
	assert_eq(str(trim.display_name), "トリム")
	assert_eq(str(trim.job_id), "engineer")
	assert_eq(int(trim.rarity), 3)
	assert_eq(str(trim.passive_id), "eng_trap_opener")
	assert_eq(str(trim.ultimate_skill_id), "eng_full_arm_cascade")
	var bran: Resource = DataRegistry.get_gacha_helper_data("helper_r")
	assert_eq(str(bran.passive_id), "eng_brand_afterheat")
	assert_eq(str(bran.ultimate_skill_id), "eng_blaze_overload")
	assert_eq(int(bran.rarity), 4)
	var ortho: Resource = DataRegistry.get_gacha_helper_data("helper_s")
	assert_eq(str(ortho.passive_id), "eng_seam_pierce")
	assert_eq(str(ortho.ultimate_skill_id), "eng_armor_gekigeki")
	assert_eq(int(ortho.rarity), 2)


func test_engineer_passive_defs_exist() -> void:
	var opener: Dictionary = CombatPassives.get_def("eng_trap_opener")
	assert_eq(str(opener.get("effect", "")), "place_engineer_trap")
	assert_eq(str(opener.get("trigger", "")), "on_combat_start")
	assert_eq(int(opener.get("trap_fires", 0)), 2)
	var afterheat: Dictionary = CombatPassives.get_def("eng_brand_afterheat")
	assert_eq(str(afterheat.get("trigger", "")), "on_skill_hit")
	assert_almost_eq(float(afterheat.get("min_skill_cooldown", 0.0)), 12.0, 0.001)
	assert_eq(str(afterheat.get("status_id", "")), "ignite")
	var seam: Dictionary = CombatPassives.get_def("eng_seam_pierce")
	assert_eq(int(seam.get("every_n", 0)), 3)
	assert_true(bool(seam.get("armor_break_stack", false)))


func test_engineer_ultimate_skills_exist() -> void:
	for sid: String in [
		"eng_full_arm_cascade",
		"eng_blaze_overload",
		"eng_armor_gekigeki",
	]:
		var sd: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(sd, sid)
		assert_eq(str(sd.slot_type), "ultimate")


func test_helper_member_passive_resolution() -> void:
	var member: Resource = Adventurer.new()
	member.id = "gacha_helper_q"
	member.job_id = "engineer"
	var defs: Array = CombatPassives.for_member(member)
	assert_eq(defs.size(), 1)
	assert_eq(str(defs[0].get("id", "")), "eng_trap_opener")
	var ult: Resource = DataRegistry.get_skill_data(
		str(DataRegistry.get_gacha_helper_data("helper_q").ultimate_skill_id)
	)
	assert_not_null(ult)
	assert_eq(str(ult.id), "eng_full_arm_cascade")


func test_cascade_skill_has_eng_cascade_tag() -> void:
	var sd: Resource = DataRegistry.get_skill_data("eng_full_arm_cascade")
	assert_true(sd.tags.has("eng_cascade"))
	assert_true(sd.tags.has("trap_spike"))
	assert_eq(str(sd.target_type), "all_enemies")


func test_armor_gekigeki_has_vs_armor_break_tag() -> void:
	var sd: Resource = DataRegistry.get_skill_data("eng_armor_gekigeki")
	assert_true(sd.tags.has("vs_armor_break"))
	assert_eq(str(sd.apply_status_id), "armor_break")
