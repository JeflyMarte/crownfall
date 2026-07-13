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


func test_spawn_burst_without_crash() -> void:
	var host := Node2D.new()
	add_child_autofree(host)
	var mgr: RefCounted = _CombatVfxManager.new()
	mgr.spawn_apply_burst(host, Vector2(100, 100), "ignite")
	mgr.spawn_dot_tick(host, Vector2(120, 100), "poison")
	assert_gt(host.get_child_count(), 0)


func test_dot_telop_color_mapping() -> void:
	assert_true(_CombatVfxManager.dot_telop_color("poison").g > 0.8)
	assert_true(_CombatVfxManager.dot_telop_color("ignite").r > 0.9)
	assert_true(_CombatVfxManager.dot_telop_color("ignite").g < 0.5)


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
