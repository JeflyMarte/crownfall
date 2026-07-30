extends Control

## 展示室 — 中央 Idle／左装備／右ステ。背景モック座標に合わせて配置。

const ShowcaseCatalogScript = preload("res://scripts/showcase/ShowcaseCatalog.gd")
const ShowcaseUiTokensScript = preload("res://scripts/showcase/ShowcaseUiTokens.gd")
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"

const COLOR_GOLD: Color = UiTypography.COLOR_GOLD
const COLOR_SUB: Color = UiTypography.COLOR_SUB
const COLOR_BODY: Color = UiTypography.COLOR_BODY

enum Mode { OWN, STAFF }

var _mode: Mode = Mode.OWN
var _staff_preset_id: String = ""
var _display_member: Resource = null
var _credit_text: String = ""

@onready var _bg_texture: TextureRect = $BgTexture
@onready var _btn_back: Button = $ButtonBack
@onready var _label_title: Label = $Header/LabelTitle
@onready var _btn_own: Button = $ModeRow/BtnOwn
@onready var _btn_staff: Button = $ModeRow/BtnStaff
@onready var _equip_panel: PanelContainer = $EquipPanel
@onready var _stats_panel: PanelContainer = $StatsPanel
@onready var _equip_col: Control = $EquipPanel/EquipCol
@onready var _idle_host: CenterContainer = $IdleHost
@onready var _stats_col: Control = $StatsPanel/StatsCol
@onready var _footer: PanelContainer = $Footer
@onready var _footer_name: Label = $Footer/FooterVBox/NameLabel
@onready var _footer_meta: Label = $Footer/FooterVBox/MetaLabel
@onready var _footer_credit: Label = $Footer/FooterVBox/CreditLabel
@onready var _empty_panel: PanelContainer = $EmptyPanel
@onready var _empty_label: Label = $EmptyPanel/EmptyVBox/EmptyLabel
@onready var _empty_actions: VBoxContainer = $EmptyPanel/EmptyVBox/EmptyActions
@onready var _staff_scroll: ScrollContainer = $StaffStrip
@onready var _mode_row: Control = $ModeRow
@onready var _bottom_nav: PanelContainer = $BottomNav

var _detail_overlay: Control = null
var _detail_host: VBoxContainer = null
var _detail_title: Label = null
var _staff_player_name: String = ""
var _btn_change_member: Button = null
var _btn_staff_list: Button = null
var _power_panel: Control = null
var _power_frame: TextureRect = null
var _power_caption: Label = null
var _power_value: Label = null
var _name_frame_top_rule: Control = null
var _pick_overlay: Control = null
var _pick_list: VBoxContainer = null
var _pick_title: Label = null
## "member" | "staff"
var _pick_mode: String = "member"


func _ready() -> void:
	_label_title.text = "展示室"
	UiTypography.apply_screen_title(_label_title)
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.SHOWCASE)
	_btn_back.pressed.connect(_on_back_pressed)
	var mode_group := ButtonGroup.new()
	_btn_own.button_group = mode_group
	_btn_staff.button_group = mode_group
	_btn_own.pressed.connect(func(): _set_mode(Mode.OWN))
	_btn_staff.pressed.connect(func(): _set_mode(Mode.STAFF))
	_setup_chrome()
	_ensure_power_panel()
	_ensure_name_frame_top_rule()
	_ensure_change_member_button()
	_ensure_staff_list_button()
	_apply_layout_rects()
	if ShowcaseCatalogScript.STAFF_PRESETS.size() > 0:
		_staff_preset_id = str(ShowcaseCatalogScript.STAFF_PRESETS[0].get("id", ""))
	_set_mode(Mode.OWN)


