class_name GachaRarityConfig
extends RefCounted

## ガチャ助っ人の★帯ルール（P3-GACHA-005 / **P3-GACHA-008**）。
## 基本5職スターター（adventurer_0..4）は対象外 — ガチャプールのみ。
## 現行プールは ★2〜4（★1 はプールなし・重み0）。

const MIN_RARITY: int = 1
const MAX_RARITY: int = 4

const RARITY_WEIGHTS: Dictionary = {
	1: 0.0,
	2: 0.50,
	3: 0.35,
	4: 0.15,
}

const REFUND_BY_RARITY: Dictionary = {
	1: 1,
	2: 1,
	3: 2,
	4: 4,
}

# 素体（BASE_MEMBER_HP=30）への加算。戦闘・UI 表示で使用。
const STAT_BONUS_BY_RARITY: Dictionary = {
	1: {"hp": 0, "attack": 0, "defense": 0},
	2: {"hp": 3, "attack": 1, "defense": 0},
	3: {"hp": 6, "attack": 2, "defense": 1},
	4: {"hp": 10, "attack": 4, "defense": 2},
}

static func clamp_rarity(rarity: int) -> int:
	return clampi(rarity, MIN_RARITY, MAX_RARITY)

static func get_stat_bonuses(rarity: int) -> Dictionary:
	return STAT_BONUS_BY_RARITY.get(clamp_rarity(rarity), STAT_BONUS_BY_RARITY[1]).duplicate()

static func get_refund(rarity: int) -> int:
	return int(REFUND_BY_RARITY.get(clamp_rarity(rarity), 1))

static func roll_rarity_tier() -> int:
	var roll: float = randf()
	var acc: float = 0.0
	for tier in range(MIN_RARITY, MAX_RARITY + 1):
		var w: float = float(RARITY_WEIGHTS.get(tier, 0.0))
		if w <= 0.0:
			continue
		acc += w
		if roll <= acc:
			return tier
	return 2

static func rate_display_text() -> String:
	return "★2 %.0f%% / ★3 %.0f%% / ★4 %.0f%%（未所持優先）" % [
		float(RARITY_WEIGHTS.get(2, 0.0)) * 100.0,
		float(RARITY_WEIGHTS.get(3, 0.0)) * 100.0,
		float(RARITY_WEIGHTS.get(4, 0.0)) * 100.0,
	]

static func apply_base_stats_to_adventurer(adv: Resource, rarity: int, base_hp: int) -> void:
	if adv == null:
		return
	var stats_class = load("res://scripts/domain/Stats.gd")
	var bonuses: Dictionary = get_stat_bonuses(rarity)
	var stats = stats_class.new()
	stats.hp = base_hp + int(bonuses.get("hp", 0))
	stats.attack = int(bonuses.get("attack", 0))
	stats.defense = int(bonuses.get("defense", 0))
	adv.base_stats = stats
