extends GutTest
## CombatPassives の解決ロジック（P3-D155 / P3-GACHA-006）。


func _make_member(id: String, job_id: String, rarity: int) -> Resource:
	var adv: Resource = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = id
	adv.job_id = job_id
	adv.rarity = rarity
	return adv


func _ids(defs: Array) -> Array:
	var out: Array = []
	for d in defs:
		out.append(str(d.get("id", "")))
	return out


func test_base_roster_uses_char_passive_only() -> void:
	var member: Resource = _make_member("adventurer_0", "swordsman", 4)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["ald_royal_flame"], "基本ロスターはキャラ固有のみ（★4でもティア追加なし）")


func test_low_rarity_gets_job_fallback_only() -> void:
	var member: Resource = _make_member("extra_1", "ranger", 2)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["foresight"], "★2以下はジョブフォールバックのみ")


func test_star3_appends_tier_passive() -> void:
	var member: Resource = _make_member("extra_2", "alchemist", 3)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["field_medic", "spare_vial"], "★3はジョブFB+★3職固有")


func test_star4_appends_star4_only() -> void:
	var member: Resource = _make_member("extra_3", "vanguard", 4)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_true(ids.has("greatshield_order"), "★4は★4職固有を付与")
	assert_false(ids.has("unyielding_stance"), "★3定義は重複付与しない")


func test_gacha_helper_keeps_own_passive_plus_tier() -> void:
	var member: Resource = _make_member("gacha_helper_a", "vanguard", 4)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["valden_iron_oath", "greatshield_order"], "助っ人固有+★4職固有")


func test_all_tier_passive_defs_exist() -> void:
	for job in ["swordsman", "ranger", "alchemist", "vanguard", "beast_tamer"]:
		assert_false(CombatPassives.tier_def_for(job, 3).is_empty(), "★3定義あり: " + job)
		assert_false(CombatPassives.tier_def_for(job, 4).is_empty(), "★4定義あり: " + job)
	assert_true(CombatPassives.tier_def_for("swordsman", 2).is_empty(), "★2は定義なし")
