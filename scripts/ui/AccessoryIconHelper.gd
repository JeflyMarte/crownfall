class_name AccessoryIconHelper
extends RefCounted

## 装飾品の形カテゴリ汎用アイコン（案A）。専用絵が無い／暫定プレースホルダ向け。
const TYPE_RING: String = "ring"
const TYPE_CHARM: String = "charm"
const TYPE_TALISMAN: String = "talisman"
const TYPE_SEAL: String = "seal"

const GENERIC_PATHS: Dictionary = {
	TYPE_RING: "res://assets/ui/equipment/ICO_ACC_Generic_Ring.png",
	TYPE_CHARM: "res://assets/ui/equipment/ICO_ACC_Generic_Charm.png",
	TYPE_TALISMAN: "res://assets/ui/equipment/ICO_ACC_Generic_Talisman.png",
	TYPE_SEAL: "res://assets/ui/equipment/ICO_ACC_Generic_Seal.png",
}

## ID から形を推定。`AccessoryData.accessory_type` があればそちらを優先。
static func infer_type(accessory_id: String, explicit_type: String = "") -> String:
	var t: String = explicit_type.strip_edges().to_lower()
	if GENERIC_PATHS.has(t):
		return t
	var id: String = accessory_id.to_lower()
	if id.is_empty():
		return TYPE_RING
	## より具体的な接尾辞を先に（frost_fang_charm が talisman に吸われないよう charm を fang より前）。
	if _id_has_any(id, ["seal", "sigil"]):
		return TYPE_SEAL
	if _id_has_any(id, ["charm", "brooch", "lantern"]):
		return TYPE_CHARM
	if _id_has_any(id, ["talisman", "amulet", "orb"]):
		return TYPE_TALISMAN
	if _id_has_any(id, ["ring", "signet"]):
		return TYPE_RING
	if _id_has_any(id, ["band"]):
		return TYPE_RING
	return TYPE_RING


static func generic_path(accessory_type: String) -> String:
	return str(GENERIC_PATHS.get(accessory_type, GENERIC_PATHS[TYPE_RING]))


static func path_for_id(accessory_id: String, explicit_type: String = "") -> String:
	return generic_path(infer_type(accessory_id, explicit_type))


static func _id_has_any(id: String, keys: Array) -> bool:
	for key in keys:
		if id.find(str(key)) >= 0:
			return true
	return false
