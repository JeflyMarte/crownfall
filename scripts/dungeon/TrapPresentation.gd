class_name TrapPresentation
extends RefCounted

## 罠部屋・探索罠の演出 SSOT（P3-UX-TRAP-001 / P3-UX-TRAP-002）。

const ROOM_BG_SETUP_PATH: String = "res://assets/dungeon/common/trap/BG_Room_Trap_Setup.png"
const ROOM_BG_HIT_PATH: String = "res://assets/dungeon/common/trap/BG_Room_Trap_Hit.png"
const ROOM_BG_AVOID_PATH: String = "res://assets/dungeon/common/trap/BG_Room_Trap_Avoid.png"
## 後方互換（旧名）
const ROOM_BG_PATH: String = ROOM_BG_SETUP_PATH
const TRIGGER_CHANCE: float = 0.5

const COLOR_AVOID: Color = Color(0.45, 0.92, 0.58)
const COLOR_HIT: Color = Color(1.0, 0.35, 0.35)

const SETUP_LINES: Array[String] = [
	"床石の綴ぎ目から、かすかな金属音が漏れている…",
	"通路の影が、不自然に細く歪んでいる…",
	"朽ちた壁に、古い機括の楔が並んでいる…",
	"足元の砂塵だけが、無風なのに舞い上がった…",
]
const HIT_LINES: Array[String] = [
	"遅れた足が、棘の罠を踏み抜いた！",
	"床板が沈み、鋭い杭が影を穿った！",
	"古いワイヤーが跳ね上がり、肉を裂いた！",
]
const HIT_LINES_AOE: Array[String] = [
	"通路全体に棘が噴き出した！",
	"天井の機括が砕け、瓦礫が降り注いだ！",
	"床が一斉に落ち、杭の嵐がパーティを襲った！",
]
const AVOID_LINES: Array[String] = [
	"全員が間一髪で退いた。機括は沈黙に戻った。",
	"斥候の合図の直後、罠だけが空を切った。",
	"粘った音を立てて針が落ちたが、誰も捉えずに終わった。",
]

const ROOM_DMG_SCALE: float = 1.35
const EXPLORE_DMG_SCALE: float = 1.2
const SHAKE_INTENSITY: float = 5.0
const ALERT_ALPHAS: Array[float] = [0.32, 0.22, 0.14]
const ALERT_ALPHAS_FAST: Array[float] = [0.16, 0.11]


static func timings(fast_run: bool) -> Dictionary:
	if fast_run:
		return {"setup_hold": 0.72}
	return {"setup_hold": 1.25}


static func bg_path_for_phase(phase: String) -> String:
	match phase:
		"hit":
			return ROOM_BG_HIT_PATH
		"avoid":
			return ROOM_BG_AVOID_PATH
		_:
			return ROOM_BG_SETUP_PATH


static func pick_setup_line(rng: RandomNumberGenerator = null) -> String:
	return _pick_line(SETUP_LINES, rng)


static func pick_hit_line(rng: RandomNumberGenerator = null) -> String:
	return _pick_line(HIT_LINES, rng)


static func pick_hit_line_aoe(rng: RandomNumberGenerator = null) -> String:
	return _pick_line(HIT_LINES_AOE, rng)


static func pick_avoid_line(rng: RandomNumberGenerator = null) -> String:
	return _pick_line(AVOID_LINES, rng)


static func is_triggered(rng: RandomNumberGenerator = null) -> bool:
	if rng != null:
		return rng.randf() < TRIGGER_CHANCE
	return randf() < TRIGGER_CHANCE


static func format_hit_narrative(hit_line: String, member_name: String, dmg: int) -> String:
	return "%s\n%s に %d ダメージ！" % [hit_line, member_name, dmg]


static func format_aoe_hit_narrative(hit_line: String, hit_count: int) -> String:
	return "%s\nパーティ全体に罠ダメージ！（%d人）" % [hit_line, hit_count]


static func pulse_count(trap_room: bool, fast_run: bool) -> int:
	if fast_run:
		return 2
	return 3 if trap_room else 2


static func damage_scale(trap_room: bool) -> float:
	return ROOM_DMG_SCALE if trap_room else EXPLORE_DMG_SCALE


static func peak_alphas(trap_room: bool, fast_run: bool) -> Array[float]:
	var pulses: int = pulse_count(trap_room, fast_run)
	var source: Array[float] = ALERT_ALPHAS_FAST if fast_run else ALERT_ALPHAS
	var out: Array[float] = []
	for i: int in pulses:
		out.append(source[mini(i, source.size() - 1)])
	return out


static func _pick_line(lines: Array[String], rng: RandomNumberGenerator) -> String:
	if lines.is_empty():
		return ""
	if rng != null:
		return lines[rng.randi() % lines.size()]
	return lines[randi() % lines.size()]
