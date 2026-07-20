class_name NavUiTokens
extends RefCounted

## 拠点メニュー（左 / 下ナビ）のサイズ・余白トークン。

const VIEWPORT_WIDTH: float = 720.0

const BOTTOM_NAV_HEIGHT: float = 68.0
const BOTTOM_NAV_ICON_RATIO: float = 0.8
const BOTTOM_NAV_TEXT_RATIO: float = 0.2
const BOTTOM_NAV_SEPARATION: int = 0
const BOTTOM_NAV_ITEM_COUNT: int = 9

const SIDE_MENU_WIDTH: float = 176.0
const SIDE_MENU_HEIGHT: float = 48.0
const SIDE_MENU_ICON: int = 28
const SIDE_MENU_FONT: int = 16
const SIDE_MENU_ROW_GAP: int = 8
const SIDE_MENU_ICON_TEXT_GAP: int = 6

## 下ナビ表示用。短い名称はそのまま。旧称→短縮の互換も残す。
const BOTTOM_NAV_LABELS: Dictionary = {
	"パーティー編成": "パーティ",
	"パーティ編成": "パーティ",
	"キャラ管理": "キャラ",
	"装備一覧": "装備",
}

static func bottom_nav_item_width() -> float:
	return VIEWPORT_WIDTH / float(BOTTOM_NAV_ITEM_COUNT)

static func bottom_nav_icon_size() -> int:
	return maxi(1, int(floor(BOTTOM_NAV_HEIGHT * BOTTOM_NAV_ICON_RATIO)))

static func bottom_nav_font_size() -> int:
	return maxi(10, int(floor(BOTTOM_NAV_HEIGHT * BOTTOM_NAV_TEXT_RATIO)) - 1)

static func bottom_nav_label(full_title: String) -> String:
	return str(BOTTOM_NAV_LABELS.get(full_title, full_title))

static func flat_button_style() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

static func ensure_bottom_nav_cell(btn: Button) -> Dictionary:
	if btn == null:
		return {}
	var cell := btn.get_node_or_null("NavCell") as VBoxContainer
	if cell == null:
		btn.text = ""
		btn.icon = null
		btn.expand_icon = false
		cell = VBoxContainer.new()
		cell.name = "NavCell"
		cell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cell.add_theme_constant_override("separation", 0)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(cell)

		var icon_slot := CenterContainer.new()
		icon_slot.name = "IconSlot"
		icon_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_slot.size_flags_stretch_ratio = 8.0
		icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon_slot)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_slot.add_child(icon)

		var label := Label.new()
		label.name = "Label"
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = 2.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(label)

	var icon_rect := cell.get_node_or_null("IconSlot/Icon") as TextureRect
	var label_node := cell.get_node_or_null("Label") as Label
	if icon_rect != null:
		var icon_px: int = bottom_nav_icon_size()
		icon_rect.custom_minimum_size = Vector2(icon_px, icon_px)
	if label_node != null:
		UiTypography.apply_menu_label(
			label_node,
			bottom_nav_font_size(),
			UiTypography.COLOR_BODY,
			UiTypography.OUTLINE_MENU
		)
	return {"icon": icon_rect, "label": label_node}

static func get_bottom_nav_text(btn: Button) -> String:
	var parts := ensure_bottom_nav_cell(btn)
	var label: Label = parts.get("label") as Label
	return label.text if label != null else btn.text

static func set_bottom_nav_text(btn: Button, text: String) -> void:
	var parts := ensure_bottom_nav_cell(btn)
	var label: Label = parts.get("label") as Label
	if label != null:
		label.text = text
	btn.text = ""

static func set_bottom_nav_icon(btn: Button, category: String, icon_id: String) -> void:
	var parts := ensure_bottom_nav_cell(btn)
	var icon: TextureRect = parts.get("icon") as TextureRect
	if icon == null:
		return
	var tex := IconPaths.get_icon_texture(icon_id, category)
	icon.texture = tex
	icon.visible = tex != null

static func set_bottom_nav_text_color(btn: Button, color: Color) -> void:
	btn.add_theme_color_override("font_color", color)
	var parts := ensure_bottom_nav_cell(btn)
	var label: Label = parts.get("label") as Label
	if label != null:
		label.add_theme_color_override("font_color", color)

static func set_bottom_nav_disabled_style(btn: Button, disabled: bool) -> void:
	var parts := ensure_bottom_nav_cell(btn)
	var label: Label = parts.get("label") as Label
	var icon: TextureRect = parts.get("icon") as TextureRect
	var color: Color = UiTypography.COLOR_LOCKED if disabled else UiTypography.COLOR_BODY
	if label != null:
		label.add_theme_color_override("font_color", color)
	if icon != null:
		icon.modulate = Color(0.58, 0.56, 0.52, 1.0) if disabled else Color.WHITE

static func apply_bottom_nav_button(btn: Button) -> void:
	if btn == null:
		return
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(bottom_nav_item_width(), BOTTOM_NAV_HEIGHT)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, flat_button_style())
	ensure_bottom_nav_cell(btn)

static func apply_bottom_nav_row(nav_row: HBoxContainer) -> void:
	if nav_row == null:
		return
	nav_row.add_theme_constant_override("separation", BOTTOM_NAV_SEPARATION)
	for child in nav_row.get_children():
		if child is Button:
			apply_bottom_nav_button(child as Button)

static func make_side_menu_row(entry: Dictionary) -> Control:
	var locked: bool = bool(entry.get("locked", false))
	var full_title: String = str(entry["title"])

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(SIDE_MENU_WIDTH, SIDE_MENU_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))

	var btn := Button.new()
	btn.flat = true
	btn.disabled = locked
	btn.tooltip_text = "準備中" if locked else full_title
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, flat_button_style())
	panel.add_child(btn)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = SIDE_MENU_ROW_GAP
	row.offset_right = -SIDE_MENU_ROW_GAP
	row.add_theme_constant_override("separation", SIDE_MENU_ICON_TEXT_GAP)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)

	var icon_box := _make_side_icon(str(entry.get("icon_category", "")), str(entry.get("icon_id", "")))
	row.add_child(icon_box)

	var label := Label.new()
	label.text = full_title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiTypography.apply_menu_label(
		label,
		SIDE_MENU_FONT,
		UiTypography.COLOR_LOCKED if locked else UiTypography.COLOR_BODY,
		UiTypography.OUTLINE_MENU
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	return panel

static func _make_side_icon(category: String, icon_id: String) -> Control:
	var frame := CenterContainer.new()
	frame.custom_minimum_size = Vector2(SIDE_MENU_ICON, SIDE_MENU_ICON)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if category.is_empty() or icon_id.is_empty():
		return frame
	var tex := IconPaths.get_icon_texture(icon_id, category)
	if tex == null:
		return frame
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(SIDE_MENU_ICON, SIDE_MENU_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(icon)
	return frame
