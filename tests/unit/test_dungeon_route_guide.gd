extends GutTest
## P3-DG-ROUTE-GUIDE-001 — イベント／降臨／無限の手引き。

const _Guide := preload("res://scripts/ui/DungeonRouteGuideOverlay.gd")
const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")


func before_each() -> void:
	GameState.tutorial_flags.clear()


func test_guides_have_three_pages_each() -> void:
	for gid: String in [_Guide.GUIDE_EVENT, _Guide.GUIDE_DESCENT, _Guide.GUIDE_ABYSS]:
		var def: Dictionary = _Guide._all_guides().get(gid, {}) as Dictionary
		assert_false(def.is_empty(), gid)
		var pages: Array = def.get("pages", []) as Array
		assert_eq(pages.size(), 3, gid)
		assert_false(str(def.get("topic", "")).is_empty(), "topic %s" % gid)
		for page: Variant in pages:
			var p: Dictionary = page as Dictionary
			assert_false(str(p.get("title", "")).is_empty(), "title %s" % gid)
			assert_false(str(p.get("body", "")).is_empty(), "body %s" % gid)


func test_guide_copy_avoids_dev_terms() -> void:
	var blob: String = ""
	for gid: String in [_Guide.GUIDE_EVENT, _Guide.GUIDE_DESCENT, _Guide.GUIDE_ABYSS]:
		var def: Dictionary = _Guide._all_guides().get(gid, {}) as Dictionary
		blob += str(def.get("topic", ""))
		for page: Variant in def.get("pages", []) as Array:
			blob += str((page as Dictionary).get("body", ""))
	for term: String in ["route_type", "abyss_", "DoT", "tick", "Threat", "深層ダンジョン"]:
		assert_false(blob.find(term) >= 0, "dev term %s" % term)


func test_queue_abyss_auto_only_once() -> void:
	assert_false(_Guide.has_pending_auto())
	_Guide.queue_auto_if_unseen(_Guide.GUIDE_ABYSS)
	assert_true(_Guide.has_pending_auto())
	assert_eq(_Guide.peek_pending_auto(), _Guide.GUIDE_ABYSS)
	_Guide.mark_seen(_Guide.GUIDE_ABYSS)
	_Guide.queue_auto_if_unseen(_Guide.GUIDE_ABYSS)
	assert_false(_Guide.has_pending_auto())


func test_event_guide_has_no_auto_flag() -> void:
	_Guide.queue_auto_if_unseen(_Guide.GUIDE_EVENT)
	assert_false(_Guide.has_pending_auto())


func test_abyss_unlock_queues_guide() -> void:
	if not Constants.ABYSS_DUNGEONS_PLAYABLE:
		pass_test("ABYSS off")
		return
	GameState.reset_for_new_game()
	GameState.debug_full_unlock = false
	GameState.tutorial_flags.clear()
	var before: Dictionary = _ContentUnlockNotice.snapshot_unlocked()
	## 親クリアで深層解放。
	GameState.mark_dungeon_cleared("mourngate")
	_ContentUnlockNotice.queue_newly_unlocked(before)
	assert_true(_Guide.has_pending_auto())
	assert_eq(_Guide.peek_pending_auto(), _Guide.GUIDE_ABYSS)
