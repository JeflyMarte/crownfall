class_name FloorChoiceOverlay
extends Control

## ダンジョン分かれ道 UI（P3-DG-FLOOR-CHOICE-001）。
## 背景 720×1280 の四角位置に説明文／ヒット領域をスケール配置する。

signal confirmed(choice_id: String, harvest_kinds: Array[String])

const BG_PATH: String = "res://assets/ui/dungeon/UI_DG_FloorChoice_BG.png"
const DESIGN_W: float = 720.0
const DESIGN_H: float = 1280.0

## パネル全体ヒット（左=戦力／中=収穫／右=強襲）
const PANEL_RECTS: Array[Rect2] = [
	Rect2(28, 300, 197, 395),
	Rect2(250, 300, 218, 395),
	Rect2(494, 300, 196, 395),
]
## アイコン下の説明文領域
const TEXT_RECTS: Array[Rect2] = [
	Rect2(38, 455, 177, 222),
	Rect2(260, 455, 198, 222),
	Rect2(504, 455, 176, 222),
]
const CONFIRM_RECT: Rect2 = Rect2(110, 1005, 500, 90)

const CHOICE_POWER: String = "power"
const CHOICE_HEAL: String = "heal"
const CHOICE_HARVEST: String = "harvest"
const CHOICE_ASSAULT: String = "assault"

var _bg: TextureRect
var _panel_buttons: Array[Button] = []
var _text_labels: Array[Label] = []
var _confirm_btn: Button
var _harvest_row: HBoxContainer
var _harvest_toggles: Dictionary = {}
var _selected: String = ""
var _heal_mode: bool = false
var _selected_harvest: Array[String] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = TextureRect.new()
	_bg.name = "FloorChoiceBg"
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(BG_PATH):
		_bg.texture = load(BG_PATH) as Texture2D
	add_child(_bg)

	for i: int in 3:
		var hit := Button.new()
		hit.name = "PanelHit%d" % i
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		var sb := StyleBoxEmpty.new()
		hit.add_theme_stylebox_override("normal", sb)
		hit.add_theme_stylebox_override("hover", sb)
		hit.add_theme_stylebox_override("pressed", sb)
		hit.add_theme_stylebox_override("focus", sb)
		hit.pressed.connect(_on_panel_pressed.bind(i))
		add_child(hit)
		_panel_buttons.append(hit)

		var lab := Label.new()
		lab.name = "PanelText%d" % i
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_body(lab, 18, UiTypography.COLOR_BODY, UiTypography.OUTLINE_BODY)
		add_child(lab)
		_text_labels.append(lab)

	_confirm_btn = Button.new()
	_confirm_btn.name = "ConfirmHit"
	_confirm_btn.flat = true
	_confirm_btn.focus_mode = Control.FOCUS_NONE
	_confirm_btn.text = ""
	var empty := StyleBoxEmpty.new()
	_confirm_btn.add_theme_stylebox_override("normal", empty)
	_confirm_btn.add_theme_stylebox_override("hover", empty)
	_confirm_btn.add_theme_stylebox_override("pressed", empty)
	_confirm_btn.add_theme_stylebox_override("disabled", empty)
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	add_child(_confirm_btn)

	_harvest_row = HBoxContainer.new()
	_harvest_row.name = "HarvestToggles"
	_harvest_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_harvest_row.add_theme_constant_override("separation", 8)
	_harvest_row.visible = false
	add_child(_harvest_row)
	for kind: String in BalanceConfig.FLOOR_CHOICE_REWARD_KINDS:
		var tog := Button.new()
		tog.toggle_mode = true
		tog.text = _harvest_kind_label(kind)
		tog.focus_mode = Control.FOCUS_NONE
		UiTypography.apply_menu_button(tog)
		tog.toggled.connect(_on_harvest_toggled.bind(kind))
		_harvest_row.add_child(tog)
		_harvest_toggles[kind] = tog

	resized.connect(_layout_to_size)
	_layout_to_size()


func open(heal_mode: bool) -> void:
	_heal_mode = heal_mode
	_selected = ""
	_selected_harvest.clear()
	for kind: String in _harvest_toggles.keys():
		var tog: Button = _harvest_toggles[kind]
		tog.set_pressed_no_signal(false)
	_harvest_row.visible = false
	_refresh_texts()
	_refresh_selection_visual()
	_update_confirm_enabled()
	visible = true
	move_to_front()


func close() -> void:
	visible = false


