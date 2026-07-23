class_name BlacksmithUiHelper
extends RefCounted

const RARITY_GEMS: Array[String] = ["◇", "◆", "✦", "★", "❖"]
const RARITY_SHORT: Array[String] = ["N", "R", "SR", "SSR", "MY"]

## モック寄せ: 行はやや詰め、選択枠は Texture 側で厚く見せる。
const LIST_CARD_MIN_HEIGHT: int = 112
const CRAFTABLE_CHIP_WIDTH: int = 120
## 下段ストリップ内に収める（152 だと帯が上に伸びて左右パネルへ乗る）。
const CRAFTABLE_CHIP_HEIGHT: int = 112
## 左リスト／錬成素材チップ用（行カードに収まる固定サイズ）
const LIST_ICON_PX: int = 72
## 作成可能ストリップ用（装備袋 INV_CELL 以上）
const LIST_CELL_PX: int = 112
## 装備袋と同ポリシー（枠装飾の内側に収める）
const ITEM_ICON_FRAME_MARGIN_PX: int = 18
const ITEM_ICON_MODULATE: Color = Color(1.24, 1.18, 1.10, 1.0)
const ITEM_ICON_UNDERLAY_COLOR: Color = Color(0.04, 0.03, 0.02, 0.58)
## InvCell の texture_margin(12/144)＋余白。これを超える描画は枠左右にはみ出して見える。
const FORGE_ICON_SAFE_FILL: float = 0.52
## 詳細ヒーローは大きく見せるが、枠いっぱいに食い込ませない。
const HERO_ICON_INSET_RATIO: float = 0.03
const HERO_ICON_INSET_MIN_PX: int = 4
const HERO_ICON_SAFE_FILL: float = 0.94
## ヒーローは暗下地なし。武器背景（ペデスタル）の上に透過で武器本体。
const HERO_USE_UNDERLAY: bool = false
const HERO_USE_PEDESTAL: bool = true

const RARITY_COLORS: Array[Color] = [
	Color(0.60, 0.60, 0.60),
	Color(0.30, 0.55, 0.95),
	Color(0.70, 0.45, 0.95),
	Color(0.95, 0.75, 0.25),
	Color(0.35, 0.88, 1.0),
]

## 暗背景向けの名前色（レアリティ対応・可読性優先）。
const RARITY_NAME_COLORS: Array[Color] = [
	Color(0.92, 0.92, 0.90),
	Color(0.48, 0.74, 1.0),
	Color(0.86, 0.58, 1.0),
	Color(1.0, 0.86, 0.38),
	Color(0.55, 0.95, 1.0),
]

const CATEGORY_LABELS: Dictionary = {
	"weapon": "武器",
	"armor": "防具",
	"accessory": "装飾",
}

static func rarity_gem(rarity: int) -> String:
	return RARITY_GEMS[clampi(rarity, 0, RARITY_GEMS.size() - 1)]

static func rarity_short_label(rarity: int) -> String:
	return RARITY_SHORT[clampi(rarity, 0, RARITY_SHORT.size() - 1)]

static func category_label(category: String) -> String:
	return str(CATEGORY_LABELS.get(category, category))

static func owned_count(output_type: String, output_id: String) -> int:
	var count: int = 0
	match output_type:
		"weapon":
			for item in GameState.inventory:
				if item != null and str(item.weapon_id) == output_id:
					count += 1
		"armor":
			for item in GameState.armor_inventory:
				if item != null and str(item.armor_id) == output_id:
					count += 1
		"accessory":
			for item in GameState.accessory_inventory:
				if item != null and str(item.accessory_id) == output_id:
					count += 1
	return count

static func output_rarity(craft: Resource) -> int:
	if craft == null:
		return 0
	match str(craft.output_type):
		"weapon":
			var wd: Resource = DataRegistry.get_weapon_data(str(craft.output_id))
			return int(wd.rarity) if wd != null else 0
		"armor":
			var ad: Resource = DataRegistry.get_armor_data(str(craft.output_id))
			return int(ad.rarity) if ad != null else 0
		"accessory":
			var ac: Resource = DataRegistry.get_accessory_data(str(craft.output_id))
			return int(ac.rarity) if ac != null else 0
	return 0

static func output_display_name(craft: Resource) -> String:
	if craft == null:
		return ""
	return DataRegistry.get_item_name(str(craft.output_id), str(craft.output_type))

