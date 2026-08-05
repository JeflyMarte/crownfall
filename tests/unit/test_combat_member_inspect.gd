extends GutTest

const _InspectHelper = preload("res://scripts/ui/CombatMemberInspectHelper.gd")
const _PetSystem = preload("res://scripts/pets/PetSystem.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()


func test_build_shows_equipped_skill_passive_and_ultimate() -> void:
	var member: Resource = GameState.find_roster_member_by_id("adventurer_0")
	assert_not_null(member)
	var detail: Dictionary = _InspectHelper.build(member)
	assert_eq(str(detail.get("name", "")), str(member.display_name))
	assert_gt((detail.get("skills", []) as Array).size(), 0)
	assert_gt((detail.get("passives", []) as Array).size(), 0)
	assert_false((detail.get("ultimate", {}) as Dictionary).is_empty())
	var skill: Dictionary = (detail["skills"] as Array)[0]
	assert_false(str(skill.get("effect", "")).is_empty())
	var passive: Dictionary = (detail["passives"] as Array)[0]
	assert_false(str(passive.get("description", "")).is_empty())


func test_pet_has_skill_but_no_ultimate() -> void:
	_PetSystem.grant_starter_pet()
	var pet: Resource = GameState.active_pet
	assert_not_null(pet)
	var detail: Dictionary = _InspectHelper.build(pet)
	assert_gt((detail.get("skills", []) as Array).size(), 0)
	assert_true((detail.get("ultimate", {}) as Dictionary).is_empty())
