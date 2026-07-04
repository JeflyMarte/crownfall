extends Control

const _HubNpcHelper := preload("res://scripts/ui/HubNpcHelper.gd")

const DUNGEON_SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"
const EVENT_SCENE: String = "res://scenes/event/EventScene.tscn"

@onready var _menu_vbox: VBoxContainer = $HubView/LeftMenuPanel/MenuScroll/MenuVBox
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
@onready var _label_menu_title: Label = $HubView/LeftMenuPanel/MenuScroll/MenuVBox/LabelMenuTitle
@onready var _label_event_tag: Label = $HubView/EventBanner/EventVBox/EventTextCol/LabelEventTag
@onready var _label_event_title: Label = $HubView/EventBanner/EventVBox/EventTextCol/LabelEventTitle
@onready var _label_event_desc: Label = $HubView/EventBanner/EventVBox/EventTextCol/LabelEventDesc
@onready var _label_event_timer: Label = $HubView/EventBanner/EventVBox/LabelEventTimer
@onready var _event_banner: PanelContainer = $HubView/EventBanner

func _ready() -> void:
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.HOME)
	_decorate_panels()
	_build_left_menu()
	DailyMissionSystem.missions_updated.connect(_refresh_daily_missions)
	EventSystem.event_updated.connect(_refresh_event_banner)
	$ResetTimer.timeout.connect(_update_daily_reset_label)
	$ResetTimer.timeout.connect(_refresh_event_banner)
	_event_banner.gui_input.connect(_on_event_banner_input)
	_event_banner.mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_valid_dungeon_selection()
	DailyMissionSystem.ensure_refreshed()
	EventSystem.ensure_active()
	_update_display()
	_refresh_daily_missions()
	_refresh_event_banner()
	_apply_typography()
	GameState.base_initial_view = "hub"

func _apply_typography() -> void:
	UiTypography.apply_display(_label_player_name, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_player_level, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_label_gold, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_token, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_display(_label_daily_title, UiTypography.SIZE_BODY_SMALL)
	UiTypography.apply_caption(_label_daily_reset)
	UiTypography.apply_display(_portrait_glyph, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_menu_title, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
	UiTypography.apply_caption(_label_event_tag, UiTypography.COLOR_GOLD)
	UiTypography.apply_display(_label_event_title, UiTypography.SIZE_BODY_SMALL)
	UiTypography.apply_caption(_label_event_desc)
	UiTypography.apply_caption(_label_event_timer)

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
	$HubView/DailyMissionPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$HubView/CurrencyStrip.add_theme_stylebox_override(
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
	for entry in BottomNavHelper.SIDE_MENU_ENTRIES:
		var card := NavUiTokens.make_side_menu_row(entry)
		var btn := _find_side_menu_button(card)
		if btn != null and not bool(entry.get("locked", false)):
			btn.pressed.connect(_on_menu_entry_pressed.bind(str(entry["id"])))
		_menu_vbox.add_child(card)

func _find_side_menu_button(card: Control) -> Button:
	for child in card.get_children():
		if child is Button:
			return child as Button
	return null

func _on_menu_entry_pressed(entry_id: String) -> void:
	_HubNpcHelper.queue_hint(entry_id)
	match entry_id:
		"adventure":
			_on_dungeon_button_pressed()
		"equipment":
			_on_equipment_button_pressed()
		"roster":
			_on_roster_button_pressed()
		"blacksmith":
			_on_blacksmith_button_pressed()
		"gacha":
			_on_gacha_button_pressed()
		"codex":
			_on_codex_button_pressed()

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
	_populate_currency_strip()

## ホーム中段のリソース帯（モックの5列ステータス行 / P3-UI3-001）。
## 空パネルのまま表示されていた CurrencyStrip を実データで埋める。
func _populate_currency_strip() -> void:
	var row: HBoxContainer = $HubView/CurrencyStrip/CurrencyRow
	for child in row.get_children():
		child.queue_free()
	var cleared: int = 0
	var total_dungeons: int = 0
	for d in DataRegistry.get_all_dungeon_data():
		if d == null:
			continue
		total_dungeons += 1
		if GameState.is_dungeon_cleared(str(d.id)):
			cleared += 1
	var stats: Array = [
		["%d" % GameState.gold, "ゴールド"],
		[CurrencyHelper.format_amount(), CurrencyHelper.DISPLAY_NAME],
		["%d人" % GameState.roster.size(), "冒険者"],
		["%d/%d" % [cleared, total_dungeons], "踏破"],
		["%d" % GameState.discovery_registry.size(), "発見"],
	]
	for pair in stats:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var value := Label.new()
		value.text = str(pair[0])
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.clip_text = true
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UiTypography.apply_body(value, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
		col.add_child(value)
		var caption := Label.new()
		caption.text = str(pair[1])
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.clip_text = true
		UiTypography.apply_caption(caption)
		col.add_child(caption)
		row.add_child(col)

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

func _refresh_event_banner() -> void:
	var event_data: Resource = EventSystem.get_active_event()
	_event_banner.visible = event_data != null
	if event_data == null:
		return
	_label_event_tag.text = str(event_data.tag_text)
	_label_event_title.text = str(event_data.title)
	_label_event_desc.text = EventSystem.active_modifier_summary()
	_label_event_timer.text = EventSystem.countdown_text()

func _on_event_banner_input(event: InputEvent) -> void:
	if not EventSystem.is_event_running():
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if ResourceLoader.exists(EVENT_SCENE):
				SceneRouter.change_scene(EVENT_SCENE)

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
	UiTypography.apply_menu_button(btn, false)
	var claimed: bool = bool(entry.get("claimed", false))
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
