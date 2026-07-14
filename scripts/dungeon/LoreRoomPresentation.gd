class_name LoreRoomPresentation
extends RefCounted

## 碑文部屋の演出 SSOT（P3-UX-LORE-001）。

const ROOM_BG_SETUP_PATH: String = "res://assets/dungeon/common/lore/BG_Room_Lore_Setup.png"
const ROOM_BG_SUCCESS_PATH: String = "res://assets/dungeon/common/lore/BG_Room_Lore_Success.png"
const ROOM_BG_FAIL_PATH: String = "res://assets/dungeon/common/lore/BG_Room_Lore_Fail.png"
const SUCCESS_CHANCE: float = 0.5

const COLOR_SUCCESS: Color = Color(0.78, 0.62, 1.0)
const COLOR_FAIL: Color = Color(0.72, 0.70, 0.66)

const SETUP_LINES: Array[String] = [
	"壁面に、風化した刻印が浮かび上がっている…",
	"崩れた石碑に、古い言語の行が並んでいる…",
	"床石の綴ぎ目に、祈りの碑文が刻まれていた…",
	"朽ちた柱の根元に、読み取れない銘文が残っている…",
]
const FAIL_LINES: Array[String] = [
	"刻印は判読できなかった。図鑑には残らない。",
	"文字は摩耗しすぎて、意味を読み取れなかった。",
	"碑文の断片だけが残り、記録には至らなかった。",
]


static func timings(fast_run: bool) -> Dictionary:
	if fast_run:
		return {"setup_hold": 1.15}
	return {"setup_hold": 2.0}


static func bg_path_for_phase(phase: String) -> String:
	match phase:
		"success":
			return ROOM_BG_SUCCESS_PATH
		"fail":
			return ROOM_BG_FAIL_PATH
		_:
			return ROOM_BG_SETUP_PATH


static func pick_setup_line(rng: RandomNumberGenerator = null) -> String:
	return _pick_line(SETUP_LINES, rng)


static func pick_fail_line(rng: RandomNumberGenerator = null) -> String:
	return _pick_line(FAIL_LINES, rng)


static func is_deciphered(rng: RandomNumberGenerator = null) -> bool:
	if rng != null:
		return rng.randf() < SUCCESS_CHANCE
	return randf() < SUCCESS_CHANCE


static func _pick_line(lines: Array[String], rng: RandomNumberGenerator) -> String:
	if lines.is_empty():
		return ""
	if rng != null:
		return lines[rng.randi() % lines.size()]
	return lines[randi() % lines.size()]
