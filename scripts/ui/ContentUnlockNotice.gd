class_name ContentUnlockNotice
extends RefCounted

## ダンジョン／章の新規解放を検知し、ポップアップ用キューに積む。

const _DungeonUnlockOverlay := preload("res://scripts/ui/DungeonUnlockOverlay.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")

## キャンペーン次帯解放時に代表表示する Biome（ハード／NM の入口）。
const CAMPAIGN_TIER_ENTRY_BIOME_ID: String = "mourngate"


static func snapshot_unlocked() -> Dictionary:
	var stages: Dictionary = {}
	var dungeons: Dictionary = {}
	for stage in DataRegistry.get_all_stage_data():
		if stage == null:
			continue
		var sid: String = str(stage.id)
		if sid.is_empty():
			continue
		if GameState.is_stage_unlocked(sid):
			stages[sid] = true
	for data in DataRegistry.get_all_dungeon_data():
		if data == null:
			continue
		var did: String = str(data.id)
		if did.is_empty():
			continue
		if GameState.is_dungeon_unlocked(did):
			dungeons[did] = true
	var campaign_tiers: Dictionary = {
		str(_DungeonTierConfig.TIER_HARD): GameState.is_dungeon_tier_unlocked(
			CAMPAIGN_TIER_ENTRY_BIOME_ID, _DungeonTierConfig.TIER_HARD
		),
		str(_DungeonTierConfig.TIER_NIGHTMARE): GameState.is_dungeon_tier_unlocked(
			CAMPAIGN_TIER_ENTRY_BIOME_ID, _DungeonTierConfig.TIER_NIGHTMARE
		),
	}
	return {"stages": stages, "dungeons": dungeons, "campaign_tiers": campaign_tiers}


static func queue_newly_unlocked(before: Dictionary) -> void:
	if before.is_empty():
		return
	var after: Dictionary = snapshot_unlocked()
	var before_dungeons: Dictionary = before.get("dungeons", {}) as Dictionary
	var after_dungeons: Dictionary = after.get("dungeons", {}) as Dictionary
	var before_stages: Dictionary = before.get("stages", {}) as Dictionary
	var after_stages: Dictionary = after.get("stages", {}) as Dictionary
	var new_dungeon_ids: Array[String] = []
	for did in after_dungeons.keys():
		var id_str: String = str(did)
		if before_dungeons.has(id_str):
			continue
		new_dungeon_ids.append(id_str)
		_queue_entry("dungeon", id_str, _dungeon_display_name(id_str))
	for sid in after_stages.keys():
		var stage_id: String = str(sid)
		if before_stages.has(stage_id):
			continue
		var stage: Resource = DataRegistry.get_stage_data(stage_id)
		if stage == null:
			continue
		## 新規 Biome 解放と同時の章1は Biome 名の通知に任せる。
		var biome_id: String = str(stage.biome_id)
		if new_dungeon_ids.has(biome_id):
			continue
		_queue_entry("stage", stage_id, _stage_display_name(stage))
	var before_tiers: Dictionary = before.get("campaign_tiers", {}) as Dictionary
	var after_tiers: Dictionary = after.get("campaign_tiers", {}) as Dictionary
	for tier in [_DungeonTierConfig.TIER_HARD, _DungeonTierConfig.TIER_NIGHTMARE]:
		var key: String = str(tier)
		if bool(after_tiers.get(key, false)) and not bool(before_tiers.get(key, false)):
			queue_campaign_tier_unlock(tier)


## メイン最終 Biome クリア後など、ハード／NM 帯の入口解放をキューする。
static func queue_campaign_tier_unlock(tier: int) -> void:
	var t: int = _DungeonTierConfig.clamp_tier(tier)
	if t != _DungeonTierConfig.TIER_HARD and t != _DungeonTierConfig.TIER_NIGHTMARE:
		return
	var biome_id: String = CAMPAIGN_TIER_ENTRY_BIOME_ID
	var display: String = _tier_dungeon_display_name(biome_id, t)
	_queue_entry("dungeon_tier", biome_id, display, t)


