extends GutTest

## P3-SKILL-KIT-001 — 職キット7本＋全体技データ

func test_each_job_has_seven_unlocks() -> void:
	for job_id in ["swordsman", "ranger", "vanguard", "alchemist", "beast_tamer"]:
		var job: Resource = DataRegistry.get_job_data(job_id)
		assert_not_null(job, job_id)
		assert_eq(job.skill_unlocks.size(), 7, "%s unlocks" % job_id)
		assert_eq(job.learnable_skill_ids.size(), 7, "%s learnable" % job_id)
		var levels: Array = []
		for entry: Variant in job.skill_unlocks:
			levels.append(int(entry.get("level", 0)))
			var sid: String = str(entry.get("skill_id", ""))
			assert_false(sid.is_empty())
			assert_not_null(DataRegistry.get_skill_data(sid), sid)
		assert_eq(levels, [1, 8, 15, 22, 30, 40, 50], "%s levels" % job_id)


func test_new_aoe_and_party_skills_exist() -> void:
	var aoe_ids: Array[String] = [
		"blade_tempest", "blood_mist_slash", "volley_shot", "hunting_ground_mark",
		"shield_quake", "miasma_cloud", "venom_spray",
	]
	for sid in aoe_ids:
		var sk: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(sk, sid)
		assert_eq(str(sk.target_type), "all_enemies", sid)
		assert_eq(str(sk.effect_type), "damage", sid)
	var party_ids: Array[String] = ["bulwark_aura", "rally_vapors", "herd_call"]
	for sid in party_ids:
		var sk2: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(sk2, sid)
		assert_eq(str(sk2.target_type), "all_party", sid)
		assert_eq(str(sk2.effect_type), "buff", sid)


func test_conditional_followup_tags() -> void:
	var chain: Resource = DataRegistry.get_skill_data("chain_slash")
	assert_true(chain.tags.has("vs_bleed"))
	var pursuit: Resource = DataRegistry.get_skill_data("mark_pursuit")
	assert_true(pursuit.tags.has("vs_mark"))


func test_swordsman_description_is_offense_frontline() -> void:
	var job: Resource = DataRegistry.get_job_data("swordsman")
	assert_false(str(job.description).contains("被弾を引き受ける"))
	assert_true(str(job.description).contains("主火力") or str(job.description).contains("切れ味"))
