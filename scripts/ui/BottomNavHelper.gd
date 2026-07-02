class_name BottomNavHelper
extends RefCounted

## 全拠点系画面で共通の下ナビ配線（003_01 Phase A: 6タブ）。

const SCENE_HOME: String = "res://scenes/base/BaseScene.tscn"
const SCENE_ROSTER: String = "res://scenes/roster/RosterScene.tscn"
const SCENE_DUNGEON: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const SCENE_BLACKSMITH: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const SCENE_GACHA: String = "res://scenes/gacha/GachaScene.tscn"

enum Tab { HOME, PARTY, ADVENTURE, FORGE, SHOP, MENU }

const TAB_NODE_NAMES: Dictionary = {
	Tab.HOME: "NavHome",
	Tab.PARTY: "NavParty",
	Tab.ADVENTURE: "NavAdventure",
	Tab.FORGE: "NavForge",
	Tab.SHOP: "NavShop",
	Tab.MENU: "NavMenu",
}

const COLOR_NAV_ACTIVE: Color = Color(0.95, 0.84, 0.4, 1)
const COLOR_NAV_IDLE: Color = Color(0.78, 0.74, 0.6, 1)

const NAV_LABELS: Dictionary = {
	"NavHome": "ホーム",
	"NavParty": "パーティ",
	"NavAdventure": "冒険",
	"NavForge": "強化",
	"NavShop": "ショップ",
	"NavMenu": "メニュー",
}

static func setup(nav_row: HBoxContainer, active_tab: Tab) -> void:
	if nav_row == null:
		return
	apply_standard_labels(nav_row)
	NavIconHelper.decorate_bottom_nav_row(nav_row)
	highlight_tab(nav_row, active_tab)
	_connect_if_needed(nav_row.get_node_or_null("NavHome") as Button, _go_hub)
	_connect_if_needed(nav_row.get_node_or_null("NavParty") as Button, _go_party)
	_connect_if_needed(nav_row.get_node_or_null("NavAdventure") as Button, _go_adventure)
	_connect_if_needed(nav_row.get_node_or_null("NavForge") as Button, _go_forge)
	_connect_if_needed(nav_row.get_node_or_null("NavShop") as Button, _go_shop)
	_connect_if_needed(nav_row.get_node_or_null("NavMenu") as Button, _go_menu_grid)

static func highlight_tab(nav_row: HBoxContainer, active_tab: Tab) -> void:
	_set_active_tab(nav_row, active_tab)

static func apply_standard_labels(nav_row: HBoxContainer) -> void:
	if nav_row == null:
		return
	for child in nav_row.get_children():
		if not child is Button:
			continue
		var btn := child as Button
		var label: String = str(NAV_LABELS.get(btn.name, ""))
		if not label.is_empty():
			btn.text = label

static func _connect_if_needed(btn: Button, handler: Callable) -> void:
	if btn == null:
		return
	btn.toggle_mode = false
	for conn in btn.pressed.get_connections():
		btn.pressed.disconnect(conn["callable"])
	btn.pressed.connect(handler)

static func _set_active_tab(nav_row: HBoxContainer, active_tab: Tab) -> void:
	for child in nav_row.get_children():
		if not child is Button:
			continue
		var btn := child as Button
		var is_active: bool = str(TAB_NODE_NAMES.get(active_tab, "")) == str(btn.name)
		btn.toggle_mode = false
		btn.button_pressed = false
		btn.add_theme_color_override("font_color", COLOR_NAV_ACTIVE if is_active else COLOR_NAV_IDLE)

static func _go_hub() -> void:
	GameState.base_initial_view = "hub"
	SceneRouter.change_scene(SCENE_HOME)

static func _go_party() -> void:
	if ResourceLoader.exists(SCENE_ROSTER):
		SceneRouter.change_scene(SCENE_ROSTER)

static func _go_adventure() -> void:
	SceneRouter.change_scene(SCENE_DUNGEON)

static func _go_forge() -> void:
	SceneRouter.change_scene(SCENE_BLACKSMITH)

static func _go_shop() -> void:
	if ResourceLoader.exists(SCENE_GACHA):
		SceneRouter.change_scene(SCENE_GACHA)

static func _go_menu_grid() -> void:
	GameState.base_initial_view = "menu_grid"
	SceneRouter.change_scene(SCENE_HOME)
