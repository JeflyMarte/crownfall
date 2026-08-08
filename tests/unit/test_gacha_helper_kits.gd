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
	assert_eq(str(lenore.get("display_name", "")), "呪印の増幅")
	assert_almost_eq(float(lenore.get("outgoing_vs_status_mult", 1.0)), 1.45, 0.001)
	assert_false(lenore.has("effect"))
	assert_false(lenore.has("status_id"))
	var sian: Dictionary = CombatPassives.get_def("sian_silent_line")
	assert_eq(str(sian.get("display_name", "")), "沈黙の罠糸")
	assert_eq(str(sian.get("effect", "")), "random_enemy_status")
	assert_true(sian.get("status_pool", []).has("chill"))
	assert_true(sian.get("status_pool", []).has("slow"))
	assert_true(sian.get("status_pool", []).has("fear"))
	assert_almost_eq(float(sian.get("status_chance", 0.0)), 0.28, 0.001)
	assert_false(sian.has("back_row_evasion_rate_add"))
	var neri: Dictionary = CombatPassives.get_def("neri_waterfowl_call")
	assert_almost_eq(float(neri.get("pet_outgoing_mult", 1.0)), 1.25, 0.001)
	assert_almost_eq(float(neri.get("pet_defense_mult", 1.0)), 1.25, 0.001)
	assert_almost_eq(float(neri.get("pet_max_hp_mult", 1.0)), 1.25, 0.001)
	assert_almost_eq(float(neri.get("pet_revive_on_combat_end_chance", 0.0)), 0.25, 0.001)
	var mirei: Dictionary = CombatPassives.get_def("mirei_swarm_resonance")
	assert_eq(str(mirei.get("display_name", "")), "毒牙")
	assert_eq(str(mirei.get("effect", "")), "random_enemy_status")
	assert_true(mirei.get("status_pool", []).has("poison"))
	assert_false(mirei.has("pet_outgoing_mult"))
	var borg: Dictionary = CombatPassives.get_def("borg_gate_voice")
	assert_eq(str(borg.get("display_name", "")), "門前の応撃")
	assert_eq(str(borg.get("effect", "")), "counter_attack")
	assert_almost_eq(float(borg.get("cooldown", 0.0)), 3.5, 0.001)
	assert_false(borg.has("evasion_add"))
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


func test_borg_counter_passive_def() -> void:
	var member: Resource = Adventurer.new()
	member.id = "gacha_helper_n"
	member.job_id = "vanguard"
	var defs: Array = CombatPassives.for_member(member)
	assert_eq(defs.size(), 1)
	assert_eq(str(defs[0].get("effect", "")), "counter_attack")
	assert_eq(str(defs[0].get("trigger", "")), "on_hit_taken")
	assert_almost_eq(float(defs[0].get("cooldown", 0.0)), 3.5, 0.001)


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
	assert_almost_eq(CombatPassives.pet_defense_mult_from_party(), 1.25, 0.001)
	assert_almost_eq(CombatPassives.pet_max_hp_mult_from_party(), 1.25, 0.001)
	var revive: Dictionary = CombatPassives.pet_revive_on_combat_end_def()
	assert_almost_eq(float(revive.get("chance", 0.0)), 0.25, 0.001)
