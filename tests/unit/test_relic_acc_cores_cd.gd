extends GutTest
## P3-BAL-RELIC-ACC-CD-001 — 案C（レリック DoT／オトモ核）＋案D（開幕装飾の役割分離）。


func _equip_relic(relic_id: String, job_id: String = "swordsman") -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "relic_cd"
	member.job_id = job_id
	member.rarity = 1
	GameState.owned_relics = [relic_id]
	GameState.party_members = [member]
	GameState.set_member_relic(member, relic_id)


func after_each() -> void:
	GameState.party_members = []
	GameState.owned_relics = []


func test_scout_lens_is_dot_core() -> void:
	var def: Dictionary = CombatPassives.get_def("relic_scout_lens")
	assert_almost_eq(float(def.get("outgoing_vs_status_mult", 1.0)), 1.45, 0.001)
	assert_true(def.get("outgoing_vs_status_ids", []).has("poison"))
	assert_true(def.get("outgoing_vs_status_ids", []).has("bleed"))
	assert_almost_eq(float(def.get("outgoing_without_status_mult", 1.0)), 0.85, 0.001)
	assert_eq(str(def.get("effect", "")), "random_enemy_status")
	assert_ne(str(def.get("effect", "")), "opening_strike")
	_equip_relic("relic_scout_lens")
	assert_almost_eq(CombatPassives.relic_mark_focus_outgoing_mult(0, ["poison"]), 1.45, 0.001)
	assert_almost_eq(CombatPassives.relic_mark_focus_outgoing_mult(0, []), 0.85, 0.001)


func test_war_banner_is_pet_core() -> void:
	var def: Dictionary = CombatPassives.get_def("relic_war_banner")
	assert_almost_eq(float(def.get("pet_outgoing_mult", 1.0)), 1.35, 0.001)
	assert_almost_eq(float(def.get("pet_defense_mult", 1.0)), 1.15, 0.001)
	assert_almost_eq(float(def.get("outgoing_mult", 1.0)), 0.85, 0.001)
	_equip_relic("relic_war_banner")
	assert_almost_eq(CombatPassives.pet_outgoing_mult_from_party(), 1.35, 0.001)
	assert_almost_eq(CombatPassives.pet_defense_mult_from_party(), 1.15, 0.001)


func test_hourglass_remains_ultimate_core() -> void:
	var def: Dictionary = CombatPassives.get_def("relic_old_hourglass")
	assert_almost_eq(float(def.get("ultimate_charge_dealt_mult", 1.0)), 2.0, 0.001)
	assert_almost_eq(float(def.get("skill_cd_mult", 1.0)), 1.30, 0.001)


func test_opening_accessories_roles_diverge() -> void:
	var royal: Dictionary = CombatPassives.get_def("eq_mourngate_royal")
	assert_almost_eq(float(royal.get("first_attack_mult", 1.0)), 1.75, 0.001)
	assert_false(royal.has("trigger"), "王家は初撃倍率（開幕小鼓舞を廃止）")
	var covenant: Dictionary = CombatPassives.get_def("eq_silvaria_covenant")
	assert_eq(str(covenant.get("effect", "")), "party_rally")
	assert_almost_eq(float(covenant.get("ultimate_charge_flat", 0.0)), 25.0, 0.001)
	assert_eq(str(covenant.get("status_id", "x")), "")
	assert_ne(str(covenant.get("status_id", "")), "empower_minor")
