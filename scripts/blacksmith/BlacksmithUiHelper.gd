class_name BlacksmithUiHelper
extends RefCounted

const RARITY_GEMS: Array[String] = ["◇", "◆", "✦", "★"]

const CATEGORY_LABELS: Dictionary = {
	"weapon": "武器",
	"armor": "防具",
	"accessory": "装飾",
}

static func rarity_gem(rarity: int) -> String:
	return RARITY_GEMS[clampi(rarity, 0, RARITY_GEMS.size() - 1)]

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
		return CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	if craftable:
		return CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	return CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)

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
