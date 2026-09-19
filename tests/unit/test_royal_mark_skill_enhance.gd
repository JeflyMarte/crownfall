extends GutTest

## Decision 144 Phase 2 — Job Skill / Ultimate 王痕強化

const _RoyalMarkConfig := preload("res://scripts/systems/RoyalMarkConfig.gd")
const _RoyalMarkSkillModifier := preload("res://scripts/systems/RoyalMarkSkillModifier.gd")
const _Adventurer := preload("res://scripts/domain/Adventurer.gd")
const _Stats := preload("res://scripts/domain/Stats.gd")
const _SkillData := preload("res://scripts/data/SkillData.gd")


func before_each() -> void:
	GameState.debug_full_unlock = false
	GameState.royal_mark_shards = 0
	GameState.royal_mark_ranks = {}
	GameState.royal_mark_paths = {}
	GameState.roster.clear()
	GameState.party_members.clear()
	GameState.gold = 0
	GameState.current_dungeon_id = ""


func _set_equipped(member: Resource, skill_ids: Array) -> void:
	var ids: Array[String] = []
	for sid: Variant in skill_ids:
		ids.append(str(sid))
	member.equipped_skill_ids = ids


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


func test_rank_ii_no_skill_enhance() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 2}
	var sk: Resource = _make_skill("slash_attack", "damage", 1.45)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_eq(out, sk)
	assert_eq(float(out.power_multiplier), 1.45)


func test_rank_iii_damage_mult() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 3}
	var sk: Resource = _make_skill("slash_attack", "damage", 1.45)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_ne(out, sk)
	assert_almost_eq(float(out.power_multiplier), 1.45 * 1.10, 0.001)


func test_rank_iii_heal_mult() -> void:
	var m: Resource = _make_human("gacha_helper_c")
	m.job_id = "alchemist"
	_set_equipped(m, ["mend"])
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_c": 3}
	var sk: Resource = _make_skill("mend", "heal", 0.20)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_almost_eq(float(out.power_multiplier), 0.20 * 1.15, 0.001)


func test_rank_iii_status_chance() -> void:
	var m: Resource = _make_human("adventurer_0")
	_set_equipped(m, ["rend_slash"])
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 3}
	var sk: Resource = _make_skill("rend_slash", "damage", 1.1, "skill", "bleed", 0.80)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_eq(float(out.power_multiplier), 1.1)
	assert_almost_eq(float(out.apply_status_chance), 0.90, 0.001)


func test_rank_iii_buff_duration_meta() -> void:
	var m: Resource = _make_human("adventurer_3")
	m.job_id = "vanguard"
	_set_equipped(m, ["offensive_stance"])
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_3": 3}
	var sk: Resource = _make_skill("offensive_stance", "buff", 1.0, "skill", "empower", 1.0)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_eq(_RoyalMarkSkillModifier.duration_add_from_skill(out), 1)


func test_rank_iii_trap_power() -> void:
	var m: Resource = _make_human("gacha_helper_q")
	m.job_id = "engineer"
	_set_equipped(m, ["eng_spike_trap"])
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_q": 3}
	var sk: Resource = _make_skill(
		"eng_spike_trap", "buff", 0.65, "skill", "", 0.0, ["trap_place", "trap_spike"]
	)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_almost_eq(float(out.power_multiplier), 0.65 * 1.10, 0.001)


func test_trail_ward_excluded() -> void:
	var m: Resource = _make_human("adventurer_1")
	m.job_id = "ranger"
	_set_equipped(m, ["trail_ward"])
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_1": 5}
	var sk: Resource = _make_skill("trail_ward", "none", 1.0, "skill", "", 0.0, ["equip_passive"])
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_eq(out, sk)


func test_skill_swap_retargets() -> void:
	var m: Resource = _make_human("adventurer_0")
	_set_equipped(m, ["slash_attack"])
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 3}
	var slash: Resource = _make_skill("slash_attack", "damage", 1.45)
	var rend: Resource = _make_skill("rend_slash", "damage", 1.1, "skill", "bleed", 0.8)
	assert_ne(_RoyalMarkSkillModifier.enhance_for_combat(slash, m), slash)
	assert_eq(_RoyalMarkSkillModifier.enhance_for_combat(rend, m), rend)
	_set_equipped(m, ["rend_slash"])
	assert_eq(_RoyalMarkSkillModifier.enhance_for_combat(slash, m), slash)
	assert_ne(_RoyalMarkSkillModifier.enhance_for_combat(rend, m), rend)


func test_rank_v_keeps_skill_iii() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	var sk: Resource = _make_skill("slash_attack", "damage", 1.45)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_almost_eq(float(out.power_multiplier), 1.45 * 1.10, 0.001)


func test_rank_iv_no_ultimate_enhance() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 4}
	var ult: Resource = _make_skill("ouga_retsudan", "damage", 1.9, "ultimate", "bleed", 0.85)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_eq(out, ult)


