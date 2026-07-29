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


func test_war_banner_plan_b_outgoing_penalty() -> void:
	if GameState.party_members.is_empty():
		return
	var member: Resource = GameState.party_members[0]
	var saved_relic: String = GameState.get_equipped_relic_passive_id(member)
	GameState.owned_relics = ["relic_war_banner"]
	GameState.toggle_member_relic_passive(member, "relic_war_banner")
	var eff: Dictionary = CombatPassives.stat_multipliers_for_member(member, 0)
	assert_eq(float(eff["outgoing_mult"]), 0.85)
	var def: Dictionary = CombatPassives.get_def("relic_war_banner")
	assert_eq(str(def.get("trigger", "")), "on_kill")
	assert_eq(str(def.get("effect", "")), "apply_status")
	assert_eq(str(def.get("target", "")), "party")
	GameState.toggle_member_relic_passive(member, "")
	if not saved_relic.is_empty():
		GameState.toggle_member_relic_passive(member, saved_relic)


func test_combat_relics_effects_for_aegis_no_flat_incoming() -> void:
	var eff: Dictionary = CombatRelics.effects_for("relic_aegis_shard")
	assert_eq(float(eff["incoming_mult"]), 1.0)
	assert_eq(float(eff["outgoing_mult"]), 1.0)
	var def: Dictionary = CombatPassives.get_def("relic_aegis_shard")
	assert_eq(str(def.get("effect", "")), "taunt_and_guard")


func test_plan_b_helper_curves() -> void:
	assert_eq(CombatPassives.relic_outgoing_hp_tier_mult(-1, 0.2), 1.0)
	## 装備なしでも 1.0
	if GameState.party_members.is_empty():
		return
	var member: Resource = GameState.party_members[0]
	var saved: String = GameState.get_equipped_relic_passive_id(member)
	GameState.owned_relics = ["relic_berserker_charm", "relic_hunter_sigil", "relic_old_hourglass"]
	GameState.toggle_member_relic_passive(member, "relic_berserker_charm")
	assert_eq(CombatPassives.relic_outgoing_hp_tier_mult(0, 0.60), 1.0)
	assert_eq(CombatPassives.relic_outgoing_hp_tier_mult(0, 0.40), 1.40)
	assert_eq(CombatPassives.relic_outgoing_hp_tier_mult(0, 0.20), 1.80)
	assert_eq(CombatPassives.relic_heal_received_mult(0), 0.5)
	GameState.toggle_member_relic_passive(member, "relic_hunter_sigil")
	assert_eq(CombatPassives.relic_mark_focus_outgoing_mult(0, ["mark"]), 1.50)
	assert_eq(CombatPassives.relic_mark_focus_outgoing_mult(0, []), 0.75)
	assert_eq(CombatPassives.relic_pre_hit_status_id(0), "mark")
	GameState.toggle_member_relic_passive(member, "relic_old_hourglass")
	assert_eq(CombatPassives.relic_skill_cd_mult(0), 1.30)
	assert_eq(CombatPassives.equipped_relic_float(0, "ultimate_charge_dealt_mult", 1.0), 2.0)
	GameState.toggle_member_relic_passive(member, "")
	if not saved.is_empty():
		GameState.toggle_member_relic_passive(member, saved)


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
