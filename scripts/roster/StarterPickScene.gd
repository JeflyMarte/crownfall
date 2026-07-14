extends Control

## 新規ゲーム時の初期5人選択（P3-STORY-STARTER-001）。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"

var _selected_id: String = ""
var _confirm_btn: Button
var _cards: Dictionary = {}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.07, 0.1, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

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
	UiTypography.apply_display(title, UiTypography.SIZE_DISPLAY_TITLE)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "最初の1人を選択してください。\n残りはダンジョン攻略に応じて合流します。"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(sub, 16, Color(0.75, 0.78, 0.85))
	root.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
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
	sb.bg_color = Color(0.12, 0.13, 0.18, 0.95)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.35, 0.38, 0.45)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	_cards[adv_id] = panel

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconPaths.get_icon_texture(job_id, "chr")
	row.add_child(icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = str(def["name"])
	UiTypography.apply_display(name_lbl, 22)
	col.add_child(name_lbl)

	var job_data: Resource = DataRegistry.get_job_data(job_id)
	var job_lbl := Label.new()
	job_lbl.text = str(job_data.display_name) if job_data != null else job_id
	UiTypography.apply_body(job_lbl, 15, Color(0.7, 0.72, 0.8))
	col.add_child(job_lbl)

	return panel


func _select(adventurer_id: String) -> void:
	_selected_id = adventurer_id
	_confirm_btn.disabled = false
	for id: Variant in _cards.keys():
		var panel: PanelContainer = _cards[id]
		var sb: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if str(id) == adventurer_id:
			sb.border_color = Color(0.85, 0.72, 0.35)
			sb.bg_color = Color(0.18, 0.16, 0.12, 0.98)
		else:
			sb.border_color = Color(0.35, 0.38, 0.45)
			sb.bg_color = Color(0.12, 0.13, 0.18, 0.95)
		panel.add_theme_stylebox_override("panel", sb)


func _on_confirm() -> void:
	if _selected_id.is_empty():
		return
	if not GameState.select_starting_adventurer(_selected_id):
		return
	SaveManager.save_game()
	SceneRouter.change_scene(HOME_SCENE)
