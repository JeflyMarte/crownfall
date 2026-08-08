class_name ShowcaseCatalog
extends RefCounted

## ビルド作例プリセット（読取専用・セーブ非汚染）。P3-SHOWCASE-001／P3-UX-SHOWCASE-BUILD-COPY-001。
## β到達の理想ビルド（レジェンド以下。エンシェント／ミシック不使用・深層なし）。
## キャラ Lv・装備 Lv は上限99想定。

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
## ビルド作例装備はレジェンド以下（エンシェント=SET／ミシック不可）。
const STAFF_MAX_EQUIP_RARITY: int = Enums.Rarity.LEGENDARY
const STAFF_SHOWCASE_LEVEL: int = 99
const STAFF_SHOWCASE_EQUIP_LEVEL: int = 99

## ビルド作例。装備 id はカタログ実在分のみ。
## character_id = 肖像／個人補正用（adventurer_* / gacha_helper_*）。
## display_name + build_name → 名札「アルド(出血主砲ビルド)」。
## player_name = 内部番号（ビルド1…）。一覧ソート用。名札には使わない。
## build_blurb = スキル欄下の短い役割説明。
const STAFF_PRESETS: Array = [
	{
		"id": "staff_aldo_bleed",
		"credit": "Crownfall Staff",
		"player_name": "ビルド1",
		"character_id": "adventurer_0",
		"display_name": "アルド",
		"build_name": "出血主砲ビルド",
		"build_blurb": "出血を重ねて火力を伸ばす主砲型。高火力レリックで押し切る。",
		"job_id": "swordsman",
		"level": 99,
		"rarity": 3,
		"weapon_id": "pulsekeen_edge",
		"armor_id": "bloodpact_plate",
		"accessory_id": "bloodvein_signet",
		"relic_id": "relic_berserker_charm",
		"equipped_skill_ids": ["blood_mist_slash"],
		"enhance_level": 4,
		"equip_level": 99,
	},
	{
		"id": "staff_galen_bulwark",
		"credit": "Crownfall Staff",
		"player_name": "ビルド2",
		"character_id": "adventurer_3",
		"display_name": "ガレン",
		"build_name": "防壁盾役ビルド",
		"build_blurb": "ヘイトと耐久で前線を受ける盾役。味方を守る防壁装備構成。",
		"job_id": "vanguard",
		"level": 99,
		"rarity": 3,
		"weapon_id": "aegis_line_sword",
		"armor_id": "bulwark_role_plate",
		"accessory_id": "ironvow_amulet",
		"relic_id": "relic_aegis_shard",
		"equipped_skill_ids": ["assault_shatter"],
		"enhance_level": 4,
		"equip_level": 99,
	},
	{
		"id": "staff_serin_healer",
		"credit": "Crownfall Staff",
		"player_name": "ビルド3",
		"character_id": "gacha_helper_c",
		"display_name": "セリン",
		"build_name": "野営ヒーラービルド",
		"build_blurb": "回復と支援でパーティを支える調剤型。安定した継戦力向け。",
		"job_id": "alchemist",
		"level": 99,
		"rarity": 3,
		"weapon_id": "mendweaver_staff",
		"armor_id": "field_salve_robe",
		"accessory_id": "apothecary_vial",
		"relic_id": "relic_lament_ring",
		"equipped_skill_ids": ["salve_burst"],
		"enhance_level": 4,
		"equip_level": 99,
	},
	{
		"id": "staff_riva_mark",
		"credit": "Crownfall Staff",
		"player_name": "ビルド4",
		"character_id": "adventurer_1",
		"display_name": "リーヴァ",
		"build_name": "標的シナジービルド",
		"build_blurb": "標的を付けて味方の集中火力を引き出す射撃型。連携向き。",
		"job_id": "ranger",
		"level": 99,
		"rarity": 3,
		"weapon_id": "volley_horizon_bow",
		"armor_id": "flurry_light_mail",
		"accessory_id": "pierce_charm",
		"relic_id": "relic_hunter_sigil",
		"equipped_skill_ids": ["hunting_ground_mark"],
		"enhance_level": 4,
		"equip_level": 99,
	},
	{
		"id": "staff_mirei_pet",
		"credit": "Crownfall Staff",
		"player_name": "ビルド5",
		"character_id": "adventurer_4",
		"display_name": "ミレイ",
		"build_name": "毒牙ビルド",
		"build_blurb": "毒とペット連携で削る指揮型。継続ダメージと相棒運用の見本。",
		"job_id": "beast_tamer",
		"level": 99,
		"rarity": 3,
		"weapon_id": "packbond_staff",
		"armor_id": "beastcall_mantle",
		"accessory_id": "beastlord_fang",
		"relic_id": "relic_scout_lens",
		"equipped_skill_ids": ["venom_spray"],
		"enhance_level": 4,
		"equip_level": 99,
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
