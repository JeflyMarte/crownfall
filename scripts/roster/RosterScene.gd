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
## NOTIFICATION_RESIZED での再構築を抑止する幅差（px）。微小差での連鎖再生成を防ぐ。
const _RESIZE_REBUILD_EPSILON_PX: float = 2.0

const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
const _FRONT_JOB_IDS: Array[String] = ["swordsman", "vanguard"]
const _RECOMMENDED_JOB_ORDER: Array[String] = [
	"vanguard", "swordsman", "ranger", "alchemist", "beast_tamer",
]
const _ROLE_FILTER_ORDER: Array[String] = ["all", "tank", "dps", "scout", "support"]

var _selected: Array = []
var _formation_slots: Array = [null, null, null, null]
var _formation_pick_slot: int = -1
var _active_pick_slot: int = -1
## 下リスト先行の入れ替え候補（一覧タップ → パーティ枠タップ）。
var _roster_pick_member: Resource = null
var _sort_by_rarity: bool = false
var _role_filter_index: int = 0
## false=冒険者一覧 / true=ペット一覧
var _show_pets: bool = false
var _formation_cells: Array[PanelContainer] = []
## 再構築の再入・RESIZED 連鎖でセルが積み上がり「押すたび拡大」するのを防ぐ。
var _roster_ui_rebuilding: bool = false
var _last_layout_content_w: float = -1.0
## 陣形オーバーレイ開始時のスロット下書き（Dim キャンセル用）。
var _formation_overlay_snapshot: Array = []

## パーティ保存／一覧オーバーレイ（P3-ROSTER-PARTY-PRESET-001）。
var _party_overlay: Control = null
var _party_overlay_title: Label = null
var _party_overlay_list: VBoxContainer = null
var _party_overlay_mode: String = "load"
var _party_overwrite_confirm: ConfirmationDialog = null
var _party_overwrite_slot: int = -1

@onready var _main_vbox: VBoxContainer = $MainScroll/MainVBox
@onready var _main_scroll: ScrollContainer = $MainScroll
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _label_power: Label = $Header/HeaderRow/LabelTitle
@onready var _label_power_legacy: Label = $MainScroll/MainVBox/PowerSection/LabelPower
@onready var _active_party_row: HBoxContainer = $MainScroll/MainVBox/ActivePartyHost/ActivePartyRow
@onready var _roster_grid: GridContainer = $MainScroll/MainVBox/RosterGrid
@onready var _label_status: Label = $MainScroll/MainVBox/LabelStatus
@onready var _formation_overlay: CanvasLayer = $FormationOverlay
@onready var _formation_board: VBoxContainer = $FormationOverlay/FormationPanel/FormationVBox/FormationBoard
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
	$FooterRow/ButtonPartySave.pressed.connect(_on_party_save_pressed)
	$FooterRow/ButtonPartyList.pressed.connect(_on_party_list_pressed)
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
	_SurveySystem.ensure_party_restored_if_awaiting_claim()
	_selected = GameState.party_members.duplicate()
	_strip_dispatched_from_selection()
	_init_formation_slots_from_party()
	_apply_panel_styles()
	_configure_layout()
	_apply_typography()
	_apply_toolbar_buttons()
	_build_formation_grid()
	## パーティ枠だけ先に出し、一覧グリッドは次フレ（ローディング中に埋まる）。
	_refresh_entry_light()
	call_deferred("_deferred_entry_populate")
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
	## コンテンツ幅を VBox の min に書き戻すと Grid と循環し押すたびに拡大する。禁止。
	_main_vbox.custom_minimum_size.x = 0.0
	_roster_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_active_party_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_active_party_row.custom_minimum_size = Vector2(0, _active_card_min_height())
	_last_layout_content_w = _layout_content_width()


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
	HeaderCurrencyHelper.apply_to_row($Header/HeaderRow)
	UiTypography.apply_body(
		$MainScroll/MainVBox/ListHeader/LabelListTitle,
		UiTypography.SIZE_CAPTION
	)
	UiTypography.apply_menu_button($FooterRow/ButtonPartySave, false)
	UiTypography.apply_menu_button($FooterRow/ButtonPartyList, false)
	$FooterRow/ButtonPartySave.custom_minimum_size = Vector2(0, 48)
	$FooterRow/ButtonPartyList.custom_minimum_size = Vector2(0, 48)

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
	if what != NOTIFICATION_RESIZED or not is_node_ready():
		return
	if _roster_ui_rebuilding:
		return
	var content_w: float = _layout_content_width()
	## 幅がほぼ変わっていないのに rebuild すると queue_free 残存と連鎖して拡大する。
	if _last_layout_content_w >= 0.0 and absf(content_w - _last_layout_content_w) < _RESIZE_REBUILD_EPSILON_PX:
		_configure_layout()
		return
	_configure_layout()
	_last_layout_content_w = content_w
	_rebuild_active_party_row()
	_rebuild_roster_grid()


