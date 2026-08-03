class_name ShowcaseCatalog
extends RefCounted

## スタッフ作例プリセット（読取専用・セーブ非汚染）。P3-SHOWCASE-001。
## β到達の理想ビルド（降臨セット／ビルドL・神話・深層なし）。

const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _GachaRarityConfig = preload("res://scripts/gacha/GachaRarityConfig.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")

## 構図は ShowcaseUiTokens（背景モック座標）を正とする。
const STAGE_IDLE_PX: float = 228.0
const EQUIP_CELL_PX: int = 80
const STAGE_H_PX: float = 460.0
const SIDE_COL_W: float = 168.0

## スタッフ作例。装備 id はカタログ実在分のみ。
## character_id = 肖像／個人補正用（adventurer_* / gacha_helper_*）。
## display_name + build_name → 名札「アルド(出血主砲ビルド)」。
## player_name = 内部番号（スタッフ1…）。一覧ソート用。名札には使わない。
const STAFF_PRESETS: Array = [
	{
		"id": "staff_aldo_bleed",
		"credit": "Crownfall Staff",
		"player_name": "スタッフ1",
		"character_id": "adventurer_0",
		"display_name": "アルド",
		"build_name": "出血主砲ビルド",
		"job_id": "swordsman",
		"level": 50,
		"rarity": 3,
		"weapon_id": "chronos_toki_sword",
		"armor_id": "chronos_toki_armor",
		"accessory_id": "chronos_toki_orb",
		"relic_id": "relic_berserker_charm",
		"equipped_skill_ids": ["blood_mist_slash"],
		"enhance_level": 4,
		"equip_level": 50,
	},
	{
		"id": "staff_galen_antique",
		"credit": "Crownfall Staff",
		"player_name": "スタッフ2",
		"character_id": "adventurer_3",
		"display_name": "ガレン",
		"build_name": "アンティーク壁ビルド",
		"job_id": "vanguard",
		"level": 50,
		"rarity": 3,
		"weapon_id": "valgard_antique_blade",
		"armor_id": "valgard_antique_armor",
		"accessory_id": "valgard_antique_amulet",
		"relic_id": "relic_aegis_shard",
		"equipped_skill_ids": ["apex_guard"],
		"enhance_level": 4,
		"equip_level": 50,
	},
	{
		"id": "staff_serin_healer",
		"credit": "Crownfall Staff",
		"player_name": "スタッフ3",
		"character_id": "gacha_helper_c",
		"display_name": "セリン",
		"build_name": "野営ヒーラービルド",
		"job_id": "alchemist",
		"level": 50,
		"rarity": 3,
		"weapon_id": "mendweaver_staff",
		"armor_id": "field_salve_robe",
		"accessory_id": "apothecary_vial",
		"relic_id": "relic_lament_ring",
		"equipped_skill_ids": ["salve_burst"],
		"enhance_level": 4,
		"equip_level": 50,
	},
	{
		"id": "staff_riva_mark",
		"credit": "Crownfall Staff",
		"player_name": "スタッフ4",
		"character_id": "adventurer_1",
		"display_name": "リーヴァ",
		"build_name": "標的シナジービルド",
		"job_id": "ranger",
		"level": 50,
		"rarity": 3,
		"weapon_id": "chronos_toki_bow",
		"armor_id": "chronos_toki_armor",
		"accessory_id": "chronos_toki_orb",
		"relic_id": "relic_hunter_sigil",
		"equipped_skill_ids": ["hunting_ground_mark"],
		"enhance_level": 4,
		"equip_level": 50,
	},
	{
		"id": "staff_mirei_pet",
		"credit": "Crownfall Staff",
		"player_name": "スタッフ5",
		"character_id": "adventurer_4",
		"display_name": "ミレイ",
		"build_name": "ペット指揮ビルド",
		"job_id": "beast_tamer",
		"level": 50,
		"rarity": 3,
		"weapon_id": "packbond_staff",
		"armor_id": "beastcall_mantle",
		"accessory_id": "beastlord_fang",
		"relic_id": "relic_scout_lens",
		"equipped_skill_ids": ["herd_call"],
		"enhance_level": 4,
		"equip_level": 50,
	},
]


static func staff_presets() -> Array:
	return STAFF_PRESETS.duplicate(true)


static func find_staff_preset(preset_id: String) -> Dictionary:
	for raw: Variant in STAFF_PRESETS:
		if raw is Dictionary and str(raw.get("id", "")) == preset_id:
			return (raw as Dictionary).duplicate(true)
	return {}


## 展示室用。所持チェック付き normalize を踏まずレリック id を読む（スタッフ作例向け）。
static func member_relic_id(member: Resource) -> String:
	if member == null:
		return ""
	if "equipped_passive_ids" in member:
		for raw: Variant in member.equipped_passive_ids:
			var pid: String = CombatPassives.migrate_relic_passive_id(str(raw))
			if CombatPassives.is_relic_passive(pid):
				return pid
	return GameState.get_equipped_relic_passive_id(member)


