class_name EquipmentUiHelper
extends RefCounted

const RARITY_GEMS: Array[String] = ["◇", "◆", "✦", "★"]
const LEVEL_CAP: int = LevelSystem.MAX_LEVEL

const SORT_LABELS: Dictionary = {
	"rarity": "レアリティ",
	"name": "名前",
}

const EQUIPPED_FILTER_LABELS: Dictionary = {
	"all": "すべて",
	"equipped": "装備中",
	"unequipped": "未装備",
}

const CATEGORY_LABELS: Dictionary = {
	"all": "すべて",
	"weapon": "武器",
	"armor": "防具",
	"accessory": "装飾",
	"relic": "レリック",
}

static func category_label(category: String) -> String:
	return str(CATEGORY_LABELS.get(category, category))

static func rarity_gem(rarity: int) -> String:
	return RARITY_GEMS[clampi(rarity, 0, RARITY_GEMS.size() - 1)]

static func stars_text(rarity: int) -> String:
	return RosterUiHelper.stars_text(clampi(rarity, 1, 5))

static func level_line(level: int, max_level: int = LEVEL_CAP) -> String:
	return "Lv.%d / %d" % [clampi(level, 1, max_level), max_level]

static func rarity_stars_text(rarity: int) -> String:
	var count: int = clampi(rarity + 1, 1, 4)
	var out: String = ""
	for _i in count:
		out += "★"
	return out

static func enhance_badge(item: Resource, category: String) -> String:
	if category != "weapon" or item == null:
		return ""
	var level: int = EquipmentEnhancer.get_enhance_level(item)
	if level <= 0:
		return ""
	return "+%d" % level

static func enhance_badge_font_size(cell_height: float) -> int:
	return maxi(14, int(cell_height * 0.22))

static func apply_enhance_badge(
	parent: Control,
	item: Resource,
	category: String,
	cell_size: Vector2,
	color: Color = Color(0.95, 0.78, 0.28, 1.0)
) -> void:
	var text: String = enhance_badge(item, category)
	if text.is_empty():
		return
	var font_size: int = enhance_badge_font_size(cell_size.y)
	var width: float = float(font_size) * maxf(2.0, float(text.length()) * 0.72)
	add_corner_badge(
		parent,
		text,
		color,
		Vector2(cell_size.x - width - 3.0, cell_size.y - float(font_size) - 4.0),
		font_size
	)

## レジェンド装備アイコンの左下に Legend リボンを重ねる。
static func apply_legendary_badge(parent: Control, rarity: int, cell_size: Vector2) -> void:
	if parent == null or rarity < Enums.Rarity.LEGENDARY:
		return
	var tex: Texture2D = EquipmentUiTokens.legendary_badge()
	if tex == null:
		return
	var badge_size: Vector2 = EquipmentUiTokens.legendary_badge_size(cell_size)
	if badge_size.x <= 0.0 or badge_size.y <= 0.0:
		return
	var margin: float = EquipmentUiTokens.LEGENDARY_BADGE_MARGIN_PX
	var icon := TextureRect.new()
	icon.name = "LegendaryBadge"
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 2
	icon.custom_minimum_size = badge_size
	icon.size = badge_size
	icon.position = Vector2(margin, cell_size.y - badge_size.y - margin)
	parent.add_child(icon)

static func add_corner_badge(
	parent: Control,
	text: String,
	color: Color,
	pos: Vector2,
	font_size: int = 13,
	outline_size: int = 3
) -> void:
	if text.is_empty():
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", outline_size)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = pos
	parent.add_child(lbl)

static func equipped_member_index(item: Resource) -> int:
	if item == null:
		return -1
	return GameState.find_item_equipped_member_index(item)

static func equipped_owner_job_id(item: Resource) -> String:
	var idx: int = equipped_member_index(item)
	if idx < 0:
		return ""
	var member: Resource = GameState.get_member(idx)
	if member == null:
		return ""
	return str(member.job_id)

static func relic_equipped_member_index(relic_id: String) -> int:
	var pid: String = CombatPassives.migrate_relic_passive_id(relic_id)
	if pid.is_empty():
		return -1
	for i in GameState.party_members.size():
		var member: Resource = GameState.party_members[i]
		if member == null:
			continue
		if GameState.get_equipped_relic_passive_id(member) == pid:
			return i
	return -1

static func filter_by_equipped_state(
	entries: Array,
	state: String,
	member_index: int
) -> Array:
	if state == "all":
		return entries
	var out: Array = []
	for entry in entries:
		if entry is not Dictionary:
			continue
		var category: String = str(entry.get("category", ""))
		if category == "relic":
			var relic_id: String = str(entry.get("relic_id", ""))
			var owner: int = relic_equipped_member_index(relic_id)
			var on_self: bool = owner == member_index
			if state == "equipped" and owner >= 0:
				out.append(entry)
			elif state == "unequipped" and owner < 0:
				out.append(entry)
			elif state == "equipped_self" and on_self:
				out.append(entry)
			continue
		var item: Resource = entry.get("item")
		var owner: int = equipped_member_index(item)
		var on_self: bool = owner == member_index
		if state == "equipped" and owner >= 0:
			out.append(entry)
		elif state == "unequipped" and owner < 0:
			out.append(entry)
		elif state == "equipped_self" and on_self:
			out.append(entry)
	return out

static func sort_inventory_entries(entries: Array, sort_by: String = "rarity") -> Array:
	var sorted: Array = entries.duplicate()
	if sort_by == "name":
		sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var cat_a: String = str(a.get("category", ""))
			var cat_b: String = str(b.get("category", ""))
			if cat_a == "relic" or cat_b == "relic":
				return _relic_sort_name(str(a.get("relic_id", ""))) < _relic_sort_name(str(b.get("relic_id", "")))
			return _entry_sort_name(a.get("item"), cat_a) < _entry_sort_name(b.get("item"), cat_b)
		)
		return sorted
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var cat_a: String = str(a.get("category", ""))
		var cat_b: String = str(b.get("category", ""))
		if cat_a == "relic" or cat_b == "relic":
			return _relic_sort_name(str(a.get("relic_id", ""))) < _relic_sort_name(str(b.get("relic_id", "")))
		var item_a: Resource = a.get("item")
		var item_b: Resource = b.get("item")
		var rarity_a: int = _entry_rarity(item_a, cat_a)
		var rarity_b: int = _entry_rarity(item_b, cat_b)
		if rarity_a != rarity_b:
			return rarity_a > rarity_b
		return _entry_sort_name(item_a, cat_a) < _entry_sort_name(item_b, cat_b)
	)
	return sorted

static func _entry_rarity(item: Resource, category: String) -> int:
	if item == null:
		return 0
	match category:
		"weapon":
			var wd: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
			return int(wd.rarity) if wd != null else 0
		"armor":
			var ad: Resource = DataRegistry.get_armor_data(str(item.armor_id))
			return int(ad.rarity) if ad != null else 0
		"accessory":
			var ac: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			return int(ac.rarity) if ac != null else 0
	return 0

static func _entry_sort_name(item: Resource, category: String) -> String:
	if item == null:
		return ""
	match category:
		"weapon":
			return EquipmentEnhancer.get_display_name(item)
		"armor":
			return EquipmentDisplayNames.get_instance_name(item, "armor")
		"accessory":
			return EquipmentDisplayNames.get_instance_name(item, "accessory")
	return ""

static func _relic_sort_name(relic_id: String) -> String:
	return CombatPassives.relic_display_name(relic_id)