func _layout_to_size() -> void:
	var sz: Vector2 = size
	if sz.x <= 1.0 or sz.y <= 1.0:
		return
	## COVER 相当: 短い辺に合わせて拡大し中央クロップ。
	var scale: float = maxf(sz.x / DESIGN_W, sz.y / DESIGN_H)
	var draw_w: float = DESIGN_W * scale
	var draw_h: float = DESIGN_H * scale
	var ox: float = (sz.x - draw_w) * 0.5
	var oy: float = (sz.y - draw_h) * 0.5
	for i: int in 3:
		_place_control(_panel_buttons[i], PANEL_RECTS[i], ox, oy, scale)
		_place_control(_text_labels[i], TEXT_RECTS[i], ox, oy, scale)
	_place_control(_confirm_btn, CONFIRM_RECT, ox, oy, scale)
## 収穫トグルは中央パネル下端〜警告の手前
	var row_r := Rect2(120.0, 708.0, 480.0, 48.0)
	_place_control(_harvest_row, row_r, ox, oy, scale)


func _place_control(ctrl: Control, design: Rect2, ox: float, oy: float, scale: float) -> void:
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.position = Vector2(ox + design.position.x * scale, oy + design.position.y * scale)
	ctrl.size = design.size * scale


func _refresh_texts() -> void:
	var a_title: String = "応急手当" if _heal_mode else "戦力強化"
	var a_body: String = (
		"生存者を25%回復\n次のフロア開始時"
		if _heal_mode
		else "与ダメ ×1.5\n次のフロアのみ"
	)
	_text_labels[0].text = "%s\n%s" % [a_title, a_body]
	_text_labels[1].text = "収穫強化\n報酬2種を選んで\n×1.35\n次のフロアのみ"
	_text_labels[2].text = "強襲ルート\n精鋭＋雑魚が出現\n報酬すべて ×1.25"


func _on_panel_pressed(index: int) -> void:
	match index:
		0:
			_selected = CHOICE_HEAL if _heal_mode else CHOICE_POWER
			_harvest_row.visible = false
			_clear_harvest_selection()
		1:
			_selected = CHOICE_HARVEST
			_harvest_row.visible = true
		2:
			_selected = CHOICE_ASSAULT
			_harvest_row.visible = false
			_clear_harvest_selection()
	_refresh_selection_visual()
	_update_confirm_enabled()


func _clear_harvest_selection() -> void:
	_selected_harvest.clear()
	for kind: String in _harvest_toggles.keys():
		(_harvest_toggles[kind] as Button).set_pressed_no_signal(false)


func _on_harvest_toggled(pressed: bool, kind: String) -> void:
	if pressed:
		if kind in _selected_harvest:
			return
		if _selected_harvest.size() >= BalanceConfig.FLOOR_CHOICE_HARVEST_PICKS:
			## 上限超過分はトグルを戻す
			(_harvest_toggles[kind] as Button).set_pressed_no_signal(false)
			return
		_selected_harvest.append(kind)
	else:
		_selected_harvest.erase(kind)
	_update_confirm_enabled()


func _refresh_selection_visual() -> void:
	for i: int in 3:
		var chosen: bool = false
		match i:
			0:
				chosen = _selected == CHOICE_POWER or _selected == CHOICE_HEAL
			1:
				chosen = _selected == CHOICE_HARVEST
			2:
				chosen = _selected == CHOICE_ASSAULT
		_panel_buttons[i].modulate = Color(1.15, 1.15, 1.05, 1.0) if chosen else Color.WHITE
		_text_labels[i].modulate = Color(1.2, 1.15, 0.9, 1.0) if chosen else Color.WHITE


func _update_confirm_enabled() -> void:
	var ok: bool = false
	if _selected == CHOICE_POWER or _selected == CHOICE_HEAL or _selected == CHOICE_ASSAULT:
		ok = true
	elif _selected == CHOICE_HARVEST:
		ok = _selected_harvest.size() == BalanceConfig.FLOOR_CHOICE_HARVEST_PICKS
	_confirm_btn.disabled = not ok
	_confirm_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP if ok else Control.MOUSE_FILTER_IGNORE
	)


func _on_confirm_pressed() -> void:
	if _confirm_btn.disabled or _selected.is_empty():
		return
	var kinds: Array[String] = []
	if _selected == CHOICE_HARVEST:
		kinds = _selected_harvest.duplicate()
	confirmed.emit(_selected, kinds)


static func _harvest_kind_label(kind: String) -> String:
	match kind:
		"exp":
			return "経験値"
		"gold":
			return "ゴールド"
		"material":
			return "素材"
		"equip":
			return "装備"
		_:
			return kind
