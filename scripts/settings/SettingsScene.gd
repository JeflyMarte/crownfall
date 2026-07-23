extends Control

## 設定画面（MVP）— 音声 / ゲームプレイ / システム。

const _SettingsPrefs := preload("res://scripts/settings/SettingsPrefs.gd")
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const TITLE_SCENE: String = "res://scenes/title/TitleScene.tscn"
## 司令官BGの罫線が「ーーー」に見えるため、設定は単色下地のみ（テクスチャBG禁止）。
const BG_COLOR: Color = Color(0.045, 0.045, 0.09, 1.0)

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const SECTION_GAP: int = 16
const BODY_SEP: int = 8
const INNER_PAD: int = 10
## Header 下端と音声パネルのあいだの余白。
const HEADER_CONTENT_GAP: float = 24.0
const _META_BODY_BASE_TOP: StringName = &"_cf_body_base_top"

@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _bg: ColorRect = $Bg
@onready var _main_scroll: ScrollContainer = $MainScroll
@onready var _content_host: VBoxContainer = $MainScroll/MainVBox/ContentHost

var _speed_buttons: Dictionary = {}
var _redeem_input: LineEdit = null
var _redeem_status: Label = null
var _redeem_dialog: AcceptDialog = null


func _ready() -> void:
	_SettingsPrefs.ensure_loaded()
	if _bg != null:
		_bg.color = BG_COLOR
	_label_title.text = "設定"
	UiTypography.apply_screen_title(_label_title)
	UiTypography.apply_button(_btn_back, false)
	_btn_back.pressed.connect(_on_back_pressed)
	_content_host.add_theme_constant_override("separation", SECTION_GAP)
	## chrome 適用前に本文基準 top を入れておく（BottomNavHelper → HubLayoutHelper）。
	_sync_main_scroll_below_header()
	if _opened_from_title():
		var bottom: Control = $BottomNav as Control
		if bottom != null:
			bottom.visible = false
	else:
		BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	_ensure_redeem_dialog()
	_rebuild_page()
	_configure_layout()
	call_deferred("_configure_layout")
	var tree: SceneTree = get_tree()
	if tree != null:
		var timer: SceneTreeTimer = tree.create_timer(0.08)
		timer.timeout.connect(_configure_layout)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_configure_layout()


func _configure_layout() -> void:
	if _main_scroll == null:
		return
	_sync_main_scroll_below_header()
	var bottom: Control = $BottomNav as Control
	var nav_hidden: bool = bottom == null or not bottom.visible
	if nav_hidden:
		_main_scroll.offset_bottom = -12.0
	else:
		var nav_h: float = maxf(NavUiTokens.BOTTOM_NAV_HEIGHT, bottom.size.y) + 8.0
		_main_scroll.offset_bottom = -nav_h


func _sync_main_scroll_below_header() -> void:
	var header: Control = $Header as Control
	if header == null or _main_scroll == null:
		return
	var top_inset: float = 0.0
	if SafeAreaHelper.should_apply_chrome():
		top_inset = SafeAreaHelper.top_inset()
	var header_bottom: float = header.offset_bottom
	if header.size.y > 1.0:
		header_bottom = maxf(header_bottom, header.offset_top + header.size.y)
	var desired_top: float = header_bottom + HEADER_CONTENT_GAP
	_main_scroll.offset_top = desired_top
	_main_scroll.set_meta(
		_META_BODY_BASE_TOP,
		maxf(HEADER_CONTENT_GAP + 46.0, desired_top - top_inset)
	)


func _rebuild_page() -> void:
	for child in _content_host.get_children():
		child.queue_free()
	_speed_buttons.clear()
	_content_host.add_child(_build_audio_section())
	_content_host.add_child(_build_gameplay_section())
	_content_host.add_child(_build_redeem_section())
	_content_host.add_child(_build_system_section())


