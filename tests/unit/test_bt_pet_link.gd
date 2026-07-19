extends GutTest

## P3-BT-PET-LINK-001 — BTスキル／パッシブのオトモ連携

const _PetSystem = preload("res://scripts/pets/PetSystem.gd")

func before_each() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		assert_true(GameState.select_starting_adventurer("adventurer_4"))
	_PetSystem.ensure_starter_pet()


func test_beast_tamer_learns_pet_skills() -> void:
	var job: Resource = DataRegistry.get_job_data("beast_tamer")
	assert_not_null(job)
	var learnable: Array = job.learnable_skill_ids
	assert_true(learnable.has("pet_bond_rally"))
	assert_true(learnable.has("pet_command_fang"))
	assert_true(learnable.has("pet_bond_guard"))
	assert_true(learnable.has("herd_call"))
	assert_false(learnable.has("beast_bite"))
	assert_false(learnable.has("alpha_strike"))
	assert_false(learnable.has("apex_tame"))
	assert_not_null(DataRegistry.get_skill_data("pet_bond_rally"))
	assert_not_null(DataRegistry.get_skill_data("pet_command_fang"))
	assert_not_null(DataRegistry.get_skill_data("pet_bond_guard"))
	var herd: Resource = DataRegistry.get_skill_data("herd_call")
	assert_eq(str(herd.display_name), "群れの號令")


func test_mirei_and_pack_instinct_are_pet_outgoing() -> void:
	var mirei: Dictionary = CombatPassives.get_def("mirei_swarm_resonance")
	assert_eq(str(mirei.get("display_name", "")), "相棒共鳴")
	assert_eq(float(mirei.get("pet_outgoing_mult", 1.0)), 1.20)
	var pack: Dictionary = CombatPassives.get_def("pack_instinct")
	assert_eq(str(pack.get("display_name", "")), "群れの指揮")
	assert_eq(float(pack.get("pet_outgoing_mult", 1.0)), 1.10)


func test_pet_outgoing_mult_stacks_from_party() -> void:
	## ミレイ編成時は相棒共鳴で ×1.2
	var mult: float = CombatPassives.pet_outgoing_mult_from_party()
	assert_eq(mult, 1.20)
