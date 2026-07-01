extends Control

const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")

const FORMATION_SLOT_COUNT: int = 4
const FORMATION_CELL_PX: int = 148

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_FRONT: Color = Color(0.55, 0.72, 0.95)
const COLOR_BACK: Color = Color(0.65, 0.85, 0.55)
const COLOR_EMPTY: Color = Color(0.35, 0.33, 0.30)
const COLOR_PICK: Color = Color(0.95, 0.78, 0.35)

var _selected: Array = []
var _formation_slots: Array = [null, null, null, null]
var _formation_pick_slot: int = -1
var _formation_cells: Array[PanelContainer] = []

@onready var _tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var _formation_board: VBoxContainer = $VBoxContainer/TabContainer/TabFormation/FormationBoard
@onready var _label_status: Label = $VBoxContainer/LabelStatus
@onready var _button_confirm: Button = $VBoxContainer/ButtonConfirm

func _ready() -> void:
	_tab_container.set_tab_title(0, "編成")
	_tab_container.set_tab_title(1, "陣形")
	_tab_container.tab_changed.connect(_on_tab_changed)
	$VBoxContainer/ButtonConfirm.pressed.connect(_on_confirm_pressed)
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	$VBoxContainer/TabContainer/TabFormation/PresetRow/ButtonPresetFront.pressed.connect(
		_on_formation_preset_pressed.bind("front")
	)
	$VBoxContainer/TabContainer/TabFormation/PresetRow/ButtonPresetBalanced.pressed.connect(
		_on_formation_preset_pressed.bind("balanced")
	)
	$VBoxContainer/TabContainer/TabFormation/PresetRow/ButtonPresetBack.pressed.connect(
		_on_formation_preset_pressed.bind("back")
	)
	_selected = GameState.party_members.duplicate()
	_init_formation_slots_from_party()
	_build_formation_grid()
	_rebuild_roster_list()
	_refresh_formation_grid()
	_update_confirm_button()

func _on_tab_changed(tab: int) -> void:
	if tab == 1:
		_sync_formation_slots_from_selection()
		_refresh_formation_grid()

func _init_formation_slots_from_party() -> void:
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = null
	for i in mini(FORMATION_SLOT_COUNT, GameState.party_members.size()):
		_formation_slots[i] = GameState.party_members[i]

func _sync_formation_slots_from_selection() -> void:
	var kept: Array = []
	for slot in _formation_slots:
		if slot != null and _selected.has(slot):
			kept.append(slot)
	for adv in _selected:
		if not kept.has(adv):
			kept.append(adv)
	while kept.size() < FORMATION_SLOT_COUNT:
		kept.append(null)
	for i in FORMATION_SLOT_COUNT:
		_formation_slots[i] = kept[i] if i < kept.size() else null
	_apply_formation_rows_from_slots()

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
	label.add_theme_font_size_override("font_size", 15)
	_formation_board.add_child(label)

