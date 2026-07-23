class_name ContentUnlockNotice
extends RefCounted

## ダンジョン／章の新規解放を検知し、ポップアップ用キューに積む。

const _DungeonUnlockOverlay := preload("res://scripts/ui/DungeonUnlockOverlay.gd")


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
	return {"stages": stages, "dungeons": dungeons}


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


static func _queue_entry(kind: String, id: String, display_name: String) -> void:
	if id.is_empty() or display_name.is_empty():
		return
	for raw in GameState.pending_content_unlock_notices:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if str(entry.get("kind", "")) == kind and str(entry.get("id", "")) == id:
			return
	GameState.pending_content_unlock_notices.append({
		"kind": kind,
		"id": id,
		"display_name": display_name,
	})


static func _dungeon_display_name(dungeon_id: String) -> String:
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data != null and "display_name" in data and not str(data.display_name).is_empty():
		return str(data.display_name)
	return dungeon_id


static func _stage_display_name(stage: Resource) -> String:
	if stage != null and "display_name" in stage and not str(stage.display_name).is_empty():
		return str(stage.display_name)
	return str(stage.id) if stage != null else ""


static func has_pending() -> bool:
	return not GameState.pending_content_unlock_notices.is_empty()


## キュー先頭を1件表示。dismiss で次があれば続けて出す。
## on_all_done: キュー消化後（または空のとき）に1回呼ぶ。
static func show_pending_on(parent: Node, on_all_done: Callable = Callable()) -> CanvasLayer:
	if parent == null:
		if on_all_done.is_valid():
			on_all_done.call()
		return null
	if parent.get_node_or_null("DungeonUnlockOverlay") != null:
		return null
	if not has_pending():
		if on_all_done.is_valid():
			on_all_done.call()
		return null
	var raw: Variant = GameState.pending_content_unlock_notices.pop_front()
	if not raw is Dictionary:
		return show_pending_on(parent, on_all_done)
	var entry: Dictionary = raw
	var name_str: String = str(entry.get("display_name", "")).strip_edges()
	if name_str.is_empty():
		return show_pending_on(parent, on_all_done)
	var overlay: CanvasLayer = _DungeonUnlockOverlay.show_on(parent, name_str)
	overlay.dismissed.connect(func(_n: String) -> void:
		show_pending_on(parent, on_all_done)
	)
	return overlay
