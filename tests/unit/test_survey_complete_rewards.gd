extends GutTest

## P3-SURVEY-COMPLETE-001 — 完全調査一回限り景品。

const _SurveyCompleteRewards := preload("res://scripts/survey/SurveyCompleteRewards.gd")
const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
const _PetSystem := preload("res://scripts/pets/PetSystem.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		GameState.select_starting_adventurer("adventurer_0")
	GameState.hub_survey_progress = {}
	GameState.hub_survey_complete_claimed = {}
	GameState.owned_pet_ids = ["pet_jack"]
	GameState.ticket_inventory = {}
	GameState.gold = 0
	GameState.gacha_token = 0
	GameState.material_inventory = {}


func test_mourngate_complete_grants_gacha_ticket() -> void:
	GameState.hub_survey_progress["mourngate"] = 100.0
	var r: Dictionary = _SurveyCompleteRewards.try_claim("mourngate", false)
	assert_true(bool(r.get("ok", false)), str(r))
	assert_eq(int(r.get("token", 0)), 30)
	assert_eq(int(r.get("gold", 0)), 500)
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 1)
	assert_true(_SurveyCompleteRewards.is_claimed("mourngate"))
	var again: Dictionary = _SurveyCompleteRewards.try_claim("mourngate", false)
	assert_false(bool(again.get("ok", true)))


func test_whisperwood_complete_grants_pack_and_ash() -> void:
	GameState.hub_survey_progress["whisperwood"] = 99.0
	_SurveySystem.add_survey_percent("whisperwood", 2.0, false)
	assert_true(_PetSystem.owns_pet("pet_ash"))
	assert_true(_SurveyCompleteRewards.is_claimed("whisperwood"))
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 1)
	assert_gte(GameState.gold, 800)
	assert_gte(GameState.gacha_token, 50)


func test_mistfen_complete_grants_lb_star2() -> void:
	GameState.hub_survey_progress["mistfen"] = 100.0
	var r: Dictionary = _SurveyCompleteRewards.try_claim("mistfen", false)
	assert_true(bool(r.get("ok", false)), str(r))
	assert_eq(TicketInventory.get_qty(TicketIds.LB_STAR2), 1)


func test_blackshore_complete_grants_lb_star3_and_ink() -> void:
	GameState.hub_survey_progress["blackshore"] = 100.0
	_PetSystem.sync_unlocks_from_survey_progress(false)
	var r: Dictionary = _SurveyCompleteRewards.try_claim("blackshore", false)
	assert_true(bool(r.get("ok", false)), str(r))
	assert_true(_PetSystem.owns_pet("pet_ink"))
	assert_eq(TicketInventory.get_qty(TicketIds.LB_STAR3), 1)


func test_frostridge_complete_grants_lb_star3() -> void:
	GameState.hub_survey_progress["frostridge"] = 100.0
	var r: Dictionary = _SurveyCompleteRewards.try_claim("frostridge", false)
	assert_true(bool(r.get("ok", false)), str(r))
	assert_eq(TicketInventory.get_qty(TicketIds.LB_STAR3), 1)
	## 外れは★2、当たりは★4。どちらかが付く。
	var lb2: int = TicketInventory.get_qty(TicketIds.LB_STAR2)
	var lb4: int = TicketInventory.get_qty(TicketIds.LB_STAR4)
	assert_true(lb2 + lb4 >= 1)


func test_preview_entries_include_chance_notes() -> void:
	var bs: Array[Dictionary] = _SurveyCompleteRewards.preview_entries("blackshore")
	var has_lb4_note: bool = false
	for e in bs:
		if str(e.get("id", "")) == TicketIds.LB_STAR4 and str(e.get("chance_note", "")) == "3%":
			has_lb4_note = true
	assert_true(has_lb4_note)
	var fr: Array[Dictionary] = _SurveyCompleteRewards.preview_entries("frostridge")
	var has_8: bool = false
	for e in fr:
		if str(e.get("chance_note", "")) == "8%":
			has_8 = true
	assert_true(has_8)
