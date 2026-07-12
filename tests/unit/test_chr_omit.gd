extends GutTest

## P3-CHR-OMIT-001 — メイン5以外（ガチャ助っ人）オミット。

func test_gacha_helpers_playable_flag_default() -> void:
	assert_false(Constants.GACHA_HELPERS_PLAYABLE)
	assert_false(Constants.are_gacha_helpers_playable())

func test_omit_strips_gacha_from_roster() -> void:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var helper_adv = adventurer_class.new()
	helper_adv.id = "gacha_helper_a"
	helper_adv.display_name = "TestHelper"
	helper_adv.job_id = "swordsman"
	# フラグが false のとき add は拒否
	var before: int = GameState.roster.size()
	GameState.add_roster_member(helper_adv)
	assert_eq(GameState.roster.size(), before, "omit 中は gacha_ 追加不可")
	# 強制挿入後に omit で除去
	GameState.roster.append(helper_adv)
	GameState.party_members = [helper_adv]
	GameState.omit_gacha_helpers_from_roster()
	for adv in GameState.roster:
		assert_false(Constants.is_gacha_helper_id(str(adv.id)))
	for adv in GameState.party_members:
		assert_false(Constants.is_gacha_helper_id(str(adv.id)))
	assert_gt(GameState.party_members.size(), 0)

func test_gacha_pull_blocked_when_omitted() -> void:
	if Constants.are_gacha_helpers_playable():
		return
	GameState.gacha_token = 10
	var result: Dictionary = GachaSystem.pull()
	assert_false(bool(result.get("ok", true)))
	assert_eq(str(result.get("reason", "")), "omitted")
