extends GutTest

## P3-BAL-OMIT-EXPLORE-REWARD-001: 報酬4種オミット・罠解除は残る。

func test_reward_bonuses_disabled() -> void:
	assert_false(ExplorationSkills.REWARD_BONUSES_ENABLED)
	assert_true(ExplorationSkills.is_reward_skill("gather"))
	assert_true(ExplorationSkills.is_reward_skill("mine"))
	assert_true(ExplorationSkills.is_reward_skill("lockpick"))
	assert_true(ExplorationSkills.is_reward_skill("decipher"))
	assert_false(ExplorationSkills.is_reward_skill("disarm"))


func test_reward_skills_never_active_for_room() -> void:
	var members: Array = []
	assert_false(
		ExplorationSkills.has_skill_for_room(members, "mine", Enums.RoomType.TREASURE)
	)
	assert_false(
		ExplorationSkills.has_skill_for_room(members, "lockpick", Enums.RoomType.TREASURE)
	)
	assert_false(
		ExplorationSkills.has_skill_for_room(members, "decipher", Enums.RoomType.EVENT)
	)
	assert_false(
		ExplorationSkills.has_skill_for_room(members, "gather", Enums.RoomType.EVENT)
	)