## 子をツリーから即外す（レイアウトに残さない）。破棄は queue_free。
## pressed / gui_input の呼び出し中に free() するとデバッガ Abort でゲーム終了する。
func _clear_children_immediate(parent: Node) -> void:
	if parent == null:
		return
	var children: Array = parent.get_children()
	for child in children:
		parent.remove_child(child)
		child.queue_free()


func _rebuild_active_party_row() -> void:
	if _roster_ui_rebuilding:
		return
	_roster_ui_rebuilding = true
	_clear_children_immediate(_active_party_row)
	for slot_index in FORMATION_SLOT_COUNT:
		_active_party_row.add_child(_make_active_party_card(slot_index))
	_roster_ui_rebuilding = false
	_reapply_scroll_touch()


func _reapply_scroll_touch() -> void:
	## BottomNav の初回 enable 後にカードが再生成されるため、rebuild のたびに再 PASS 化。
	## 内側に別 Scroll を置かない（ActivePartyHost は非 Scroll）。nest は false で固定。
	if _main_scroll != null:
		ScrollTouchHelper.enable(_main_scroll, false)


func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()


func _refresh_power_label() -> void:
	var members: Array = _active_members_in_slot_order()
	_label_power.text = UiTypography.decorate_title_text(
		"総合戦力 %s" % RosterUiHelper.format_combat_power(
			RosterUiHelper.compute_combat_power(members)
		)
	)

func _format_number(value: int) -> String:
	return RosterUiHelper.format_combat_power(value)

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

func _active_members_in_slot_order() -> Array:
	var members: Array = []
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member != null and _selected.has(member):
			members.append(member)
	return members

func _party_index_for_member(member: Resource) -> int:
	if member == null:
		return -1
	return GameState.party_members.find(member)

func _refresh_entry_light() -> void:
	_update_currency()
	_refresh_power_label()
	if _roster_ui_rebuilding:
		return
	_roster_ui_rebuilding = true
	_clear_children_immediate(_active_party_row)
	for slot_index in FORMATION_SLOT_COUNT:
		_active_party_row.add_child(_make_active_party_card(slot_index))
	_roster_ui_rebuilding = false
	_refresh_formation_grid()
	_reapply_scroll_touch()


func _deferred_entry_populate() -> void:
	if not is_inside_tree() or _roster_ui_rebuilding:
		return
	_roster_ui_rebuilding = true
	_clear_children_immediate(_roster_grid)
	_populate_roster_grid()
	_roster_ui_rebuilding = false
	_reapply_scroll_touch()


func _refresh_all() -> void:
	_update_currency()
	_refresh_power_label()
	if _roster_ui_rebuilding:
		return
	_roster_ui_rebuilding = true
	_clear_children_immediate(_active_party_row)
	for slot_index in FORMATION_SLOT_COUNT:
		_active_party_row.add_child(_make_active_party_card(slot_index))
	_clear_children_immediate(_roster_grid)
	_populate_roster_grid()
	_roster_ui_rebuilding = false
	_refresh_formation_grid()
	_commit_active_party()
	_reapply_scroll_touch()