func _setup_chrome() -> void:
	var bg_tex: Texture2D = ShowcaseUiTokensScript.load_tex(ShowcaseUiTokensScript.BG)
	if bg_tex != null:
		_bg_texture.texture = bg_tex
	_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	var empty_sb: StyleBox = ShowcaseUiTokensScript.transparent_button_style()
	_btn_back.flat = true
	_btn_back.focus_mode = Control.FOCUS_NONE
	_btn_back.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_back.z_index = 30
	## Header 配下だと他UIと被る／相対座標が分かりにくいのでルート直下へ。
	if _btn_back.get_parent() != self:
		_btn_back.reparent(self)
	_btn_back.add_theme_stylebox_override("normal", empty_sb)
	_btn_back.add_theme_stylebox_override("hover", empty_sb)
	_btn_back.add_theme_stylebox_override("pressed", empty_sb)
	_btn_back.add_theme_stylebox_override("focus", empty_sb)
	_btn_back.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	_btn_back.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	_btn_back.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	_btn_back.tooltip_text = "メニューに戻る"
	_btn_back.text = ""

	_equip_panel.add_theme_stylebox_override("panel", ShowcaseUiTokensScript.content_panel_style())
	_stats_panel.add_theme_stylebox_override("panel", ShowcaseUiTokensScript.content_panel_style())
	_equip_panel.clip_contents = false
	_stats_panel.clip_contents = false
	_equip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footer.add_theme_stylebox_override("panel", ShowcaseUiTokensScript.name_card_style())
	_footer.z_index = 5
	_footer.modulate = Color(1, 1, 1, 1)
	_empty_panel.add_theme_stylebox_override("panel", ShowcaseUiTokensScript.empty_panel_style())
	_bottom_nav.add_theme_stylebox_override("panel", _bottom_nav_style())

	_apply_layout_rects()
	_empty_panel.visible = false
	## 横並びスタッフ名は廃止。一覧ボタンへ。
	_staff_scroll.visible = false
	_refresh_mode_tab_styles()


func _bottom_nav_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.08, 0.96)
	sb.border_width_top = 1
	sb.border_color = Color(0.70, 0.58, 0.28, 0.75)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 6.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 6.0
	return sb


func _apply_layout_rects() -> void:
	var back: Rect2 = ShowcaseUiTokensScript.BACK_RECT
	_btn_back.position = back.position
	_btn_back.size = back.size
	_btn_back.custom_minimum_size = back.size

	var mode: Rect2 = ShowcaseUiTokensScript.MODE_ROW
	_mode_row.position = mode.position
	_mode_row.size = mode.size
	var own_r: Rect2 = ShowcaseUiTokensScript.MODE_TAB_OWN
	_btn_own.position = own_r.position - mode.position
	_btn_own.size = own_r.size
	var staff_r: Rect2 = ShowcaseUiTokensScript.MODE_TAB_STAFF
	_btn_staff.position = staff_r.position - mode.position
	_btn_staff.size = staff_r.size

	## 旧 StaffStrip は非表示のまま（一覧ボタンに置換）。
	_staff_scroll.visible = false

	if _btn_staff_list != null:
		var staff_list_r: Rect2 = ShowcaseUiTokensScript.STAFF_LIST_RECT
		_btn_staff_list.position = staff_list_r.position
		_btn_staff_list.size = staff_list_r.size
		_btn_staff_list.custom_minimum_size = staff_list_r.size

	var equip: Rect2 = ShowcaseUiTokensScript.EQUIP_RECT
	_equip_panel.position = equip.position
	_equip_panel.size = equip.size

	var stats: Rect2 = ShowcaseUiTokensScript.STATS_RECT
	_stats_panel.position = stats.position
	_stats_panel.size = stats.size

	var idle_size: Vector2 = ShowcaseUiTokensScript.IDLE_HOST_SIZE
	var idle_center: Vector2 = ShowcaseUiTokensScript.IDLE_CENTER
	_idle_host.position = idle_center - idle_size * 0.5
	_idle_host.size = idle_size

	var footer: Rect2 = ShowcaseUiTokensScript.FOOTER_RECT
	_footer.position = footer.position
	_footer.size = footer.size

	if _power_panel != null:
		var power_r: Rect2 = ShowcaseUiTokensScript.POWER_RECT
		_power_panel.position = power_r.position
		_power_panel.size = power_r.size
		_power_panel.custom_minimum_size = power_r.size
		if _power_frame != null:
			_power_frame.position = Vector2.ZERO
			_power_frame.size = power_r.size

	if _name_frame_top_rule != null:
		var rule_r: Rect2 = ShowcaseUiTokensScript.NAME_FRAME_TOP_RULE
		_name_frame_top_rule.position = rule_r.position
		_name_frame_top_rule.size = rule_r.size
		_name_frame_top_rule.queue_redraw()

	if _btn_change_member != null:
		var change_r: Rect2 = ShowcaseUiTokensScript.CHANGE_MEMBER_RECT
		_btn_change_member.position = change_r.position
		_btn_change_member.size = change_r.size
		_btn_change_member.custom_minimum_size = change_r.size

	var empty: Rect2 = ShowcaseUiTokensScript.EMPTY_RECT
	_empty_panel.position = empty.position
	_empty_panel.size = empty.size