## デバッグ／手動: ノーマル Biome クリア相当の「次解放」を1件キュー。
## 最終メイン → ハード入口。それ以外 → 次メイン Biome。
static func queue_next_after_main_biome_clear(biome_id: String, cleared_tier: int = -1) -> bool:
	var notice: Dictionary = next_unlock_after_main_clear(biome_id, cleared_tier)
	if notice.is_empty():
		return false
	var kind: String = str(notice.get("kind", "dungeon"))
	var id_str: String = str(notice.get("id", ""))
	var name_str: String = str(notice.get("display_name", ""))
	var tier: int = int(notice.get("tier", -1))
	_queue_entry(kind, id_str, name_str, tier)
	return true


## 戻り: {kind, id, display_name, tier?}。次が無ければ空。
static func next_unlock_after_main_clear(biome_id: String, cleared_tier: int = -1) -> Dictionary:
	var bid: String = biome_id.strip_edges()
	if bid.is_empty():
		return {}
	var t: int = cleared_tier
	if t < 0:
		t = _DungeonTierConfig.TIER_NORMAL
	t = _DungeonTierConfig.clamp_tier(t)
	var mains: Array[String] = []
	for mid: String in _DungeonTierConfig.MAIN_BIOME_IDS:
		mains.append(mid)
	var idx: int = mains.find(bid)
	if idx < 0:
		return {}
	## ノーマル最終クリア → ハード入口（モーンゲート）。
	if t == _DungeonTierConfig.TIER_NORMAL and idx == mains.size() - 1:
		return {
			"kind": "dungeon_tier",
			"id": CAMPAIGN_TIER_ENTRY_BIOME_ID,
			"display_name": _tier_dungeon_display_name(
				CAMPAIGN_TIER_ENTRY_BIOME_ID, _DungeonTierConfig.TIER_HARD
			),
			"tier": _DungeonTierConfig.TIER_HARD,
		}
	## ハード最終クリア → ナイトメア入口。
	if t == _DungeonTierConfig.TIER_HARD and idx == mains.size() - 1:
		return {
			"kind": "dungeon_tier",
			"id": CAMPAIGN_TIER_ENTRY_BIOME_ID,
			"display_name": _tier_dungeon_display_name(
				CAMPAIGN_TIER_ENTRY_BIOME_ID, _DungeonTierConfig.TIER_NIGHTMARE
			),
			"tier": _DungeonTierConfig.TIER_NIGHTMARE,
		}
	## 同ティアの次メイン（ノーマル／ハード／NM の章進行）。
	if idx + 1 < mains.size():
		var next_id: String = mains[idx + 1]
		if t == _DungeonTierConfig.TIER_NORMAL:
			return {
				"kind": "dungeon",
				"id": next_id,
				"display_name": _dungeon_display_name(next_id),
			}
		return {
			"kind": "dungeon_tier",
			"id": next_id,
			"display_name": _tier_dungeon_display_name(next_id, t),
			"tier": t,
		}
	return {}


static func _queue_entry(
	kind: String,
	id: String,
	display_name: String,
	tier: int = -1,
	detail: String = "",
	rewards: Array = []
) -> void:
	if id.is_empty() or display_name.is_empty():
		return
	for raw in GameState.pending_content_unlock_notices:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if str(entry.get("kind", "")) != kind:
			continue
		if str(entry.get("id", "")) != id:
			continue
		if int(entry.get("tier", -1)) != tier:
			continue
		return
	var payload: Dictionary = {
		"kind": kind,
		"id": id,
		"display_name": display_name,
	}
	if tier >= 0:
		payload["tier"] = tier
	var detail_str: String = detail.strip_edges()
	if not detail_str.is_empty():
		payload["detail"] = detail_str
	if not rewards.is_empty():
		payload["rewards"] = rewards.duplicate(true)
	GameState.pending_content_unlock_notices.append(payload)


static func _dungeon_display_name(dungeon_id: String) -> String:
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data != null and "display_name" in data and not str(data.display_name).is_empty():
		return str(data.display_name)
	return dungeon_id


static func _tier_dungeon_display_name(dungeon_id: String, tier: int) -> String:
	var base: String = _dungeon_display_name(dungeon_id)
	var tier_name: String = _DungeonTierConfig.display_name(tier)
	if tier_name.is_empty() or tier == _DungeonTierConfig.TIER_NORMAL:
		return base
	## 「ハード・王都地下モーンゲート」
	return "%s・%s" % [tier_name, base]


static func _stage_display_name(stage: Resource) -> String:
	if stage != null and "display_name" in stage and not str(stage.display_name).is_empty():
		return str(stage.display_name)
	return str(stage.id) if stage != null else ""