func _make_active_party_card(slot_index: int) -> Control:
	var member: Resource = _formation_slots[slot_index]
	var card_w: int = _slot_card_width()
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	## STOP のままだと縦ドラッグを奪う。ScrollTouch が PASS 化し、タップは gui_input で受ける。
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.clip_contents = true
	panel.add_theme_stylebox_override(
		"panel",
		RosterUiHelper.card_panel_style(member != null, slot_index == 0)
	)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)
	if member == null:
		var empty := Label.new()
		empty.text = "空き"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.custom_minimum_size = Vector2(0, _active_card_min_height() - 8)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLOR_EMPTY)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_body(empty, UiTypography.SIZE_CAPTION, COLOR_EMPTY)
		vbox.add_child(empty)
		panel.gui_input.connect(_on_active_card_input.bind(slot_index))
		if _roster_pick_member != null:
			panel.add_theme_stylebox_override("panel", RosterUiHelper.pick_panel_style())
		return panel
	var portrait_tex: Texture2D = RosterUiHelper.get_member_portrait_texture(member)
	## 枠幅は据え置き。肖像だけ枠内いっぱい（余白は content_margin 分のみ）。
	var portrait_px: int = maxi(card_w - 12, 72)
	if portrait_tex != null:
		vbox.add_child(RosterUiHelper.make_clamped_portrait(portrait_tex, portrait_px, true))
	var name_lbl := Label.new()
	name_lbl.text = RosterUiHelper.member_name_with_limit_break(member)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_CAPTION, UiTypography.COLOR_BODY)
	vbox.add_child(name_lbl)
	var stars := Label.new()
	stars.text = "%s  Lv%d" % [RosterUiHelper.stars_text(int(member.rarity)), int(member.level)]
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(stars, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	vbox.add_child(stars)
	var job_lbl := Label.new()
	job_lbl.text = RosterUiHelper.job_display_name(member)
	job_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	job_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(job_lbl, UiTypography.SIZE_CAPTION)
	vbox.add_child(job_lbl)
	var stats: Dictionary = RosterUiHelper.compute_member_stats(member, _party_index_for_member(member))
	vbox.add_child(_make_card_stat_row("hp", "HP", int(stats.get("hp", 0))))
	vbox.add_child(_make_card_stat_row("attack", "攻撃力", int(stats.get("attack", 0))))
	vbox.add_child(_make_card_stat_row("defense", "防御力", int(stats.get("defense", 0))))
	var row_lbl := Label.new()
	## 表示はスロット位置基準（前列／後列の見た目）。
	var is_back: bool = _slot_row_for_index(slot_index) == GameState.FORMATION_BACK
	row_lbl.text = "後列" if is_back else "前列"
	row_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(row_lbl, COLOR_BACK if is_back else COLOR_FRONT)
	vbox.add_child(row_lbl)
	var detail := Button.new()
	detail.text = "詳細"
	UiTypography.apply_menu_button(detail, false)
	detail.add_theme_font_size_override("font_size", UiTypography.SIZE_CAPTION)
	## ScrollTouch の PASS 化を避け、pressed でキャラ画面へ遷移できるようにする。
	detail.set_meta(&"_cf_keep_mouse_stop", true)
	detail.mouse_filter = Control.MOUSE_FILTER_STOP
	detail.focus_mode = Control.FOCUS_NONE
	detail.pressed.connect(_on_detail_pressed.bind(member))
	vbox.add_child(detail)
	panel.gui_input.connect(_on_active_card_input.bind(slot_index))
	if _active_pick_slot == slot_index or _roster_pick_member != null:
		panel.add_theme_stylebox_override("panel", RosterUiHelper.pick_panel_style())
	return panel


func _make_card_stat_row(stat_key: String, label_text: String, value: int) -> Control:
	const CARD_STAT_ICON_PX: int = 16
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_CAPTION, COLOR_SUB)
	row.add_child(name_lbl)
	var val_lbl := Label.new()
	val_lbl.text = str(value)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(val_lbl, UiTypography.SIZE_CAPTION, UiTypography.COLOR_BODY)
	row.add_child(val_lbl)
	return row

func _pick_style() -> StyleBoxFlat:
	## 互換ラッパ。選択でセル最小サイズが変わらないよう Helper 側で margin 固定。
	return RosterUiHelper.pick_panel_style()

