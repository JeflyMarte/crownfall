class_name EquipmentRecommendHelper
extends RefCounted

## キャラ画面「おすすめ装備」— 未装備かつ装備可能な中から、
## 総合能力が最も高い武／防／飾をそのキャラへ装備する。

const CATEGORIES: PackedStringArray = ["weapon", "armor", "accessory"]


## 戻り: {
##   ok, changed, reason,
##   equipped: {weapon?, armor?, accessory?}  # 実際に付け替えたアイテム
## }
static func apply_for_member(member_index: int) -> Dictionary:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return {"ok": false, "changed": false, "reason": "invalid_member", "equipped": {}}
	var member: Resource = GameState.party_members[member_index]
	if member == null:
		return {"ok": false, "changed": false, "reason": "no_member", "equipped": {}}
	if PetSystem.is_pet_member(member):
		return {"ok": false, "changed": false, "reason": "pet", "equipped": {}}
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


## スロット単体の能力スコア（メンバーを書き換えない）。
static func _item_power(member: Resource, category: String, item: Resource) -> float:
	if item == null:
		return 0.0
	match category:
		"weapon":
			var atk: float = float(EquipmentEnhancer.get_effective_attack(item))
			## 職適性（preferred 外は候補に入れないが、倍率差は反映）。
			var wdata: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
			var mult: float = JobStatCalculator.get_preferred_weapon_multiplier(member, wdata)
			atk *= mult
			var spd: float = float(item.attack_speed) if "attack_speed" in item else 1.0
			var crt: float = float(item.critical_rate) if "critical_rate" in item else 0.0
			return atk + crt * 100.0 + spd * 10.0
		"armor":
			return (
				float(EquipmentEnhancer.effective_armor_defense(item))
				+ float(EquipmentEnhancer.effective_armor_hp(item))
			)
		"accessory":
			return _accessory_power(item)
		_:
			return 0.0


static func _accessory_power(item: Resource) -> float:
	if item == null:
		return 0.0
	var data: Resource = null
	if "accessory_id" in item and not str(item.accessory_id).is_empty():
		data = DataRegistry.get_accessory_data(str(item.accessory_id))
	var hp: float = 0.0
	var atk: float = 0.0
	var defense: float = 0.0
	var crt: float = 0.0
	if data != null:
		hp = float(EquipmentEnhancer.effective_accessory_int_bonus(item, "hp_bonus", data))
		atk = float(EquipmentEnhancer.effective_accessory_int_bonus(item, "attack_bonus", data))
		defense = float(
			EquipmentEnhancer.effective_accessory_int_bonus(item, "defense_bonus", data)
		)
		crt = float(
			EquipmentEnhancer.effective_accessory_float_bonus(item, "crit_rate_bonus", data)
		)
	const _Mods := preload("res://scripts/equipment/EquipmentRandomMods.gd")
	_Mods.ensure_migrated(item)
	hp += float(_Mods.sum_kind_int(item, _Mods.KIND_HP_UP))
	atk += float(_Mods.sum_kind_int(item, _Mods.KIND_ATTACK_UP))
	defense += float(_Mods.sum_kind_int(item, _Mods.KIND_DEFENSE_UP))
	crt += float(_Mods.sum_kind_float(item, _Mods.KIND_CRIT_RATE))
	## 平ステ0の固有効果飾りでも空スロットより優先できるようレアを微小加点。
	var rarity: float = float(int(item.rarity)) if "rarity" in item else 0.0
	return hp + atk + defense + crt * 100.0 + rarity * 0.01


static func _tiebreak_better(a: Resource, b: Resource, category: String) -> bool:
	var ra: int = 0
	var rb: int = 0
	match category:
		"weapon":
			ra = EquipmentEnhancer.weapon_rarity(a)
			rb = EquipmentEnhancer.weapon_rarity(b)
		"armor":
			ra = EquipmentEnhancer.armor_rarity(a)
			rb = EquipmentEnhancer.armor_rarity(b)
		"accessory":
			ra = int(a.rarity) if a != null and "rarity" in a else 0
			rb = int(b.rarity) if b != null and "rarity" in b else 0
	if ra != rb:
		return ra > rb
	if category == "weapon":
		return EquipmentEnhancer.get_enhance_level(a) > EquipmentEnhancer.get_enhance_level(b)
	return false


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
			EquipmentEnhancer.clamp_equip_level_to_member(item, member)
			member.equipped_weapon = item
			return true
		"armor":
			EquipmentEnhancer.clamp_equip_level_to_member(item, member)
			member.equipped_armor = item
			return true
		"accessory":
			EquipmentEnhancer.clamp_equip_level_to_member(item, member)
			member.equipped_accessory = item
			return true
		_:
			return false
