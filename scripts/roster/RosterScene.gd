extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const DUNGEON_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const FORMATION_SLOT_COUNT: int = 4
const FORMATION_CELL_PX: int = 132
const GRID_COLUMNS: int = 4
const GRID_H_SEPARATION: int = 6
const SLOT_H_SEPARATION: int = 6
const FOOTER_HEIGHT: int = 60
const TOOLBAR_BTN_H: int = 38
## Header → タブ帯 → 本文 の余白（タブが金線に食い込まないよう十分空ける）。
const HEADER_CONTENT_GAP: float = 10.0
const TOOLBAR_BAND_HEIGHT: float = 46.0
const TOOLBAR_SCROLL_GAP: float = 10.0
const _META_BODY_BASE_TOP: StringName = &"_cf_body_base_top"
const _META_BODY_BASE_BOTTOM: StringName = &"_cf_body_base_bottom"

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_FRONT: Color = Color(0.55, 0.72, 0.95)
const COLOR_BACK: Color = Color(0.65, 0.85, 0.55)
const COLOR_EMPTY: Color = Color(0.35, 0.33, 0.30)
const COLOR_PICK: Color = Color(0.95, 0.78, 0.35)

const _FRONT_JOB_IDS: Array[String] = ["swordsman", "vanguard"]
const _RECOMMENDED_JOB_ORDER: Array[String] = [
	"vanguard", "swordsman", "ranger", "alchemist", "beast_tamer",
]
const _ROLE_FILTER_ORDER: Array[String] = ["all", "tank", "dps", "scout", "support"]

var _selected: Array = []
var _formation_slots: Array = [null, null, null, null]
var _formation_pick_slot: int = -1
var _active_pick_slot: int = -1
var _sort_by_rarity: bool = true
var _role_filter_index: int = 0
## false=冒険者一覧 / true=ペット（オトモ）一覧
var _show_pets: bool = false
var _formation_cells: Array[PanelContainer] = []

@onready var _main_vbox: VBoxContainer = $MainScroll/MainVBox
@onready var _main_scroll: ScrollContainer = $MainScroll
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _label_power: Label = $Header/HeaderRow/LabelTitle
@onready var _label_power_legacy: Label = $MainScroll/MainVBox/PowerSection/LabelPower
@onready var _active_party_row: HBoxContainer = $MainScroll/MainVBox/ActivePartyScroll/ActivePartyRow
@onready var _roster_grid: GridContainer = $MainScroll/MainVBox/RosterGrid
@onready var _label_status: Label = $MainScroll/MainVBox/LabelStatus
@onready var _formation_overlay: CanvasLayer = $FormationOverlay
@onready var _formation_board: VBoxContainer = $FormationOverlay/FormationPanel/FormationVBox/FormationBoard
@onready var _button_save: Button = $FooterRow/ButtonSave
var _toolbar_band: MarginContainer
var _btn_recommend: Button
var _btn_formation: Button

func _ready() -> void:
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.PARTY)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	_ensure_toolbar_band()
	_btn_recommend.pressed.connect(_on_recommend_pressed)
	_btn_formation.pressed.connect(_open_formation_overlay)
	$MainScroll/MainVBox/ListHeader/ButtonSort.pressed.connect(_on_sort_pressed)
	$MainScroll/MainVBox/ListHeader/ButtonRoleFilter.pressed.connect(_on_role_filter_pressed)
	$MainScroll/MainVBox/ListHeader/ButtonPet.pressed.connect(_on_pet_tab_pressed)
	$FooterRow/ButtonReset.pressed.connect(_on_reset_pressed)
	$FooterRow/ButtonSave.pressed.connect(_on_save_pressed)
	$FormationOverlay/Dim.gui_input.connect(_on_formation_dim_input)
	$FormationOverlay/FormationPanel/FormationVBox/ButtonFormationClose.pressed.connect(_close_formation_overlay)
	$FormationOverlay/FormationPanel/FormationVBox/FormationPresetRow/ButtonPresetFront.pressed.connect(
		_on_formation_preset_pressed.bind("front")
	)
	$FormationOverlay/FormationPanel/FormationVBox/FormationPresetRow/ButtonPresetBalanced.pressed.connect(
		_on_formation_preset_pressed.bind("balanced")
	)
	$FormationOverlay/FormationPanel/FormationVBox/FormationPresetRow/ButtonPresetBack.pressed.connect(
		_on_formation_preset_pressed.bind("back")
	)
	_selected = GameState.party_members.duplicate()
	_init_formation_slots_from_party()
	_apply_panel_styles()
	_configure_layout()
	_apply_typography()
	_apply_toolbar_buttons()
	_build_formation_grid()
	_refresh_all()
	call_deferred("_refresh_layout")
	## chrome 遅延再適用のあともタブ帯・本文を Header 下へ再同期する。
	var tree: SceneTree = get_tree()
	if tree != null:
		for delay_sec: float in [0.05, 0.12, 0.25]:
			var timer: SceneTreeTimer = tree.create_timer(delay_sec)
			timer.timeout.connect(_configure_layout)

