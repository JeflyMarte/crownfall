class_name BottomNavHelper
extends RefCounted

## 拠点系画面の左メニュー / 下ナビ共通定義。

const SCENE_HOME: String = "res://scenes/base/BaseScene.tscn"
const SCENE_EQUIPMENT: String = "res://scenes/equipment/EquipmentScene.tscn"
const SCENE_ROSTER: String = "res://scenes/roster/RosterScene.tscn"
const SCENE_DUNGEON: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const SCENE_BLACKSMITH: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const SCENE_GACHA: String = "res://scenes/gacha/GachaScene.tscn"
const SCENE_CODEX: String = "res://scenes/codex/CodexScene.tscn"

enum Tab { NONE, HOME, ADVENTURE, CHARACTER, PARTY, FORGE, GACHA, CODEX }

const COLOR_NAV_ACTIVE: Color = Color(0.95, 0.84, 0.4, 1)
const COLOR_NAV_IDLE: Color = Color(0.92, 0.88, 0.78, 1)

# 実シーンの NavRow 構成（NavHome/NavParty/NavAdventure/NavForge/NavShop/NavMenu）と
# 1:1 対応させる（P3-UI3-001 — 旧 NavCharacter/NavGacha/NavCodex 参照は不在ノードで無効だった）。
const BOTTOM_NAV_ENTRIES: Array[Dictionary] = [
	{
		"id": "home",
		"title": "ホーム",
		"node": "NavHome",
		"tab": Tab.HOME,
		"icon_category": "nav",
		"icon_id": "home",
		"locked": false,
	},
	{
		"id": "roster",
		"title": "パーティー編成",
		"node": "NavParty",
		"tab": Tab.PARTY,
		"icon_category": "nav",
		"icon_id": "party",
		"locked": false,
	},
	{
		"id": "adventure",
		"title": "冒険に出る",
		"node": "NavAdventure",
		"tab": Tab.ADVENTURE,
		"icon_category": "nav",
		"icon_id": "adventure",
		"locked": false,
	},
	{
		"id": "blacksmith",
		"title": "鍛冶屋",
		"node": "NavForge",
		"tab": Tab.FORGE,
		"icon_category": "nav",
		"icon_id": "forge",
		"locked": false,
	},
	{
		"id": "gacha",
		"title": "召喚所",
		"node": "NavShop",
		"tab": Tab.GACHA,
		"icon_category": "nav",
		"icon_id": "gacha",
		"locked": false,
	},
	{
		"id": "codex",
		"title": "図鑑",
		"node": "NavMenu",
		"tab": Tab.CODEX,
		"icon_category": "nav",
		"icon_id": "codex",
		"locked": false,
	},
]

const SIDE_MENU_ENTRIES: Array[Dictionary] = [
	{
		"id": "adventure",
		"title": "冒険に出る",
		"node": "NavAdventure",
		"tab": Tab.ADVENTURE,
		"icon_category": "nav",
		"icon_id": "adventure",
		"locked": false,
	},
	{
		"id": "equipment",
		"title": "キャラ管理",
		"node": "NavCharacter",
		"tab": Tab.CHARACTER,
		"icon_category": "nav",
		"icon_id": "character",
		"locked": false,
	},
	{
		"id": "roster",
		"title": "パーティー編成",
		"node": "NavParty",
		"tab": Tab.PARTY,
		"icon_category": "nav",
		"icon_id": "party",
		"locked": false,
	},
	{
		"id": "blacksmith",
		"title": "鍛冶屋",
		"node": "NavForge",
		"tab": Tab.FORGE,
		"icon_category": "nav",
		"icon_id": "forge",
		"locked": false,
	},
	{
		"id": "gacha",
		"title": "召喚所",
		"node": "NavGacha",
		"tab": Tab.GACHA,
		"icon_category": "nav",
		"icon_id": "gacha",
		"locked": false,
	},
	{
		"id": "codex",
		"title": "図鑑",
		"node": "NavCodex",
		"tab": Tab.CODEX,
		"icon_category": "nav",
		"icon_id": "codex",
		"locked": false,
	},
	{
		"id": "settings",
		"title": "設定",
		"node": "NavSettings",
		"tab": Tab.NONE,
		"icon_category": "nav",
		"icon_id": "settings",
		"locked": true,
	},
]

static func setup(nav_row: HBoxContainer, active_tab: Tab) -> void:
	if nav_row == null:
		return
	NavUiTokens.apply_bottom_nav_row(nav_row)
	apply_standard_labels(nav_row)
	NavIconHelper.decorate_bottom_nav_row(nav_row)
	highlight_tab(nav_row, active_tab)
	_wire_nav_row(nav_row, active_tab)

