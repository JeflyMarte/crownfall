extends GutTest

## P3-SURVEY-COMPLETE-001 — 完全調査景品（案A: 100%ごと付与→0%リセット）。

const _SurveyCompleteRewards := preload("res://scripts/survey/SurveyCompleteRewards.gd")
const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")


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


func test_mourngate_complete_grants_and_resets() -> void:
	GameState.hub_survey_progress["mourngate"] = 100.0
	var r: Dictionary = _SurveyCompleteRewards.try_claim("mourngate", false)
	assert_true(bool(r.get("ok", false)), str(r))
	assert_eq(int(r.get("token", 0)), 10)
	assert_eq(int(r.get("gold", 0)), 200)
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 1)
	assert_true(_SurveyCompleteRewards.is_claimed("mourngate"))
	assert_eq(_SurveySystem.get_survey_percent("mourngate"), 0.0, "付与後は0%")
	var again_empty: Dictionary = _SurveyCompleteRewards.try_claim("mourngate", false)
	assert_false(bool(again_empty.get("ok", true)), "0%では再付与しない")
	GameState.hub_survey_progress["mourngate"] = 100.0
	var again: Dictionary = _SurveyCompleteRewards.try_claim("mourngate", false)
	assert_true(bool(again.get("ok", false)), "2周目も資源は再付与")
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 2)
	assert_eq(GameState.gacha_token, 20)
	assert_eq(_SurveySystem.get_survey_percent("mourngate"), 0.0)


func test_whisperwood_complete_grants_pack_and_ash() -> void:
	GameState.hub_survey_progress["whisperwood"] = 99.0
	_SurveySystem.add_survey_percent("whisperwood", 2.0, false)
	assert_true(_PetSystem.owns_pet("pet_ash"))
	assert_true(_SurveyCompleteRewards.is_claimed("whisperwood"))
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 1)
	assert_gte(GameState.gold, 350)
	assert_gte(GameState.gacha_token, 15)
	assert_eq(_SurveySystem.get_survey_percent("whisperwood"), 0.0)


func test_second_cycle_does_not_regrant_ash() -> void:
	GameState.hub_survey_progress["whisperwood"] = 100.0
	var first: Dictionary = _SurveyCompleteRewards.try_claim("whisperwood", false)
	assert_true(bool(first.get("ok", false)))
	assert_eq(str(first.get("pet_id", "")), "pet_ash")
	assert_true(_PetSystem.owns_pet("pet_ash"))
	var preview_after: Array[Dictionary] = _SurveyCompleteRewards.preview_entries("whisperwood")
	for e in preview_after:
		assert_ne(str(e.get("kind", "")), "pet", "所持済みアッシュはプレビューに出ない")
	GameState.hub_survey_progress["whisperwood"] = 100.0
	var second: Dictionary = _SurveyCompleteRewards.try_claim("whisperwood", false)
	assert_true(bool(second.get("ok", false)))
	assert_eq(str(second.get("pet_id", "")), "", "2周目はペット欄が空")
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 2)


func test_mistfen_complete_lb_star2_is_chance_only() -> void:
	GameState.hub_survey_progress["mistfen"] = 100.0
	var r: Dictionary = _SurveyCompleteRewards.try_claim("mistfen", false)
	assert_true(bool(r.get("ok", false)), str(r))
	## ★2券は5%抽選。確定ではない。
	assert_lte(TicketInventory.get_qty(TicketIds.LB_STAR2), 1)
	assert_eq(int(r.get("token", 0)), 20)
	assert_eq(_SurveySystem.get_survey_percent("mistfen"), 0.0)


func test_blackshore_complete_grants_ink_lb_chance_only() -> void:
	GameState.hub_survey_progress["blackshore"] = 100.0
	var r: Dictionary = _SurveyCompleteRewards.try_claim("blackshore", false)
	assert_true(bool(r.get("ok", false)), str(r))
	assert_true(_PetSystem.owns_pet("pet_ink"))
	assert_eq(str(r.get("pet_id", "")), "pet_ink")
	## ★3/★4 は低確率。確定付与しない。
	assert_lte(TicketInventory.get_qty(TicketIds.LB_STAR3), 1)
	assert_lte(TicketInventory.get_qty(TicketIds.LB_STAR4), 1)
	GameState.hub_survey_progress["blackshore"] = 100.0
	var second: Dictionary = _SurveyCompleteRewards.try_claim("blackshore", false)
	assert_true(bool(second.get("ok", false)))
	assert_eq(str(second.get("pet_id", "")), "", "2周目はインクを再付与しない")


func test_frostridge_complete_lb_chance_only() -> void:
	GameState.hub_survey_progress["frostridge"] = 100.0
	var r: Dictionary = _SurveyCompleteRewards.try_claim("frostridge", false)
	assert_true(bool(r.get("ok", false)), str(r))
	assert_eq(int(r.get("token", 0)), 30)
	assert_lte(TicketInventory.get_qty(TicketIds.LB_STAR3), 1)
	assert_lte(TicketInventory.get_qty(TicketIds.LB_STAR4), 1)


func test_preview_entries_lb_rates() -> void:
	assert_eq(_SurveyCompleteRewards.P_LB_STAR2, 0.05)
	assert_eq(_SurveyCompleteRewards.P_LB_STAR3, 0.05)
	assert_eq(_SurveyCompleteRewards.P_LB_STAR4, 0.01)
	var bs: Array[Dictionary] = _SurveyCompleteRewards.preview_entries("blackshore")
	var has_lb3: bool = false
	var has_lb4: bool = false
	for e in bs:
		if str(e.get("id", "")) == TicketIds.LB_STAR3 and str(e.get("chance_note", "")) == "5%":
			has_lb3 = true
		if str(e.get("id", "")) == TicketIds.LB_STAR4 and str(e.get("chance_note", "")) == "1%":
			has_lb4 = true
	assert_true(has_lb3)
	assert_true(has_lb4)
	var fr: Array[Dictionary] = _SurveyCompleteRewards.preview_entries("frostridge")
	var has_fr4: bool = false
	for e in fr:
		if str(e.get("id", "")) == TicketIds.LB_STAR4 and str(e.get("chance_note", "")) == "1%":
			has_fr4 = true
	assert_true(has_fr4)
	var mf: Array[Dictionary] = _SurveyCompleteRewards.preview_entries("mistfen")
	var has_lb2: bool = false
	for e in mf:
		if str(e.get("id", "")) == TicketIds.LB_STAR2 and str(e.get("chance_note", "")) == "5%":
			has_lb2 = true
	assert_true(has_lb2)
	assert_eq(_SurveyCompleteRewards.preview_dedupe_key({"kind": "gold"}), "gold")
	assert_eq(_SurveyCompleteRewards.preview_chance_label({"kind": "gold", "qty": 500}), "確定")


func test_cycle_token_config_is_harsher() -> void:
	assert_eq(_SurveyConfig.TOKEN_GRANT_CHANCE, 0.40)
	assert_eq(_SurveyConfig.TOKEN_SHORT_MAX, 10)
	assert_eq(_SurveyConfig.TOKEN_STANDARD_MAX, 18)


func test_sync_claimed_at_100_resets_without_regrant() -> void:
	GameState.hub_survey_progress["mourngate"] = 100.0
	GameState.hub_survey_complete_claimed["mourngate"] = true
	GameState.gacha_token = 0
	_SurveyCompleteRewards.sync_all_pending(false)
	assert_eq(_SurveySystem.get_survey_percent("mourngate"), 0.0)
	assert_eq(GameState.gacha_token, 0, "旧セーブの100%滞留はリセットのみ")