static func preview_lines(craft: Resource) -> PackedStringArray:
	var lines: PackedStringArray = []
	if craft == null:
		return lines
	match str(craft.output_type):
		"weapon":
			var wd: Resource = DataRegistry.get_weapon_data(str(craft.output_id))
			if wd == null:
				return lines
			lines.append("攻撃力 %d" % int(wd.base_attack))
			lines.append("会心率 %.0f%%" % (float(wd.base_critical_rate) * 100.0))
			if not str(wd.weapon_type).is_empty():
				lines.append("種別 %s" % str(wd.weapon_type))
			var effect_text: String = EquipmentItemDetailHelper.weapon_legendary_effect_text_from_data(wd)
			if not effect_text.is_empty():
				lines.append("固有効果 %s" % effect_text)
			elif not str(wd.fixed_skill_id).is_empty():
				var skill: Resource = DataRegistry.get_skill_data(str(wd.fixed_skill_id))
				var skill_name: String = str(skill.display_name) if skill != null else str(wd.fixed_skill_id)
				lines.append("武器スキル %s" % skill_name)
		"armor":
			var ad: Resource = DataRegistry.get_armor_data(str(craft.output_id))
			if ad == null:
				return lines
			lines.append("防御力 %d" % int(ad.base_defense))
			lines.append("HP +%d" % int(ad.base_hp_bonus))
			if ad.resist_elements.size() > 0:
				lines.append("耐性 %s" % ", ".join(ad.resist_elements))
		"accessory":
			var ac: Resource = DataRegistry.get_accessory_data(str(craft.output_id))
			if ac == null:
				return lines
			if int(ac.hp_bonus) > 0:
				lines.append("HP +%d" % int(ac.hp_bonus))
			if int(ac.attack_bonus) > 0:
				lines.append("攻撃力 +%d" % int(ac.attack_bonus))
			if float(ac.crit_rate_bonus) > 0.0:
				lines.append("会心率 +%.0f%%" % (float(ac.crit_rate_bonus) * 100.0))
	return lines

static func card_style(selected: bool, craftable: bool = false) -> StyleBox:
	if selected:
		return list_card_style(true, craftable, 0)
	if craftable:
		return list_card_style(false, true, 0)
	return CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)

static func list_card_style(selected: bool, craftable: bool, rarity: int) -> StyleBox:
	var textured: StyleBox = (
		ForgeUiTokens.list_card_selected_style()
		if selected
		else ForgeUiTokens.list_card_normal_style()
	)
	if _texture_style_ok(textured):
		if craftable and not selected and textured is StyleBoxTexture:
			var tinted: StyleBoxTexture = (textured as StyleBoxTexture).duplicate() as StyleBoxTexture
			tinted.modulate_color = Color(0.88, 1.0, 0.84, 1.0)
			return tinted
		return textured
	return simple_list_card_style(selected, craftable, rarity)

static func simple_list_card_style(selected: bool, craftable: bool, rarity: int) -> StyleBox:
	# Texture 欠落時のフォールバック。選択時のみ薄いハイライト。
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 4.0
	sb.content_margin_bottom = 4.0
	sb.set_border_width_all(0)
	if selected:
		sb.bg_color = Color(0.28, 0.24, 0.18, 0.55)
		sb.set_border_width_all(2)
		sb.border_color = rarity_color(rarity).lerp(Color(1.0, 1.0, 1.0), 0.25)
	elif craftable:
		sb.bg_color = Color(0.16, 0.22, 0.14, 0.35)
	else:
		sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	return sb

static func craftable_strip_style(selected: bool) -> StyleBox:
	# チップ枠も最小限（加工フレーム感を出さない）。
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(4)
	sb.set_border_width_all(0)
	if selected:
		sb.bg_color = Color(0.28, 0.24, 0.16, 0.55)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.95, 0.82, 0.38, 0.9)
	else:
		sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	return sb


## 下段「作成可能／素材にする装備」帯の外枠。
static func craftable_panel_style() -> StyleBox:
	var textured: StyleBox = ForgeUiTokens.craftable_band_style()
	if _texture_style_ok(textured):
		return textured
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.05, 0.88)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.86, 0.72, 0.32, 0.92)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(8.0)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_size = 4
	return sb

static func material_chip_style(rarity: int, sufficient: bool, cell_px: int = -1) -> StyleBox:
	var px: int = cell_px if cell_px > 0 else list_cell_px()
	var style: StyleBox = EquipmentUiTokens.rarity_slot_style(rarity, sufficient, px)
	if not sufficient:
		return _material_insufficient_tint(style)
	return style

