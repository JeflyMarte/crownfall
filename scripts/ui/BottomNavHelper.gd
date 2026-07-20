class_name BottomNavHelper
extends RefCounted

const _HubNpcHelper := preload("res://scripts/ui/HubNpcHelper.gd")

## 拠点系画面の左メニュー / 下ナビ共通定義。

const SCENE_HOME: String = "res://scenes/base/BaseScene.tscn"
const SCENE_EQUIPMENT: String = "res://scenes/equipment/EquipmentScene.tscn"
const SCENE_EQUIPMENT_CATALOG: String = "res://scenes/equipment/EquipmentCatalogScene.tscn"
const SCENE_ROSTER: String = "res://scenes/roster/RosterScene.tscn"
const SCENE_DUNGEON: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const SCENE_BLACKSMITH: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const SCENE_GACHA: String = "res://scenes/gacha/GachaScene.tscn"
const SCENE_CODEX: String = "res://scenes/codex/CodexScene.tscn"
const SCENE_COMMANDER: String = "res://scenes/commander/CommanderScene.tscn"
const SCENE_SETTINGS: String = "res://scenes/settings/SettingsScene.tscn"

enum Tab { NONE, HOME, ADVENTURE, CHARACTER, PARTY, FORGE, GACHA, CODEX, MYPAGE }

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
		"id": "adventure",
		"title": "ダンジョン",
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
		"id": "equipment_catalog",
		"title": "装備一覧",
		"node": "NavEquipmentCatalog",
		"tab": Tab.NONE,
		"icon_category": "nav",
		"icon_id": "equipment",
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
		"title": "招待状",
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
	{
		"id": "commander",
		"title": "マイページ",
		"node": "NavMyPage",
		"tab": Tab.MYPAGE,
		"icon_category": "nav",
		"icon_id": "mypage",
		"locked": false,
	},
]

## 下ナビと同じ並び（ホームは拠点本体のため左メニューでは省略。末尾に設定）。
const SIDE_MENU_ENTRIES: Array[Dictionary] = [
	{
		"id": "adventure",
		"title": "ダンジョン",
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
		"id": "equipment_catalog",
		"title": "装備一覧",
		"node": "NavEquipmentCatalog",
		"tab": Tab.NONE,
		"icon_category": "nav",
		"icon_id": "equipment",
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
		"title": "招待状",
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
		"id": "commander",
		"title": "マイページ",
		"node": "NavCommander",
		"tab": Tab.MYPAGE,
		"icon_category": "nav",
		"icon_id": "mypage",
		"locked": false,
	},
	{
		"id": "settings",
		"title": "設定",
		"node": "NavSettings",
		"tab": Tab.NONE,
		"icon_category": "nav",
		"icon_id": "settings",
		"locked": false,
	},
]

static func setup(nav_row: HBoxContainer, active_tab: Tab) -> void:
	if nav_row == null:
		return
	_reorder_nav_row(nav_row)
	NavUiTokens.apply_bottom_nav_row(nav_row)
	apply_standard_labels(nav_row)
	NavIconHelper.decorate_bottom_nav_row(nav_row)
	highlight_tab(nav_row, active_tab)
	_wire_nav_row(nav_row, active_tab)
	_HubNpcHelper.show_pending_banner(_scene_root(nav_row))


## BOTTOM_NAV_ENTRIES の順に子を並べ、未掲載ボタンは隠す。
## 並び: ホーム → ダンジョン → … → 図鑑 → マイページ。
static func _reorder_nav_row(nav_row: HBoxContainer) -> void:
	var kept: Dictionary = {}
	for i in BOTTOM_NAV_ENTRIES.size():
		var node_name: String = str(BOTTOM_NAV_ENTRIES[i]["node"])
		kept[node_name] = true
		var btn: Button = _ensure_nav_button(nav_row, node_name)
		btn.visible = true
		nav_row.move_child(btn, i)
	for child in nav_row.get_children():
		if child is Button and not kept.has(str(child.name)):
			(child as Button).visible = false


static func _ensure_nav_button(nav_row: HBoxContainer, node_name: String) -> Button:
	var existing: Button = nav_row.get_node_or_null(node_name) as Button
	if existing != null:
		return existing
	var btn := Button.new()
	btn.name = node_name
	nav_row.add_child(btn)
	return btn

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
		btn.disabled = bool(entry.get("locked", false)) or _is_entry_omitted(str(entry.get("id", "")))
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

