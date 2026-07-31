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
## レア文字ロゴ（N/R/E＝左上）。
const RARITY_BADGE_N: String = ROOT + "ICO_Equip_Rarity_N.png"
const RARITY_BADGE_R: String = ROOT + "ICO_Equip_Rarity_R.png"
const RARITY_BADGE_E: String = ROOT + "ICO_Equip_Rarity_E.png"
## L／ミシック／エンシェントは左下ワードマーク。
const LEGENDARY_BADGE: String = ROOT + "ICO_Equip_LegendaryBadge.png"
const MYTHIC_BADGE: String = ROOT + "ICO_Equip_MythicBadge.png"
const ANCIENT_BADGE: String = ROOT + "ICO_Equip_AncientBadge.png"
## セル幅に対する下段バッジ幅比率（左下寄せ）。
const LEGENDARY_BADGE_WIDTH_RATIO: float = 0.72
const LEGENDARY_BADGE_MARGIN_PX: float = 3.0
## 左上 N/R/E ロゴのセル辺に対する比率（鍛冶屋一覧と同値）。
const CORNER_RARITY_BADGE_RATIO: float = 0.20
const CORNER_RARITY_BADGE_MARGIN_PX: float = 0.0

const STAT_ICONS: Dictionary = {
	"hp": ROOT + "ICO_Equip_Stat_HP.png",
	"attack": ROOT + "ICO_Equip_Stat_ATK.png",
	"defense": ROOT + "ICO_Equip_Stat_DEF.png",
	"speed": ROOT + "ICO_Equip_Stat_SPD.png",
	"crit_rate": ROOT + "ICO_Equip_Stat_CRIT.png",
	"crit_damage": ROOT + "ICO_Equip_Stat_CRITDMG.png",
	## ランダム行（kind キーと 1:1。ステータス内でファイルを被らせない）
	"attack_up": ROOT + "ICO_Equip_Stat_ATKUP.png",
	"defense_up": ROOT + "ICO_Equip_Stat_DEFUP.png",
	"hp_up": ROOT + "ICO_Equip_Stat_HPUP.png",
	"attack_speed": ROOT + "ICO_Equip_Stat_ATKSPD.png",
	"on_hit_status": ROOT + "ICO_Equip_Stat_ONHIT.png",
	"gold_gain": ROOT + "ICO_Equip_Stat_GOLD.png",
	"exp_gain": ROOT + "ICO_Equip_Stat_EXP.png",
	"rare_drop": ROOT + "ICO_Equip_Stat_RAREDROP.png",
	"healing": ROOT + "ICO_Equip_Stat_HEAL.png",
	"evasion": ROOT + "ICO_Equip_Stat_EVADE.png",
	"evasion_rate": ROOT + "ICO_Equip_Stat_EVADE.png",
	"resist_elements": ROOT + "ICO_Equip_Stat_RESIST.png",
	"resist": ROOT + "ICO_Equip_Stat_RESIST.png",
	"status_immunities": ROOT + "ICO_Equip_Stat_IMMUNE.png",
	"chill_chance": ROOT + "ICO_Equip_Stat_CHILL.png",
	"shock_chance": ROOT + "ICO_Equip_Stat_SHOCK.png",
	"ignite_chance": ROOT + "ICO_Equip_Stat_IGNITE.png",
	"poison_chance": ROOT + "ICO_Equip_Stat_POISON.png",
	"bane": ROOT + "ICO_Equip_Stat_BANE.png",
	## 属性値（汎用フォールバック＋属性別）
	"element": ROOT + "ICO_Equip_Stat_ELEMENT.png",
	"element_power": ROOT + "ICO_Equip_Stat_ELEMENT.png",
	"element_power:fire": ROOT + "ICO_Equip_Stat_FIRE.png",
	"element_power:ice": ROOT + "ICO_Equip_Stat_ICE.png",
	"element_power:thunder": ROOT + "ICO_Equip_Stat_THUNDER.png",
	"element_power:dark": ROOT + "ICO_Equip_Stat_DARK.png",
	"element_power:holy": ROOT + "ICO_Equip_Stat_HOLY.png",
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
	"relic": ROOT + "ICO_Equip_Cat_Relic.png",
}

const INV_CELLS: Array[String] = [
	ROOT + "UI_Equip_InvCell_N.png",
	ROOT + "UI_Equip_InvCell_R.png",
	ROOT + "UI_Equip_InvCell_SR.png",
	ROOT + "UI_Equip_InvCell_SSR.png",
	ROOT + "UI_Equip_InvCell_MYTHIC.png",
	ROOT + "UI_Equip_InvCell_SET.png", # SET（エンシェントレア）— 緑枠
]