func _build_audio_section() -> Control:
	var sec: Dictionary = _begin_section("音声")
	var body: VBoxContainer = sec["body"]
	body.add_child(_make_volume_row("Master", _SettingsPrefs.get_master_volume(), _on_master_changed))
	body.add_child(_make_volume_row("BGM", _SettingsPrefs.get_bgm_volume(), _on_bgm_changed))
	body.add_child(_make_volume_row("SE", _SettingsPrefs.get_sfx_volume(), _on_sfx_changed))
	var mute := CheckButton.new()
	mute.text = "ミュート"
	mute.button_pressed = _SettingsPrefs.is_muted()
	mute.toggled.connect(_on_mute_toggled)
	UiTypography.apply_button(mute, false)
	body.add_child(mute)
	return sec["panel"]


func _build_gameplay_section() -> Control:
	var sec: Dictionary = _begin_section("ゲームプレイ")
	var body: VBoxContainer = sec["body"]
	var speed_lbl := Label.new()
	speed_lbl.text = "戦闘速度（探索開始時）"
	UiTypography.apply_caption(speed_lbl, COLOR_SUB)
	body.add_child(speed_lbl)
	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	body.add_child(speed_row)
	for pair in [
		[_SettingsPrefs.SPEED_ID_X1, "×1"],
		[_SettingsPrefs.SPEED_ID_X15, "×1.5"],
	]:
		var btn := Button.new()
		btn.toggle_mode = true
		btn.text = str(pair[1])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_speed_pressed.bind(str(pair[0])))
		UiTypography.apply_button(btn, false)
		speed_row.add_child(btn)
		_speed_buttons[str(pair[0])] = btn
	_refresh_speed_buttons()
	var dmg := CheckButton.new()
	dmg.text = "ダメージ数字を表示"
	dmg.button_pressed = _SettingsPrefs.show_damage_numbers()
	dmg.toggled.connect(_on_damage_toggled)
	UiTypography.apply_button(dmg, false)
	body.add_child(dmg)
	var log_btn := CheckButton.new()
	log_btn.text = "戦闘ログを表示"
	log_btn.button_pressed = _SettingsPrefs.show_battle_log()
	log_btn.toggled.connect(_on_log_toggled)
	UiTypography.apply_button(log_btn, false)
	body.add_child(log_btn)
	var vib := CheckButton.new()
	vib.text = "振動（対応端末のみ）"
	vib.button_pressed = _SettingsPrefs.is_vibration_enabled()
	vib.toggled.connect(_on_vibration_toggled)
	UiTypography.apply_button(vib, false)
	body.add_child(vib)
	return sec["panel"]


func _build_redeem_section() -> Control:
	var sec: Dictionary = _begin_section("特典コード")
	var body: VBoxContainer = sec["body"]
	_add_caption(body, "コードを入力して特典を受け取ります（セーブごと1回）")
	_redeem_input = LineEdit.new()
	_redeem_input.placeholder_text = "コードを入力"
	_redeem_input.clear_button_enabled = true
	_redeem_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_redeem_input.custom_minimum_size = Vector2(0, 40)
	var body_font: Font = UiTypography.body_font()
	if body_font != null:
		_redeem_input.add_theme_font_override("font", body_font)
	_redeem_input.add_theme_font_size_override("font_size", UiTypography.SIZE_BODY_SMALL)
	_redeem_input.add_theme_color_override("font_color", UiTypography.COLOR_BODY)
	_redeem_input.text_submitted.connect(func(_t: String) -> void: _on_redeem_pressed())
	body.add_child(_redeem_input)
	var btn := Button.new()
	btn.text = "受け取る"
	btn.pressed.connect(_on_redeem_pressed)
	UiTypography.apply_button(btn, true)
	body.add_child(btn)
	_redeem_status = Label.new()
	_redeem_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_redeem_status.text = ""
	UiTypography.apply_caption(_redeem_status, COLOR_SUB)
	body.add_child(_redeem_status)
	return sec["panel"]


func _build_system_section() -> Control:
	var sec: Dictionary = _begin_section("システム")
	var body: VBoxContainer = sec["body"]
	_add_caption(body, "バージョン: %s" % _SettingsPrefs.app_version_text())
	_add_caption(body, _SettingsPrefs.save_status_text())
	var home_btn := Button.new()
	home_btn.text = "タイトルへ戻る" if _opened_from_title() else "拠点へ戻る"
	home_btn.pressed.connect(_on_back_pressed)
	UiTypography.apply_button(home_btn, false)
	body.add_child(home_btn)
	return sec["panel"]