static func highlight_tab(nav_row: HBoxContainer, active_tab: Tab) -> void:
	_set_active_tab(nav_row, active_tab)

static func apply_standard_labels(nav_row: HBoxContainer) -> void:
	if nav_row == null:
		return
	for entry in BOTTOM_NAV_ENTRIES:
		var btn: Button = nav_row.get_node_or_null(str(entry["node"])) as Button
		if btn == null:
			continue
		var full_title: String = str(entry["title"])
		var nav_text: String = NavUiTokens.bottom_nav_label(full_title)
		NavUiTokens.set_bottom_nav_text(btn, nav_text)
		btn.disabled = bool(entry.get("locked", false))
		NavUiTokens.set_bottom_nav_disabled_style(btn, btn.disabled)
		if btn.disabled:
			btn.tooltip_text = "準備中"
		elif nav_text != full_title:
			btn.tooltip_text = full_title
		else:
			btn.tooltip_text = ""

static func get_entry_by_id(entry_id: String) -> Dictionary:
	for entry in BOTTOM_NAV_ENTRIES:
		if str(entry["id"]) == entry_id:
			return entry
	for entry in SIDE_MENU_ENTRIES:
		if str(entry["id"]) == entry_id:
			return entry
	return {}

static func _wire_nav_row(nav_row: HBoxContainer, active_tab: Tab) -> void:
	var home_btn: Button = nav_row.get_node_or_null("NavHome") as Button
	if home_btn != null:
		if active_tab == Tab.HOME:
			home_btn.disabled = true
			home_btn.tooltip_text = "拠点ホーム"
			NavUiTokens.set_bottom_nav_text_color(home_btn, COLOR_NAV_ACTIVE)
		else:
			home_btn.disabled = false
			NavUiTokens.set_bottom_nav_disabled_style(home_btn, false)
			_connect_if_needed(home_btn, _go_home)
	_connect_if_needed(nav_row.get_node_or_null("NavAdventure") as Button, _go_adventure)
	_connect_if_needed(nav_row.get_node_or_null("NavParty") as Button, _go_party)
	_connect_if_needed(nav_row.get_node_or_null("NavForge") as Button, _go_forge)
	_connect_if_needed(nav_row.get_node_or_null("NavShop") as Button, _go_gacha)
	_connect_if_needed(nav_row.get_node_or_null("NavMenu") as Button, _go_codex)

static func _connect_if_needed(btn: Button, handler: Callable) -> void:
	if btn == null or btn.disabled:
		return
	btn.toggle_mode = false
	for conn in btn.pressed.get_connections():
		btn.pressed.disconnect(conn["callable"])
	btn.pressed.connect(handler)

static func _set_active_tab(nav_row: HBoxContainer, active_tab: Tab) -> void:
	var active_node: String = ""
	if active_tab != Tab.NONE:
		for entry in BOTTOM_NAV_ENTRIES:
			if entry["tab"] == active_tab:
				active_node = str(entry["node"])
				break
	for child in nav_row.get_children():
		if not child is Button:
			continue
		var btn := child as Button
		var is_active: bool = str(btn.name) == active_node
		btn.toggle_mode = false
		btn.button_pressed = false
		var color: Color = COLOR_NAV_ACTIVE if is_active else COLOR_NAV_IDLE
		NavUiTokens.set_bottom_nav_text_color(btn, color)

static func _go_home() -> void:
	_change_scene(SCENE_HOME)

static func _go_adventure() -> void:
	_change_scene(SCENE_DUNGEON)

static func _go_character() -> void:
	if ResourceLoader.exists(SCENE_EQUIPMENT):
		_change_scene(SCENE_EQUIPMENT)

static func _go_party() -> void:
	if ResourceLoader.exists(SCENE_ROSTER):
		_change_scene(SCENE_ROSTER)

static func _go_forge() -> void:
	_change_scene(SCENE_BLACKSMITH)

static func _go_gacha() -> void:
	if ResourceLoader.exists(SCENE_GACHA):
		_change_scene(SCENE_GACHA)

static func _go_codex() -> void:
	if ResourceLoader.exists(SCENE_CODEX):
		_change_scene(SCENE_CODEX)

static func _change_scene(path: String) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var router: Node = tree.root.get_node_or_null("/root/SceneRouter")
	if router != null and router.has_method("change_scene"):
		router.call("change_scene", path)
