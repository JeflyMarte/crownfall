class_name UltimatePresentation
extends RefCounted

## 必殺技シネマ演出 SSOT（P3-UX-ULT-001）。

const COLOR_TITLE: Color = Color(1.0, 0.92, 0.55)
const COLOR_NAME_ATTACK: Color = Color(1.0, 0.78, 0.22)
const COLOR_NAME_HEAL: Color = Color(0.65, 1.0, 0.82)
const COLOR_VIGNETTE_ATTACK: Color = Color(0.08, 0.04, 0.0, 0.42)
const COLOR_VIGNETTE_HEAL: Color = Color(0.02, 0.08, 0.05, 0.38)
const FLASH_ATTACK: Color = Color(1.0, 0.88, 0.45)
const FLASH_HEAL: Color = Color(0.55, 1.0, 0.72)

const TITLE_TEXT: String = "必殺技"


static func timings(fast_run: bool) -> Dictionary:
	if fast_run:
		return {
			"dim_in": 0.08,
			"telop_in": 0.10,
			"hold": 0.18,
			"impact": 0.12,
			"telop_out": 0.12,
			"shake": 8.0,
			"flash_in": 0.10,
			"flash_impact": 0.20,
		}
	return {
		"dim_in": 0.12,
		"telop_in": 0.14,
		"hold": 0.42,
		"impact": 0.18,
		"telop_out": 0.16,
		"shake": 12.0,
		"flash_in": 0.14,
		"flash_impact": 0.36,
	}


static func skill_telop_name(display_name: String) -> String:
	var trimmed: String = display_name.strip_edges()
	if trimmed.is_empty():
		return "！！"
	if trimmed.ends_with("！") or trimmed.ends_with("!"):
		return trimmed
	return "%s！！" % trimmed


static func is_heal_skill(skill_data: Resource) -> bool:
	return skill_data != null and str(skill_data.effect_type) == "heal"


static func name_color(skill_data: Resource) -> Color:
	if is_heal_skill(skill_data):
		return COLOR_NAME_HEAL
	return COLOR_NAME_ATTACK


static func vignette_color(skill_data: Resource) -> Color:
	if is_heal_skill(skill_data):
		return COLOR_VIGNETTE_HEAL
	return COLOR_VIGNETTE_ATTACK


static func flash_color(skill_data: Resource) -> Color:
	if is_heal_skill(skill_data):
		return FLASH_HEAL
	return FLASH_ATTACK
