extends GutTest

## ガチャ助っ人 個人ステ・固有パッシブ。

const _Bonuses = preload("res://scripts/roster/CharacterStatBonuses.gd")


func test_helper_personal_bonuses() -> void:
	var k: Dictionary = _Bonuses.for_helper_id("helper_k")
	assert_eq(int(k.get("attack", 0)), 270)
	assert_true(int(k.get("defense", 0)) < 0)
	var o: Dictionary = _Bonuses.for_helper_id("helper_o")
	assert_eq(int(o.get("attack", 0)), 40)
	assert_true(int(o.get("hp", 0)) < 0)


func test_passive_defs_for_new_four() -> void:
	var lenore: Dictionary = CombatPassives.get_def("lenore_seal_echo")
	assert_almost_eq(float(lenore.get("outgoing_mult", 1.0)), 1.18, 0.001)
	assert_almost_eq(float(lenore.get("incoming_mult", 1.0)), 1.12, 0.001)
	var sian: Dictionary = CombatPassives.get_def("sian_silent_line")
	assert_eq(str(sian.get("trigger", "")), "on_combat_start")
	assert_eq(str(sian.get("status_id", "")), "empower_minor")
	assert_eq(str(sian.get("target", "")), "party")
	var neri: Dictionary = CombatPassives.get_def("neri_waterfowl_call")
	assert_almost_eq(float(neri.get("pet_outgoing_mult", 1.0)), 1.25, 0.001)
	assert_almost_eq(float(neri.get("pet_defense_mult", 1.0)), 1.10, 0.001)
	var borg: Dictionary = CombatPassives.get_def("borg_gate_voice")
	assert_almost_eq(float(borg.get("evasion_rate_add", 0.0)), 0.18, 0.001)
	assert_false(borg.has("threat_base_add"))


func test_helper_tres_passive_wired() -> void:
	assert_eq(str(DataRegistry.get_gacha_helper_data("helper_k").passive_id), "lenore_seal_echo")
	assert_eq(str(DataRegistry.get_gacha_helper_data("helper_m").passive_id), "sian_silent_line")
	assert_eq(str(DataRegistry.get_gacha_helper_data("helper_n").passive_id), "borg_gate_voice")
	assert_eq(str(DataRegistry.get_gacha_helper_data("helper_o").passive_id), "neri_waterfowl_call")


func test_helper_p_personal_bonus() -> void:
	var b: Dictionary = _Bonuses.for_helper_id("helper_p")
	assert_eq(int(b.get("hp", 0)), 180)
	assert_eq(int(b.get("attack", 0)), 300)
	assert_eq(int(b.get("defense", 0)), 90)


func test_borg_no_longer_threat_tank() -> void:
	var member: Resource = Adventurer.new()
	member.id = "gacha_helper_n"
	member.job_id = "vanguard"
	assert_almost_eq(CombatPassives.threat_base_add_for_member(member), 0.0, 0.001)
	assert_almost_eq(
		float(CombatPassives.character_stat_modifiers_for_member(0).get("evasion_rate_add", -1.0)),
		0.0,
		0.001
	)
	## for_member 経由で回避を読む
	var defs: Array = CombatPassives.for_member(member)
	assert_eq(defs.size(), 1)
	assert_almost_eq(float(defs[0].get("evasion_rate_add", 0.0)), 0.18, 0.001)


func test_neri_pet_defense_mult_from_party() -> void:
	GameState.reset_for_new_game()
	var neri: Resource = Adventurer.new()
	neri.id = "gacha_helper_o"
	neri.job_id = "beast_tamer"
	neri.display_name = "ネリ"
	GameState.party_members = [neri]
	var pet_class = load("res://scripts/domain/Adventurer.gd")
	var pet = pet_class.new()
	pet.id = "pet_jack"
	GameState.active_pet = pet
	assert_almost_eq(CombatPassives.pet_outgoing_mult_from_party(), 1.25, 0.001)
	assert_almost_eq(CombatPassives.pet_defense_mult_from_party(), 1.10, 0.001)
