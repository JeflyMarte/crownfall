class_name AffixRoller
extends RefCounted

## M6 AffixRoller（P2-Task029）。Affix 付与（P2-Task030）。戦闘 stat 未接続。
## equipment_category: "weapon" | "armor" | "accessory"

const CATEGORY_WEAPON: String = "weapon"
const CATEGORY_ARMOR: String = "armor"
const CATEGORY_ACCESSORY: String = "accessory"

const SLOT_PREFIX: String = "prefix"
const SLOT_SUFFIX: String = "suffix"

## MVP 登録済 Affix id プール（resources/affixes/）
const AFFIX_POOL: Array[String] = [
	"sharp",
	"swift",
	"heavy",
	"blessed",
	"fortune",
	"scholarly",
	"treasure_hunter",
	"protection",
	"of_might",
	"shocking",
	"igniting",
	"chilling",
	"septic",
]

## 抽選 Affix のレアリティ tier 重み（合計 100）
const AFFIX_RARITY_WEIGHTS: Dictionary = {
	Enums.Rarity.COMMON: 70,
	Enums.Rarity.RARE: 25,
	Enums.Rarity.EPIC: 4,
	Enums.Rarity.LEGENDARY: 1,
}

static func roll_for_equipment(
	equipment_category: String,
	item_rarity: int = Enums.Rarity.COMMON
) -> Dictionary:
	var roller: RefCounted = load("res://scripts/equipment/AffixRoller.gd").new()
	return roller._roll_for_equipment(equipment_category, item_rarity)

func _roll_for_equipment(equipment_category: String, item_rarity: int) -> Dictionary:
	var result: Dictionary = {
		"equipment_category": equipment_category,
		"item_rarity": item_rarity,
		"prefix_ids": [],
		"suffix_ids": [],
		"prefixes": [],
		"suffixes": [],
	}
	if not _is_valid_category(equipment_category):
		result["error"] = "invalid_category"
		return result
	var max_affix_rarity: int = _roll_affix_rarity_tier(item_rarity)
	var exclude_ids: Array[String] = []
	var prefix: Resource = _roll_slot(equipment_category, SLOT_PREFIX, max_affix_rarity, exclude_ids)
	if prefix != null:
		result["prefix_ids"].append(prefix.id)
		result["prefixes"].append(prefix)
		exclude_ids.append(prefix.id)
	if equipment_category == CATEGORY_WEAPON:
		var suffix: Resource = _roll_slot(equipment_category, SLOT_SUFFIX, max_affix_rarity, exclude_ids)
		if suffix != null:
			result["suffix_ids"].append(suffix.id)
			result["suffixes"].append(suffix)
	return result

func _is_valid_category(equipment_category: String) -> bool:
	return equipment_category in [CATEGORY_WEAPON, CATEGORY_ARMOR, CATEGORY_ACCESSORY]

func _roll_affix_rarity_tier(item_rarity: int) -> int:
	var cap: int = clampi(item_rarity, Enums.Rarity.COMMON, Enums.Rarity.LEGENDARY)
	var roll: int = randi() % 100
	var cumulative: int = 0
	for tier: int in [
		Enums.Rarity.COMMON,
		Enums.Rarity.RARE,
		Enums.Rarity.EPIC,
		Enums.Rarity.LEGENDARY,
	]:
		if tier > cap:
			continue
		cumulative += int(AFFIX_RARITY_WEIGHTS.get(tier, 0))
		if roll < cumulative:
			return tier
	return Enums.Rarity.COMMON

func _roll_slot(
	equipment_category: String,
	slot_category: String,
	max_affix_rarity: int,
	exclude_ids: Array[String]
) -> Resource:
	var candidates: Array[Resource] = _get_candidates(
		equipment_category, slot_category, max_affix_rarity, exclude_ids
	)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]

func _get_candidates(
	equipment_category: String,
	slot_category: String,
	max_affix_rarity: int,
	exclude_ids: Array[String]
) -> Array[Resource]:
	var candidates: Array[Resource] = []
	for affix_id: String in AFFIX_POOL:
		if affix_id in exclude_ids:
			continue
		var data: Resource = DataRegistry.get_affix_data(affix_id)
		if data == null:
			continue
		if data.affix_category != slot_category:
			continue
		if data.rarity > max_affix_rarity:
			continue
		if not _matches_equipment_tag(data, equipment_category):
			continue
		candidates.append(data)
	return candidates

func _matches_equipment_tag(affix_data: Resource, equipment_category: String) -> bool:
	if affix_data.tags.is_empty():
		return true
	return equipment_category in affix_data.tags