func test_rank_v_damage_cap() -> void:
	var m: Resource = _make_human("gacha_helper_f")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_f": 5}
	var ult: Resource = _make_skill("break_edge", "damage", 3.2, "ultimate")
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_almost_eq(float(out.power_multiplier), 3.2 * 1.08, 0.001)


func test_rank_v_heal_add() -> void:
	var m: Resource = _make_human("gacha_helper_c")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_c": 5}
	var ult: Resource = _make_skill("grand_elixir", "heal", 0.20, "ultimate")
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_almost_eq(float(out.power_multiplier), 0.23, 0.001)


func test_rank_v_control_chance() -> void:
	var m: Resource = _make_human("gacha_helper_m")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_m": 5}
	var ult: Resource = _make_skill(
		"silence_web", "damage", 1.15, "ultimate", "fear", 0.70
	)
	ult.apply_status_id2 = "chill"
	ult.apply_status_chance2 = 1.0
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_eq(float(out.power_multiplier), 1.15)
	assert_almost_eq(float(out.apply_status_chance), 0.80, 0.001)


func test_rank_v_counter() -> void:
	var m: Resource = _make_human("gacha_helper_n")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_n": 5}
	var ult: Resource = _make_skill(
		"vg_gate_counter", "buff", 1.0, "ultimate", "guard_minor", 1.0, ["counter_charges_3"]
	)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_eq(_RoyalMarkSkillModifier.counter_charges_from_skill(out, 3), 4)


func test_rank_v_cascade() -> void:
	var m: Resource = _make_human("gacha_helper_q")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_q": 5}
	var ult: Resource = _make_skill(
		"eng_full_arm_cascade", "damage", 0.70, "ultimate", "", 0.0, ["eng_cascade"]
	)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_eq(_RoyalMarkSkillModifier.cascade_max_from_skill(out, 3), 4)


func test_rank_v_ab_mult() -> void:
	var m: Resource = _make_human("gacha_helper_s")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_s": 5}
	var ult: Resource = _make_skill(
		"eng_armor_gekigeki", "damage", 2.4, "ultimate", "armor_break", 1.0, ["vs_armor_break"]
	)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_almost_eq(_RoyalMarkSkillModifier.vs_armor_break_mult_from_skill(out, 1.35), 1.45, 0.001)


func test_rank_v_crit_surge_duration() -> void:
	var m: Resource = _make_human("gacha_helper_p")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_p": 5}
	var ult: Resource = _make_skill(
		"critical_storm", "damage", 2.7, "ultimate", "", 0.0, ["self_status_crit_surge"]
	)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_eq(_RoyalMarkSkillModifier.duration_add_from_skill(out), 1)
	## Decision 146: 威力最低保証
	assert_almost_eq(float(out.power_multiplier), 2.7 * 1.08, 0.001)


func test_rank_v_blood_drain_duration() -> void:
	var m: Resource = _make_human("gacha_helper_e")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_e": 5}
	var ult: Resource = _make_skill("blood_drain", "buff", 1.0, "ultimate", "blood_drain", 1.0)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_eq(_RoyalMarkSkillModifier.duration_add_from_skill(out), 1)


func test_rank_v_heartbeat_heal() -> void:
	var m: Resource = _make_human("gacha_helper_i")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"gacha_helper_i": 5}
	var ult: Resource = _make_skill(
		"heartbeat", "buff", 0.08, "ultimate", "guard", 1.0, ["party_maxhp_heal"]
	)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_almost_eq(float(out.power_multiplier), 0.10, 0.001)


func test_rank_v_attune_duration() -> void:
	var m: Resource = _make_human("adventurer_2")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_2": 5}
	var ult: Resource = _make_skill(
		"elemental_boost", "buff", 1.0, "ultimate", "elemental_attune", 1.0
	)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(ult, m)
	assert_eq(_RoyalMarkSkillModifier.duration_add_from_skill(out), 1)


func test_status_chance_cap() -> void:
	var m: Resource = _make_human("adventurer_0")
	_set_equipped(m, ["rend_slash"])
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 3}
	var sk: Resource = _make_skill("rend_slash", "damage", 1.1, "skill", "bleed", 0.97)
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_eq(float(out.apply_status_chance), 1.0)


func test_phase1_stat_mults_unchanged() -> void:
	assert_eq(_RoyalMarkConfig.hp_mult_for_rank(5), 1.08)
	assert_eq(_RoyalMarkConfig.atk_mult_for_rank(5), 1.08)
	assert_eq(_RoyalMarkConfig.def_mult_for_rank(5), 1.08)
	assert_eq(_RoyalMarkConfig.def_mult_for_rank(3), 1.03)


func test_cooldown_unchanged_by_enhance() -> void:
	var m: Resource = _make_human("adventurer_0")
	GameState.roster = [m]
	GameState.royal_mark_ranks = {"adventurer_0": 5}
	var sk: Resource = _make_skill("slash_attack", "damage", 1.45)
	sk.cooldown = 3.0
	var out: Resource = _RoyalMarkSkillModifier.enhance_for_combat(sk, m)
	assert_eq(float(out.cooldown), 3.0)
