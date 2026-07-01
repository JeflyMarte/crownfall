extends Control

const DUNGEON_SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"
const GUILD_SCENE: String = "res://scenes/guild/GuildScene.tscn"
const MAX_VISIBLE_MATERIALS: int = 3

const COLOR_GOLD: Color = Color(0.95, 0.84, 0.4, 1)
const COLOR_SUB: Color = Color(0.78, 0.74, 0.6, 1)
const COLOR_MAT_SUB: Color = Color(0.78, 0.74, 0.6, 1)
const COLOR_MAT_TEXT: Color = Color(0.92, 0.86, 0.65, 1)

const MENU_ENTRIES: Array[Dictionary] = [
	{
		"id": "adventure",
		"title": "冒険",
		"subtitle": "ダンジョン探索・戦闘",
		"icon_category": "dungeon",
		"icon_id": "",
		"glyph": "⚔",
	},
	{
		"id": "equipment",
		"title": "英雄管理",
		"subtitle": "装備・スキル・戦術",
		"icon_category": "chr",
		"icon_id": "swordsman",
		"glyph": "英",
	},
	{
		"id": "blacksmith",
		"title": "赤鉄の工房",
		"subtitle": "装備の生産・強化",
		"icon_category": "weapon",
		"icon_id": "iron_sword",
		"glyph": "鍛",
	},
	{
		"id": "roster",
		"title": "編成",
		"subtitle": "パーティ・陣形",
		"icon_category": "chr",
		"icon_id": "ranger",
		"glyph": "編",
	},
	{
		"id": "codex",
		"title": "図鑑",
		"subtitle": "調査記録・生態図鑑",
		"icon_category": "",
		"icon_id": "",
		"glyph": "📖",
	},
	{
		"id": "gacha",
		"title": "召喚",
		"subtitle": "助っ人を召喚",
		"icon_category": "currency",
		"icon_id": "arcane_crystal",
		"glyph": "◆",
	},
	{
		"id": "guild",
		"title": "ギルド認定",
		"subtitle": "上級専門資格",
		"icon_category": "chr",
		"icon_id": "vanguard",
		"glyph": "認",
	},
]

@onready var _material_chip: PanelContainer = $TopBar/TopBarRow/MaterialChip
@onready var _material_icons: HBoxContainer = $TopBar/TopBarRow/MaterialChip/MaterialRow/MaterialIcons
@onready var _label_gold: Label = $TopBar/TopBarRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $TopBar/TopBarRow/TokenChip/TokenRow/LabelToken
@onready var _menu_vbox: VBoxContainer = $LeftMenuPanel/MenuVBox
@onready var _feature_grid: GridContainer = $FeaturePanel/FeatureGrid
@onready var _title_panel: PanelContainer = $TitlePanel
@onready var _spotlight_panel: PanelContainer = $SpotlightPanel
@onready var _label_spotlight_name: Label = $SpotlightPanel/SpotlightVBox/SpotlightRow/InfoCol/LabelDungeonName
@onready var _label_spotlight_meta: Label = $SpotlightPanel/SpotlightVBox/SpotlightRow/InfoCol/LabelDungeonMeta
@onready var _spotlight_icon: TextureRect = $SpotlightPanel/SpotlightVBox/SpotlightRow/IconFrame/SpotlightIcon
@onready var _spotlight_glyph: Label = $SpotlightPanel/SpotlightVBox/SpotlightRow/IconFrame/SpotlightGlyph
@onready var _btn_challenge: Button = $SpotlightPanel/SpotlightVBox/ButtonChallenge

@onready var _nav_home: Button = $BottomNav/NavRow/NavHome
@onready var _nav_adventure: Button = $BottomNav/NavRow/NavAdventure
@onready var _nav_party: Button = $BottomNav/NavRow/NavParty
@onready var _nav_codex: Button = $BottomNav/NavRow/NavCodex
@onready var _nav_shop: Button = $BottomNav/NavRow/NavShop
@onready var _daily_panel: PanelContainer = $DailyMissionPanel
@onready var _label_daily_reset: Label = $DailyMissionPanel/DailyVBox/LabelDailyReset
@onready var _mission_list: VBoxContainer = $DailyMissionPanel/DailyVBox/MissionList
@onready var _label_daily_title: Label = $DailyMissionPanel/DailyVBox/LabelDailyTitle

func _ready() -> void:
	_decorate_panels()
	_build_menu_cards()
	_build_feature_grid()
	_btn_challenge.pressed.connect(_on_dungeon_button_pressed)
	_nav_home.pressed.connect(_on_home_nav_pressed)
	_nav_adventure.pressed.connect(_on_dungeon_button_pressed)
	_nav_party.pressed.connect(_on_roster_button_pressed)
	_nav_codex.pressed.connect(_on_codex_button_pressed)
	_nav_shop.pressed.connect(_on_gacha_button_pressed)
	_material_chip.gui_input.connect(_on_material_chip_gui_input)
	DailyMissionSystem.missions_updated.connect(_refresh_daily_missions)
	$ResetTimer.timeout.connect(_update_daily_reset_label)
	_ensure_valid_dungeon_selection()
	DailyMissionSystem.ensure_refreshed()
	_update_display()
	_refresh_daily_missions()

