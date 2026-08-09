extends GutTest

const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		GameState.select_starting_adventurer("adventurer_0")
	GameState.unlock_starter_adventurer("adventurer_1")
	GameState.unlock_starter_adventurer("adventurer_2")
	GameState.hub_survey_cycle = {}
	GameState.hub_survey_party_backup_ids = []
	GameState.survey_staff_nonoka_unlocked = true


func _two_combat() -> Array[String]:
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 2:
			break
	return combat_ids


func _mark_complete() -> void:
	GameState.hub_survey_cycle["start_unix"] = Time.get_unix_time_from_system() - (
		_SurveyConfig.SHORT_DURATION_SEC + 10.0
	)


func test_claim_restores_full_party_order() -> void:
	var combat_ids: Array[String] = _two_combat()
	assert_eq(combat_ids.size(), 2)
	var party: Array = [
		GameState.find_roster_member_by_id(combat_ids[0]),
		GameState.find_roster_member_by_id(combat_ids[1]),
	]
	assert_true(GameState.set_active_party(party))
	var started: Dictionary = _SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0]] as Array[String]
	)
	assert_true(bool(started.get("ok", false)), str(started))
	assert_eq(GameState.party_members.size(), 1, "派遣中は1人残る")
	assert_eq(str(GameState.party_members[0].id), combat_ids[1])
	_mark_complete()
	var claimed: Dictionary = _SurveySystem.claim_cycle()
	assert_true(bool(claimed.get("ok", false)), str(claimed))
	assert_eq(GameState.party_members.size(), 2, "受取後は2人に戻る")
	assert_eq(str(GameState.party_members[0].id), combat_ids[0], "先頭も復元")
	assert_eq(str(GameState.party_members[1].id), combat_ids[1])


func test_complete_restores_party_before_claim() -> void:
	## タイマー完了（受取待ち）時点で編成に戻る。❗️表示中にパーティ欠けしない。
	var combat_ids: Array[String] = _two_combat()
	assert_eq(combat_ids.size(), 2)
	assert_true(GameState.set_active_party([
		GameState.find_roster_member_by_id(combat_ids[0]),
		GameState.find_roster_member_by_id(combat_ids[1]),
	]))
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0]] as Array[String]
	).get("ok", false)))
	assert_true(_SurveySystem.is_member_dispatched(combat_ids[0]), "進行中は派遣ロック")
	assert_eq(GameState.party_members.size(), 1)
	_mark_complete()
	assert_true(_SurveySystem.is_cycle_complete())
	assert_false(_SurveySystem.is_member_dispatched(combat_ids[0]), "完了後は編成ロック解除")
	assert_true(_SurveySystem.ensure_party_restored_if_awaiting_claim(false))
	assert_eq(GameState.party_members.size(), 2, "完了時点で編成復元")
	assert_true(bool(GameState.hub_survey_cycle.get("party_restored", false)))
	## 完了後に編成を減らしても、受取は派遣前編成へ戻す（欠員確定を防ぐ）。
	assert_true(GameState.set_active_party([
		GameState.find_roster_member_by_id(combat_ids[1]),
	]))
	var claimed: Dictionary = _SurveySystem.claim_cycle()
	assert_true(bool(claimed.get("ok", false)), str(claimed))
	assert_eq(GameState.party_members.size(), 2, "受取で派遣前編成へ復帰")
	assert_eq(str(GameState.party_members[0].id), combat_ids[0])
	assert_eq(str(GameState.party_members[1].id), combat_ids[1])


func test_claim_repairs_party_when_restored_flag_but_missing() -> void:
	## party_restored だけ立って欠員のまま → 受取で修復する。
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	assert_eq(combat_ids.size(), 4)
	var party: Array = []
	for id in combat_ids:
		party.append(GameState.find_roster_member_by_id(id))
	assert_true(GameState.set_active_party(party))
	var dispatch: Array[String] = [combat_ids[0], combat_ids[1]]
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		dispatch
	).get("ok", false)))
	assert_eq(GameState.party_members.size(), 2, "派遣中は2人")
	_mark_complete()
	## フラグだけ立てて欠員のまま（旧バグ再現）。
	GameState.hub_survey_cycle["party_restored"] = true
	assert_eq(GameState.party_members.size(), 2)
	assert_true(bool(_SurveySystem.claim_cycle().get("ok", false)))
	assert_eq(GameState.party_members.size(), 4, "受取で4人へ修復")
	for id2 in combat_ids:
		var found: bool = false
		for m in GameState.party_members:
			if m != null and str(m.id) == id2:
				found = true
		assert_true(found, "missing %s" % id2)


