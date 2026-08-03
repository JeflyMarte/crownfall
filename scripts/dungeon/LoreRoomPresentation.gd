class_name LoreRoomPresentation
extends RefCounted

## 碑文部屋の演出 SSOT（P3-UX-LORE-001 / P3-UX-LORE-002）。

const ROOM_BG_SETUP_PATH: String = "res://assets/dungeon/common/lore/BG_Room_Lore_Setup.png"
const ROOM_BG_SUCCESS_PATH: String = "res://assets/dungeon/common/lore/BG_Room_Lore_Success.png"
const ROOM_BG_FAIL_PATH: String = "res://assets/dungeon/common/lore/BG_Room_Lore_Fail.png"
## 後方互換: ハード帯の判読率（ティア別は success_chance）。
## 記録を1件も持っていないときは初回保証で必ず成功（P3-UX-LORE-002）。
const SUCCESS_CHANCE: float = 0.8

const COLOR_SUCCESS: Color = Color(0.78, 0.62, 1.0)
const COLOR_FAIL: Color = Color(0.72, 0.70, 0.66)

const SETUP_LINES: Array[String] = [
	"壁面に、風化した刻印が浮かび上がっている…",
	"崩れた石碑に、古い言語の行が並んでいる…",
	"床石の綴ぎ目に、祈りの碑文が刻まれていた…",
	"朽ちた柱の根元に、読み取れない銘文が残っている…",
]
const FAIL_LINES: Array[String] = [
	"刻印を無理に辿ると、反動の呪詛が体を蝕んだ。",
	"判読に失敗し、古い気配が隊の一人を弱らせた。",
	"碑文は読めず、触れた者が脆い影に包まれた。",
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


static func pick_fail_line(rng: RandomNumberGenerator = null) -> String:
	return _pick_line(FAIL_LINES, rng)


static func success_chance(tier: int = 1) -> float:
	return BalanceConfig.lore_success_chance(tier)


static func is_deciphered(rng: RandomNumberGenerator = null, tier: int = 1) -> bool:
	## 図鑑「記録」が未所持なら必ず成功（初回保証）。
	if DiscoveryRegistry.count_by_category("lore") <= 0:
		return true
	var chance: float = success_chance(tier)
	if rng != null:
		return rng.randf() < chance
	return randf() < chance


static func format_success_narrative_bbcode(plain_lines: String) -> String:
	return NonCombatNarrativeColors.colorize_multiline(plain_lines)


static func format_fail_narrative_bbcode(fail_line: String, penalty_line: String = "") -> String:
	return NonCombatNarrativeColors.format_fail_bbcode(fail_line, penalty_line)


static func _pick_line(lines: Array[String], rng: RandomNumberGenerator) -> String:
	if lines.is_empty():
		return ""
	if rng != null:
		return lines[rng.randi() % lines.size()]
	return lines[randi() % lines.size()]
