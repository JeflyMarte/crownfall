class_name HubDebugEvents
extends RefCounted

## 拠点デバッグメニュー用の演出トリガ（debug_full_unlock 時のみ UI から呼ぶ）。

const _StarterRecruitment := preload("res://scripts/roster/StarterRecruitment.gd")
const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _SurveyCompleteRewards := preload("res://scripts/survey/SurveyCompleteRewards.gd")

## メイン Biome の並び（表示用）。
const MAIN_BIOME_ORDER: PackedStringArray = [
	"mourngate",
	"whisperwood",
	"mistfen",
	"blackshore",
	"frostridge",
]


static func list_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append({
		"id": "section_clear",
		"title": "—— 章クリア加入ストーリー ——",
		"hint": "ニーナ功績→解放→加入予告→加入（③はノノカ合流も）",
		"section": true,
	})
	for biome_id in _main_biome_ids():
		var label: String = _biome_chapter5_label(biome_id)
		out.append({
			"id": "clear_ceremony:%s" % biome_id,
			"title": "%sクリア相当" % label,
			"hint": "加入ストーリー一式（解放済みでもプレビュー可）",
		})
	out.append({
		"id": "section_unlock",
		"title": "—— 解放ポップ ——",
		"hint": "バナー付き解放演出のみ",
		"section": true,
	})
	for biome_id in _main_biome_ids():
		if biome_id == Constants.MOURNGATE_DUNGEON_ID:
			continue
		out.append({
			"id": "dungeon_unlock:%s" % biome_id,
			"title": "解放：%s" % _dungeon_short_name(biome_id),
			"hint": "ダンジョン解放ポップを1件",
		})
	out.append({
		"id": "dungeon_unlock_hard_mourngate",
		"title": "解放：ハード・モーンゲート",
		"hint": "ハード入口解放ポップ",
	})
	out.append({
		"id": "dungeon_unlock_nm_mourngate",
		"title": "解放：ナイトメア・モーンゲート",
		"hint": "ナイトメア入口解放ポップ",
	})
	out.append({
		"id": "stage_unlock_popup",
		"title": "章解放ポップ",
		"hint": "章名の解放通知を1件",
	})
	out.append({
		"id": "section_survey_claim",
		"title": "—— 調査室受取 ——",
		"hint": "サイクル完了ポップ（付与なし）",
		"section": true,
	})
	out.append({
		"id": "survey_claim_result",
		"title": "調査完了",
		"hint": "分解完了同型の受取ポップをプレビュー",
	})
	out.append({
		"id": "section_survey",
		"title": "—— 完全調査報酬 ——",
		"hint": "景品ポップのみ（付与なし）",
		"section": true,
	})
	for biome_id in _main_biome_ids():
		if not _SurveyCompleteRewards.has_table(biome_id):
			continue
		out.append({
			"id": "survey_complete:%s" % biome_id,
			"title": "完全調査：%s" % _dungeon_short_name(biome_id),
			"hint": "確定景品内訳のポップを1件",
		})
	out.append({
		"id": "section_rare_nina",
		"title": "—— レア入手ニーナ ——",
		"hint": "初回ガイド／2回目以降の吹き出し",
		"section": true,
	})
	out.append_array([
		{
			"id": "nina_rare_guide:relic",
			"title": "初回：レリック入手後",
			"hint": "祝福＋説明オーバーレイ",
		},
		{
			"id": "nina_rare_guide:legendary",
			"title": "初回：レジェンド入手後",
			"hint": "祝福＋説明オーバーレイ",
		},
		{
			"id": "nina_rare_guide:mythic",
			"title": "初回：ミシック入手後",
			"hint": "祝福＋説明オーバーレイ",
		},
		{
			"id": "nina_rare_nav:relic",
			"title": "通知：レリック（2回目〜）",
			"hint": "メニュー吹き出しのみ",
		},
		{
			"id": "nina_rare_nav:legendary",
			"title": "通知：レジェンド（2回目〜）",
			"hint": "メニュー吹き出しのみ",
		},
		{
			"id": "nina_rare_nav:mythic",
			"title": "通知：ミシック（2回目〜）",
			"hint": "メニュー吹き出しのみ",
		},
		{
			"id": "nina_rare_flags_reset",
			"title": "レア入手ガイドフラグをリセット",
			"hint": "初回ガイドを再度出せるようにする",
		},
		{
			"id": "hub_room_guide_flags_reset",
			"title": "部屋ガイドフラグをリセット",
			"hint": "調査／招き／封蔵／展示の初回手引きを再度出せる",
		},
	])
	out.append({
		"id": "section_parts",
		"title": "—— 部品単体 ——",
		"hint": "個別確認用",
		"section": true,
	})
	out.append_array([
		{
			"id": "nina_merit_only",
			"title": "ニーナ功績セリフのみ",
			"hint": "功績トークだけ再生",
		},
		{
			"id": "nina_teaser_only",
			"title": "ニーナ加入予告のみ",
			"hint": "加入予告だけ再生（解放済みでも可）",
		},
		{
			"id": "starter_join_only",
			"title": "加入画面のみ",
			"hint": "加入演出プレビュー（解放済みでも可）",
		},
		{
			"id": "rank_up_popup",
			"title": "等級アップ演出",
			"hint": "未表示なら等級アップ、無ければ1段戻して再演",
		},
		{
			"id": "hub_guide",
			"title": "拠点はじめガイド",
			"hint": "初回ガイドをプレビュー表示（セーブ済みフラグは触らない）",
		},
		{
			"id": "clear_pending_story",
			"title": "加入ストーリー待ちをクリア",
			"hint": "pending の功績／予告／候補を破棄",
		},
	])
	return out