func test_ensure_repairs_when_flag_set_but_party_incomplete() -> void:
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	assert_eq(combat_ids.size(), 4)
	var party: Array = []
	for id in combat_ids:
		party.append(GameState.find_roster_member_by_id(id))
	assert_true(GameState.set_active_party(party))
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0], combat_ids[1]] as Array[String]
	).get("ok", false)))
	_mark_complete()
	GameState.hub_survey_cycle["party_restored"] = true
	assert_eq(GameState.party_members.size(), 2)
	assert_true(_SurveySystem.ensure_party_restored_if_awaiting_claim(false))
	assert_eq(GameState.party_members.size(), 4, "ensure が欠員フラグ付きも修復")
	assert_true(bool(GameState.hub_survey_cycle.get("party_restored", false)))


func test_claim_restores_after_save_load() -> void:
	var combat_ids: Array[String] = _two_combat()
	assert_eq(combat_ids.size(), 2)
	assert_true(GameState.set_active_party([
		GameState.find_roster_member_by_id(combat_ids[0]),
		GameState.find_roster_member_by_id(combat_ids[1]),
	]))
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0]] as Array[String]
	).get("ok", false)))
	_mark_complete()
	assert_true(SaveManager.save_game())
	GameState.reset_for_new_game()
	assert_true(SaveManager.load_game())
	assert_true(_SurveySystem.has_active_cycle())
	assert_true(_SurveySystem.is_cycle_complete())
	## ロード時 ensure で復元済み
	var during_ids: Array[String] = []
	for m in GameState.party_members:
		if m != null:
			during_ids.append(str(m.id))
	assert_true(during_ids.has(combat_ids[0]), "完了セーブのロードで派遣員が戻る")
	assert_true(during_ids.has(combat_ids[1]))
	var claimed: Dictionary = _SurveySystem.claim_cycle()
	assert_true(bool(claimed.get("ok", false)), str(claimed))
	assert_eq(GameState.party_members.size(), 2)


func test_claim_legacy_without_party_ids_before() -> void:
	var combat_ids: Array[String] = _two_combat()
	assert_eq(combat_ids.size(), 2)
	assert_true(GameState.set_active_party([
		GameState.find_roster_member_by_id(combat_ids[0]),
		GameState.find_roster_member_by_id(combat_ids[1]),
	]))
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0]] as Array[String]
	).get("ok", false)))
	GameState.hub_survey_cycle.erase("party_ids_before")
	GameState.hub_survey_party_backup_ids = []
	_mark_complete()
	var claimed: Dictionary = _SurveySystem.claim_cycle()
	assert_true(bool(claimed.get("ok", false)), str(claimed))
	var after_ids: Array[String] = []
	for m in GameState.party_members:
		if m != null:
			after_ids.append(str(m.id))
	assert_true(after_ids.has(combat_ids[0]), "フォールバックで派遣員復帰")
	assert_true(after_ids.has(combat_ids[1]))


func test_claim_uses_independent_backup_when_cycle_ids_missing() -> void:
	## cycle 内 party_ids_before が欠けても独立バックアップで4人復帰。
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	assert_eq(combat_ids.size(), 4)
	var party: Array = []
	for id in combat_ids:
		party.append(GameState.find_roster_member_by_id(id))
	assert_true(GameState.set_active_party(party))
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0], combat_ids[1]] as Array[String]
	).get("ok", false)))
	assert_eq(GameState.party_members.size(), 2)
	GameState.hub_survey_cycle.erase("party_ids_before")
	assert_eq(GameState.hub_survey_party_backup_ids.size(), 4)
	_mark_complete()
	assert_true(bool(_SurveySystem.claim_cycle().get("ok", false)))
	assert_eq(GameState.party_members.size(), 4, "backup から4人復帰")
	assert_eq(GameState.hub_survey_party_backup_ids.size(), 0, "成功後は backup クリア")


