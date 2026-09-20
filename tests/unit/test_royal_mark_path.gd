extends GutTest

## Decision 146 — 分岐型王痕（path / 排他 / migration / Ult 最低保証）

const _RoyalMarkConfig := preload("res://scripts/systems/RoyalMarkConfig.gd")
const _RoyalMarkSystem := preload("res://scripts/systems/RoyalMarkSystem.gd")
const _RoyalMarkSkillModifier := preload("res://scripts/systems/RoyalMarkSkillModifier.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _Adventurer := preload("res://scripts/domain/Adventurer.gd")
const _Stats := preload("res://scripts/domain/Stats.gd")
const _SkillData := preload("res://scripts/data/SkillData.gd")
const ROYAL_MARK_SCENE: String = "res://scenes/royal_mark/RoyalMarkScene.tscn"


func before_each() -> void:
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	GameState.dungeon_tier_cleared.clear()
	GameState.royal_mark_shards = 0
	GameState.royal_mark_ranks = {}
	GameState.royal_mark_paths = {}
	GameState.gold = 0
	GameState.roster.clear()
	GameState.party_members.clear()
	GameState.current_dungeon_id = ""
	GameState.active_pet = null


func _clear_main_normal() -> void:
	for biome_id: String in _DungeonTierConfig.MAIN_BIOME_IDS:
		GameState.mark_dungeon_cleared(biome_id)
		GameState.mark_dungeon_tier_cleared(biome_id, _DungeonTierConfig.TIER_NORMAL)


func _make_human(id: String, level: int = 50) -> Resource:
	var adv: Resource = _Adventurer.new()
	adv.id = id
	adv.display_name = id
	adv.job_id = "swordsman"
	adv.level = level
	adv.rarity = 3
	_set_equipped(adv, ["slash_attack"])
	var st: Resource = _Stats.new()
	st.hp = 800
	st.attack = 100
	st.defense = 50
	adv.base_stats = st
	return adv


func _set_equipped(member: Resource, skill_ids: Array) -> void:
	var ids: Array[String] = []
	for sid: Variant in skill_ids:
		ids.append(str(sid))
	member.equipped_skill_ids = ids


func _make_skill(
	sid: String,
	effect_type: String,
	power: float,
	slot_type: String = "skill",
	status_id: String = "",
	status_chance: float = 0.0,
	tags: Array = []
) -> Resource:
	var sk: Resource = _SkillData.new()
	sk.id = sid
	sk.display_name = sid
	sk.effect_type = effect_type
	sk.power_multiplier = power
	sk.slot_type = slot_type
	sk.apply_status_id = status_id
	sk.apply_status_chance = status_chance
	var typed_tags: Array[String] = []
	for t: Variant in tags:
		typed_tags.append(str(t))
	sk.tags = typed_tags
	return sk


## --- Rank gate / offense / defense tables ---

func test_rank_i_ii_no_path_effect() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.party_members = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 2}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_OFFENSE}
	assert_eq(_RoyalMarkSystem.offense_outgoing_mult_for_member(m), 1.0)
	assert_eq(_RoyalMarkSystem.defense_incoming_mult_for_member(m), 1.0)
	assert_eq(_RoyalMarkSystem.job_skill_mode_for_member(m), "none")


func test_offense_rank_table() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_OFFENSE}
	for pair: Array in [[3, 1.02], [4, 1.04], [5, 1.06]]:
		GameState.royal_mark_ranks = {"adventurer_0": int(pair[0])}
		assert_almost_eq(
			_RoyalMarkSystem.offense_outgoing_mult_for_member(m), float(pair[1]), 0.0001
		)


func test_defense_rank_table() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_DEFENSE}
	for pair: Array in [[3, 0.97], [4, 0.95], [5, 0.92]]:
		GameState.royal_mark_ranks = {"adventurer_0": int(pair[0])}
		assert_almost_eq(
			_RoyalMarkSystem.defense_incoming_mult_for_member(m), float(pair[1]), 0.0001
		)


func test_unselected_no_offense_defense() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_UNSELECTED}
	assert_eq(_RoyalMarkSystem.offense_outgoing_mult_for_member(m), 1.0)
	assert_eq(_RoyalMarkSystem.defense_incoming_mult_for_member(m), 1.0)


func test_offense_stacks_on_outgoing_common_path() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.party_members = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_OFFENSE}
	var enemy: Resource = load("res://scripts/data/EnemyData.gd").new()
	enemy.id = "probe"
	enemy.max_hp = 100
	enemy.attack = 8
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	var with_off: float = cc.get_member_outgoing_damage_multiplier(0)
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_DEFENSE}
	var without: float = cc.get_member_outgoing_damage_multiplier(0)
	assert_almost_eq(with_off / without, 1.06, 0.001)


