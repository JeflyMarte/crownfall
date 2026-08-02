class_name AbyssDungeonConfig
extends RefCounted

## Biome深層（P3-DG-ABYSS-001-A / P3-DG-ABYSS-LV-001）。
## 階数帯・チャンク・親Biome対応。敵Lvは表示階の絶対表（Biome基準Lvは使わない）。

const ROUTE_TYPE: String = "abyss"
const CHUNK_FLOORS: int = 10
const FLOOR_HARD_START: int = 33
const FLOOR_NIGHTMARE_START: int = 66
const FLOOR_ENDLESS_START: int = 100
## 100F以降: この階数ごとに敵Lvを +1。
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

## 表示階 → 敵Lvアンカー（P3-DG-ABYSS-LV-001）。中間は線形補間。
## Vector2i(floor, level)
const LEVEL_ANCHORS: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(2, 2),
	Vector2i(10, 5),
	Vector2i(20, 12),
	Vector2i(32, 28),
	Vector2i(33, 32),
	Vector2i(50, 52),
	Vector2i(65, 72),
	Vector2i(66, 80),
	Vector2i(80, 95),
	Vector2i(99, 110),
]


static func is_abyss_dungeon_id(dungeon_id: String) -> bool:
	return PARENT_BIOME_BY_ABYSS.has(dungeon_id)


static func is_abyss_data(data: Resource) -> bool:
	if data == null:
		return false
	return str(data.route_type) == ROUTE_TYPE


static func parent_biome_id(abyss_id: String) -> String:
	return str(PARENT_BIOME_BY_ABYSS.get(abyss_id, ""))


## 10F チャンク番号（0始まり）。1–10→0、11–20→1 …
static func floor_block_index(floor_1based: int) -> int:
	return int((maxi(1, floor_1based) - 1) / CHUNK_FLOORS)


## チャンク先頭階（1, 11, 21…）。天候再抽選の境界。
static func is_block_start_floor(floor_1based: int) -> bool:
	var f: int = maxi(1, floor_1based)
	return ((f - 1) % CHUNK_FLOORS) == 0


## 偶数チャンク=Early（背景1）、奇数=Late（背景2）。
static func uses_early_battle_bg_for_floor(floor_1based: int) -> bool:
	return (floor_block_index(floor_1based) % 2) == 0


## 表示階（1始まり）→ 合成ティア（セレクトの Hard/NM とは独立）。
static func synthetic_tier_for_floor(floor_1based: int) -> int:
	var f: int = maxi(1, floor_1based)
	if f >= FLOOR_NIGHTMARE_START:
		return _DungeonTierConfig.TIER_NIGHTMARE
	if f >= FLOOR_HARD_START:
		return _DungeonTierConfig.TIER_HARD
	return _DungeonTierConfig.TIER_NORMAL


## 深層の敵Lv（絶対値）。階数＝Lv の単純式は使わない。
static func enemy_level_for_floor(floor_1based: int) -> int:
	var f: int = maxi(1, floor_1based)
	var lv_at_99: int = LEVEL_ANCHORS[LEVEL_ANCHORS.size() - 1].y
	if f >= FLOOR_ENDLESS_START:
		return lv_at_99 + int((f - 99) / ENDLESS_LEVEL_STEP)
	if f <= LEVEL_ANCHORS[0].x:
		return maxi(1, LEVEL_ANCHORS[0].y)
	for i in range(1, LEVEL_ANCHORS.size()):
		var prev: Vector2i = LEVEL_ANCHORS[i - 1]
		var cur: Vector2i = LEVEL_ANCHORS[i]
		if f > cur.x:
			continue
		if f == cur.x:
			return maxi(1, cur.y)
		if f == prev.x:
			return maxi(1, prev.y)
		var span: int = cur.x - prev.x
		if span <= 0:
			return maxi(1, cur.y)
		var t: float = float(f - prev.x) / float(span)
		return maxi(1, int(round(lerpf(float(prev.y), float(cur.y), t))))
	return maxi(1, lv_at_99)


## 互換: 旧「ボーナス」呼び出しは絶対Lvへ（深層は base+bonus しない）。
static func enemy_level_bonus_for_floor(floor_1based: int) -> int:
	return enemy_level_for_floor(floor_1based)
