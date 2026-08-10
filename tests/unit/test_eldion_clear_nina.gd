extends GutTest

## エルディオン（frostridge_5_5）初クリアのニーナ功績（加入無しでも発火）。

const _ChapterClearNinaLines := preload("res://scripts/ui/ChapterClearNinaLines.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")


func before_each() -> void:
	GameState.roster.clear()
	GameState.party_members.clear()
	GameState.starter_unlocked_ids.clear()
	GameState.starter_pick_pending = true
	GameState.stage_progress.clear()
	GameState.dungeon_progress.clear()
	GameState.dungeon_tier_cleared.clear()
	GameState.pending_starter_recruit_id = ""
	GameState.pending_clear_nina_merit = false
	GameState.pending_clear_nina_teaser = false
	GameState.pending_clear_stage_id = ""
	GameState.last_run_starter_recruited_id = ""
	GameState.last_run_starter_recruited_name = ""


func after_each() -> void:
	GameState.seed_all_starters_unlocked()
	GameState.pending_clear_nina_merit = false
	GameState.pending_clear_nina_teaser = false
	GameState.pending_clear_stage_id = ""
	GameState.pending_starter_recruit_id = ""


func test_frostridge_merit_lines_mention_normal_and_hard() -> void:
	var lines: Array[String] = _ChapterClearNinaLines.merit_lines_for_stage("frostridge_5_5")
	assert_eq(lines.size(), 2)
	var joined: String = " ".join(lines)
	assert_true(joined.contains("ノーマル"), joined)
	assert_true(joined.contains("ハード"), joined)


func test_frostridge_first_clear_queues_merit_without_recruit() -> void:
	## 初期5が揃っていると加入候補は空だが、功績トークは出す。
	GameState.seed_all_starters_unlocked()
	GameState.pending_clear_nina_merit = false
	GameState.pending_clear_nina_teaser = false
	GameState.mark_stage_cleared("frostridge_5_5", _DungeonTierConfig.TIER_NORMAL)
	assert_true(GameState.pending_clear_nina_merit)
	assert_eq(GameState.pending_clear_stage_id, "frostridge_5_5")
	assert_false(GameState.pending_clear_nina_teaser)
	assert_eq(GameState.pending_starter_recruit_id, "")


func test_frostridge_recruit_teaser_is_empty() -> void:
	var lines: Array[String] = _ChapterClearNinaLines.recruit_teaser_lines_for_stage("frostridge_5_5")
	assert_eq(lines.size(), 0, "5-5は加入予告文案を持たない")
