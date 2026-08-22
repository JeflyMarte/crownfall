extends GutTest
## P3-VFX-STATUS-001 — 状態異常 VFX マネージャ。

const _CombatVfxManager = preload("res://scripts/combat/CombatVfxManager.gd")


func test_status_element_mapping() -> void:
	assert_eq(_CombatVfxManager.status_element("ignite"), "fire")
	assert_eq(_CombatVfxManager.status_element("chill"), "ice")
	assert_eq(_CombatVfxManager.status_element("shock"), "thunder")
	assert_eq(_CombatVfxManager.status_element("curse"), "dark")
	assert_eq(_CombatVfxManager.status_element("poison"), "")


func test_aura_status_list_covers_core_debuffs() -> void:
	var mgr: RefCounted = _CombatVfxManager.new()
	for sid in ["poison", "chill", "shock", "ignite", "curse", "bleed"]:
		assert_true(sid in mgr.AURA_STATUS_IDS, sid)


func test_aura_includes_buff_and_combat_debuffs() -> void:
	## P3-UX-COMBAT-VFX-001
	var mgr: RefCounted = _CombatVfxManager.new()
	for sid in ["empower", "empower_minor", "guard", "mark", "vulnerable", "armor_break", "slow", "enrage"]:
		assert_true(sid in mgr.AURA_STATUS_IDS, sid)


func test_status_apply_telop_color_buff_is_orange() -> void:
	var buff_c: Color = _CombatVfxManager.status_apply_telop_color("empower")
	assert_true(buff_c.r > 0.9)
	assert_true(buff_c.g > 0.6 and buff_c.g < 0.85)
	var debuff_c: Color = _CombatVfxManager.status_apply_telop_color("poison")
	assert_ne(buff_c, debuff_c)


func test_weapon_hit_style_differs_sword_vs_bow() -> void:
	var sword: Dictionary = _CombatVfxManager.weapon_hit_style("sword")
	var bow: Dictionary = _CombatVfxManager.weapon_hit_style("bow")
	assert_ne(sword.get("scale"), bow.get("scale"))
	assert_true(float((bow.get("scale") as Vector2).y) > float((bow.get("scale") as Vector2).x))
	assert_true(float((sword.get("scale") as Vector2).x) > float((sword.get("scale") as Vector2).y))


func test_loop_aura_preprocess_is_capped() -> void:
	## 弱機フリーズ種: preprocess=lifetime 禁止。短くキャップする。
	var mgr: RefCounted = _CombatVfxManager.new()
	var aura: CPUParticles2D = mgr._build_loop_aura("poison")
	assert_not_null(aura)
	assert_lt(aura.preprocess, aura.lifetime)
	assert_lte(aura.preprocess, 0.12)


func test_dot_telop_color_mapping() -> void:
	## 毒は紫系（回復緑と被らせない）。
	var poison_c: Color = _CombatVfxManager.dot_telop_color("poison")
	assert_true(poison_c.b > poison_c.g, "poison telop should skew purple/blue over green")
	assert_true(_CombatVfxManager.dot_telop_color("ignite").r > 0.9)
	assert_true(_CombatVfxManager.dot_telop_color("ignite").g < 0.5)


func test_status_apply_telop_text() -> void:
	## P3-UX-STATUS-TELOP-001
	assert_eq(_CombatVfxManager.status_apply_telop_text("毒"), "毒を付与！")
	assert_eq(_CombatVfxManager.status_apply_telop_text("炎上"), "炎上を付与！")
	assert_eq(_CombatVfxManager.status_apply_telop_text("鼓舞"), "鼓舞を付与！")
	assert_eq(_CombatVfxManager.status_apply_telop_text(""), "")
	assert_eq(_CombatVfxManager.status_apply_telop_text("  "), "")


func test_unit_tint_from_statuses() -> void:
	var poison_only: Array = [{"effect_id": "poison", "stacks": 1}]
	var ignite_only: Array = [{"effect_id": "ignite", "stacks": 1}]
	assert_ne(
		_CombatVfxManager.unit_tint_from_statuses(poison_only),
		_CombatVfxManager.unit_tint_from_statuses(ignite_only)
	)
	assert_eq(_CombatVfxManager.unit_tint_from_statuses([]), Color.WHITE)


func test_is_buff_status_classification() -> void:
	assert_true(_CombatVfxManager.is_buff_status("empower"))
	assert_true(_CombatVfxManager.is_buff_status("empower_minor"))
	assert_true(_CombatVfxManager.is_buff_status("guard"))
	assert_false(_CombatVfxManager.is_buff_status("poison"))
	assert_false(_CombatVfxManager.is_buff_status("ignite"))


func test_sync_and_clear_auras() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	var mgr: RefCounted = _CombatVfxManager.new()
	var statuses: Array = [{"effect_id": "ignite", "stacks": 1, "remaining_ticks": 3}]
	mgr.sync_unit_auras("enemy_0", anchor, statuses, true)
	assert_true(anchor.has_node("StatusAuraHost"))
	mgr.clear_all()
	await get_tree().process_frame
	var host_after: Node = anchor.get_node_or_null("StatusAuraHost")
	if host_after != null:
		assert_eq(host_after.get_child_count(), 0)


func test_combat_vfx_sprite_assets_exist() -> void:
	for path in [
		"res://resources/animation/FX_Hit_Normal.tres",
		"res://resources/animation/FX_Hit_Critical.tres",
		"res://resources/animation/FX_Hit_Fire.tres",
		"res://resources/animation/FX_Hit_Ice.tres",
		"res://resources/animation/FX_Hit_Thunder.tres",
		"res://resources/animation/FX_Heal.tres",
	]:
		assert_true(ResourceLoader.exists(path), "missing combat vfx: %s" % path)
