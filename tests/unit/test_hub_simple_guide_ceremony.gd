extends GutTest

## はじめガイド完了儀式（ジャック支給・魔晶石500）

const _HubGuide := preload("res://scripts/ui/HubSimpleGuideOverlay.gd")
const _PetSystem := preload("res://scripts/pets/PetSystem.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		assert_true(GameState.select_starting_adventurer("adventurer_0"))


func test_new_game_starts_with_zero_tokens_and_no_jack() -> void:
	assert_eq(GameState.gacha_token, 0)
	assert_false(_PetSystem.is_starter_pet_granted())
	assert_null(GameState.active_pet)
	assert_eq(_HubGuide.PAGES.size(), 6)
	assert_true(str(_HubGuide.PAGES[5].get("body", "")).contains("ジャック"))


func test_guide_mark_done_queues_jack_grant() -> void:
	assert_true(_HubGuide.should_show())
	_HubGuide.mark_done()
	assert_false(_HubGuide.should_show())
	## BaseScene が pending を立てる想定。フラグのみでも未支給。
	assert_false(_PetSystem.is_starter_pet_granted())
	assert_eq(GameState.gacha_token, 0)


func test_grant_starter_pet_and_starting_tokens() -> void:
	_HubGuide.mark_done()
	var pet: Resource = _PetSystem.grant_starter_pet()
	assert_not_null(pet)
	assert_eq(str(pet.id), "pet_jack")
	assert_true(_PetSystem.is_starter_pet_granted())
	GameState.tutorial_flags["hub_starting_tokens_granted"] = true
	GameState.gacha_token += GachaSystem.STARTING_TOKENS
	assert_eq(GameState.gacha_token, GachaSystem.STARTING_TOKENS)


func test_jack_join_quotes_are_barks() -> void:
	const _Quotes := preload("res://scripts/roster/StarterJoinQuotes.gd")
	assert_eq(_Quotes.line_for("pet_jack"), "ワンッ！")
	assert_eq(_Quotes.reveal_line_for("pet_jack"), "ワンッ！")
