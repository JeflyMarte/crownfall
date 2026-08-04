extends GutTest
## CombatPassives の解決ロジック（P3-D155 / P3-PASSIVE-CHAR-001）。


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
	var member: Resource = _make_member("adventurer_0", "swordsman", Adventurer.STARTER_RARITY)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["ald_royal_flame"], "基本ロスターはキャラ固有のみ（ティア追加なし）")


func test_low_rarity_gets_job_fallback_only() -> void:
	var member: Resource = _make_member("extra_1", "ranger", 2)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["foresight"], "★2以下はジョブフォールバックのみ")


func test_star3_no_auto_tier_passive() -> void:
	var member: Resource = _make_member("extra_2", "alchemist", 3)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["field_medic"], "案α: 職帯は自動付与しない")
	var pool: Array[String] = CombatPassives.selectable_passive_ids(member)
	assert_true(pool.has("field_medic"))
	assert_false(pool.has("spare_vial"), "職帯は選択プール外")


func test_star4_no_auto_tier_passive() -> void:
	var member: Resource = _make_member("extra_3", "vanguard", 4)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["bulwark"], "案α: ★4職帯も自動付与しない")
	assert_false(CombatPassives.selectable_passive_ids(member).has("greatshield_order"))


func test_gacha_helper_keeps_own_passive_only() -> void:
	var member: Resource = _make_member("gacha_helper_a", "vanguard", 4)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["valden_iron_oath"], "助っ人固有のみ（職帯なし）")
	assert_false(CombatPassives.selectable_passive_ids(member).has("greatshield_order"))


func test_hodaka_action_skip_chance() -> void:
	var member: Resource = _make_member("gacha_helper_p", "swordsman", 4)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["hodaka_blood_price"])
	assert_almost_eq(CombatPassives.action_skip_chance_for_member(member), 0.20, 0.001)
	assert_eq(CombatPassives.action_skip_label_for_member(member), "血潮の代償")
	var plain: Resource = _make_member("adventurer_0", "swordsman", Adventurer.STARTER_RARITY)
	assert_almost_eq(CombatPassives.action_skip_chance_for_member(plain), 0.0, 0.001)


func test_all_tier_passive_defs_exist() -> void:
	for job in ["swordsman", "ranger", "alchemist", "vanguard", "beast_tamer"]:
		assert_false(CombatPassives.tier_def_for(job, 3).is_empty(), "★3定義あり: " + job)
		assert_false(CombatPassives.tier_def_for(job, 4).is_empty(), "★4定義あり: " + job)
	assert_true(CombatPassives.tier_def_for("swordsman", 2).is_empty(), "★2は定義なし")


func test_equipped_legendary_gear_appends_passives() -> void:
	var member: Resource = _make_member("extra_eq", "vanguard", 1)
	var armor_inst: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	armor_inst.armor_id = "serdion_ward_plate"
	member.equipped_armor = armor_inst
	var acc_inst: Resource = load("res://scripts/domain/AccessoryInstance.gd").new()
	acc_inst.accessory_id = "mourngate_royal_seal"
	member.equipped_accessory = acc_inst
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_true(ids.has("bulwark"), "ジョブFB維持")
	assert_true(ids.has("eq_serdion_ward"), "防具レジェンド passive")
	assert_true(ids.has("eq_mourngate_royal"), "装飾レジェンド passive")


func test_combat_loadout_log_entries_match_for_member() -> void:
	var member: Resource = _make_member("extra_eq", "vanguard", 1)
	var armor_inst: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	armor_inst.armor_id = "serdion_ward_plate"
	member.equipped_armor = armor_inst
	var passive_ids: Array = _ids(CombatPassives.for_member(member))
	var log_names: Array = []
	for entry in CombatPassives.combat_loadout_log_entries(member):
		log_names.append(str(entry.get("name", "")))
	assert_eq(log_names.size(), passive_ids.size())
	for def in CombatPassives.for_member(member):
		assert_true(log_names.has(str(def.get("display_name", ""))))


func test_passive_v2_job_stat_mods() -> void:
	var foresight: Dictionary = CombatPassives.get_def("foresight")
	assert_eq(float(foresight.get("evasion_rate_add", 0.0)), 0.20)
	var fervor: Dictionary = CombatPassives.get_def("battle_fervor")
	assert_eq(float(fervor.get("first_attack_mult", 1.0)), 2.0)
	var doctrine: Dictionary = CombatPassives.get_def("royal_sword_doctrine")
	assert_eq(float(doctrine.get("ultimate_power_mult", 1.0)), 1.50)
	var bulwark: Dictionary = CombatPassives.get_def("bulwark")
	assert_eq(str(bulwark.get("effect", "")), "counter_attack")


func test_character_stat_modifiers_aggregate() -> void:
	var prev_party: Array = GameState.party_members.duplicate()
	var member: Resource = _make_member("extra_ranger", "ranger", 2)
	GameState.party_members = [member]
	var mods: Dictionary = CombatPassives.character_stat_modifiers_for_member(0)
	assert_eq(float(mods.get("evasion_rate_add", 0.0)), 0.20)
	GameState.party_members = prev_party


