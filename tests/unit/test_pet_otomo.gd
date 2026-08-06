extends GutTest

## P3-PET-OTOMO-001 — 随伴ペット「ジャック」

const _PetSystem = preload("res://scripts/pets/PetSystem.gd")

func before_each() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		assert_true(GameState.select_starting_adventurer("adventurer_0"))
	_PetSystem.grant_starter_pet()


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
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))


func test_pet_skill_unlocks_by_level() -> void:
	## Lv1/8/16/24/32 で解放が増える。装備枠は常に1本（先頭が既定＝全体鼓舞）。
	GameState.active_pet.level = 1
	GameState.active_pet.equipped_skill_ids = [] as Array[String]
	_PetSystem.sync_pet_runtime(GameState.active_pet)
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))
	assert_eq(SkillProgression.get_pet_required_level(GameState.active_pet, "pet_jack_frenzy"), 1)

	GameState.active_pet.level = 8
	GameState.active_pet.equipped_skill_ids = [] as Array[String]
	_PetSystem.sync_pet_runtime(GameState.active_pet)
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_true(SkillProgression.get_unlocked_pet_skill_ids(GameState.active_pet).has("pet_pounce"))
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))

	GameState.active_pet.level = 32
	GameState.active_pet.equipped_skill_ids = [] as Array[String]
	_PetSystem.sync_pet_runtime(GameState.active_pet)
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_eq(SkillProgression.get_unlocked_pet_skill_ids(GameState.active_pet).size(), 5)
	assert_eq(SkillProgression.get_pet_required_level(GameState.active_pet, "pet_nibble"), 32)


func test_pet_skill_equip_toggle_at_max_level() -> void:
	GameState.active_pet.level = 99
	GameState.active_pet.equipped_skill_ids = [] as Array[String]
	_PetSystem.sync_pet_runtime(GameState.active_pet)
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))
	## 別スキルを選ぶと1枠を置換
	GameState.toggle_member_skill(GameState.active_pet, "pet_jack_savage")
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_jack_savage"))
	assert_false(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))
	## 解除できる
	GameState.toggle_member_skill(GameState.active_pet, "pet_jack_savage")
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 0)
	## normalize で解放済み先頭が戻る
	SkillProgression.normalize_equipped_skills(GameState.active_pet)
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))


func test_pet_level_up_syncs_new_skills() -> void:
	GameState.active_pet.level = 7
	GameState.active_pet.exp = LevelSystem.exp_to_next(7) - 1
	GameState.active_pet.equipped_skill_ids = [] as Array[String]
	_PetSystem.sync_pet_runtime(GameState.active_pet)
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	LevelSystem.grant_exp_to_party(1)
	assert_gte(int(GameState.active_pet.level), 8)
	## 装備は1枠のまま。解放プールに pounce が加わる
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_true(SkillProgression.get_unlocked_pet_skill_ids(GameState.active_pet).has("pet_pounce"))


func test_pet_data_and_skills_exist() -> void:
	var data: Resource = _PetSystem.get_pet_data("pet_jack")
	assert_not_null(data)
	assert_not_null(DataRegistry.get_skill_data("pet_nibble"))
	assert_not_null(DataRegistry.get_skill_data("pet_pounce"))
	assert_not_null(DataRegistry.get_skill_data("pet_jack_rend"))
	assert_not_null(DataRegistry.get_skill_data("pet_jack_frenzy"))
	assert_not_null(DataRegistry.get_skill_data("pet_jack_savage"))
	assert_false(_PetSystem.sprite_path_for(GameState.active_pet).is_empty())


func test_pet_base_stats_are_buffed_150() -> void:
	## P3-BAL-PET-SUPPORT-001: 基礎 ×1.5 → 630/105/53
	for pid: String in ["pet_jack", "pet_ash", "pet_ink"]:
		var data: Resource = _PetSystem.get_pet_data(pid)
		assert_not_null(data, pid)
		assert_eq(int(data.base_stats.hp), 630, pid)
		assert_eq(int(data.base_stats.attack), 105, pid)
		assert_eq(int(data.base_stats.defense), 53, pid)
	assert_eq(int(GameState.active_pet.base_stats.hp), 630)
	assert_eq(int(GameState.active_pet.base_stats.attack), 105)
	assert_eq(int(GameState.active_pet.base_stats.defense), 53)


