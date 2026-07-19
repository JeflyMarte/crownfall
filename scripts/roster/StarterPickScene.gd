extends Control

## 新規ゲーム時の初期隊員選択 — P3-INTRO-001 / 002 / P3-STORY-STARTER-001。
## 選んだ1人のみ解放。他は章クリア等で加入。

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const PORTRAIT_SIZE := Vector2(112, 148)

var _selected_id: String = ""
var _confirm_btn: Button
var _cards: Dictionary = {}


func _ready() -> void:
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
	sub.text = "最初に編成の中心とする隊員を選んでください。\n選んだ隊員が先頭になります。"
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

	_confirm_btn = Button.new()
	_confirm_btn.text = "この隊員で始める"
	_confirm_btn.disabled = true
	_confirm_btn.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_button(_confirm_btn)
	_confirm_btn.pressed.connect(_on_confirm)
	root.add_child(_confirm_btn)


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

	var frame_tex: Texture2D = _IntroUiAssets.load_tex(_IntroUiAssets.STARTER_CARD_FRAME)
	if frame_tex != null:
		var frame := TextureRect.new()
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.texture = frame_tex
		portrait_stack.add_child(frame)

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
		return job_id
	return raw


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


func _on_confirm() -> void:
	if _selected_id.is_empty():
		return
	if not GameState.select_intro_starter(_selected_id):
		return
	SaveManager.save_game()
	SceneRouter.change_scene(HOME_SCENE)
