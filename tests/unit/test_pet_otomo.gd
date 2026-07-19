extends GutTest

## P3-PET-OTOMO-001 — 随伴オトモ「ジャック」

const _PetSystem = preload("res://scripts/pets/PetSystem.gd")

func before_each() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		assert_true(GameState.select_starting_adventurer("adventurer_0"))


func test_jack_exists_outside_party() -> void:
	assert_not_null(GameState.active_pet)
	assert_eq(str(GameState.active_pet.id), "pet_jack")
	assert_eq(str(GameState.active_pet.display_name), "ジャック")
	assert_eq(int(GameState.active_pet.rarity), 1)
	for m in GameState.party_members:
		assert_ne(str(m.id), "pet_jack")
	for m in GameState.roster:
		assert_ne(str(m.id), "pet_jack")


func test_jack_in_combatants_as_fifth() -> void:
	var combatants: Array = GameState.get_combatants()
	assert_eq(combatants.size(), GameState.party_members.size() + 1)
	var last: Resource = combatants[combatants.size() - 1]
	assert_eq(str(last.id), "pet_jack")
	assert_true(GameState.is_pet_combatant(combatants.size() - 1))
	assert_eq(GameState.get_combatant_formation_slot(combatants.size() - 1), _PetSystem.PET_FORMATION_SLOT)
	assert_false(GameState.is_member_back_row(combatants.size() - 1))


func test_wipeout_ignores_pet_only() -> void:
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc._init_party_hp()
	var pet_i: int = GameState.combatant_count() - 1
	assert_true(pet_i >= 0)
	## 人間を全滅させ、ペットだけ残す
	for i in GameState.party_members.size():
		if i < cc.party_combat_hp.size():
			cc.party_combat_hp[i] = 0
	if pet_i < cc.party_combat_hp.size():
		cc.party_combat_hp[pet_i] = maxi(1, cc.party_max_hp[pet_i])
	assert_true(cc.is_party_wiped())


func test_grant_exp_includes_pet() -> void:
	var before_lv: int = int(GameState.active_pet.level)
	var before_exp: int = int(GameState.active_pet.exp)
	var result: Dictionary = LevelSystem.grant_exp_to_party(50)
	assert_true(result.has("pet_jack") or int(GameState.active_pet.exp) > before_exp or int(GameState.active_pet.level) > before_lv)


func test_pet_skills_survive_normalize() -> void:
	SkillProgression.normalize_equipped_skills(GameState.active_pet)
	assert_gt(GameState.active_pet.equipped_skill_ids.size(), 0)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_nibble"))


func test_pet_data_and_skills_exist() -> void:
	var data: Resource = _PetSystem.get_pet_data("pet_jack")
	assert_not_null(data)
	assert_not_null(DataRegistry.get_skill_data("pet_nibble"))
	assert_not_null(DataRegistry.get_skill_data("pet_pounce"))
	assert_false(_PetSystem.sprite_path_for(GameState.active_pet).is_empty())
