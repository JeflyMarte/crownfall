extends GutTest

## P3-UX-COMBAT-BAND-001／ART-001 — 帯VFXスタイル分類＋本番シート未配置は無演出。


func _fake_skill(id: String, display_name: String, target: String, element: String = "", cast: float = 0.0, slot: String = "skill", effect: String = "damage") -> Resource:
	var s: Resource = SkillData.new()
	s.id = id
	s.display_name = display_name
	s.target_type = target
	s.element = element
	s.cast_time = cast
	s.slot_type = slot
	s.effect_type = effect
	return s


func test_enemy_breath_and_pulse_and_tide() -> void:
	assert_eq(
		CombatBandVfx.classify_enemy_skill(_fake_skill("enemy_eldion_glacial_breath", "氷河の吐息", "all_party", "ice", 1.0)),
		CombatBandVfx.STYLE_BREATH
	)
	assert_eq(
		CombatBandVfx.classify_enemy_skill(_fake_skill("boss_decree_wave", "断罪の波動", "all_party", "dark", 1.0)),
		CombatBandVfx.STYLE_PULSE
	)
	assert_eq(
		CombatBandVfx.classify_enemy_skill(_fake_skill("enemy_moldgar_abyss_surge", "深淵の泥濤", "all_party", "dark", 1.0)),
		CombatBandVfx.STYLE_TIDE
	)
	assert_eq(
		CombatBandVfx.classify_enemy_skill(_fake_skill("enemy_ink_veil", "墨煙の帳", "all_party", "", 0.0)),
		CombatBandVfx.STYLE_MIST
	)


func test_enemy_single_target_has_no_band() -> void:
	assert_eq(
		CombatBandVfx.classify_enemy_skill(_fake_skill("enemy_anchor_crush", "錨打ち", "party", "", 0.0)),
		""
	)


func test_ally_aoe_styles() -> void:
	assert_eq(
		CombatBandVfx.classify_ally_aoe_skill(_fake_skill("blade_tempest", "剣嵐", "all_enemies")),
		CombatBandVfx.STYLE_FAN
	)
	assert_eq(
		CombatBandVfx.classify_ally_aoe_skill(_fake_skill("volley_shot", "斉射", "all_enemies")),
		CombatBandVfx.STYLE_VOLLEY
	)
	assert_eq(
		CombatBandVfx.classify_ally_aoe_skill(_fake_skill("miasma_cloud", "瘴気の霧", "all_enemies", "dark")),
		CombatBandVfx.STYLE_MIST
	)
	assert_eq(
		CombatBandVfx.classify_ally_aoe_skill(_fake_skill("shield_quake", "盾撃波", "all_enemies")),
		CombatBandVfx.STYLE_QUAKE
	)
	assert_eq(
		CombatBandVfx.classify_ally_aoe_skill(_fake_skill("slash_attack", "一閃", "enemy")),
		""
	)


func test_ultimate_styles() -> void:
	assert_eq(
		CombatBandVfx.classify_ultimate(_fake_skill("dead_eye", "デッドアイ", "enemy", "", 0.0, "ultimate")),
		CombatBandVfx.STYLE_SHOT
	)
	assert_eq(
		CombatBandVfx.classify_ultimate(_fake_skill("titan_roar", "タイタンロア", "enemy", "", 0.0, "ultimate")),
		CombatBandVfx.STYLE_ROAR
	)
	assert_eq(
		CombatBandVfx.classify_ultimate(_fake_skill("ouga_retsudan", "王牙列断", "enemy", "", 0.0, "ultimate")),
		CombatBandVfx.STYLE_SLASH
	)
	assert_eq(
		CombatBandVfx.classify_ultimate(_fake_skill("grand_elixir", "グランドエリクサー", "ally", "", 0.0, "ultimate", "heal")),
		""
	)


func test_p0_frames_paths_and_missing_means_no_play() -> void:
	assert_eq(
		CombatBandVfx.frames_path_for_style(CombatBandVfx.STYLE_BREATH),
		"res://resources/animation/FX_Band_Breath.tres"
	)
	assert_eq(
		CombatBandVfx.frames_path_for_style(CombatBandVfx.STYLE_PULSE),
		"res://resources/animation/FX_Band_Pulse.tres"
	)
	assert_eq(
		CombatBandVfx.frames_path_for_style(CombatBandVfx.STYLE_SLASH),
		"res://resources/animation/FX_Band_Slash.tres"
	)
	## P0 はシート配置済み。P1（fan 等）は未配置＝無演出（四角に戻さない）。
	assert_true(CombatBandVfx.has_band_frames(CombatBandVfx.STYLE_BREATH))
	assert_true(CombatBandVfx.has_band_frames(CombatBandVfx.STYLE_PULSE))
	assert_true(CombatBandVfx.has_band_frames(CombatBandVfx.STYLE_SLASH))
	assert_false(CombatBandVfx.has_band_frames(CombatBandVfx.STYLE_FAN))
	var host: Node = add_child_autoqfree(Node.new())
	var layer: Node = add_child_autoqfree(Node2D.new())
	assert_gt(
		CombatBandVfx.play_enemy_band(
			host, layer, Vector2(100, 100), Rect2(0, 0, 200, 120), CombatBandVfx.STYLE_BREATH, "ice", 1.0
		),
		0.0
	)
	assert_gt(
		CombatBandVfx.play_ultimate_band(
			host, layer, Vector2(40, 80), Vector2(200, 80), CombatBandVfx.STYLE_SLASH, "", 1.0
		),
		0.0
	)
	assert_eq(
		CombatBandVfx.play_ally_band(
			host, layer, Vector2(40, 80), Rect2(100, 40, 200, 120), CombatBandVfx.STYLE_FAN, "fire", 1.0
		),
		0.0
	)
