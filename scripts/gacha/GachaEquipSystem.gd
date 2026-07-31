extends RefCounted
class_name GachaEquipSystem

## 封蔵の匣（灰冠装備ガチャ）。P3-GACHA-EQ-SEAL-UI-001 / Decision 28。
## 初版: 通常 L ロール。灰冠専用 random_mods／固有パッシブは後続。

const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver := preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver := preload("res://scripts/equipment/AccessoryStatResolver.gd")

const PULL_COST: int = 300

## { kind: "weapon"|"armor"|"accessory", id: String, seat: String, blurb: String }
const POOL: Array[Dictionary] = [
	{"kind": "weapon", "id": "kaiwan_crosslit", "seat": "塞図", "blurb": "最初の一太刀だけが道を塞ぐ"},
	{"kind": "weapon", "id": "kaiwan_vendict", "seat": "売境", "blurb": "境を売り、血で買う"},
	{"kind": "weapon", "id": "kaiwan_silent", "seat": "裂鍵", "blurb": "封じを裂き、知を削ぐ"},
	{"kind": "weapon", "id": "kaiwan_perfidy", "seat": "違約", "blurb": "約束を刃に変える"},
	{"kind": "weapon", "id": "kaiwan_nox", "seat": "灯断", "blurb": "灯を消し、闇で射る"},
	{"kind": "weapon", "id": "kaiwan_false", "seat": "偽星", "blurb": "偽の星炉が脆い刃を生む"},
	{"kind": "weapon", "id": "kaiwan_saltine", "seat": "奪潮", "blurb": "潮を奪い、疾く走る"},
	{"kind": "weapon", "id": "kaiwan_wiltes", "seat": "枯翠", "blurb": "癒しを枯らして火力へ"},
	{"kind": "weapon", "id": "kaiwan_relictos", "seat": "断継", "blurb": "継ぎを断ち、連鎖で狩る"},
	{"kind": "armor", "id": "kaiwan_primehide", "seat": "塞図", "blurb": "最初の被弾までを塞ぐ皮"},
	{"kind": "armor", "id": "kaiwan_bloodmail", "seat": "売境", "blurb": "血を糧にする鎖帷子"},
	{"kind": "armor", "id": "kaiwan_voidrobe", "seat": "裂鍵", "blurb": "虚ろなローブが時を伸ばす"},
	{"kind": "armor", "id": "kaiwan_oathbreak", "seat": "違約", "blurb": "破約の板金"},
	{"kind": "armor", "id": "kaiwan_duskmail", "seat": "灯断", "blurb": "宵闇の後列を守る"},
	{"kind": "armor", "id": "kaiwan_forgepate", "seat": "偽星", "blurb": "偽炉の加護と脆さ"},
	{"kind": "armor", "id": "kaiwan_tideskin", "seat": "奪潮", "blurb": "潮膚が罠を薄める"},
	{"kind": "armor", "id": "kaiwan_thornmail", "seat": "枯翠", "blurb": "棘が回復を刺し変える"},
	{"kind": "armor", "id": "kaiwan_lastcoil", "seat": "断継", "blurb": "最後の鎖が撃破を伸ばす"},
	{"kind": "accessory", "id": "kaiwan_initio", "seat": "塞図", "blurb": "初撃に宿る灰心"},
	{"kind": "accessory", "id": "kaiwan_venomband", "seat": "売境", "blurb": "毒帯が火力を盛る"},
	{"kind": "accessory", "id": "kaiwan_unlock", "seat": "裂鍵", "blurb": "解呪の鍵飾り"},
	{"kind": "accessory", "id": "kaiwan_curseband", "seat": "違約", "blurb": "呪いを乗せる腕輪"},
	{"kind": "accessory", "id": "kaiwan_nocturne", "seat": "灯断", "blurb": "消灯の代償を初撃へ"},
	{"kind": "accessory", "id": "kaiwan_sparkle", "seat": "偽星", "blurb": "偽星の輝きは強化次第"},
	{"kind": "accessory", "id": "kaiwan_reefhook", "seat": "奪潮", "blurb": "リーフの鉤が潮を呼ぶ"},
	{"kind": "accessory", "id": "kaiwan_wither", "seat": "枯翠", "blurb": "枯葉が癒しを焼く"},
	{"kind": "accessory", "id": "kaiwan_nextedge", "seat": "断継", "blurb": "次の刃が連鎖する"},
]