func _decorate_panels() -> void:
	_title_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)
	_spotlight_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	$FeaturePanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$LeftMenuPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_daily_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)

func _build_menu_cards() -> void:
	for child in _menu_vbox.get_children():
		if child.name != "LabelMenuTitle" and child.name != "SepMenu":
			child.queue_free()
	for entry in MENU_ENTRIES:
		_menu_vbox.add_child(_make_menu_card(entry, false))

func _build_feature_grid() -> void:
	for child in _feature_grid.get_children():
		child.queue_free()
	for entry in MENU_ENTRIES:
		_feature_grid.add_child(_make_menu_card(entry, true))

func _make_menu_card(entry: Dictionary, compact: bool) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_on_menu_entry_pressed.bind(str(entry["id"])))
	panel.add_child(btn)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)
	row.add_child(_make_entry_icon(entry, 28 if compact else 24))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	var title := Label.new()
	title.text = str(entry["title"])
	title.add_theme_font_size_override("font_size", 14 if compact else 13)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(title)
	var subtitle := Label.new()
	subtitle.text = str(entry["subtitle"])
	subtitle.add_theme_font_size_override("font_size", 10 if compact else 11)
	subtitle.add_theme_color_override("font_color", COLOR_SUB)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(subtitle)
	if compact:
		panel.custom_minimum_size = Vector2(108, 92)
	else:
		panel.custom_minimum_size = Vector2(0, 52)
	return panel

func _make_entry_icon(entry: Dictionary, size_px: int) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(size_px, size_px)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var category: String = str(entry.get("icon_category", ""))
	var icon_id: String = str(entry.get("icon_id", ""))
	if category == "dungeon" and icon_id.is_empty():
		icon_id = GameState.current_dungeon_id
	var tex: Texture2D = null
	if not category.is_empty() and not icon_id.is_empty():
		tex = IconPaths.get_icon_texture(icon_id, category)
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(size_px - 6, size_px - 6)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = str(entry.get("glyph", "◆"))
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 16)
		glyph.add_theme_color_override("font_color", COLOR_GOLD)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(glyph)
	return frame

func _on_menu_entry_pressed(entry_id: String) -> void:
	match entry_id:
		"adventure":
			_on_dungeon_button_pressed()
		"equipment":
			_on_equipment_button_pressed()
		"blacksmith":
			_on_blacksmith_button_pressed()
		"roster":
			_on_roster_button_pressed()
		"codex":
			_on_codex_button_pressed()
		"gacha":
			_on_gacha_button_pressed()
		"guild":
			_on_guild_button_pressed()

func _ensure_valid_dungeon_selection() -> void:
	if not _is_dungeon_available(GameState.current_dungeon_id):
		GameState.current_dungeon_id = Constants.DEFAULT_DUNGEON_ID

func _is_dungeon_available(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	return DataRegistry.get_dungeon_data(dungeon_id) != null

func _update_display() -> void:
	_update_currency()
	_update_materials()
	_update_spotlight()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()
	$TopBar/TopBarRow/TokenChip.tooltip_text = CurrencyHelper.DISPLAY_NAME

func _update_spotlight() -> void:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var dungeon_data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	var display_name: String = dungeon_id
	if dungeon_data != null:
		display_name = str(dungeon_data.display_name)
	_label_spotlight_name.text = display_name
	var prog: Dictionary = GameState.dungeon_progress.get(dungeon_id, {})
	var discovery: float = float(prog.get("discovery", 0.0)) * 100.0
	_label_spotlight_meta.text = "発見率 %.0f%% ｜ 難易度 %d" % [
		discovery,
		int(dungeon_data.difficulty) if dungeon_data != null else 1,
	]
	var icon_tex: Texture2D = IconPaths.get_icon_texture(dungeon_id, "dungeon")
	_spotlight_icon.texture = icon_tex
	_spotlight_icon.visible = icon_tex != null
	_spotlight_glyph.visible = icon_tex == null
	if icon_tex == null:
		_spotlight_glyph.text = "城"

func _update_materials() -> void:
	for child in _material_icons.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = []
	for raw_id in GameState.material_inventory.keys():
		var mat_id: String = str(raw_id)
		var qty: int = GameState.get_material_quantity(mat_id)
		if qty > 0:
			entries.append({"id": mat_id, "qty": qty})
	if entries.is_empty():
		_material_chip.visible = false
		_material_chip.tooltip_text = ""
		return
	_material_chip.visible = true
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["qty"]) > int(b["qty"])
	)
	var tooltip_lines: PackedStringArray = []
	for entry in entries:
		tooltip_lines.append(
			"%s x%d" % [DataRegistry.get_material_name(str(entry["id"])), int(entry["qty"])]
		)
	_material_chip.tooltip_text = "\n".join(tooltip_lines)
	var show_count: int = mini(entries.size(), MAX_VISIBLE_MATERIALS)
	for i in show_count:
		var e: Dictionary = entries[i]
		_material_icons.add_child(_make_material_chip_cell(str(e["id"]), int(e["qty"])))
	var overflow: int = entries.size() - show_count
	if overflow > 0:
		var more := Label.new()
		more.text = "+%d" % overflow
		more.add_theme_font_size_override("font_size", 13)
		more.add_theme_color_override("font_color", COLOR_MAT_SUB)
		_material_icons.add_child(more)

