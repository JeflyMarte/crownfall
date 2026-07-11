extends GutTest

## P3-EVO-VIS-001 — 進化 modulate 着色。

const _EvolutionVisual = preload("res://scripts/systems/EvolutionVisual.gd")

func _make_member(evolved: bool) -> Resource:
	var cls = load("res://scripts/domain/Adventurer.gd")
	var m = cls.new()
	m.job_id = "swordsman"
	m.is_evolved = evolved
	return m

func test_base_modulate_white_before_evolution() -> void:
	var member: Resource = _make_member(false)
	assert_eq(_EvolutionVisual.base_modulate(member), Color.WHITE)

func test_base_modulate_gold_after_evolution() -> void:
	var member: Resource = _make_member(true)
	assert_eq(_EvolutionVisual.base_modulate(member), _EvolutionVisual.MODULATE_EVOLVED)

func test_sprite_modulate_combines_status_tint() -> void:
	var member: Resource = _make_member(true)
	var statuses: Array = [{"effect_id": "poison"}]
	var tinted: Color = _EvolutionVisual.sprite_modulate(member, statuses)
	assert_ne(tinted, Color.WHITE)
	assert_ne(tinted, _EvolutionVisual.MODULATE_EVOLVED)

func test_portrait_modulate_dimmed_when_dead() -> void:
	var member: Resource = _make_member(true)
	assert_eq(
		_EvolutionVisual.portrait_modulate(member, false),
		_EvolutionVisual.MODULATE_DIMMED
	)
