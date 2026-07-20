extends SceneTree

## P3-UI-Base-A — BaseScene 拠点ハブ headless 検証（CI / smoke 補助）。

const EXPECTED_LEFT_MENU: int = 9
const LEFT_MENU_DESIGN_TOP: float = 96.0
const _SafeAreaHelper := preload("res://scripts/ui/SafeAreaHelper.gd")
const HubLayoutHelper := preload("res://scripts/ui/HubLayoutHelper.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: PackedStringArray = []
	var scene: PackedScene = load("res://scenes/base/BaseScene.tscn") as PackedScene
	if scene == null:
		_fail(["BaseScene.tscn load failed"])
		return
	var root: Control = scene.instantiate() as Control
	if root == null:
		_fail(["BaseScene instantiate failed"])
		return
	get_root().add_child(root)
	await create_timer(0.2).timeout
	failures.append_array(_verify(root))
	failures.append_array(_verify_hub_restored(root))
	root.queue_free()
	if failures.is_empty():
		print("VERIFY_BASE_HUB: PASS")
		quit(0)
	else:
		_fail(failures)

func _fail(messages: PackedStringArray) -> void:
	for msg in messages:
		push_error(msg)
	print("VERIFY_BASE_HUB: FAIL (%d)" % messages.size())
	quit(1)

func _verify(root: Control) -> PackedStringArray:
	var failures: PackedStringArray = []
	var hub: Control = root.get_node_or_null("HubView") as Control
	if hub == null or not hub.visible:
		failures.append("HubView missing or not visible on boot")
	var menu_vbox: VBoxContainer = root.get_node_or_null(
		"HubView/LeftMenuPanel/MenuScroll/MenuVBox"
	) as VBoxContainer
	if menu_vbox == null:
		failures.append("MenuVBox path missing")
	else:
		var dynamic: int = 0
		for child in menu_vbox.get_children():
			if child.name != "LabelMenuTitle" and child.name != "SepMenu":
				dynamic += 1
		if dynamic != EXPECTED_LEFT_MENU:
			failures.append("Left menu count=%d expected=%d" % [dynamic, EXPECTED_LEFT_MENU])
	var nav_row: HBoxContainer = root.get_node_or_null("BottomNav/NavRow") as HBoxContainer
	if nav_row == null:
		failures.append("BottomNav/NavRow missing")
	else:
		var home: Button = nav_row.get_node_or_null("NavHome") as Button
		if home == null:
			failures.append("Missing nav button: NavHome")
	return failures


func _verify_hub_restored(root: Control) -> PackedStringArray:
	## 案B: Mac では simulate OFF。TopBar／左メニューはシーン設計座標のまま。
	var failures: PackedStringArray = []
	if _SafeAreaHelper.should_apply_chrome():
		## 実機／明示 simulate 時は動的 chrome あり得るのでスキップ。
		return failures
	var top_bar: Control = root.get_node_or_null("HubView/TopBar") as Control
	var left: Control = root.get_node_or_null("HubView/LeftMenuPanel") as Control
	var nav: Control = root.get_node_or_null("BottomNav") as Control
	if top_bar != null and top_bar.offset_top > 1.0:
		failures.append("TopBar offset_top=%.1f expected≈0 on desktop" % top_bar.offset_top)
	if left != null:
		if absf(left.offset_top - LEFT_MENU_DESIGN_TOP) > 1.0:
			failures.append(
				"LeftMenuPanel offset_top=%.1f expected≈%.1f" % [left.offset_top, LEFT_MENU_DESIGN_TOP]
			)
		var rows: int = 0
		var vbox: VBoxContainer = root.get_node_or_null(
			"HubView/LeftMenuPanel/MenuScroll/MenuVBox"
		) as VBoxContainer
		if vbox != null:
			for child in vbox.get_children():
				if child is Control and child.name != "LabelMenuTitle" and child.name != "SepMenu":
					rows += 1
		if rows < EXPECTED_LEFT_MENU:
			failures.append("Left menu rows=%d expected=%d" % [rows, EXPECTED_LEFT_MENU])
	if nav != null and absf(nav.offset_top + 84.0) > 1.0:
		## シーン設計の BottomNav 高さ。
		failures.append("BottomNav offset_top=%.1f expected≈-84 on desktop" % nav.offset_top)
	failures.append_array(_verify_hub_device_layout_simulated(root))
	return failures


func _verify_hub_device_layout_simulated(root: Control) -> PackedStringArray:
	## simulate ON で TopBar 追従・日課下端アンカーを検証（実機相当）。
	var failures: PackedStringArray = []
	var setting: StringName = &"crownfall/ui/simulate_mobile_safe_area"
	var prev: bool = bool(ProjectSettings.get_setting(setting, false))
	ProjectSettings.set_setting(setting, true)
	HubLayoutHelper.apply_chrome_safe_area(root)
	HubLayoutHelper.layout_hub_home_content(root)
	var top_inset: float = _SafeAreaHelper.top_inset()
	var top_bar: Control = root.get_node_or_null("HubView/TopBar") as Control
	var left: Control = root.get_node_or_null("HubView/LeftMenuPanel") as Control
	var daily: Control = root.get_node_or_null("HubView/DailyMissionPanel") as Control
	if top_bar != null and absf(top_bar.offset_top - top_inset) > 1.0:
		failures.append(
			"sim TopBar offset_top=%.1f expected≈%.1f" % [top_bar.offset_top, top_inset]
		)
	if left != null:
		var expect_left: float = top_inset + LEFT_MENU_DESIGN_TOP
		if absf(left.offset_top - expect_left) > 1.0:
			failures.append(
				"sim LeftMenu offset_top=%.1f expected≈%.1f" % [left.offset_top, expect_left]
			)
		if top_bar != null and left.offset_top < top_bar.offset_bottom - 1.0:
			failures.append(
				"sim LeftMenu overlaps TopBar (left.top=%.1f top_bar.bottom=%.1f)"
				% [left.offset_top, top_bar.offset_bottom]
			)
	if daily != null:
		if absf(daily.anchor_top - 1.0) > 0.01 or absf(daily.anchor_bottom - 1.0) > 0.01:
			failures.append("sim DailyMissionPanel should be bottom-anchored")
		if daily.offset_bottom > -1.0:
			failures.append("sim DailyMissionPanel offset_bottom=%.1f expected < 0" % daily.offset_bottom)
	ProjectSettings.set_setting(setting, prev)
	## デスクトップ既定へ戻したあと、再適用でシーン座標に戻す必要はない（検証終了）。
	return failures
