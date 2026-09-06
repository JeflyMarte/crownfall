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


func test_engineer_trap_frame_matches_status_size_art_cropped() -> void:
	var packed: PackedScene = load("res://scenes/dungeon/DungeonScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var status_sz: float = float(scene.get("STATUS_ICON_SIZE"))
	var mark: Control = scene.call(
		"_build_engineer_trap_status_icon",
		{
			"effect_id": "eng_trap_spike",
			"display_name": "スパイクトラップ",
			"stacks": 4,
		}
	)
	assert_not_null(mark)
	var fires: Label = mark.find_child("TrapFires", true, false) as Label
	assert_not_null(fires)
	assert_eq(fires.text, "4")
	var frame: PanelContainer = mark.find_child("TrapFrame", true, false) as PanelContainer
	assert_not_null(frame)
	## 枠は他ステと同寸の正方形。数字は枠の外。
	assert_eq(frame.custom_minimum_size.x, status_sz)
	assert_eq(frame.custom_minimum_size.y, status_sz)
	assert_false(frame.is_ancestor_of(fires))
	assert_lt(fires.get_index(), frame.get_index())
	var icon: TextureRect = mark.find_child("TrapIcon", true, false) as TextureRect
	assert_not_null(icon)
	assert_true(frame.is_ancestor_of(icon))
	var raw: Texture2D = _IconPaths.get_icon_texture("eng_trap_spike", "status")
	var cropped: Texture2D = _IconPaths.display_texture_for_engineer_trap("eng_trap_spike", raw)
	assert_not_null(cropped)
	## 余白クロップで表示領域が元より小さくなる（枠内の絵が大きく見える）。
	assert_lt(cropped.get_width() * cropped.get_height(), raw.get_width() * raw.get_height())
