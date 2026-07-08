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
	assert_eq(ids, ["field_medic"], "★3ティアは装備時のみ有効（既定はジョブFB）")
	var pool: Array[String] = CombatPassives.selectable_passive_ids(member)
	assert_true(pool.has("field_medic"))
	assert_true(pool.has("spare_vial"))


func test_star4_appends_star4_only() -> void:
	var member: Resource = _make_member("extra_3", "vanguard", 4)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["bulwark"], "★4ティアは装備時のみ有効（既定はジョブFB）")
	GameState.toggle_member_passive(member, "greatshield_order")
	ids = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["greatshield_order"])
	assert_false(ids.has("unyielding_stance"), "★3定義は重複付与しない")


func test_gacha_helper_keeps_own_passive_plus_tier() -> void:
	var member: Resource = _make_member("gacha_helper_a", "vanguard", 4)
	var ids: Array = _ids(CombatPassives.for_member(member))
	assert_eq(ids, ["valden_iron_oath"], "助っ人固有が既定。★4は装備で差し替え")
	assert_true(CombatPassives.selectable_passive_ids(member).has("greatshield_order"))


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


func test_party_exp_mult_from_panacea() -> void:
	var prev_party: Array = GameState.party_members.duplicate()
	var member: Resource = _make_member("extra_alch", "alchemist", 4)
	GameState.toggle_member_passive(member, "panacea_gift")
	GameState.party_members = [member]
	assert_eq(CombatPassives.party_exp_mult(), 1.10)
	GameState.party_members = prev_party
