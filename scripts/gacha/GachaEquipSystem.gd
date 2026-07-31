extends RefCounted
class_name GachaEquipSystem

## 封蔵の匣（灰冠装備ガチャ）。P3-GACHA-EQ-SEAL-UI-001 / Decision 28。
## 案A: Epic 55%／L 45%。L内は灰冠 60%／既存L 40%。深層・神話・セット除外。

const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver := preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver := preload("res://scripts/equipment/AccessoryStatResolver.gd")

const PULL_COST: int = 300

## 帯確率（合計 1.0）。
const RATE_EPIC: float = 0.55
const RATE_LEGENDARY: float = 0.45
## L 内（合計 1.0）。
const RATE_L_KAIWAN: float = 0.60
const RATE_L_OTHER: float = 0.40

const KINDS: Array[String] = ["weapon", "armor", "accessory"]

## { kind, id, seat, blurb, effect } — 灰冠限定（メリデメは Decision 28。effect は画面用の口語説明）。
const POOL: Array[Dictionary] = [
	{"kind": "weapon", "id": "kaiwan_crosslit", "seat": "塞図", "blurb": "最初の一太刀だけが道を塞ぐ", "effect": "戦闘の最初の攻撃の威力が３０％アップ！ただし、２撃目以降の威力は８％ダウン！"},
	{"kind": "weapon", "id": "kaiwan_vendict", "seat": "売境", "blurb": "境を売り、血で買う", "effect": "与えるダメージが１８％アップ！ただし、受けるダメージが１２％アップ！"},
	{"kind": "weapon", "id": "kaiwan_silent", "seat": "裂鍵", "blurb": "封じを裂き、知を削ぐ", "effect": "敵のバフを解除する確率が３０％アップ！さらにデバフを付与する力が１５％アップ！ただし、自分のスキルの再使用時間が１０％延びる！"},
	{"kind": "weapon", "id": "kaiwan_perfidy", "seat": "違約", "blurb": "約束を刃に変える", "effect": "デバフ中の敵への威力が２２％アップ！ただし、味方への回復・援護効果が２０％ダウン！"},
	{"kind": "weapon", "id": "kaiwan_nox", "seat": "灯断", "blurb": "灯を消し、闇で射る", "effect": "後列からの威力が２０％アップ！さらに会心率が８％アップ！ただし、戦闘開始時に自分のHPが８％減少する！"},
	{"kind": "weapon", "id": "kaiwan_false", "seat": "偽星", "blurb": "偽の星炉が脆い刃を生む", "effect": "炉研ぎ・錬成の効果が１５％アップ！ただし、受けたときのクリティカル率が１０％アップ！"},
	{"kind": "weapon", "id": "kaiwan_saltine", "seat": "奪潮", "blurb": "潮を奪い、疾く走る", "effect": "行動速度が１２％アップ！さらに水・氷属性の威力が１５％アップ！ただし、罠・探索ダメージが２５％アップ！"},
	{"kind": "weapon", "id": "kaiwan_wiltes", "seat": "枯翠", "blurb": "癒しを枯らして火力へ", "effect": "回復スキルの半分が追加ダメージに変わる！ただし、継続回復・ターン回復が５０％ダウン！"},
	{"kind": "weapon", "id": "kaiwan_relictos", "seat": "断継", "blurb": "継ぎを断ち、連鎖で狩る", "effect": "敵を倒した直後の次の攻撃の威力が３５％アップ！ただし、味方が戦闘不能のあいだ自分の威力は１５％ダウン！"},
	{"kind": "armor", "id": "kaiwan_primehide", "seat": "塞図", "blurb": "最初の被弾までを塞ぐ皮", "effect": "戦闘中、最初の被弾までのダメージが２０％ダウン！ただし、それ以降の被ダメは８％アップ！"},
	{"kind": "armor", "id": "kaiwan_bloodmail", "seat": "売境", "blurb": "血を糧にする鎖帷子", "effect": "ダメージを受けたあと、次の攻撃の威力が１２％アップ！ただし、最大HPが１０％ダウン！"},
	{"kind": "armor", "id": "kaiwan_voidrobe", "seat": "裂鍵", "blurb": "虚ろなローブが時を伸ばす", "effect": "自分のスキル再使用ペナルティが半分になる！ただし、与えるダメージが８％ダウン！"},
	{"kind": "armor", "id": "kaiwan_oathbreak", "seat": "違約", "blurb": "破約の板金", "effect": "デバフ中の敵から受けるダメージが１２％ダウン！ただし、自分が受ける回復が１５％ダウン！"},
	{"kind": "armor", "id": "kaiwan_duskmail", "seat": "灯断", "blurb": "宵闇の後列を守る", "effect": "開幕のHP減少が半分になる！ただし、前列にいると与ダメが１０％ダウン！"},
	{"kind": "armor", "id": "kaiwan_forgepate", "seat": "偽星", "blurb": "偽炉の加護と脆さ", "effect": "炉研ぎ・錬成の効果がさらに１０％アップ！ただし、被クリティカル率がさらに８％アップ！"},
	{"kind": "armor", "id": "kaiwan_tideskin", "seat": "奪潮", "blurb": "潮膚が罠を薄める", "effect": "罠・探索ダメージのペナルティが半分になる！ただし、炎属性の被ダメが１５％アップ！"},
	{"kind": "armor", "id": "kaiwan_thornmail", "seat": "枯翠", "blurb": "棘が回復を刺し変える", "effect": "回復を与ダメへ変換する率が１５ポイントアップ！ただし、受ける回復が２０％ダウン！"},
	{"kind": "armor", "id": "kaiwan_lastcoil", "seat": "断継", "blurb": "最後の鎖が撃破を伸ばす", "effect": "撃破後のバフ時間が延びる！ただし、味方戦闘不能時の与ダメペナが２０％に悪化する！"},
	{"kind": "accessory", "id": "kaiwan_initio", "seat": "塞図", "blurb": "初撃に宿る灰心", "effect": "初撃の会心率が２５％アップ！ただし、２撃目以降の会心は１０％ダウン！"},
	{"kind": "accessory", "id": "kaiwan_venomband", "seat": "売境", "blurb": "毒帯が火力を盛る", "effect": "与えるダメージが１０％アップ！ただし、回復効果が１５％ダウン！"},
	{"kind": "accessory", "id": "kaiwan_unlock", "seat": "裂鍵", "blurb": "解呪の鍵飾り", "effect": "バフ解除に成功すると追加で小ダメージ！ただし、味方へのバフ効果時間が１５％ダウン！"},
	{"kind": "accessory", "id": "kaiwan_curseband", "seat": "違約", "blurb": "呪いを乗せる腕輪", "effect": "攻撃時、低確率で追加デバフを付与！ただし、援護・オーラ系効果が２５％ダウン！"},
	{"kind": "accessory", "id": "kaiwan_nocturne", "seat": "灯断", "blurb": "消灯の代償を初撃へ", "effect": "開幕に失ったHPの割合が初撃の威力に上乗せ！ただし、戦闘中のHP回復が３０％ダウン！"},
	{"kind": "accessory", "id": "kaiwan_sparkle", "seat": "偽星", "blurb": "偽星の輝きは強化次第", "effect": "強化が進むほど与ダメが上がる！ただし、未強化だと与ダメが２０％ダウン！"},
	{"kind": "accessory", "id": "kaiwan_reefhook", "seat": "奪潮", "blurb": "リーフの鉤が潮を呼ぶ", "effect": "水・氷属性の威力が１０％アップ！さらに行動速度が５％アップ！ただし、聖属性耐性が１０％ダウン！"},
	{"kind": "accessory", "id": "kaiwan_wither", "seat": "枯翠", "blurb": "枯葉が癒しを焼く", "effect": "回復するたびに自分にも軽いダメージが入り、そのぶん与ダメが上がる！ただし、蘇生や強回復はほぼ効かない！"},
	{"kind": "accessory", "id": "kaiwan_nextedge", "seat": "断継", "blurb": "次の刃が連鎖する", "effect": "撃破連鎖の２回目にも半分の補正が乗る！ただし、戦闘開始時のSPが１０％ダウン！"},
]

