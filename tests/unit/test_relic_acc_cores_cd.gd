extends GutTest
## P3-BAL-RELIC-REMAKE-001 — レリック8種ルール改変＋開幕装飾の役割分離（案D維持）。

const _PetSystem = preload("res://scripts/pets/PetSystem.gd")


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
	GameState.active_pet = null


func test_scout_lens_is_treasure_compass() -> void:
	var def: Dictionary = CombatPassives.get_def("relic_scout_lens")
	assert_eq(str(def.get("display_name", "")), "宝箱の羅針")
	assert_eq(int(def.get("treasure_room_weight_add", 0)), 20)
	assert_false(def.has("outgoing_vs_status_mult"))
	assert_ne(str(def.get("effect", "")), "random_enemy_status")
	_equip_relic("relic_scout_lens")
	assert_eq(CombatPassives.party_treasure_room_weight_add(), 20)


func test_war_banner_is_command_pet_core() -> void:
	var def: Dictionary = CombatPassives.get_def("relic_war_banner")
	assert_eq(str(def.get("display_name", "")), "指揮の軍旗")
	assert_almost_eq(float(def.get("pet_outgoing_mult", 1.0)), 1.20, 0.001)
	assert_almost_eq(float(def.get("pet_defense_mult", 1.0)), 1.10, 0.001)
	assert_almost_eq(float(def.get("outgoing_mult", 1.0)), 1.0, 0.001)
	assert_eq(str(def.get("trigger", "")), "on_kill")
	assert_eq(str(def.get("effect", "")), "party_rally")
	_equip_relic("relic_war_banner")
	## pet_*_mult_from_party はペット未所持だと 1.0 固定のガードがある。
	GameState.active_pet = _PetSystem.create_pet_adventurer(_PetSystem.STARTER_PET_ID)
	assert_almost_eq(CombatPassives.pet_outgoing_mult_from_party(), 1.20, 0.001)
	assert_almost_eq(CombatPassives.pet_defense_mult_from_party(), 1.10, 0.001)


func test_hourglass_is_skill_cd_core() -> void:
	var def: Dictionary = CombatPassives.get_def("relic_old_hourglass")
	assert_eq(str(def.get("display_name", "")), "連撃の歯車")
	assert_almost_eq(float(def.get("ultimate_charge_dealt_mult", 1.0)), 1.0, 0.001)
	assert_almost_eq(float(def.get("skill_cd_mult", 1.0)), 0.85, 0.001)


func test_opening_accessories_roles_diverge() -> void:
	var royal: Dictionary = CombatPassives.get_def("eq_mourngate_royal")
	assert_almost_eq(float(royal.get("first_attack_mult", 1.0)), 1.75, 0.001)
	assert_false(royal.has("trigger"), "王家は初撃倍率（開幕小鼓舞を廃止）")
	var covenant: Dictionary = CombatPassives.get_def("eq_silvaria_covenant")
	assert_eq(str(covenant.get("effect", "")), "party_rally")
	assert_almost_eq(float(covenant.get("ultimate_charge_flat", 0.0)), 25.0, 0.001)
	assert_eq(str(covenant.get("status_id", "x")), "")
	assert_ne(str(covenant.get("status_id", "")), "empower_minor")