func test_defense_stacks_on_incoming_common_path() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.party_members = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_DEFENSE}
	var enemy: Resource = load("res://scripts/data/EnemyData.gd").new()
	enemy.id = "probe"
	enemy.max_hp = 100
	enemy.attack = 8
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	var with_def: float = cc.get_member_incoming_damage_multiplier(0)
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_OFFENSE}
	var without: float = cc.get_member_incoming_damage_multiplier(0)
	assert_almost_eq(with_def / without, 0.92, 0.001)


func test_pet_no_offense() -> void:
	var pet: Resource = _Adventurer.new()
	pet.id = "pet_jack"
	pet.display_name = "ジャック"
	pet.level = 99
	GameState.roster = [pet]
	GameState.royal_mark_ranks = {"pet_jack": 5}
	GameState.royal_mark_paths = {"pet_jack": _RoyalMarkConfig.PATH_OFFENSE}
	assert_eq(_RoyalMarkSystem.offense_outgoing_mult_for_member(pet), 1.0)


## --- Exclusive job skill ---

func test_unselected_legacy_job_enhance() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 3}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_UNSELECTED}
	assert_eq(_RoyalMarkSystem.job_skill_mode_for_member(m), "legacy")
	var sk: Resource = _make_skill("slash_attack", "damage", 1.45)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_almost_eq(float(out.power_multiplier), 1.45 * 1.10, 0.001)


func test_offense_no_job_enhance() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_OFFENSE}
	assert_eq(_RoyalMarkSystem.job_skill_mode_for_member(m), "none")
	var sk: Resource = _make_skill("slash_attack", "damage", 1.45)
	assert_eq(_RoyalMarkSkillModifier.enhance_for_combat(sk, m), sk)


func test_defense_no_job_enhance() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 4}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_DEFENSE}
	assert_eq(_RoyalMarkSystem.job_skill_mode_for_member(m), "none")
	var sk: Resource = _make_skill("slash_attack", "damage", 1.45)
	assert_eq(_RoyalMarkSkillModifier.enhance_for_combat(sk, m), sk)


func test_technique_damage_iv_v() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_TECHNIQUE}
	GameState.royal_mark_ranks = {"adventurer_0": 3}
	var sk: Resource = _make_skill("slash_attack", "damage", 1.0)
	assert_almost_eq(
		float(_RoyalMarkSkillModifier.enhance_for_combat(sk, m).power_multiplier), 1.10, 0.001
	)
	GameState.royal_mark_ranks = {"adventurer_0": 4}
	assert_almost_eq(
		float(_RoyalMarkSkillModifier.enhance_for_combat(sk, m).power_multiplier), 1.15, 0.001
	)
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	assert_almost_eq(
		float(_RoyalMarkSkillModifier.enhance_for_combat(sk, m).power_multiplier), 1.20, 0.001
	)


func test_technique_heal_trap_status_buff() -> void:
	## heal
	var healer: Resource = _make_human("gacha_helper_c")
	healer.job_id = "alchemist"
	_set_equipped(healer, ["mend"])
	GameState.roster = [healer]
	GameState.royal_mark_ranks = {"gacha_helper_c": 5}
	GameState.royal_mark_paths = {"gacha_helper_c": _RoyalMarkConfig.PATH_TECHNIQUE}
	var heal: Resource = _make_skill("mend", "heal", 1.0)
	assert_almost_eq(
		float(_RoyalMarkSkillModifier.enhance_for_combat(heal, healer).power_multiplier), 1.25, 0.001
	)
	## trap
	var eng: Resource = _make_human("gacha_helper_q")
	eng.job_id = "engineer"
	_set_equipped(eng, ["eng_spike_trap"])
	GameState.roster = [eng]
	GameState.royal_mark_ranks = {"gacha_helper_q": 5}
	GameState.royal_mark_paths = {"gacha_helper_q": _RoyalMarkConfig.PATH_TECHNIQUE}
	var trap: Resource = _make_skill(
		"eng_spike_trap", "buff", 1.0, "skill", "", 0.0, ["trap_place"]
	)
	assert_almost_eq(
		float(_RoyalMarkSkillModifier.enhance_for_combat(trap, eng).power_multiplier), 1.20, 0.001
	)
	## status+damage dual forbid
	var m: Resource = _make_human("adventurer_0")
	_set_equipped(m, ["rend_slash"])
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_TECHNIQUE}
	var status_sk: Resource = _make_skill("rend_slash", "damage", 1.1, "skill", "bleed", 0.50)
	var status_out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(status_sk, m)
	assert_eq(float(status_out.power_multiplier), 1.1)
	assert_almost_eq(float(status_out.apply_status_chance), 0.70, 0.001)
	## buff duration
	var vg: Resource = _make_human("adventurer_3")
	vg.job_id = "vanguard"
	_set_equipped(vg, ["offensive_stance"])
	GameState.roster = [vg]
	GameState.royal_mark_ranks = {"adventurer_3": 5}
	GameState.royal_mark_paths = {"adventurer_3": _RoyalMarkConfig.PATH_TECHNIQUE}
	var buff: Resource = _make_skill("offensive_stance", "buff", 1.0, "skill", "empower", 1.0)
	assert_eq(
		_RoyalMarkSkillModifier.duration_add_from_skill(
			_RoyalMarkSkillModifier.enhance_for_combat(buff, vg)
		),
		1
	)