func _refresh_mode_tab_styles() -> void:
	_apply_mode_tab_style(_btn_own, _mode == Mode.OWN)
	_apply_mode_tab_style(_btn_staff, _mode == Mode.STAFF)


func _apply_mode_tab_style(btn: Button, active: bool) -> void:
	var style: StyleBox = ShowcaseUiTokensScript.mode_tab_style(active)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_stylebox_override("disabled", style)
	var col: Color = (
		ShowcaseUiTokensScript.COLOR_TAB_ACTIVE_FONT
		if active
		else ShowcaseUiTokensScript.COLOR_TAB_INACTIVE_FONT
	)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", col)
	btn.add_theme_color_override("font_pressed_color", col)
	btn.add_theme_color_override("font_disabled_color", col)
	btn.add_theme_color_override("font_focus_color", col)
	UiTypography.apply_menu_button(btn, false)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", col)
	btn.add_theme_color_override("font_pressed_color", col)


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_btn_own.button_pressed = mode == Mode.OWN
	_btn_staff.button_pressed = mode == Mode.STAFF
	_staff_scroll.visible = false
	_refresh_mode_tab_styles()
	_refresh_display()
	_update_change_member_button()
	_update_staff_list_button()


func _ensure_name_frame_top_rule() -> void:
	## 背景焼込の名札枠は上辺横線が欠けているため、金線＋中央菱で補完する。
	if _name_frame_top_rule != null:
		return
	_name_frame_top_rule = Control.new()
	_name_frame_top_rule.name = "NameFrameTopRule"
	_name_frame_top_rule.z_index = 4
	_name_frame_top_rule.visible = false
	_name_frame_top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_frame_top_rule.draw.connect(_on_name_frame_top_rule_draw)
	add_child(_name_frame_top_rule)


func _on_name_frame_top_rule_draw() -> void:
	if _name_frame_top_rule == null:
		return
	var sz: Vector2 = _name_frame_top_rule.size
	if sz.x < 8.0 or sz.y < 1.0:
		return
	var y_mid: float = sz.y * 0.5
	var gold := Color(0.90, 0.74, 0.38, 0.92)
	var gold_dim := Color(0.72, 0.56, 0.28, 0.75)
	## 左右から中央菱へ向かう横線（中央は菱で切る）。
	var diamond_half: float = 5.0
	var cx: float = sz.x * 0.5
	_name_frame_top_rule.draw_line(
		Vector2(0.0, y_mid), Vector2(cx - diamond_half - 1.0, y_mid), gold, 1.5, true
	)
	_name_frame_top_rule.draw_line(
		Vector2(cx + diamond_half + 1.0, y_mid), Vector2(sz.x, y_mid), gold, 1.5, true
	)
	var diamond := PackedVector2Array([
		Vector2(cx, y_mid - diamond_half * 0.7),
		Vector2(cx + diamond_half, y_mid),
		Vector2(cx, y_mid + diamond_half * 0.7),
		Vector2(cx - diamond_half, y_mid),
	])
	_name_frame_top_rule.draw_colored_polygon(diamond, gold)
	_name_frame_top_rule.draw_polyline(
		PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
		gold_dim,
		1.0,
		true
	)