static func _is_entry_omitted(entry_id: String) -> bool:
	return entry_id == "gacha" and not Constants.are_gacha_helpers_playable()

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
	var character_btn: Button = nav_row.get_node_or_null("NavCharacter") as Button
	if character_btn != null:
		if active_tab == Tab.CHARACTER:
			character_btn.disabled = true
			character_btn.tooltip_text = "キャラ管理"
			NavUiTokens.set_bottom_nav_text_color(character_btn, COLOR_NAV_ACTIVE)
		else:
			character_btn.disabled = false
			NavUiTokens.set_bottom_nav_disabled_style(character_btn, false)
			_connect_if_needed(character_btn, _go_character)
	_connect_if_needed(nav_row.get_node_or_null("NavEquipmentCatalog") as Button, _go_equipment_catalog)
	_connect_if_needed(nav_row.get_node_or_null("NavAdventure") as Button, _go_adventure)
	_connect_if_needed(nav_row.get_node_or_null("NavParty") as Button, _go_party)
	var forge_btn: Button = nav_row.get_node_or_null("NavForge") as Button
	if forge_btn != null:
		if active_tab == Tab.FORGE:
			forge_btn.disabled = true
			forge_btn.tooltip_text = "鍛冶屋"
			NavUiTokens.set_bottom_nav_text_color(forge_btn, COLOR_NAV_ACTIVE)
		else:
			forge_btn.disabled = false
			NavUiTokens.set_bottom_nav_disabled_style(forge_btn, false)
			_connect_if_needed(forge_btn, _go_forge)
	_connect_if_needed(nav_row.get_node_or_null("NavShop") as Button, _go_gacha)
	var codex_btn: Button = nav_row.get_node_or_null("NavMenu") as Button
	if codex_btn != null:
		if active_tab == Tab.CODEX:
			codex_btn.disabled = true
			codex_btn.tooltip_text = "図鑑"
			NavUiTokens.set_bottom_nav_text_color(codex_btn, COLOR_NAV_ACTIVE)
		else:
			codex_btn.disabled = false
			NavUiTokens.set_bottom_nav_disabled_style(codex_btn, false)
			_connect_if_needed(codex_btn, _go_codex)
	var mypage_btn: Button = nav_row.get_node_or_null("NavMyPage") as Button
	if mypage_btn != null:
		if active_tab == Tab.MYPAGE:
			mypage_btn.disabled = true
			mypage_btn.tooltip_text = "マイページ"
			NavUiTokens.set_bottom_nav_text_color(mypage_btn, COLOR_NAV_ACTIVE)
		else:
			mypage_btn.disabled = false
			NavUiTokens.set_bottom_nav_disabled_style(mypage_btn, false)
			_connect_if_needed(mypage_btn, _go_mypage)

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

static func _go_equipment_catalog() -> void:
	if ResourceLoader.exists(SCENE_EQUIPMENT_CATALOG):
		_change_scene(SCENE_EQUIPMENT_CATALOG)

static func _go_party() -> void:
	if ResourceLoader.exists(SCENE_ROSTER):
		_change_scene(SCENE_ROSTER)

static func _go_forge() -> void:
	_change_scene(SCENE_BLACKSMITH)

static func _go_gacha() -> void:
	if not Constants.are_gacha_helpers_playable():
		return
	if ResourceLoader.exists(SCENE_GACHA):
		_change_scene(SCENE_GACHA)

static func _go_codex() -> void:
	if ResourceLoader.exists(SCENE_CODEX):
		_change_scene(SCENE_CODEX)

static func _go_mypage() -> void:
	if ResourceLoader.exists(SCENE_COMMANDER):
		_change_scene(SCENE_COMMANDER)

static func _change_scene(path: String) -> void:
	_HubNpcHelper.queue_hint_for_scene(path)
	SceneRouter.change_scene(path)

static func _scene_root(nav_row: HBoxContainer) -> Control:
	var node: Node = nav_row
	while node != null:
		if node.get_parent() == null or str(node.get_parent().name) == "root":
			return node as Control
		node = node.get_parent()
	return nav_row.get_parent() as Control
