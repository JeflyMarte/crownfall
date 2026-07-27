extends GutTest

## P3-JOB-EVO-OMIT-001 — ジョブ到達形はβ完全オミット。

const _EvolutionTraits = preload("res://scripts/systems/EvolutionTraits.gd")
const _JobEvolution = preload("res://scripts/systems/JobEvolution.gd")
const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")

func _make_member(job_id: String, evolved: bool = false, level: int = 30) -> Resource:
	var cls = load("res://scripts/domain/Adventurer.gd")
	var m = cls.new()
	m.id = "adventurer_test"
	m.job_id = job_id
	m.level = level
	m.is_evolved = evolved
	return m

func test_job_evolution_playable_flag_is_off() -> void:
	assert_false(Constants.JOB_EVOLUTION_PLAYABLE)

func test_cannot_evolve_while_omitted() -> void:
	var member: Resource = _make_member("swordsman", false, 99)
	assert_false(_JobEvolution.can_evolve(member))
	assert_false(_JobEvolution.evolve(member))
	assert_false(bool(member.is_evolved))

func test_traits_ignored_even_if_save_flag_set() -> void:
	var member: Resource = _make_member("ranger", true)
	assert_eq(_EvolutionTraits.for_member(member).size(), 0)
	GameState.party_members = [member]
	assert_eq(_EvolutionTraits.party_weapon_drop_mult(), 1.0)
	assert_eq(_EvolutionTraits.preview_for_job("swordsman").size(), 0)

func test_stat_display_keeps_base_job_name() -> void:
	var member: Resource = _make_member("swordsman", true)
	var mods: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	assert_eq(str(mods.get("display_name", "")), "ソードマン")
	assert_false(bool(mods.get("is_evolved", true)))

func test_evolved_name_hidden_while_omitted() -> void:
	var member: Resource = _make_member("swordsman", true)
	assert_eq(_JobEvolution.get_evolved_name(member), "")
