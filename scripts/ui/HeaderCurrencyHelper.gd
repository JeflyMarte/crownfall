class_name HeaderCurrencyHelper
extends RefCounted

## ホーム TopBar 基準の所持金／魔晶石チップ統一（P3-UX-CURRENCY-CHROME-001）。
## 基準: BaseScene HubView/TopBar の GoldChip / TokenChip。

const GOLD_ICON_PX: float = 20.0
const TOKEN_ICON_PX: float = 18.0
const ROW_SEP: int = 6
const CHIP_MARGIN: float = 8.0


static func chip_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.09, 0.05, 0.85)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.55, 0.45, 0.18, 0.5)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = CHIP_MARGIN
	sb.content_margin_top = 4.0
	sb.content_margin_right = CHIP_MARGIN
	sb.content_margin_bottom = 4.0
	return sb


## HeaderRow / TopBarRow 直下の GoldChip・TokenChip をホーム準拠に揃える。
static func apply_to_row(row: Node) -> void:
	if row == null:
		return
	apply_chips(
		row.get_node_or_null("GoldChip") as Control,
		row.get_node_or_null("TokenChip") as Control
	)


static func apply_chips(gold_chip: Control, token_chip: Control) -> void:
	_style_chip(gold_chip, true)
	_style_chip(token_chip, false)


static func _style_chip(chip: Control, is_gold: bool) -> void:
	if chip == null:
		return
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if chip is PanelContainer:
		(chip as PanelContainer).add_theme_stylebox_override("panel", chip_style())
	chip.tooltip_text = ""
	var row_name: String = "GoldRow" if is_gold else "TokenRow"
	var row: HBoxContainer = chip.get_node_or_null(row_name) as HBoxContainer
	if row != null:
		row.add_theme_constant_override("separation", ROW_SEP)
	var icon_name: String = "GoldIcon" if is_gold else "TokenIcon"
	var icon: TextureRect = null
	if row != null:
		icon = row.get_node_or_null(icon_name) as TextureRect
	if icon != null:
		var px: float = GOLD_ICON_PX if is_gold else TOKEN_ICON_PX
		icon.custom_minimum_size = Vector2(px, px)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var label_name: String = "LabelGold" if is_gold else "LabelToken"
	var label: Label = null
	if row != null:
		label = row.get_node_or_null(label_name) as Label
	if label != null:
		label.clip_text = false
		label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		## ホームと同じ: 本文フォント・SIZE_BODY_SMALL・金文字（魔晶石も同色）。
		UiTypography.apply_body(label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
