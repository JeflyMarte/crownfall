class_name StarterJoinQuotes
extends RefCounted

## 章クリア後の拠点加入セリフ（P3-STORY-STARTER-001 hub ceremony）。

const JOIN_LINES: Dictionary = {
	"adventurer_0": "遅れたな。これからは前線を任せてくれ。",
	"adventurer_1": "……合流する。足手まといにはならないわ。",
	"adventurer_2": "薬も知恵も持ってきた。ギルドの調査、手伝わせてくれ。",
	"adventurer_3": "盾は預かった。お前たちの背中は、俺が守る。",
	"adventurer_4": "ジャックと一緒に来たよ。一緒にいこう！",
}


static func line_for(adventurer_id: String) -> String:
	var line: String = str(JOIN_LINES.get(adventurer_id, "")).strip_edges()
	if not line.is_empty():
		return line
	var def: Variant = GameState.find_base_roster_def(adventurer_id)
	if def is Dictionary:
		return "%sが調査隊に合流する。" % str(def.get("name", "仲間"))
	return "新たな仲間が調査隊に合流する。"
