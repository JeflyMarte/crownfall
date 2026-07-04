class_name DungeonTierConfig
extends RefCounted

## 同一ダンジョン内の危険度ティア（P3-DG-TIER / P3-D164）。Biome difficulty（★）とは別軸。

const TIER_NORMAL: int = 0
const TIER_HARD: int = 1
const TIER_NIGHTMARE: int = 2
const TIER_COUNT: int = 3

const ENEMY_LEVEL_BONUS: Array[int] = [0, 3, 6]
const RARITY_WEIGHT_MULT: Array[float] = [1.0, 1.3, 1.6]
const REWARD_MULT: Array[float] = [1.0, 1.2, 1.4]

static func clamp_tier(tier: int) -> int:
	return clampi(tier, TIER_NORMAL, TIER_NIGHTMARE)

static func display_name(tier: int) -> String:
	match clamp_tier(tier):
		TIER_HARD:
			return "ハード"
		TIER_NIGHTMARE:
			return "ナイトメア"
		_:
			return "ノーマル"

static func enemy_level_bonus(tier: int) -> int:
	return ENEMY_LEVEL_BONUS[clamp_tier(tier)]

static func rarity_weight_mult(tier: int) -> float:
	return RARITY_WEIGHT_MULT[clamp_tier(tier)]

static func reward_mult(tier: int) -> float:
	return REWARD_MULT[clamp_tier(tier)]

static func summary_text(tier: int) -> String:
	if tier <= TIER_NORMAL:
		return ""
	var bonus: int = enemy_level_bonus(tier)
	var rare: float = rarity_weight_mult(tier)
	var reward: float = reward_mult(tier)
	return "敵Lv+%d / レア×%.1f / 報酬×%.1f" % [bonus, rare, reward]
