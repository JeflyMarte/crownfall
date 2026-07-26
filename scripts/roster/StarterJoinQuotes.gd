class_name StarterJoinQuotes
extends RefCounted

## 章クリア後の拠点加入セリフ（P3-STORY-STARTER-001 hub ceremony）。
## JOIN = 加入動機（ショーケース）。REVEAL = 合流確定後の一言（ガチャ風リビール）。

const JOIN_LINES: Dictionary = {
	"adventurer_0": (
		"会議より一歩先が性に合う。お前たちの調査隊なら、俺が先頭を切れると思った。"
	),
	"adventurer_1": (
		"足手まといにはならない。静かに地図を埋める仕事が欲しくて、この隊を選んだ。"
	),
	"adventurer_2": (
		"机の記録より、現場で薬を配りたい。ギルドの調査を、野で支えられる隊がここだと思った。"
	),
	"adventurer_3": (
		"調査が続くなら、誰かが盾を預かる必要がある。お前たちの背中を守るために来た。"
	),
	"adventurer_4": (
		"ジャックと一緒に、生き物の声が聞こえる場所へ行きたい。だからこの調査隊に入るよ。"
	),
}

## ロスター確定後。動機の繰り返しではなく、これからどう動くかの一言。
const REVEAL_LINES: Dictionary = {
	"adventurer_0": "遅れたな。これからは前線を任せてくれ。",
	"adventurer_1": "……合流した。合図は短くでいいわ。",
	"adventurer_2": "薬袋は開けてある。怪我人が出たら、すぐ呼んでくれ。",
	"adventurer_3": "盾は預かった。お前たちの背中は、俺が守る。",
	"adventurer_4": "ジャックも喜んでるよ。一緒にいこう！",
}


static func line_for(adventurer_id: String) -> String:
	return _line_from(JOIN_LINES, adventurer_id)


static func reveal_line_for(adventurer_id: String) -> String:
	return _line_from(REVEAL_LINES, adventurer_id)


static func _line_from(table: Dictionary, adventurer_id: String) -> String:
	var line: String = str(table.get(adventurer_id, "")).strip_edges()
	if not line.is_empty():
		return line
	var def: Variant = GameState.find_base_roster_def(adventurer_id)
	if def is Dictionary:
		return "%sが調査隊に合流する。" % str(def.get("name", "仲間"))
	return "新たな仲間が調査隊に合流する。"