func _begin_section(title: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", INNER_PAD)
	margin.add_theme_constant_override("margin_right", INNER_PAD)
	margin.add_theme_constant_override("margin_top", INNER_PAD)
	margin.add_theme_constant_override("margin_bottom", INNER_PAD)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", BODY_SEP)
	margin.add_child(col)
	var heading := Label.new()
	heading.text = title
	UiTypography.apply_display(heading, UiTypography.SIZE_BODY, COLOR_GOLD)
	col.add_child(heading)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", BODY_SEP)
	col.add_child(body)
	return {"panel": panel, "body": body}


func _make_volume_row(label_text: String, value: float, handler: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(72, 0)
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL)
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 28)
	slider.value_changed.connect(handler)
	row.add_child(slider)
	var pct := Label.new()
	pct.name = "Pct"
	pct.custom_minimum_size = Vector2(48, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.text = "%d%%" % int(round(value * 100.0))
	UiTypography.apply_caption(pct, COLOR_SUB)
	row.add_child(pct)
	slider.value_changed.connect(func(v: float) -> void:
		pct.text = "%d%%" % int(round(v * 100.0))
	)
	return row


func _add_caption(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(lbl, COLOR_SUB)
	parent.add_child(lbl)


func _refresh_speed_buttons() -> void:
	var current: String = _SettingsPrefs.get_combat_speed_id()
	for speed_id in _speed_buttons.keys():
		var btn: Button = _speed_buttons[speed_id] as Button
		if btn == null:
			continue
		var active: bool = str(speed_id) == current
		btn.button_pressed = active
		UiTypography.apply_button(btn, active)


func _on_master_changed(v: float) -> void:
	_SettingsPrefs.set_master_volume(v)


func _on_bgm_changed(v: float) -> void:
	_SettingsPrefs.set_bgm_volume(v)


func _on_sfx_changed(v: float) -> void:
	_SettingsPrefs.set_sfx_volume(v)
	AudioManager.play_sfx("ui_switch", 1.0, 0.08)


func _on_mute_toggled(v: bool) -> void:
	_SettingsPrefs.set_muted(v)


func _on_speed_pressed(speed_id: String) -> void:
	_SettingsPrefs.set_combat_speed_id(speed_id)
	_refresh_speed_buttons()


func _on_damage_toggled(v: bool) -> void:
	_SettingsPrefs.set_show_damage_numbers(v)


func _on_log_toggled(v: bool) -> void:
	_SettingsPrefs.set_show_battle_log(v)


func _on_vibration_toggled(v: bool) -> void:
	_SettingsPrefs.set_vibration_enabled(v)


func _opened_from_title() -> bool:
	return SceneRouter.settings_return_scene == TITLE_SCENE


func _ensure_redeem_dialog() -> void:
	if _redeem_dialog != null:
		return
	_redeem_dialog = AcceptDialog.new()
	_redeem_dialog.title = "特典コード"
	_redeem_dialog.ok_button_text = "OK"
	add_child(_redeem_dialog)


func _on_redeem_pressed() -> void:
	if _redeem_input == null:
		return
	AudioManager.play_sfx("ui_switch", 1.0, 0.08)
	var raw: String = _redeem_input.text
	## タイトルから開いた場合はセーブを読み直してから付与（空 GameState 上書き防止）。
	var result: Dictionary = RedeemCodeSystem.try_redeem(raw, _opened_from_title())
	var message: String = str(result.get("message", ""))
	if bool(result.get("ok", false)):
		var summary: String = str(result.get("summary", ""))
		if not summary.is_empty():
			message = "%s\n\n%s" % [message, summary]
		if _redeem_input != null:
			_redeem_input.text = ""
		AudioManager.play_sfx("ui_confirm", 1.0, 0.08)
	if _redeem_status != null:
		_redeem_status.text = message
	_ensure_redeem_dialog()
	_redeem_dialog.dialog_text = message
	_redeem_dialog.popup_centered()


func _on_back_pressed() -> void:
	var path: String = SceneRouter.settings_return_scene
	if path.is_empty():
		path = HOME_SCENE
	SceneRouter.change_scene(path)
