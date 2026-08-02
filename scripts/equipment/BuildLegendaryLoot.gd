extends RefCounted
## ビルド拡張レジェンド防具・装飾（P3-EQ-LEG-BUILD-001）。
## x-5 初回ボス討伐時、既存Biome固定Lに加え未所持を1点付与。

const ARMOR_IDS: Array[String] = [
	"bloodpact_plate",
	"flurry_light_mail",
	"bulwark_role_plate",
	"cover_aegis_cloak",
	"hexweave_robe",
]

const ACCESSORY_IDS: Array[String] = [
	"blade_dance_ring",
	"pierce_charm",
	"pulse_amulet",
	"beastlord_fang",
	"apothecary_vial",
]


static func all_ids() -> Array[String]:
	var out: Array[String] = []
	out.append_array(ARMOR_IDS)
	out.append_array(ACCESSORY_IDS)
	return out


static func _owns_armor(armor_id: String) -> bool:
	for inst: Variant in GameState.armor_inventory:
		if inst != null and str(inst.armor_id) == armor_id:
			return true
	for m: Resource in GameState.party_members:
		if m == null or m.equipped_armor == null:
			continue
		if str(m.equipped_armor.armor_id) == armor_id:
			return true
	return false


static func _owns_accessory(accessory_id: String) -> bool:
	for inst: Variant in GameState.accessory_inventory:
		if inst != null and str(inst.accessory_id) == accessory_id:
			return true
	for m: Resource in GameState.party_members:
		if m == null or m.equipped_accessory == null:
			continue
		if str(m.equipped_accessory.accessory_id) == accessory_id:
			return true
	return false


static func unowned_candidates() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for aid: String in ARMOR_IDS:
		if not _owns_armor(aid):
			out.append({"category": "armor", "id": aid})
	for cid: String in ACCESSORY_IDS:
		if not _owns_accessory(cid):
			out.append({"category": "accessory", "id": cid})
	return out


## 未所持から1点抽選。無ければ空。
static func roll_one() -> Dictionary:
	var pool: Array[Dictionary] = unowned_candidates()
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]
