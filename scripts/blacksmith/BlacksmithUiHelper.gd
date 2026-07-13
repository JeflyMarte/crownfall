class_name BlacksmithUiHelper
extends RefCounted

const RARITY_GEMS: Array[String] = ["◇", "◆", "✦", "★"]
const RARITY_SHORT: Array[String] = ["N", "R", "SR", "SSR"]

const LIST_CARD_MIN_HEIGHT: int = 120
const CRAFTABLE_CHIP_WIDTH: int = 120
const CRAFTABLE_CHIP_HEIGHT: int = 136

const RARITY_COLORS: Array[Color] = [
	Color(0.60, 0.60, 0.60),
	Color(0.30, 0.55, 0.95),
	Color(0.70, 0.45, 0.95),
	Color(0.95, 0.75, 0.25),
]

## 暗背景向けの名前色（レアリティ対応・可読性優先）。
const RARITY_NAME_COLORS: Array[Color] = [
	Color(0.92, 0.92, 0.90),
	Color(0.48, 0.74, 1.0),
	Color(0.86, 0.58, 1.0),
	Color(1.0, 0.86, 0.38),
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
	return simple_list_card_style(selected, craftable, rarity)

static func simple_list_card_style(selected: bool, craftable: bool, rarity: int) -> StyleBox:
	# 加工フレームなし。選択時のみ薄いハイライト。
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(4)
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

static func list_cell_px() -> int:
	return EquipmentUiTokens.INV_CELL_PX

static func attach_hero_icon(host: Control, item_id: String, category: String, display_px: int) -> void:
	for child in host.get_children():
		child.queue_free()
	host.custom_minimum_size = Vector2(display_px, display_px)
	var tex: Texture2D = IconPaths.get_icon_texture(item_id, category)
	if tex == null:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.add_child(glyph)
		return
	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(icon)

static func attach_item_icon(host: Control, item_id: String, category: String, cell_px: int) -> void:
	for child in host.get_children():
		child.queue_free()
	var tex: Texture2D = IconPaths.get_icon_texture(item_id, category)
	if tex == null:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.add_child(glyph)
		return
	var inset: int = EquipmentUiTokens.icon_inset_px(cell_px, EquipmentUiTokens.INV_CELL_DESIGN_PX)
	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = inset
	icon.offset_top = inset
	icon.offset_right = -inset
	icon.offset_bottom = -inset
	host.add_child(icon)

static func make_item_icon_cell(
	item_id: String,
	category: String,
	rarity: int,
	cell_px: int = -1,
	highlight: bool = false
) -> PanelContainer:
	var px: int = cell_px if cell_px > 0 else list_cell_px()
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(px, px)
	frame.add_theme_stylebox_override(
		"panel", EquipmentUiTokens.rarity_slot_style(rarity, highlight, px)
	)
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	attach_item_icon(host, item_id, category, px)
	EquipmentUiHelper.apply_legendary_badge(host, rarity, Vector2(px, px))
	return frame

static func make_plain_item_icon(
	item_id: String,
	category: String,
	cell_px: int = -1
) -> Control:
	var px: int = cell_px if cell_px > 0 else list_cell_px()
	var host := Control.new()
	host.custom_minimum_size = Vector2(px, px)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attach_item_icon(host, item_id, category, px)
	return host

static func rarity_color(rarity: int) -> Color:
	return RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]

static func rarity_name_color(rarity: int) -> Color:
	return RARITY_NAME_COLORS[clampi(rarity, 0, RARITY_NAME_COLORS.size() - 1)]

static func detail_panel_style() -> StyleBox:
	# CombatUiFrames の暗い塗りつぶし枠を使わず、背景を透かして可読性を確保。
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.16, 0.13, 0.42)
	sb.set_border_width_all(0)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10.0)
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
	return StyleBoxEmpty.new()

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


static func apply_bulk_dismantle_button(btn: Button) -> void:
	_apply_image_button_styles(btn, ForgeUiTokens.bulk_dismantle_button_styles(), true)
	if btn.custom_minimum_size.y < 76.0:
		btn.custom_minimum_size = Vector2(btn.custom_minimum_size.x, 76.0)


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
		btn.add_theme_font_size_override("font_size", 28)
	else:
		btn.text = ""
		btn.add_theme_font_size_override("font_size", 1)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0))
		btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0))
	if btn.custom_minimum_size.y < 76.0:
		btn.custom_minimum_size = Vector2(btn.custom_minimum_size.x, 76.0)

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
	sb.bg_color = Color(0.13, 0.11, 0.08, 0.9) if active else Color(0.09, 0.08, 0.07, 0.78)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 4.0
	sb.set_border_width_all(1)
	sb.border_color = Color(0.88, 0.72, 0.30, 0.95) if active else Color(0.34, 0.31, 0.27, 0.65)
	return sb

static func notify_dot_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.92, 0.28, 0.22, 1.0)
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(0.0)
	return sb

static func apply_mode_tab(btn: Button, active: bool) -> void:
	var style: StyleBox = mode_tab_style(active)
	if active:
		var textured: StyleBox = ForgeUiTokens.tab_active_style()
		if _texture_style_ok(textured):
			style = textured
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_font_size_override("font_size", 17 if active else 16)
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
