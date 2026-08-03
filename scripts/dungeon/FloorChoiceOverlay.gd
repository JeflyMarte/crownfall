class_name FloorChoiceOverlay
extends Control

## ダンジョン分かれ道 UI（P3-DG-FLOOR-CHOICE-001）。
## 背景 720×1280 の四角位置に説明文／ヒット領域をスケール配置する。
## B 収穫はランダム2種を提示（プレイヤーは選ばない）。確定は警告文直下の実ボタン。
## 選択中パネルの直上に指差し画像を表示する。

signal confirmed(choice_id: String, harvest_kinds: Array[String])

const BG_PATH: String = "res://assets/ui/dungeon/UI_DG_FloorChoice_BG.png"
const POINTER_PATH: String = "res://assets/ui/dungeon/UI_DG_FloorChoice_Pointer.png"
const DESIGN_W: float = 720.0
const DESIGN_H: float = 1280.0

## パネル全体ヒット（左=戦力／中=収穫／右=強襲）
const PANEL_RECTS: Array[Rect2] = [
	Rect2(28, 300, 202, 395),
	Rect2(250, 300, 218, 395),
	Rect2(494, 300, 196, 395),
]
## アイコン下の説明文領域
const TEXT_RECTS: Array[Rect2] = [
	Rect2(38, 455, 182, 222),
	Rect2(260, 455, 198, 222),
	Rect2(504, 455, 176, 222),
]
## 警告文直下の空き領域（差し替え背景に確定ボタン焼き込みなし）
const CONFIRM_RECT: Rect2 = Rect2(110, 820, 500, 90)
## 選択中パネル直上の指差し（デザイン座標）
const POINTER_SIZE: Vector2 = Vector2(64, 100)
const POINTER_GAP_ABOVE: float = 6.0

const CHOICE_POWER: String = "power"
const CHOICE_HEAL: String = "heal"
const CHOICE_HARVEST: String = "harvest"
const CHOICE_ASSAULT: String = "assault"

var _bg: TextureRect
var _pointer: TextureRect
var _panel_buttons: Array[Button] = []
var _text_labels: Array[Label] = []
var _confirm_btn: Button
var _selected: String = ""
var _heal_mode: bool = false
var _offered_harvest: Array[String] = []
var _layout_ox: float = 0.0
var _layout_oy: float = 0.0
var _layout_scale: float = 1.0


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

	_pointer = TextureRect.new()
	_pointer.name = "SelectionPointer"
	_pointer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pointer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.visible = false
	if ResourceLoader.exists(POINTER_PATH):
		_pointer.texture = load(POINTER_PATH) as Texture2D
	add_child(_pointer)

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
	_confirm_btn.focus_mode = Control.FOCUS_NONE
	_confirm_btn.text = "選択を確定する"
	UiTypography.apply_menu_button(_confirm_btn)
	var confirm_sb := StyleBoxFlat.new()
	confirm_sb.bg_color = Color(0.12, 0.08, 0.18, 0.92)
	confirm_sb.border_color = Color(0.72, 0.55, 0.28, 1.0)
	confirm_sb.set_border_width_all(2)
	confirm_sb.set_corner_radius_all(6)
	confirm_sb.content_margin_left = 12
	confirm_sb.content_margin_right = 12
	confirm_sb.content_margin_top = 8
	confirm_sb.content_margin_bottom = 8
	_confirm_btn.add_theme_stylebox_override("normal", confirm_sb)
	var confirm_hover := confirm_sb.duplicate() as StyleBoxFlat
	confirm_hover.bg_color = Color(0.18, 0.12, 0.26, 0.95)
	_confirm_btn.add_theme_stylebox_override("hover", confirm_hover)
	_confirm_btn.add_theme_stylebox_override("pressed", confirm_hover)
	var confirm_dis := confirm_sb.duplicate() as StyleBoxFlat
	confirm_dis.bg_color = Color(0.08, 0.06, 0.10, 0.55)
	confirm_dis.border_color = Color(0.35, 0.32, 0.30, 1.0)
	_confirm_btn.add_theme_stylebox_override("disabled", confirm_dis)
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	add_child(_confirm_btn)

	resized.connect(_layout_to_size)
	_layout_to_size()


func open(heal_mode: bool) -> void:
	_heal_mode = heal_mode
	_selected = ""
	_offered_harvest = roll_harvest_kinds()
	_refresh_texts()
	_refresh_selection_visual()
	_update_confirm_enabled()
	visible = true
	move_to_front()


func close() -> void:
	visible = false


