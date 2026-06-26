class_name BuildTagHelper
extends RefCounted

const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")

const TAG_COLORS: Dictionary = {
	"Attack": Color(0.85, 0.35, 0.28),
	"Critical": Color(0.9, 0.75, 0.15),
	"Survival": Color(0.28, 0.72, 0.38),
	"Exploration": Color(0.35, 0.6, 0.9),
	"Basic": Color(0.5, 0.5, 0.55),
}

static func estimate_party_tags() -> PackedStringArray:
	var has_attack: bool = false
	var has_critical: bool = false
	var has_survival: bool = false
	var has_exploration: bool = false
	for member in GameState.party_members:
		if member == null:
			continue
		var items: Array = [member.equipped_weapon, member.equipped_armor, member.equipped_accessory]
		for item in items:
			if item == null or not ("is_appraised" in item) or not item.is_appraised:
				continue
			var all_ids: Array = []
			if "prefix_ids" in item:
				all_ids.append_array(item.prefix_ids)
			if "suffix_ids" in item:
				all_ids.append_array(item.suffix_ids)
			for affix_id in all_ids:
				var affix_data: Resource = DataRegistry.get_affix_data(str(affix_id))
				if affix_data == null:
					continue
				var st: String = affix_data.stat_type.to_lower()
				if "attack" in st:
					has_attack = true
				if "critical" in st:
					has_critical = true
				if "hp" in st or "defense" in st or "healing" in st:
					has_survival = true
	for member in GameState.party_members:
		if member == null:
			continue
		var role: String = str(_JobStatCalculator.get_member_modifiers(member).get("role", "")).to_lower()
		if role == "dps":
			has_attack = true
		elif role == "tank":
			has_survival = true
		elif role == "scout":
			has_exploration = true
	var tags: PackedStringArray = []
	if has_attack:
		tags.append("Attack")
	if has_critical:
		tags.append("Critical")
	if has_survival:
		tags.append("Survival")
	if has_exploration:
		tags.append("Exploration")
	if tags.is_empty():
		tags.append("Basic")
	return tags

static func format_tags_line() -> String:
	return " / ".join(estimate_party_tags())

static func populate_chip_row(row: HBoxContainer) -> void:
	for child: Node in row.get_children():
		child.queue_free()
	for tag: String in estimate_party_tags():
		row.add_child(_make_chip(tag))

static func _make_chip(tag: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 28)
	var style := StyleBoxFlat.new()
	var color: Color = TAG_COLORS.get(tag, TAG_COLORS["Basic"])
	style.bg_color = Color(color.r, color.g, color.b, 0.85)
	style.set_corner_radius_all(6)
	style.set_border_width_all(1)
	style.border_color = Color(0, 0, 0, 0.6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = tag
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	panel.add_child(label)
	return panel