func _refresh_layout() -> void:
	_configure_layout()
	_rebuild_active_party_row()
	_rebuild_roster_grid()

func _configure_layout() -> void:
	_ensure_toolbar_band()
	HubLayoutHelper.apply_horizontal_insets(_main_scroll)
	_layout_toolbar_and_scroll()
	# 実測ナビ高（パネル余白込み）でフッターを配置し、下ナビとの重なりを防ぐ（P3-UI3-001）
	var nav_h: float = maxf(NavUiTokens.BOTTOM_NAV_HEIGHT, $BottomNav.size.y) + 8.0
	var footer_top: float = -(nav_h + float(FOOTER_HEIGHT))
	_main_scroll.offset_bottom = footer_top
	var footer_row: Control = $FooterRow
	footer_row.offset_top = footer_top
	footer_row.offset_bottom = -nav_h
	footer_row.z_index = 15
	_main_vbox.add_theme_constant_override("separation", 4)
	_roster_grid.add_theme_constant_override("h_separation", GRID_H_SEPARATION)
	_roster_grid.add_theme_constant_override("v_separation", GRID_H_SEPARATION)
	_active_party_row.add_theme_constant_override("separation", SLOT_H_SEPARATION)
	_main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content_w: float = _layout_content_width()
	if content_w > 1.0:
		_main_vbox.custom_minimum_size.x = content_w
	_roster_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_active_party_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_active_party_row.custom_minimum_size = Vector2(0, _active_card_min_height())


## おすすめ編成／陣形を Header 直下の固定帯へ移し、スクロール本文と分離する。
func _ensure_toolbar_band() -> void:
	if _toolbar_band != null and is_instance_valid(_toolbar_band):
		return
	var power_section: Control = $MainScroll/MainVBox/PowerSection as Control
	var row: HBoxContainer = power_section.get_node_or_null("PowerButtonRow") as HBoxContainer
	if row == null:
		return
	_btn_recommend = row.get_node("ButtonRecommend") as Button
	_btn_formation = row.get_node("ButtonFormation") as Button
	_toolbar_band = MarginContainer.new()
	_toolbar_band.name = "ToolbarBand"
	_toolbar_band.add_theme_constant_override("margin_left", 12)
	_toolbar_band.add_theme_constant_override("margin_right", 12)
	_toolbar_band.add_theme_constant_override("margin_top", 0)
	_toolbar_band.add_theme_constant_override("margin_bottom", 0)
	_toolbar_band.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_toolbar_band)
	move_child(_toolbar_band, $Header.get_index() + 1)
	row.get_parent().remove_child(row)
	_toolbar_band.add_child(row)
	## 旧 PowerSection（非表示ラベルのみ）はレイアウトから外す。
	if power_section != null:
		power_section.visible = false
		power_section.custom_minimum_size = Vector2.ZERO


## Header 下にタブ帯、その下に一覧スクロールを積む（金線への食い込み防止）。
func _layout_toolbar_and_scroll() -> void:
	var header: Control = $Header as Control
	if header == null or _main_scroll == null or _toolbar_band == null:
		return
	var top_inset: float = 0.0
	if SafeAreaHelper.should_apply_chrome():
		top_inset = SafeAreaHelper.top_inset()
	var header_bottom: float = header.offset_bottom
	if header.size.y > 1.0:
		header_bottom = maxf(header_bottom, header.offset_top + header.size.y)
	var band_top: float = header_bottom + HEADER_CONTENT_GAP
	var band_bottom: float = band_top + TOOLBAR_BAND_HEIGHT
	_toolbar_band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toolbar_band.offset_left = 0.0
	_toolbar_band.offset_right = 0.0
	_toolbar_band.offset_top = band_top
	_toolbar_band.offset_bottom = band_bottom
	_toolbar_band.z_index = 5
	## chrome 遅延再適用用の設計座標（inset 抜き）。
	_toolbar_band.set_meta(_META_BODY_BASE_TOP, band_top - top_inset)
	_toolbar_band.set_meta(_META_BODY_BASE_BOTTOM, band_bottom - top_inset)
	var scroll_top: float = band_bottom + TOOLBAR_SCROLL_GAP
	_main_scroll.offset_top = scroll_top
	_main_scroll.set_meta(_META_BODY_BASE_TOP, scroll_top - top_inset)

