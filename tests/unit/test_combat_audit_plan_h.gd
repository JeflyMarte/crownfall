extends GutTest
## P3-FIX-COMBAT-AUDIT-H-001 — shock/ignite をデバフ集合へ（与ダメ・標的・連携武装）。

const _EnemyData = preload("res://scripts/data/EnemyData.gd")
const _Adventurer = preload("res://scripts/domain/Adventurer.gd")
const _WeaponInstance = preload("res://scripts/domain/WeaponInstance.gd")


func after_each() -> void:
	GameState.party_members = []
	GameState.active_pet = null


func test_debuff_status_ids_include_shock_and_ignite() -> void:
	assert_true(CombatController.DEBUFF_STATUS_IDS.has("shock"))
	assert_true(CombatController.DEBUFF_STATUS_IDS.has("ignite"))
	assert_true(CombatLinks.is_debuff_mark_status("shock"))
	assert_true(CombatLinks.is_debuff_mark_status("ignite"))
	assert_true(CombatLinks.is_debuff_mark_status("chill"))


func test_enemy_slot_has_debuff_detects_shock() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "debuff_probe"
	member.job_id = "mage"
	GameState.party_members = [member]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "shock_target"
	enemy.max_hp = 80
	enemy.attack = 10
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	assert_false(cc.enemy_slot_has_debuff(0))
	assert_true(cc.apply_status_to_enemy_slot(0, "shock", 1, 10))
	assert_true(cc.enemy_slot_has_debuff(0))


func test_outgoing_vs_shock_applies_through_damage_multiplier() -> void:
	## 沼断ちの雷勢: shock 敵へ +40%。present_statuses が DEBUFF 集合経由で集まること。
	var member: Resource = _Adventurer.new()
	member.id = "thunder_probe"
	member.job_id = "mage"
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "volgrave_thunderblade"
	member.equipped_weapon = weapon
	GameState.party_members = [member]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "shock_mob"
	enemy.max_hp = 100
	enemy.attack = 8
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	var base: float = cc.get_member_outgoing_damage_multiplier(0, "", false, "", 0)
	assert_true(cc.apply_status_to_enemy_slot(0, "shock", 1, 10))
	var boosted: float = cc.get_member_outgoing_damage_multiplier(0, "", false, "", 0)
	assert_almost_eq(boosted / base, 1.40, 0.001)


func test_outgoing_vs_ignite_applies_through_damage_multiplier() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "ignite_probe"
	member.job_id = "mage"
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "silvaria_fang"
	member.equipped_weapon = weapon
	GameState.party_members = [member]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "ignite_mob"
	enemy.max_hp = 100
	enemy.attack = 8
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	var base: float = cc.get_member_outgoing_damage_multiplier(0, "", false, "", 0)
	assert_true(cc.apply_status_to_enemy_slot(0, "ignite", 1, 10))
	var boosted: float = cc.get_member_outgoing_damage_multiplier(0, "", false, "", 0)
	assert_almost_eq(boosted / base, 1.40, 0.001)


func test_debuff_priority_targeting_picks_shocked_enemy() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "tgt_probe"
	member.job_id = "scout"
	GameState.party_members = [member]
	var e0: Resource = _EnemyData.new()
	e0.id = "clean"
	e0.max_hp = 50
	e0.attack = 5
	var e1: Resource = _EnemyData.new()
	e1.id = "shocked"
	e1.max_hp = 50
	e1.attack = 5
	var cc := CombatController.new()
	add_child_autofree(cc)
	## 群れ2体: slot0 清潔 / slot1 感電
	cc.start_combat_group([e0, e1], 1)
	assert_true(cc.apply_status_to_enemy_slot(1, "shock", 1, 10))
	var slot: int = cc.pick_enemy_slot_by_rule("enemy_with_debuff")
	assert_eq(slot, 1)