static func material_chip_style_for_id(material_id: String, sufficient: bool, cell_px: int = -1) -> StyleBox:
	return material_chip_style(EquipmentEnhancer.material_rarity(material_id), sufficient, cell_px)

static func _material_insufficient_tint(style: StyleBox) -> StyleBox:
	if style is StyleBoxTexture:
		var tinted: StyleBoxTexture = (style as StyleBoxTexture).duplicate() as StyleBoxTexture
		tinted.modulate_color = Color(1.0, 0.55, 0.5, 1.0)
		return tinted
	if style is StyleBoxFlat:
		var flat: StyleBoxFlat = (style as StyleBoxFlat).duplicate() as StyleBoxFlat
		flat.border_color = Color(0.78, 0.36, 0.32, 0.95)
		return flat
	return style

static func add_corner_badge(
	parent: Control,
	text: String,
	color: Color,
	pos: Vector2,
	font_size: int = 11
) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = pos
	parent.add_child(lbl)

static func recipes_for_category(category: String) -> Array:
	var out: Array = []
	for craft in DataRegistry.get_all_craft_data():
		if craft == null:
			continue
		if str(craft.output_type) == category:
			out.append(craft)
	out.sort_custom(func(a: Resource, b: Resource) -> bool:
		var a_ok: bool = CraftHelper.can_craft(a)
		var b_ok: bool = CraftHelper.can_craft(b)
		if a_ok != b_ok:
			return a_ok
		return str(a.display_name) < str(b.display_name)
	)
	return out

static func has_craftable_recipes() -> bool:
	return not CraftHelper.get_craftable_recipes().is_empty()


## 強化左一覧の並び用スコア（高いほど上）。
static func enhance_list_stat_score(item: Resource) -> int:
	if item == null:
		return 0
	match EquipmentEnhancer.item_category(item):
		"weapon":
			return EquipmentEnhancer.get_effective_attack(item)
		"armor":
			return (
				EquipmentEnhancer.effective_armor_defense(item) * 10
				+ EquipmentEnhancer.effective_armor_hp(item)
			)
		"accessory":
			var data: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			var score: int = 0
			score += EquipmentEnhancer.effective_accessory_int_bonus(item, "hp_bonus", data)
			score += EquipmentEnhancer.effective_accessory_int_bonus(item, "attack_bonus", data) * 10
			score += EquipmentEnhancer.effective_accessory_int_bonus(item, "defense_bonus", data) * 10
			score += int(
				round(
					EquipmentEnhancer.effective_accessory_float_bonus(item, "critical_rate", data)
					* 1000.0
				)
			)
			return score
		_:
			return 0


## 強化左一覧: 装備中優先 → ステ高い順 → レア → 炉研ぎLv → 名前。
static func enhance_list_sort_before(
	a: Resource,
	b: Resource,
	a_equipped: bool,
	b_equipped: bool
) -> bool:
	if a_equipped != b_equipped:
		return a_equipped
	var a_score: int = enhance_list_stat_score(a)
	var b_score: int = enhance_list_stat_score(b)
	if a_score != b_score:
		return a_score > b_score
	var a_rarity: int = EquipmentEnhancer.item_rarity(a)
	var b_rarity: int = EquipmentEnhancer.item_rarity(b)
	if a_rarity != b_rarity:
		return a_rarity > b_rarity
	var a_lv: int = EquipmentEnhancer.get_enhance_level(a)
	var b_lv: int = EquipmentEnhancer.get_enhance_level(b)
	if a_lv != b_lv:
		return a_lv > b_lv
	return EquipmentEnhancer.get_display_name(a) < EquipmentEnhancer.get_display_name(b)

static func list_cell_px() -> int:
	return LIST_CELL_PX

static func list_icon_px() -> int:
	return LIST_ICON_PX

static func item_icon_inset_px(cell_px: int) -> int:
	return EquipmentUiTokens.icon_inset_px(
		cell_px,
		EquipmentUiTokens.INV_CELL_DESIGN_PX,
		ITEM_ICON_FRAME_MARGIN_PX
	)

