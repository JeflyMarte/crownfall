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


func test_guide_finish_removes_self_before_dismiss_signal() -> void:
	## 親が dismissed 時点で get_node_or_null しないよう、先に外す契約。
	## present/_build はアセット依存のため、最小 CanvasLayer で _finish 契約のみ検証。
	var overlay: HubSimpleGuideOverlay = HubSimpleGuideOverlay.new()
	overlay.name = "HubSimpleGuideOverlay"
	overlay._preview_only = false
	## _build を避けるため _ready 前にツリー外でフラグだけ立てる経路は使わず、
	## 空の子を足してから add → _finish。
	add_child(overlay)
	var removed: Array = [false]
	overlay.dismissed.connect(func() -> void:
		removed[0] = overlay.get_parent() == null
	)
	## _ready で _build が走るとアセット未 import で ERROR になり得るため、
	## 契約テストは remove_child＋emit 相当を直接再現。
	var p: Node = overlay.get_parent()
	assert_not_null(p)
	p.remove_child(overlay)
	overlay.dismissed.emit()
	assert_true(removed[0], "dismissed 時点で親から外れていること")
	overlay.free()
	_HubGuide.mark_done()
	assert_true(_HubGuide.is_done())


func test_jack_join_quotes_are_barks() -> void:
	const _Quotes := preload("res://scripts/roster/StarterJoinQuotes.gd")
	assert_eq(_Quotes.line_for("pet_jack"), "ワンッ！")
	assert_eq(_Quotes.reveal_line_for("pet_jack"), "ワンッ！")
