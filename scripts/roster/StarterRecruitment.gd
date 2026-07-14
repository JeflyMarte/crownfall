class_name StarterRecruitment
extends RefCounted

## 初期5人の加入判定・抽選（P3-STORY-STARTER-001）。


static func is_recruit_eligible_stage(stage_id: String, tier: int) -> bool:
	if not Constants.STARTER_STORY_RECRUIT:
		return false
	if tier != 0:
		return false
	var stage: Resource = DataRegistry.get_stage_data(stage_id)
	if stage == null:
		return false
	var biome_id: String = str(stage.biome_id)
	if biome_id.is_empty():
		return false
	var dungeon: Resource = DataRegistry.get_dungeon_data(biome_id)
	if dungeon == null or str(dungeon.route_type) != "main":
		return false
	var chapter: int = int(stage.chapter_index)
	if chapter == 5:
		return true
	if (
		Constants.STARTER_RECRUIT_BETA_EXTRA
		and biome_id == Constants.MOURNGATE_DUNGEON_ID
		and chapter >= 2
		and chapter <= 4
	):
		return true
	return false


static func missing_starter_defs() -> Array:
	var out: Array = []
	for def: Variant in GameState.BASE_ROSTER_DEFS:
		var adv_id: String = str(def["id"])
		if not GameState.is_starter_unlocked(adv_id):
			out.append(def)
	return out


## 初回クリア時に呼ぶ。加入したら Adventurer、否则 null。
static func try_recruit_after_first_clear(stage_id: String, tier: int) -> Resource:
	if not is_recruit_eligible_stage(stage_id, tier):
		return null
	var missing: Array = missing_starter_defs()
	if missing.is_empty():
		return null
	var pick: Dictionary = missing[randi() % missing.size()]
	return GameState.unlock_starter_adventurer(str(pick["id"]))