func _apply_typography() -> void:
	_label_power_legacy.visible = false
	_label_power.text = "総合戦力 0"
	UiTypography.apply_screen_title(_label_power)
	UiTypography.apply_body(_label_gold, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_token, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(
		$MainScroll/MainVBox/ListHeader/LabelListTitle,
		UiTypography.SIZE_CAPTION
	)
	UiTypography.apply_menu_button($FooterRow/ButtonReset, false)
	UiTypography.apply_menu_button($FooterRow/ButtonSave, false)
	$FooterRow/ButtonReset.custom_minimum_size = Vector2(0, 48)
	$FooterRow/ButtonSave.custom_minimum_size = Vector2(0, 48)

func _apply_toolbar_buttons() -> void:
	var compact := _compact_toolbar_style()
	_ensure_toolbar_band()
	var specs: Array[Dictionary] = [
		{"btn": _btn_recommend, "min": Vector2(0, TOOLBAR_BTN_H), "expand": true},
		{"btn": _btn_formation, "min": Vector2(0, TOOLBAR_BTN_H), "expand": true},
		{
			"btn": $MainScroll/MainVBox/ListHeader/ButtonSort,
			"min": Vector2(0, TOOLBAR_BTN_H),
			"expand": true,
		},
		{
			"btn": $MainScroll/MainVBox/ListHeader/ButtonRoleFilter,
			"min": Vector2(0, TOOLBAR_BTN_H),
			"expand": true,
		},
		{
			"btn": $MainScroll/MainVBox/ListHeader/ButtonPet,
			"min": Vector2(0, TOOLBAR_BTN_H),
			"expand": true,
		},
	]
	for spec in specs:
		var btn: Button = spec["btn"] as Button
		if btn == null:
			continue
		UiTypography.apply_menu_button(btn, false)
		btn.add_theme_font_size_override("font_size", UiTypography.SIZE_CAPTION)
		btn.clip_text = true
		btn.custom_minimum_size = spec["min"]
		btn.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if bool(spec.get("expand", false))
			else Control.SIZE_SHRINK_BEGIN
		)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			btn.add_theme_stylebox_override(state, compact)

func _compact_toolbar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.05, 0.92)
	style.border_color = Color(0.55, 0.45, 0.18, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _layout_content_width() -> float:
	return HubLayoutHelper.scroll_content_width(_main_scroll)

func _slot_card_width() -> int:
	return HubLayoutHelper.column_width(
		_layout_content_width(),
		FORMATION_SLOT_COUNT,
		SLOT_H_SEPARATION
	)

func _grid_cell_width() -> int:
	return HubLayoutHelper.column_width(
		_layout_content_width(),
		GRID_COLUMNS,
		GRID_H_SEPARATION
	)

func _grid_cell_height() -> int:
	return _grid_cell_width()

func _active_card_min_height() -> int:
	return int(float(_slot_card_width()) * 1.62)

func _apply_panel_styles() -> void:
	$FormationOverlay/FormationPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_configure_layout()
		_rebuild_active_party_row()
		_rebuild_roster_grid()

func _refresh_all() -> void:
	_update_currency()
	_refresh_power_label()
	_rebuild_active_party_row()
	_rebuild_roster_grid()
	_refresh_formation_grid()
	_update_save_button()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

func _refresh_power_label() -> void:
	var members: Array = _active_members_in_slot_order()
	_label_power.text = UiTypography.decorate_title_text(
		"総合戦力 %s" % _format_number(RosterUiHelper.compute_combat_power(members))
	)

func _format_number(value: int) -> String:
	var text: String = str(value)
	if text.length() <= 3:
		return text
	var out: String = ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3, 3) + out
		text = text.substr(0, text.length() - 3)
	return text + out

func _init_formation_slots_from_party() -> void:
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = null
	var placed: Dictionary = {}
	for member in GameState.party_members:
		if member == null:
			continue
		var slot: int = GameState.get_member_formation_slot(member)
		if slot < 0 or slot >= FORMATION_SLOT_COUNT:
			continue
		if _formation_slots[slot] != null:
			continue
		_formation_slots[slot] = member
		placed[member] = true
	## 空き枠は「未配置メンバー」から埋める。party index 直埋めは複製の原因。
	for member in GameState.party_members:
		if member == null or placed.has(member):
			continue
		for i in FORMATION_SLOT_COUNT:
			if _formation_slots[i] == null:
				_formation_slots[i] = member
				placed[member] = true
				break
	_dedupe_formation_slots_local()

