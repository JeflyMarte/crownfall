extends SceneTree

## BaseScene 拠点ハブ headless 検証。

const EXPECTED_LEFT_MENU: int = 7
const EXPECTED_NAV_BUTTONS: int = 7

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
	await create_timer(0.05).timeout
	failures.append_array(_verify(root))
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
	quit()

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
		for entry in BottomNavHelper.SIDE_MENU_ENTRIES:
			var found: bool = _node_tree_has_label(menu_vbox, str(entry["title"]))
			if not found:
				failures.append("Left menu missing: %s" % str(entry["title"]))
	var nav_row: HBoxContainer = root.get_node_or_null("BottomNav/NavRow") as HBoxContainer
	if nav_row == null:
		failures.append("BottomNav/NavRow missing")
	else:
		if nav_row.get_child_count() != EXPECTED_NAV_BUTTONS:
			failures.append(
				"Nav button count=%d expected=%d" % [nav_row.get_child_count(), EXPECTED_NAV_BUTTONS]
			)
		for entry in BottomNavHelper.BOTTOM_NAV_ENTRIES:
			var btn: Button = nav_row.get_node_or_null(str(entry["node"])) as Button
			if btn == null:
				failures.append("Missing nav button: %s" % str(entry["node"]))
			elif btn.name == "NavHome":
				if not btn.disabled:
					failures.append("NavHome should be disabled on BaseScene")
			elif not bool(entry.get("locked", false)) and btn.pressed.get_connections().is_empty():
				failures.append("Nav button not wired: %s" % str(entry["node"]))
	return failures

func _node_tree_has_label(root: Node, text: String) -> bool:
	if root is Label and (root as Label).text == text:
		return true
	for child in root.get_children():
		if _node_tree_has_label(child, text):
			return true
	return false
