extends RefCounted
## 章クリア時の基本職加入（P3-JOIN-001）。

const _Content := preload("res://scripts/roster/RosterJoinContent.gd")
const JOIN_SCENE: String = "res://scenes/roster/RosterJoinScene.tscn"
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const FLAG_KEY: String = "starter_progression_v1"


static func is_progression_enabled() -> bool:
	return bool(GameState.starter_progression_v1)


static func enable_progression() -> void:
	GameState.starter_progression_v1 = true


## 章の初回クリア時に呼ぶ。pending を立てるだけ（加入は会話完了時）。
static func on_stage_first_cleared(stage_id: String) -> void:
	if not is_progression_enabled():
		return
	if not _Content.is_join_trigger_stage(stage_id):
		return
	if not GameState.pending_roster_join_id.is_empty():
		return
	var next_id: String = _Content.next_unjoined_id()
	if next_id.is_empty():
		return
	GameState.pending_roster_join_id = next_id


static func has_pending_join() -> bool:
	return not GameState.pending_roster_join_id.is_empty()


static func resolve_home_scene() -> String:
	if has_pending_join():
		return JOIN_SCENE
	return HOME_SCENE


## 会話完了時。ロスターへ追加し pending を解消する。
static func commit_pending_join() -> bool:
	var adv_id: String = GameState.pending_roster_join_id
	if adv_id.is_empty():
		return false
	if not GameState.grant_base_roster_member(adv_id):
		GameState.pending_roster_join_id = ""
		return false
	GameState.pending_roster_join_id = ""
	return true