func _dedupe_formation_slots_local() -> void:
	var seen: Dictionary = {}
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member == null:
			continue
		if seen.has(member):
			_formation_slots[i] = null
			continue
		seen[member] = true

func _sync_formation_slots_from_selection() -> void:
	## 空きスロット（前列空＋後列のみ等）を詰めない。詰めると後列が前列表示になる。
	var seen: Dictionary = {}
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member == null:
			continue
		if not _selected.has(member) or seen.has(member):
			_formation_slots[i] = null
			continue
		seen[member] = true
	for adv in _selected:
		if adv == null or seen.has(adv):
			continue
		for i in FORMATION_SLOT_COUNT:
			if _formation_slots[i] == null:
				_formation_slots[i] = adv
				seen[adv] = true
				break
	_dedupe_formation_slots_local()
	_apply_formation_rows_from_slots()

func _active_members_in_slot_order() -> Array:
	var members: Array = []
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member != null and _selected.has(member):
			members.append(member)
	return members

func _party_index_for_member(member: Resource) -> int:
	for i in _selected.size():
		if _selected[i] == member:
			return i
	return -1

func _rebuild_active_party_row() -> void:
	for child in _active_party_row.get_children():
		child.queue_free()
	for slot_index in FORMATION_SLOT_COUNT:
		_active_party_row.add_child(_make_active_party_card(slot_index))

func _make_active_party_card(slot_index: int) -> Control:
	var member: Resource = _formation_slots[slot_index]
	var card_w: int = _slot_card_width()
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	panel.add_theme_stylebox_override(
		"panel",
		RosterUiHelper.card_panel_style(member != null, slot_index == 0)
	)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)
	if member == null:
		var empty := Label.new()
		empty.text = "空き"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.custom_minimum_size = Vector2(0, _active_card_min_height() - 8)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLOR_EMPTY)
		UiTypography.apply_body(empty, UiTypography.SIZE_CAPTION, COLOR_EMPTY)
		vbox.add_child(empty)
		panel.gui_input.connect(_on_active_card_input.bind(slot_index))
		return panel
	var portrait_tex: Texture2D = RosterUiHelper.get_member_portrait_texture(member)
	var portrait_px: int = clampi(card_w - 8, 56, 92)
	if portrait_tex != null:
		var portrait := TextureRect.new()
		portrait.texture = portrait_tex
		portrait.custom_minimum_size = Vector2(portrait_px, portrait_px)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(portrait)
	var name_lbl := Label.new()
	name_lbl.text = RosterUiHelper.short_display_name(str(member.display_name))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_CAPTION, UiTypography.COLOR_BODY)
	vbox.add_child(name_lbl)
	var stars := Label.new()
	stars.text = "%s  Lv%d" % [RosterUiHelper.stars_text(int(member.rarity)), int(member.level)]
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(stars, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	vbox.add_child(stars)
	var job_lbl := Label.new()
	job_lbl.text = RosterUiHelper.job_display_name(member)
	job_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(job_lbl, UiTypography.SIZE_CAPTION)
	vbox.add_child(job_lbl)
	var stats: Dictionary = RosterUiHelper.compute_member_stats(member, _party_index_for_member(member))
	vbox.add_child(_make_card_stat_row("attack", "攻撃力", int(stats.get("attack", 0))))
	vbox.add_child(_make_card_stat_row("defense", "防御力", int(stats.get("defense", 0))))
	vbox.add_child(_make_card_stat_row("hp", "HP", int(stats.get("hp", 0))))
	var row_lbl := Label.new()
	var is_back: bool = GameState.get_member_formation_row(member) == GameState.FORMATION_BACK
	row_lbl.text = "後列" if is_back else "前列"
	row_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(row_lbl, COLOR_BACK if is_back else COLOR_FRONT)
	vbox.add_child(row_lbl)
	var detail := Button.new()
	detail.text = "詳細"
	UiTypography.apply_menu_button(detail, false)
	detail.add_theme_font_size_override("font_size", UiTypography.SIZE_CAPTION)
	detail.pressed.connect(_on_detail_pressed.bind(member))
	vbox.add_child(detail)
	panel.gui_input.connect(_on_active_card_input.bind(slot_index))
	if _active_pick_slot == slot_index:
		panel.add_theme_stylebox_override("panel", _pick_style())
	return panel

func _make_card_stat_row(stat_key: String, label_text: String, value: int) -> Control:
	const CARD_STAT_ICON_PX: int = 16
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tex: Texture2D = EquipmentUiTokens.stat_icon(stat_key)
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(CARD_STAT_ICON_PX, CARD_STAT_ICON_PX)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_CAPTION, COLOR_SUB)
	row.add_child(name_lbl)
	var val_lbl := Label.new()
	val_lbl.text = str(value)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_body(val_lbl, UiTypography.SIZE_CAPTION, UiTypography.COLOR_BODY)
	row.add_child(val_lbl)
	return row