## 戻り値: 空=成功、非空=エラーメッセージ。
static func run(entry_id: String) -> String:
	if entry_id.begins_with("section_"):
		return "見出しです"
	if entry_id.begins_with("clear_ceremony:"):
		return _queue_clear_ceremony(entry_id.substr("clear_ceremony:".length()))
	if entry_id.begins_with("dungeon_unlock:"):
		return _queue_dungeon_unlock_notice(entry_id.substr("dungeon_unlock:".length()))
	if entry_id.begins_with("survey_complete:"):
		return _queue_survey_complete_notice(entry_id.substr("survey_complete:".length()))
	if entry_id.begins_with("nina_rare_guide:"):
		return _queue_nina_rare_guide(entry_id.substr("nina_rare_guide:".length()))
	if entry_id.begins_with("nina_rare_nav:"):
		return _queue_nina_rare_nav(entry_id.substr("nina_rare_nav:".length()))
	match entry_id:
		"dungeon_unlock_hard_mourngate":
			GameState.pending_content_unlock_notices.clear()
			_ContentUnlockNotice.queue_campaign_tier_unlock(_DungeonTierConfig.TIER_HARD)
			return ""
		"dungeon_unlock_nm_mourngate":
			GameState.pending_content_unlock_notices.clear()
			_ContentUnlockNotice.queue_campaign_tier_unlock(_DungeonTierConfig.TIER_NIGHTMARE)
			return ""
		"stage_unlock_popup":
			return _queue_stage_unlock_notice()
		"nina_merit_only":
			return _queue_nina_merit_only()
		"nina_teaser_only":
			return _queue_nina_teaser_only()
		"starter_join_only":
			return _queue_starter_join_only()
		"rank_up_popup":
			return _queue_rank_up()
		"hub_guide":
			return _queue_hub_guide()
		"survey_claim_result":
			## 表示は BaseScene 側（即ポップ・付与なし）。
			return ""
		"nina_rare_flags_reset":
			return _reset_nina_rare_flags()
		"hub_room_guide_flags_reset":
			return _reset_hub_room_guide_flags()
		"clear_pending_story":
			return _clear_pending_story()
		## 後方互換
		"clear_ceremony_1_5":
			return _queue_clear_ceremony(Constants.MOURNGATE_DUNGEON_ID)
		"dungeon_unlock_popup":
			return _queue_dungeon_unlock_notice("whisperwood")
		_:
			return "未知のデバッグ項目です"


static func _main_biome_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	var seen: Dictionary = {}
	for biome_id in MAIN_BIOME_ORDER:
		if DataRegistry.get_dungeon_data(biome_id) == null:
			continue
		ids.append(biome_id)
		seen[biome_id] = true
	for data in DataRegistry.get_all_dungeon_data():
		if data == null or str(data.route_type) != "main":
			continue
		var did: String = str(data.id)
		if did.is_empty() or seen.has(did):
			continue
		ids.append(did)
		seen[did] = true
	return ids


static func _dungeon_short_name(dungeon_id: String) -> String:
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data != null and "display_name" in data and not str(data.display_name).is_empty():
		return str(data.display_name)
	return dungeon_id


static func _biome_chapter5_label(biome_id: String) -> String:
	var stage: Resource = DataRegistry.get_stage_by_chapter(biome_id, 5)
	if stage == null:
		return "%s ×-5" % biome_id
	var biome_index: int = int(stage.biome_index) if "biome_index" in stage else 0
	if biome_index > 0:
		return "%d-5" % biome_index
	return "%s 5章" % _dungeon_short_name(biome_id)


static func _chapter5_stage_id(biome_id: String) -> String:
	var stage: Resource = DataRegistry.get_stage_by_chapter(biome_id, 5)
	if stage == null:
		return ""
	return str(stage.id)


