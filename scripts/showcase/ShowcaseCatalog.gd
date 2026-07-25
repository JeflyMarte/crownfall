class_name ShowcaseCatalog
extends RefCounted

## スタッフ作例プリセット（読取専用・セーブ非汚染）。P3-SHOWCASE-001。

const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")

## 構図は ShowcaseUiTokens（背景モック座標）を正とする。
const STAGE_IDLE_PX: float = 228.0
const EQUIP_CELL_PX: int = 64
const STAGE_H_PX: float = 460.0
const SIDE_COL_W: float = 168.0

## スタッフ作例。装備 id はカタログ実在分のみ。
## player_name = 展示している隊長名（チップ表示）。display_name = 展示キャラ名。
const STAFF_PRESETS: Array = [
	{
		"id": "staff_aldo_blade",
		"credit": "Crownfall Staff",
		"player_name": "レオ",
		"display_name": "アルド",
		"job_id": "swordsman",
		"level": 42,
		"rarity": 3,
		"weapon_id": "iron_sword",
		"armor_id": "leather_armor",
		"accessory_id": "mourngate_sigil",
		"base_hp": 420,
		"base_attack": 48,
		"base_defense": 36,
	},
	{
		"id": "staff_ranger_mist",
		"credit": "Crownfall Staff",
		"player_name": "アヤ",
		"display_name": "ミスト",
		"job_id": "ranger",
		"level": 38,
		"rarity": 3,
		"weapon_id": "hunting_bow",
		"armor_id": "mire_hide_garb",
		"accessory_id": "marsh_pearl_ring",
		"base_hp": 340,
		"base_attack": 52,
		"base_defense": 22,
	},
	{
		"id": "staff_alchemist_fen",
		"credit": "Crownfall Staff",
		"player_name": "カイト",
		"display_name": "フェン",
		"job_id": "alchemist",
		"level": 40,
		"rarity": 3,
		"weapon_id": "apprentice_staff",
		"armor_id": "moss_weave_garb",
		"accessory_id": "moldgar_eye_talisman",
		"base_hp": 300,
		"base_attack": 44,
		"base_defense": 20,
	},
	{
		"id": "staff_vanguard_gate",
		"credit": "Crownfall Staff",
		"player_name": "リン",
		"display_name": "ガルド",
		"job_id": "vanguard",
		"level": 45,
		"rarity": 3,
		"weapon_id": "rusted_blade",
		"armor_id": "mourngate_plate",
		"accessory_id": "mourngate_royal_seal",
		"base_hp": 520,
		"base_attack": 40,
		"base_defense": 58,
	},
	{
		"id": "staff_tamer_bond",
		"credit": "Crownfall Staff",
		"player_name": "ソラ",
		"display_name": "ミレイ",
		"job_id": "beast_tamer",
		"level": 36,
		"rarity": 3,
		"weapon_id": "tinder_bow",
		"armor_id": "sepia_hide_vest",
		"accessory_id": "leech_oil_charm",
		"base_hp": 360,
		"base_attack": 46,
		"base_defense": 28,
	},
]


static func staff_presets() -> Array:
	return STAFF_PRESETS.duplicate(true)


static func find_staff_preset(preset_id: String) -> Dictionary:
	for raw: Variant in STAFF_PRESETS:
		if raw is Dictionary and str(raw.get("id", "")) == preset_id:
			return (raw as Dictionary).duplicate(true)
	return {}


## スタッフ作例から表示専用 Adventurer を組み立てる（roster に入れない）。
static func build_member_from_preset(preset: Dictionary) -> Resource:
	if preset.is_empty():
		return null
	var adv := Adventurer.new()
	adv.id = "showcase_%s" % str(preset.get("id", "staff"))
	adv.display_name = str(preset.get("display_name", "？？？"))
	adv.job_id = str(preset.get("job_id", "swordsman"))
	adv.level = maxi(1, int(preset.get("level", 1)))
	adv.rarity = clampi(int(preset.get("rarity", 1)), 1, 4)
	var stats := Stats.new()
	stats.hp = maxi(1, int(preset.get("base_hp", 100)))
	stats.attack = maxi(0, int(preset.get("base_attack", 10)))
	stats.defense = maxi(0, int(preset.get("base_defense", 10)))
	adv.base_stats = stats
	adv.equipped_weapon = _make_weapon(str(preset.get("weapon_id", "")), adv.id)
	adv.equipped_armor = _make_armor(str(preset.get("armor_id", "")), adv.id)
	adv.equipped_accessory = _make_accessory(str(preset.get("accessory_id", "")), adv.id)
	return adv


static func _make_weapon(weapon_id: String, owner_tag: String) -> Resource:
	if weapon_id.is_empty():
		return null
	var data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if data == null:
		return null
	var inst := WeaponInstance.new()
	inst.instance_id = "showcase_wpn_%s_%s" % [owner_tag, weapon_id]
	inst.weapon_id = weapon_id
	inst.is_appraised = true
	inst.equip_level = 1
	_WeaponStatResolver.apply_drop_stats(inst, data)
	return inst


static func _make_armor(armor_id: String, owner_tag: String) -> Resource:
	if armor_id.is_empty():
		return null
	var data: Resource = DataRegistry.get_armor_data(armor_id)
	if data == null:
		return null
	var inst := ArmorInstance.new()
	inst.instance_id = "showcase_arm_%s_%s" % [owner_tag, armor_id]
	inst.armor_id = armor_id
	inst.is_appraised = true
	inst.rarity = int(data.rarity) if "rarity" in data else 0
	inst.equip_level = 1
	_ArmorStatResolver.apply_drop_stats(inst, data)
	return inst


static func _make_accessory(accessory_id: String, owner_tag: String) -> Resource:
	if accessory_id.is_empty():
		return null
	var data: Resource = DataRegistry.get_accessory_data(accessory_id)
	if data == null:
		return null
	var inst := AccessoryInstance.new()
	inst.instance_id = "showcase_acc_%s_%s" % [owner_tag, accessory_id]
	inst.accessory_id = accessory_id
	inst.is_appraised = true
	inst.equip_level = 1
	_AccessoryStatResolver.apply_drop_stats(inst, data)
	return inst
