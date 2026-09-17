extends Control

## 新規ゲーム時の初期隊員選択 — P3-INTRO-001 / 002 / P3-STORY-STARTER-001。
## 選んだ1人のみ解放。他は章クリア等で加入。

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const _IntroTutorialConfig := preload("res://scripts/intro/IntroTutorialConfig.gd")
const PORTRAIT_SIZE := Vector2(112, 148)

var _selected_id: String = ""
var _confirm_btn: Button
var _cards: Dictionary = {}
## ConfirmationDialog（Window）は実機で入力を食う既往 → Control オーバーレイ。
var _confirm_overlay: Control = null
var _confirm_body_label: Label = null


func _ready() -> void:
	## 導入フローの続き（ニーナ吹き出し→隊員選択）。イントロBGMを維持。
	AudioManager.play_bgm("introduction")
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_IntroUiAssets.add_full_bg(self, _IntroUiAssets.BG_STARTER, Color(0.06, 0.07, 0.1, 1))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var title := Label.new()
	title.text = "調査隊員を選ぶ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(title, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "最初に編成の中心とする隊員を選んでください。\n選んだ隊員と、ギルド地下の訓練坑へ向かいます。"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(sub, 16, Color(0.82, 0.84, 0.90))
	root.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	for def: Variant in GameState.BASE_ROSTER_DEFS:
		list.add_child(_make_card(def as Dictionary))
	## カードは STOP+gui_input でタップ判定するため、未適用だと実機でタッチスクロールできない。
	ScrollTouchHelper.enable(scroll)

	_confirm_btn = Button.new()
	_confirm_btn.text = "この隊員で始める"
	_confirm_btn.disabled = true
	_confirm_btn.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_button(_confirm_btn)
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	root.add_child(_confirm_btn)
	_ensure_confirm_overlay()


func _make_card(def: Dictionary) -> PanelContainer:
	var adv_id: String = str(def["id"])
	var job_id: String = str(def["job"])
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select(adv_id)
	)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.14, 0.90)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.35, 0.38, 0.45)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	_cards[adv_id] = panel

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var portrait_stack := Control.new()
	portrait_stack.custom_minimum_size = PORTRAIT_SIZE
	row.add_child(portrait_stack)

	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconPaths.get_icon_texture(adv_id, "chr")
	if icon.texture == null:
		icon.texture = IconPaths.get_icon_texture(job_id, "chr")
	portrait_stack.add_child(icon)
	## キラ枠（STARTER_CARD_FRAME）は載せない。アイコン本体のみ。

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = str(def["name"])
	UiTypography.apply_display(name_lbl, 22)
	col.add_child(name_lbl)

	var job_data: Resource = DataRegistry.get_job_data(job_id)
	var job_lbl := Label.new()
	job_lbl.text = str(job_data.display_name) if job_data != null else job_id
	UiTypography.apply_body(job_lbl, 15, Color(0.75, 0.78, 0.86))
	col.add_child(job_lbl)

	var blurb := Label.new()
	blurb.text = _starter_blurb(job_data, job_id)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(blurb, Color(0.70, 0.72, 0.78))
	col.add_child(blurb)

	return panel


## 職の一行説明（性能・役割）。JobData.description を正とし、開発メモ括弧は表示から除く。
func _starter_blurb(job_data: Resource, job_id: String) -> String:
	var raw: String = ""
	if job_data != null and "description" in job_data:
		raw = str(job_data.description).strip_edges()
	if raw.is_empty():
		return "調査隊員。"
	# 「（召喚は将来実装）」等の実装メモをプレイヤー向け表示から除去。
	var cut: int = raw.find("（")
	if cut >= 0:
		raw = raw.substr(0, cut).strip_edges()
	if raw.is_empty():
		return _ensure_sentence_period(job_id)
	return _ensure_sentence_period(raw)


static func _ensure_sentence_period(text: String) -> String:
	var t: String = text.strip_edges()
	if t.is_empty():
		return t
	if t.ends_with("。") or t.ends_with("！") or t.ends_with("？") or t.ends_with("!"):
		return t
	return t + "。"


func _select(adventurer_id: String) -> void:
	_selected_id = adventurer_id
	_confirm_btn.disabled = false
	for id: Variant in _cards.keys():
		var panel: PanelContainer = _cards[id] as PanelContainer
		var sb: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if str(id) == adventurer_id:
			sb.border_color = Color(0.95, 0.82, 0.35)
		else:
			sb.border_color = Color(0.35, 0.38, 0.45)
		panel.add_theme_stylebox_override("panel", sb)


func _selected_display_name() -> String:
	if _selected_id.is_empty():
		return ""
	for def: Variant in GameState.BASE_ROSTER_DEFS:
		var d: Dictionary = def as Dictionary
		if str(d.get("id", "")) == _selected_id:
			return str(d.get("name", _selected_id))
	return _selected_id


func _on_confirm_pressed() -> void:
	if _selected_id.is_empty():
		return
	var name: String = _selected_display_name()
	AudioManager.play_sfx("ui_confirm")
	_show_confirm_overlay("%s ではじめてよろしいですか？" % name)


func _ensure_confirm_overlay() -> void:
	if _confirm_overlay != null:
		return
	_confirm_overlay = Control.new()
	_confirm_overlay.name = "ConfirmOverlay"
	_confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.visible = false
	_confirm_overlay.z_index = 80
	_confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirm_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_confirm_dim_input)
	_confirm_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.14, 0.96)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.86, 0.74, 0.45)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	var title := Label.new()
	title.text = "確認"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(title, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	col.add_child(title)
	_confirm_body_label = Label.new()
	_confirm_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(_confirm_body_label, 16, Color(0.82, 0.84, 0.90))
	col.add_child(_confirm_body_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	var cancel_btn := Button.new()
	cancel_btn.text = "いいえ"
	cancel_btn.custom_minimum_size = Vector2(140, 48)
	UiTypography.apply_button(cancel_btn)
	cancel_btn.pressed.connect(_on_confirm_canceled)
	row.add_child(cancel_btn)
	var ok_btn := Button.new()
	ok_btn.text = "はい"
	ok_btn.custom_minimum_size = Vector2(140, 48)
	UiTypography.apply_button(ok_btn)
	ok_btn.pressed.connect(_on_start_confirmed)
	row.add_child(ok_btn)


func _show_confirm_overlay(body: String) -> void:
	_ensure_confirm_overlay()
	_confirm_body_label.text = body
	_confirm_overlay.visible = true
	_confirm_overlay.move_to_front()


func _hide_confirm_overlay() -> void:
	if _confirm_overlay != null:
		_confirm_overlay.visible = false


func _on_confirm_canceled() -> void:
	AudioManager.play_sfx("ui_cancel")
	_hide_confirm_overlay()


func _on_confirm_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_confirm_canceled()


func _on_start_confirmed() -> void:
	_hide_confirm_overlay()
	if _selected_id.is_empty():
		return
	if not GameState.select_intro_starter(_selected_id):
		return
	_IntroTutorialConfig.mark_pending()
	_IntroTutorialConfig.begin_run()
	SaveManager.save_game()
	SceneRouter.change_scene(_IntroTutorialConfig.DUNGEON_SCENE)
