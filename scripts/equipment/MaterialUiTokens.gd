class_name MaterialUiTokens
extends RefCounted

## 素材セル UI — 装備インベントリと同一の rarity 枠（P3-MAT-RARITY-001）。

static func material_rarity(material_id: String) -> int:
	return EquipmentEnhancer.material_rarity(material_id)

static func cell_style(rarity: int, highlight: bool = false, cell_px: int = -1) -> StyleBox:
	var px: int = cell_px if cell_px > 0 else EquipmentUiTokens.INV_CELL_PX
	return EquipmentUiTokens.rarity_slot_style(rarity, highlight, px)

static func chip_style(material_id: String, sufficient: bool, cell_px: int = -1) -> StyleBox:
	return chip_style_for_rarity(material_rarity(material_id), sufficient, cell_px)

static func chip_style_for_rarity(rarity: int, sufficient: bool, cell_px: int = -1) -> StyleBox:
	var style: StyleBox = cell_style(rarity, sufficient, cell_px)
	if not sufficient:
		return _insufficient_tint(style)
	return style

static func make_icon_cell(
	material_id: String,
	cell_px: int = EquipmentUiTokens.INV_CELL_PX,
	sufficient: bool = true
) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(cell_px, cell_px)
	frame.add_theme_stylebox_override("panel", chip_style(material_id, sufficient, cell_px))
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_attach_material_icon(host, material_id, cell_px)
	return frame

static func _attach_material_icon(host: Control, material_id: String, cell_px: int) -> void:
	for child in host.get_children():
		child.queue_free()
	var tex: Texture2D = IconPaths.get_icon_texture(material_id, "material")
	if tex == null:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.add_child(glyph)
		return
	var inset: int = EquipmentUiTokens.icon_inset_px(cell_px, EquipmentUiTokens.INV_CELL_DESIGN_PX)
	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = inset
	icon.offset_top = inset
	icon.offset_right = -inset
	icon.offset_bottom = -inset
	host.add_child(icon)

static func _insufficient_tint(style: StyleBox) -> StyleBox:
	if style is StyleBoxTexture:
		var tinted: StyleBoxTexture = (style as StyleBoxTexture).duplicate() as StyleBoxTexture
		tinted.modulate_color = Color(1.0, 0.55, 0.5, 1.0)
		return tinted
	if style is StyleBoxFlat:
		var flat: StyleBoxFlat = (style as StyleBoxFlat).duplicate() as StyleBoxFlat
		flat.border_color = Color(0.78, 0.36, 0.32, 0.95)
		return flat
	return style