static func forge_icon_side_px(cell_px: int, inset: int, safe_fill: float = FORGE_ICON_SAFE_FILL) -> int:
	## inset 由来と、InvCell 9-slice 内側に収まる上限の小さい方。
	var by_inset: int = maxi(1, cell_px - inset * 2)
	var by_safe: int = maxi(1, int(floor(float(cell_px) * safe_fill)))
	return mini(by_inset, by_safe)


static func _item_inset_px(_item_id: String, _category: String, cell_px: int) -> int:
	## 鍛冶は弓の inset 縮小を使わない（枠はみ出し再発防止）。
	return EquipmentUiTokens.icon_inset_px(
		cell_px,
		EquipmentUiTokens.INV_CELL_DESIGN_PX,
		ITEM_ICON_FRAME_MARGIN_PX
	)


static func _attach_icon_full_rect_inset(
	host: Control,
	tex: Texture2D,
	inset: int,
	rarity: int = 0,
	use_inv_cell_bg: bool = false,
	with_underlay: bool = true
) -> void:
	## FULL_RECT＋対称 inset。親サイズ確定後も必ず内側。負の中央offsetは使わない。
	host.clip_contents = true
	if use_inv_cell_bg:
		## 小セルは 9-slice だと枠が潰れるため、InvCell を等倍スケール下地として載せる（装備画面と同アセット）。
		var idx: int = clampi(rarity, 0, EquipmentUiTokens.INV_CELLS.size() - 1)
		var bg_tex: Texture2D = EquipmentUiTokens.load_tex(EquipmentUiTokens.INV_CELLS[idx])
		if bg_tex != null:
			var bg := TextureRect.new()
			bg.name = "ItemBg"
			bg.texture = bg_tex
			bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg.stretch_mode = TextureRect.STRETCH_SCALE
			bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			host.add_child(bg)
		elif with_underlay:
			_attach_flat_icon_underlay(host, inset)
	elif with_underlay:
		_attach_flat_icon_underlay(host, inset)
	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.texture = tex
	icon.modulate = ITEM_ICON_MODULATE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = inset
	icon.offset_top = inset
	icon.offset_right = -inset
	icon.offset_bottom = -inset
	host.add_child(icon)


static func _attach_flat_icon_underlay(host: Control, inset: int) -> void:
	var underlay := Panel.new()
	underlay.name = "ItemIconUnderlay"
	underlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	underlay.offset_left = inset
	underlay.offset_top = inset
	underlay.offset_right = -inset
	underlay.offset_bottom = -inset
	var sb := StyleBoxFlat.new()
	sb.bg_color = ITEM_ICON_UNDERLAY_COLOR
	sb.set_border_width_all(0)
	sb.set_corner_radius_all(4)
	underlay.add_theme_stylebox_override("panel", sb)
	host.add_child(underlay)


static func attach_hero_icon(host: Control, item_id: String, category: String, display_px: int) -> void:
	for child in host.get_children():
		child.queue_free()
	host.custom_minimum_size = Vector2(display_px, display_px)
	host.clip_contents = true
	var tex: Texture2D = IconPaths.get_icon_texture(item_id, category)
	if tex != null and category == "weapon":
		tex = IconPaths.display_texture_for_weapon(item_id, tex)
	if tex == null:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.add_child(glyph)
		return
	var inset: int = maxi(
		HERO_ICON_INSET_MIN_PX,
		int(round(float(display_px) * HERO_ICON_INSET_RATIO))
	)
	## safe_fill からも下限を取る（右はみ出し防止）。
	var side: int = forge_icon_side_px(display_px, inset, HERO_ICON_SAFE_FILL)
	## 偶数余りを inset に寄せ、描画辺が safe_fill を超えないようにする。
	inset = int(ceil((float(display_px) - float(side)) * 0.5))
	_attach_icon_full_rect_inset(host, tex, inset, 0, false, HERO_USE_UNDERLAY)

static func attach_item_icon(
	host: Control,
	item_id: String,
	category: String,
	cell_px: int,
	rarity: int = 0,
	use_inv_cell_bg: bool = false
) -> void:
	for child in host.get_children():
		child.queue_free()
	host.custom_minimum_size = Vector2(cell_px, cell_px)
	host.clip_contents = true
	var tex: Texture2D = IconPaths.get_icon_texture(item_id, category)
	if tex == null:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.add_child(glyph)
		return
	var inset: int = _item_inset_px(item_id, category, cell_px)
	var side: int = forge_icon_side_px(cell_px, inset, FORGE_ICON_SAFE_FILL)
	inset = int(ceil((float(cell_px) - float(side)) * 0.5))
	_attach_icon_full_rect_inset(host, tex, inset, rarity, use_inv_cell_bg)