func test_jack_skills_are_support_oriented() -> void:
	## Lv1全体鼓舞。回復／単体鼓舞／つなぎダメ。火力特化ではない。
	assert_eq(str(DataRegistry.get_skill_data("pet_jack_frenzy").effect_type), "buff")
	assert_eq(str(DataRegistry.get_skill_data("pet_jack_frenzy").target_type), "all_party")
	assert_eq(str(DataRegistry.get_skill_data("pet_pounce").effect_type), "heal")
	assert_eq(str(DataRegistry.get_skill_data("pet_jack_rend").effect_type), "buff")
	assert_eq(str(DataRegistry.get_skill_data("pet_jack_savage").effect_type), "heal")
	assert_eq(str(DataRegistry.get_skill_data("pet_nibble").effect_type), "damage")
	assert_eq(str(GameState.active_pet.tactics_id), "support_focus")
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))


func test_jack_basic_attack_is_melee_not_ranged() -> void:
	## 鼓舞が long でも、武器なしペットの通常攻撃は近接（前衛遠隔ペナルティを踏まない）。
	var pet_i: int = GameState.combatant_count() - 1
	assert_true(GameState.is_pet_combatant(pet_i))
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))
	assert_eq(str(DataRegistry.get_skill_data("pet_jack_frenzy").range_type), "melee")
	assert_eq(str(DataRegistry.get_skill_data("pet_jack_rend").range_type), "melee")
	assert_eq(CombatRange.resolve_member_default(pet_i), "melee")
	assert_eq(CombatRange.resolve_for_action(pet_i), "melee")
	assert_eq(GameState.formation_range_outgoing_multiplier(pet_i, "melee"), 1.0)
	assert_eq(GameState.formation_range_log_tag(pet_i, "melee"), "")
	## 万一 long と誤判定しても前衛ペナルティが付くことを回帰で明示
	assert_lt(GameState.formation_range_outgoing_multiplier(pet_i, "long"), 1.0)
	assert_true(GameState.formation_range_log_tag(pet_i, "long").contains("遠隔"))


func test_jack_portrait_icon_resolves() -> void:
	var tex: Texture2D = RosterUiHelper.get_member_portrait_texture(GameState.active_pet)
	assert_not_null(tex)
	assert_eq(RosterUiHelper.job_display_name(GameState.active_pet), "ペット")
	assert_true(ResourceLoader.exists("res://assets/ui/chr_icons/ICO_CHR_Jack.png"))


func test_pet_threat_is_at_or_below_back_row() -> void:
	## P3-BAL-PET-EVADE-THREAT-001 案C: Threat 0.6＝後列雑魚職相当以下。
	assert_almost_eq(_PetSystem.PET_THREAT_BASE, BalanceConfig.FORMATION_BACK_THREAT, 0.0001)
	assert_lte(_PetSystem.PET_THREAT_BASE, 1.0 * BalanceConfig.FORMATION_BACK_THREAT)
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc._init_party_hp()
	var pet_i: int = GameState.combatant_count() - 1
	assert_true(GameState.is_pet_combatant(pet_i))
	var pet_threat: float = cc._job_threat_base(pet_i)
	assert_almost_eq(pet_threat, 0.6, 0.0001)
	## 前列雑魚職(1.0)より低く、max_threat では人間が優先される。
	for i in GameState.party_members.size():
		if i < cc.party_threat.size():
			cc.party_threat[i] = 1.0
	if pet_i < cc.party_threat.size():
		cc.party_threat[pet_i] = pet_threat
	var target: int = cc.pick_enemy_target_member_index(-1)
	assert_ne(target, pet_i)


func test_pet_base_evasion_rate() -> void:
	assert_almost_eq(_PetSystem.PET_BASE_EVASION_RATE, 0.20, 0.0001)
	var pet_i: int = GameState.combatant_count() - 1
	assert_true(GameState.is_pet_combatant(pet_i))
	assert_almost_eq(DamageCalculator.member_evasion_rate(pet_i), 0.20, 0.0001)