func _make_material_chip_cell(mat_id: String, qty: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var icon_tex: Texture2D = IconPaths.get_icon_texture(mat_id, "material")
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "材"
		glyph.add_theme_font_size_override("font_size", 12)
		glyph.add_theme_color_override("font_color", COLOR_MAT_SUB)
		row.add_child(glyph)
	var qty_label := Label.new()
	qty_label.text = str(qty)
	qty_label.add_theme_font_size_override("font_size", 13)
	qty_label.add_theme_color_override("font_color", COLOR_MAT_TEXT)
	row.add_child(qty_label)
	return row

func _on_material_chip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			SceneRouter.change_scene(BLACKSMITH_SCENE)

func _on_home_nav_pressed() -> void:
	_update_display()
	_refresh_daily_missions()

func _refresh_daily_missions() -> void:
	_update_daily_reset_label()
	_label_daily_title.text = "ギルド日課 ●" if DailyMissionSystem.has_claimable() else "ギルド日課"
	for child in _mission_list.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = DailyMissionSystem.get_entries()
	for i in entries.size():
		_mission_list.add_child(_make_daily_row(i, entries[i]))

func _update_daily_reset_label() -> void:
	_label_daily_reset.text = "リセットまで %s" % DailyMissionSystem.reset_countdown_text()

func _make_daily_row(index: int, entry: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var mark := Label.new()
	var claimed: bool = bool(entry.get("claimed", false))
	var complete: bool = bool(entry.get("complete", false))
	if claimed:
		mark.text = "✓"
		mark.add_theme_color_override("font_color", Color(0.55, 0.88, 0.5))
	elif complete:
		mark.text = "◆"
		mark.add_theme_color_override("font_color", COLOR_GOLD)
	else:
		mark.text = "□"
		mark.add_theme_color_override("font_color", COLOR_SUB)
	mark.custom_minimum_size = Vector2(14, 0)
	mark.add_theme_font_size_override("font_size", 12)
	row.add_child(mark)
	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.text = "%s  %d/%d" % [
		str(entry.get("title", "")),
		int(entry.get("progress", 0)),
		int(entry.get("target_count", 1)),
	]
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", COLOR_GOLD if complete else COLOR_SUB)
	row.add_child(info)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(44, 22)
	btn.add_theme_font_size_override("font_size", 10)
	if claimed:
		btn.text = "済"
		btn.disabled = true
	elif bool(entry.get("can_claim", false)):
		btn.text = "受取"
		btn.pressed.connect(_on_daily_claim_pressed.bind(index))
	else:
		btn.text = "—"
		btn.disabled = true
	row.add_child(btn)
	return row

func _on_daily_claim_pressed(index: int) -> void:
	var result: Dictionary = DailyMissionSystem.claim(index)
	if not bool(result.get("ok", false)):
		return
	SaveManager.save_game()
	_update_currency()
	_update_materials()
	_refresh_daily_missions()

func _on_dungeon_button_pressed() -> void:
	SceneRouter.change_scene(DUNGEON_SELECT_SCENE)

func _on_equipment_button_pressed() -> void:
	SceneRouter.change_scene(EQUIPMENT_SCENE)

func _on_blacksmith_button_pressed() -> void:
	SceneRouter.change_scene(BLACKSMITH_SCENE)

func _on_codex_button_pressed() -> void:
	SceneRouter.change_scene(CODEX_SCENE)

func _on_gacha_button_pressed() -> void:
	if ResourceLoader.exists(GACHA_SCENE):
		SceneRouter.change_scene(GACHA_SCENE)

func _on_roster_button_pressed() -> void:
	if ResourceLoader.exists(ROSTER_SCENE):
		SceneRouter.change_scene(ROSTER_SCENE)

func _on_guild_button_pressed() -> void:
	if ResourceLoader.exists(GUILD_SCENE):
		SceneRouter.change_scene(GUILD_SCENE)
