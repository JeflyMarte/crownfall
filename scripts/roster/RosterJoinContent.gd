extends RefCounted
## 基本職の章加入キュー・文案（P3-JOIN-001）。

## 加入優先順（導入選択済みはスキップ）
const JOIN_ORDER: Array[String] = [
	"adventurer_3", # ガレン
	"adventurer_1", # リーヴァ
	"adventurer_2", # アイリス
	"adventurer_0", # アルド
	"adventurer_4", # ロアン
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
	"adventurer_2": "res://assets/npc/ART_ADV_Iris.png",
	"adventurer_3": "res://assets/npc/ART_ADV_Galen.png",
	"adventurer_4": "res://assets/npc/ART_ADV_Roan.png",
}

const NINA_BRIDGE: String = "見知った顔を連れてきました。口を合わせてもらいましょう。"

const LINES_BY_ID: Dictionary = {
	# 見た目は各職 idle ドット準拠（P3-JOIN-001b）
	"adventurer_0": [ # アルド／青外套の剣士
		"アルドだ。前衛、任せてくれ。",
		"派手なことはできないが、剣と足は離さない。",
		"隊長が指した道を、切って進む。それだけだ。",
	],
	"adventurer_1": [ # リーヴァ／緑フードの斥候
		"……リーヴァ。緑の匂いと、床の音は拾える。",
		"覗きすぎない距離で、先を見る。それが仕事。",
		"声は大きくしない。合図だけで、追いつけるよ。",
	],
	"adventurer_2": [ # アイリス／白髪紫外套の錬成屋
		"アイリスよ。瓶と記録が得意領域。",
		"刃物より、反応のほうが誠実なこと、あるわ。",
		"危ない調合は止める。……止まらない時は、後退を推奨するだけ。",
	],
	"adventurer_3": [ # ガレン／青金の盾騎士
		"ガレン。盾は、ここにある。",
		"獅子の紋は飾りだ。役割は単純——隊を崩さないこと。",
		"前は俺が受ける。隊長は方針だけ握っていてくれ。",
	],
	"adventurer_4": [ # ロアン／獣使い・相棒付き
		"ロアンだ。相棒も連れてきた。文句はあとでいい。",
		"吠え声も足跡も、俺には会話のうちだ。",
		"森でも地下でも、生きてるものには耳を貸す。任せておけ。",
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