static func pull_cost() -> int:
	return PULL_COST


static func can_pull() -> bool:
	return GameState.gacha_token >= PULL_COST


static func rate_display_text() -> String:
	return "灰冠限定 L／席共鳴ランダム（初版）"


static func catchcopy() -> String:
	return "盗まれた炉の武具。正義の刃ではない。"


static func featured_entries() -> Array:
	## 武器9を Featured 回転の主軸に（防・飾は排出に含む）。
	var out: Array = []
	for e: Dictionary in POOL:
		if str(e.get("kind", "")) == "weapon":
			out.append(e)
	return out


static func pool_entry_by_id(item_id: String) -> Dictionary:
	for e: Dictionary in POOL:
		if str(e.get("id", "")) == item_id:
			return e
	return {}


static func display_name_for(kind: String, item_id: String) -> String:
	match kind:
		"weapon":
			var w: Resource = DataRegistry.get_weapon_data(item_id)
			return str(w.display_name) if w != null else item_id
		"armor":
			var a: Resource = DataRegistry.get_armor_data(item_id)
			return str(a.display_name) if a != null else item_id
		"accessory":
			var c: Resource = DataRegistry.get_accessory_data(item_id)
			return str(c.display_name) if c != null else item_id
	return item_id


static func kind_label(kind: String) -> String:
	match kind:
		"weapon":
			return "武器"
		"armor":
			return "防具"
		"accessory":
			return "装飾"
	return kind


## 結果: { ok, reason?, kind, item_id, display_name, seat, rarity, instance }
static func pull() -> Dictionary:
	if not can_pull():
		return {"ok": false, "reason": "no_token"}
	if POOL.is_empty():
		return {"ok": false, "reason": "empty_pool"}
	GameState.gacha_token -= PULL_COST
	var entry: Dictionary = POOL[randi() % POOL.size()]
	var kind: String = str(entry.get("kind", ""))
	var item_id: String = str(entry.get("id", ""))
	var inst: Resource = _spawn_instance(kind, item_id)
	if inst == null:
		GameState.gacha_token += PULL_COST
		return {"ok": false, "reason": "spawn_failed"}
	_grant(kind, inst)
	if GameState.has_method("note_equipment_obtained"):
		GameState.note_equipment_obtained(inst)
	return {
		"ok": true,
		"kind": kind,
		"item_id": item_id,
		"display_name": display_name_for(kind, item_id),
		"seat": str(entry.get("seat", "")),
		"blurb": str(entry.get("blurb", "")),
		"rarity": Enums.Rarity.LEGENDARY,
		"instance": inst,
	}


static func _spawn_instance(kind: String, item_id: String) -> Resource:
	match kind:
		"weapon":
			var data: Resource = DataRegistry.get_weapon_data(item_id)
			if data == null:
				return null
			var w: Resource = WeaponInstance.new()
			w.instance_id = _new_instance_id()
			w.weapon_id = item_id
			_WeaponStatResolver.apply_drop_stats(w, data)
			w.is_appraised = true
			return w
		"armor":
			var adata: Resource = DataRegistry.get_armor_data(item_id)
			if adata == null:
				return null
			var a: Resource = ArmorInstance.new()
			a.instance_id = _new_instance_id()
			a.armor_id = item_id
			_ArmorStatResolver.apply_drop_stats(a, adata)
			a.is_appraised = true
			return a
		"accessory":
			var cdata: Resource = DataRegistry.get_accessory_data(item_id)
			if cdata == null:
				return null
			var c: Resource = AccessoryInstance.new()
			c.instance_id = _new_instance_id()
			c.accessory_id = item_id
			_AccessoryStatResolver.apply_drop_stats(c, cdata)
			c.is_appraised = true
			return c
	return null


static func _grant(kind: String, inst: Resource) -> void:
	match kind:
		"weapon":
			GameState.inventory.append(inst)
		"armor":
			GameState.armor_inventory.append(inst)
		"accessory":
			GameState.accessory_inventory.append(inst)


static func _new_instance_id() -> String:
	return "kaiwan_%d_%d" % [Time.get_ticks_msec(), randi() % 100000]
