class_name DungeonTierConfig
extends RefCounted

## 同一ダンジョン内の危険度ティア（P3-DG-TIER / P3-D164 → P3-DG-TIER-002 上書き）。
## Hard/Nightmare はメイン5 Biome のキャンペーン周回帯。
## H1-1 > N5-5、NM1-1 > H5-5 になるよう敵Lvボーナスを N 最終章 cap から導出する。

const TIER_NORMAL: int = 0
const TIER_HARD: int = 1
const TIER_NIGHTMARE: int = 2
const TIER_COUNT: int = 3

## メイン周回の対象 Biome（N1→N5 / H1→H5 / NM1→NM5）
const MAIN_BIOME_IDS: Array[String] = [
	"mourngate",
	"whisperwood",
	"mistfen",
	"blackshore",
	"frostridge",
]

const RARITY_WEIGHT_MULT: Array[float] = [1.0, 1.3, 1.6]
const REWARD_MULT: Array[float] = [1.0, 1.2, 1.4]

static var _cached_normal_cap: int = -1


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


## メインノーマル最終（N5-5）相当の敵Lv。ステージデータから最大値を取る。
static func main_normal_cap_level() -> int:
	if _cached_normal_cap > 0:
		return _cached_normal_cap
	var cap: int = 1
	for biome_id: String in MAIN_BIOME_IDS:
		for stage: Variant in DataRegistry.get_stages_for_biome(biome_id):
			if stage == null:
				continue
			cap = maxi(cap, int(stage.enemy_level))
	_cached_normal_cap = maxi(1, cap)
	return _cached_normal_cap


## Hard = +N5-5相当、Nightmare = +2×N5-5相当 → H1-1(=1+cap) > N5-5、NM1-1 > H5-5。
static func enemy_level_bonus(tier: int) -> int:
	var cap: int = main_normal_cap_level()
	match clamp_tier(tier):
		TIER_HARD:
			return cap
		TIER_NIGHTMARE:
			return cap * 2
		_:
			return 0


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


## メイン5 Biome すべてが当該ティアクリア済みか（Hard/NM キャンペーン解放判定）。
static func is_main_campaign_tier_cleared(tier: int) -> bool:
	var t: int = clamp_tier(tier)
	for biome_id: String in MAIN_BIOME_IDS:
		if t == TIER_NORMAL:
			if not GameState.is_dungeon_cleared(biome_id):
				return false
		elif not GameState.is_dungeon_tier_cleared(biome_id, t):
			return false
	return true


## テスト用。キャッシュを破棄する。
static func clear_cap_cache() -> void:
	_cached_normal_cap = -1
