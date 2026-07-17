extends GutTest
## パッシブ装備 UI / GameState（P3-D088 拡張）。


func _make_member(id: String, job_id: String, rarity: int) -> Resource:
	var adv: Resource = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = id
	adv.job_id = job_id
	adv.rarity = rarity
	return adv


func test_default_passives_match_legacy_pool() -> void:
	var member: Resource = _make_member("extra_2", "alchemist", 3)
	var ids: Array = []
	for pid in GameState.get_equipped_passive_ids(member):
		ids.append(pid)
	assert_eq(ids, ["field_medic"])


func test_unequip_passive_persists_empty() -> void:
	var member: Resource = _make_member("extra_3", "alchemist", 3)
	assert_eq(GameState.get_equipped_character_passive_ids(member), ["field_medic"])
	GameState.toggle_member_passive(member, "field_medic")
	assert_eq(GameState.get_equipped_character_passive_ids(member), [])
	assert_true(member.passive_slots_customized)


func test_toggle_swaps_equipped_passive() -> void:
	## P3-PASSIVE-CHAR-001 案α: 職帯は選択不可。外して再装備でトグルを検証。
	var member: Resource = _make_member("extra_2", "alchemist", 3)
	GameState.toggle_member_passive(member, "field_medic")
	assert_eq(GameState.get_equipped_passive_ids(member), [])
	GameState.toggle_member_passive(member, "field_medic")
	var ids: Array[String] = GameState.get_equipped_passive_ids(member)
	assert_eq(ids, ["field_medic"])
	var combat_ids: Array = []
	for def in CombatPassives.for_member(member):
		combat_ids.append(str(def.get("id", "")))
	assert_eq(combat_ids, ["field_medic"])


func test_selectable_pool_excludes_equipment_passives() -> void:
	var member: Resource = _make_member("extra_eq", "vanguard", 1)
	var armor_inst: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	armor_inst.armor_id = "serdion_ward_plate"
	member.equipped_armor = armor_inst
	var pool: Array[String] = CombatPassives.selectable_passive_ids(member)
	assert_false(pool.has("eq_serdion_ward"))
	assert_true(pool.has("bulwark"))