static func roll_harvest_kinds() -> Array[String]:
	var pool: Array[String] = BalanceConfig.FLOOR_CHOICE_REWARD_KINDS.duplicate()
	pool.shuffle()
	var picks: int = mini(BalanceConfig.FLOOR_CHOICE_HARVEST_PICKS, pool.size())
	var out: Array[String] = []
	for i: int in picks:
		out.append(pool[i])
	return out


func _layout_to_size() -> void:
	var sz: Vector2 = size
	if sz.x <= 1.0 or sz.y <= 1.0:
		return
	## COVER 相当: 短い辺に合わせて拡大し中央クロップ。
	_layout_scale = maxf(sz.x / DESIGN_W, sz.y / DESIGN_H)
	var draw_w: float = DESIGN_W * _layout_scale
	var draw_h: float = DESIGN_H * _layout_scale
	_layout_ox = (sz.x - draw_w) * 0.5
	_layout_oy = (sz.y - draw_h) * 0.5
	for i: int in 3:
		_place_control(_panel_buttons[i], PANEL_RECTS[i], _layout_ox, _layout_oy, _layout_scale)
		_place_control(_text_labels[i], TEXT_RECTS[i], _layout_ox, _layout_oy, _layout_scale)
	_place_control(_confirm_btn, CONFIRM_RECT, _layout_ox, _layout_oy, _layout_scale)
	_update_pointer_position()
	## 指差し・確定を前面に
	move_child(_pointer, get_child_count() - 1)
	move_child(_confirm_btn, get_child_count() - 1)


func _place_control(ctrl: Control, design: Rect2, ox: float, oy: float, scale: float) -> void:
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.position = Vector2(ox + design.position.x * scale, oy + design.position.y * scale)
	ctrl.size = design.size * scale


func _selected_panel_index() -> int:
	match _selected:
		CHOICE_POWER, CHOICE_HEAL:
			return 0
		CHOICE_HARVEST:
			return 1
		CHOICE_ASSAULT:
			return 2
		_:
			return -1


func _update_pointer_position() -> void:
	if _pointer == null:
		return
	var idx: int = _selected_panel_index()
	if idx < 0 or _layout_scale <= 0.0:
		_pointer.visible = false
		return
	var panel: Rect2 = PANEL_RECTS[idx]
	var design := Rect2(
		panel.position.x + (panel.size.x - POINTER_SIZE.x) * 0.5,
		panel.position.y - POINTER_SIZE.y - POINTER_GAP_ABOVE,
		POINTER_SIZE.x,
		POINTER_SIZE.y
	)
	_place_control(_pointer, design, _layout_ox, _layout_oy, _layout_scale)
	_pointer.visible = true


func _refresh_texts() -> void:
	var a_title: String = "応急手当" if _heal_mode else "戦力強化"
	var a_body: String = (
		"生存者を25%回復\n次のフロア開始時"
		if _heal_mode
		else "与ダメ ×1.5\n次のフロアのみ"
	)
	_text_labels[0].text = "%s\n%s" % [a_title, a_body]
	var harvest_labels: PackedStringArray = PackedStringArray()
	for k: String in _offered_harvest:
		harvest_labels.append(_harvest_kind_label(k))
	var harvest_line: String = "・".join(harvest_labels)
	if harvest_line.is_empty():
		harvest_line = "報酬2種"
	_text_labels[1].text = (
		"収穫強化\n%s\n×%.2f\n次のフロアのみ"
		% [harvest_line, BalanceConfig.FLOOR_CHOICE_HARVEST_MULT]
	)
	_text_labels[2].text = "強襲ルート\n精鋭＋雑魚が出現\n報酬すべて ×1.25"


func _on_panel_pressed(index: int) -> void:
	match index:
		0:
			_selected = CHOICE_HEAL if _heal_mode else CHOICE_POWER
		1:
			_selected = CHOICE_HARVEST
		2:
			_selected = CHOICE_ASSAULT
	_refresh_selection_visual()
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
	_update_pointer_position()


func _update_confirm_enabled() -> void:
	var ok: bool = not _selected.is_empty()
	if _selected == CHOICE_HARVEST and _offered_harvest.size() < BalanceConfig.FLOOR_CHOICE_HARVEST_PICKS:
		ok = false
	_confirm_btn.disabled = not ok
	_confirm_btn.mouse_filter = (
		Control.MOUSE_FILTER_STOP if ok else Control.MOUSE_FILTER_IGNORE
	)


func _on_confirm_pressed() -> void:
	if _confirm_btn.disabled or _selected.is_empty():
		return
	var kinds: Array[String] = []
	if _selected == CHOICE_HARVEST:
		kinds = _offered_harvest.duplicate()
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