const CATEGORY_MIN_SIZE: Vector2 = Vector2(64, 76)
## 装備カード左の正面 Idle ドット（台座上・モック構図）。
const PORTRAIT_PX: int = 200
const PORTRAIT_STACK_SIZE: Vector2 = Vector2(200, 268)
const PEDESTAL_HEIGHT_PX: int = 88
## 足元を台座に乗せるための重ね（px）。
const PORTRAIT_PEDESTAL_OVERLAP_PX: int = 40
const STAT_ICON_PX: int = 28
## アセット生成サイズ（`generate_equipment_ui_assets.py`）。
const INV_CELL_DESIGN_PX: int = 144
const SLOT_DESIGN_PX: int = 128
## CardRow が 720 を超えて VBox 左右膨張→左欠けしないよう抑える。
const SLOT_PANEL_MIN_W: int = 192
## フォールバック下限（動的計算が効かない headless 等）。
const SLOT_PX: int = 96
const INV_CELL_PX: int = 112
const INV_GRID_FALLBACK_W: float = 688.0
const INV_CELL_MARGINS: Vector4i = Vector4i(12, 12, 12, 12)
## アイコンを枠・コーナー装飾の内側に収める（防具/レリックのフルブリードアート向け）。
const ICON_FRAME_MARGIN_PX: int = 18
## 弓は透過余白が多く小さく見えるため、inset をこの倍率へ縮小（鍛冶屋と同バランス）。
const BOW_ICON_INSET_SCALE: float = 0.55
## 装備セル枠線色（COMMON/RARE/EPIC/LEGENDARY/MYTHIC/SET）。背景は INV_CELLS の金属質ティント。
const RARITY_BORDER_COLORS: Array[Color] = [
	Color(0.60, 0.60, 0.60),
	Color(0.30, 0.55, 0.95),
	Color(0.70, 0.45, 0.95),
	Color(0.95, 0.75, 0.25),
	Color(0.35, 0.88, 1.0), # MYTHIC — 水色
	Color(0.28, 0.86, 0.42), # SET / エンシェントレア — 緑
]

static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func back_icon() -> Texture2D:
	return load_tex(ICO_BACK)

static func stat_icon(stat_key: String) -> Texture2D:
	if stat_key.is_empty():
		return null
	var path: String = str(STAT_ICONS.get(stat_key, ""))
	if path.is_empty() and stat_key.begins_with("element_power:"):
		path = str(STAT_ICONS.get("element_power", ""))
	return load_tex(path)


## 詳細行用。属性値は element_power:fire 等へ展開し専用アイコンを使う。
static func detail_stat_icon_key(mod: Dictionary) -> String:
	var kind: String = str(mod.get("kind", ""))
	if kind.is_empty():
		return "mod"
	if kind == "element_power":
		var elem: String = str(mod.get("meta", {}).get("element", ""))
		if not elem.is_empty():
			return "element_power:%s" % elem
		return kind
	if kind == "on_hit_status":
		var sid: String = str(mod.get("meta", {}).get("status_id", ""))
		match sid:
			"chill":
				return "chill_chance"
			"shock":
				return "shock_chance"
			"ignite":
				return "ignite_chance"
			"poison":
				return "poison_chance"
			_:
				return kind
	return kind

static func category_icon(category: String) -> Texture2D:
	return load_tex(str(CATEGORY_ICONS.get(category, "")))

static func filter_icon() -> Texture2D:
	return load_tex(FILTER_ICON)

static func legendary_badge() -> Texture2D:
	return load_tex(LEGENDARY_BADGE)

static func mythic_badge() -> Texture2D:
	return load_tex(MYTHIC_BADGE)

static func ancient_badge() -> Texture2D:
	return load_tex(ANCIENT_BADGE)

static func corner_rarity_badge(rarity: int) -> Texture2D:
	match clampi(rarity, 0, 5):
		Enums.Rarity.COMMON:
			return load_tex(RARITY_BADGE_N)
		Enums.Rarity.RARE:
			return load_tex(RARITY_BADGE_R)
		Enums.Rarity.EPIC:
			return load_tex(RARITY_BADGE_E)
		_:
			return null

static func tier_badge(rarity: int) -> Texture2D:
	## 左下ワードマーク。L／ミシック／エンシェント。
	if rarity == Enums.Rarity.LEGENDARY:
		return legendary_badge()
	if rarity == Enums.Rarity.MYTHIC:
		return mythic_badge()
	if rarity == Enums.Rarity.SET:
		return ancient_badge()
	return null