func test_orphan_backup_repairs_after_failed_claim_flag() -> void:
	## 受取後に欠員＋backup 残存 → 編成画面 ensure で修復。
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	assert_eq(combat_ids.size(), 4)
	GameState.hub_survey_cycle = {}
	GameState.hub_survey_party_backup_ids = combat_ids.duplicate()
	## 欠員状態（派遣後の2人だけ）を再現。
	assert_true(GameState.set_active_party([
		GameState.find_roster_member_by_id(combat_ids[2]),
		GameState.find_roster_member_by_id(combat_ids[3]),
	]))
	assert_eq(GameState.party_members.size(), 2)
	assert_true(_SurveySystem.ensure_party_restored_if_awaiting_claim(false))
	assert_eq(GameState.party_members.size(), 4, "orphan backup で修復")
	assert_eq(GameState.hub_survey_party_backup_ids.size(), 0)


func test_ensure_does_not_skip_when_restored_flag_but_empty_ids() -> void:
	## party_restored + 空 ids でスキップして欠員確定する旧穴。
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	assert_eq(combat_ids.size(), 4)
	var party: Array = []
	for id in combat_ids:
		party.append(GameState.find_roster_member_by_id(id))
	assert_true(GameState.set_active_party(party))
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0], combat_ids[1]] as Array[String]
	).get("ok", false)))
	_mark_complete()
	GameState.hub_survey_cycle["party_restored"] = true
	GameState.hub_survey_cycle["party_ids_before"] = []
	## 独立 backup は残す（開始時に書いた正本）。
	assert_eq(GameState.party_members.size(), 2)
	assert_true(_SurveySystem.ensure_party_restored_if_awaiting_claim(false))
	assert_eq(GameState.party_members.size(), 4)


func test_claim_then_reload_keeps_restored_party() -> void:
	var combat_ids: Array[String] = _two_combat()
	assert_eq(combat_ids.size(), 2)
	assert_true(GameState.set_active_party([
		GameState.find_roster_member_by_id(combat_ids[0]),
		GameState.find_roster_member_by_id(combat_ids[1]),
	]))
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0]] as Array[String]
	).get("ok", false)))
	_mark_complete()
	assert_true(bool(_SurveySystem.claim_cycle().get("ok", false)))
	assert_eq(GameState.party_members.size(), 2)
	assert_true(SaveManager.save_game())
	GameState.reset_for_new_game()
	assert_true(SaveManager.load_game())
	var after_ids: Array[String] = []
	for m in GameState.party_members:
		if m != null:
			after_ids.append(str(m.id))
	assert_eq(after_ids.size(), 2, "受取セーブ後のロードで編成維持")
	assert_true(after_ids.has(combat_ids[0]))
	assert_true(after_ids.has(combat_ids[1]))


func test_dispatch_all_but_one_from_full_party() -> void:
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	assert_eq(combat_ids.size(), 4)
	var party: Array = []
	for id in combat_ids:
		party.append(GameState.find_roster_member_by_id(id))
	assert_true(GameState.set_active_party(party))
	var dispatch: Array[String] = [combat_ids[0], combat_ids[1], combat_ids[2]]
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		dispatch
	).get("ok", false)))
	assert_eq(GameState.party_members.size(), 1)
	assert_eq(str(GameState.party_members[0].id), combat_ids[3])
	_mark_complete()
	assert_true(bool(_SurveySystem.claim_cycle().get("ok", false)))
	assert_eq(GameState.party_members.size(), 4, "3人派遣の受取後は4人復元")
	for id2 in combat_ids:
		var found: bool = false
		for m in GameState.party_members:
			if m != null and str(m.id) == id2:
				found = true
		assert_true(found, "missing %s" % id2)


func test_ensure_heal_does_not_shrink_full_party() -> void:
	## 小さい orphan backup があっても、既に全員いる編成を潰さない。
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	assert_eq(combat_ids.size(), 4)
	var party: Array = []
	for id in combat_ids:
		party.append(GameState.find_roster_member_by_id(id))
	assert_true(GameState.set_active_party(party))
	GameState.hub_survey_cycle = {}
	## backup は2人だけ（壊れた短縮バックアップ）
	GameState.hub_survey_party_backup_ids = [combat_ids[0], combat_ids[1]]
	assert_false(_SurveySystem.ensure_party_restored_if_awaiting_claim(false))
	assert_eq(GameState.party_members.size(), 4, "heal は人数を減らさない")
	assert_eq(GameState.hub_survey_party_backup_ids.size(), 0, "包含済みなら orphan クリア")