static func make_item_icon_cell(
	item_id: String,
	category: String,
	rarity: int,
	cell_px: int = -1,
	highlight: bool = false
) -> Control:
	## 装備袋と同型の固定 Button。PanelContainer は使わない。
	var px: int = cell_px if cell_px > 0 else list_cell_px()
	var btn := Button.new()
	btn.name = "ForgeItemIconCell"
	btn.custom_minimum_size = Vector2(px, px)
	btn.size = Vector2(px, px)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.clip_contents = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.disabled = true
	btn.flat = false
	## 72px 前後では InvCell 9-slice の左枠が潰れて「左欠け」に見える。
	## リストサイズは Flat（透明）＋ InvCell 等倍下地。ストリップ大セルは StyleBoxTexture。
	var use_stylebox_cell: bool = px > 88
	var style: StyleBox
	if use_stylebox_cell:
		style = EquipmentUiTokens.rarity_slot_style(rarity, highlight, px)
		if style != null:
			style = style.duplicate()
			style.set_content_margin_all(0.0)
	else:
		style = _list_icon_flat_frame(rarity, highlight, px)
	for state in ["normal", "pressed", "hover", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, style)
	btn.add_theme_constant_override("h_separation", 0)
	btn.add_theme_constant_override("icon_max_width", 0)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0))
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 0))
	btn.text = ""
	attach_item_icon(btn, item_id, category, px, rarity, not use_stylebox_cell)
	EquipmentUiHelper.apply_legendary_badge(btn, rarity, Vector2(px, px))
	return btn


static func _list_icon_flat_frame(rarity: int, highlight: bool, cell_px: int) -> StyleBoxFlat:
	## 下地は ItemBg（InvCell）。StyleBox は選択ハイライト枠のみ。
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	var col: Color = rarity_color(rarity)
	if highlight:
		sb.set_border_width_all(2)
		sb.border_color = col.lerp(Color.WHITE, 0.28)
	else:
		sb.set_border_width_all(0)
		sb.border_color = Color(0, 0, 0, 0)
	sb.set_corner_radius_all(maxi(4, int(round(float(cell_px) * 0.08))))
	sb.set_content_margin_all(0.0)
	## shadow は親カード外へ描画され「左はみ出し」に見えるので付けない。
	return sb


static func make_plain_item_icon(
	item_id: String,
	category: String,
	cell_px: int = -1
) -> Control:
	var px: int = cell_px if cell_px > 0 else list_cell_px()
	var host := Control.new()
	host.name = "ForgePlainItemIcon"
	host.custom_minimum_size = Vector2(px, px)
	host.size = Vector2(px, px)
	host.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.clip_contents = true
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attach_item_icon(host, item_id, category, px)
	return host

static func rarity_color(rarity: int) -> Color:
	return RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]

static func rarity_name_color(rarity: int) -> Color:
	return RARITY_NAME_COLORS[clampi(rarity, 0, RARITY_NAME_COLORS.size() - 1)]

static func detail_panel_style() -> StyleBox:
	var textured: StyleBox = ForgeUiTokens.detail_panel_style()
	if _texture_style_ok(textured):
		return textured
	# Texture 欠落時: 右ペインを金枠 Flat で囲む。
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.06, 0.72)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.86, 0.72, 0.32, 0.92)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10.0)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	sb.shadow_size = 2
	return sb

static func rarity_box(rarity: int, highlight: bool = true) -> StyleBox:
	var textured: StyleBox = ForgeUiTokens.item_cell_style(rarity, highlight)
	if _texture_style_ok(textured):
		return textured
	var sb := StyleBoxFlat.new()
	var col: Color = rarity_color(rarity)
	sb.bg_color = Color(0.08, 0.07, 0.05, 0.92) if not highlight else Color(0.14, 0.12, 0.08, 1.0)
	sb.set_border_width_all(3 if highlight else 2)
	sb.border_color = col if not highlight else col.lerp(Color.WHITE, 0.22)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(6.0)
	if highlight:
		sb.shadow_color = Color(col.r, col.g, col.b, 0.45)
		sb.shadow_size = 6
	return sb

static func cost_panel_style() -> StyleBox:
	## 必要コスト帯: やや小さく見せるため左余白で右寄せ気味に。
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(0)
	sb.content_margin_left = 36.0
	sb.content_margin_top = 6.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 4.0
	return sb