func _ensure_power_panel() -> void:
	if _power_panel != null:
		return
	_power_panel = Control.new()
	_power_panel.name = "PowerPanel"
	_power_panel.z_index = 6
	_power_panel.visible = false
	_power_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_power_panel.clip_contents = false
	_power_frame = TextureRect.new()
	_power_frame.name = "PowerFrame"
	_power_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_power_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_power_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_power_frame.texture = ShowcaseUiTokensScript.power_frame_texture()
	_power_panel.add_child(_power_frame)
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", -2)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_power_panel.add_child(vb)
	_power_caption = Label.new()
	_power_caption.text = "総合戦力"
	_power_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_power_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(_power_caption, COLOR_GOLD)
	vb.add_child(_power_caption)
	_power_value = Label.new()
	_power_value.text = "0"
	_power_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_power_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(
		_power_value, ShowcaseUiTokensScript.STAT_POWER_FONT_SIZE, COLOR_GOLD
	)
	vb.add_child(_power_value)
	add_child(_power_panel)


func _set_power_display(power: int) -> void:
	_ensure_power_panel()
	if _power_value != null:
		_power_value.text = RosterUiHelper.format_combat_power(power)


func _ensure_change_member_button() -> void:
	if _btn_change_member != null:
		return
	_btn_change_member = Button.new()
	_btn_change_member.name = "BtnChangeMember"
	_btn_change_member.text = "キャラ変更"
	_btn_change_member.z_index = 6
	_btn_change_member.visible = false
	_btn_change_member.focus_mode = Control.FOCUS_NONE
	UiTypography.apply_menu_button(_btn_change_member, false)
	_apply_staff_chip_style(_btn_change_member, true)
	_btn_change_member.pressed.connect(_on_change_member_pressed)
	add_child(_btn_change_member)


func _update_change_member_button() -> void:
	if _btn_change_member == null:
		return
	_btn_change_member.visible = (
		_mode == Mode.OWN
		and _display_member != null
		and not _empty_panel.visible
	)


func _ensure_staff_list_button() -> void:
	if _btn_staff_list != null:
		return
	_btn_staff_list = Button.new()
	_btn_staff_list.name = "BtnStaffList"
	_btn_staff_list.text = "スタッフキャラ"
	_btn_staff_list.z_index = 6
	_btn_staff_list.visible = false
	_btn_staff_list.focus_mode = Control.FOCUS_NONE
	_btn_staff_list.clip_text = true
	UiTypography.apply_menu_button(_btn_staff_list, false)
	_btn_staff_list.add_theme_font_size_override("font_size", UiTypography.SIZE_CAPTION)
	_apply_staff_chip_style(_btn_staff_list, true)
	_btn_staff_list.pressed.connect(_on_staff_list_pressed)
	add_child(_btn_staff_list)


func _update_staff_list_button() -> void:
	if _btn_staff_list == null:
		return
	var show_btn: bool = _mode == Mode.STAFF and not _empty_panel.visible
	_btn_staff_list.visible = show_btn
	if not show_btn:
		return
	_btn_staff_list.text = "スタッフキャラ"
	_btn_staff_list.tooltip_text = "スタッフ作例を切り替える"


func _apply_staff_chip_style(btn: Button, active: bool) -> void:
	var style: StyleBox = ShowcaseUiTokensScript.staff_chip_style(active)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	var col: Color = COLOR_GOLD if active else COLOR_BODY
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", col)
	btn.add_theme_color_override("font_pressed_color", col)


func _on_staff_list_pressed() -> void:
	AudioManager.play_sfx("ui_select")
	_show_staff_preset_overlay()


func _on_staff_preset_pressed(preset_id: String) -> void:
	_staff_preset_id = preset_id
	_hide_pick_member_overlay()
	if _mode == Mode.STAFF:
		_refresh_display()


