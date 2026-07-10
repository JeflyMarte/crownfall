class_name EquipmentUiTokens
extends RefCounted

const ROOT: String = "res://assets/ui/equipment_ui/"

const BG: String = ROOT + "UI_BG_Equipment.png"
const ORNAMENT_DIAMOND: String = ROOT + "UI_Ornament_Diamond.png"
const ICO_BACK: String = ROOT + "UI_Ico_Back_Gold.png"
const CHAR_CARD: String = ROOT + "UI_Equip_CharCard.png"
const PORTRAIT_PEDESTAL: String = ROOT + "UI_Equip_PortraitPedestal.png"
const TAB_ACTIVE: String = ROOT + "UI_Equip_Tab_Active.png"
const TAB_INACTIVE: String = ROOT + "UI_Equip_Tab_Inactive.png"
const SLOT_FRAME: String = ROOT + "UI_Equip_Slot_Frame.png"
const SLOT_LOCKED: String = ROOT + "UI_Equip_Slot_Locked.png"
const BTN_UNEQUIP: String = ROOT + "UI_Equip_Btn_Unequip.png"
const BTN_STAT_DETAIL: String = ROOT + "UI_Equip_Btn_StatDetail_Disabled.png"
const FILTER_ICON: String = ROOT + "ICO_Equip_Filter.png"
const SECTION_RULE: String = ROOT + "UI_Equip_SectionRule.png"

const STAT_ICONS: Dictionary = {
	"hp": ROOT + "ICO_Equip_Stat_HP.png",
	"attack": ROOT + "ICO_Equip_Stat_ATK.png",
	"defense": ROOT + "ICO_Equip_Stat_DEF.png",
	"speed": ROOT + "ICO_Equip_Stat_SPD.png",
	"crit_rate": ROOT + "ICO_Equip_Stat_CRIT.png",
	"crit_damage": ROOT + "ICO_Equip_Stat_CRITDMG.png",
	"evasion_rate": ROOT + "ICO_Equip_Stat_SPD.png",
	"element": ROOT + "ICO_Equip_Stat_ELEMENT.png",
	"element_power": ROOT + "ICO_Equip_Stat_ELEMENT.png",
	"bane": ROOT + "ICO_Equip_Stat_BANE.png",
	"resist": ROOT + "ICO_Equip_Stat_ELEMENT.png",
}

const EFFECT_STAT_KEYS: Dictionary = {
	"攻撃力": "attack",
	"防御力": "defense",
	"HP": "hp",
	"クリティカル率": "crit_rate",
	"クリティカルダメージ": "crit_damage",
	"攻撃速度": "speed",
}

const CATEGORY_ICONS: Dictionary = {
	"all": ROOT + "ICO_Equip_Cat_All.png",
	"weapon": ROOT + "ICO_Equip_Cat_Weapon.png",
	"armor": ROOT + "ICO_Equip_Cat_Armor.png",
	"accessory": ROOT + "ICO_Equip_Cat_Accessory.png",
	"relic": "res://assets/ui/relics/ICO_REL_WarBanner.png",
}

const INV_CELLS: Array[String] = [
	ROOT + "UI_Equip_InvCell_N.png",
	ROOT + "UI_Equip_InvCell_R.png",
	ROOT + "UI_Equip_InvCell_SR.png",
	ROOT + "UI_Equip_InvCell_SSR.png",
]

const CATEGORY_MIN_SIZE: Vector2 = Vector2(64, 76)
const PORTRAIT_PX: int = 96
const STAT_ICON_PX: int = 28
## アセット生成サイズ（`generate_equipment_ui_assets.py`）。
const INV_CELL_DESIGN_PX: int = 144
const SLOT_DESIGN_PX: int = 128
const SLOT_PANEL_MIN_W: int = 200
## フォールバック下限（動的計算が効かない headless 等）。
const SLOT_PX: int = 96
const INV_CELL_PX: int = 112
const INV_GRID_FALLBACK_W: float = 688.0
const INV_CELL_MARGINS: Vector4i = Vector4i(12, 12, 12, 12)
## 装備セル枠線色（COMMON/RARE/EPIC/LEGENDARY）。背景は INV_CELLS の金属質ティント。
const RARITY_BORDER_COLORS: Array[Color] = [
	Color(0.60, 0.60, 0.60),
	Color(0.30, 0.55, 0.95),
	Color(0.70, 0.45, 0.95),
	Color(0.95, 0.75, 0.25),
]