func _on_active_card_input(event: InputEvent, slot_index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	## gui_input 中に当該カードを破棄しないよう deferred。
	_on_active_card_pressed.call_deferred(slot_index)


func _on_active_card_pressed(slot_index: int) -> void:
	if not is_instance_valid(self):
		return
	## 一覧先行: 下で選んだメンバーをこの枠へ入れる／入れ替える。
	if _roster_pick_member != null:
		_apply_roster_pick_to_slot(slot_index)
		return
	if _formation_slots[slot_index] == null:
		return
	if _active_pick_slot < 0:
		_active_pick_slot = slot_index
		_roster_pick_member = null
		_label_status.text = "入れ替え先を下のリストから選んでください"
	else:
		if _active_pick_slot != slot_index:
			var tmp = _formation_slots[_active_pick_slot]
			_formation_slots[_active_pick_slot] = _formation_slots[slot_index]
			_formation_slots[slot_index] = tmp
			_label_status.text = "パーティ内の並びを入れ替えました"
		else:
			_label_status.text = ""
		_active_pick_slot = -1
	_rebuild_active_party_row()
	_rebuild_roster_grid()
	_commit_active_party()

func _on_detail_pressed(member: Resource) -> void:
	## 詳細は閲覧遷移のみ（編成確定は入れ替え操作時に済んでいる）。
	if member == null:
		return
	## 入れ替え選択中でも詳細は優先（カード入れ替えに食わせない）。
	_active_pick_slot = -1
	_roster_pick_member = null
	## Equipment はレベル順ビューなので index ではなく id で渡す（取り違え防止）。
	GameState.equipment_focus_member_id = str(member.id)
	GameState.equipment_focus_member_index = -1
	AudioManager.play_sfx("ui_confirm")
	SceneRouter.change_scene(EQUIPMENT_SCENE)

func _rebuild_roster_grid() -> void:
	if _roster_ui_rebuilding:
		return
	_roster_ui_rebuilding = true
	_clear_children_immediate(_roster_grid)
	_populate_roster_grid()
	_roster_ui_rebuilding = false
	_reapply_scroll_touch()


func _populate_roster_grid() -> void:
	if _show_pets:
		PetSystem.ensure_starter_pet()
		PetSystem.sync_unlocks_from_stage_progress(false)
		var owned: Array[String] = PetSystem.owned_pet_ids_ordered()
		if owned.is_empty():
			var empty_pet := Label.new()
			empty_pet.text = "ペットがいません"
			empty_pet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_pet.add_theme_color_override("font_color", COLOR_SUB)
			_roster_grid.add_child(empty_pet)
			return
		var active_id: String = str(GameState.active_pet.id) if GameState.active_pet != null else ""
		var shared_lv: int = int(GameState.active_pet.level) if GameState.active_pet != null else 1
		var shared_exp: int = int(GameState.active_pet.exp) if GameState.active_pet != null else 0
		for pid in owned:
			var pet: Resource
			if pid == active_id and GameState.active_pet != null:
				pet = GameState.active_pet
			else:
				pet = PetSystem.create_pet_adventurer(pid)
				pet.level = shared_lv
				pet.exp = shared_exp
			_roster_grid.add_child(_make_roster_grid_card(pet))
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
	_roster_pick_member = null
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
	var is_active_pet: bool = (
		is_pet
		and GameState.active_pet != null
		and str(GameState.active_pet.id) == str(adv.id)
	)
	var dispatched: bool = (not is_pet) and _is_survey_dispatched(adv)
	var in_party: bool = (not is_pet) and _selected.has(adv)
	var picking: bool = (not is_pet) and (_active_pick_slot >= 0 or _roster_pick_member != null)
	var list_picked: bool = (not is_pet) and _roster_pick_member == adv
	var cell_h: int = _grid_cell_height()
	var cell_w: int = _grid_cell_width()
	## 枠高さのみ固定。幅は Grid 列に EXPAND（cell_w を min に書くと列合計が循環拡大する）。
	## 下段（Lv／星）を先に確保し、肖像は残り高さに収める（大きくしすぎると下段が clip で消える）。
	const BOTTOM_BAR_H: int = 28
	var icon_px: int = clampi(
		mini(cell_w - 4, cell_h - BOTTOM_BAR_H - 6),
		64,
		RosterUiHelper.portrait_hard_max_px()
	)
	var wrapper := PanelContainer.new()
	wrapper.custom_minimum_size = Vector2(0, cell_h)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	wrapper.clip_contents = true
	if is_pet:
		wrapper.add_theme_stylebox_override("panel", RosterUiHelper.card_panel_style(is_active_pet, false))
	elif list_picked or (picking and _active_pick_slot >= 0 and not in_party and not dispatched):
		wrapper.add_theme_stylebox_override("panel", RosterUiHelper.pick_panel_style())
	else:
		wrapper.add_theme_stylebox_override("panel", RosterUiHelper.card_panel_style(in_party, false))
	# 入れ替え選択中はリストを暗くせず選べることを示す。通常時のみ編成中を暗くする。
	if dispatched:
		wrapper.modulate = Color(0.55, 0.52, 0.48, 1.0)
	elif in_party and not picking:
		wrapper.modulate = Color(0.42, 0.42, 0.42, 1.0)
	elif is_pet and not is_active_pet:
		wrapper.modulate = Color(0.72, 0.72, 0.72, 1.0)
	## 肖像は Button の子にしない（押下スタイル／min size 伝播で原寸逃げする）。
	## PanelContainer は1子のみ。中身＋透明タップは stack に載せる。
	var stack := Control.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.clip_contents = true
	wrapper.add_child(stack)
	var body := VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_theme_constant_override("separation", 0)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(body)
	var tex: Texture2D = RosterUiHelper.get_member_portrait_texture(adv)
	var icon_area := CenterContainer.new()
	icon_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_area.clip_contents = true
	body.add_child(icon_area)
	if tex != null:
		icon_area.add_child(RosterUiHelper.make_clamped_portrait(tex, icon_px, true))
	var bottom_bar := PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, BOTTOM_BAR_H)
	bottom_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_bar.add_theme_stylebox_override("panel", RosterUiHelper.roster_bottom_bar_style())
	body.add_child(bottom_bar)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 4)
	info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_bar.add_child(info_row)
	var lv_lbl := Label.new()
	if dispatched:
		lv_lbl.text = "調査中"
	else:
		lv_lbl.text = "Lv.%d" % int(adv.level)
		if is_pet and is_active_pet:
			lv_lbl.text = "出撃 Lv.%d" % int(adv.level)
	lv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_caption(lv_lbl, COLOR_GOLD if dispatched else UiTypography.COLOR_BODY)
	lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_child(lv_lbl)
	var star_lbl := Label.new()
	star_lbl.text = RosterUiHelper.stars_text(int(adv.rarity))
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_caption(star_lbl, UiTypography.COLOR_GOLD)
	star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_child(star_lbl)
	## 透明タップ面（子なし）— 肖像の min size に影響させない。
	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_toggle_selection.bind(adv))
	stack.add_child(btn)
	return wrapper