func _refresh_display() -> void:
	_display_member = null
	_credit_text = ""
	if _mode == Mode.OWN:
		_display_member = GameState.find_showcase_member()
		_staff_player_name = ""
		if _display_member == null:
			_show_empty_own()
			return
	else:
		var preset: Dictionary = ShowcaseCatalogScript.find_staff_preset(_staff_preset_id)
		if preset.is_empty() and ShowcaseCatalogScript.STAFF_PRESETS.size() > 0:
			preset = ShowcaseCatalogScript.STAFF_PRESETS[0].duplicate(true)
			_staff_preset_id = str(preset.get("id", ""))
		_display_member = ShowcaseCatalogScript.build_member_from_preset(preset)
		_staff_player_name = str(preset.get("player_name", ""))
		_credit_text = ""
		if _display_member == null:
			_show_empty_message("スタッフ作例を読み込めませんでした")
			return
	_empty_panel.visible = false
	_set_stage_visible(true)
	_populate_stage(_display_member)
	_update_change_member_button()
	_update_staff_list_button()


func _set_stage_visible(on: bool) -> void:
	_equip_panel.visible = on
	_stats_panel.visible = on
	_idle_host.visible = on
	_footer.visible = on
	if _power_panel != null:
		_power_panel.visible = on
	if _name_frame_top_rule != null:
		_name_frame_top_rule.visible = on
		if on:
			_name_frame_top_rule.queue_redraw()


func _show_empty_own() -> void:
	_set_stage_visible(false)
	_empty_panel.visible = true
	_empty_label.text = "まだ自慢キャラがいません。\n展示する仲間を選んでください。"
	for child in _empty_actions.get_children():
		child.queue_free()
	var lead_btn := Button.new()
	lead_btn.text = "パーティ先頭を展示する"
	UiTypography.apply_menu_button(lead_btn, false)
	_apply_staff_chip_style(lead_btn, true)
	lead_btn.pressed.connect(_on_set_party_lead)
	_empty_actions.add_child(lead_btn)
	var pick_lbl := Label.new()
	pick_lbl.text = "ロスターから選ぶ"
	UiTypography.apply_caption(pick_lbl, COLOR_GOLD)
	_empty_actions.add_child(pick_lbl)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 220)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_empty_actions.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for member: Resource in GameState.roster:
		if member == null:
			continue
		var row := Button.new()
		row.text = "%s  Lv.%d  %s" % [
			str(member.display_name),
			int(member.level),
			RosterUiHelper.job_display_name(member),
		]
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiTypography.apply_menu_button(row, false)
		_apply_staff_chip_style(row, false)
		row.pressed.connect(_on_pick_member.bind(str(member.id)))
		list.add_child(row)
	ScrollTouchHelper.enable(scroll)
	_footer_name.text = ""
	_footer_meta.text = ""
	_footer_credit.text = ""
	_update_change_member_button()
	_update_staff_list_button()


func _show_empty_message(msg: String) -> void:
	_set_stage_visible(false)
	_empty_panel.visible = true
	_empty_label.text = msg
	for child in _empty_actions.get_children():
		child.queue_free()
	_footer_name.text = ""
	_footer_meta.text = ""
	_footer_credit.text = ""
	_update_change_member_button()
	_update_staff_list_button()


func _on_set_party_lead() -> void:
	if GameState.party_members.is_empty():
		return
	var lead: Resource = GameState.party_members[0]
	if lead == null:
		return
	GameState.set_showcase_member_id(str(lead.id))
	SaveManager.save_game()
	_refresh_display()


func _on_pick_member(member_id: String) -> void:
	GameState.set_showcase_member_id(member_id)
	SaveManager.save_game()
	_hide_pick_member_overlay()
	_refresh_display()


func _on_change_member_pressed() -> void:
	AudioManager.play_sfx("ui_select")
	_show_pick_member_overlay()