static func has_pending() -> bool:
	return not GameState.pending_content_unlock_notices.is_empty()


## 結果／ダンジョン選択では出さず、拠点（メインメニュー）で出す kind。
const DEFER_TO_HUB_KINDS: PackedStringArray = PackedStringArray(["survey_complete"])


## キュー先頭を1件表示。dismiss で次があれば続けて出す。
## on_all_done: キュー消化後（または空のとき）に1回呼ぶ。
## skip_kinds: 表示せずキューに残す kind（拠点へ持ち越し）。
static func show_pending_on(
	parent: Node,
	on_all_done: Callable = Callable(),
	skip_kinds: PackedStringArray = PackedStringArray()
) -> CanvasLayer:
	if parent == null:
		if on_all_done.is_valid():
			on_all_done.call()
		return null
	var existing: Node = parent.get_node_or_null("DungeonUnlockOverlay")
	if existing != null:
		## dismiss 直後は queue_free 待ち。同フレーム再入すると on_all_done が呼ばれず連鎖が止まる。
		if existing.is_queued_for_deletion():
			_defer_show_pending(parent, on_all_done, skip_kinds)
		return null
	if not has_pending():
		if on_all_done.is_valid():
			on_all_done.call()
		return null
	var deferred: Array = []
	var entry: Dictionary = {}
	var found: bool = false
	while not GameState.pending_content_unlock_notices.is_empty():
		var raw: Variant = GameState.pending_content_unlock_notices.pop_front()
		if not raw is Dictionary:
			continue
		var candidate: Dictionary = raw
		var name_str: String = str(candidate.get("display_name", "")).strip_edges()
		if name_str.is_empty():
			continue
		var kind: String = str(candidate.get("kind", "dungeon")).strip_edges()
		if skip_kinds.has(kind):
			deferred.append(candidate)
			continue
		entry = candidate
		found = true
		break
	## スキップした通知は元の相対順を保って先頭へ戻す。
	for i in range(deferred.size() - 1, -1, -1):
		GameState.pending_content_unlock_notices.push_front(deferred[i])
	if not found:
		if on_all_done.is_valid():
			on_all_done.call()
		return null
	var content_id: String = str(entry.get("id", "")).strip_edges()
	var shown_kind: String = str(entry.get("kind", "dungeon")).strip_edges()
	var detail: String = str(entry.get("detail", "")).strip_edges()
	var display_name: String = str(entry.get("display_name", "")).strip_edges()
	var rewards: Array = []
	var rewards_v: Variant = entry.get("rewards", [])
	if rewards_v is Array:
		rewards = rewards_v as Array
	var banner_id: String = _banner_id_for_entry(shown_kind, content_id)
	var overlay: CanvasLayer = _DungeonUnlockOverlay.show_on(
		parent, display_name, banner_id, shown_kind, detail, rewards
	)
	overlay.dismissed.connect(func(_n: String) -> void:
		_defer_show_pending(parent, on_all_done, skip_kinds)
	)
	return overlay


## 結果／選択画面用。完全調査などは拠点まで残す。
static func show_pending_on_except_hub_deferred(
	parent: Node,
	on_all_done: Callable = Callable()
) -> CanvasLayer:
	return show_pending_on(parent, on_all_done, DEFER_TO_HUB_KINDS)


static func _defer_show_pending(
	parent: Node,
	on_all_done: Callable,
	skip_kinds: PackedStringArray = PackedStringArray()
) -> void:
	if parent == null or not is_instance_valid(parent):
		if on_all_done.is_valid():
			on_all_done.call()
		return
	var tree: SceneTree = parent.get_tree()
	if tree == null:
		if on_all_done.is_valid():
			on_all_done.call()
		return
	tree.create_timer(0.0).timeout.connect(
		func() -> void:
			show_pending_on(parent, on_all_done, skip_kinds),
		CONNECT_ONE_SHOT
	)


static func _banner_id_for_entry(kind: String, content_id: String) -> String:
	if kind == "dungeon" or kind == "dungeon_tier" or kind == "survey_complete":
		return content_id
	if kind == "stage":
		var stage: Resource = DataRegistry.get_stage_data(content_id)
		if stage != null and "biome_id" in stage:
			return str(stage.biome_id)
	return ""
