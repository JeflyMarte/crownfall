extends GutTest

## P3-CHR-OMIT-001 / P3-GACHA-ENABLE-001 — ガチャ助っ人の有効化と omit 経路。

func test_gacha_helpers_playable_flag_default() -> void:
	assert_true(Constants.GACHA_HELPERS_PLAYABLE)
	assert_true(Constants.are_gacha_helpers_playable())

func test_gacha_helper_can_join_roster_when_enabled() -> void:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var helper_adv = adventurer_class.new()
	helper_adv.id = "gacha_helper_a"
	helper_adv.display_name = "TestHelper"
	helper_adv.job_id = "swordsman"
	var before: int = GameState.roster.size()
	GameState.add_roster_member(helper_adv)
	assert_eq(GameState.roster.size(), before + 1, "有効時は gacha_ 追加可")
	# 後始末（他テスト汚染防止）
	GameState.roster.erase(helper_adv)
	if GameState.party_members.has(helper_adv):
		GameState.party_members.erase(helper_adv)

func test_omit_is_noop_when_playable() -> void:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var helper_adv = adventurer_class.new()
	helper_adv.id = "gacha_helper_omit_probe"
	helper_adv.display_name = "OmitProbe"
	helper_adv.job_id = "ranger"
	GameState.add_roster_member(helper_adv)
	GameState.omit_gacha_helpers_from_roster()
	var still_present: bool = false
	for adv in GameState.roster:
		if adv != null and str(adv.id) == "gacha_helper_omit_probe":
			still_present = true
			break
	assert_true(still_present, "PLAYABLE 時は omit が no-op")
	GameState.roster.erase(helper_adv)

func test_gacha_pull_allowed_when_enabled() -> void:
	assert_true(Constants.are_gacha_helpers_playable())
	GameState.gacha_token = 10
	var owned_before: int = GameState.owned_helpers.size()
	var result: Dictionary = GachaSystem.pull()
	assert_true(bool(result.get("ok", false)), "ENABLE 時は pull 可能")
	assert_true(str(result.get("helper_id", "")) != "")
	assert_gte(GameState.owned_helpers.size(), owned_before)