func test_starter_and_gacha_passive_redesign() -> void:
	var ald: Dictionary = CombatPassives.get_def("ald_royal_flame")
	assert_eq(str(ald.get("status_id", "")), "bleed")
	assert_eq(float(ald.get("status_chance", 0.0)), 0.25)
	assert_false(ald.has("outgoing_mult"), "平与ダメはスキル核寄せで廃止")
	var riva: Dictionary = CombatPassives.get_def("riva_lone_focus")
	assert_eq(str(riva.get("status_id", "")), "mark")
	assert_eq(float(riva.get("status_chance", 0.0)), 0.25)
	assert_eq(str(riva.get("display_name", "")), "狙印の刻")
	var elias: Dictionary = CombatPassives.get_def("elias_field_elixir")
	assert_eq(str(elias.get("trigger", "")), "on_combat_start")
	assert_eq(str(elias.get("target", "")), "most_injured")
	assert_eq(float(elias.get("heal_max_hp_fraction", 0.0)), 0.30)
	var galen: Dictionary = CombatPassives.get_def("galen_sacred_bastion")
	assert_eq(float(galen.get("incoming_mult", 0.0)), 0.90)
	assert_eq(float(galen.get("threat_base_add", 0.0)), 80.0)
	assert_ne(str(galen.get("effect", "")), "counter_attack")
	var kaida: Dictionary = CombatPassives.get_def("kaida_arena_edge")
	assert_eq(str(kaida.get("display_name", "")), "一閃の賭け")
	assert_almost_eq(float(kaida.get("first_attack_mult", 1.0)), 1.75, 0.001)
	assert_false(kaida.has("outgoing_mult"))
	var ivar: Dictionary = CombatPassives.get_def("ivar_trail_sight")
	assert_true(bool(ivar.get("exploration_damage_immune", false)))
	assert_eq(float(ivar.get("exploration_damage_party_mult", 1.0)), 0.5)
	var garm: Dictionary = CombatPassives.get_def("garm_caravan_guard")
	assert_eq(float(garm.get("death_save_chance", 0.0)), 0.10)
	var serin: Dictionary = CombatPassives.get_def("serin_quick_mend")
	assert_eq(str(serin.get("trigger", "")), "on_action_start")
	assert_eq(str(serin.get("condition", "")), "ally_hp_below")
	assert_eq(str(serin.get("target", "")), "most_injured")
	assert_eq(float(serin.get("heal_max_hp_fraction", 0.0)), 0.25)
	assert_true(bool(serin.get("once_per_combat", false)))
	var mira: Dictionary = CombatPassives.get_def("mira_beast_call")
	assert_eq(str(mira.get("status_id", "")), "chill")
	assert_eq(float(mira.get("status_chance", 0.0)), 0.20)
	assert_almost_eq(float(mira.get("pet_heal_on_action_max_hp_fraction", 0.0)), 0.10, 0.001)
	var whistle: Dictionary = CombatPassives.get_def("tamer_whistle")
	assert_eq(str(whistle.get("status_id", "")), "chill")
	var valden: Dictionary = CombatPassives.get_def("valden_iron_oath")
	assert_eq(float(valden.get("party_incoming_mult", 0.0)), 0.90)
	assert_false(valden.has("passive_condition"))
	assert_eq(str(valden.get("effect", "")), "heal")
	assert_eq(str(valden.get("trigger", "")), "on_hit_taken")
	assert_almost_eq(float(valden.get("heal_max_hp_fraction", 0.0)), 0.10, 0.001)
	assert_eq(str(valden.get("display_name", "")), "鉄誓の壁")


func test_kaida_first_attack_mult() -> void:
	var kaida: Dictionary = CombatPassives.get_def("kaida_arena_edge")
	assert_eq(str(kaida.get("display_name", "")), "一閃の賭け")
	assert_almost_eq(float(kaida.get("first_attack_mult", 1.0)), 1.75, 0.001)
	assert_false(kaida.has("outgoing_mult"))
	var prev_party: Array = GameState.party_members.duplicate()
	var member: Resource = _make_member("gacha_helper_f", "swordsman", 2)
	GameState.party_members = [member]
	var mods: Dictionary = CombatPassives.character_stat_modifiers_for_member(0)
	assert_almost_eq(float(mods.get("first_attack_mult", 1.0)), 1.75, 0.001)
	assert_almost_eq(float(mods.get("outgoing_mult", 1.0)), 1.0, 0.001)
	GameState.party_members = prev_party


func test_ivar_exploration_immunity_flag() -> void:
	var member: Resource = _make_member("gacha_helper_b", "ranger", 2)
	assert_true(CombatPassives.member_ignores_exploration_damage(member))
	assert_eq(float(CombatPassives.exploration_damage_party_mult_for_member(member)), 0.5)
	var ivar_def: Dictionary = CombatPassives.get_def("ivar_trail_sight")
	assert_eq(float(ivar_def.get("exploration_damage_party_mult", 1.0)), 0.5)
	var prev_party: Array = GameState.party_members.duplicate()
	GameState.party_members = [member]
	assert_eq(float(CombatPassives.party_exploration_damage_mult()), 0.5)
	GameState.party_members = prev_party


func test_star1_omitted_helper_passives() -> void:
	var leon: Dictionary = CombatPassives.get_def("leon_sword_focus")
	assert_eq(float(leon.get("outgoing_vs_status_mult", 0.0)), 1.25)
	var durante: Dictionary = CombatPassives.get_def("durante_vial_echo")
	assert_eq(str(durante.get("effect", "")), "chance_cast_equipped_skill")
	assert_eq(float(durante.get("status_chance", 0.0)), 0.10)
	var helper_h: Resource = DataRegistry.get_gacha_helper_data("helper_h")
	assert_not_null(helper_h)
	assert_eq(str(helper_h.passive_id), "durante_vial_echo")
	var member: Resource = _make_member("gacha_helper_d", "swordsman", 1)
	GameState.party_members = [member]
	assert_eq(CombatPassives.outgoing_vs_status_mult_for_member(0), 1.25)
