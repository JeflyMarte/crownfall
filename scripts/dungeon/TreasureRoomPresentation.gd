class_name TreasureRoomPresentation
extends RefCounted

## 宝箱部屋の演出 SSOT（P3-UX-TREASURE-001）。

const ROOM_BG_SETUP_PATH: String = "res://assets/dungeon/common/treasure/BG_Room_Treasure_Setup.png"
const ROOM_BG_SUCCESS_PATH: String = "res://assets/dungeon/common/treasure/BG_Room_Treasure_Success.png"
const ROOM_BG_FAIL_PATH: String = "res://assets/dungeon/common/treasure/BG_Room_Treasure_Fail.png"
const SUCCESS_CHANCE: float = 0.5
const FAILURE_GOLD_RATIO: float = 0.5

const COLOR_SUCCESS: Color = Color(1.0, 0.86, 0.28)
const COLOR_FAIL: Color = Color(0.72, 0.70, 0.66)

const SETUP_LINES: Array[String] = [
	"部屋の奥に、古びた宝箱が沈黙している…",
	"埃をかぶった金具が、かすかに光を反射した。",
	"崩れた祭壇の陰に、重い蓋の箱が置かれている…",
	"床に刻まれた紋章の先に、宝箱の気配がある。",
]
const SUCCESS_LINES: Array[String] = [
	"錠前が外れ、中から報酬が溢れ出した！",
	"蓋が開き、長い眠りから宝物が目を覚ました。",
	"宝箱は満ちていた。戦利品を回収した。",
]
const FAIL_LINES: Array[String] = [
	"箱は空だった。わずかなゴールドだけが残っていた。",
	"中身は朽ち、取れるものはほとんどなかった。",
	"罠の跡だけが残り、宝物は既に奪われていた。",
]


static func timings(fast_run: bool) -> Dictionary:
	if fast_run:
		return {"setup_hold": 0.72}
	return {"setup_hold": 1.25}


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


static func pick_success_line(rng: RandomNumberGenerator = null) -> String:
	return _pick_line(SUCCESS_LINES, rng)


static func pick_fail_line(rng: RandomNumberGenerator = null) -> String:
	return _pick_line(FAIL_LINES, rng)


static func is_successful(rng: RandomNumberGenerator = null) -> bool:
	if rng != null:
		return rng.randf() < SUCCESS_CHANCE
	return randf() < SUCCESS_CHANCE


static func failure_gold_amount(base_gold: int) -> int:
	return maxi(1, int(round(float(base_gold) * FAILURE_GOLD_RATIO)))


static func format_success_narrative(success_line: String, gold: int, accessory_name: String) -> String:
	var text: String = "%s\nゴールド +%d" % [success_line, gold]
	if not accessory_name.is_empty():
		text += "\n装飾品: %s" % accessory_name
	return text


static func format_fail_narrative(fail_line: String, gold: int) -> String:
	if gold <= 0:
		return fail_line
	return "%s\nゴールド +%d" % [fail_line, gold]


static func _pick_line(lines: Array[String], rng: RandomNumberGenerator) -> String:
	if lines.is_empty():
		return ""
	if rng != null:
		return lines[rng.randi() % lines.size()]
	return lines[randi() % lines.size()]
