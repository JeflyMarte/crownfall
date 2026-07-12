class_name EventPresentation
extends RefCounted

## イベント部屋テロップ演出 SSOT（P3-UX-EVENT-001）。

const COLOR_HEAL: Color = Color(0.35, 0.95, 0.48)
const COLOR_DAMAGE: Color = Color(1.0, 0.32, 0.28)
const COLOR_GOLD: Color = Color(1.0, 0.86, 0.28)
const COLOR_BUFF: Color = Color(1.0, 0.62, 0.22)
const COLOR_MATERIAL: Color = Color(1.0, 0.72, 0.28)
const COLOR_LORE: Color = Color(0.78, 0.62, 1.0)
const COLOR_NEUTRAL: Color = Color(0.92, 0.9, 0.86)

const SCENE_MAX_CHARS: int = 52
const SHAKE_NORMAL: float = 4.0
const SHAKE_FAST: float = 2.5
const BG_ALPHA: float = 0.52
const DIM_ALPHA: float = 0.30

const OUTCOME_BG_PATHS: Dictionary = {
	"heal": "res://assets/dungeon/common/event/BG_Event_Heal.png",
	"damage": "res://assets/dungeon/common/event/BG_Event_Damage.png",
	"gold": "res://assets/dungeon/common/event/BG_Event_Gold.png",
	"buff": "res://assets/dungeon/common/event/BG_Event_Buff.png",
	"material": "res://assets/dungeon/common/event/BG_Event_Material.png",
	"lore": "res://assets/dungeon/common/event/BG_Event_Lore.png",
}
const DEFAULT_BG_PATH: String = "res://assets/dungeon/common/event/BG_Event_Lore.png"


static func timings(fast_run: bool) -> Dictionary:
	if fast_run:
		return {
			"scene_fade_in": 0.10,
			"scene_hold": 0.38,
			"result_fade_in": 0.10,
			"result_hold": 0.42,
			"fade_out": 0.12,
			"pre_fx": 0.06,
			"fx": 0.12,
			"shake": SHAKE_FAST,
			"sparks": 18,
		}
	return {
		"scene_fade_in": 0.14,
		"scene_hold": 0.58,
		"result_fade_in": 0.12,
		"result_hold": 0.52,
		"fade_out": 0.16,
		"pre_fx": 0.10,
		"fx": 0.16,
		"shake": SHAKE_NORMAL,
		"sparks": 28,
	}


static func outcome_type(outcome: Dictionary) -> String:
	return str(outcome.get("type", "nothing"))


static func outcome_color(outcome_type_name: String) -> Color:
	match outcome_type_name:
		"heal":
			return COLOR_HEAL
		"damage":
			return COLOR_DAMAGE
		"gold":
			return COLOR_GOLD
		"buff":
			return COLOR_BUFF
		"material":
			return COLOR_MATERIAL
		"lore":
			return COLOR_LORE
		_:
			return COLOR_NEUTRAL


static func flash_color(outcome_type_name: String) -> Color:
	return outcome_color(outcome_type_name)


static func spark_amount(outcome_type_name: String) -> int:
	match outcome_type_name:
		"gold", "material":
			return 36
		"heal", "buff", "damage":
			return 28
		"lore":
			return 20
		_:
			return 16


static func format_scene_line(description: String) -> String:
	var text: String = description.strip_edges()
	if text.length() <= SCENE_MAX_CHARS:
		return text
	return text.substr(0, SCENE_MAX_CHARS - 1) + "…"


static func format_result_line(outcome: Dictionary) -> String:
	var type_name: String = outcome_type(outcome)
	match type_name:
		"heal":
			return "HP +%d" % int(outcome.get("amount", 0))
		"damage":
			return "HP -%d" % int(outcome.get("amount", 0))
		"gold":
			return "ゴールド +%d" % int(outcome.get("amount", 0))
		"buff":
			return "攻撃力 ×%.2f" % float(outcome.get("multiplier", 1.0))
		"material":
			var label: String = str(outcome.get("label", ""))
			if label.is_empty():
				label = "素材"
			return "%s ×%d" % [label, int(outcome.get("amount", 1))]
		"lore":
			return "【碑文】%s" % str(outcome.get("label", "記録"))
		_:
			return "—"


static func background_path(outcome_type_name: String) -> String:
	return str(OUTCOME_BG_PATHS.get(outcome_type_name, DEFAULT_BG_PATH))
