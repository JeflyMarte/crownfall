extends GutTest
## 戦闘監査フォロー I: スロット別敵スキル／沈黙戦闘クロック／召喚失敗でターン消費。

const _DungeonScene := preload("res://scripts/dungeon/DungeonScene.gd")
const _SkillExecutor := preload("res://scripts/combat/SkillExecutor.gd")


func test_silence_duration_constant() -> void:
	assert_almost_eq(_DungeonScene.ENEMY_SILENCE_DURATION_SEC, 5.0, 0.001)


func test_silence_ticks_on_combat_clock_not_wall_time() -> void:
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.party_combat_hp = [100]
	cc.party_max_hp = [100]
	cc.is_in_combat = true
	cc.apply_member_skill_silence(0, 5.0)
	assert_true(cc.is_member_skill_silenced(0))
	## 壁時計を待たず、戦闘クロック 2 秒で残りが減る。
	assert_false(cc.tick_member_skill_silence(2.0))
	assert_true(cc.is_member_skill_silenced(0))
	assert_true(cc.tick_member_skill_silence(3.5))
	assert_false(cc.is_member_skill_silenced(0))


func test_silence_does_not_tick_when_delta_zero() -> void:
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.party_combat_hp = [50]
	cc.party_max_hp = [50]
	cc.apply_member_skill_silence(0, 5.0)
	assert_false(cc.tick_member_skill_silence(0.0))
	assert_true(cc.is_member_skill_silenced(0))


func test_silence_cleared_on_combat_end() -> void:
	var cc := CombatController.new()
	add_child_autofree(cc)
	var rat: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	assert_not_null(rat)
	cc.party_combat_hp = [100]
	cc.party_max_hp = [100]
	cc.start_combat_group([rat], 1)
	cc.apply_member_skill_silence(0, 5.0)
	assert_true(cc.is_member_skill_silenced(0))
	cc.end_combat()
	assert_false(cc.is_member_skill_silenced(0))


func test_summon_support_skill_consumes_cd_before_spawn() -> void:
	## CD 消費後にスポーン失敗しても呼び出し側はターン消費する契約。
	var ex = _SkillExecutor.new()
	var skill: Resource = DataRegistry.get_skill_data("enemy_crown_call")
	assert_not_null(skill)
	assert_eq(str(skill.effect_type), "summon")
	var key: String = "enemy:1:%s" % str(skill.id)
	var res: Dictionary = ex.execute_support_skill(skill, key)
	assert_true(bool(res.get("executed", false)))
	assert_gt(ex.get_cooldown_remaining(key), 0.0)
	assert_false(ex.can_cast(skill, key))


func test_non_active_enemy_slot_has_own_skill_pool() -> void:
	## フォーカス外スロットも skill_ids を持つ（スロット別発動の前提）。
	var cc := CombatController.new()
	add_child_autofree(cc)
	var moth: Resource = DataRegistry.get_enemy_data("clock_moth")
	var lamp: Resource = DataRegistry.get_enemy_data("tide_lamp")
	assert_not_null(moth)
	assert_not_null(lamp)
	cc.start_combat_group([moth, lamp], 1, false)
	assert_eq(cc.swarm_data.size(), 2)
	assert_eq(cc.active_enemy_index, 0)
	assert_true(cc.is_enemy_slot_alive(1))
	var slot1: Resource = cc.get_enemy_data_at(1)
	assert_not_null(slot1)
	assert_false(slot1.skill_ids.is_empty())
	assert_true(slot1.skill_ids.has("enemy_tide_silence"))
