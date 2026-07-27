extends GutTest

## P3-EVO-TRAIT-001 — 昇格特質（データ残置）。プレイは JOB_EVOLUTION_PLAYABLE 依存。

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

func test_omit_blocks_evolution_api() -> void:
	## β既定はオミット（P3-JOB-EVO-OMIT-001）。
	assert_false(Constants.JOB_EVOLUTION_PLAYABLE)
	var member: Resource = _make_member("swordsman", false, 30)
	assert_false(_JobEvolution.can_evolve(member))
	assert_eq(_EvolutionTraits.for_member(_make_member("ranger", true)).size(), 0)

func test_trait_defs_still_exist_for_data() -> void:
	## データは残置。プレイOFF時は preview も空。
	assert_eq(_EvolutionTraits.preview_for_job("swordsman").size(), 0)
	assert_eq(_EvolutionTraits.preview_for_job("beast_tamer").size(), 0)