static func unique_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.05, 0.9)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.85, 0.72, 0.28, 0.9)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8.0)
	return sb

static func primary_button_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.42, 0.32, 0.08, 1.0)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.85, 0.72, 0.28, 1.0)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10.0)
	return sb

static func primary_button_hover() -> StyleBoxFlat:
	var sb := primary_button_normal()
	sb.bg_color = Color(0.52, 0.40, 0.12, 1.0)
	sb.border_color = Color(0.95, 0.82, 0.38, 1.0)
	return sb

static func primary_button_disabled() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.16, 0.14, 0.9)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.35, 0.32, 0.28, 0.8)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10.0)
	return sb

const PRIMARY_KIND_PRODUCE: String = "produce"
const PRIMARY_KIND_DISMANTLE: String = "dismantle"
const PRIMARY_KIND_ENHANCE: String = "enhance"

static func apply_primary_button(btn: Button, kind: String = PRIMARY_KIND_PRODUCE) -> void:
	var styles: Dictionary = {}
	match kind:
		PRIMARY_KIND_DISMANTLE:
			styles = ForgeUiTokens.dismantle_button_styles()
		PRIMARY_KIND_ENHANCE:
			styles = ForgeUiTokens.enhance_button_styles()
		_:
			styles = ForgeUiTokens.produce_button_styles()
	_apply_image_button_styles(btn, styles, true)


## 一括分解は長いラベルのため、本番ボタンより小さめ・一行固定。
const BULK_DISMANTLE_FONT_SIZE: int = 18

static func apply_bulk_dismantle_button(btn: Button) -> void:
	_apply_image_button_styles(btn, ForgeUiTokens.bulk_dismantle_button_styles(), true)
	btn.add_theme_font_size_override("font_size", BULK_DISMANTLE_FONT_SIZE)
	btn.clip_text = false
	btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	btn.autowrap_mode = TextServer.AUTOWRAP_OFF
	## 一括はラベルが長いので主ボタンより広め。
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.custom_minimum_size = Vector2(300.0, ForgeUiTokens.PRIMARY_BTN_HEIGHT_PX)


static func _apply_image_button_styles(btn: Button, styles: Dictionary, with_overlay_text: bool) -> void:
	var normal: StyleBox = styles.get("normal", null)
	var disabled: StyleBox = styles.get("disabled", null)
	if _texture_style_ok(normal):
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", normal)
		btn.add_theme_stylebox_override("pressed", normal)
	else:
		btn.add_theme_stylebox_override("normal", primary_button_normal())
		btn.add_theme_stylebox_override("hover", primary_button_hover())
		btn.add_theme_stylebox_override("pressed", primary_button_hover())
	if _texture_style_ok(disabled):
		btn.add_theme_stylebox_override("disabled", disabled)
	else:
		btn.add_theme_stylebox_override("disabled", primary_button_disabled())
	if with_overlay_text:
		btn.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72, 1.0))
		btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.48, 1.0))
		btn.add_theme_font_size_override("font_size", 26)
	else:
		btn.text = ""
		btn.add_theme_font_size_override("font_size", 1)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0))
		btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0))
	## 横幅を抑えて中央寄せ（EXPAND_FILL だと枠いっぱいに伸びる）。
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.custom_minimum_size = Vector2(
		ForgeUiTokens.PRIMARY_BTN_WIDTH_PX,
		maxi(btn.custom_minimum_size.y, ForgeUiTokens.PRIMARY_BTN_HEIGHT_PX)
	)

static func mode_tab_style(active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.11, 0.07, 0.94) if active else Color(0.08, 0.07, 0.06, 0.82)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 6.0
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 3 if active else 1
	sb.border_color = Color(0.95, 0.78, 0.28, 1.0) if active else Color(0.38, 0.34, 0.30, 0.7)
	return sb

static func category_tab_style(active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.13, 0.09, 0.94) if active else Color(0.09, 0.08, 0.07, 0.82)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 4.0
	sb.set_border_width_all(3 if active else 1)
	sb.border_color = Color(0.95, 0.82, 0.38, 1.0) if active else Color(0.40, 0.36, 0.30, 0.72)
	if active:
		sb.shadow_color = Color(0.85, 0.65, 0.2, 0.35)
		sb.shadow_size = 3
	return sb

static func notify_dot_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.92, 0.28, 0.22, 1.0)
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(0.0)
	return sb

