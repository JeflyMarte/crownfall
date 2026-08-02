class_name EquipmentRollHelper
extends RefCounted

## 装備ドロップ時のレア度別ランダムステータス数・パーフェクトロール表示。

## Noto / 本文フォントで確実に出る ★（絵文字⭐️はグリフ欠落で見えないことがある）。
const PERFECT_STAR: String = "★"

const RANDOM_STAT_COUNT: Dictionary = {
	Enums.Rarity.COMMON: 1,
	Enums.Rarity.RARE: 2,
	Enums.Rarity.EPIC: 3,
	Enums.Rarity.LEGENDARY: 4,
	Enums.Rarity.MYTHIC: 4,
	Enums.Rarity.SET: 4,
}

static func random_stat_count(rarity: int) -> int:
	return int(RANDOM_STAT_COUNT.get(rarity, RANDOM_STAT_COUNT[Enums.Rarity.COMMON]))

static func pick_random_stats(pool: Array[String], count: int) -> Array[String]:
	if pool.is_empty() or count <= 0:
		return []
	var available: Array[String] = pool.duplicate()
	available.shuffle()
	var take: int = mini(count, available.size())
	return available.slice(0, take)

static func perfect_roll_count(item: Resource) -> int:
	if item == null:
		return 0
	## 移行セーブでも mods から再集計（表示名★と一致させる）。
	var _Mods = load("res://scripts/equipment/EquipmentRandomMods.gd")
	_Mods.ensure_migrated(item)
	if not ("perfect_roll_count" in item):
		return 0
	return maxi(0, int(item.perfect_roll_count))


## ランダム行が1本以上 MAX（★）に到達しているか（装備一覧「MAXあり」フィルタ用）。
static func has_any_perfect_roll(item: Resource) -> bool:
	return perfect_roll_count(item) > 0


static func perfect_roll_suffix(item: Resource) -> String:
	var count: int = perfect_roll_count(item)
	if count <= 0:
		return ""
	var out: String = ""
	for _i in count:
		out += PERFECT_STAR
	## 例: 最初の剣　★★
	return "　" + out

static func roll_int_bonus(roll_max: int) -> Dictionary:
	if roll_max <= 0:
		return {"value": 0, "perfect": true}
	var bonus: int = randi() % (roll_max + 1)
	return {"value": bonus, "perfect": bonus >= roll_max}

static func roll_rate_value(rarity: int, min_table: Dictionary, max_table: Dictionary) -> Dictionary:
	var min_val: float = float(min_table.get(rarity, min_table[Enums.Rarity.COMMON]))
	var max_val: float = float(max_table.get(rarity, max_table[Enums.Rarity.COMMON]))
	if max_val <= min_val:
		return {"value": max_val, "perfect": true}
	const STEPS: int = 10
	var step: int = randi() % (STEPS + 1)
	var value: float = min_val + (max_val - min_val) * float(step) / float(STEPS)
	return {"value": value, "perfect": step >= STEPS}

static func roll_float_bonus(max_bonus: float, steps: int = 10) -> Dictionary:
	if max_bonus <= 0.0:
		return {"value": 0.0, "perfect": true}
	var step: int = randi() % (steps + 1)
	var value: float = max_bonus * float(step) / float(steps)
	return {"value": value, "perfect": step >= steps}
