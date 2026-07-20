extends SceneTree

const _SafeAreaHelper := preload("res://scripts/ui/SafeAreaHelper.gd")

## Usage: godot --headless --path . -s tools/debug_hub_layout.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/base/BaseScene.tscn") as PackedScene
	if packed == null:
		push_error("failed to load BaseScene")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await create_timer(0.25).timeout
	var hub: Control = scene.get_node_or_null("HubView") as Control
	var left: Control = scene.get_node_or_null("HubView/LeftMenuPanel") as Control
	var scroll: ScrollContainer = scene.get_node_or_null("HubView/LeftMenuPanel/MenuScroll") as ScrollContainer
	var vbox: VBoxContainer = scene.get_node_or_null("HubView/LeftMenuPanel/MenuScroll/MenuVBox") as VBoxContainer
	var daily: Control = scene.get_node_or_null("HubView/DailyMissionPanel") as Control
	var strip: Control = scene.get_node_or_null("HubView/CurrencyStrip") as Control
	var nav: Control = scene.get_node_or_null("BottomNav") as Control
	print("=== HUB LAYOUT DUMP ===")
	print("simulate=", ProjectSettings.get_setting("crownfall/ui/simulate_mobile_safe_area", false))
	print("top_inset=", _SafeAreaHelper.top_inset(), " bottom_inset=", _SafeAreaHelper.bottom_inset())
	if hub != null:
		print("HubView size=", hub.size, " offsets t/b=", hub.offset_top, "/", hub.offset_bottom)
	if left != null:
		print(
			"LeftMenu size=", left.size,
			" top/bottom=", left.offset_top, "/", left.offset_bottom,
			" h=", left.offset_bottom - left.offset_top
		)
	if scroll != null:
		print("MenuScroll size=", scroll.size, " vmode=", scroll.vertical_scroll_mode)
	if vbox != null:
		print(
			"MenuVBox size=", vbox.size,
			" min=", vbox.get_combined_minimum_size(),
			" children=", vbox.get_child_count()
		)
		for c in vbox.get_children():
			if c is Control:
				var ctrl: Control = c as Control
				print("  - ", ctrl.name, " size=", ctrl.size, " min=", ctrl.get_combined_minimum_size())
	if strip != null:
		print("CurrencyStrip size=", strip.size, " t/b=", strip.offset_top, "/", strip.offset_bottom)
	if daily != null:
		print("Daily size=", daily.size, " t/b=", daily.offset_top, "/", daily.offset_bottom)
	if nav != null:
		print("BottomNav size=", nav.size, " t/b=", nav.offset_top, "/", nav.offset_bottom)
	print("=== END DUMP ===")
	quit(0)
