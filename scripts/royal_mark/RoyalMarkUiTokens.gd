class_name RoyalMarkUiTokens
extends RefCounted

## 王痕育成画面の見た目トークン（モック寄せ・青黒＋古金）。ロジックは持たない。

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45, 1.0)
const COLOR_GOLD_LIT: Color = Color(0.98, 0.88, 0.42, 1.0)
const COLOR_GOLD_DIM: Color = Color(0.45, 0.40, 0.30, 1.0)
const COLOR_NAVY: Color = Color(0.06, 0.08, 0.14, 1.0)
const COLOR_NAVY_PANEL: Color = Color(0.05, 0.07, 0.12, 1.0)
const COLOR_BODY: Color = Color(0.94, 0.91, 0.85, 1.0)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62, 1.0)
const COLOR_MUTED: Color = Color(0.42, 0.40, 0.36, 1.0)
const COLOR_SHORTAGE: Color = Color(0.78, 0.42, 0.36, 1.0)

const EMBLEM_DIR: String = "res://assets/ui/royal_mark/emblems/"
const BG_PATH: String = "res://assets/ui/royal_mark/UI_BG_RoyalMark.png"


## Rank 0..5 用紋章パス。欠ける場合は Rank0 へフォールバック。
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
	sb.border_color = COLOR_GOLD
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


static func apply_chrome_button(btn: Button, enabled: bool = true) -> void:
	var normal: StyleBoxFlat = chrome_button_style(enabled)
	btn.add_theme_stylebox_override("normal", normal)
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
