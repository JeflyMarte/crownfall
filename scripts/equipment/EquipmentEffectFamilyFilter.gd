class_name EquipmentEffectFamilyFilter
extends RefCounted

## 装備一覧の効果ファミリー絞り込み（P3-UX-EQ-EFFECT-FAMILY-001 案B）。
## 選択ファミリーは OR。カテゴリ／装備中フィルターとは AND。

const FAMILY_OFFENSE: String = "offense"
const FAMILY_DEFENSE: String = "defense"
const FAMILY_CRIT: String = "crit"
const FAMILY_STATUS: String = "status"
const FAMILY_ECONOMY: String = "economy"
const FAMILY_LEGENDARY: String = "legendary"

const FAMILY_ORDER: Array[String] = [
	FAMILY_OFFENSE,
	FAMILY_DEFENSE,
	FAMILY_CRIT,
	FAMILY_STATUS,
	FAMILY_ECONOMY,
	FAMILY_LEGENDARY,
]

const FAMILY_LABELS: Dictionary = {
	FAMILY_OFFENSE: "火力",
	FAMILY_DEFENSE: "耐久",
	FAMILY_CRIT: "会心",
	FAMILY_STATUS: "状態異常",
	FAMILY_ECONOMY: "稼ぎ",
	FAMILY_LEGENDARY: "固有",
}

## random_mods.kind → ファミリー
const KIND_TO_FAMILY: Dictionary = {
	EquipmentRandomMods.KIND_ATTACK_UP: FAMILY_OFFENSE,
	EquipmentRandomMods.KIND_ATTACK_SPEED: FAMILY_OFFENSE,
	EquipmentRandomMods.KIND_ELEMENT_POWER: FAMILY_OFFENSE,
	EquipmentRandomMods.KIND_BANE: FAMILY_OFFENSE,
	EquipmentRandomMods.KIND_DEFENSE_UP: FAMILY_DEFENSE,
	EquipmentRandomMods.KIND_HP_UP: FAMILY_DEFENSE,
	EquipmentRandomMods.KIND_EVASION: FAMILY_DEFENSE,
	EquipmentRandomMods.KIND_RESIST: FAMILY_DEFENSE,
	EquipmentRandomMods.KIND_HEALING: FAMILY_DEFENSE,
	EquipmentRandomMods.KIND_CRIT_RATE: FAMILY_CRIT,
	EquipmentRandomMods.KIND_CRIT_DAMAGE: FAMILY_CRIT,
	EquipmentRandomMods.KIND_ON_HIT: FAMILY_STATUS,
	EquipmentRandomMods.KIND_CHILL: FAMILY_STATUS,
	EquipmentRandomMods.KIND_SHOCK: FAMILY_STATUS,
	EquipmentRandomMods.KIND_IGNITE: FAMILY_STATUS,
	EquipmentRandomMods.KIND_POISON: FAMILY_STATUS,
	EquipmentRandomMods.KIND_IMMUNITY: FAMILY_STATUS,
	EquipmentRandomMods.KIND_GOLD_GAIN: FAMILY_ECONOMY,
	EquipmentRandomMods.KIND_EXP_GAIN: FAMILY_ECONOMY,
	EquipmentRandomMods.KIND_RARE_DROP: FAMILY_ECONOMY,
}


static func family_label(family_id: String) -> String:
	return str(FAMILY_LABELS.get(family_id, family_id))


static func button_summary(selected: Array) -> String:
	if selected.is_empty():
		return "効果"
	if selected.size() == 1:
		return "効果:%s" % family_label(str(selected[0]))
	return "効果×%d" % selected.size()


static func normalize_selection(selected: Array) -> Array[String]:
	var out: Array[String] = []
	var seen: Dictionary = {}
	for raw in selected:
		var fid: String = str(raw)
		if not FAMILY_LABELS.has(fid) or seen.has(fid):
			continue
		seen[fid] = true
		out.append(fid)
	return out


static func filter_entries(entries: Array, selected_families: Array) -> Array:
	var families: Array[String] = normalize_selection(selected_families)
	if families.is_empty():
		return entries
	var out: Array = []
	for entry in entries:
		if entry is not Dictionary:
			continue
		var item: Resource = entry.get("item") as Resource
		var category: String = str(entry.get("category", ""))
		if item_matches_any_family(item, category, families):
			out.append(entry)
	return out


static func item_matches_any_family(item: Resource, category: String, families: Array) -> bool:
	if item == null or families.is_empty():
		return false
	for raw in families:
		if item_matches_family(item, category, str(raw)):
			return true
	return false


static func item_matches_family(item: Resource, category: String, family_id: String) -> bool:
	if item == null or family_id.is_empty():
		return false
	if family_id == FAMILY_LEGENDARY:
		return not _fixed_passive_id(item, category).is_empty()
	for mod in EquipmentRandomMods.get_mods(item):
		if mod is not Dictionary:
			continue
		var kind: String = str(mod.get("kind", ""))
		if str(KIND_TO_FAMILY.get(kind, "")) == family_id:
			return true
	## マスタ固定（mod 無しの旧品・固有帯）もファミリーに含める。
	return _master_matches_family(item, category, family_id)


static func _fixed_passive_id(item: Resource, category: String) -> String:
	if item == null:
		return ""
	match category:
		"weapon":
			var wd: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
			if wd != null and "fixed_passive_id" in wd:
				return str(wd.fixed_passive_id)
		"armor":
			var ad: Resource = DataRegistry.get_armor_data(str(item.armor_id))
			if ad != null and "fixed_passive_id" in ad:
				return str(ad.fixed_passive_id)
		"accessory":
			var acd: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			if acd != null and "fixed_passive_id" in acd:
				return str(acd.fixed_passive_id)
	return ""


static func _master_matches_family(item: Resource, category: String, family_id: String) -> bool:
	match category:
		"weapon":
			var wd: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
			if wd == null:
				return false
			if family_id == FAMILY_OFFENSE:
				if not str(wd.element).is_empty():
					return true
				if "bane_class" in wd and not str(wd.bane_class).is_empty():
					return true
		"armor":
			var ad: Resource = DataRegistry.get_armor_data(str(item.armor_id))
			if ad == null:
				return false
			if family_id == FAMILY_DEFENSE and "resist_elements" in ad:
				var resists: Variant = ad.resist_elements
				if resists is Array and not (resists as Array).is_empty():
					return true
	return false