func _make_formation_row(slot_a: int, slot_b: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.add_child(_make_formation_cell(slot_a))
	row.add_child(_make_formation_cell(slot_b))
	return row

func _make_formation_cell(slot_index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(FORMATION_CELL_PX, FORMATION_CELL_PX)
	panel.add_theme_stylebox_override("panel", _cell_style(false, false))
	panel.gui_input.connect(_on_formation_cell_input.bind(slot_index))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.name = "FormationCell%d" % slot_index
	_formation_cells.append(panel)
	return panel

func _cell_style(active: bool, picked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.94)
	if picked:
		style.border_color = COLOR_PICK
		style.set_border_width_all(3)
	elif active:
		style.border_color = COLOR_GOLD
		style.set_border_width_all(3)
	else:
		style.border_color = Color(0.45, 0.40, 0.32)
		style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
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
		var is_front: bool = i < 2
		panel.add_theme_stylebox_override(
			"panel", _cell_style(is_front, _formation_pick_slot == i)
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
		vbox.add_theme_constant_override("separation", 4)
		var icon_tex: Texture2D = IconPaths.get_icon_texture(str(member.job_id), "chr")
		if icon_tex != null:
			var portrait := TextureRect.new()
			portrait.texture = icon_tex
			portrait.custom_minimum_size = Vector2(72, 72)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vbox.add_child(portrait)
		var name_lbl := Label.new()
		name_lbl.text = member.display_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(name_lbl)
		var row_lbl := Label.new()
		row_lbl.text = "後列" if GameState.get_member_formation_row(member) == GameState.FORMATION_BACK else "前列"
		row_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_lbl.add_theme_font_size_override("font_size", 11)
		row_lbl.add_theme_color_override(
			"font_color", COLOR_BACK if GameState.get_member_formation_row(member) == GameState.FORMATION_BACK else COLOR_FRONT
		)
		vbox.add_child(row_lbl)
		panel.add_child(vbox)

func _slot_row_for_index(slot_index: int) -> int:
	return GameState.FORMATION_FRONT if slot_index < 2 else GameState.FORMATION_BACK

func _apply_formation_rows_from_slots() -> void:
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member == null:
			continue
		GameState.set_member_formation_row(member, _slot_row_for_index(i))
		GameState.set_member_formation_slot(member, i)

func _on_formation_preset_pressed(preset: String) -> void:
	var members: Array = _collect_selected_members_for_formation()
	if members.is_empty():
		_label_status.text = "先に編成タブでメンバーを選んでください"
		return
	match preset:
		"front":
			_assign_formation_by_role(members, true)
		"back":
			_assign_formation_by_role(members, false)
		_:
			_place_members_in_slots(members, [0, 1, 2, 3])
	_apply_formation_rows_from_slots()
	_formation_pick_slot = -1
	_refresh_formation_grid()

func _collect_selected_members_for_formation() -> Array:
	var members: Array = []
	for adv in _formation_slots:
		if adv != null:
			members.append(adv)
	if members.is_empty():
		members = _selected.duplicate()
	return members

const _FRONT_JOB_IDS: Array[String] = ["swordsman", "vanguard"]

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

func _rebuild_roster_list() -> void:
	var container: VBoxContainer = $VBoxContainer/TabContainer/TabRoster/ScrollContainer/RosterListContainer
	for child in container.get_children():
		child.queue_free()
	for adv in GameState.get_roster():
		_add_roster_row(container, adv)

func _add_roster_row(container: VBoxContainer, adv: Resource) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var btn := Button.new()
	btn.text = "★" if _selected.has(adv) else "☆"
	btn.pressed.connect(func(): _toggle_selection(adv))
	row.add_child(btn)
	var icon_tex: Texture2D = IconPaths.get_icon_texture(str(adv.job_id), "chr")
	if icon_tex != null:
		var portrait := TextureRect.new()
		portrait.texture = icon_tex
		portrait.custom_minimum_size = Vector2(48, 48)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)
	var lbl := Label.new()
	lbl.text = _format_roster_member(adv)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	container.add_child(row)

func _toggle_selection(adv: Resource) -> void:
	if _selected.has(adv):
		if _selected.size() > 1:
			_selected.erase(adv)
	else:
		if _selected.size() < GameState.ACTIVE_PARTY_SIZE:
			_selected.append(adv)
	_sync_formation_slots_from_selection()
	_rebuild_roster_list()
	_refresh_formation_grid()
	_update_confirm_button()

func _ordered_party_from_formation() -> Array:
	var ordered: Array = []
	for i in FORMATION_SLOT_COUNT:
		var member: Resource = _formation_slots[i]
		if member != null and _selected.has(member):
			ordered.append(member)
	for adv in _selected:
		if not ordered.has(adv):
			ordered.append(adv)
	return ordered

func _update_confirm_button() -> void:
	var count: int = _selected.size()
	_button_confirm.disabled = count < 1 or count > GameState.ACTIVE_PARTY_SIZE

func _on_confirm_pressed() -> void:
	_sync_formation_slots_from_selection()
	_apply_formation_rows_from_slots()
	var party: Array = _ordered_party_from_formation()
	if not GameState.set_active_party(party):
		_label_status.text = "編成の変更に失敗しました（1〜%d名・重複不可）" % GameState.ACTIVE_PARTY_SIZE
		return
	SaveManager.save_game()
	_label_status.text = "編成・陣形を保存しました"

func _format_roster_member(adv: Resource) -> String:
	var mods: Dictionary = _JobStatCalculator.get_member_modifiers(adv)
	var job_display: String = mods.get("display_name", str(adv.job_id))
	if job_display.is_empty():
		job_display = str(adv.job_id)
	var role: String = mods.get("role", "")
	var level: int = int(adv.level)
	var prefix: String = "[編成] " if _selected.has(adv) else "       "
	var line: String = "%s%s Lv%d / %s" % [prefix, adv.display_name, level, job_display]
	if not role.is_empty():
		line += " / %s" % role
	return line

func _on_back_pressed() -> void:
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