func _ensure_pick_member_overlay() -> void:
	if _pick_overlay != null:
		return
	_pick_overlay = Control.new()
	_pick_overlay.name = "ShowcasePickMemberOverlay"
	_pick_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pick_overlay.visible = false
	_pick_overlay.z_index = 70
	_pick_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pick_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_pick_member_dim_input)
	_pick_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pick_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 720)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", ShowcaseUiTokensScript.detail_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(outer)
	var title := Label.new()
	title.text = "展示するキャラを選ぶ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(title, UiTypography.SIZE_BODY, COLOR_GOLD)
	outer.add_child(title)
	_pick_title = title
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 520)
	outer.add_child(scroll)
	_pick_list = VBoxContainer.new()
	_pick_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pick_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_pick_list)
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.custom_minimum_size = Vector2(200, 48)
	UiTypography.apply_menu_button(close_btn, false)
	_apply_staff_chip_style(close_btn, false)
	close_btn.pressed.connect(_hide_pick_member_overlay)
	outer.add_child(close_btn)
	ScrollTouchHelper.enable(scroll)


func _show_pick_member_overlay() -> void:
	_ensure_pick_member_overlay()
	_pick_mode = "member"
	if _pick_title != null:
		_pick_title.text = "展示するキャラを選ぶ"
	for child in _pick_list.get_children():
		child.queue_free()
	var current_id: String = str(GameState.showcase_member_id)
	for member: Resource in GameState.roster:
		if member == null:
			continue
		var mid: String = str(member.id)
		var row := Button.new()
		var mark: String = "（展示中）" if mid == current_id else ""
		row.text = "%s  Lv.%d  %s%s" % [
			str(member.display_name),
			int(member.level),
			RosterUiHelper.job_display_name(member),
			("  " + mark) if not mark.is_empty() else "",
		]
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 48)
		UiTypography.apply_menu_button(row, false)
		_apply_staff_chip_style(row, mid == current_id)
		row.pressed.connect(_on_pick_member.bind(mid))
		_pick_list.add_child(row)
	_pick_overlay.visible = true


func _show_staff_preset_overlay() -> void:
	_ensure_pick_member_overlay()
	_pick_mode = "staff"
	if _pick_title != null:
		_pick_title.text = "スタッフ作例を選ぶ"
	for child in _pick_list.get_children():
		child.queue_free()
	for raw: Variant in ShowcaseCatalogScript.staff_presets():
		if not (raw is Dictionary):
			continue
		var preset: Dictionary = raw
		var pid: String = str(preset.get("id", ""))
		if pid.is_empty():
			continue
		var row := Button.new()
		var pname: String = str(preset.get("player_name", preset.get("display_name", "？")))
		var char_name: String = str(preset.get("display_name", ""))
		var mark: String = "（表示中）" if pid == _staff_preset_id else ""
		if char_name.is_empty():
			row.text = "%s%s" % [pname, ("  " + mark) if not mark.is_empty() else ""]
		else:
			row.text = "%s  —  %s%s" % [
				pname,
				char_name,
				("  " + mark) if not mark.is_empty() else "",
			]
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 48)
		row.clip_text = true
		UiTypography.apply_menu_button(row, false)
		_apply_staff_chip_style(row, pid == _staff_preset_id)
		row.pressed.connect(_on_staff_preset_pressed.bind(pid))
		_pick_list.add_child(row)
	_pick_overlay.visible = true


func _hide_pick_member_overlay() -> void:
	if _pick_overlay != null:
		_pick_overlay.visible = false


func _on_pick_member_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_pick_member_overlay()
		AudioManager.play_sfx("ui_cancel")


