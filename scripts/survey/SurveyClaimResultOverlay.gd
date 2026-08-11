class_name SurveyClaimResultOverlay
extends CanvasLayer

## 調査室サイクル受取の完了ポップ（鍛冶・分解完了と同型枠＋調査完了ロゴ）。

signal dismissed

const TITLE_PATH: String = "res://assets/ui/survey/UI_Survey_Title_Complete.png"
const GOLD_ICON_PATH: String = "res://assets/ui/batch2/ICO_Gold.png"

var _overlay: Control = null
var _detail_host: VBoxContainer = null
var _title_tex: TextureRect = null
var _title_lbl: Label = null


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present(result: Dictionary) -> void:
	_populate(result)
	visible = true
	AudioManager.play_sfx("ui_confirm")


func _build() -> void:
	_overlay = Control.new()
	_overlay.name = "SurveyClaimResultRoot"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 920)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", ForgeUiTokens.enhance_result_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(outer)
	var title_wrap := Control.new()
	title_wrap.custom_minimum_size = Vector2(0, 100)
	title_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(title_wrap)
	_title_tex = TextureRect.new()
	_title_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_tex.anchor_left = 0.18
	_title_tex.anchor_right = 0.82
	_title_tex.anchor_top = 0.12
	_title_tex.anchor_bottom = 0.88
	_title_tex.offset_left = 0.0
	_title_tex.offset_right = 0.0
	_title_tex.offset_top = 0.0
	_title_tex.offset_bottom = 0.0
	_title_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_title_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(TITLE_PATH):
		_title_tex.texture = load(TITLE_PATH) as Texture2D
	_title_tex.visible = _title_tex.texture != null
	title_wrap.add_child(_title_tex)
	_title_lbl = Label.new()
	_title_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_lbl.text = "調査完了"
	_title_lbl.visible = _title_tex.texture == null
	UiTypography.apply_display(
		_title_lbl, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD
	)
	_title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_title_lbl.add_theme_constant_override("shadow_outline_size", 4)
	title_wrap.add_child(_title_lbl)
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
	UiTypography.apply_menu_button(close_btn)
	close_btn.pressed.connect(_dismiss)
	outer.add_child(close_btn)
	var bottom_pad := Control.new()
	bottom_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_pad.custom_minimum_size = Vector2(0, 36)
	outer.add_child(bottom_pad)
	visible = false


func _populate(result: Dictionary) -> void:
	for child in _detail_host.get_children():
		child.queue_free()
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 56)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 18)
	_detail_host.add_child(pad)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	pad.add_child(col)
	var gained := Label.new()
	gained.text = "獲得成果"
	UiTypography.apply_caption(gained, UiTypography.COLOR_GOLD)
	col.add_child(gained)
	var any: bool = false
	var mat_id: String = str(result.get("material_id", ""))
	var mat_qty: int = int(result.get("material_qty", 0))
	if not mat_id.is_empty() and mat_qty > 0:
		any = true
		col.add_child(_make_material_row(mat_id, mat_qty))
	var gold: int = int(result.get("gold", 0))
	if gold > 0:
		any = true
		col.add_child(_make_currency_row("ゴールド", gold, _load_gold_tex()))
	var tokens: int = int(result.get("token", 0))
	if tokens > 0:
		any = true
		col.add_child(
			_make_currency_row(CurrencyHelper.DISPLAY_NAME, tokens, CurrencyHelper.get_icon_texture())
		)
	var weapon_id: String = str(result.get("weapon_id", ""))
	if not weapon_id.is_empty():
		any = true
		col.add_child(_make_weapon_row(weapon_id))
	var tickets_v: Variant = result.get("tickets", {})
	if tickets_v is Dictionary:
		for tid_v in (tickets_v as Dictionary).keys():
			var tid: String = str(tid_v)
			var tqty: int = int((tickets_v as Dictionary)[tid_v])
			if tid.is_empty() or tqty <= 0:
				continue
			any = true
			col.add_child(_make_ticket_row(tid, tqty))
	var complete_mats: Variant = result.get("complete_materials", {})
	if complete_mats is Dictionary:
		for mid_v in (complete_mats as Dictionary).keys():
			var mid: String = str(mid_v)
			var mqty: int = int((complete_mats as Dictionary)[mid_v])
			if mid.is_empty() or mqty <= 0:
				continue
			any = true
			col.add_child(_make_material_row(mid, mqty))
	var complete_pet: String = str(result.get("complete_pet_id", "")).strip_edges()
	if not complete_pet.is_empty():
		any = true
		col.add_child(_make_pet_row(complete_pet))
	var exp_entries: Array = result.get("exp_entries", []) as Array
	if not exp_entries.is_empty():
		any = true
		col.add_child(_make_exp_section(exp_entries))
	if not any:
		var empty := Label.new()
		empty.text = "（成果なし）"
		UiTypography.apply_caption(empty, UiTypography.COLOR_SUB)
		col.add_child(empty)


