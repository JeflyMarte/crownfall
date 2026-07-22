class_name GachaRarityConfig
extends RefCounted

## ガチャ助っ人の★帯ルール（P3-GACHA-005 / **P3-GACHA-008**）。
## 基本5職スターター（adventurer_0..4）は対象外 — ガチャプールのみ。
## 現行プールは ★2〜4（★1 はプールなし・重み0）。

const _CharacterStatBonuses = preload("res://scripts/roster/CharacterStatBonuses.gd")

const MIN_RARITY: int = 1
const MAX_RARITY: int = 4

const RARITY_WEIGHTS: Dictionary = {
	1: 0.0,
	2: 0.50,
	3: 0.35,
	4: 0.15,
}

const REFUND_BY_RARITY: Dictionary = {
	1: 25,
	2: 50,
	3: 100,
	4: 150,
}

# 素体（BASE_MEMBER_HP=800）への加算。戦闘・UI 表示で使用。
# P3-STAT-CHAR-001: ★帯を広げて 4>3>2>1 が読めるようにする。個差は CharacterStatBonuses。
const STAT_BONUS_BY_RARITY: Dictionary = {
	1: {"hp": 0, "attack": 0, "defense": 0},
	2: {"hp": 100, "attack": 70, "defense": 45},
	3: {"hp": 380, "attack": 190, "defense": 115},
	4: {"hp": 780, "attack": 360, "defense": 290},
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
	return "★2 %.0f%% / ★3 %.0f%% / ★4 %.0f%%" % [
		float(RARITY_WEIGHTS.get(2, 0.0)) * 100.0,
		float(RARITY_WEIGHTS.get(3, 0.0)) * 100.0,
		float(RARITY_WEIGHTS.get(4, 0.0)) * 100.0,
	]

## personal: CharacterStatBonuses の {hp, attack, defense}。★帯に加算。
static func apply_base_stats_to_adventurer(
	adv: Resource,
	rarity: int,
	base_hp: int,
	personal: Dictionary = {}
) -> void:
	if adv == null:
		return
	var stats_class = load("res://scripts/domain/Stats.gd")
	var bonuses: Dictionary = get_stat_bonuses(rarity)
	var pers: Dictionary = _CharacterStatBonuses.normalize_bonus(personal)
	var bonus_scale: float = BalanceConfig.ALLY_STAT_BONUS_SCALE
	var atk_scale: float = BalanceConfig.ALLY_ATK_BONUS_SCALE
	var bonus_hp: int = int(round(float(int(bonuses.get("hp", 0)) + int(pers.get("hp", 0))) * bonus_scale))
	var bonus_atk: int = int(round(float(int(bonuses.get("attack", 0)) + int(pers.get("attack", 0))) * atk_scale))
	var bonus_def: int = int(round(float(int(bonuses.get("defense", 0)) + int(pers.get("defense", 0))) * bonus_scale))
	var stats = stats_class.new()
	stats.hp = maxi(1, base_hp + bonus_hp)
	## ATK/DEF 0 禁止（見栄え）
	stats.attack = maxi(1, bonus_atk)
	stats.defense = maxi(1, bonus_def)
	adv.base_stats = stats


## 冒険者 id / レア / 個人補正を解決して base_stats を書き込む（ロード同期用）。
static func apply_stats_for_adventurer(adv: Resource) -> void:
	if adv == null:
		return
	var rarity: int = clamp_rarity(int(adv.rarity) if "rarity" in adv else MIN_RARITY)
	var base_hp: int = CombatController.BASE_MEMBER_HP
	var adv_id: String = str(adv.id)
	if adv_id.begins_with("gacha_"):
		var helper: Resource = DataRegistry.get_gacha_helper_data(adv_id.trim_prefix("gacha_"))
		if helper != null:
			rarity = clamp_rarity(int(helper.rarity))
			adv.rarity = rarity
			if helper.base_stats != null and int(helper.base_stats.hp) > 0:
				base_hp = int(helper.base_stats.hp)
	apply_base_stats_to_adventurer(
		adv,
		rarity,
		base_hp,
		_CharacterStatBonuses.for_adventurer(adv)
	)
