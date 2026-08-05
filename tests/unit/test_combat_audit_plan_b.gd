extends GutTest
## P3-FIX-COMBAT-AUDIT-B-001 — コンボ／戦術／パッシブ／UI peek 回帰。

const _StatusResolver := preload("res://scripts/combat/StatusResolver.gd")
const _Adventurer := preload("res://scripts/domain/Adventurer.gd")
const _WeaponInstance := preload("res://scripts/domain/WeaponInstance.gd")


func after_each() -> void:
	GameState.party_members = []


func test_ultimate_tag_is_known_for_ally_combo() -> void:
	assert_true(CombatTags.is_known("ultimate"))
	assert_true(CombatCombos.ally_tag_eligible("empower", ["ultimate"]))
	assert_false(CombatCombos.ally_tag_eligible("empower", ["slash"]))
	var ult: Resource = DataRegistry.get_skill_data("ultimate_strike")
	assert_not_null(ult)
	assert_true("ultimate" in ult.tags)


func test_lucian_outgoing_mult_independent_of_on_attack_trigger() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "lucian_probe"
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "abyss_fangs_lucian"
	member.equipped_weapon = weapon
	GameState.party_members = [member]
	var mods: Dictionary = CombatPassives.character_stat_modifiers_for_member(0)
	assert_almost_eq(float(mods.get("outgoing_mult", 1.0)), 1.15, 0.001)
	var def: Dictionary = CombatPassives.get_def("eq_mythic_lucian")
	assert_eq(str(def.get("trigger", "")), "on_attack")


func test_burial_crown_on_kill_refund_fraction() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "crown_probe"
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "burial_crown_greatsword"
	member.equipped_weapon = weapon
	GameState.party_members = [member]
	assert_almost_eq(CombatPassives.on_kill_refund_fraction(0), 0.45, 0.001)
	assert_eq(str(CombatPassives.get_def("eq_mythic_burial_crown").get("effect", "")), "refund_ct")


func test_guaranteed_skip_peek_does_not_need_rng() -> void:
	var resolver = _StatusResolver.new()
	assert_false(resolver.has_guaranteed_action_skip("party_0"))
	assert_true(resolver.apply_status("party_0", "stun", 1, 0))
	assert_true(resolver.has_guaranteed_action_skip("party_0"))
	## Probabilistic chill must not count as guaranteed.
	assert_true(resolver.apply_status("party_1", "chill", 1, 0))
	assert_false(resolver.has_guaranteed_action_skip("party_1"))
	## Slow uses interval proxy only — not guaranteed.
	assert_true(resolver.apply_status("party_2", "slow", 1, 0))
	assert_false(resolver.has_guaranteed_action_skip("party_2"))


func test_dead_target_retargets_by_member_rule() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "retarget_probe"
	member.tactics_id = "attack_focus"
	GameState.party_members = [member]

	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.swarm_hp = [0, 40, 10]
	ctrl.swarm_max_hp = [50, 40, 50]
	ctrl.active_enemy_index = 1
	ctrl.member_target_slot = [0]
	var picked: int = ctrl.get_member_target_slot(0)
	assert_eq(picked, 2, "lowest_hp among living should win over DEFAULT front")


func test_gambit_bleed_hint_any_enemy() -> void:
	var hint: String = CombatGambit.condition_hint("enemy_has_bleed")
	assert_true(hint.contains("生存敵"))
	assert_true(CombatTactics.condition_met(
		{"condition": "enemy_has_bleed"},
		{"enemy_has_bleed": true}
	))
	assert_false(CombatTactics.condition_met(
		{"condition": "enemy_has_bleed"},
		{"enemy_has_bleed": false}
	))
