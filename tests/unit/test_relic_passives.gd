extends GutTest
## レリック解放型パッシブ（P3-RELIC-PASSIVE）＋尖鋭案B（P3-UX-RELIC-TACTICS-B001）。


func _make_member(id: String, job_id: String = "swordsman") -> Resource:
	var adv: Resource = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = id
	adv.job_id = job_id
	adv.rarity = 1
	return adv


func test_migrate_relic_passive_id_legacy() -> void:
	assert_eq(CombatPassives.migrate_relic_passive_id("war_banner"), "relic_war_banner")
	assert_eq(CombatPassives.migrate_relic_passive_id("relic_war_banner"), "relic_war_banner")
	assert_eq(CombatPassives.migrate_relic_passive_id(""), "")


func test_normalize_moves_relic_id_to_equipped_passives() -> void:
	var member: Resource = _make_member("relic_norm")
	member.relic_id = "war_banner"
	GameState.owned_relics = ["relic_war_banner"]
	var _relic: String = GameState.get_equipped_relic_passive_id(member)
	assert_eq(str(member.relic_id), "")
	assert_eq(GameState.get_equipped_relic_passive_id(member), "relic_war_banner")
	assert_eq(GameState.get_equipped_character_passive_ids(member).size(), 0)


func test_relic_passive_not_active_without_equip() -> void:
	var member: Resource = _make_member("relic_off")
	GameState.owned_relics = ["relic_war_banner"]
	assert_eq(GameState.get_equipped_relic_passive_id(member), "")
	var ids: Array = []
	for def in CombatPassives.for_member(member):
		ids.append(str(def.get("id", "")))
	assert_false(ids.has("relic_war_banner"))


func test_relic_passive_active_when_equipped() -> void:
	var member: Resource = _make_member("relic_on")
	GameState.owned_relics = ["relic_war_banner"]
	GameState.set_member_relic(member, "relic_war_banner")
	var ids: Array = []
	for def in CombatPassives.for_member(member):
		ids.append(str(def.get("id", "")))
	assert_true(ids.has("relic_war_banner"))


func test_toggle_relic_passive_exclusive_slot() -> void:
	var member: Resource = _make_member("relic_toggle")
	GameState.owned_relics = ["relic_war_banner", "relic_aegis_shard"]
	GameState.toggle_member_relic_passive(member, "relic_war_banner")
	assert_eq(GameState.get_equipped_relic_passive_id(member), "relic_war_banner")
	GameState.toggle_member_relic_passive(member, "relic_aegis_shard")
	assert_eq(GameState.get_equipped_relic_passive_id(member), "relic_aegis_shard")
	GameState.toggle_member_relic_passive(member, "relic_aegis_shard")
	assert_eq(GameState.get_equipped_relic_passive_id(member), "")


func test_war_banner_command_flag() -> void:
	var member: Resource = _make_member("relic_banner")
	GameState.owned_relics = ["relic_war_banner"]
	GameState.party_members = [member]
	GameState.set_member_relic(member, "relic_war_banner")
	var eff: Dictionary = CombatPassives.stat_multipliers_for_member(member, 0)
	assert_eq(float(eff["outgoing_mult"]), 1.0)
	var def: Dictionary = CombatPassives.get_def("relic_war_banner")
	assert_almost_eq(float(def.get("pet_outgoing_mult", 1.0)), 1.20, 0.001)
	assert_almost_eq(float(def.get("pet_defense_mult", 1.0)), 1.10, 0.001)
	assert_eq(str(def.get("trigger", "")), "on_kill")
	assert_eq(str(def.get("effect", "")), "party_rally")
	GameState.party_members = []
	GameState.owned_relics = []


func test_combat_relics_effects_for_aegis_redirect() -> void:
	var eff: Dictionary = CombatRelics.effects_for("relic_aegis_shard")
	assert_eq(float(eff["incoming_mult"]), 1.0)
	assert_eq(float(eff["outgoing_mult"]), 1.0)
	var def: Dictionary = CombatPassives.get_def("relic_aegis_shard")
	assert_almost_eq(float(def.get("redirect_rear_hit_chance", 0.0)), 0.40, 0.001)
	assert_eq(str(def.get("effect", "")), "")


func test_relic_remake_helper_curves() -> void:
	assert_eq(CombatPassives.relic_outgoing_hp_tier_mult(-1, 0.2), 1.0)
	var member: Resource = _make_member("relic_curves")
	GameState.party_members = [member]
	GameState.owned_relics = [
		"relic_berserker_charm", "relic_hunter_sigil", "relic_old_hourglass",
		"relic_reactive_aegis", "relic_lament_ring",
	]
	GameState.set_member_relic(member, "relic_berserker_charm")
	assert_eq(CombatPassives.relic_outgoing_hp_tier_mult(0, 0.20), 1.0)
	assert_almost_eq(float(CombatPassives.stat_multipliers_for_member(member, 0)["outgoing_mult"]), 1.0, 0.001)
	assert_eq(CombatPassives.combat_regen_defs_for_party().size(), 1)
	GameState.set_member_relic(member, "relic_hunter_sigil")
	assert_eq(CombatPassives.relic_mark_focus_outgoing_mult(0, ["mark"]), 1.25)
	assert_eq(CombatPassives.relic_mark_focus_outgoing_mult(0, []), 1.0)
	assert_eq(CombatPassives.relic_pre_hit_status_id(0), "mark")
	GameState.set_member_relic(member, "relic_old_hourglass")
	assert_eq(CombatPassives.relic_skill_cd_mult(0), 0.85)
	assert_eq(CombatPassives.equipped_relic_float(0, "ultimate_charge_dealt_mult", 1.0), 1.0)
	GameState.set_member_relic(member, "relic_reactive_aegis")
	assert_almost_eq(CombatPassives.relic_lifesteal_ratio(0), 0.08, 0.001)
	assert_almost_eq(float(CombatPassives.stat_multipliers_for_member(member, 0)["incoming_mult"]), 1.0, 0.001)
	GameState.set_member_relic(member, "relic_lament_ring")
	var save_def: Dictionary = CombatPassives.death_save_def_for_member(0)
	assert_true(bool(save_def.get("death_save_once", false)))
	assert_almost_eq(float(save_def.get("death_save_heal_max_hp_fraction", 0.0)), 0.20, 0.001)
	assert_false(save_def.has("death_save_outgoing_mult"))
	GameState.party_members = []
	GameState.owned_relics = []


func test_save_v4_migrates_relic_id_field() -> void:
	var migrated: Dictionary = SaveManager._migrate_save_data({
		"save_version": 3,
		"owned_relics": ["war_banner"],
		"roster": [{
			"id": "m1",
			"job_id": "swordsman",
			"relic_id": "aegis_shard",
			"equipped_passives": ["battle_fervor"],
		}],
	})
	assert_eq(int(migrated["save_version"]), SaveManager.SAVE_VERSION)
	assert_eq(migrated["owned_relics"], ["relic_war_banner"])
	var entry: Dictionary = migrated["roster"][0]
	assert_false(entry.has("relic_id"))
	assert_true("relic_aegis_shard" in entry["equipped_passives"])