func _pick_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.94)
	style.border_color = COLOR_PICK
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style

func _on_active_card_input(event: InputEvent, slot_index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _formation_slots[slot_index] == null:
		return
	if _active_pick_slot < 0:
		_active_pick_slot = slot_index
		_label_status.text = "入れ替え先を下のリストから選んでください"
	else:
		if _active_pick_slot != slot_index:
			var tmp = _formation_slots[_active_pick_slot]
			_formation_slots[_active_pick_slot] = _formation_slots[slot_index]
			_formation_slots[slot_index] = tmp
			_apply_formation_rows_from_slots()
			_label_status.text = "パーティ内の並びを入れ替えました"
		else:
			_label_status.text = ""
		_active_pick_slot = -1
	_rebuild_active_party_row()
	_rebuild_roster_grid()

func _on_detail_pressed(member: Resource) -> void:
	var party: Array = _ordered_party_from_formation()
	if not GameState.set_active_party(party):
		_label_status.text = "詳細を開くには有効な編成が必要です"
		return
	var roster: Array = GameState.get_roster()
	var roster_idx: int = roster.find(member)
	if roster_idx < 0:
		roster_idx = 0
	GameState.equipment_focus_member_index = roster_idx
	SceneRouter.change_scene(EQUIPMENT_SCENE)

func _rebuild_roster_grid() -> void:
	for child in _roster_grid.get_children():
		child.queue_free()
	if _show_pets:
		var pet: Resource = PetSystem.ensure_starter_pet()
		if pet != null:
			_roster_grid.add_child(_make_roster_grid_card(pet))
		else:
			var empty_pet := Label.new()
			empty_pet.text = "ペットがいません"
			empty_pet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_pet.add_theme_color_override("font_color", COLOR_SUB)
			_roster_grid.add_child(empty_pet)
		return
	var roster: Array = GameState.get_roster().duplicate()
	roster = roster.filter(func(adv: Resource) -> bool: return _passes_role_filter(adv))
	roster.sort_custom(func(a: Resource, b: Resource) -> bool: return _sort_roster_cmp(a, b))
	for adv in roster:
		_roster_grid.add_child(_make_roster_grid_card(adv))
	if roster.is_empty():
		var empty := Label.new()
		empty.text = "該当キャラがいません"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLOR_SUB)
		_roster_grid.add_child(empty)

func _passes_role_filter(adv: Resource) -> bool:
	var filter_id: String = _ROLE_FILTER_ORDER[_role_filter_index]
	if filter_id == "all":
		return true
	var mods: Dictionary = JobStatCalculator.get_member_modifiers(adv)
	return str(mods.get("role", "")) == filter_id

func _on_pet_tab_pressed() -> void:
	_show_pets = true
	_active_pick_slot = -1
	_update_list_header_title()
	_rebuild_roster_grid()
	_rebuild_active_party_row()

func _update_list_header_title() -> void:
	$MainScroll/MainVBox/ListHeader/LabelListTitle.text = (
		"ペット一覧" if _show_pets else "キャラクター一覧"
	)

func _sort_roster_cmp(a: Resource, b: Resource) -> bool:
	if _sort_by_rarity:
		if int(a.rarity) != int(b.rarity):
			return int(a.rarity) > int(b.rarity)
		if int(a.level) != int(b.level):
			return int(a.level) > int(b.level)
	else:
		if int(a.level) != int(b.level):
			return int(a.level) > int(b.level)
		if int(a.rarity) != int(b.rarity):
			return int(a.rarity) > int(b.rarity)
	return str(a.display_name) < str(b.display_name)