static func legendary_badge_size(cell_size: Vector2, tex: Texture2D = null) -> Vector2:
	var badge_tex: Texture2D = tex if tex != null else legendary_badge()
	if badge_tex == null or cell_size.x <= 0.0:
		return Vector2.ZERO
	var badge_w: float = cell_size.x * LEGENDARY_BADGE_WIDTH_RATIO
	var aspect: float = float(badge_tex.get_height()) / maxf(1.0, float(badge_tex.get_width()))
	return Vector2(badge_w, badge_w * aspect)

static func corner_rarity_badge_size(cell_size: Vector2) -> Vector2:
	if cell_size.x <= 0.0 or cell_size.y <= 0.0:
		return Vector2.ZERO
	var side: float = minf(cell_size.x, cell_size.y) * CORNER_RARITY_BADGE_RATIO
	return Vector2(side, side)

static func scaled_margin(design_px: int, cell_px: int, design_margin: int) -> int:
	if design_px <= 0:
		return design_margin
	return maxi(2, int(round(float(design_margin) * float(cell_px) / float(design_px))))

static func scaled_content_margin(design_px: int, cell_px: int, design_margin: float = 8.0) -> float:
	if design_px <= 0:
		return design_margin
	return maxf(2.0, design_margin * float(cell_px) / float(design_px))

static func icon_inset_px(cell_px: int, design_px: int, frame_margin: int = ICON_FRAME_MARGIN_PX) -> int:
	var margin: int = scaled_margin(design_px, cell_px, frame_margin)
	var content: float = scaled_content_margin(design_px, cell_px)
	return margin + int(ceil(content))

static func is_bow_weapon(item_id: String, category: String) -> bool:
	if category != "weapon" or item_id.is_empty():
		return false
	var data: Resource = DataRegistry.get_weapon_data(item_id)
	if data == null:
		return false
	return str(data.weapon_type) == "bow"

## 通常 inset。弓のみ `BOW_ICON_INSET_SCALE` で大きく見せる（BlacksmithUiHelper と同ポリシー）。
static func icon_inset_for_item(
	cell_px: int,
	design_px: int,
	item_id: String = "",
	category: String = "",
	frame_margin: int = ICON_FRAME_MARGIN_PX
) -> int:
	var inset: int = icon_inset_px(cell_px, design_px, frame_margin)
	if is_bow_weapon(item_id, category):
		inset = maxi(2, int(round(float(inset) * BOW_ICON_INSET_SCALE)))
	return inset

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

## インベントリ／図鑑セルへアイコンを載せる（枠 StyleBox は呼び出し側）。
static func attach_item_cell_layers(
	btn: Button,
	icon: Texture2D,
	cell_px: int,
	design_px: int = INV_CELL_DESIGN_PX,
	item_id: String = "",
	category: String = ""
) -> void:
	if btn == null or icon == null:
		return
	var existing: Node = btn.get_node_or_null("ItemIcon")
	if existing != null:
		existing.queue_free()
	var inset: int = icon_inset_for_item(cell_px, design_px, item_id, category)
	var side: int = maxi(1, cell_px - inset * 2)
	var half: float = float(side) * 0.5
	var tex_rect := TextureRect.new()
	tex_rect.name = "ItemIcon"
	tex_rect.texture = icon
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.anchor_left = 0.5
	tex_rect.anchor_top = 0.5
	tex_rect.anchor_right = 0.5
	tex_rect.anchor_bottom = 0.5
	tex_rect.offset_left = -half
	tex_rect.offset_top = -half
	tex_rect.offset_right = half
	tex_rect.offset_bottom = half
	btn.add_child(tex_rect)

## 所持／スロット枠はセル数ぶん StyleBox を new すると実機で重い・メモリ圧迫の原因になる。
static var _rarity_cell_style_cache: Dictionary = {}


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
	var cache_key: String = "%d_%d_%d" % [clampi(rarity, 0, 99), 1 if highlight else 0, cell_px]
	if _rarity_cell_style_cache.has(cache_key):
		return _rarity_cell_style_cache[cache_key] as StyleBox
	var idx: int = clampi(rarity, 0, INV_CELLS.size() - 1)
	var content_margin: float = scaled_content_margin(INV_CELL_DESIGN_PX, cell_px, 4.0)
	var sb_tex: StyleBoxTexture = texture_stylebox(INV_CELLS[idx], INV_CELL_MARGINS, content_margin)
	var out: StyleBox
	if sb_tex.texture != null:
		sb_tex.modulate_color = Color(1.12, 1.10, 1.05, 1.0) if highlight else Color.WHITE
		out = sb_tex
	else:
		out = _rarity_border_style_fallback(rarity, highlight, cell_px)
	_rarity_cell_style_cache[cache_key] = out
	return out

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