func _is_survey_dispatched(adv: Resource) -> bool:
	return adv != null and _SurveySystem.is_member_dispatched(str(adv.id))


func _strip_dispatched_from_selection() -> void:
	var kept: Array = []
	for adv in _selected:
		if adv != null and not _is_survey_dispatched(adv):
			kept.append(adv)
	_selected = kept


func _toggle_selection(adv: Resource) -> void:
	## Button.pressed 内でカードを破棄すると落ちるため、入れ替え処理は次フレームへ。
	_toggle_selection_deferred.call_deferred(adv)


func _toggle_selection_deferred(adv: Resource) -> void:
	if not is_instance_valid(self):
		return
	if PetSystem.is_pet_member(adv):
		var name_short: String = RosterUiHelper.short_display_name(str(adv.display_name))
		if GameState.active_pet != null and str(GameState.active_pet.id) == str(adv.id):
			_label_status.text = "%sは出撃中のペットです（4人編成には入りません）" % name_short
			return
		if PetSystem.set_active_pet_id(str(adv.id)):
			_label_status.text = "%sに切り替えました" % name_short
			_rebuild_roster_grid()
		else:
			_label_status.text = "ペットの切り替えに失敗しました"
		return
	if _active_pick_slot >= 0:
		_roster_pick_member = null
		_apply_active_pick_with_roster(adv)
		return
	## 一覧先行の入れ替え: 同じメンバー再タップで解除。
	if _roster_pick_member == adv:
		_roster_pick_member = null
		_label_status.text = ""
		_rebuild_active_party_row()
		_rebuild_roster_grid()
		return
	if _selected.has(adv):
		if _selected.size() > 1:
			_selected.erase(adv)
			_roster_pick_member = null
			_sync_formation_slots_from_selection()
			_active_pick_slot = -1
			_refresh_all()
		else:
			_label_status.text = "パーティには最低1人必要です"
		return
	if _is_survey_dispatched(adv):
		_label_status.text = "%sは調査中のため編成できません" % RosterUiHelper.short_display_name(
			str(adv.display_name)
		)
		return
	## 空きがあれば追加。満員なら一覧→パーティ入れ替えモードへ。
	if _selected.size() < GameState.ACTIVE_PARTY_SIZE:
		_selected.append(adv)
		_roster_pick_member = null
		_sync_formation_slots_from_selection()
		_active_pick_slot = -1
		_refresh_all()
		return
	_active_pick_slot = -1
	_roster_pick_member = adv
	_label_status.text = "入れ替えたいパーティの枠を選んでください"
	_rebuild_active_party_row()
	_rebuild_roster_grid()


