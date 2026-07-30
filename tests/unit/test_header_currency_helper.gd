extends GutTest

## ホーム TopBar 基準の通貨チップ統一（P3-UX-CURRENCY-CHROME-001）。

const _HeaderCurrencyHelper := preload("res://scripts/ui/HeaderCurrencyHelper.gd")


func test_apply_chips_matches_hub_typography_and_icon_sizes() -> void:
	var row := HBoxContainer.new()
	add_child_autofree(row)
	var gold_chip := _make_chip(row, true)
	var token_chip := _make_chip(row, false)
	## 意図的にホームと違う初期値。
	var gold_lbl: Label = gold_chip.get_node("GoldRow/LabelGold")
	var token_lbl: Label = token_chip.get_node("TokenRow/LabelToken")
	gold_lbl.add_theme_font_size_override("font_size", 12)
	token_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	(gold_chip.get_node("GoldRow/GoldIcon") as TextureRect).custom_minimum_size = Vector2(12, 12)
	(token_chip.get_node("TokenRow/TokenIcon") as TextureRect).custom_minimum_size = Vector2(12, 12)
	token_chip.tooltip_text = "魔晶石"

	_HeaderCurrencyHelper.apply_to_row(row)

	assert_eq(int(gold_lbl.get_theme_font_size("font_size")), UiTypography.SIZE_BODY_SMALL)
	assert_eq(int(token_lbl.get_theme_font_size("font_size")), UiTypography.SIZE_BODY_SMALL)
	assert_eq(gold_lbl.get_theme_font("font"), UiTypography.body_font())
	assert_eq(token_lbl.get_theme_font("font"), UiTypography.body_font())
	assert_eq(gold_lbl.get_theme_color("font_color"), UiTypography.COLOR_GOLD)
	assert_eq(token_lbl.get_theme_color("font_color"), UiTypography.COLOR_GOLD)
	assert_eq(
		(gold_chip.get_node("GoldRow/GoldIcon") as TextureRect).custom_minimum_size,
		Vector2(_HeaderCurrencyHelper.GOLD_ICON_PX, _HeaderCurrencyHelper.GOLD_ICON_PX)
	)
	assert_eq(
		(token_chip.get_node("TokenRow/TokenIcon") as TextureRect).custom_minimum_size,
		Vector2(_HeaderCurrencyHelper.TOKEN_ICON_PX, _HeaderCurrencyHelper.TOKEN_ICON_PX)
	)
	assert_eq(token_chip.tooltip_text, "")
	var sb: StyleBox = (gold_chip as PanelContainer).get_theme_stylebox("panel")
	assert_true(sb is StyleBoxFlat)
	assert_almost_eq((sb as StyleBoxFlat).content_margin_left, _HeaderCurrencyHelper.CHIP_MARGIN, 0.01)


func _make_chip(parent: Node, is_gold: bool) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "GoldChip" if is_gold else "TokenChip"
	parent.add_child(chip)
	var row := HBoxContainer.new()
	row.name = "GoldRow" if is_gold else "TokenRow"
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.name = "GoldIcon" if is_gold else "TokenIcon"
	row.add_child(icon)
	var label := Label.new()
	label.name = "LabelGold" if is_gold else "LabelToken"
	label.text = "0"
	row.add_child(label)
	return chip