## キャッシュ: kind -> Array[{kind,id}]
static var _epic_by_kind: Dictionary = {}
static var _other_l_by_kind: Dictionary = {}
static var _pools_ready: bool = false


static func pull_cost() -> int:
	return PULL_COST


static func can_pull() -> bool:
	return GameState.gacha_token >= PULL_COST


static func can_pull_with_ticket() -> bool:
	return TicketSystem.can_use_free_seal()


static func rate_display_text() -> String:
	## フォーマット無しの生文字列。%% だと画面に二重 % が出る（P3-FIX-GACHA-SEAL-AUDIT-A-001）。
	return "Epic 55%／L 45%（灰冠寄）"


static func rate_detail_text() -> String:
	return (
		"Epic 55%%\nL 45%%（内訳: 灰冠 60%%／既存L 40%%）\n\n"
		+ "部位は武・防・飾均等 → その中で均等\n"
		+ "除外: 神話・降臨セット・深層専用・真・王遺産\n\n"
		+ "1回 %d 魔晶石／封蔵開封券可"
	) % PULL_COST


static func catchcopy() -> String:
	return "灰冠の刃を手にする"


static func effect_title() -> String:
	return "効果"


static func effect_text_for(entry: Dictionary) -> String:
	if entry.is_empty():
		return ""
	var effect: String = str(entry.get("effect", "")).strip_edges()
	if not effect.is_empty():
		return effect
	return str(entry.get("blurb", ""))


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