## 上段パーティ枠を選んだあとに下リストを押すと、その枠のメンバーを入れ替える。
func _apply_active_pick_with_roster(adv: Resource) -> void:
	var slot: int = _active_pick_slot
	_active_pick_slot = -1
	_roster_pick_member = null
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
		_label_status.text = "パーティ内の並びを入れ替えました"
	else:
		if _is_survey_dispatched(adv):
			_label_status.text = "%sは調査中のため編成できません" % RosterUiHelper.short_display_name(
				str(adv.display_name)
			)
			_rebuild_active_party_row()
			_rebuild_roster_grid()
			return
		if current != null:
			_selected.erase(current)
		if not _selected.has(adv):
			_selected.append(adv)
		_formation_slots[slot] = adv
		_label_status.text = "メンバーを入れ替えました"
	_refresh_all()


## 下リスト先行: 選んだメンバーを指定パーティ枠へ入れる／入れ替える。
func _apply_roster_pick_to_slot(slot_index: int) -> void:
	var adv: Resource = _roster_pick_member
	_roster_pick_member = null
	_active_pick_slot = -1
	if adv == null or slot_index < 0 or slot_index >= FORMATION_SLOT_COUNT:
		_rebuild_active_party_row()
		_rebuild_roster_grid()
		return
	if _is_survey_dispatched(adv):
		_label_status.text = "%sは調査中のため編成できません" % RosterUiHelper.short_display_name(
			str(adv.display_name)
		)
		_rebuild_active_party_row()
		_rebuild_roster_grid()
		return
	var current: Resource = _formation_slots[slot_index]
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
			_formation_slots[slot_index] = adv
			_formation_slots[other_slot] = current
		_label_status.text = "パーティ内の並びを入れ替えました"
	else:
		if current != null:
			_selected.erase(current)
		if not _selected.has(adv):
			_selected.append(adv)
		_formation_slots[slot_index] = adv
		_label_status.text = "メンバーを入れ替えました"
	_refresh_all()

func _on_recommend_pressed() -> void:
	var roster: Array = _eligible_roster_for_party()
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
	_roster_pick_member = null
	_formation_pick_slot = -1
	if _selected.is_empty():
		_label_status.text = "編成可能なメンバーがいません（調査中を除く）"
	else:
		_label_status.text = "おすすめ編成を適用しました"
	_refresh_all()

## ---- パーティ保存／一覧（P3-ROSTER-PARTY-PRESET-001） ----

const _PARTY_OVERLAY_ICON_PX: int = 48

func _on_party_save_pressed() -> void:
	_open_party_overlay("save")

func _on_party_list_pressed() -> void:
	_open_party_overlay("load")