func _make_roster_grid_card(adv: Resource) -> Control:
	var is_pet: bool = PetSystem.is_pet_member(adv)
	var in_party: bool = (not is_pet) and _selected.has(adv)
	var picking: bool = (not is_pet) and _active_pick_slot >= 0
	var cell_h: int = _grid_cell_height()
	var wrapper := PanelContainer.new()
	wrapper.custom_minimum_size = Vector2(0, cell_h)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_pet:
		wrapper.add_theme_stylebox_override("panel", RosterUiHelper.card_panel_style(true, false))
	elif picking and not in_party:
		wrapper.add_theme_stylebox_override("panel", _pick_style())
	else:
		wrapper.add_theme_stylebox_override("panel", RosterUiHelper.card_panel_style(in_party, false))
	# 入れ替え選択中はリストを暗くせず選べることを示す。通常時のみ編成中を暗くする。
	if in_party and not picking:
		wrapper.modulate = Color(0.42, 0.42, 0.42, 1.0)
	var btn := Button.new()
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, cell_h)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_toggle_selection.bind(adv))
	wrapper.add_child(btn)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	var tex: Texture2D = RosterUiHelper.get_member_portrait_texture(adv)
	var icon_area := Control.new()
	icon_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_area.custom_minimum_size = Vector2(0, cell_h - 34)
	icon_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_area)
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_area.add_child(icon)
	var bottom_bar := PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 24)
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.04, 0.03, 0.02, 0.82)
	bar_style.content_margin_left = 4
	bar_style.content_margin_top = 1
	bar_style.content_margin_right = 4
	bar_style.content_margin_bottom = 1
	bottom_bar.add_theme_stylebox_override("panel", bar_style)
	vbox.add_child(bottom_bar)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 4)
	info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_bar.add_child(info_row)
	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d" % int(adv.level)
	lv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_caption(lv_lbl)
	lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_child(lv_lbl)
	var star_lbl := Label.new()
	star_lbl.text = RosterUiHelper.stars_text(int(adv.rarity))
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_caption(star_lbl, UiTypography.COLOR_GOLD)
	star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_child(star_lbl)
	return wrapper

func _toggle_selection(adv: Resource) -> void:
	if PetSystem.is_pet_member(adv):
		_label_status.text = "%sは常時随伴するオトモです（4人編成には入りません）" % RosterUiHelper.short_display_name(
			str(adv.display_name)
		)
		return
	if _active_pick_slot >= 0:
		_apply_active_pick_with_roster(adv)
		return
	if _selected.has(adv):
		if _selected.size() > 1:
			_selected.erase(adv)
	else:
		if _selected.size() < GameState.ACTIVE_PARTY_SIZE:
			_selected.append(adv)
	_sync_formation_slots_from_selection()
	_active_pick_slot = -1
	_refresh_all()


## 上段パーティ枠を選んだあとに下リストを押すと、その枠のメンバーを入れ替える。
func _apply_active_pick_with_roster(adv: Resource) -> void:
	var slot: int = _active_pick_slot
	_active_pick_slot = -1
	if slot < 0 or slot >= FORMATION_SLOT_COUNT or adv == null:
		_rebuild_active_party_row()
		_rebuild_roster_grid()
		return
	var current: Resource = _formation_slots[slot]
	if adv == current:
		_label_status.text = ""
		_rebuild_active_party_row()
		_rebuild_roster_grid()
		return
	if _selected.has(adv):
		var other_slot: int = -1
		for i in FORMATION_SLOT_COUNT:
			if _formation_slots[i] == adv:
				other_slot = i
				break
		if other_slot >= 0:
			_formation_slots[slot] = adv
			_formation_slots[other_slot] = current
		_apply_formation_rows_from_slots()
		_label_status.text = "パーティ内の並びを入れ替えました"
	else:
		if current != null:
			_selected.erase(current)
		if not _selected.has(adv):
			_selected.append(adv)
		_formation_slots[slot] = adv
		_apply_formation_rows_from_slots()
		_label_status.text = "メンバーを入れ替えました"
	_refresh_all()

func _on_recommend_pressed() -> void:
	var roster: Array = GameState.get_roster()
	var picked: Array = []
	for job_id in _RECOMMENDED_JOB_ORDER:
		for adv in roster:
			if str(adv.job_id) == job_id and adv not in picked:
				picked.append(adv)
				break
	for adv in roster:
		if adv not in picked:
			picked.append(adv)
		if picked.size() >= GameState.ACTIVE_PARTY_SIZE:
			break
	_selected = picked.slice(0, mini(GameState.ACTIVE_PARTY_SIZE, picked.size()))
	_assign_formation_by_role(_selected, true)
	_active_pick_slot = -1
	_formation_pick_slot = -1
	_label_status.text = "おすすめ編成を適用しました"
	_refresh_all()

