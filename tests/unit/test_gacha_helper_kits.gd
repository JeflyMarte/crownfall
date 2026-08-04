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
	assert_eq(str(lenore.get("status_id", "")), "vulnerable")
	assert_eq(str(lenore.get("effect", "")), "apply_status")
	var sian: Dictionary = CombatPassives.get_def("sian_silent_line")
	assert_eq(str(sian.get("status_id", "")), "mark")
	assert_almost_eq(float(sian.get("back_row_evasion_rate_add", 0.0)), 0.18, 0.001)
	assert_true(bool(sian.get("once_per_combat", false)))
	var neri: Dictionary = CombatPassives.get_def("neri_waterfowl_call")
	assert_almost_eq(float(neri.get("pet_outgoing_mult", 1.0)), 1.2, 0.001)
	assert_almost_eq(float(neri.get("pet_defense_mult", 1.0)), 1.2, 0.001)
	assert_almost_eq(float(neri.get("pet_max_hp_mult", 1.0)), 1.2, 0.001)
	assert_almost_eq(float(neri.get("pet_revive_on_combat_end_chance", 0.0)), 0.30, 0.001)
	var mirei: Dictionary = CombatPassives.get_def("mirei_swarm_resonance")
	assert_eq(str(mirei.get("status_id", "")), "poison")
	assert_eq(str(mirei.get("display_name", "")), "毒牙の共鳴")
	assert_almost_eq(float(mirei.get("pet_outgoing_mult", 1.0)), 1.5, 0.001)
	var borg: Dictionary = CombatPassives.get_def("borg_gate_voice")
	assert_eq(str(borg.get("effect", "")), "grant_self_evasion")
	assert_almost_eq(float(borg.get("evasion_add", 0.0)), 0.22, 0.001)
	assert_false(borg.has("evasion_rate_add"))
	assert_false(borg.has("threat_base_add"))


func test_empower_minor_ally_combo_weaker_than_empower() -> void:
	## 必殺コンボ用の弱鼓舞定義は維持（シアン固有からは外した）。
	assert_true(CombatCombos.ally_trigger_ids().has("empower_minor"))
	var full: Dictionary = CombatCombos.ally_rule("empower")
	var minor: Dictionary = CombatCombos.ally_rule("empower_minor")
	assert_almost_eq(float(full.get("hit_fraction", 0.0)), 0.35, 0.001)
	assert_almost_eq(float(minor.get("hit_fraction", 0.0)), 0.20, 0.001)
	assert_eq(str(minor.get("require_tag", "")), "ultimate")


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


func test_borg_combat_start_evasion_not_permanent() -> void:
	var member: Resource = Adventurer.new()
	member.id = "gacha_helper_n"
	member.job_id = "vanguard"
	assert_almost_eq(CombatPassives.threat_base_add_for_member(member), 0.0, 0.001)
	CombatPassives.reset_combat_scoped()
	GameState.party_members = [member]
	assert_almost_eq(
		float(CombatPassives.character_stat_modifiers_for_member(0).get("evasion_rate_add", -1.0)),
		0.0,
		0.001
	)
	CombatPassives.grant_combat_evasion(0, 0.22)
	assert_almost_eq(
		float(CombatPassives.character_stat_modifiers_for_member(0).get("evasion_rate_add", 0.0)),
		0.22,
		0.001
	)
	CombatPassives.reset_combat_scoped()
	var defs: Array = CombatPassives.for_member(member)
	assert_eq(defs.size(), 1)
	assert_eq(str(defs[0].get("effect", "")), "grant_self_evasion")


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
	assert_almost_eq(CombatPassives.pet_outgoing_mult_from_party(), 1.2, 0.001)
	assert_almost_eq(CombatPassives.pet_defense_mult_from_party(), 1.2, 0.001)
	assert_almost_eq(CombatPassives.pet_max_hp_mult_from_party(), 1.2, 0.001)
	var revive: Dictionary = CombatPassives.pet_revive_on_combat_end_def()
	assert_almost_eq(float(revive.get("chance", 0.0)), 0.30, 0.001)
