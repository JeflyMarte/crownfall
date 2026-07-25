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


func test_jack_portrait_icon_resolves() -> void:
	var tex: Texture2D = RosterUiHelper.get_member_portrait_texture(GameState.active_pet)
	assert_not_null(tex)
	assert_eq(RosterUiHelper.job_display_name(GameState.active_pet), "ペット")
	assert_true(ResourceLoader.exists("res://assets/ui/chr_icons/ICO_CHR_Jack.png"))


func test_pet_threat_can_be_selected_over_generic_jobs() -> void:
	## max_threat 下でも雑魚職より高く、盾より低いこと（無敵回避）。
	assert_gt(_PetSystem.PET_THREAT_BASE, 1.0)
	assert_lt(_PetSystem.PET_THREAT_BASE, 2.0)
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc._init_party_hp()
	var pet_i: int = GameState.combatant_count() - 1
	assert_true(GameState.is_pet_combatant(pet_i))
	## 人間を全員 Threat 1.0 相当（剣士/盾以外）に揃えた想定で、ペットが選ばれうる
	for i in GameState.party_members.size():
		if i < cc.party_threat.size():
			cc.party_threat[i] = 1.0
	if pet_i < cc.party_threat.size():
		cc.party_threat[pet_i] = _PetSystem.PET_THREAT_BASE
	var target: int = cc.pick_enemy_target_member_index(-1)
	assert_eq(target, pet_i)


func test_pet_takes_damage_with_base_defense() -> void:
	## party_members 外でも base DEF が被ダメ計算に乗る。
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc._init_party_hp()
	var pet_i: int = GameState.combatant_count() - 1
	assert_true(pet_i >= 0)
	## 低DEFだと乱数で mitigated が消えるため、一時的に上げて combatant 経路を検証
	var saved_def: int = int(GameState.active_pet.base_stats.defense)
	GameState.active_pet.base_stats.defense = 400
	var before: int = int(cc.party_combat_hp[pet_i])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var result: Dictionary = DamageCalculator.enemy_damage_to_member(cc, pet_i, 1.0, 200, -1, rng)
	GameState.active_pet.base_stats.defense = saved_def
	assert_false(bool(result.get("missed", false)))
	assert_gt(int(result.get("final", 0)), 0)
	assert_gt(int(result.get("mitigated", 0)), 0)
	cc.apply_damage_to_member(pet_i, int(result["final"]))
	assert_lt(int(cc.party_combat_hp[pet_i]), before)


## --- P3-PET-VARIANT-001 ---

func test_variant_pet_data_exists() -> void:
	assert_not_null(_PetSystem.get_pet_data("pet_ash"))
	assert_not_null(_PetSystem.get_pet_data("pet_ink"))
	assert_eq(str(_PetSystem.get_pet_data("pet_ash").display_name), "アッシュ")
	assert_eq(str(_PetSystem.get_pet_data("pet_ink").display_name), "インク")
	assert_true(ResourceLoader.exists("res://resources/animation/PET_Ash.tres"))
	assert_true(ResourceLoader.exists("res://resources/animation/PET_Ink.tres"))
	assert_true(ResourceLoader.exists("res://assets/ui/chr_icons/ICO_CHR_Ash.png"))
	assert_true(ResourceLoader.exists("res://assets/ui/chr_icons/ICO_CHR_Ink.png"))


func test_owned_pets_seed_with_jack_only() -> void:
	assert_true(GameState.owned_pet_ids.has("pet_jack"))
	assert_false(GameState.owned_pet_ids.has("pet_ash"))
	assert_false(GameState.owned_pet_ids.has("pet_ink"))


func test_unlock_ash_on_mourngate_1_5_clear() -> void:
	GameState.mark_stage_cleared("mourngate_1_5", 0)
	assert_true(_PetSystem.owns_pet("pet_ash"))
	assert_false(_PetSystem.owns_pet("pet_ink"))


func test_unlock_ink_on_whisperwood_2_5_clear() -> void:
	GameState.mark_stage_cleared("whisperwood_2_5", 0)
	assert_true(_PetSystem.owns_pet("pet_ink"))


func test_switch_active_pet_carries_level_exp() -> void:
	_PetSystem.unlock_pet("pet_ash", false)
	GameState.active_pet.level = 12
	GameState.active_pet.exp = 340
	assert_true(_PetSystem.set_active_pet_id("pet_ash"))
	assert_eq(str(GameState.active_pet.id), "pet_ash")
	assert_eq(str(GameState.active_pet.display_name), "アッシュ")
	assert_eq(int(GameState.active_pet.level), 12)
	assert_eq(int(GameState.active_pet.exp), 340)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_ash_bark"))
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_ash_guard"))
	assert_false(GameState.active_pet.equipped_skill_ids.has("pet_nibble"))
	assert_true(_PetSystem.set_active_pet_id("pet_jack"))
	assert_eq(str(GameState.active_pet.id), "pet_jack")
	assert_eq(int(GameState.active_pet.level), 12)
	assert_eq(int(GameState.active_pet.exp), 340)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_nibble"))


func test_cannot_activate_unowned_pet() -> void:
	assert_false(_PetSystem.set_active_pet_id("pet_ink"))
	assert_eq(str(GameState.active_pet.id), "pet_jack")


func test_variant_role_skills() -> void:
	var ash: Resource = _PetSystem.get_pet_data("pet_ash")
	var ink: Resource = _PetSystem.get_pet_data("pet_ink")
	assert_true(ash.skill_ids.has("pet_ash_bark"))
	assert_true(ash.skill_ids.has("pet_ash_guard"))
	assert_true(ink.skill_ids.has("pet_ink_fang"))
	assert_true(ink.skill_ids.has("pet_ink_snare"))
	var bark: Resource = DataRegistry.get_skill_data("pet_ash_bark")
	var guard_s: Resource = DataRegistry.get_skill_data("pet_ash_guard")
	var fang: Resource = DataRegistry.get_skill_data("pet_ink_fang")
	var snare: Resource = DataRegistry.get_skill_data("pet_ink_snare")
	assert_not_null(bark)
	assert_not_null(guard_s)
	assert_not_null(fang)
	assert_not_null(snare)
	assert_eq(str(bark.effect_type), "buff")
	assert_true(bark.tags.has("taunt"))
	assert_eq(str(bark.apply_status_id), "guard")
	assert_eq(str(guard_s.apply_status_id), "guard")
	assert_eq(str(fang.apply_status_id), "bleed")
	assert_eq(str(snare.apply_status_id), "slow")


func test_variant_portrait_icons_resolve() -> void:
	_PetSystem.unlock_pet("pet_ash", false)
	_PetSystem.unlock_pet("pet_ink", false)
	_PetSystem.set_active_pet_id("pet_ash")
	assert_not_null(RosterUiHelper.get_member_portrait_texture(GameState.active_pet))
	_PetSystem.set_active_pet_id("pet_ink")
	assert_not_null(RosterUiHelper.get_member_portrait_texture(GameState.active_pet))
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_ink_fang"))
