extends GutTest
## タイタンロア等の挑発が Threat に反映され、敵ターゲットが切り替わること。

const _Adventurer = preload("res://scripts/domain/Adventurer.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.party_members.clear()
	GameState.active_pet = null
	for i: int in 2:
		var adv: Resource = _Adventurer.new()
		adv.id = "vg_%d" % i
		adv.display_name = "VG%d" % (i + 1)
		adv.job_id = "vanguard"
		adv.level = 10
		adv.formation_row = 0
		GameState.party_members.append(adv)


func test_titan_roar_data_requests_taunt() -> void:
	var skill: Resource = DataRegistry.get_skill_data("titan_roar")
	assert_not_null(skill)
	assert_eq(str(skill.effect_type), "buff")
	assert_eq(str(skill.slot_type), "ultimate")
	assert_true(skill.tags.has("taunt"), "タイタンロアは taunt タグ必須")
	assert_eq(str(skill.apply_status_id), "guard")


func test_apply_taunt_pulls_aggro_from_other_vanguard() -> void:
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc._init_party_hp()
	cc._reset_party_threat_for_combat()
	assert_eq(cc.party_threat.size(), 2)
	## 同職・同前列は基礎 Threat 同値 → 編成番号が若い方（0）。
	assert_eq(cc.pick_enemy_target_member_index(-1), 0)
	var before1: float = cc.get_member_threat(1)
	## 2番（index 1）がタイタンロア着地時と同じ apply_taunt。
	cc.apply_taunt(1)
	assert_almost_eq(
		cc.get_member_threat(1),
		before1 + BalanceConfig.THREAT_TAUNT,
		0.001
	)
	assert_eq(cc.pick_enemy_target_member_index(-1), 1)
	assert_eq(cc.pick_enemy_target_for_melee_attack(-1), 1)


func test_taunt_overrides_prior_focus_on_vg1() -> void:
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc._init_party_hp()
	cc._reset_party_threat_for_combat()
	## 1番が被弾で Threat を稼いだ状態を模擬。
	cc.add_threat(0, 80.0)
	assert_eq(cc.pick_enemy_target_member_index(-1), 0)
	cc.apply_taunt(1)
	assert_gt(cc.get_member_threat(1), cc.get_member_threat(0))
	assert_eq(cc.pick_enemy_target_member_index(-1), 1)


func test_titan_roar_taunt_amount_beats_heavy_prior_focus() -> void:
	## THREAT_TAUNT（320）が、1番の先行ヘイトを覆せることを確認。
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc._init_party_hp()
	cc._reset_party_threat_for_combat()
	cc.add_threat(0, BalanceConfig.THREAT_TAUNT - 1.0)
	assert_eq(cc.pick_enemy_target_member_index(-1), 0)
	cc.apply_taunt(1)
	assert_eq(cc.pick_enemy_target_member_index(-1), 1)