func test_technique_status_damage_no_double() -> void:
	var m: Resource = _make_human("adventurer_0")
	_set_equipped(m, ["rend_slash"])
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_TECHNIQUE}
	var sk: Resource = _make_skill("rend_slash", "damage", 1.5, "skill", "bleed", 0.40)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_eq(float(out.power_multiplier), 1.5)
	assert_almost_eq(float(out.apply_status_chance), 0.60, 0.001)


func test_technique_excludes_weapon_and_trail_ward() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_TECHNIQUE}
	_set_equipped(m, ["slash_attack"])
	var wpn: Resource = _make_skill("wpn_slash", "damage", 2.0, "weapon")
	assert_eq(_RoyalMarkSkillModifier.enhance_for_combat(wpn, m), wpn)
	_set_equipped(m, ["trail_ward"])
	var tw: Resource = _make_skill("trail_ward", "none", 1.0, "skill", "", 0.0, ["equip_passive"])
	assert_eq(_RoyalMarkSkillModifier.enhance_for_combat(tw, m), tw)


func test_cannot_return_to_unselected() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 3}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_OFFENSE}
	var bad: Dictionary = _RoyalMarkSystem.apply_path(m, _RoyalMarkConfig.PATH_UNSELECTED)
	assert_false(bool(bad.get("ok", true)))
	assert_eq(_RoyalMarkSystem.path_of_member(m), _RoyalMarkConfig.PATH_OFFENSE)


func test_path_change_free_and_dungeon_lock() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 3}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_UNSELECTED}
	var shards_before: int = _RoyalMarkSystem.get_shards()
	var gold_before: int = int(GameState.gold)
	## current_dungeon_id は選択中DG（拠点でも非空）→ ロックしない
	GameState.current_dungeon_id = "mourngate"
	var ok: Dictionary = _RoyalMarkSystem.apply_path(m, _RoyalMarkConfig.PATH_TECHNIQUE)
	assert_true(bool(ok.get("ok", false)), str(ok))
	assert_eq(_RoyalMarkSystem.get_shards(), shards_before)
	assert_eq(int(GameState.gold), gold_before)
	assert_true(_RoyalMarkSystem.is_path_change_allowed())


func test_path_change_allowed_ignores_selected_dungeon_id() -> void:
	GameState.current_dungeon_id = "mourngate"
	assert_true(_RoyalMarkSystem.is_path_change_allowed())
	GameState.current_dungeon_id = ""
	assert_true(_RoyalMarkSystem.is_path_change_allowed())

## --- Migration ---

func test_v18_to_v19_paths_unselected() -> void:
	var data: Dictionary = {
		"save_version": 18,
		"royal_mark_shards": 40,
		"royal_mark_ranks": {
			"adventurer_0": 2,
			"adventurer_1": 3,
			"adventurer_2": 4,
			"adventurer_3": 5,
		},
	}
	data = SaveManager._migrate_save_data(data)
	assert_eq(int(data.get("save_version", 0)), 20)
	## v20 で所持×10
	assert_eq(int(data.get("royal_mark_shards", 0)), 400)
	var paths: Dictionary = data.get("royal_mark_paths", {})
	assert_false(paths.has("adventurer_0"))
	assert_eq(str(paths.get("adventurer_1", "")), _RoyalMarkConfig.PATH_UNSELECTED)
	assert_eq(str(paths.get("adventurer_2", "")), _RoyalMarkConfig.PATH_UNSELECTED)
	assert_eq(str(paths.get("adventurer_3", "")), _RoyalMarkConfig.PATH_UNSELECTED)


func test_migration_invalid_path_sanitize() -> void:
	var data: Dictionary = {
		"save_version": 18,
		"royal_mark_ranks": {"adventurer_0": 5},
		"royal_mark_paths": {"adventurer_0": "bogus"},
	}
	data = SaveManager._migrate_save_data(data)
	assert_eq(str(data["royal_mark_paths"]["adventurer_0"]), _RoyalMarkConfig.PATH_UNSELECTED)


