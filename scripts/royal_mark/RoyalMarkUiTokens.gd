class_name RoyalMarkUiTokens
extends RefCounted

## 王痕育成画面の見た目トークン。金色は見出し／王痕重要情報に限定。

const COLOR_GOLD: Color = Color(0.82, 0.70, 0.42, 1.0)
const COLOR_GOLD_LIT: Color = Color(0.96, 0.86, 0.40, 1.0)
const COLOR_GOLD_DIM: Color = Color(0.48, 0.42, 0.32, 1.0)
const COLOR_NAVY_PANEL: Color = Color(0.05, 0.07, 0.12, 1.0)
## 本文は黄と被らないアイボリー寄り白
const COLOR_BODY: Color = Color(0.92, 0.93, 0.95, 1.0)
const COLOR_SUB: Color = Color(0.70, 0.72, 0.76, 1.0)
const COLOR_MUTED: Color = Color(0.52, 0.54, 0.58, 1.0)
const COLOR_SHORTAGE: Color = Color(0.82, 0.40, 0.34, 1.0)
## 数値・強化値（水色）／固有名（柔らかい緑青）
const COLOR_BOOST: Color = Color(0.55, 0.88, 0.95, 1.0)
const COLOR_NAME: Color = Color(0.72, 0.92, 0.78, 1.0)

const EMBLEM_DIR: String = "res://assets/ui/royal_mark/emblems/"
const BG_PATH: String = "res://assets/ui/royal_mark/UI_BG_RoyalMark.png"

const EMBLEM_SIZE_BASE: float = 80.0
const EMBLEM_SIZE_RANK5: float = 96.0
const EMBLEM_HOST_BASE: float = 100.0
const EMBLEM_HOST_RANK5: float = 112.0
const PORTRAIT_SIZE: float = 120.0


static func emblem_path_for_rank(rank: int) -> String:
	var r: int = clampi(rank, 0, 5)
	var path: String = "%sICO_RoyalMark_Rank%d.png" % [EMBLEM_DIR, r]
	if ResourceLoader.exists(path):
		return path
	var fallback: String = "%sICO_RoyalMark_Rank0.png" % EMBLEM_DIR
	if ResourceLoader.exists(fallback):
		return fallback
	return "res://assets/ui/passives/ICO_PASSIVE_RoyalSwordDoctrine.png"


static func info_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_NAVY_PANEL
	sb.border_color = COLOR_GOLD_DIM
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 12.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 10.0
	return sb


static func enhance_card_style(is_ultimate: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.09, 1.0)
	sb.border_color = COLOR_GOLD_LIT if is_ultimate else COLOR_GOLD
	sb.set_border_width_all(2 if is_ultimate else 1)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 10.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 8.0
	return sb


static func material_row_style(shortage: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.04, 0.08, 1.0)
	sb.border_color = COLOR_SHORTAGE if shortage else COLOR_GOLD_DIM
	sb.set_border_width_all(1)
	sb.content_margin_left = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 6.0
	return sb


static func chrome_button_style(enabled: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.14, 1.0) if enabled else Color(0.05, 0.05, 0.08, 1.0)
	sb.border_color = COLOR_GOLD if enabled else COLOR_GOLD_DIM
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 8.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 8.0
	return sb


static func upgrade_button_style(enabled: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.09, 0.06, 1.0) if enabled else Color(0.06, 0.06, 0.07, 1.0)
	sb.border_color = COLOR_GOLD_LIT if enabled else COLOR_GOLD_DIM
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 16.0
	sb.content_margin_top = 12.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 12.0
	return sb


static func status_pill_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	sb.border_color = COLOR_GOLD_DIM
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 16.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 4.0
	return sb


static func path_button_style(selected: bool, enabled: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if selected:
		sb.bg_color = Color(0.14, 0.12, 0.06, 1.0)
		sb.border_color = COLOR_GOLD_LIT
		sb.set_border_width_all(3)
	elif enabled:
		sb.bg_color = Color(0.05, 0.06, 0.09, 1.0)
		sb.border_color = COLOR_GOLD_DIM
		sb.set_border_width_all(1)
	else:
		sb.bg_color = Color(0.04, 0.04, 0.06, 1.0)
		sb.border_color = Color(0.28, 0.26, 0.22, 1.0)
		sb.set_border_width_all(1)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 6.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 6.0
	sb.content_margin_bottom = 8.0
	return sb


static func apply_path_button(btn: Button, selected: bool, enabled: bool = true) -> void:
	btn.disabled = not enabled
	btn.add_theme_stylebox_override("normal", path_button_style(selected, enabled))
	btn.add_theme_stylebox_override("hover", path_button_style(selected, true))
	btn.add_theme_stylebox_override("pressed", path_button_style(true, true))
	btn.add_theme_stylebox_override("disabled", path_button_style(false, false))
	## 選択中は枠を金、文字は本文色（金×金で潰さない）
	var font_col: Color = COLOR_MUTED
	if enabled:
		font_col = COLOR_BODY
	btn.add_theme_color_override("font_color", font_col)
	btn.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	btn.add_theme_font_size_override("font_size", UiTypography.SIZE_CAPTION)


static func max_banner_style() -> StyleBoxFlat:
	## Rank V MAX 用の薄い帯（大きなカードを避ける）。
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.04, 1.0)
	sb.border_color = COLOR_GOLD
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 10.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 4.0
	return sb


static func apply_chrome_button(btn: Button, enabled: bool = true) -> void:
	btn.add_theme_stylebox_override("normal", chrome_button_style(enabled))
	btn.add_theme_stylebox_override("hover", chrome_button_style(true))
	btn.add_theme_stylebox_override("pressed", chrome_button_style(true))
	btn.add_theme_stylebox_override("disabled", chrome_button_style(false))
	btn.add_theme_color_override("font_color", COLOR_BODY if enabled else COLOR_MUTED)
	btn.add_theme_color_override("font_disabled_color", COLOR_MUTED)


static func apply_upgrade_button(btn: Button, enabled: bool = true) -> void:
	btn.add_theme_stylebox_override("normal", upgrade_button_style(enabled))
	btn.add_theme_stylebox_override("hover", upgrade_button_style(true))
	btn.add_theme_stylebox_override("pressed", upgrade_button_style(true))
	btn.add_theme_stylebox_override("disabled", upgrade_button_style(false))
	btn.add_theme_color_override("font_color", COLOR_GOLD_LIT if enabled else COLOR_MUTED)
	btn.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	btn.add_theme_font_size_override("font_size", UiTypography.SIZE_BUTTON)


static func format_stat_bonus(mult: float) -> String:
	var pct: int = int(round((mult - 1.0) * 100.0))
	if pct <= 0:
		return "—"
	return "+%d%%" % pct
