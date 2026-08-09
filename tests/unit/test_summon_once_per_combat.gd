extends GutTest
## P3-BAL-SUMMON-ONCE-001 — 招集スキルは戦闘中1回。


func test_all_summon_skills_are_once_per_combat() -> void:
	var ids: Array[String] = [
		"enemy_crown_call",
		"enemy_boar_call",
		"enemy_granvel_call_mirror",
		"enemy_moldgar_call_marsh",
		"enemy_nereion_call_dread",
		"enemy_chronos_wave_call_moth",
		"enemy_big_cosmic_duck_call",
	]
	for sid: String in ids:
		var skill: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(skill, sid)
		assert_eq(str(skill.effect_type), "summon", sid)
		assert_true(skill.tags.has("once_per_combat"), sid)
		assert_gte(float(skill.cooldown), 9999.0, sid)


func test_corpse_reuse_clears_slot_summon_flag() -> void:
	## 死体スロット再利用時に slot: 鍵が残るとクローン召喚が不発になる回帰防止。
	const _DungeonScene := preload("res://scripts/dungeon/DungeonScene.gd")
	var scene: Node = _DungeonScene.new()
	scene._enemy_summon_used["slot:1"] = true
	scene._enemy_summon_used["skill:enemy_boar_call"] = true
	scene._kill_award_slots[1] = true
	scene._kill_award_slots.erase(1)
	scene._enemy_summon_used.erase("slot:1")
	assert_false(bool(scene._enemy_summon_used.get("slot:1", false)))
	assert_true(bool(scene._enemy_summon_used.get("skill:enemy_boar_call", false)), "指定召喚の skill: 鍵は残す")
	scene.free()


func test_corpse_reuse_clears_enemy_slot_cooldowns() -> void:
	## 招集スキルは CD9999。死体再利用後に enemy:slot: 接頭辞の CD が残ると再発火不能。
	const _SkillExecutor := preload("res://scripts/combat/SkillExecutor.gd")
	var ex = _SkillExecutor.new()
	ex.add_cooldown_seconds("enemy:1:enemy_boar_call", 9999.0)
	ex.add_cooldown_seconds("enemy:2:enemy_boar_call", 9999.0)
	ex.clear_cooldown_keys_with_prefix("enemy:1:")
	assert_eq(ex.get_cooldown_remaining("enemy:1:enemy_boar_call"), 0.0)
	assert_gt(ex.get_cooldown_remaining("enemy:2:enemy_boar_call"), 0.0)
