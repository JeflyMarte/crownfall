class_name EvolutionVisual
extends RefCounted

## ジョブ進化の見た目 SSOT（P3-EVO-VIS-001 MVP）。
## 進化済みキャラに modulate 着色で昇格感を付与する。

const MODULATE_EVOLVED: Color = Color(1.12, 1.05, 0.78)
const MODULATE_PORTRAIT_EVOLVED: Color = Color(1.1, 1.02, 0.82)
const MODULATE_DIMMED: Color = Color(0.55, 0.55, 0.55, 0.65)


static func is_evolved(member: Resource) -> bool:
	return member != null and bool(member.is_evolved)


static func base_modulate(member: Resource) -> Color:
	if is_evolved(member):
		return MODULATE_EVOLVED
	return Color.WHITE


static func portrait_modulate(member: Resource, alive: bool = true) -> Color:
	if not alive:
		return MODULATE_DIMMED
	if is_evolved(member):
		return MODULATE_PORTRAIT_EVOLVED
	return Color.WHITE


static func sprite_modulate(member: Resource, statuses: Array = []) -> Color:
	var base: Color = base_modulate(member)
	if statuses.is_empty():
		return base
	var status_tint: Color = CombatVfxManager.unit_tint_from_statuses(statuses)
	if status_tint == Color.WHITE:
		return base
	return Color(
		base.r * status_tint.r,
		base.g * status_tint.g,
		base.b * status_tint.b,
		base.a
	)