## 名札／一覧用。「アルド(出血主砲ビルド)」。
static func staff_nameplate_text(preset: Dictionary) -> String:
	var char_name: String = str(preset.get("display_name", "")).strip_edges()
	var build: String = str(preset.get("build_name", "")).strip_edges()
	if char_name.is_empty():
		return build
	if build.is_empty():
		return char_name
	return "%s(%s)" % [char_name, build]


## スタッフ作例から表示専用 Adventurer を組み立てる（roster に入れない）。
static func build_member_from_preset(preset: Dictionary) -> Resource:
	if preset.is_empty():
		return null
	var adv := Adventurer.new()
	var character_id: String = str(preset.get("character_id", "")).strip_edges()
	if character_id.is_empty():
		character_id = "showcase_%s" % str(preset.get("id", "staff"))
	adv.id = character_id
	adv.display_name = str(preset.get("display_name", "？？？"))
	adv.job_id = str(preset.get("job_id", "swordsman"))
	adv.level = maxi(1, int(preset.get("level", 1)))
	adv.rarity = clampi(int(preset.get("rarity", Adventurer.STARTER_RARITY)), 1, 4)
	adv.is_evolved = adv.level >= 30
	_GachaRarityConfig.apply_stats_for_adventurer(adv)
	var enhance_lv: int = clampi(int(preset.get("enhance_level", 0)), 0, _EquipmentEnhancer.MAX_FORGE_LEVEL)
	var equip_lv: int = _EquipmentEnhancer.clamp_equip_level(int(preset.get("equip_level", adv.level)))
	adv.equipped_weapon = _make_weapon(
		str(preset.get("weapon_id", "")), character_id, enhance_lv, equip_lv
	)
	adv.equipped_armor = _make_armor(
		str(preset.get("armor_id", "")), character_id, enhance_lv, equip_lv
	)
	adv.equipped_accessory = _make_accessory(
		str(preset.get("accessory_id", "")), character_id, enhance_lv, equip_lv
	)
	var relic_id: String = CombatPassives.migrate_relic_passive_id(
		str(preset.get("relic_id", "")).strip_edges()
	)
	if not relic_id.is_empty() and CombatPassives.is_relic_passive(relic_id):
		## スタッフ作例は所持フラグ無し。equipped_passive_ids 直置き（normalize で消されないよう表示は直読み）。
		adv.equipped_passive_ids = [relic_id] as Array[String]
		adv.passive_slots_customized = true
	var skill_ids: Array[String] = []
	var raw_skills: Variant = preset.get("equipped_skill_ids", [])
	if raw_skills is Array:
		for raw_sid: Variant in raw_skills:
			var sid: String = str(raw_sid).strip_edges()
			if sid.is_empty() or skill_ids.has(sid):
				continue
			if skill_ids.size() >= Constants.MAX_EQUIPPED_SKILLS:
				break
			skill_ids.append(sid)
	adv.equipped_skill_ids = skill_ids
	return adv


static func _make_weapon(
	weapon_id: String, owner_tag: String, enhance_level: int, equip_level: int
) -> Resource:
	if weapon_id.is_empty():
		return null
	var data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if data == null:
		return null
	var inst := WeaponInstance.new()
	inst.instance_id = "showcase_wpn_%s_%s" % [owner_tag, weapon_id]
	inst.weapon_id = weapon_id
	inst.is_appraised = true
	inst.equip_level = equip_level
	inst.enhance_level = enhance_level
	_WeaponStatResolver.apply_drop_stats(inst, data)
	inst.equip_level = equip_level
	inst.enhance_level = enhance_level
	return inst


static func _make_armor(
	armor_id: String, owner_tag: String, enhance_level: int, equip_level: int
) -> Resource:
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
	inst.equip_level = equip_level
	inst.enhance_level = enhance_level
	_ArmorStatResolver.apply_drop_stats(inst, data)
	inst.equip_level = equip_level
	inst.enhance_level = enhance_level
	return inst


static func _make_accessory(
	accessory_id: String, owner_tag: String, enhance_level: int, equip_level: int
) -> Resource:
	if accessory_id.is_empty():
		return null
	var data: Resource = DataRegistry.get_accessory_data(accessory_id)
	if data == null:
		return null
	var inst := AccessoryInstance.new()
	inst.instance_id = "showcase_acc_%s_%s" % [owner_tag, accessory_id]
	inst.accessory_id = accessory_id
	inst.is_appraised = true
	inst.equip_level = equip_level
	inst.enhance_level = enhance_level
	_AccessoryStatResolver.apply_drop_stats(inst, data)
	inst.equip_level = equip_level
	inst.enhance_level = enhance_level
	return inst
