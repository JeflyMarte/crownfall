class_name CommanderSurveyPoints
extends RefCounted

## 調査許可等級用の調査点（SP）算出 SSOT（P3-CMD-001）。
## セーブに SP は保存せず、進行データから都度再計算する。

const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")

const DISCOVERY_WEIGHTS: Dictionary = {
	"enemy": 3,
	"material": 2,
	"weapon": 2,
	"dungeon": 10,
	"room": 1,
	"event": 2,
	"lore": 8,
}

const STAGE_CLEAR_NORMAL: int = 20
const STAGE_CLEAR_HARD_BONUS: int = 8
const STAGE_CLEAR_NIGHTMARE_BONUS: int = 12
const BOSS_CHAPTER_BONUS: int = 30

const RUN_CLEAR: int = 2
const RUN_RETIRE: int = 1

const ENEMY_STAGE3_BONUS: int = 2
const ENEMY_STAGE4_BONUS: int = 2
const ENEMY_STAGE5_BONUS: int = 3


static func evaluate() -> int:
	var total: int = 0
	total += _score_discovery_registry()
	total += _score_stage_progress()
	total += _score_enemy_codex_depth()
	total += _score_run_outcomes()
	return total


static func _score_discovery_registry() -> int:
	var total: int = 0
	for key: Variant in GameState.discovery_registry.keys():
		var key_str: String = str(key)
		var colon: int = key_str.find(":")
		if colon <= 0:
			continue
		var category: String = key_str.substr(0, colon)
		total += int(DISCOVERY_WEIGHTS.get(category, 0))
	return total


static func _score_stage_progress() -> int:
	var total: int = 0
	for stage_id: Variant in GameState.stage_progress.keys():
		var stage_key: String = str(stage_id)
		var progress: Dictionary = GameState.stage_progress[stage_key]
		if not progress is Dictionary:
			continue
		var tiers: Dictionary = progress.get("tiers", {})
		var had_normal: bool = false
		if tiers is Dictionary and not tiers.is_empty():
			if bool(tiers.get(str(_DungeonTierConfig.TIER_NORMAL), false)):
				total += STAGE_CLEAR_NORMAL
				had_normal = true
			if bool(tiers.get(str(_DungeonTierConfig.TIER_HARD), false)):
				total += STAGE_CLEAR_HARD_BONUS
			if bool(tiers.get(str(_DungeonTierConfig.TIER_NIGHTMARE), false)):
				total += STAGE_CLEAR_NIGHTMARE_BONUS
		elif bool(progress.get("cleared", false)):
			total += STAGE_CLEAR_NORMAL
			had_normal = true
		if had_normal and _is_boss_chapter(stage_key):
			total += BOSS_CHAPTER_BONUS
	return total


static func _is_boss_chapter(stage_id: String) -> bool:
	var stage: Resource = DataRegistry.get_stage_data(stage_id)
	if stage == null:
		return false
	return bool(stage.has_boss_floor())


static func _score_enemy_codex_depth() -> int:
	var total: int = 0
	for enemy_id: Variant in GameState.enemy_codex.keys():
		var stage: int = GameState.get_enemy_stage(str(enemy_id))
		if stage >= 3:
			total += ENEMY_STAGE3_BONUS
		if stage >= 4:
			total += ENEMY_STAGE4_BONUS
		if stage >= 5:
			total += ENEMY_STAGE5_BONUS
	return total


static func _score_run_outcomes() -> int:
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	return (
		int(lifetime.get("runs_cleared", 0)) * RUN_CLEAR
		+ int(lifetime.get("runs_retired", 0)) * RUN_RETIRE
	)


static func discovery_count() -> int:
	return GameState.discovery_registry.size()