static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func back_icon() -> Texture2D:
	return load_tex(ICO_BACK)

static func stat_icon(stat_key: String) -> Texture2D:
	return load_tex(str(STAT_ICONS.get(stat_key, "")))

static func category_icon(category: String) -> Texture2D:
	return load_tex(str(CATEGORY_ICONS.get(category, "")))

static func filter_icon() -> Texture2D:
	return load_tex(FILTER_ICON)

static func scaled_margin(design_px: int, cell_px: int, design_margin: int) -> int:
	if design_px <= 0:
		return design_margin
	return maxi(2, int(round(float(design_margin) * float(cell_px) / float(design_px))))

static func scaled_content_margin(design_px: int, cell_px: int, design_margin: float = 8.0) -> float:
	if design_px <= 0:
		return design_margin
	return maxf(2.0, design_margin * float(cell_px) / float(design_px))

static func icon_inset_px(cell_px: int, design_px: int, frame_margin: int = 10) -> int:
	var margin: int = scaled_margin(design_px, cell_px, frame_margin)
	var content: float = scaled_content_margin(design_px, cell_px)
	return margin + int(ceil(content))

static func cell_px_for_grid_width(grid_w: float, columns: int, h_sep: int) -> int:
	if columns <= 0:
		return INV_CELL_PX
	if grid_w < 100.0:
		return INV_CELL_PX
	var cell_w: float = floor((grid_w - float(columns - 1) * h_sep) / float(columns))
	return maxi(INV_CELL_PX, int(cell_w))

static func cell_px_for_slot_panel(panel_w: float, columns: int, h_sep: int) -> int:
	if columns <= 0:
		return SLOT_PX
	var width: float = panel_w if panel_w >= 120.0 else float(SLOT_PANEL_MIN_W)
	var cell_w: float = floor((width - float(columns - 1) * h_sep) / float(columns))
	return maxi(SLOT_PX, int(cell_w))

static func texture_stylebox(
	path: String,
	margins: Vector4i = Vector4i(12, 12, 12, 12),
	content_margin: float = 8.0
) -> StyleBoxTexture:
	var tex: Texture2D = load_tex(path)
	var sb := StyleBoxTexture.new()
	if tex == null:
		return sb
	sb.texture = tex
	sb.texture_margin_left = margins.x
	sb.texture_margin_top = margins.y
	sb.texture_margin_right = margins.z
	sb.texture_margin_bottom = margins.w
	sb.set_content_margin_all(content_margin)
	return sb

static func char_card_style() -> StyleBox:
	var sb: StyleBoxTexture = texture_stylebox(CHAR_CARD, Vector4i(18, 18, 18, 18))
	# 背景画像を透かすため半透明化。
	sb.modulate_color = Color(1, 1, 1, 0.62)
	return sb

static func tab_active_style() -> StyleBox:
	return texture_stylebox(TAB_ACTIVE, Vector4i(14, 10, 14, 16))

static func tab_inactive_style() -> StyleBox:
	return texture_stylebox(TAB_INACTIVE, Vector4i(14, 10, 14, 12))

static func slot_frame_style(cell_px: int = SLOT_DESIGN_PX) -> StyleBox:
	return _rarity_cell_style(0, false, cell_px)

static func unequip_button_style() -> StyleBox:
	return texture_stylebox(BTN_UNEQUIP, Vector4i(16, 12, 16, 12))

static func stat_detail_button_style() -> StyleBox:
	return texture_stylebox(BTN_STAT_DETAIL, Vector4i(14, 10, 14, 10))

static func inv_cell_style(rarity: int, highlight: bool = false, cell_px: int = INV_CELL_DESIGN_PX) -> StyleBox:
	return _rarity_cell_style(rarity, highlight, cell_px)

static func rarity_slot_style(rarity: int, highlight: bool, cell_px: int = INV_CELL_DESIGN_PX) -> StyleBox:
	return _rarity_cell_style(rarity, highlight, cell_px)