static func ensure_pools() -> void:
	if _pools_ready:
		return
	_epic_by_kind = {"weapon": [], "armor": [], "accessory": []}
	_other_l_by_kind = {"weapon": [], "armor": [], "accessory": []}
	_collect_from_list("weapon", DataRegistry.get_all_weapon_data())
	_collect_from_list("armor", DataRegistry.get_all_armor_data())
	_collect_from_list("accessory", DataRegistry.get_all_accessory_data())
	_pools_ready = true


## テスト用にキャッシュを落とす。
static func reset_pools_for_tests() -> void:
	_pools_ready = false
	_epic_by_kind.clear()
	_other_l_by_kind.clear()


static func epic_pool_count() -> int:
	ensure_pools()
	return _count_by_kind(_epic_by_kind)


static func other_l_pool_count() -> int:
	ensure_pools()
	return _count_by_kind(_other_l_by_kind)


static func entries_for_pool(pool_tag: String) -> Array:
	ensure_pools()
	var out: Array = []
	match pool_tag:
		"epic":
			for k: String in KINDS:
				out.append_array(_epic_by_kind.get(k, []) as Array)
		"other_l":
			for k: String in KINDS:
				out.append_array(_other_l_by_kind.get(k, []) as Array)
		"kaiwan":
			out.append_array(POOL)
	return out


static func _count_by_kind(by_kind: Dictionary) -> int:
	var n: int = 0
	for k: String in KINDS:
		n += (by_kind.get(k, []) as Array).size()
	return n


static func _collect_from_list(kind: String, items: Array) -> void:
	for data: Variant in items:
		if data == null:
			continue
		var item_id: String = _data_id(kind, data)
		if item_id.is_empty():
			continue
		if not _is_eligible_standard(kind, item_id, data):
			continue
		var rarity: int = int(data.rarity) if "rarity" in data else -1
		var entry: Dictionary = {"kind": kind, "id": item_id}
		if rarity == Enums.Rarity.EPIC:
			(_epic_by_kind[kind] as Array).append(entry)
		elif rarity == Enums.Rarity.LEGENDARY:
			(_other_l_by_kind[kind] as Array).append(entry)


static func _data_id(kind: String, data: Resource) -> String:
	match kind:
		"weapon", "accessory":
			return str(data.id) if "id" in data else ""
		"armor":
			if "armor_id" in data and not str(data.armor_id).is_empty():
				return str(data.armor_id)
			return str(data.id) if "id" in data else ""
	return ""


static func _is_eligible_standard(kind: String, item_id: String, data: Resource) -> bool:
	## 灰冠は専用プール。既存枠から除外。
	if item_id.begins_with("kaiwan_"):
		return false
	## 深層専用除外（案A推奨）。
	if item_id.begins_with("abyss_"):
		return false
	var rarity: int = int(data.rarity) if "rarity" in data else -1
	if rarity != Enums.Rarity.EPIC and rarity != Enums.Rarity.LEGENDARY:
		return false
	## 神話・セット帯・降臨セット部位は出さない。
	if rarity >= Enums.Rarity.MYTHIC:
		return false
	if "set_id" in data and not str(data.set_id).is_empty():
		return false
	## データが解決できること。
	match kind:
		"weapon":
			return DataRegistry.get_weapon_data(item_id) != null
		"armor":
			return DataRegistry.get_armor_data(item_id) != null
		"accessory":
			return DataRegistry.get_accessory_data(item_id) != null
	return false


