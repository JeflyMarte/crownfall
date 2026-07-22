class_name StarterRecruitment
extends RefCounted

## 初期5人の加入判定・抽選（P3-STORY-STARTER-001）。
## クリア時は候補のみ確定。実加入は拠点の StarterJoinOverlay で行う。


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
		if GameState.is_starter_unlocked(adv_id):
			continue
		if adv_id == GameState.pending_starter_recruit_id:
			continue
		out.append(def)
	return out


## 初回クリア時: 加入候補を返す（unlock しない）。空 Dictionary = なし。
static func pick_recruit_after_first_clear(stage_id: String, tier: int) -> Dictionary:
	if not is_recruit_eligible_stage(stage_id, tier):
		return {}
	var missing: Array = missing_starter_defs()
	if missing.is_empty():
		return {}
	var pick: Dictionary = missing[randi() % missing.size()]
	return {
		"id": str(pick.get("id", "")),
		"name": str(pick.get("name", "")),
	}


## 互換: 即 unlock（テスト／デバッグ用）。本番クリア経路は pick → 拠点演出。
static func try_recruit_after_first_clear(stage_id: String, tier: int) -> Resource:
	var pick: Dictionary = pick_recruit_after_first_clear(stage_id, tier)
	if pick.is_empty():
		return null
	return GameState.unlock_starter_adventurer(str(pick.get("id", "")))
