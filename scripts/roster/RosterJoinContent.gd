extends RefCounted
## 基本職の章加入キュー・文案（P3-JOIN-001）。

## 加入優先順（導入選択済みはスキップ）
const JOIN_ORDER: Array[String] = [
	"adventurer_3", # ガレン
	"adventurer_1", # リーヴァ
	"adventurer_2", # エリアス
	"adventurer_0", # アルド
	"adventurer_4", # ミレイ
]

## 初回クリアで次の未所持を pending する章
const JOIN_TRIGGER_STAGES: Array[String] = [
	"mourngate_1_1",
	"mourngate_1_2",
	"mourngate_1_3",
	"mourngate_1_5",
]

const PORTRAIT_BY_ID: Dictionary = {
	"adventurer_0": "res://assets/npc/ART_ADV_Aldo.png",
	"adventurer_1": "res://assets/npc/ART_ADV_Reeva.png",
	"adventurer_2": "res://assets/npc/ART_ADV_Elias.png",
	"adventurer_3": "res://assets/npc/ART_ADV_Galen.png",
	"adventurer_4": "res://assets/npc/ART_ADV_Mirei.png",
}

const NINA_BRIDGE: String = "適任の調査員を連れてきました。自己紹介をお願いします。"

const LINES_BY_ID: Dictionary = {
	"adventurer_0": [
		"アルドです。剣はそこそこ使えます。…たぶん。",
		"隊長の方針に合わせます。危ない場所は、先に出ます。",
		"生き残って、記録を持ち帰れば勝ち——それでいいですよね。",
	],
	"adventurer_1": [
		"リーヴァ。道と音は、私の担当で。",
		"地図に無い線を拾うのが好きなんです。危ない線も含めて。",
		"遠くだから、詳しい話はあとで。まず編成に入れて。",
	],
	"adventurer_2": [
		"エリアス。試料と記録が主戦場です。",
		"刃より瓶のほうが、真実に近いこともある。",
		"危険な反応は止めます。…止めきれないときもありますが。",
	],
	"adventurer_3": [
		"ガレン。盾番です。派手なことはしません。",
		"隊が崩れる瞬間を、潰すのが仕事です。",
		"任せてください。前は、私が受けます。",
	],
	"adventurer_4": [
		"ミレイ。生き物の側の人、です。",
		"咆哮も足跡も、一応・会話のうち。",
		"変な目で見ないでください。……まあ、普通は見ますね。",
	],
}


static func is_join_trigger_stage(stage_id: String) -> bool:
	return JOIN_TRIGGER_STAGES.has(stage_id)


static func next_unjoined_id() -> String:
	for adv_id: String in JOIN_ORDER:
		if GameState.find_roster_member_by_id(adv_id) == null:
			return adv_id
	return ""


static func get_lines(adventurer_id: String) -> Array[String]:
	var raw: Variant = LINES_BY_ID.get(adventurer_id, [])
	var out: Array[String] = []
	if raw is Array:
		for line: Variant in raw:
			out.append(str(line))
	return out


static func get_portrait_path(adventurer_id: String) -> String:
	return str(PORTRAIT_BY_ID.get(adventurer_id, ""))


static func display_name_for(adventurer_id: String) -> String:
	var def: Variant = GameState.find_base_roster_def(adventurer_id)
	if def is Dictionary:
		return str(def.get("name", adventurer_id))
	return adventurer_id
