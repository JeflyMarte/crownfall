extends GutTest

## 機巧士仕掛け頭上マーク（P3-JOB-ENGINEER-001-M1）

const _IconPaths := preload("res://scripts/ui/IconPaths.gd")
const _StatusEffectLinkHelper := preload("res://scripts/ui/StatusEffectLinkHelper.gd")


func test_engineer_trap_status_icons_resolve() -> void:
	for sid: String in ["eng_trap_spike", "eng_trap_snare", "eng_trap_break"]:
		var tex: Texture2D = _IconPaths.get_icon_texture(sid, "status")
		assert_not_null(tex, sid)


func test_engineer_trap_display_names() -> void:
	assert_eq(_StatusEffectLinkHelper.display_name_for("eng_trap_spike"), "スパイクトラップ")
	assert_eq(_StatusEffectLinkHelper.display_name_for("eng_trap_snare"), "スネアトラップ")
	assert_eq(_StatusEffectLinkHelper.display_name_for("eng_trap_break"), "ブレイクトラップ")


func test_engineer_trap_icon_is_larger_with_fires_above() -> void:
	var packed: PackedScene = load("res://scenes/dungeon/DungeonScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_gt(float(scene.get("ENGINEER_TRAP_ICON_SIZE")), float(scene.get("STATUS_ICON_SIZE")))
	var panel: PanelContainer = scene.call(
		"_build_engineer_trap_status_icon",
		{
			"effect_id": "eng_trap_spike",
			"display_name": "スパイクトラップ",
			"stacks": 4,
		}
	)
	assert_not_null(panel)
	assert_eq(panel.custom_minimum_size.x, float(scene.get("ENGINEER_TRAP_ICON_SIZE")))
	assert_gt(panel.custom_minimum_size.y, float(scene.get("ENGINEER_TRAP_ICON_SIZE")))
	var fires: Label = panel.find_child("TrapFires", true, false) as Label
	assert_not_null(fires)
	assert_eq(fires.text, "4")
	var icon: TextureRect = panel.find_child("TrapIcon", true, false) as TextureRect
	assert_not_null(icon)
	## 残発ラベルがアイコンより上（VBox 先頭）。
	assert_lt(fires.get_index(), icon.get_index())
