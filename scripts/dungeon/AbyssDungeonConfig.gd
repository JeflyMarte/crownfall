class_name AbyssDungeonConfig
extends RefCounted

## Biome深層（P3-DG-ABYSS-001-A）。階数帯・チャンク・親Biome対応。

const ROUTE_TYPE: String = "abyss"
const CHUNK_FLOORS: int = 10
const FLOOR_HARD_START: int = 33
const FLOOR_NIGHTMARE_START: int = 66
const FLOOR_ENDLESS_START: int = 100
## 100F以降: この階数ごとに敵Lvを +1（NMボーナスに加算）。
const ENDLESS_LEVEL_STEP: int = 5

const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")

## abyss_id → 親メイン Biome id
const PARENT_BIOME_BY_ABYSS: Dictionary = {
	"abyss_mourngate": "mourngate",
	"abyss_whisperwood": "whisperwood",
	"abyss_mistfen": "mistfen",
	"abyss_blackshore": "blackshore",
	"abyss_frostridge": "frostridge",
}


static func is_abyss_dungeon_id(dungeon_id: String) -> bool:
	return PARENT_BIOME_BY_ABYSS.has(dungeon_id)


static func is_abyss_data(data: Resource) -> bool:
	if data == null:
		return false
	return str(data.route_type) == ROUTE_TYPE


static func parent_biome_id(abyss_id: String) -> String:
	return str(PARENT_BIOME_BY_ABYSS.get(abyss_id, ""))


## 表示階（1始まり）→ 合成ティア（セレクトの Hard/NM とは独立）。
static func synthetic_tier_for_floor(floor_1based: int) -> int:
	var f: int = maxi(1, floor_1based)
	if f >= FLOOR_NIGHTMARE_START:
		return _DungeonTierConfig.TIER_NIGHTMARE
	if f >= FLOOR_HARD_START:
		return _DungeonTierConfig.TIER_HARD
	return _DungeonTierConfig.TIER_NORMAL


static func enemy_level_bonus_for_floor(floor_1based: int) -> int:
	var f: int = maxi(1, floor_1based)
	var bonus: int = _DungeonTierConfig.enemy_level_bonus(synthetic_tier_for_floor(f))
	if f >= FLOOR_ENDLESS_START:
		bonus += int((f - (FLOOR_ENDLESS_START - 1)) / ENDLESS_LEVEL_STEP)
	return bonus
