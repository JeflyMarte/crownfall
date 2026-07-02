extends Control

const DUNGEON_SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const COLOR_GOLD: Color = Color(0.95, 0.84, 0.4, 1)
const COLOR_SUB: Color = Color(0.78, 0.74, 0.6, 1)
const COLOR_LOCKED: Color = Color(0.5, 0.48, 0.42, 1)

const LEFT_MENU_ENTRIES: Array[Dictionary] = [
	{
		"id": "adventure",
		"title": "冒険に出る",
		"icon_category": "ui",
		"icon_id": "adventure",
		"glyph": "⚔",
		"locked": false,
	},
	{
		"id": "equipment",
		"title": "英雄管理",
		"icon_category": "ui",
		"icon_id": "hero",
		"glyph": "英",
		"locked": false,
	},
	{
		"id": "blacksmith",
		"title": "鍛冶屋",
		"icon_category": "ui",
		"icon_id": "blacksmith",
		"glyph": "鍛",
		"locked": false,
	},
	{
		"id": "legacy",
		"title": "遺産の間",
		"icon_category": "ui",
		"icon_id": "legacy",
		"glyph": "遺",
		"locked": true,
	},
	{
		"id": "codex",
		"title": "図鑑",
		"icon_category": "ui",
		"icon_id": "codex",
		"glyph": "📖",
		"locked": false,
	},
	{
		"id": "merchant",
		"title": "商人",
		"icon_category": "ui",
		"icon_id": "merchant",
		"glyph": "商",
		"locked": true,
	},
	{
		"id": "settings",
		"title": "設定",
		"icon_category": "ui",
		"icon_id": "settings",
		"glyph": "⚙",
		"locked": true,
	},
]

const GRID_MENU_ENTRIES: Array[Dictionary] = [
	{
		"id": "adventure",
		"title": "冒険",
		"subtitle": "探索・戦闘",
		"icon_category": "ui",
		"icon_id": "adventure",
		"glyph": "⚔",
		"locked": false,
	},
	{
		"id": "dungeon",
		"title": "ダンジョン",
		"subtitle": "挑戦一覧",
		"icon_category": "ui",
		"icon_id": "dungeon",
		"glyph": "城",
		"locked": false,
	},
	{
		"id": "arena",
		"title": "アリーナ",
		"subtitle": "準備中",
		"icon_category": "ui",
		"icon_id": "arena",
		"glyph": "闘",
		"locked": true,
	},
	{
		"id": "merchant",
		"title": "商人",
		"subtitle": "準備中",
		"icon_category": "ui",
		"icon_id": "merchant",
		"glyph": "商",
		"locked": true,
	},
	{
		"id": "blacksmith",
		"title": "鍛冶屋",
		"subtitle": "生産・強化",
		"icon_category": "ui",
		"icon_id": "blacksmith",
		"glyph": "鍛",
		"locked": false,
	},
	{
		"id": "gacha",
		"title": "召喚",
		"subtitle": "助っ人召喚",
		"icon_category": "ui",
		"icon_id": "gacha",
		"glyph": "◆",
		"locked": false,
	},
	{
		"id": "codex",
		"title": "図鑑",
		"subtitle": "調査記録",
		"icon_category": "ui",
		"icon_id": "codex",
		"glyph": "📖",
		"locked": false,
	},
	{
		"id": "missions",
		"title": "ミッション",
		"subtitle": "準備中",
		"icon_category": "ui",
		"icon_id": "missions",
		"glyph": "任",
		"locked": true,
	},
	{
		"id": "guild",
		"title": "ギルド",
		"subtitle": "準備中",
		"icon_category": "ui",
		"icon_id": "guild",
		"glyph": "盾",
		"locked": true,
	},
]

