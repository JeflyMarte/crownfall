class_name AbyssLegendaryWeapons
extends RefCounted

## 深層限定レジェンド武器（P3-DG-ABYSS-001-C / P3-DG-ABYSS-LEG-001）。

const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _WeaponInstance := preload("res://scripts/domain/WeaponInstance.gd")

## abyss_dungeon_id → weapon_id
const WEAPON_BY_ABYSS: Dictionary = {
	"abyss_mourngate": "abyss_veinblade",
	"abyss_whisperwood": "abyss_rootfang",
	"abyss_mistfen": "abyss_mirestaff",
	"abyss_blackshore": "abyss_netherbow",
	"abyss_frostridge": "abyss_riftclaw",
}

const WEAPON_IDS: Array[String] = [
	"abyss_veinblade",
	"abyss_rootfang",
	"abyss_mirestaff",
	"abyss_netherbow",
	"abyss_riftclaw",
]


static func is_abyss_legendary_id(weapon_id: String) -> bool:
	return weapon_id in WEAPON_IDS


static func weapon_id_for_abyss(dungeon_id: String) -> String:
	return str(WEAPON_BY_ABYSS.get(dungeon_id, ""))


static func grant_for_abyss(dungeon_id: String) -> Resource:
	var weapon_id: String = weapon_id_for_abyss(dungeon_id)
	if weapon_id.is_empty():
		return null
	return grant_weapon(weapon_id)


static func grant_weapon(weapon_id: String) -> Resource:
	if not is_abyss_legendary_id(weapon_id):
		return null
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		push_warning("AbyssLegendaryWeapons: missing weapon data %s" % weapon_id)
		return null
	var instance: Resource = _WeaponInstance.new()
	instance.instance_id = "abyss_%s_%d_%d" % [weapon_id, Time.get_ticks_msec(), randi() % 100000]
	instance.weapon_id = weapon_id
	_WeaponStatResolver.apply_drop_stats(instance, weapon_data)
	instance.is_appraised = true
	GameState.inventory.append(instance)
	if EventBus.has_signal("weapon_obtained"):
		EventBus.weapon_obtained.emit(weapon_id)
	return instance


static func display_name_for_abyss(dungeon_id: String) -> String:
	var weapon_id: String = weapon_id_for_abyss(dungeon_id)
	if weapon_id.is_empty():
		return ""
	var data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if data == null:
		return weapon_id
	return str(data.display_name)