func _populate_stage(member: Resource) -> void:
	for child in _equip_col.get_children():
		child.queue_free()
	for child in _idle_host.get_children():
		child.queue_free()
	for child in _stats_col.get_children():
		child.queue_free()

	## 装備は装備品一覧と同系のレア枠・背景・レア表記。見出し／帯は背景焼込。
	var equip_items: Array = [
		member.equipped_weapon,
		member.equipped_armor,
		member.equipped_accessory,
	]
	var equip_cats: Array[String] = ["weapon", "armor", "accessory"]
	var offsets: Array = ShowcaseUiTokensScript.EQUIP_ICON_OFFSETS
	for i in range(mini(equip_items.size(), offsets.size())):
		var icon: Control = _make_equip_icon_cell(equip_items[i], equip_cats[i])
		if icon == null:
			continue
		var off: Vector2 = offsets[i]
		icon.position = off
		_equip_col.add_child(icon)

	var portrait := ChrIdlePortraitView.new()
	portrait.set_portrait_size(ShowcaseUiTokensScript.STAGE_IDLE_PX)
	_idle_host.add_child(portrait)
	portrait.set_from_member(member)

	var stats: Dictionary = RosterUiHelper.compute_member_stats(member)
	_set_power_display(RosterUiHelper.combat_power_from_stats(stats))

	var values: Array[String] = [
		"%d" % int(stats.get("hp", 0)),
		"%d" % int(stats.get("attack", 0)),
		"%d" % int(stats.get("defense", 0)),
		"%.2f" % float(stats.get("speed", 1.0)),
		"%.0f%%" % (float(stats.get("crit_rate", 0.0)) * 100.0),
		"%.0f%%" % (float(stats.get("crit_damage", 1.5)) * 100.0),
	]
	var keys: Array[String] = ShowcaseUiTokensScript.STAT_KEYS
	var row_h: float = ShowcaseUiTokensScript.STAT_ROW_H
	var top_pad: float = ShowcaseUiTokensScript.STAT_HEADER_PAD
	var icon_left: float = ShowcaseUiTokensScript.STAT_ICON_LEFT
	var icon_px: float = ShowcaseUiTokensScript.STAT_ICON_PX
	var value_left: float = ShowcaseUiTokensScript.STAT_VALUE_LEFT
	var value_w: float = maxf(24.0, _stats_panel.size.x - value_left - 8.0)
	for i in range(values.size()):
		var y: float = top_pad + float(i) * row_h
		var key: String = keys[i] if i < keys.size() else ""
		var icon: Control = _make_stat_icon(key)
		if icon != null:
			icon.position = Vector2(icon_left, y + (row_h - icon_px) * 0.5)
			_stats_col.add_child(icon)
		var val: Label = _make_stat_value_only(values[i])
		val.position = Vector2(value_left, y)
		val.size = Vector2(value_w, row_h)
		_stats_col.add_child(val)

	_footer_name.text = str(member.display_name)
	if _mode == Mode.STAFF and not _staff_player_name.is_empty():
		_footer_name.text = _staff_player_name
	UiTypography.apply_display(_footer_name, UiTypography.SIZE_BODY, COLOR_GOLD)
	if _mode == Mode.STAFF:
		_footer_meta.text = "%s  Lv.%d  %s" % [
			str(member.display_name),
			int(member.level),
			RosterUiHelper.job_display_name(member),
		]
	else:
		_footer_meta.text = "Lv.%d  %s" % [
			int(member.level),
			RosterUiHelper.job_display_name(member),
		]
	UiTypography.apply_body(_footer_meta, UiTypography.SIZE_CAPTION - 2, COLOR_BODY)
	_footer_credit.text = _credit_text
	UiTypography.apply_caption(_footer_credit, COLOR_SUB)


func _make_equip_icon_cell(item: Resource, category: String) -> Control:
	var cell_px: int = ShowcaseUiTokensScript.EQUIP_CELL_PX
	var cell_size := Vector2(cell_px, cell_px)
	if item == null:
		return null
	var item_id: String = _item_id(item, category)
	var tex: Texture2D = IconPaths.get_icon_texture(item_id, category)
	if tex != null and category == "weapon":
		tex = IconPaths.display_texture_for_weapon(item_id, tex)
	if tex == null:
		return null
	var rarity: int = _item_rarity(item, category)
	var btn := Button.new()
	btn.custom_minimum_size = cell_size
	btn.size = cell_size
	btn.focus_mode = Control.FOCUS_NONE
	btn.clip_contents = true
	btn.tooltip_text = "%s\n（タップで詳細）" % EquipmentItemDetailHelper.short_name(item, category)
	btn.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	var normal: StyleBox = EquipmentUiTokens.rarity_slot_style(rarity, false, cell_px)
	var hover: StyleBox = EquipmentUiTokens.rarity_slot_style(rarity, true, cell_px)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override("disabled", normal)
	EquipmentUiTokens.attach_item_cell_layers(
		btn, tex, cell_px, EquipmentUiTokens.INV_CELL_DESIGN_PX, item_id, category
	)
	EquipmentUiHelper.apply_rarity_badges(btn, rarity, cell_size)
	if category == "weapon":
		EquipmentUiHelper.apply_enhance_badge(btn, item, category, cell_size, COLOR_GOLD)
	btn.pressed.connect(_on_equip_icon_pressed.bind(item, category))
	return btn