@onready var _hub_view: Control = $HubView
@onready var _menu_grid_view: Control = $MenuGridView
@onready var _menu_vbox: VBoxContainer = $HubView/LeftMenuPanel/MenuScroll/MenuVBox
@onready var _feature_grid: GridContainer = $MenuGridView/MenuGridPanel/MenuGridVBox/FeatureGrid
@onready var _currency_row: HBoxContainer = $HubView/CurrencyStrip/CurrencyRow
@onready var _label_gold: Label = $HubView/TopBar/TopBarRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $HubView/TopBar/TopBarRow/TokenChip/TokenRow/LabelToken
@onready var _label_player_name: Label = $HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PlayerInfo/LabelPlayerName
@onready var _label_player_level: Label = $HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PlayerInfo/LabelPlayerLevel
@onready var _portrait_art: TextureRect = $HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PortraitFrame/PortraitArt
@onready var _portrait_glyph: Label = $HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PortraitFrame/PortraitGlyph
@onready var _player_card: PanelContainer = $HubView/TopBar/TopBarRow/PlayerCard
@onready var _label_daily_reset: Label = $HubView/DailyMissionPanel/DailyVBox/DailyHeader/LabelDailyReset
@onready var _mission_list: VBoxContainer = $HubView/DailyMissionPanel/DailyVBox/MissionList
@onready var _label_daily_title: Label = $HubView/DailyMissionPanel/DailyVBox/DailyHeader/LabelDailyTitle

func _ready() -> void:
	_wire_bottom_nav()
	_decorate_panels()
	_build_left_menu()
	_build_feature_grid()
	_build_currency_strip()
	DailyMissionSystem.missions_updated.connect(_refresh_daily_missions)
	$ResetTimer.timeout.connect(_update_daily_reset_label)
	_ensure_valid_dungeon_selection()
	DailyMissionSystem.ensure_refreshed()
	_update_display()
	_refresh_daily_missions()
	_apply_typography()
	_apply_initial_view()
	BottomNavHelper.highlight_tab($BottomNav/NavRow, _active_bottom_tab())

