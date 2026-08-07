extends RefCounted
class_name GachaEquipSystem

## 封蔵の匣（灰冠装備ガチャ）。P3-GACHA-EQ-SEAL-UI-001 / Decision 28。
## 案A: Epic 55%／L 45%。L内は灰冠 60%／既存L 40%。深層・神話・セット除外。

const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver := preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver := preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _BuildLegendaryLoot := preload("res://scripts/equipment/BuildLegendaryLoot.gd")

const PULL_COST: int = 300

## 帯確率（合計 1.0）。
const RATE_EPIC: float = 0.55
const RATE_LEGENDARY: float = 0.45
## L 内（合計 1.0）。
const RATE_L_KAIWAN: float = 0.60
const RATE_L_OTHER: float = 0.40

const KINDS: Array[String] = ["weapon", "armor", "accessory"]

## { kind, id, seat, blurb, effect, inventory_effect } — 灰冠限定（メリデメは Decision 28）。
## blurb は Featured 黄字煽り：商品紹介調の2行。effect は封蔵画面の口語。
## inventory_effect は装備一覧・固有効果用（他L装備と同型の落ち着いた文体）。
const POOL: Array[Dictionary] = [
	{"kind": "weapon", "id": "kaiwan_crosslit", "seat": "塞図", "blurb": "初撃だけで勝負を決める！\n開幕の一閃に全振りしたいときに！", "effect": "戦闘の最初の攻撃の威力が３０％アップ！ただし、２撃目以降の威力は８％ダウン！", "inventory_effect": "戦闘の最初の攻撃の威力が30%上昇する。2撃目以降の威力は8%低下する。"},
	{"kind": "weapon", "id": "kaiwan_vendict", "seat": "売境", "blurb": "とにかく削る火力特化！\n硬い相手には向かない——殴り合い覚悟で！", "effect": "与えるダメージが１８％アップ！ただし、受けるダメージが１２％アップ！", "inventory_effect": "与ダメージが18%上昇する。被ダメージが12%増加する。"},
	{"kind": "weapon", "id": "kaiwan_silent", "seat": "裂鍵", "blurb": "強化中の敵に刺さる杖！\nバフを盛る相手ほど痛い！", "effect": "バフ中の敵への威力が２５％アップ！ただし、自分のスキルの再使用時間が１０％延びる！", "inventory_effect": "バフ中の敵への威力が25%上昇する。自身のスキル再使用時間が10%延びる。"},
	{"kind": "weapon", "id": "kaiwan_perfidy", "seat": "違約", "blurb": "デバフ中の敵にとにかく強い！\n相手にデバフをばら撒く味方と組み合わせて高火力を叩き込め！", "effect": "デバフ中の敵への威力が２２％アップ！ただし、味方への回復・援護効果が２０％ダウン！", "inventory_effect": "デバフ中の敵への威力が22%上昇する。味方への回復・援護効果は20%低下する。"},
	{"kind": "weapon", "id": "kaiwan_nox", "seat": "灯断", "blurb": "後列から会心で撃ち抜く！\n開幕で少し削れる代わりに、後ろから仕留める一択！", "effect": "後列からの威力が２０％アップ！さらに会心率が８％アップ！ただし、戦闘開始時に自分のHPが８％減少する！", "inventory_effect": "後列からの威力が20%上昇し、会心率が8%上昇する。戦闘開始時に自身のHPが8%減少する。"},
	{"kind": "weapon", "id": "kaiwan_false", "seat": "偽星", "blurb": "会心が刺さった瞬間が本番！\nクリティカル特化の脆い刃！", "effect": "会心ダメージが３０％アップ！ただし、受けたときのクリティカル率が１０％アップ！", "inventory_effect": "会心ダメージが30%上昇する。被クリティカル率が10%上昇する。"},
	{"kind": "weapon", "id": "kaiwan_saltine", "seat": "奪潮", "blurb": "足が速く、水と氷に乗せる！\n罠には弱いけど、属性編成の追い風に！", "effect": "行動速度が１２％アップ！さらに水・氷属性の威力が１５％アップ！ただし、罠・探索ダメージが２５％アップ！", "inventory_effect": "行動速度が12%上昇し、水・氷属性の威力が15%上昇する。罠・探索ダメージが25%増加する。"},
	{"kind": "weapon", "id": "kaiwan_wiltes", "seat": "枯翠", "blurb": "癒すたび最弱へ棘が飛ぶ！\nヒーラーが殴りも担うときの杖！", "effect": "回復スキルを使うと、いちばん弱い敵に回復量の４０％相当のダメージ！ただし、自分が受ける回復が２０％ダウン！", "inventory_effect": "回復スキル使用時、最弱の敵に回復量の40%相当のダメージを与える。自身が受ける回復が20%低下する。"},
	{"kind": "weapon", "id": "kaiwan_relictos", "seat": "断継", "blurb": "倒した直後がいちばん熱い！\n連鎖撃破で押し切る編成向き！", "effect": "敵を倒した直後の次の攻撃の威力が３５％アップ！ただし、味方が戦闘不能のあいだ自分の威力は１５％ダウン！", "inventory_effect": "敵を倒した直後の次の攻撃の威力が35%上昇する。味方が戦闘不能のあいだ、自身の威力は15%低下する。"},
	{"kind": "armor", "id": "kaiwan_primehide", "seat": "塞図", "blurb": "開幕の被弾をガチガチに！\n最初の一発を耐えて戦線を保て！", "effect": "戦闘中、最初の被弾までのダメージが２０％ダウン！ただし、それ以降の被ダメは８％アップ！", "inventory_effect": "戦闘中、最初の被弾までのダメージが20%減少する。それ以降の被ダメージは8%増加する。"},
	{"kind": "armor", "id": "kaiwan_bloodmail", "seat": "売境", "blurb": "殴られたあとが本番！\n被弾を反撃の合図に変える！", "effect": "ダメージを受けたあと、次の攻撃の威力が１２％アップ！ただし、最大HPが１０％ダウン！", "inventory_effect": "ダメージを受けたあと、次の攻撃の威力が12%上昇する。最大HPが10%低下する。"},
	{"kind": "armor", "id": "kaiwan_voidrobe", "seat": "裂鍵", "blurb": "スキルをもっと回したい！\n手数重視の回転特化コーデに！", "effect": "自分のスキル再使用ペナルティが半分になる！ただし、与えるダメージが８％ダウン！", "inventory_effect": "自身のスキル再使用ペナルティが半分になる。与ダメージが8%低下する。"},
	{"kind": "armor", "id": "kaiwan_oathbreak", "seat": "違約", "blurb": "デバフ戦の盾になる！\n弱体だらけの戦場で粘り強く！", "effect": "デバフ中の敵から受けるダメージが１２％ダウン！ただし、自分が受ける回復が１５％ダウン！", "inventory_effect": "デバフ中の敵から受けるダメージが12%減少する。自身が受ける回復が15%低下する。"},
	{"kind": "armor", "id": "kaiwan_duskmail", "seat": "灯断", "blurb": "開幕の損耗を抑える！\n灯断武器と合わせて立ち上がりを安定！", "effect": "開幕のHP減少が半分になる！ただし、前列にいると与ダメが１０％ダウン！", "inventory_effect": "開幕のHP減少が半分になる。前列にいると与ダメージが10%低下する。"},
	{"kind": "armor", "id": "kaiwan_forgepate", "seat": "偽星", "blurb": "強化の伸びしろをさらに！\n偽星武器とセットで育成が加速！", "effect": "炉研ぎ・錬成の効果がさらに１０％アップ！ただし、被クリティカル率がさらに８％アップ！", "inventory_effect": "炉研ぎ・錬成の効果がさらに10%上昇する。被クリティカル率がさらに8%上昇する。"},
	{"kind": "armor", "id": "kaiwan_tideskin", "seat": "奪潮", "blurb": "罠や探索の痛みを半減！\n疾風編成の足回りを守る一枚！", "effect": "罠・探索ダメージのペナルティが半分になる！ただし、炎属性の被ダメが１５％アップ！", "inventory_effect": "罠・探索ダメージのペナルティが半分になる。炎属性の被ダメージが15%増加する。"},
	{"kind": "armor", "id": "kaiwan_thornmail", "seat": "枯翠", "blurb": "回復追撃の棘をさらに伸ばす！\n枯翠武器の追い打ちを盛る一枚！", "effect": "回復スキルの追撃ダメージが１５ポイントアップ！ただし、受ける回復が２０％ダウン！", "inventory_effect": "回復スキルの追撃ダメージが15ポイント上昇する。受ける回復が20%低下する。"},
	{"kind": "armor", "id": "kaiwan_lastcoil", "seat": "断継", "blurb": "撃破後の余韻を伸ばす！\n連鎖特化パーティの締めに！", "effect": "撃破後のバフ時間が延びる！ただし、味方戦闘不能時の与ダメペナが２０％に悪化する！", "inventory_effect": "撃破後のバフ時間が延びる。味方戦闘不能時の与ダメージペナルティが20%に悪化する。"},
	{"kind": "accessory", "id": "kaiwan_initio", "seat": "塞図", "blurb": "初撃の会心を一気に盛る！\n開幕クリティカル狙いの相棒に！", "effect": "初撃の会心率が２５％アップ！ただし、２撃目以降の会心は１０％ダウン！", "inventory_effect": "初撃の会心率が25%上昇する。2撃目以降の会心率は10%低下する。"},
	{"kind": "accessory", "id": "kaiwan_venomband", "seat": "売境", "blurb": "与ダメを素直に底上げ！\n回復は捨てて火力だけ欲しいときに！", "effect": "与えるダメージが１０％アップ！ただし、回復効果が１５％ダウン！", "inventory_effect": "与ダメージが10%上昇する。回復効果が15%低下する。"},
	{"kind": "accessory", "id": "kaiwan_unlock", "seat": "裂鍵", "blurb": "バフ解除にダメージを乗せる！\n裂鍵武器と組むと削ぎが加速！", "effect": "バフ解除に成功すると追加で小ダメージ！ただし、味方へのバフ効果時間が１５％ダウン！", "inventory_effect": "バフ解除に成功すると追加で小ダメージを与える。味方へのバフ効果時間が15%短縮する。"},
	{"kind": "accessory", "id": "kaiwan_curseband", "seat": "違約", "blurb": "攻撃しながらデバフをばら撒く！\n違約武器の特攻を自分で仕込む！", "effect": "攻撃時、低確率で追加デバフを付与！ただし、援護・オーラ系効果が２５％ダウン！", "inventory_effect": "攻撃時、低確率で追加デバフを付与する。援護・オーラ系効果が25%低下する。"},
	{"kind": "accessory", "id": "kaiwan_nocturne", "seat": "灯断", "blurb": "開幕のコストを初撃に変える！\n灯断セットで立ち上がり火力を稼ぐ！", "effect": "開幕に失ったHPの割合が初撃の威力に上乗せ！ただし、戦闘中のHP回復が３０％ダウン！", "inventory_effect": "開幕に失ったHPの割合が初撃の威力に上乗せされる。戦闘中のHP回復が30%低下する。"},
	{"kind": "accessory", "id": "kaiwan_sparkle", "seat": "偽星", "blurb": "強化するほど火力が跳ねる！\n未強化のままでは本領を出せない！", "effect": "強化が進むほど与ダメが上がる！ただし、未強化だと与ダメが２０％ダウン！", "inventory_effect": "強化が進むほど与ダメージが上昇する。未強化だと与ダメージが20%低下する。"},
	{"kind": "accessory", "id": "kaiwan_reefhook", "seat": "奪潮", "blurb": "水氷と速度をひと盛り！\n奪潮武器の疾風編成を後押し！", "effect": "水・氷属性の威力が１０％アップ！さらに行動速度が５％アップ！ただし、聖属性耐性が１０％ダウン！", "inventory_effect": "水・氷属性の威力が10%上昇し、行動速度が5%上昇する。聖属性耐性が10%低下する。"},
	{"kind": "accessory", "id": "kaiwan_wither", "seat": "枯翠", "blurb": "回復のたびに火力へ変換！\n枯翠編成を極振りするときの賭け！", "effect": "回復するたびに自分にも軽いダメージが入り、そのぶん与ダメが上がる！ただし、蘇生や強回復はほぼ効かない！", "inventory_effect": "回復するたびに自身にも軽いダメージが入り、そのぶん与ダメージが上昇する。蘇生や強回復はほぼ効かない。"},
	{"kind": "accessory", "id": "kaiwan_nextedge", "seat": "断継", "blurb": "撃破連鎖の２回目も伸ばす！\n断継武器の追い打ちを途切れさせない！", "effect": "撃破連鎖の２回目にも半分の補正が乗る！ただし、戦闘開始時のSPが１０％ダウン！", "inventory_effect": "撃破連鎖の2回目にも半分の補正が乗る。戦闘開始時のSPが10%低下する。"},
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
	return "Epic 55%／LEGEND 45%（灰冠寄）"


static func rate_detail_text() -> String:
	return (
		"Epic 55%%\nLEGEND 45%%（内訳: 灰冠 60%%／既存LEGEND 40%%）\n\n"
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



static func inventory_effect_text_for(entry: Dictionary) -> String:
	if entry.is_empty():
		return ""
	var inv: String = str(entry.get("inventory_effect", "")).strip_edges()
	if not inv.is_empty():
		return inv
	## 未設定時のみ口語へフォールバック（運用上は inventory_effect 必須）。
	return effect_text_for(entry)


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
	## ビルド拡張Lは x-5 追加枠（Decision 50／54）。封蔵の既存L 40%から除外。
	if item_id in _BuildLegendaryLoot.all_ids():
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
	## ダンジョンドロップと同様に New 表示対象へ。
	GameState.mark_equipment_new(inst)
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