func test_pet_does_not_gain_ultimate_charge() -> void:
	## ペットは必殺ゲージ対象外（P3-PET-ULT-OMIT-001）。
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc._init_party_hp()
	cc._init_member_ultimate_charge()
	var pet_i: int = GameState.combatant_count() - 1
	assert_true(GameState.is_pet_combatant(pet_i))
	cc.add_ultimate_charge(pet_i, Constants.ULTIMATE_CHARGE_MAX)
	assert_eq(cc.get_ultimate_charge(pet_i), 0.0)
	assert_false(cc.is_ultimate_charge_ready(pet_i))


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


func test_unlock_ash_on_whisperwood_survey_complete() -> void:
	assert_false(_PetSystem.owns_pet("pet_ash"))
	GameState.mark_stage_cleared("mourngate_1_5", 0)
	assert_false(_PetSystem.owns_pet("pet_ash"), "章クリアでは解放しない")
	GameState.hub_survey_progress["whisperwood"] = 100.0
	_PetSystem.sync_unlocks_from_survey_progress(false)
	assert_true(_PetSystem.owns_pet("pet_ash"))
	assert_false(_PetSystem.owns_pet("pet_ink"))


func test_unlock_ink_on_blackshore_survey_complete() -> void:
	assert_false(_PetSystem.owns_pet("pet_ink"))
	GameState.mark_stage_cleared("whisperwood_2_5", 0)
	assert_false(_PetSystem.owns_pet("pet_ink"), "章クリアでは解放しない")
	GameState.hub_survey_progress["blackshore"] = 100.0
	_PetSystem.sync_unlocks_from_survey_progress(false)
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
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_false(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))
	assert_eq(str(GameState.active_pet.tactics_id), "attack_focus")
	assert_true(_PetSystem.set_active_pet_id("pet_jack"))
	assert_eq(str(GameState.active_pet.id), "pet_jack")
	assert_eq(int(GameState.active_pet.level), 12)
	assert_eq(int(GameState.active_pet.exp), 340)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_jack_frenzy"))
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_false(GameState.active_pet.equipped_skill_ids.has("pet_jack_rend"))


func test_pet_tactics_editable_and_persists_across_switch() -> void:
	## ペットも人間と同様に行動方針を変更可。個体別に保持。
	assert_eq(GameState.get_member_tactics_id(GameState.active_pet), "support_focus")
	GameState.set_member_tactics(GameState.active_pet, "attack_focus")
	assert_eq(GameState.get_member_tactics_id(GameState.active_pet), "attack_focus")
	assert_eq(str(GameState.pet_tactics_ids.get("pet_jack", "")), "attack_focus")
	_PetSystem.unlock_pet("pet_ash", false)
	assert_true(_PetSystem.set_active_pet_id("pet_ash"))
	assert_eq(GameState.get_member_tactics_id(GameState.active_pet), "attack_focus")
	## アッシュ既定は attack_focus。別方針に変えてジャックへ戻してもジャック設定は残る。
	GameState.set_member_tactics(GameState.active_pet, "defend_focus")
	assert_true(_PetSystem.set_active_pet_id("pet_jack"))
	assert_eq(GameState.get_member_tactics_id(GameState.active_pet), "attack_focus")
	assert_true(SaveManager.save_game())
	GameState.reset_for_new_game()
	assert_true(SaveManager.load_game())
	assert_eq(str(GameState.active_pet.id), "pet_jack")
	assert_eq(GameState.get_member_tactics_id(GameState.active_pet), "attack_focus")


func test_cannot_activate_unowned_pet() -> void:
	assert_false(_PetSystem.set_active_pet_id("pet_ink"))
	assert_eq(str(GameState.active_pet.id), "pet_jack")