## 結果: { ok, reason?, kind, item_id, display_name, seat, blurb, rarity, pool, instance, paid_with_ticket }
static func pull(use_ticket: bool = false) -> Dictionary:
	var paid_with_ticket: bool = false
	if use_ticket:
		if not TicketSystem.try_consume_free_seal():
			return {"ok": false, "reason": "no_ticket"}
		paid_with_ticket = true
	elif not can_pull():
		return {"ok": false, "reason": "no_token"}
	else:
		GameState.gacha_token -= PULL_COST
	ensure_pools()
	var pick: Dictionary = _roll_entry()
	if pick.is_empty():
		_refund_pull_cost(paid_with_ticket)
		return {"ok": false, "reason": "empty_pool"}
	var kind: String = str(pick.get("kind", ""))
	var item_id: String = str(pick.get("id", ""))
	var inst: Resource = _spawn_instance(kind, item_id)
	if inst == null:
		_refund_pull_cost(paid_with_ticket)
		return {"ok": false, "reason": "spawn_failed"}
	_grant(kind, inst)
	if GameState.has_method("note_equipment_obtained"):
		GameState.note_equipment_obtained(inst)
	var pool_tag: String = str(pick.get("pool", ""))
	var kaiwan: Dictionary = pool_entry_by_id(item_id) if pool_tag == "kaiwan" else {}
	return {
		"ok": true,
		"kind": kind,
		"item_id": item_id,
		"display_name": display_name_for(kind, item_id),
		"seat": str(kaiwan.get("seat", "")),
		"blurb": str(kaiwan.get("blurb", "")),
		"rarity": int(pick.get("rarity", Enums.Rarity.LEGENDARY)),
		"pool": pool_tag,
		"instance": inst,
		"paid_with_ticket": paid_with_ticket,
	}


static func _refund_pull_cost(paid_with_ticket: bool) -> void:
	if paid_with_ticket:
		TicketSystem.refund_free_seal()
	else:
		GameState.gacha_token += PULL_COST


static func _roll_entry() -> Dictionary:
	var roll: float = randf()
	if roll < RATE_EPIC:
		var epic: Dictionary = _pick_slot_then_item(_epic_by_kind)
		if epic.is_empty():
			## Epic プール空なら L へフォールバック。
			return _roll_legendary_entry()
		epic["rarity"] = Enums.Rarity.EPIC
		epic["pool"] = "epic"
		return epic
	return _roll_legendary_entry()


static func _roll_legendary_entry() -> Dictionary:
	var l_roll: float = randf()
	if l_roll < RATE_L_KAIWAN:
		var kaiwan: Dictionary = _pick_kaiwan()
		if not kaiwan.is_empty():
			kaiwan["rarity"] = Enums.Rarity.LEGENDARY
			kaiwan["pool"] = "kaiwan"
			return kaiwan
	var other: Dictionary = _pick_slot_then_item(_other_l_by_kind)
	if other.is_empty():
		var fallback: Dictionary = _pick_kaiwan()
		if fallback.is_empty():
			return {}
		fallback["rarity"] = Enums.Rarity.LEGENDARY
		fallback["pool"] = "kaiwan"
		return fallback
	other["rarity"] = Enums.Rarity.LEGENDARY
	other["pool"] = "other_l"
	return other


static func _pick_kaiwan() -> Dictionary:
	## 部位均等 → 灰冠プール内均等。
	var by_kind: Dictionary = {"weapon": [], "armor": [], "accessory": []}
	for e: Dictionary in POOL:
		var k: String = str(e.get("kind", ""))
		if by_kind.has(k):
			(by_kind[k] as Array).append(e)
	return _pick_slot_then_item(by_kind)


static func _pick_slot_then_item(by_kind: Dictionary) -> Dictionary:
	var available: Array[String] = []
	for k: String in KINDS:
		var arr: Array = by_kind.get(k, []) as Array
		if not arr.is_empty():
			available.append(k)
	if available.is_empty():
		return {}
	var kind: String = available[randi() % available.size()]
	var pool: Array = by_kind.get(kind, []) as Array
	var entry: Dictionary = (pool[randi() % pool.size()] as Dictionary).duplicate()
	entry["kind"] = kind
	return entry


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
	return "seal_%d_%d" % [Time.get_ticks_msec(), randi() % 100000]
