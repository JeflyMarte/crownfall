class_name DungeonTierConfig
extends RefCounted

## 同一ダンジョン内の危険度ティア（P3-DG-TIER-STG-001）。Biome difficulty（★）とは別軸。
## 章1-1〜5-5 をノーマル／ハード／ナイトメアで再プレイ。敵Lvは章SSOT + 弧加算。

const TIER_NORMAL: int = 0
const TIER_HARD: int = 1
const TIER_NIGHTMARE: int = 2
const TIER_COUNT: int = 3

## ノーマル章 enemy_level への加算。H1-1=1+49=50 > ノーマル5-5(49)。
const ENEMY_LEVEL_ADD: Array[int] = [0, 49, 74]
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

static func scaled_enemy_level(base_stage_level: int, tier: int) -> int:
	var base: int = maxi(1, base_stage_level)
	return base + ENEMY_LEVEL_ADD[clamp_tier(tier)]

static func enemy_level_bonus(tier: int) -> int:
	## 後方互換。新規は scaled_enemy_level を使用。
	return ENEMY_LEVEL_ADD[clamp_tier(tier)]

static func rarity_weight_mult(tier: int) -> float:
	return RARITY_WEIGHT_MULT[clamp_tier(tier)]

static func reward_mult(tier: int) -> float:
	return REWARD_MULT[clamp_tier(tier)]

static func summary_text(tier: int) -> String:
	if tier <= TIER_NORMAL:
		return ""
	var bonus: int = ENEMY_LEVEL_ADD[clamp_tier(tier)]
	var rare: float = rarity_weight_mult(tier)
	var reward: float = reward_mult(tier)
	return "敵Lv+%d / レア×%.1f / 報酬×%.1f" % [bonus, rare, reward]

static func global_unlock_hint(tier: int) -> String:
	match clamp_tier(tier):
		TIER_HARD:
			return "ノーマル5-5クリアで解放"
		TIER_NIGHTMARE:
			return "ハード5-5クリアで解放"
		_:
			return ""

## 武器ドロップ equip_level のティア別下限（P3-DG-TIER-STG-001）。
## ハード＝ノーマル5-5帯以上 / ナイトメア＝同章ハード帯以上。±1 は呼び出し側で適用後に max。
static func min_weapon_drop_equip_level(tier: int, stage: Resource, dungeon: Resource) -> int:
	match clamp_tier(tier):
		TIER_HARD:
			var final_normal: Resource = DataRegistry.get_stage_data(Constants.FINAL_NORMAL_STAGE_ID)
			if final_normal != null and int(final_normal.enemy_level) > 0:
				return maxi(1, int(final_normal.enemy_level) - 1)
			return 1
		TIER_NIGHTMARE:
			var base_lv: int = _stage_or_dungeon_enemy_level(stage, dungeon)
			return maxi(1, scaled_enemy_level(base_lv, TIER_HARD) - 1)
		_:
			return 1

static func _stage_or_dungeon_enemy_level(stage: Resource, dungeon: Resource) -> int:
	if stage != null and int(stage.enemy_level) > 0:
		return int(stage.enemy_level)
	if dungeon != null and int(dungeon.enemy_level) > 0:
		return int(dungeon.enemy_level)
	return 1
