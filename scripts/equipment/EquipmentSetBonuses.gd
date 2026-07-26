class_name EquipmentSetBonuses
extends RefCounted

## 降臨セット装備の加護（P3-DG-EVENT-SET-001）。3部位揃いのみ。パッシブ枠非消費。

const SET_CHRONOS_TOKI: String = "chronos_toki"
const SET_VALGARD_ANTIQUE: String = "valgard_antique"

const WEAPONS_BY_SET: Dictionary = {
	SET_CHRONOS_TOKI: [
		"chronos_toki_sword",
		"chronos_toki_dual",
		"chronos_toki_staff",
		"chronos_toki_bow",
	],
	SET_VALGARD_ANTIQUE: [
		"valgard_antique_blade",
		"valgard_antique_dual",
		"valgard_antique_rod",
		"valgard_antique_arrow",
	],
}

const ARMOR_BY_SET: Dictionary = {
	SET_CHRONOS_TOKI: "chronos_toki_armor",
	SET_VALGARD_ANTIQUE: "valgard_antique_armor",
}

const ACCESSORY_BY_SET: Dictionary = {
	SET_CHRONOS_TOKI: "chronos_toki_orb",
	SET_VALGARD_ANTIQUE: "valgard_antique_amulet",
}

const DUNGEON_SET: Dictionary = {
	"chronos_mausoleum": SET_CHRONOS_TOKI,
	"valgard_boundary": SET_VALGARD_ANTIQUE,
}

const BONUS: Dictionary = {
	SET_CHRONOS_TOKI: {
		"display_name": "クロノスの加護",
		"description": "行動速度 +15%／スキルCD・詠唱 −15%",
		"speed_mult": 1.15,
		"skill_cd_mult": 0.85,
		"skill_cast_mult": 0.85,
	},
	SET_VALGARD_ANTIQUE: {
		"display_name": "ヴァルガードの加護",
		"description": "HP・与ダメ +12%／被ダメ −11%",
		"hp_mult": 1.12,
		"outgoing_mult": 1.12,
		"incoming_mult": 0.89,
	},
}


static func is_set_rarity(rarity: int) -> bool:
	return rarity == Enums.Rarity.SET


static func set_id_for_dungeon(dungeon_id: String) -> String:
	return str(DUNGEON_SET.get(dungeon_id, ""))


static func all_piece_ids(set_id: String) -> Array[String]:
	var out: Array[String] = []
	for wid in WEAPONS_BY_SET.get(set_id, []):
		out.append(str(wid))
	var armor_id: String = str(ARMOR_BY_SET.get(set_id, ""))
	if not armor_id.is_empty():
		out.append(armor_id)
	var acc_id: String = str(ACCESSORY_BY_SET.get(set_id, ""))
	if not acc_id.is_empty():
		out.append(acc_id)
	return out


static func is_set_piece_id(item_id: String) -> bool:
	for set_id in WEAPONS_BY_SET.keys():
		if item_id in WEAPONS_BY_SET[set_id]:
			return true
		if item_id == str(ARMOR_BY_SET.get(set_id, "")):
			return true
		if item_id == str(ACCESSORY_BY_SET.get(set_id, "")):
			return true
	return false


static func set_id_of_weapon(weapon_id: String) -> String:
	for set_id in WEAPONS_BY_SET.keys():
		if weapon_id in WEAPONS_BY_SET[set_id]:
			return str(set_id)
	var data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if data != null and "set_id" in data:
		return str(data.set_id)
	return ""


static func set_id_of_armor(armor_id: String) -> String:
	for set_id in ARMOR_BY_SET.keys():
		if armor_id == str(ARMOR_BY_SET[set_id]):
			return str(set_id)
	var data: Resource = DataRegistry.get_armor_data(armor_id)
	if data != null and "set_id" in data:
		return str(data.set_id)
	return ""


static func set_id_of_accessory(accessory_id: String) -> String:
	for set_id in ACCESSORY_BY_SET.keys():
		if accessory_id == str(ACCESSORY_BY_SET[set_id]):
			return str(set_id)
	var data: Resource = DataRegistry.get_accessory_data(accessory_id)
	if data != null and "set_id" in data:
		return str(data.set_id)
	return ""


## 武器・防具・装飾が同一セットなら set_id。否则 ""。
static func active_set_id_for_member(member: Resource) -> String:
	if member == null:
		return ""
	var w_id: String = ""
	var a_id: String = ""
	var c_id: String = ""
	var w_inst: Resource = member.equipped_weapon if "equipped_weapon" in member else null
	if w_inst != null:
		w_id = set_id_of_weapon(str(w_inst.weapon_id))
	var a_inst: Resource = member.equipped_armor if "equipped_armor" in member else null
	if a_inst != null:
		a_id = set_id_of_armor(str(a_inst.armor_id))
	var c_inst: Resource = member.equipped_accessory if "equipped_accessory" in member else null
	if c_inst != null:
		c_id = set_id_of_accessory(str(c_inst.accessory_id))
	if w_id.is_empty() or a_id.is_empty() or c_id.is_empty():
		return ""
	if w_id == a_id and a_id == c_id:
		return w_id
	return ""


static func active_set_id_for_member_index(member_index: int) -> String:
	var combatants: Array = GameState.get_combatants()
	if member_index < 0 or member_index >= combatants.size():
		return ""
	return active_set_id_for_member(combatants[member_index])


static func bonus_for_member_index(member_index: int) -> Dictionary:
	var sid: String = active_set_id_for_member_index(member_index)
	if sid.is_empty():
		return {}
	return BONUS.get(sid, {}) as Dictionary


static func speed_mult(member_index: int) -> float:
	return float(bonus_for_member_index(member_index).get("speed_mult", 1.0))


static func skill_cd_mult(member_index: int) -> float:
	return float(bonus_for_member_index(member_index).get("skill_cd_mult", 1.0))


static func skill_cast_mult(member_index: int) -> float:
	return float(bonus_for_member_index(member_index).get("skill_cast_mult", 1.0))


static func hp_mult(member_index: int) -> float:
	return float(bonus_for_member_index(member_index).get("hp_mult", 1.0))


static func outgoing_mult(member_index: int) -> float:
	return float(bonus_for_member_index(member_index).get("outgoing_mult", 1.0))


static func incoming_mult(member_index: int) -> float:
	return float(bonus_for_member_index(member_index).get("incoming_mult", 1.0))


static func display_name(set_id: String) -> String:
	return str(BONUS.get(set_id, {}).get("display_name", ""))


static func description(set_id: String) -> String:
	return str(BONUS.get(set_id, {}).get("description", ""))