func test_migration_preserves_selected_path() -> void:
	var data: Dictionary = {
		"save_version": 20,
		"royal_mark_ranks": {"adventurer_0": 5},
		"royal_mark_paths": {"adventurer_0": "technique"},
		"royal_mark_shards": 400,
	}
	data = SaveManager._migrate_save_data(data)
	assert_eq(str(data["royal_mark_paths"]["adventurer_0"]), _RoyalMarkConfig.PATH_TECHNIQUE)
	assert_eq(int(data.get("royal_mark_shards", 0)), 400)


func test_unselected_keeps_v_ultimate() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_UNSELECTED}
	var ult: Resource = _make_skill("ouga_retsudan", "damage", 1.9, "ultimate")
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_almost_eq(float(out.power_multiplier), 1.9 * 1.08, 0.001)


func test_select_path_drops_legacy_iii() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 3}
	GameState.royal_mark_paths = {"adventurer_0": _RoyalMarkConfig.PATH_UNSELECTED}
	var sk: Resource = _make_skill("slash_attack", "damage", 1.0)
	assert_almost_eq(
		float(_RoyalMarkSkillModifier.enhance_for_combat(sk, m).power_multiplier), 1.10, 0.001
	)
	_clear_main_normal()
	_RoyalMarkSystem.apply_path(m, _RoyalMarkConfig.PATH_OFFENSE)
	assert_eq(_RoyalMarkSkillModifier.enhance_for_combat(sk, m), sk)


## --- Ultimate 146 ---

func test_ult_renol_curse_burst_damage() -> void:
	var m: Resource = _make_human("gacha_helper_l")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_l": 5}
	var ult: Resource = _make_skill("curse_burst", "damage", 2.0, "ultimate", "curse", 0.85)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_almost_eq(float(out.power_multiplier), 2.0 * 1.08, 0.001)
	assert_eq(float(out.apply_status_chance), 0.85)


func test_ult_firehawk_crit_storm_damage_and_duration() -> void:
	var m: Resource = _make_human("gacha_helper_p")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_p": 5}
	var ult: Resource = _make_skill(
		"critical_storm", "damage", 2.7, "ultimate", "", 0.0, ["self_status_crit_surge"]
	)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_eq(_RoyalMarkSkillModifier.duration_add_from_skill(out), 1)
	assert_almost_eq(float(out.power_multiplier), 2.7 * 1.08, 0.001)


func test_ult_mirei_unchanged_generic_path() -> void:
	## ミレイは override 無し（Decision 146）。generic damage+status 規則を維持。
	var ov: Dictionary = _RoyalMarkConfig.ultimate_override_for("flame_burst")
	assert_true(ov.is_empty())


## --- UI ---

func test_ui_path_hidden_below_iii() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_ranks = {"adventurer_aldric": 2}
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_false(scene.get_path_panel_visible_for_test())


func test_ui_unselected_prompt() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_ranks = {"adventurer_aldric": 3}
	GameState.royal_mark_paths = {"adventurer_aldric": _RoyalMarkConfig.PATH_UNSELECTED}
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene.get_path_panel_visible_for_test())
	assert_true(scene.get_path_current_text_for_test().find("未選択") >= 0)


func test_ui_selected_and_excluded_warning() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	a.job_id = "ranger"
	_set_equipped(a, ["trail_ward"])
	GameState.roster = [a]
	GameState.royal_mark_ranks = {"adventurer_aldric": 5}
	GameState.royal_mark_paths = {"adventurer_aldric": _RoyalMarkConfig.PATH_TECHNIQUE}
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene.get_path_current_text_for_test().find("技巧") >= 0)
	assert_true(scene.get_path_excluded_text_for_test().find("技巧強化の対象外") >= 0)


func test_ui_v_max_keeps_path_panel() -> void:
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_ranks = {"adventurer_aldric": 5}
	GameState.royal_mark_paths = {"adventurer_aldric": _RoyalMarkConfig.PATH_OFFENSE}
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene.get_max_panel_visible_for_test())
	assert_true(scene.get_path_panel_visible_for_test())


func test_ui_hub_path_buttons_enabled_with_selected_dungeon() -> void:
	## 拠点で current_dungeon_id が残っていても方針ボタンは有効（誤ロック回帰防止）
	_clear_main_normal()
	var a: Resource = _make_human("adventurer_aldric", 50)
	GameState.roster = [a]
	GameState.royal_mark_ranks = {"adventurer_aldric": 3}
	GameState.royal_mark_paths = {"adventurer_aldric": _RoyalMarkConfig.PATH_OFFENSE}
	GameState.current_dungeon_id = "mourngate"
	var scene: Node = load(ROYAL_MARK_SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene.get_path_panel_visible_for_test())
	assert_false(scene.get_path_buttons_disabled_for_test())