func _apply_typography() -> void:
	UiTypography.apply_display(_label_player_name, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_player_level, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_label_gold, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_token, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_display(_label_daily_title, UiTypography.SIZE_BODY_SMALL)
	UiTypography.apply_caption(_label_daily_reset)
	UiTypography.apply_display(_portrait_glyph, 18, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(
		$HubView/TitlePanel/TitleVBox/LabelSubtitle,
		UiTypography.SIZE_BODY_SMALL,
		UiTypography.COLOR_SUB
	)

func _wire_bottom_nav() -> void:
	var nav_row: HBoxContainer = $BottomNav/NavRow
	NavIconHelper.decorate_bottom_nav_row(nav_row)
	BottomNavHelper.apply_standard_labels(nav_row)
	BottomNavHelper.highlight_tab(nav_row, _active_bottom_tab())
	for child in nav_row.get_children():
		if child is Button:
			var btn := child as Button
			btn.toggle_mode = false
			for conn in btn.pressed.get_connections():
				btn.pressed.disconnect(conn["callable"])
	nav_row.get_node("NavHome").pressed.connect(_on_nav_home_pressed)
	nav_row.get_node("NavParty").pressed.connect(_on_roster_button_pressed)
	nav_row.get_node("NavAdventure").pressed.connect(_on_dungeon_button_pressed)
	nav_row.get_node("NavForge").pressed.connect(_on_blacksmith_button_pressed)
	nav_row.get_node("NavShop").pressed.connect(_on_gacha_button_pressed)
	nav_row.get_node("NavMenu").pressed.connect(_on_nav_menu_pressed)

func _on_nav_home_pressed() -> void:
	_show_hub()
	BottomNavHelper.highlight_tab($BottomNav/NavRow, BottomNavHelper.Tab.HOME)
	_update_display()
	_refresh_daily_missions()

func _on_nav_menu_pressed() -> void:
	_show_menu_grid()
	BottomNavHelper.highlight_tab($BottomNav/NavRow, BottomNavHelper.Tab.MENU)

func _active_bottom_tab() -> BottomNavHelper.Tab:
	if GameState.base_initial_view == "menu_grid":
		return BottomNavHelper.Tab.MENU
	return BottomNavHelper.Tab.HOME

func _apply_initial_view() -> void:
	if GameState.base_initial_view == "menu_grid":
		_show_menu_grid()
	else:
		_show_hub()
	GameState.base_initial_view = "hub"

func _show_hub() -> void:
	_hub_view.visible = true
	_menu_grid_view.visible = false

func _show_menu_grid() -> void:
	_hub_view.visible = false
	_menu_grid_view.visible = true

func _decorate_panels() -> void:
	_player_card.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$HubView/LeftMenuPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$HubView/EventBanner.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	$HubView/CurrencyStrip.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$HubView/DailyMissionPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$MenuGridView/MenuGridPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PortraitFrame.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)

func _build_left_menu() -> void:
	var to_remove: Array[Node] = []
	for child in _menu_vbox.get_children():
		if child.name != "LabelMenuTitle" and child.name != "SepMenu":
			to_remove.append(child)
	for child in to_remove:
		child.free()
	for entry in LEFT_MENU_ENTRIES:
		_menu_vbox.add_child(_make_side_menu_card(entry))

func _build_feature_grid() -> void:
	for child in _feature_grid.get_children():
		child.queue_free()
	for entry in GRID_MENU_ENTRIES:
		_feature_grid.add_child(_make_grid_menu_card(entry))

func _build_currency_strip() -> void:
	for child in _currency_row.get_children():
		child.queue_free()
	_currency_row.add_child(_make_currency_column("ゴールド", str(GameState.gold), "ui", "gold", true))
	_currency_row.add_child(
		_make_currency_column(CurrencyHelper.DISPLAY_NAME, CurrencyHelper.format_amount(), "currency", "arcane_crystal", true)
	)
	_currency_row.add_child(_make_currency_column("探索チケット", "準備中", "", "", false))
	_currency_row.add_child(_make_currency_column("プレイヤーランク", "準備中", "", "", false))

func _make_currency_column(label_text: String, value_text: String, icon_cat: String, icon_id: String, live: bool) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	if not icon_cat.is_empty() and not icon_id.is_empty():
		var tex := IconPaths.get_icon_texture(icon_id, icon_cat)
		if tex != null:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.custom_minimum_size = Vector2(24, 24)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			col.add_child(icon)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(
		value,
		UiTypography.SIZE_BODY_SMALL,
		UiTypography.COLOR_GOLD if live else UiTypography.COLOR_LOCKED
	)
	col.add_child(value)
	var caption := Label.new()
	caption.text = label_text
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(caption)
	col.add_child(caption)
	return col

func _make_side_menu_card(entry: Dictionary) -> Control:
	var locked: bool = bool(entry.get("locked", false))
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(168, 52)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = locked
	btn.tooltip_text = "準備中" if locked else ""
	btn.text = str(entry["title"]) + (" 🔒" if locked else "")
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var category: String = str(entry.get("icon_category", ""))
	var icon_id: String = str(entry.get("icon_id", ""))
	if not category.is_empty() and not icon_id.is_empty():
		var tex: Texture2D = IconPaths.get_icon_texture(icon_id, category)
		if tex != null:
			btn.icon = tex
			btn.add_theme_constant_override("icon_max_width", NavIconHelper.ICON_SIZE_MENU)
			btn.add_theme_constant_override("icon_max_height", NavIconHelper.ICON_SIZE_MENU)
	UiTypography.apply_button(btn, locked)
	if not locked:
		btn.pressed.connect(_on_menu_entry_pressed.bind(str(entry["id"])))
	return btn

func _make_grid_menu_card(entry: Dictionary) -> Control:
	var locked: bool = bool(entry.get("locked", false))
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(108, 100)
	panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var btn := Button.new()
	btn.flat = true
	btn.disabled = locked
	btn.tooltip_text = "準備中" if locked else ""
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	if not locked:
		btn.pressed.connect(_on_menu_entry_pressed.bind(str(entry["id"])))
	panel.add_child(btn)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(col)
	col.add_child(_make_entry_icon(entry, 32))
	var title := Label.new()
	title.text = str(entry["title"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(
		title,
		UiTypography.SIZE_BODY_SMALL,
		UiTypography.COLOR_LOCKED if locked else UiTypography.COLOR_GOLD
	)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)
	var subtitle := Label.new()
	subtitle.text = str(entry.get("subtitle", ""))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(subtitle)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(subtitle)
	return panel

func _make_entry_icon(entry: Dictionary, size_px: int) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(size_px, size_px)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var category: String = str(entry.get("icon_category", ""))
	var icon_id: String = str(entry.get("icon_id", ""))
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
		UiTypography.apply_display(glyph, 18, UiTypography.COLOR_GOLD)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(glyph)
	return frame

func _on_menu_entry_pressed(entry_id: String) -> void:
	match entry_id:
		"adventure", "dungeon":
			_on_dungeon_button_pressed()
		"equipment":
			_on_equipment_button_pressed()
		"blacksmith":
			_on_blacksmith_button_pressed()
		"codex":
			_on_codex_button_pressed()
		"gacha":
			_on_gacha_button_pressed()
		"roster":
			_on_roster_button_pressed()

func _ensure_valid_dungeon_selection() -> void:
	if not _is_dungeon_available(GameState.current_dungeon_id):
		GameState.current_dungeon_id = Constants.DEFAULT_DUNGEON_ID

func _is_dungeon_available(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	return DataRegistry.get_dungeon_data(dungeon_id) != null

func _update_display() -> void:
	_update_currency()
	_update_player_card()
	_build_currency_strip()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()
	$HubView/TopBar/TopBarRow/TokenChip.tooltip_text = CurrencyHelper.DISPLAY_NAME

func _update_player_card() -> void:
	if GameState.party_members.is_empty():
		_label_player_name.text = "指揮官"
		_label_player_level.text = "Lv.1"
		_portrait_art.texture = null
		_portrait_art.visible = false
		_portrait_glyph.visible = true
		_portrait_glyph.text = "英"
		return
	var member: Resource = GameState.party_members[0]
	_label_player_name.text = str(member.display_name) if str(member.display_name) != "" else "冒険者"
	_label_player_level.text = "Lv.%d" % int(member.level)
	var job_id: String = str(member.job_id)
	var tex := IconPaths.get_icon_texture(job_id, "chr")
	_portrait_art.texture = tex
	_portrait_art.visible = tex != null
	_portrait_glyph.visible = tex == null
	if tex == null:
		_portrait_glyph.text = "英"

func _refresh_daily_missions() -> void:
	_update_daily_reset_label()
	_label_daily_title.text = (
		"デイリーミッション ●" if DailyMissionSystem.has_claimable() else "デイリーミッション"
	)
	for child in _mission_list.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = DailyMissionSystem.get_entries()
	for i in entries.size():
		_mission_list.add_child(_make_daily_row(i, entries[i]))

func _update_daily_reset_label() -> void:
	_label_daily_reset.text = "リセットまで %s" % DailyMissionSystem.reset_countdown_text()

func _make_daily_row(index: int, entry: Dictionary) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	wrap.add_child(row)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text = str(entry.get("title", ""))
	UiTypography.apply_body(title, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	row.add_child(title)
	var progress_label := Label.new()
	var progress: int = int(entry.get("progress", 0))
	var target: int = int(entry.get("target_count", 1))
	progress_label.text = "%d/%d" % [progress, target]
	UiTypography.apply_caption(progress_label)
	row.add_child(progress_label)
	var reward := Label.new()
	reward.text = _format_daily_reward(entry)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_caption(reward)
	row.add_child(reward)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(60, 32)
	UiTypography.apply_button(btn, false)
	var claimed: bool = bool(entry.get("claimed", false))
	var complete: bool = bool(entry.get("complete", false))
	if claimed:
		btn.text = "済"
		btn.disabled = true
	elif bool(entry.get("can_claim", false)):
		btn.text = "受取"
		btn.pressed.connect(_on_daily_claim_pressed.bind(index))
	else:
		btn.text = "移動"
		btn.disabled = true
	row.add_child(btn)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = maxf(float(target), 1.0)
	bar.value = float(progress)
	bar.show_percentage = false
	wrap.add_child(bar)
	return wrap

func _format_daily_reward(entry: Dictionary) -> String:
	var parts: PackedStringArray = []
	var gold: int = int(entry.get("reward_gold", 0))
	var token: int = int(entry.get("reward_gacha_token", 0))
	var mat_id: String = str(entry.get("reward_material_id", ""))
	var mat_qty: int = int(entry.get("reward_material_qty", 0))
	if gold > 0:
		parts.append("%dG" % gold)
	if token > 0:
		parts.append("%s×%d" % [CurrencyHelper.DISPLAY_NAME, token])
	if not mat_id.is_empty() and mat_qty > 0:
		parts.append("%s×%d" % [DataRegistry.get_material_name(mat_id), mat_qty])
	if parts.is_empty():
		return "—"
	return " / ".join(parts)

func _on_daily_claim_pressed(index: int) -> void:
	var result: Dictionary = DailyMissionSystem.claim(index)
	if not bool(result.get("ok", false)):
		return
	SaveManager.save_game()
	_update_display()
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
