class_name BlacksmithUiHelper
extends RefCounted

const RARITY_GEMS: Array[String] = ["◇", "◆", "✦", "★"]
const RARITY_SHORT: Array[String] = ["N", "R", "SR", "SSR"]

const LIST_CARD_MIN_HEIGHT: int = 84
const CRAFTABLE_CHIP_WIDTH: int = 96
const CRAFTABLE_CHIP_HEIGHT: int = 92

const RARITY_COLORS: Array[Color] = [
	Color(0.60, 0.60, 0.60),
	Color(0.30, 0.55, 0.95),
	Color(0.70, 0.45, 0.95),
	Color(0.95, 0.75, 0.25),
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
			if not str(wd.fixed_skill_id).is_empty():
				var skill: Resource = DataRegistry.get_skill_data(str(wd.fixed_skill_id))
				var skill_name: String = str(skill.display_name) if skill != null else str(wd.fixed_skill_id)
				lines.append("固有スキル %s" % skill_name)
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

static func list_card_style(selected: bool, craftable: bool, rarity: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var rarity_col: Color = rarity_color(rarity)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	if selected:
		sb.bg_color = Color(0.16, 0.13, 0.08, 0.96)
		sb.border_width_left = 4
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.95, 0.78, 0.28, 1.0)
		sb.shadow_color = Color(0.95, 0.78, 0.28, 0.25)
		sb.shadow_size = 3
	elif craftable:
		sb.bg_color = Color(0.10, 0.14, 0.09, 0.94)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.42, 0.82, 0.38, 0.85)
	else:
		sb.bg_color = Color(0.10, 0.09, 0.08, 0.9)
		sb.set_border_width_all(1)
		sb.border_color = rarity_col.lerp(Color(0.28, 0.26, 0.24), 0.55)
	return sb

static func craftable_strip_style(selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(6)
	if selected:
		sb.bg_color = Color(0.18, 0.14, 0.08, 0.98)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.95, 0.82, 0.38, 1.0)
		sb.shadow_color = Color(0.95, 0.78, 0.28, 0.35)
		sb.shadow_size = 4
	else:
		sb.bg_color = Color(0.11, 0.15, 0.10, 0.94)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.48, 0.86, 0.42, 0.9)
	return sb

static func material_chip_style(sufficient: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.06, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.48, 0.78, 0.42, 0.9) if sufficient else Color(0.78, 0.36, 0.32, 0.95)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	return sb

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

static func rarity_color(rarity: int) -> Color:
	return RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]

static func rarity_box(rarity: int, highlight: bool = true) -> StyleBoxFlat:
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
	return CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)

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

static func apply_primary_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", primary_button_normal())
	btn.add_theme_stylebox_override("hover", primary_button_hover())
	btn.add_theme_stylebox_override("pressed", primary_button_hover())
	btn.add_theme_stylebox_override("disabled", primary_button_disabled())
	btn.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.48, 1.0))
	btn.add_theme_font_size_override("font_size", UiTypography.SIZE_BUTTON)

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
	var style := mode_tab_style(active)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_font_size_override("font_size", 16 if active else 15)
	btn.add_theme_color_override(
		"font_color",
		Color(0.98, 0.88, 0.48, 1.0) if active else Color(0.78, 0.74, 0.68, 1.0)
	)

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