func test_variant_role_skills() -> void:
	## 三角: ジャック＝サポ／アッシュ＝火力／インク＝状態異常
	var ash: Resource = _PetSystem.get_pet_data("pet_ash")
	var ink: Resource = _PetSystem.get_pet_data("pet_ink")
	assert_true(ash.skill_ids.has("pet_ash_bark"))
	assert_true(ash.skill_ids.has("pet_ash_aegis"))
	assert_true(ink.skill_ids.has("pet_ink_toxin"))
	assert_true(ink.skill_ids.has("pet_ink_paralyze"))
	assert_true(ink.skill_ids.has("pet_ink_hex"))
	assert_eq(ash.skill_unlocks.size(), 5)
	assert_eq(ink.skill_unlocks.size(), 5)
	var bark: Resource = DataRegistry.get_skill_data("pet_ash_bark")
	var guard_s: Resource = DataRegistry.get_skill_data("pet_ash_guard")
	var howl: Resource = DataRegistry.get_skill_data("pet_ash_howl")
	var bulwark: Resource = DataRegistry.get_skill_data("pet_ash_bulwark")
	var aegis: Resource = DataRegistry.get_skill_data("pet_ash_aegis")
	var fang: Resource = DataRegistry.get_skill_data("pet_ink_fang")
	var snare: Resource = DataRegistry.get_skill_data("pet_ink_snare")
	var toxin: Resource = DataRegistry.get_skill_data("pet_ink_toxin")
	var para: Resource = DataRegistry.get_skill_data("pet_ink_paralyze")
	var hex_s: Resource = DataRegistry.get_skill_data("pet_ink_hex")
	assert_not_null(bark)
	assert_not_null(guard_s)
	assert_not_null(howl)
	assert_not_null(bulwark)
	assert_not_null(aegis)
	assert_not_null(fang)
	assert_not_null(snare)
	assert_not_null(toxin)
	assert_not_null(para)
	assert_not_null(hex_s)
	assert_eq(str(bark.effect_type), "damage")
	assert_eq(str(guard_s.effect_type), "damage")
	assert_eq(str(howl.effect_type), "damage")
	assert_true(howl.tags.has("vs_bleed"))
	assert_true(bulwark.tags.has("vs_mark"))
	assert_eq(str(aegis.effect_type), "damage")
	assert_eq(str(toxin.apply_status_id), "poison")
	assert_eq(str(snare.apply_status_id), "slow")
	assert_eq(str(fang.apply_status_id), "bleed")
	assert_eq(str(para.apply_status_id), "stun")
	assert_eq(str(hex_s.apply_status_id), "mark")
	assert_eq(SkillProgression.get_pet_required_level(
		_PetSystem.create_pet_adventurer("pet_ink"), "pet_ink_toxin"), 1)
	assert_eq(SkillProgression.get_pet_required_level(
		_PetSystem.create_pet_adventurer("pet_ink"), "pet_ink_paralyze"), 24)


func test_variant_skills_unlock_at_max_level() -> void:
	_PetSystem.unlock_pet("pet_ash", false)
	_PetSystem.unlock_pet("pet_ink", false)
	GameState.active_pet.level = 32
	assert_true(_PetSystem.set_active_pet_id("pet_ash"))
	assert_eq(SkillProgression.get_unlocked_pet_skill_ids(GameState.active_pet).size(), 5)
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_ash_bark"))
	assert_true(_PetSystem.set_active_pet_id("pet_ink"))
	assert_eq(SkillProgression.get_unlocked_pet_skill_ids(GameState.active_pet).size(), 5)
	assert_eq(GameState.active_pet.equipped_skill_ids.size(), 1)
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_ink_toxin"))
	assert_false(GameState.active_pet.equipped_skill_ids.has("pet_ash_bark"))


func test_variant_portrait_icons_resolve() -> void:
	_PetSystem.unlock_pet("pet_ash", false)
	_PetSystem.unlock_pet("pet_ink", false)
	_PetSystem.set_active_pet_id("pet_ash")
	assert_not_null(RosterUiHelper.get_member_portrait_texture(GameState.active_pet))
	_PetSystem.set_active_pet_id("pet_ink")
	assert_not_null(RosterUiHelper.get_member_portrait_texture(GameState.active_pet))
	assert_true(GameState.active_pet.equipped_skill_ids.has("pet_ink_toxin"))