static func _ensure_recruit_candidate() -> String:
	## 未加入がいればそれを優先。デバッグでは全員加入済みでも誰か1人をプレビュー用に返す。
	var missing: Array = _StarterRecruitment.missing_starter_defs()
	if not missing.is_empty():
		var pick_missing: Dictionary = missing[randi() % missing.size()]
		return str(pick_missing.get("id", "")).strip_edges()
	if GameState.BASE_ROSTER_DEFS.is_empty():
		return ""
	var pick: Dictionary = GameState.BASE_ROSTER_DEFS[randi() % GameState.BASE_ROSTER_DEFS.size()]
	return str(pick.get("id", "")).strip_edges()


static func _apply_recruit_candidate(recruit_id: String) -> void:
	GameState.pending_starter_recruit_id = recruit_id
	GameState.last_run_starter_recruited_id = recruit_id
	GameState.last_run_starter_recruited_name = ""
	for def: Variant in GameState.BASE_ROSTER_DEFS:
		if str(def.get("id", "")) == recruit_id:
			GameState.last_run_starter_recruited_name = str(def.get("name", ""))
			break


static func _queue_clear_ceremony(biome_id: String) -> String:
	var stage_id: String = _chapter5_stage_id(biome_id)
	if stage_id.is_empty():
		return "%s の5章データがありません" % biome_id
	var recruit_id: String = _ensure_recruit_candidate()
	if recruit_id.is_empty():
		return "初期キャラ定義がありません"
	_apply_recruit_candidate(recruit_id)
	GameState.pending_clear_stage_id = stage_id
	GameState.pending_clear_nina_merit = true
	GameState.pending_clear_nina_teaser = true
	## ③クリア相当のプレビューではノノカ合流も続けて出す。
	if biome_id == "mistfen":
		GameState.survey_staff_nonoka_unlocked = false
		GameState.queue_nonoka_survey_join_if_needed()
	## 古い解放キューが残ると常にウィスパーウッドが出るため、次解放だけにする。
	GameState.pending_content_unlock_notices.clear()
	if not _ContentUnlockNotice.queue_next_after_main_biome_clear(
		biome_id, _DungeonTierConfig.TIER_NORMAL
	):
		return "次の解放先がありません: %s" % biome_id
	SaveManager.save_game()
	return ""


static func _queue_dungeon_unlock_notice(dungeon_id: String) -> String:
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data == null:
		return "ダンジョンがありません: %s" % dungeon_id
	var name_str: String = str(data.display_name)
	if name_str.is_empty():
		name_str = dungeon_id
	GameState.pending_content_unlock_notices.clear()
	_ContentUnlockNotice._queue_entry("dungeon", dungeon_id, name_str)
	return ""


static func _queue_survey_complete_notice(dungeon_id: String) -> String:
	if not _SurveyCompleteRewards.has_table(dungeon_id):
		return "完全調査テーブルがありません: %s" % dungeon_id
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data == null:
		return "ダンジョンがありません: %s" % dungeon_id
	var name_str: String = str(data.display_name)
	if name_str.is_empty():
		name_str = dungeon_id
	var granted: Dictionary = _SurveyCompleteRewards.sample_guaranteed_granted(dungeon_id)
	var detail: String = _SurveyCompleteRewards.format_granted_detail(granted)
	var rewards: Array = _SurveyCompleteRewards.granted_entries(granted)
	GameState.pending_content_unlock_notices.clear()
	_ContentUnlockNotice._queue_entry("survey_complete", dungeon_id, name_str, -1, detail, rewards)
	return ""


static func _queue_stage_unlock_notice() -> String:
	## 2-1 相当など、表示確認用に章解放を1件。
	var stage: Resource = DataRegistry.get_stage_by_chapter("whisperwood", 1)
	if stage == null:
		stage = DataRegistry.get_stage_by_chapter(Constants.MOURNGATE_DUNGEON_ID, 2)
	if stage == null:
		return "章データがありません"
	var sid: String = str(stage.id)
	var name_str: String = str(stage.display_name)
	if name_str.is_empty():
		name_str = sid
	_ContentUnlockNotice._queue_entry("stage", sid, name_str)
	return ""


static func _queue_nina_merit_only() -> String:
	var stage_id: String = GameState.pending_clear_stage_id
	if stage_id.is_empty():
		stage_id = _chapter5_stage_id(Constants.MOURNGATE_DUNGEON_ID)
	GameState.pending_clear_stage_id = stage_id
	GameState.pending_clear_nina_merit = true
	GameState.pending_clear_nina_teaser = false
	SaveManager.save_game()
	return ""


static func _queue_nina_teaser_only() -> String:
	var recruit_id: String = GameState.pending_starter_recruit_id.strip_edges()
	if recruit_id.is_empty():
		recruit_id = _ensure_recruit_candidate()
	if recruit_id.is_empty():
		return "初期キャラ定義がありません"
	_apply_recruit_candidate(recruit_id)
	GameState.pending_clear_nina_merit = false
	GameState.pending_clear_nina_teaser = true
	SaveManager.save_game()
	return ""


