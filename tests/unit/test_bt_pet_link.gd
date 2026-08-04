extends GutTest

## P3-BT-PET-LINK-001 — BTスキル／パッシブのペット連携

const _PetSystem = preload("res://scripts/pets/PetSystem.gd")

func before_each() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		assert_true(GameState.select_starting_adventurer("adventurer_4"))
	_PetSystem.grant_starter_pet()


func test_beast_tamer_learns_pet_skills() -> void:
	var job: Resource = DataRegistry.get_job_data("beast_tamer")
	assert_not_null(job)
	var learnable: Array = job.learnable_skill_ids
	assert_true(learnable.has("pet_bond_rally"))
	assert_true(learnable.has("pet_command_fang"))
	assert_true(learnable.has("beast_vet_care"))
	assert_true(learnable.has("herd_call"))
	assert_true(learnable.has("venom_spray"))
	assert_false(learnable.has("beast_bite"))
	assert_false(learnable.has("alpha_strike"))
	assert_false(learnable.has("hex_bolt"))
	assert_false(learnable.has("apex_tame"))
	assert_not_null(DataRegistry.get_skill_data("pet_bond_rally"))
	assert_not_null(DataRegistry.get_skill_data("pet_command_fang"))
	assert_not_null(DataRegistry.get_skill_data("beast_vet_care"))
	assert_not_null(DataRegistry.get_skill_data("venom_spray"))
	var herd: Resource = DataRegistry.get_skill_data("herd_call")
	assert_eq(str(herd.display_name), "群れの號令")
	assert_eq(str(herd.target_type), "all_party")
	## Lv50 到達技＝獣医の手当て（ペット厚め回復）
	var unlocks: Array = job.skill_unlocks
	assert_eq(unlocks.size(), 7, "職キット7本")
	var lv50: Dictionary = {}
	for entry: Variant in unlocks:
		if int(entry.get("level", 0)) == 50:
			lv50 = entry
			break
	assert_eq(str(lv50.get("skill_id", "")), "beast_vet_care")


func test_mirei_poison_fang_and_pack_instinct() -> void:
	var mirei: Dictionary = CombatPassives.get_def("mirei_swarm_resonance")
	assert_eq(str(mirei.get("display_name", "")), "毒牙の共鳴")
	assert_eq(str(mirei.get("status_id", "")), "poison")
	assert_almost_eq(float(mirei.get("status_chance", 0.0)), 0.20, 0.001)
	assert_almost_eq(float(mirei.get("pet_outgoing_mult", 1.0)), 1.5, 0.001)
	assert_almost_eq(float(mirei.get("pet_defense_mult", 1.0)), 1.5, 0.001)
	assert_almost_eq(float(mirei.get("pet_max_hp_mult", 1.0)), 1.5, 0.001)
	var pack: Dictionary = CombatPassives.get_def("pack_instinct")
	assert_eq(str(pack.get("display_name", "")), "群れの指揮")
	assert_eq(float(pack.get("pet_outgoing_mult", 1.0)), 1.10)


func test_pet_outgoing_mult_from_mirei() -> void:
	## ミレイ編成時はペット与ダメ ×1.5
	var mult: float = CombatPassives.pet_outgoing_mult_from_party()
	assert_almost_eq(mult, 1.5, 0.001)
