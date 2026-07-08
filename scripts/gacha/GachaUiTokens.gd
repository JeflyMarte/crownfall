class_name GachaUiTokens
extends RefCounted

## 召喚所 UI chrome（P3-UI-GACHA Phase 1）。ロジックは GachaSystem のまま。

const ROOT: String = "res://assets/ui/gacha_ui/"

const BG: String = ROOT + "UI_BG_Gacha.png"
const ORNAMENT_DIAMOND: String = ROOT + "UI_Ornament_Diamond.png"
const ICO_BACK: String = ROOT + "UI_Ico_Back_Gold.png"
const SECTION_RULE: String = ROOT + "UI_Gacha_SectionRule.png"
const TAB_ACTIVE: String = ROOT + "UI_Gacha_Tab_Active.png"
const TAB_INACTIVE: String = ROOT + "UI_Gacha_Tab_Inactive.png"
const BANNER_FRAME: String = ROOT + "UI_Gacha_Banner_Frame.png"
const PITY_BAR_BG: String = ROOT + "UI_Gacha_PityBar_Bg.png"
const PITY_BAR_FILL: String = ROOT + "UI_Gacha_PityBar_Fill.png"
const BTN_1PULL: String = ROOT + "UI_Gacha_Btn_1Pull.png"
const BTN_10PULL_DISABLED: String = ROOT + "UI_Gacha_Btn_10Pull_Disabled.png"
const RIBBON_SR: String = ROOT + "UI_Gacha_Ribbon_SR.png"
const LINEUP_CELL: String = ROOT + "UI_Gacha_LineupCell.png"
const PANEL_DARK: String = ROOT + "UI_Gacha_Panel_Dark.png"
const BTN_DETAIL: String = ROOT + "UI_Gacha_Btn_Detail.png"
const ICO_TOKEN: String = ROOT + "ICO_Gacha_Token.png"
const REVEAL_FRAME: String = ROOT + "UI_Gacha_Reveal_Frame.png"

const SCREEN_TITLE: String = "英雄召喚"
const TEN_PULL_RIBBON_TEXT: String = "★3以上1体確定"

const TAB_LABELS: Array[String] = ["ピックアップ", "プレミアム", "ノーマル"]
const ACTIVE_TAB_INDEX: int = 2

const TAB_HEIGHT: int = 72
const BANNER_MIN_HEIGHT: int = 280
const PITY_BAR_HEIGHT: int = 28
const LINEUP_CELL_PX: int = 120
const PULL_BTN_HEIGHT: int = 88
const PULL_BTN_MIN_WIDTH: int = 300
const RIBBON_HEIGHT: int = 56

static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func back_icon() -> Texture2D:
	return load_tex(ICO_BACK)

static func token_icon() -> Texture2D:
	return load_tex(ICO_TOKEN)

static func ornament_diamond() -> Texture2D:
	return load_tex(ORNAMENT_DIAMOND)

static func texture_stylebox(path: String, margins: Vector4i = Vector4i(12, 12, 12, 12)) -> StyleBoxTexture:
	var tex: Texture2D = load_tex(path)
	var sb := StyleBoxTexture.new()
	if tex == null:
		return sb
	sb.texture = tex
	sb.texture_margin_left = margins.x
	sb.texture_margin_top = margins.y
	sb.texture_margin_right = margins.z
	sb.texture_margin_bottom = margins.w
	sb.set_content_margin_all(8.0)
	return sb

static func tab_active_style() -> StyleBox:
	return texture_stylebox(TAB_ACTIVE, Vector4i(16, 12, 16, 20))

static func tab_inactive_style() -> StyleBox:
	return texture_stylebox(TAB_INACTIVE, Vector4i(16, 12, 16, 14))

static func banner_frame_style() -> StyleBox:
	return texture_stylebox(BANNER_FRAME, Vector4i(20, 18, 20, 22))

static func panel_dark_style() -> StyleBox:
	return texture_stylebox(PANEL_DARK, Vector4i(16, 14, 16, 14))

static func lineup_cell_style() -> StyleBox:
	return texture_stylebox(LINEUP_CELL, Vector4i(12, 12, 12, 28))

static func pull_1_style() -> StyleBox:
	return texture_stylebox(BTN_1PULL, Vector4i(18, 14, 18, 14))

static func pull_10_disabled_style() -> StyleBox:
	return texture_stylebox(BTN_10PULL_DISABLED, Vector4i(18, 14, 18, 14))

static func detail_button_style() -> StyleBox:
	return texture_stylebox(BTN_DETAIL, Vector4i(12, 10, 12, 10))

static func reveal_frame_style() -> StyleBox:
	return texture_stylebox(REVEAL_FRAME, Vector4i(20, 20, 20, 20))

static func pity_bar_background_style() -> StyleBox:
	return texture_stylebox(PITY_BAR_BG, Vector4i(14, 0, 14, 0))

static func pity_bar_fill_style() -> StyleBox:
	return texture_stylebox(PITY_BAR_FILL, Vector4i(14, 0, 14, 0))

static func apply_tab_button(btn: Button, active: bool, locked: bool = false) -> void:
	var style: StyleBox = tab_active_style() if active else tab_inactive_style()
	if style is StyleBoxTexture and (style as StyleBoxTexture).texture == null:
		style = _fallback_tab_style(active)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", tab_inactive_style())
	btn.disabled = locked
	btn.custom_minimum_size = Vector2(0, TAB_HEIGHT)
	btn.add_theme_font_size_override("font_size", 15 if active else 14)
	btn.add_theme_color_override(
		"font_color",
		Color(0.98, 0.88, 0.48, 1.0) if active else Color(0.72, 0.68, 0.62, 1.0)
	)
	btn.add_theme_color_override("font_disabled_color", Color(0.52, 0.50, 0.48, 1.0))
	if locked:
		btn.tooltip_text = "準備中"

static func apply_pull_button(btn: Button, enabled: bool, is_ten_pull: bool = false) -> void:
	var style: StyleBox = pull_1_style() if enabled else pull_10_disabled_style()
	if style is StyleBoxTexture and (style as StyleBoxTexture).texture == null:
		style = _fallback_pull_style(enabled)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", pull_10_disabled_style())
	btn.disabled = not enabled
	btn.custom_minimum_size = Vector2(PULL_BTN_MIN_WIDTH, PULL_BTN_HEIGHT)
	if is_ten_pull and not enabled:
		btn.tooltip_text = "10連召喚は準備中"

static func decorate_title(label: Label) -> void:
	UiTypography.apply_screen_title(label, UiTypography.SIZE_DISPLAY)

static func pity_ratio(current: int, max_pity: int) -> float:
	if max_pity <= 0:
		return 0.0
	return clampf(float(current) / float(max_pity), 0.0, 1.0)

static func pity_caption(current: int, max_pity: int) -> String:
	return "天井まで %d / %d 連（未所持確定）" % [clampi(current, 0, max_pity), maxi(1, max_pity)]

static func _fallback_tab_style(active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.12, 0.28, 0.94) if active else Color(0.08, 0.06, 0.12, 0.82)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(6.0)
	sb.set_border_width_all(2 if active else 1)
	sb.border_color = Color(0.88, 0.72, 0.30, 0.95) if active else Color(0.34, 0.31, 0.27, 0.65)
	return sb

static func _fallback_pull_style(enabled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.18, 0.34, 1.0) if enabled else Color(0.12, 0.11, 0.14, 0.9)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8.0)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.88, 0.72, 0.30, 0.9) if enabled else Color(0.35, 0.33, 0.38, 0.7)
	return sb