static func _queue_starter_join_only() -> String:
	var recruit_id: String = GameState.pending_starter_recruit_id.strip_edges()
	if recruit_id.is_empty():
		recruit_id = _ensure_recruit_candidate()
	if recruit_id.is_empty():
		return "初期キャラ定義がありません"
	_apply_recruit_candidate(recruit_id)
	GameState.pending_clear_nina_merit = false
	GameState.pending_clear_nina_teaser = false
	SaveManager.save_game()
	return ""


static func _queue_rank_up() -> String:
	_CommanderProfile.ensure_commander()
	var pending: String = _CommanderProfile.pending_rank_up()
	if not pending.is_empty():
		return ""
	## 未表示が無ければ1段下げて再演できるようにする。
	var current: String = _CommanderProfile.current_rank()
	var idx: int = _CommanderProfile.rank_index(current)
	if idx <= 0:
		return "これ以上下げて等級アップを再演できません"
	GameState.commander["acknowledged_rank"] = _CommanderProfile.rank_code_at(idx - 1)
	SaveManager.save_game()
	if _CommanderProfile.pending_rank_up().is_empty():
		return "等級アップの準備に失敗しました"
	return ""


static func _queue_hub_guide() -> String:
	## 表示は BaseScene 側（preview）。セーブ済みフラグは触らない。
	return ""


static func _queue_nina_rare_guide(kind: String) -> String:
	const _NinaRareAcquireGuide := preload("res://scripts/ui/NinaRareAcquireGuide.gd")
	var kind_id: String = kind.strip_edges()
	if _NinaRareAcquireGuide.flag_for(kind_id).is_empty():
		return "不明な種別です: %s" % kind_id
	## 再演用に初回フラグを戻し、同種キューを先頭に載せ替える。
	var flag_key: String = _NinaRareAcquireGuide.flag_for(kind_id)
	GameState.tutorial_flags[flag_key] = false
	var kept: Array = []
	for raw in GameState.pending_nina_rare_guides:
		if str(raw) != kind_id:
			kept.append(str(raw))
	kept.insert(0, kind_id)
	GameState.pending_nina_rare_guides = kept
	SaveManager.save_game()
	return ""


static func _queue_nina_rare_nav(kind: String) -> String:
	const _NinaRareAcquireGuide := preload("res://scripts/ui/NinaRareAcquireGuide.gd")
	var kind_id: String = kind.strip_edges()
	if _NinaRareAcquireGuide.flag_for(kind_id).is_empty():
		return "不明な種別です: %s" % kind_id
	## 2回目以降扱いにして吹き出しへ。
	_NinaRareAcquireGuide.mark_guide_done(kind_id)
	var sample: String = _debug_sample_name_for_rare(kind_id)
	_NinaRareAcquireGuide._queue_nav_notice(kind_id, sample)
	SaveManager.save_game()
	return ""


static func _reset_nina_rare_flags() -> String:
	const _NinaRareAcquireGuide := preload("res://scripts/ui/NinaRareAcquireGuide.gd")
	for kind in [
		_NinaRareAcquireGuide.KIND_RELIC,
		_NinaRareAcquireGuide.KIND_LEGENDARY,
		_NinaRareAcquireGuide.KIND_MYTHIC,
	]:
		var key: String = _NinaRareAcquireGuide.flag_for(kind)
		if not key.is_empty():
			GameState.tutorial_flags[key] = false
	GameState.pending_nina_rare_guides.clear()
	GameState.pending_nina_nav_notices.clear()
	SaveManager.save_game()
	return ""


static func _reset_hub_room_guide_flags() -> String:
	const _RoomGuide := preload("res://scripts/ui/DungeonRouteGuideOverlay.gd")
	for key: String in [
		_RoomGuide.FLAG_SURVEY,
		_RoomGuide.FLAG_GACHA_INVITE,
		_RoomGuide.FLAG_GACHA_SEAL,
		_RoomGuide.FLAG_SHOWCASE,
	]:
		GameState.tutorial_flags[key] = false
	SaveManager.save_game()
	return ""


static func _debug_sample_name_for_rare(kind: String) -> String:
	match kind:
		"relic":
			return "王国軍旗"
		"legendary":
			return "ファロス・フレア"
		"mythic":
			return "継承剣レガート"
		_:
			return "サンプル"


static func _clear_pending_story() -> String:
	GameState.pending_starter_recruit_id = ""
	GameState.last_run_starter_recruited_id = ""
	GameState.last_run_starter_recruited_name = ""
	GameState.pending_clear_nina_merit = false
	GameState.pending_clear_nina_teaser = false
	GameState.pending_clear_stage_id = ""
	GameState.pending_content_unlock_notices.clear()
	SaveManager.save_game()
	return ""
