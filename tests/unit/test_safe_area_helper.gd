extends GutTest

## P3-UI-SAFE-001 — SafeAreaHelper のヘッドレス安全性と chrome 適用。


func test_viewport_insets_headless_is_zero() -> void:
	var inset: Vector4 = SafeAreaHelper.viewport_insets()
	assert_eq(inset, Vector4.ZERO, "headless/safe欠損時は inset 0")


func test_apply_scene_chrome_bottom_nav_idempotent() -> void:
	var root := Control.new()
	root.name = "TestRoot"
	add_child(root)
	var nav := PanelContainer.new()
	nav.name = "BottomNav"
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -84.0
	nav.offset_bottom = 0.0
	root.add_child(nav)
	var hub := Control.new()
	hub.name = "HubView"
	hub.set_anchors_preset(Control.PRESET_FULL_RECT)
	hub.offset_bottom = -84.0
	root.add_child(hub)

	SafeAreaHelper.apply_scene_chrome(root)
	assert_eq(nav.offset_top, -84.0)
	assert_eq(nav.offset_bottom, 0.0)
	assert_eq(hub.offset_bottom, -84.0)

	SafeAreaHelper.apply_scene_chrome(root)
	assert_eq(nav.offset_top, -84.0)
	assert_eq(hub.offset_bottom, -84.0)

	root.queue_free()


func test_project_stretch_aspect_is_keep() -> void:
	var aspect: String = str(ProjectSettings.get_setting("display/window/stretch/aspect", ""))
	assert_eq(aspect, "keep")