func _on_reset_pressed() -> void:
	var roster: Array = GameState.get_roster()
	_selected = []
	for i in mini(GameState.ACTIVE_PARTY_SIZE, roster.size()):
		_selected.append(roster[i])
	_place_members_in_slots(_selected, [0, 1, 2, 3])
	_apply_formation_rows_from_slots()
	_active_pick_slot = -1
	_formation_pick_slot = -1
	_label_status.text = "編成を初期状態に戻しました"
	_refresh_all()

func _on_sort_pressed() -> void:
	if _show_pets:
		_show_pets = false
		_update_list_header_title()
		_rebuild_roster_grid()
		return
	_sort_by_rarity = not _sort_by_rarity
	$MainScroll/MainVBox/ListHeader/ButtonSort.text = "レアリティ順" if _sort_by_rarity else "レベル順"
	_rebuild_roster_grid()

func _on_role_filter_pressed() -> void:
	if _show_pets:
		_show_pets = false
		_update_list_header_title()
		_rebuild_roster_grid()
		return
	_role_filter_index = (_role_filter_index + 1) % _ROLE_FILTER_ORDER.size()
	var filter_id: String = _ROLE_FILTER_ORDER[_role_filter_index]
	$MainScroll/MainVBox/ListHeader/ButtonRoleFilter.text = str(
		RosterUiHelper.ROLE_FILTER_LABELS.get(filter_id, filter_id)
	)
	_rebuild_roster_grid()

func _on_save_pressed() -> void:
	_sync_formation_slots_from_selection()
	_apply_formation_rows_from_slots()
	var party: Array = _ordered_party_from_formation()
	if not GameState.set_active_party(party):
		_label_status.text = "編成の変更に失敗しました（1〜%d名・重複不可）" % GameState.ACTIVE_PARTY_SIZE
		return
	SaveManager.save_game()
	_label_status.text = "編成を保存しました"

func _ordered_party_from_formation() -> Array:
	var ordered: Array = []
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member != null and _selected.has(member) and not ordered.has(member):
			ordered.append(member)
	for adv in _selected:
		if not ordered.has(adv):
			ordered.append(adv)
	return ordered

func _update_save_button() -> void:
	var count: int = _selected.size()
	_button_save.disabled = count < 1 or count > GameState.ACTIVE_PARTY_SIZE

func _open_formation_overlay() -> void:
	_sync_formation_slots_from_selection()
	_formation_pick_slot = -1
	_refresh_formation_grid()
	_formation_overlay.visible = true

func _close_formation_overlay() -> void:
	_formation_overlay.visible = false
	_formation_pick_slot = -1
	_refresh_formation_grid()
	_rebuild_active_party_row()
	_refresh_power_label()

func _on_formation_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_formation_overlay()

func _build_formation_grid() -> void:
	for child in _formation_board.get_children():
		child.queue_free()
	_formation_cells.clear()
	_add_formation_row_label("— 前列 —", COLOR_FRONT)
	_formation_board.add_child(_make_formation_row(0, 1))
	_add_formation_row_label("— 後列 —", COLOR_BACK)
	_formation_board.add_child(_make_formation_row(2, 3))

