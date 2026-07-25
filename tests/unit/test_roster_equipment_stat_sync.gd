extends GutTest

## パーティ／キャラ画面のステ一致とスキル装備切替。

const _RosterUiHelper = preload("res://scripts/roster/RosterUiHelper.gd")
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _DebugFullUnlock = preload("res://scripts/debug/DebugFullUnlock.gd")


func before_each() -> void:
	GameState.reset_for_new_game()


func after_each() -> void:
	GameState.reset_for_new_game()


func test_roster_and_member_affix_stats_match() -> void:
	_DebugFullUnlock.apply()
	assert_gte(GameState.party_members.size(), 1)
	var member: Resource = GameState.party_members[0]
	var via_helper: Dictionary = _RosterUiHelper.compute_member_stats(member, -1)
	var via_party: Dictionary = _RosterUiHelper.compute_member_stats(member, 0)
	assert_eq(int(via_helper.get("hp", 0)), int(via_party.get("hp", 0)))
	assert_eq(int(via_helper.get("attack", 0)), int(via_party.get("attack", 0)))
	assert_eq(int(via_helper.get("defense", 0)), int(via_party.get("defense", 0)))
	var member_affix: Dictionary = _AffixStatCalculator.get_bonuses_for_member(member)
	var index_affix: Dictionary = _AffixStatCalculator.get_bonuses(0)
	assert_eq(int(member_affix.get("attack_flat", 0)), int(index_affix.get("attack_flat", 0)))
	assert_eq(int(member_affix.get("hp_flat", 0)), int(index_affix.get("hp_flat", 0)))


func test_skill_toggle_replaces_when_slot_full() -> void:
	_DebugFullUnlock.apply()
	assert_gte(GameState.party_members.size(), 1)
	var member: Resource = GameState.party_members[0]
	var unlocked: Array[String] = SkillProgression.get_unlocked_job_skill_ids(member)
	assert_gte(unlocked.size(), 2, "デバッグ LvMAX なら複数スキル解放のはず")
	GameState.toggle_member_skill(member, unlocked[0])
	assert_eq(GameState.get_equipped_skill_ids(member), [unlocked[0]] as Array[String])
	GameState.toggle_member_skill(member, unlocked[1])
	assert_eq(GameState.get_equipped_skill_ids(member), [unlocked[1]] as Array[String])
	assert_eq(Constants.MAX_EQUIPPED_SKILLS, 1)
