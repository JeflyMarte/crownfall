extends GutTest

## P3-EVO-TRAIT-001 — 昇格特質 + 進化 Lv30。

const _EvolutionTraits = preload("res://scripts/systems/EvolutionTraits.gd")
const _JobEvolution = preload("res://scripts/systems/JobEvolution.gd")

func _make_member(job_id: String, evolved: bool = false, level: int = 30) -> Resource:
	var cls = load("res://scripts/domain/Adventurer.gd")
	var m = cls.new()
	m.id = "adventurer_test"
	m.job_id = job_id
	m.level = level
	m.is_evolved = evolved
	return m

func test_evolution_requires_level_30() -> void:
	var member: Resource = _make_member("swordsman", false, 29)
	assert_false(_JobEvolution.can_evolve(member))
	member.level = 30
	assert_true(_JobEvolution.can_evolve(member))

func test_traits_empty_before_evolution() -> void:
	var member: Resource = _make_member("swordsman", false)
	assert_eq(_EvolutionTraits.for_member(member).size(), 0)

func test_traits_two_after_evolution() -> void:
	var member: Resource = _make_member("ranger", true)
	assert_eq(_EvolutionTraits.for_member(member).size(), 2)

func test_sniper_bounty_party_drop() -> void:
	GameState.party_members = [_make_member("ranger", true)]
	assert_eq(_EvolutionTraits.party_weapon_drop_mult(), 1.10)
	GameState.party_members = [_make_member("ranger", false)]
	assert_eq(_EvolutionTraits.party_weapon_drop_mult(), 1.0)

func test_lord_exp_party_mult() -> void:
	GameState.party_members = [_make_member("beast_tamer", true)]
	assert_eq(_EvolutionTraits.party_exp_mult(), 1.12)

func test_paladin_incoming_reduction() -> void:
	GameState.party_members = [_make_member("vanguard", true)]
	assert_eq(_EvolutionTraits.member_incoming_mult(0), 0.92)

func test_sage_heal_mult() -> void:
	GameState.party_members = [_make_member("alchemist", true)]
	assert_eq(_EvolutionTraits.member_heal_mult(0), 1.20)

func test_preview_has_two_per_job() -> void:
	assert_eq(_EvolutionTraits.preview_for_job("swordsman").size(), 2)
	assert_eq(_EvolutionTraits.preview_for_job("beast_tamer").size(), 2)
