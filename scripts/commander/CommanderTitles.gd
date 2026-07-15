class_name CommanderTitles
extends RefCounted

const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderSurveyPoints := preload("res://scripts/commander/CommanderSurveyPoints.gd")

## 指揮官称号（コスメのみ・戦闘力変化なし / P3-CMD-004）。

const DEFINITIONS: Array[Dictionary] = [
	{"id": "title_first_clear", "label": "初陣の報告", "description": "初めて調査を完走した"},
	{"id": "title_codex_10", "label": "記録係見習い", "description": "図鑑を10件登録した"},
	{"id": "title_codex_50", "label": "調査部補", "description": "図鑑を50件登録した"},
	{"id": "title_biome1", "label": "モーンゲート踏破", "description": "モーンゲートを完走した"},
	{"id": "title_biome5", "label": "五域調査官", "description": "メイン5Biomeを完走した"},
	{"id": "title_max_hit_1k", "label": "一撃の目撃者", "description": "最大一撃が1000を超えた"},
	{"id": "title_max_hit_5k", "label": "規格外の戦果", "description": "最大一撃が5000を超えた"},
	{"id": "title_hard_clear", "label": "危険区域指定", "description": "ハード難易度を初クリアした"},
	{"id": "title_mvp_streak", "label": "右腕の証", "description": "同一仲間がMVPを10回取った"},
	{"id": "title_nameless", "label": "無名の継承者", "description": "名前を変えずにS級に到達した", "hidden": true},
]


static func get_label(title_id: String) -> String:
	for def: Dictionary in DEFINITIONS:
		if str(def.get("id", "")) == title_id:
			return str(def.get("label", title_id))
	return title_id


static func refresh_unlocks() -> void:
	_CommanderProfile.ensure_commander()
	for def: Dictionary in DEFINITIONS:
		var title_id: String = str(def.get("id", ""))
		if title_id.is_empty():
			continue
		if _is_unlocked(title_id):
			_CommanderProfile.unlock_title(title_id)


static func _is_unlocked(title_id: String) -> bool:
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	match title_id:
		"title_first_clear":
			return int(lifetime.get("runs_cleared", 0)) >= 1
		"title_codex_10":
			return _CommanderSurveyPoints.discovery_count() >= 10
		"title_codex_50":
			return _CommanderSurveyPoints.discovery_count() >= 50
		"title_biome1":
			return GameState.is_dungeon_cleared(Constants.MOURNGATE_DUNGEON_ID)
		"title_biome5":
			return _all_main_biomes_cleared()
		"title_max_hit_1k":
			return int(lifetime.get("damage_max_hit", 0)) >= 1000
		"title_max_hit_5k":
			return int(lifetime.get("damage_max_hit", 0)) >= 5000
		"title_hard_clear":
			return _any_hard_cleared()
		"title_mvp_streak":
			return _any_mvp_count_at_least(10)
		"title_nameless":
			return (
				_CommanderProfile.current_rank() == "S"
				and _CommanderProfile.get_commander_name() == _CommanderProfile.DEFAULT_NAME
			)
	return false


static func _all_main_biomes_cleared() -> bool:
	for data: Resource in DataRegistry.get_all_dungeon_data():
		if data == null or str(data.route_type) != "main":
			continue
		if not GameState.is_dungeon_cleared(str(data.id)):
			return false
	return true


static func _any_hard_cleared() -> bool:
	for biome_id: Variant in GameState.dungeon_tier_cleared.keys():
		var tiers: Variant = GameState.dungeon_tier_cleared[biome_id]
		if tiers is Dictionary and bool((tiers as Dictionary).get("1", false)):
			return true
	return false


static func _any_mvp_count_at_least(threshold: int) -> bool:
	var counts: Variant = _CommanderProfile.get_lifetime().get("mvp_counts", {})
	if not counts is Dictionary:
		return false
	for member_id: Variant in (counts as Dictionary).keys():
		if int((counts as Dictionary)[member_id]) >= threshold:
			return true
	return false