static func apply_mode_tab(btn: Button, active: bool) -> void:
	var style: StyleBox = mode_tab_style(active)
	var textured: StyleBox = (
		ForgeUiTokens.tab_active_style() if active else ForgeUiTokens.tab_inactive_style()
	)
	if _texture_style_ok(textured):
		style = textured
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	if btn.custom_minimum_size.y < 52.0:
		btn.custom_minimum_size = Vector2(btn.custom_minimum_size.x, 52.0)
	btn.add_theme_font_size_override("font_size", 18 if active else 16)
	var tab_font: Font = UiTypography.display_font()
	if tab_font != null:
		btn.add_theme_font_override("font", tab_font)
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	btn.add_theme_color_override(
		"font_color",
		Color(0.98, 0.88, 0.48, 1.0) if active else Color(0.88, 0.84, 0.78, 1.0)
	)

static func output_subtitle(craft: Resource) -> String:
	if craft == null:
		return ""
	match str(craft.output_type):
		"weapon":
			var wd: Resource = DataRegistry.get_weapon_data(str(craft.output_id))
			if wd == null:
				return ""
			return "装備種別: %s" % CodexContentHelper.weapon_type_label(str(wd.weapon_type))
		"armor":
			return "装備種別: 防具"
		"accessory":
			return "装備種別: 装飾品"
	return ""

static func craft_stat_entries(craft: Resource) -> Array:
	var entries: Array = []
	if craft == null:
		return entries
	match str(craft.output_type):
		"weapon":
			var wd: Resource = DataRegistry.get_weapon_data(str(craft.output_id))
			if wd == null:
				return entries
			entries.append({"key": "atk", "label": "攻撃力", "value": str(int(wd.base_attack))})
			if float(wd.base_critical_rate) > 0.0:
				entries.append({
					"label": "クリティカル率",
					"key": "crit",
					"value": "%.0f%%" % (float(wd.base_critical_rate) * 100.0),
				})
			var effect_text: String = EquipmentItemDetailHelper.weapon_legendary_effect_text_from_data(wd)
			if not effect_text.is_empty():
				entries.append({
					"key": "weapon_passive",
					"label": "固有効果",
					"value": effect_text,
				})
		"armor":
			var ad: Resource = DataRegistry.get_armor_data(str(craft.output_id))
			if ad == null:
				return entries
			entries.append({"key": "def", "label": "物理防御", "value": str(int(ad.base_defense))})
			if int(ad.base_hp_bonus) > 0:
				entries.append({"key": "hp", "label": "HP", "value": "+%d" % int(ad.base_hp_bonus)})
		"accessory":
			var ac: Resource = DataRegistry.get_accessory_data(str(craft.output_id))
			if ac == null:
				return entries
			if int(ac.hp_bonus) > 0:
				entries.append({"key": "hp", "label": "HP", "value": "+%d" % int(ac.hp_bonus)})
			if int(ac.attack_bonus) > 0:
				entries.append({"key": "atk", "label": "攻撃力", "value": "+%d" % int(ac.attack_bonus)})
			if float(ac.crit_rate_bonus) > 0.0:
				entries.append({
					"key": "crit",
					"label": "クリティカル率",
					"value": "+%.0f%%" % (float(ac.crit_rate_bonus) * 100.0),
				})
	return entries

static func _texture_has_usable_alpha(tex: Texture2D) -> bool:
	if tex == null:
		return false
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return true
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w <= 0 or h <= 0:
		return false
	var step: int = maxi(1, int(sqrt(float(w * h) / 256.0)))
	var transparent: int = 0
	var samples: int = 0
	for y in range(0, h, step):
		for x in range(0, w, step):
			samples += 1
			if img.get_pixel(x, y).a < 16:
				transparent += 1
	return float(transparent) / float(samples) >= 0.05

static func _texture_style_ok(sb: StyleBox) -> bool:
	if not (sb is StyleBoxTexture):
		return false
	var tex: Texture2D = (sb as StyleBoxTexture).texture
	return tex != null and _texture_has_usable_alpha(tex)

static func apply_category_tab(btn: Button, active: bool) -> void:
	var style := category_tab_style(active)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_font_size_override("font_size", 15 if active else 14)
	btn.add_theme_color_override(
		"font_color",
		Color(0.95, 0.86, 0.52, 1.0) if active else Color(0.72, 0.69, 0.64, 1.0)
	)