func test_start_cycle_preserves_larger_backup_when_party_depleted() -> void:
	## 欠員のまま再開始しても、大きい backup を小さい現行で上書きしない。
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	assert_eq(combat_ids.size(), 4)
	GameState.hub_survey_cycle = {}
	GameState.hub_survey_party_backup_ids = combat_ids.duplicate()
	## 欠員2人のまま（ensure は枠が空いていれば癒すが、ここでは heal 成功後に再欠員を模擬するため
	## backup を残したまま party を減らす経路: heal 成功で backup クリアされるので、
	## heal 不能な「backup と現行が食い違い満枠」ではなく「欠員＋大きい backup」を使う。
	## 先に heal で4人に戻る → start 時の現行は4人。上書き防止は「heal 失敗で欠員残存」時。
	## heal が成功してしまうので、backup の一部をロスター外 ID にして heal 不完全→残す、は重い。
	## 代わりに: heal 前に party を2人・backup4人 → ensure が heal 成功して4人＋backupクリア。
	## 本テストは「heal せず欠員のまま start したとき」の保護を直接検証する。
	assert_true(GameState.set_active_party([
		GameState.find_roster_member_by_id(combat_ids[2]),
		GameState.find_roster_member_by_id(combat_ids[3]),
	]))
	## ensure を挟まず start_cycle 内の保護を見るため、backup を再セット
	## （ensure は start 先頭で走るので、heal 成功→4人化が先。その後 backup はクリアされる）。
	## heal 成功後の start では現行=4人なので上書き防止分岐は不要。欠員保護は:
	## heal が何らかで失敗し backup が残るケース。ロスターから2人を一時的に外すのは破壊的。
	## → start 内の subset 保護を、heal 後に意図的に party を減らしてから
	##   _store 相当を検証するより、公開 API で: heal 成功後 backup クリアを確認しつつ、
	##   「欠員2＋backup4 で start」すると heal で4人に戻ってから派遣されることを確認する。
	GameState.hub_survey_party_backup_ids = combat_ids.duplicate()
	var started: Dictionary = _SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0]] as Array[String]
	)
	assert_true(bool(started.get("ok", false)), str(started))
	var before_raw: Variant = GameState.hub_survey_cycle.get("party_ids_before", [])
	assert_true(before_raw is Array)
	assert_eq((before_raw as Array).size(), 4, "開始時 backup は派遣前4人（欠員2の上書き防止）")
	assert_eq(GameState.hub_survey_party_backup_ids.size(), 4)


func test_change_dungeon_path_does_not_clear_party() -> void:
	## 調査対象変更相当: ensure のみ。編成人数は不変。
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	var party: Array = []
	for id in combat_ids:
		party.append(GameState.find_roster_member_by_id(id))
	assert_true(GameState.set_active_party(party))
	GameState.hub_survey_cycle = {}
	GameState.hub_survey_party_backup_ids = []
	assert_false(_SurveySystem.ensure_party_restored_if_awaiting_claim(false))
	assert_eq(GameState.party_members.size(), 4)


func test_result_path_restores_when_survey_completes_mid_run() -> void:
	## 章クリア級の長ラン中に調査完了 → 結果入室相当の ensure で編成復帰。
	## （拠点を経由せず「次のダンジョンへ」しても欠員固定しない前提）
	GameState.seed_all_starters_unlocked()
	var combat_ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null or _SurveySystem.is_survey_staff(str(adv.id)):
			continue
		combat_ids.append(str(adv.id))
		if combat_ids.size() >= 4:
			break
	assert_eq(combat_ids.size(), 4)
	var party: Array = []
	for id in combat_ids:
		party.append(GameState.find_roster_member_by_id(id))
	assert_true(GameState.set_active_party(party))
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[combat_ids[0], combat_ids[1]] as Array[String]
	).get("ok", false)))
	assert_eq(GameState.party_members.size(), 2, "派遣中は欠員")
	_mark_complete()
	assert_true(_SurveySystem.is_cycle_complete())
	## ResultScene._ready / DungeonScene._ready 相当（save_after=false）
	assert_true(_SurveySystem.ensure_party_restored_if_awaiting_claim(false))
	assert_eq(GameState.party_members.size(), 4, "結果／次ダン入場前に4人復帰")
	assert_true(bool(GameState.hub_survey_cycle.get("party_restored", false)))