func _make_exp_section(entries: Array) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	var header := Label.new()
	header.text = "経験値"
	UiTypography.apply_caption(header, UiTypography.COLOR_GOLD)
	box.add_child(header)
	for entry_v in entries:
		if not (entry_v is Dictionary):
			continue
		box.add_child(_make_exp_row(entry_v as Dictionary))
	return box


func _make_exp_row(entry: Dictionary) -> Control:
	var mid: String = str(entry.get("member_id", ""))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tex: Texture2D = SurveySystem.investigator_portrait_texture(mid)
	row.add_child(_make_plain_icon(tex, 64))
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	var name_lbl := Label.new()
	name_lbl.text = SurveySystem.investigator_display_name(mid)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	text_col.add_child(name_lbl)
	var amount: int = int(entry.get("exp", 0))
	var levels: int = int(entry.get("levels_gained", 0))
	var lv_after: int = int(entry.get("level_after", 0))
	var detail := Label.new()
	if levels > 0:
		detail.text = "+%d EXP  Lv.%d↑" % [amount, lv_after]
	else:
		detail.text = "+%d EXP" % amount
	UiTypography.apply_body(detail, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	text_col.add_child(detail)
	row.add_child(text_col)
	return row


func _make_material_row(mat_id: String, qty: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon_cell: Control = MaterialUiTokens.make_icon_cell(mat_id, 72, true)
	icon_cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_cell)
	row.add_child(_make_name_qty_col(DataRegistry.get_material_name(mat_id), qty))
	return row


func _make_currency_row(display_name: String, qty: int, tex: Texture2D) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_make_plain_icon(tex, 72))
	row.add_child(_make_name_qty_col(display_name, qty))
	return row


func _make_weapon_row(weapon_id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tex: Texture2D = IconPaths.get_icon_texture(weapon_id, "weapon")
	row.add_child(_make_plain_icon(tex, 72))
	var name_lbl_col := VBoxContainer.new()
	name_lbl_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl_col.add_theme_constant_override("separation", 2)
	var name_lbl := Label.new()
	name_lbl.text = DataRegistry.get_weapon_name(weapon_id)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	name_lbl_col.add_child(name_lbl)
	var qty_lbl := Label.new()
	qty_lbl.text = "×1"
	UiTypography.apply_body(qty_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	name_lbl_col.add_child(qty_lbl)
	row.add_child(name_lbl_col)
	return row


func _make_ticket_row(ticket_id: String, qty: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tex: Texture2D = IconPaths.get_icon_texture(ticket_id, "ticket")
	row.add_child(_make_plain_icon(tex, 72))
	var tname: String = TicketSystem.display_name(ticket_id)
	if tname.is_empty():
		var td: Resource = DataRegistry.get_ticket_data(ticket_id)
		tname = str(td.display_name) if td != null else ticket_id
	row.add_child(_make_name_qty_col(tname, qty))
	return row


func _make_pet_row(pet_id: String) -> Control:
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tex: Texture2D = ChrIdlePortrait.get_idle_texture(pet_id)
	if tex == null:
		tex = IconPaths.get_icon_texture(pet_id, "chr")
	row.add_child(_make_plain_icon(tex, 72))
	var pet: Resource = _PetSystem.get_pet_data(pet_id)
	var pname: String = str(pet.display_name) if pet != null else pet_id
	row.add_child(_make_name_qty_col(pname, 1))
	return row


func _make_name_qty_col(display_name: String, qty: int) -> Control:
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	text_col.add_child(name_lbl)
	var qty_lbl := Label.new()
	qty_lbl.text = "×%d" % qty
	UiTypography.apply_body(qty_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	text_col.add_child(qty_lbl)
	return text_col


func _make_plain_icon(tex: Texture2D, cell_px: int) -> Control:
	var host := Control.new()
	host.custom_minimum_size = Vector2(cell_px, cell_px)
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex == null:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.add_child(glyph)
		return host
	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 8.0
	icon.offset_top = 8.0
	icon.offset_right = -8.0
	icon.offset_bottom = -8.0
	host.add_child(icon)
	return host


func _load_gold_tex() -> Texture2D:
	if ResourceLoader.exists(GOLD_ICON_PATH):
		return load(GOLD_ICON_PATH) as Texture2D
	return null


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dismiss()


func _dismiss() -> void:
	visible = false
	AudioManager.play_sfx("ui_cancel")
	dismissed.emit()
	queue_free()