func _item_rarity(item: Resource, category: String) -> int:
	if item == null:
		return 0
	var data: Resource = null
	match category:
		"weapon":
			data = DataRegistry.get_weapon_data(str(item.weapon_id))
		"armor":
			data = DataRegistry.get_armor_data(str(item.armor_id))
		"accessory":
			data = DataRegistry.get_accessory_data(str(item.accessory_id))
	if data != null and "rarity" in data:
		return int(data.rarity)
	if "rarity" in item:
		return int(item.rarity)
	return 0


func _add_equip_corner_badge(
	btn: Button,
	text: String,
	color: Color,
	pos: Vector2,
	font_size: int
) -> void:
	if text.is_empty() or btn == null:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = pos
	btn.add_child(lbl)


func _on_equip_icon_pressed(item: Resource, category: String) -> void:
	if item == null:
		return
	AudioManager.play_sfx("ui_select")
	_show_equip_detail(item, category)


func _ensure_equip_detail_overlay() -> void:
	if _detail_overlay != null:
		return
	_detail_overlay = Control.new()
	_detail_overlay.name = "ShowcaseEquipDetailOverlay"
	_detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_overlay.visible = false
	_detail_overlay.z_index = 80
	_detail_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_detail_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_equip_detail_dim_input)
	_detail_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 720)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", ShowcaseUiTokensScript.detail_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(outer)
	_detail_title = Label.new()
	_detail_title.text = "装備詳細"
	_detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(_detail_title, UiTypography.SIZE_BODY, COLOR_GOLD)
	outer.add_child(_detail_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 480)
	outer.add_child(scroll)
	_detail_host = VBoxContainer.new()
	_detail_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_host.add_theme_constant_override("separation", 6)
	scroll.add_child(_detail_host)
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.custom_minimum_size = Vector2(200, 48)
	UiTypography.apply_menu_button(close_btn, false)
	close_btn.pressed.connect(_hide_equip_detail)
	outer.add_child(close_btn)
	ScrollTouchHelper.enable(scroll)


func _show_equip_detail(item: Resource, category: String) -> void:
	_ensure_equip_detail_overlay()
	if _detail_title != null:
		_detail_title.text = "装備詳細"
	EquipmentItemDetailHelper.populate_panel(
		_detail_host,
		item,
		category,
		{"show_owner": false, "header_icon_px": 72, "meta_host": self}
	)
	_detail_overlay.visible = true


func _hide_equip_detail() -> void:
	if _detail_overlay != null:
		_detail_overlay.visible = false
	AudioManager.play_sfx("ui_cancel")


func _on_equip_detail_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_equip_detail()


func _item_id(item: Resource, category: String) -> String:
	match category:
		"armor":
			return str(item.armor_id) if "armor_id" in item else ""
		"accessory":
			return str(item.accessory_id) if "accessory_id" in item else ""
		_:
			return str(item.weapon_id) if "weapon_id" in item else ""


func _make_stat_icon(stat_key: String) -> Control:
	var tex: Texture2D = EquipmentUiTokens.stat_icon(stat_key)
	if tex == null:
		return null
	var px: float = ShowcaseUiTokensScript.STAT_ICON_PX
	var host := Control.new()
	host.custom_minimum_size = Vector2(px, px)
	host.size = Vector2(px, px)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.texture = tex
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(tr)
	return host


func _make_stat_value_only(value: String) -> Label:
	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_lbl.clip_text = false
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(
		val_lbl,
		ShowcaseUiTokensScript.STAT_VALUE_FONT_SIZE,
		COLOR_GOLD
	)
	return val_lbl


func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_cancel")
	SceneRouter.change_scene(HOME_SCENE)