func _ensure_party_overlay() -> void:
	if _party_overlay != null:
		return
	_party_overlay = Control.new()
	_party_overlay.name = "PartyPresetOverlay"
	_party_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_party_overlay.visible = false
	_party_overlay.z_index = 80
	_party_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_party_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_party_overlay_dim_input)
	_party_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 640)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", RosterUiHelper.card_panel_style(false, false))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(outer)
	_party_overlay_title = Label.new()
	_party_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(_party_overlay_title, UiTypography.SIZE_BODY, COLOR_GOLD)
	outer.add_child(_party_overlay_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_party_overlay_list = VBoxContainer.new()
	_party_overlay_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_party_overlay_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_party_overlay_list)
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.custom_minimum_size = Vector2(200, 48)
	UiTypography.apply_menu_button(close_btn)
	close_btn.pressed.connect(_close_party_overlay)
	outer.add_child(close_btn)
	_party_overwrite_confirm = ConfirmationDialog.new()
	_party_overwrite_confirm.title = "パーティ保存"
	_party_overwrite_confirm.ok_button_text = "上書きする"
	_party_overwrite_confirm.cancel_button_text = "やめる"
	_party_overwrite_confirm.confirmed.connect(_on_party_overwrite_confirmed)
	add_child(_party_overwrite_confirm)


func _on_party_overlay_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_party_overlay()


func _close_party_overlay() -> void:
	if _party_overlay != null:
		_party_overlay.visible = false
	AudioManager.play_sfx("ui_cancel")


func _open_party_overlay(mode: String) -> void:
	_ensure_party_overlay()
	_party_overlay_mode = mode
	_party_overlay_title.text = "パーティ保存（保存先を選択）" if mode == "save" else "パーティ一覧"
	_rebuild_party_overlay_rows()
	_party_overlay.visible = true


func _rebuild_party_overlay_rows() -> void:
	for child in _party_overlay_list.get_children():
		child.queue_free()
	for slot in GameState.SAVED_PARTY_SLOTS:
		_party_overlay_list.add_child(_make_party_overlay_row(slot))


func _make_party_overlay_row(slot: int) -> Control:
	var occupied: bool = GameState.has_saved_party(slot)
	var members: Array = GameState.saved_party_members(slot) if occupied else []
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 84)
	btn.add_theme_stylebox_override(
		"normal", RosterUiHelper.card_panel_style(occupied, false)
	)
	btn.add_theme_stylebox_override(
		"hover", RosterUiHelper.card_panel_style(occupied, true)
	)
	btn.add_theme_stylebox_override(
		"pressed", RosterUiHelper.card_panel_style(occupied, true)
	)
	## load モードは空きスロットを押せなくする（保存先が無いため）。
	btn.disabled = (_party_overlay_mode == "load" and not occupied)
	btn.pressed.connect(_on_party_slot_pressed.bind(slot))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	btn.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = GameState.get_saved_party_name(slot) if occupied else "%s（空き）" % GameState.default_saved_party_name(slot)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD if occupied else COLOR_SUB)
	vbox.add_child(name_lbl)
	var icon_row := HBoxContainer.new()
	icon_row.add_theme_constant_override("separation", 6)
	icon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_row)
	if members.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "（空き）" if not occupied else "（保存済メンバーが見つかりません）"
		empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_body(empty_lbl, UiTypography.SIZE_CAPTION, COLOR_SUB)
		icon_row.add_child(empty_lbl)
	else:
		for member in members:
			var tex: Texture2D = RosterUiHelper.get_member_portrait_texture(member)
			if tex != null:
				icon_row.add_child(RosterUiHelper.make_clamped_portrait(tex, _PARTY_OVERLAY_ICON_PX, true))
	return btn


func _on_party_slot_pressed(slot: int) -> void:
	if _party_overlay_mode == "save":
		if GameState.has_saved_party(slot):
			_party_overwrite_slot = slot
			_party_overwrite_confirm.dialog_text = (
				"%s に現在の編成を上書き保存しますか？" % GameState.get_saved_party_name(slot)
			)
			_party_overwrite_confirm.popup_centered()
			return
		_save_party_to_slot(slot)
		return
	## load モード
	var reason: String = GameState.apply_saved_party(slot)
	if not reason.is_empty():
		_label_status.text = reason
		return
	_selected = GameState.party_members.duplicate()
	_init_formation_slots_from_party()
	_active_pick_slot = -1
	_roster_pick_member = null
	_formation_pick_slot = -1
	SaveManager.save_game()
	_label_status.text = "%s を編成にセットしました" % GameState.get_saved_party_name(slot)
	_close_party_overlay()
	_refresh_all()