static func _rarity_cell_style(rarity: int, highlight: bool, cell_px: int = INV_CELL_DESIGN_PX) -> StyleBox:
	var idx: int = clampi(rarity, 0, INV_CELLS.size() - 1)
	var content_margin: float = scaled_content_margin(INV_CELL_DESIGN_PX, cell_px, 4.0)
	var sb_tex: StyleBoxTexture = texture_stylebox(INV_CELLS[idx], INV_CELL_MARGINS, content_margin)
	if sb_tex.texture != null:
		sb_tex.modulate_color = Color(1.12, 1.10, 1.05, 1.0) if highlight else Color.WHITE
		return sb_tex
	return _rarity_border_style_fallback(rarity, highlight, cell_px)

static func category_tab_style(active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.13, 0.09, 0.94) if active else Color(0.10, 0.08, 0.06, 0.82)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(4.0)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.88, 0.72, 0.30, 0.95) if active else Color(0.34, 0.31, 0.27, 0.65)
	return sb

static func apply_tab_button(btn: Button, active: bool, locked: bool = false) -> void:
	var style: StyleBox = tab_active_style() if active else tab_inactive_style()
	if style is StyleBoxTexture and (style as StyleBoxTexture).texture == null:
		style = category_tab_style(active)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", tab_inactive_style())
	btn.disabled = locked
	var tab_font: Font = UiTypography.display_font()
	if tab_font != null:
		btn.add_theme_font_override("font", tab_font)
	btn.add_theme_font_size_override("font_size", 18 if active else 17)
	btn.add_theme_constant_override("outline_size", 4)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	btn.add_theme_color_override(
		"font_color",
		Color(0.98, 0.88, 0.48, 1.0) if active else Color(0.72, 0.68, 0.62, 1.0)
	)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.48, 1.0))

static func decorate_title(label: Label) -> void:
	var text: String = label.text.strip_edges()
	if text.begins_with("◆"):
		return
	label.text = "◆ %s ◆" % text

static func slot_locked_style(cell_px: int = SLOT_DESIGN_PX) -> StyleBox:
	var sb: StyleBoxFlat = _rarity_border_style_fallback(0, false, cell_px)
	sb.border_color = Color(0.45, 0.42, 0.38, 0.7)
	return sb

static func _rarity_tint_ratio(rarity: int) -> float:
	return 0.08 if rarity >= 3 else 0.12

static func _rarity_bg_color(rarity: int) -> Color:
	var col: Color = RARITY_BORDER_COLORS[clampi(rarity, 0, RARITY_BORDER_COLORS.size() - 1)]
	var base: Color = Color(0.11, 0.086, 0.063, 0.92)
	return base.lerp(col, _rarity_tint_ratio(rarity))

static func _rarity_border_style_fallback(
	rarity: int,
	highlight: bool,
	cell_px: int = INV_CELL_DESIGN_PX
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var col: Color = RARITY_BORDER_COLORS[clampi(rarity, 0, RARITY_BORDER_COLORS.size() - 1)]
	sb.bg_color = _rarity_bg_color(rarity)
	# 枠は細め。装備・遺物スロット共通なので同一の細さに揃う。
	var border_w: int = maxi(1, int(round(2.5 * float(cell_px) / float(INV_CELL_DESIGN_PX))))
	if not highlight:
		border_w = maxi(1, border_w - 1)
	sb.set_border_width_all(border_w)
	sb.border_color = col if not highlight else col.lerp(Color.WHITE, 0.25)
	var radius: int = maxi(6, int(round(8.0 * float(cell_px) / float(INV_CELL_DESIGN_PX))))
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(scaled_content_margin(INV_CELL_DESIGN_PX, cell_px, 4.0))
	return sb

static func tooltip_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.06, 1.0)
	sb.border_color = Color(0.86, 0.74, 0.45, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10.0)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb

static func apply_tooltip_theme(control: Control) -> void:
	var base_theme: Theme = control.theme
	var merged: Theme = base_theme.duplicate(true) if base_theme != null else Theme.new()
	merged.set_stylebox("panel", &"TooltipPanel", tooltip_panel_style())
	merged.set_color("font_color", &"TooltipLabel", Color(0.94, 0.91, 0.83, 1.0))
	merged.set_font_size("font_size", &"TooltipLabel", 16)
	merged.set_constant("outline_size", &"TooltipLabel", 2)
	merged.set_color("font_outline_color", &"TooltipLabel", Color(0, 0, 0, 0.9))
	control.theme = merged
