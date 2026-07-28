extends GutTest

## P3-UX-COMBAT-BAND-001 — 帯VFXスタイル分類。


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