func _on_party_overwrite_confirmed() -> void:
	if _party_overwrite_slot < 0:
		return
	_save_party_to_slot(_party_overwrite_slot)
	_party_overwrite_slot = -1


func _save_party_to_slot(slot: int) -> void:
	## 保存対象は画面に表示中の編成（アクティブ編成も同時に確定する）。
	_sync_formation_slots_from_selection()
	if not _commit_active_party():
		return
	var party: Array = _ordered_party_from_formation()
	if party.is_empty():
		_label_status.text = "編成が空のため保存できません"
		return
	GameState.save_party_preset(slot, party)
	SaveManager.save_game()
	_label_status.text = "%s に保存しました" % GameState.get_saved_party_name(slot)
	_rebuild_party_overlay_rows()

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

## 編成変更をアクティブパーティへ即確定しセーブする（フッター「保存」は廃止）。
func _commit_active_party() -> bool:
	_sync_formation_slots_from_selection()
	var party: Array = _ordered_party_from_formation()
	var reject: String = GameState.active_party_reject_reason(party)
	if not reject.is_empty():
		_label_status.text = reject
		return false
	if not GameState.set_active_party(party):
		_label_status.text = "編成の変更に失敗しました（1〜%d名・重複不可）" % GameState.ACTIVE_PARTY_SIZE
		return false
	_apply_formation_rows_from_slots()
	SaveManager.save_game()
	return true

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

func _eligible_roster_for_party() -> Array:
	var out: Array = []
	for adv in GameState.get_roster():
		if adv == null or PetSystem.is_pet_member(adv):
			continue
		if _is_survey_dispatched(adv):
			continue
		out.append(adv)
	return out

func _snapshot_formation_slots() -> Array:
	return _formation_slots.duplicate()

func _restore_formation_slots(snapshot: Array) -> void:
	_formation_slots = [null, null, null, null]
	for i in mini(FORMATION_SLOT_COUNT, snapshot.size()):
		_formation_slots[i] = snapshot[i]
	_dedupe_formation_slots_local()

func _open_formation_overlay() -> void:
	_sync_formation_slots_from_selection()
	_formation_overlay_snapshot = _snapshot_formation_slots()
	_formation_pick_slot = -1
	_refresh_formation_grid()
	var close_btn: Button = $FormationOverlay/FormationPanel/FormationVBox/ButtonFormationClose
	if close_btn != null:
		close_btn.text = "確定"
	var hint: Label = $FormationOverlay/FormationPanel/FormationVBox/LabelFormationHint
	if hint != null:
		hint.text = "マスをタップして入れ替え。確定で反映／外側タップでキャンセル。"
	_formation_overlay.visible = true

func _close_formation_overlay() -> void:
	## 閉じるボタン＝確定（アクティブ編成へ即反映）。
	_formation_overlay.visible = false
	_formation_pick_slot = -1
	_formation_overlay_snapshot.clear()
	_refresh_formation_grid()
	_rebuild_active_party_row()
	_refresh_power_label()
	if _commit_active_party():
		_label_status.text = "陣形を反映しました"

func _cancel_formation_overlay() -> void:
	## Dim タップ＝キャンセル（オープン時スナップショットへ戻す）。
	if not _formation_overlay_snapshot.is_empty():
		_restore_formation_slots(_formation_overlay_snapshot)
	_formation_overlay.visible = false
	_formation_pick_slot = -1
	_formation_overlay_snapshot.clear()
	_refresh_formation_grid()
	_rebuild_active_party_row()
	_refresh_power_label()
	_label_status.text = "陣形の変更をキャンセルしました"

func _on_formation_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cancel_formation_overlay()

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
			vbox.add_child(RosterUiHelper.make_clamped_portrait(icon_tex, 96, true))
		var name_lbl := Label.new()
		name_lbl.text = RosterUiHelper.member_name_with_limit_break(member)
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
	## 画面上の編成を確定してから戻る（陣形オーバーレイ中は確定扱い）。
	if _formation_overlay.visible:
		_close_formation_overlay()
	else:
		_commit_active_party()
	SceneRouter.change_scene(HOME_SCENE)

func _go_home() -> void:
	SceneRouter.change_scene(HOME_SCENE)

func _go_to(path: String) -> void:
	SceneRouter.change_scene(path)
