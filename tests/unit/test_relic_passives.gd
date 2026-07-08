extends GutTest
## レリック解放型パッシブ（P3-RELIC-PASSIVE・案A）。


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


func test_stat_multipliers_front_row_only() -> void:
	if GameState.party_members.is_empty():
		return
	var member: Resource = GameState.party_members[0]
	var saved_row: int = member.formation_row
	var saved_relic: String = GameState.get_equipped_relic_passive_id(member)
	GameState.owned_relics = ["relic_war_banner"]
	GameState.toggle_member_relic_passive(member, "relic_war_banner")
	member.formation_row = GameState.FORMATION_FRONT
	var front: Dictionary = CombatPassives.stat_multipliers_for_member(member, 0)
	assert_eq(float(front["outgoing_mult"]), 1.10)
	member.formation_row = GameState.FORMATION_BACK
	var back: Dictionary = CombatPassives.stat_multipliers_for_member(member, 0)
	assert_eq(float(back["outgoing_mult"]), 1.0)
	member.formation_row = saved_row
	GameState.toggle_member_relic_passive(member, "")
	if not saved_relic.is_empty():
		GameState.toggle_member_relic_passive(member, saved_relic)


func test_combat_relics_effects_for() -> void:
	var eff: Dictionary = CombatRelics.effects_for("relic_aegis_shard")
	assert_eq(float(eff["incoming_mult"]), 0.90)
	assert_eq(float(eff["outgoing_mult"]), 1.0)


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