func _add_formation_row_label(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	_formation_board.add_child(label)

func _make_formation_row(slot_a: int, slot_b: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(_make_formation_cell(slot_a))
	row.add_child(_make_formation_cell(slot_b))
	return row

func _make_formation_cell(slot_index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(FORMATION_CELL_PX, FORMATION_CELL_PX)
	panel.add_theme_stylebox_override("panel", _formation_cell_style(false, false))
	panel.gui_input.connect(_on_formation_cell_input.bind(slot_index))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_formation_cells.append(panel)
	return panel

func _formation_cell_style(active: bool, picked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.94)
	if picked:
		style.border_color = COLOR_PICK
		style.set_border_width_all(3)
	elif active:
		style.border_color = COLOR_GOLD
		style.set_border_width_all(2)
	else:
		style.border_color = Color(0.45, 0.40, 0.32)
		style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	return style

func _on_formation_cell_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_formation_cell_pressed(slot_index)

func _on_formation_cell_pressed(slot_index: int) -> void:
	if _formation_pick_slot < 0:
		if _formation_slots[slot_index] == null:
			return
		_formation_pick_slot = slot_index
	else:
		if _formation_pick_slot != slot_index:
			var tmp = _formation_slots[_formation_pick_slot]
			_formation_slots[_formation_pick_slot] = _formation_slots[slot_index]
			_formation_slots[slot_index] = tmp
		_formation_pick_slot = -1
		_apply_formation_rows_from_slots()
	_refresh_formation_grid()

func _refresh_formation_grid() -> void:
	for i in _formation_cells.size():
		var panel: PanelContainer = _formation_cells[i]
		for child in panel.get_children():
			child.queue_free()
		panel.add_theme_stylebox_override(
			"panel", _formation_cell_style(i < 2, _formation_pick_slot == i)
		)
		var member: Resource = _formation_slots[i]
		if member == null:
			var empty := Label.new()
			empty.text = "空き"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.set_anchors_preset(Control.PRESET_FULL_RECT)
			empty.add_theme_color_override("font_color", COLOR_EMPTY)
			panel.add_child(empty)
			continue
		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 3)
		var icon_tex: Texture2D = RosterUiHelper.get_member_portrait_texture(member)
		if icon_tex != null:
			var portrait := TextureRect.new()
			portrait.texture = icon_tex
			portrait.custom_minimum_size = Vector2(64, 64)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vbox.add_child(portrait)
		var name_lbl := Label.new()
		name_lbl.text = RosterUiHelper.short_display_name(str(member.display_name))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(name_lbl)
		panel.add_child(vbox)

func _slot_row_for_index(slot_index: int) -> int:
	return GameState.FORMATION_FRONT if slot_index < 2 else GameState.FORMATION_BACK

func _apply_formation_rows_from_slots() -> void:
	_dedupe_formation_slots_local()
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member == null:
			continue
		GameState.set_member_formation_row(member, _slot_row_for_index(i))
		GameState.set_member_formation_slot(member, i)

func _collect_selected_members_for_formation() -> Array:
	var members: Array = []
	var seen: Dictionary = {}
	for adv in _formation_slots:
		if adv != null and not seen.has(adv):
			members.append(adv)
			seen[adv] = true
	if members.is_empty():
		for adv in _selected:
			if adv != null and not seen.has(adv):
				members.append(adv)
				seen[adv] = true
	return members

func _on_formation_preset_pressed(preset: String) -> void:
	var members: Array = _collect_selected_members_for_formation()
	if members.is_empty():
		_label_status.text = "編成メンバーがいません"
		return
	match preset:
		"front":
			## 前衛寄り: 前から詰める（2人なら前列のみ）
			_place_members_in_slots(members, [0, 1, 2, 3])
		"back":
			## 後衛=後ろ最大2人を後列（P3-D106）。2人なら前列空＋後列2
			_place_members_with_back_count(members, 2)
		_:
			## 均衡=最後尾1人後列（P3-D106）
			_place_members_with_back_count(members, 1)
	_apply_formation_rows_from_slots()
	_formation_pick_slot = -1
	_refresh_formation_grid()
	_rebuild_active_party_row()

func _place_members_with_back_count(members: Array, back_count: int) -> void:
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = null
	if members.is_empty():
		return
	var n: int = members.size()
	var back_n: int = clampi(back_count, 0, mini(2, n))
	var front_n: int = n - back_n
	## 前列は最大2。溢れた分は後列スロットへ（2×2制約）
	if front_n > 2:
		front_n = 2
		back_n = n - front_n
	var idx: int = 0
	for i in front_n:
		_formation_slots[i] = members[idx]
		idx += 1
	for j in back_n:
		_formation_slots[2 + j] = members[idx]
		idx += 1

func _assign_formation_by_role(members: Array, tanks_to_front_slots: bool) -> void:
	var tanks: Array = []
	var others: Array = []
	for m in members:
		if str(m.job_id) in _FRONT_JOB_IDS:
			tanks.append(m)
		else:
			others.append(m)
	var front_slots: Array = [0, 1]
	var back_slots: Array = [2, 3]
	var slots: Array = [null, null, null, null]
	if tanks_to_front_slots:
		_fill_slots_from_lists(slots, tanks, front_slots)
		_fill_slots_from_lists(slots, others, back_slots)
	else:
		_fill_slots_from_lists(slots, others, back_slots)
		_fill_slots_from_lists(slots, tanks, front_slots)
	_fill_slots_from_lists(slots, tanks + others, front_slots + back_slots)
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = slots[i]

func _fill_slots_from_lists(slots: Array, members: Array, open_slots: Array) -> void:
	for m in members:
		if slots.has(m):
			continue
		for slot_idx in open_slots:
			if slots[int(slot_idx)] == null:
				slots[int(slot_idx)] = m
				break

func _place_members_in_slots(members: Array, slot_order: Array) -> void:
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = null
	for i in mini(members.size(), slot_order.size()):
		_formation_slots[int(slot_order[i])] = members[i]

func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)

func _go_home() -> void:
	SceneRouter.change_scene(HOME_SCENE)

func _go_to(path: String) -> void:
	SceneRouter.change_scene(path)
