class_name CrystalExcavateUiTokens
extends RefCounted

## 魔晶石発掘 UI トークン（拠点入口・選択画面フレーム）。

const HUB_ENTRY_ICON: String = "res://assets/ui/excavate/UI_Hub_CrystalExcavate.png"
const SELECT_FRAME: String = "res://assets/ui/excavate/UI_CrystalExcavate_Select_Frame.png"
const RESULT_BANNER: String = "res://assets/ui/excavate/UI_CrystalExcavate_Result_Banner.png"
const RESULT_FRAME: String = "res://assets/ui/excavate/UI_CrystalExcavate_Result_Frame.png"
const RANKING_BANNER: String = "res://assets/ui/excavate/UI_CrystalExcavate_Ranking_Banner.png"

## 拠点：調査室(350)より小さめの円形入口。
const HUB_ICON_PX: float = 168.0
const HUB_STATUS_H: float = 22.0
const HUB_ENTRY_H: float = HUB_ICON_PX + HUB_STATUS_H

const ROW_MIN_H: float = 52.0
const EXCAVATE_BTN_H: float = 64.0

const GOLD: Color = Color(0.78, 0.64, 0.30, 1.0)
const GOLD_BRIGHT: Color = Color(0.92, 0.78, 0.42, 1.0)
const PANEL_FILL: Color = Color(0.06, 0.05, 0.14, 0.92)
const BTN_FILL: Color = Color(0.22, 0.10, 0.42, 0.96)
const BTN_FILL_HOVER: Color = Color(0.30, 0.14, 0.55, 0.98)
const BTN_FILL_PRESSED: Color = Color(0.16, 0.07, 0.32, 0.98)
const PREVIEW_TOKEN: Color = Color(0.72, 0.55, 0.95, 1.0)


static func hub_entry_texture() -> Texture2D:
	if ResourceLoader.exists(HUB_ENTRY_ICON):
		return load(HUB_ENTRY_ICON) as Texture2D
	return null


static func select_frame_texture() -> Texture2D:
	if ResourceLoader.exists(SELECT_FRAME):
		return load(SELECT_FRAME) as Texture2D
	return null


static func result_banner_texture() -> Texture2D:
	if ResourceLoader.exists(RESULT_BANNER):
		return load(RESULT_BANNER) as Texture2D
	return null


static func result_frame_texture() -> Texture2D:
	if ResourceLoader.exists(RESULT_FRAME):
		return load(RESULT_FRAME) as Texture2D
	## 未配置時は旧バナーへフォールバック。
	return result_banner_texture()


static func ranking_banner_texture() -> Texture2D:
	if ResourceLoader.exists(RANKING_BANNER):
		return load(RANKING_BANNER) as Texture2D
	return null


static func gold_row_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_FILL
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


static func excavate_button_style(kind: String) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	match kind:
		"hover":
			sb.bg_color = BTN_FILL_HOVER
			sb.border_color = GOLD_BRIGHT
		"pressed":
			sb.bg_color = BTN_FILL_PRESSED
			sb.border_color = GOLD
		"disabled":
			sb.bg_color = Color(0.12, 0.10, 0.16, 0.85)
			sb.border_color = Color(0.45, 0.40, 0.30, 0.7)
		_:
			sb.bg_color = BTN_FILL
			sb.border_color = GOLD_BRIGHT
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb


static func apply_excavate_button(btn: Button) -> void:
	if btn == null:
		return
	btn.add_theme_stylebox_override("normal", excavate_button_style("normal"))
	btn.add_theme_stylebox_override("hover", excavate_button_style("hover"))
	btn.add_theme_stylebox_override("pressed", excavate_button_style("pressed"))
	btn.add_theme_stylebox_override("disabled", excavate_button_style("disabled"))
	btn.add_theme_color_override("font_color", GOLD_BRIGHT)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.75, 1.0))
	btn.add_theme_color_override("font_pressed_color", GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.40, 0.8))
	UiTypography.apply_menu_button(btn)
