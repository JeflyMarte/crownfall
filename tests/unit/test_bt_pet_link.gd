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
	assert_true(learnable.has("apex_tame"))
	assert_false(learnable.has("beast_bite"))
	assert_false(learnable.has("alpha_strike"))
	assert_false(learnable.has("hex_bolt"))
	assert_false(learnable.has("venom_spray"), "猛毒噴霧は習得外（ORDER-001）")
	assert_not_null(DataRegistry.get_skill_data("pet_bond_rally"))
	assert_not_null(DataRegistry.get_skill_data("pet_command_fang"))
	assert_not_null(DataRegistry.get_skill_data("beast_vet_care"))
	assert_not_null(DataRegistry.get_skill_data("apex_tame"))
	var herd: Resource = DataRegistry.get_skill_data("herd_call")
	assert_eq(str(herd.display_name), "群れの號令")
	assert_eq(str(herd.target_type), "all_party")
	## Lv15＝獣医／Lv50＝極意調教（P3-SKILL-RG-BT-ORDER-001）
	var unlocks: Array = job.skill_unlocks
	assert_eq(unlocks.size(), 7, "職キット7本")
	var by_lv: Dictionary = {}
	for entry: Variant in unlocks:
		by_lv[int(entry.get("level", 0))] = str(entry.get("skill_id", ""))
	assert_eq(str(by_lv.get(15, "")), "beast_vet_care")
	assert_eq(str(by_lv.get(50, "")), "apex_tame")
	assert_almost_eq(float(DataRegistry.get_skill_data("apex_tame").cooldown), 24.0, 0.001)


func test_mirei_poison_fang_and_pack_instinct() -> void:
	var mirei: Dictionary = CombatPassives.get_def("mirei_swarm_resonance")
	assert_eq(str(mirei.get("display_name", "")), "毒牙")
	assert_eq(str(mirei.get("effect", "")), "random_enemy_status")
	assert_true(mirei.get("status_pool", []).has("poison"))
	assert_almost_eq(float(mirei.get("status_chance", 0.0)), 0.28, 0.001)
	assert_false(mirei.has("pet_outgoing_mult"))
	var pack: Dictionary = CombatPassives.get_def("pack_instinct")
	assert_eq(str(pack.get("display_name", "")), "群れの指揮")
	assert_eq(float(pack.get("pet_outgoing_mult", 1.0)), 1.10)


func test_pet_outgoing_mult_from_neri_not_mirei() -> void:
	## ミレイ単体ではペット倍率なし。ネリ編成で ×1.25。
	assert_almost_eq(CombatPassives.pet_outgoing_mult_from_party(), 1.0, 0.001)
	var neri: Resource = Adventurer.new()
	neri.id = "gacha_helper_o"
	neri.job_id = "beast_tamer"
	GameState.party_members = [neri]
	assert_almost_eq(CombatPassives.pet_outgoing_mult_from_party(), 1.25, 0.001)
