class_name HealRoomPresentation
extends RefCounted

## 回復部屋の演出 SSOT（P3-UX-HEAL-001）。

const ROOM_BG_SETUP_PATH: String = "res://assets/dungeon/common/heal/BG_Room_Heal_Setup.png"
const ROOM_BG_SUCCESS_PATH: String = "res://assets/dungeon/common/heal/BG_Room_Heal_Success.png"
const ROOM_BG_FAIL_PATH: String = "res://assets/dungeon/common/heal/BG_Room_Heal_Fail.png"
const SUCCESS_CHANCE: float = 0.5

const COLOR_SUCCESS: Color = Color(0.35, 0.95, 0.48)
const COLOR_FAIL: Color = Color(0.72, 0.70, 0.66)

const SETUP_LINES: Array[String] = [
	"壁の隙間から、清らかな水気が漂ってくる…",
	"苔むした石に、湧き水の痕が光っている…",
	"床の亀裂から、微かな霊泉の音が聞こえる…",
	"古い祭壇の傍らに、澄んだ水たまりがある…",
]
const SUCCESS_LINES: Array[String] = [
	"霊泉の水が傷を癒した。",
	"清らかな水気が全身を満たし、疲れが抜けた。",
	"湧き水の恵みで、隊の傷が閉じていく…",
]
const FAIL_LINES: Array[String] = [
	"水は涸れており、何も得られなかった。",
	"霊気は残っていたが、傷を癒す力は失われていた。",
	"湧き水は濁っており、触れる勇気はなかった。",
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


static func format_success_narrative(success_line: String, heal_amount: int) -> String:
	return "%s\n生存メンバーを %d 回復した。" % [success_line, heal_amount]


static func _pick_line(lines: Array[String], rng: RandomNumberGenerator) -> String:
	if lines.is_empty():
		return ""
	if rng != null:
		return lines[rng.randi() % lines.size()]
	return lines[randi() % lines.size()]
