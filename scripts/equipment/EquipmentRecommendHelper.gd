class_name EquipmentRecommendHelper
extends RefCounted

## キャラ画面「おすすめ装備」— 未装備かつ装備可能な中から、
## 装備総合力（EquipmentPower）が最も高い武／防／飾をそのキャラへ装備する。

const _EquipmentPower := preload("res://scripts/equipment/EquipmentPower.gd")

const CATEGORIES: PackedStringArray = ["weapon", "armor", "accessory"]


## 戻り: {
##   ok, changed, reason,
##   equipped: {weapon?, armor?, accessory?}  # 実際に付け替えたアイテム
## }
static func apply_for_member(member_index: int) -> Dictionary:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return {"ok": false, "changed": false, "reason": "invalid_member", "equipped": {}}
	return apply_for_adventurer(GameState.party_members[member_index])


## 編成内外を問わず、指定冒険者へおすすめ装備を適用（ペット不可）。
static func apply_for_adventurer(member: Resource) -> Dictionary:
	if member == null:
		return {"ok": false, "changed": false, "reason": "no_member", "equipped": {}}
	if PetSystem.is_pet_member(member):
		return {"ok": false, "changed": false, "reason": "pet", "equipped": {}}
	## ロスター／編成のいずれかに居ること（所持外のダミー不可）。
	if not _is_owned_adventurer(member):
		return {"ok": false, "changed": false, "reason": "not_owned", "equipped": {}}
	var picks: Dictionary = pick_best_unequipped(member)
	var equipped: Dictionary = {}
	var changed: bool = false
	for category in CATEGORIES:
		if not picks.has(category):
			continue
		var item: Resource = picks[category] as Resource
		if item == null:
			continue
		if not _equip_item(member, category, item):
			continue
		equipped[category] = item
		changed = true
	if changed:
		SaveManager.save_game()
	return {
		"ok": true,
		"changed": changed,
		"reason": "" if changed else "already_best",
		"equipped": equipped,
	}


static func _is_owned_adventurer(member: Resource) -> bool:
	if member == null:
		return false
	if GameState.party_members.has(member):
		return true
	if GameState.roster.has(member):
		return true
	## get_roster() 経由の参照一致も許容。
	for raw: Variant in GameState.get_roster():
		if raw == member:
			return true
	return false


## カテゴリごと最良候補（現装備より強い未装備のみ）。装備はしない。
static func pick_best_unequipped(member: Resource) -> Dictionary:
	var out: Dictionary = {}
	if member == null:
		return out
	for category in CATEGORIES:
		var best: Resource = _best_for_category(member, category)
		if best != null:
			out[category] = best
	return out


static func _best_for_category(member: Resource, category: String) -> Resource:
	var current: Resource = _get_equipped(member, category)
	var baseline: float = _item_power(member, category, current)
	## 空スロットは power 0 扱いだと「能力0の装飾」等が空より強くないと判定され装着されない。
	## 未装備時は「何もなし（−1）」より任意の候補を優先する。
	if current == null:
		baseline = -1.0
	var best_item: Resource = null
	var best_score: float = baseline
	for item in _unequipped_candidates(member, category):
		var score: float = _item_power(member, category, item)
		if score > best_score + 0.0001:
			best_score = score
			best_item = item
			continue
		if best_item != null and is_equal_approx(score, best_score):
			if _tiebreak_better(item, best_item, category):
				best_item = item
		elif best_item == null and current == null and score >= 0.0:
			## 同点帯でも空よりは候補を1つ取る（tiebreak 用の起点）。
			best_item = item
			best_score = score
	return best_item


static func _unequipped_candidates(member: Resource, category: String) -> Array:
	var out: Array = []
	var source: Array = []
	match category:
		"weapon":
			source = GameState.inventory
		"armor":
			source = GameState.armor_inventory
		"accessory":
			source = GameState.accessory_inventory
		_:
			return out
	for raw in source:
		if raw == null or not (raw is Resource):
			continue
		var item: Resource = raw as Resource
		if "is_appraised" in item and not bool(item.is_appraised):
			continue
		if GameState.find_item_equipped_owner(item) != null:
			continue
		if category == "weapon" and not JobStatCalculator.can_equip_weapon(member, item):
			continue
		out.append(item)
	return out


## スロット単体の装備総合力（非表示・P3-EQ-POWER-RECOMMEND-001）。
static func _item_power(member: Resource, category: String, item: Resource) -> float:
	return _EquipmentPower.score(item, category, member)


## 同点時: レア → 装備Lv → 炉研ぎ（全カテゴリ共通）。
static func _tiebreak_better(a: Resource, b: Resource, _category: String) -> bool:
	var ra: int = EquipmentEnhancer.item_rarity(a)
	var rb: int = EquipmentEnhancer.item_rarity(b)
	if ra != rb:
		return ra > rb
	var la: int = EquipmentEnhancer.get_equip_level(a)
	var lb: int = EquipmentEnhancer.get_equip_level(b)
	if la != lb:
		return la > lb
	return EquipmentEnhancer.get_enhance_level(a) > EquipmentEnhancer.get_enhance_level(b)


static func _get_equipped(member: Resource, category: String) -> Resource:
	match category:
		"weapon":
			return member.equipped_weapon if "equipped_weapon" in member else null
		"armor":
			return member.equipped_armor if "equipped_armor" in member else null
		"accessory":
			return member.equipped_accessory if "equipped_accessory" in member else null
		_:
			return null


static func _equip_item(member: Resource, category: String, item: Resource) -> bool:
	if item == null:
		return false
	var current: Resource = _get_equipped(member, category)
	if current == item:
		return false
	match category:
		"weapon":
			if not JobStatCalculator.can_equip_weapon(member, item):
				return false
			member.equipped_weapon = item
			return true
		"armor":
			member.equipped_armor = item
			return true
		"accessory":
			member.equipped_accessory = item
			return true
		_:
			return false
