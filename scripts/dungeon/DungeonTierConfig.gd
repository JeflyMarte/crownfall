class_name DungeonTierConfig
extends RefCounted

## 同一ダンジョン内の危険度ティア（P3-DG-TIER / P3-DG-TIER-002 → P3-BAL-NM-CAP99-001 上書き）。
## Hard/Nightmare はメイン5 Biome のキャンペーン周回帯。
## ノーマル最終の推奨Lvを起点に、H終端≈75／NM終端≈99 になるよう加算する。

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

## P3-BAL-NM-CAP99-001 — 終端の推奨Lv目標（N終端推奨からの差分でボーナス導出）。
const TARGET_HARD_END_RECOMMENDED: int = 75
const TARGET_NIGHTMARE_END_RECOMMENDED: int = 99

const RARITY_WEIGHT_MULT: Array[float] = [1.0, 1.3, 1.6]
const REWARD_MULT: Array[float] = [1.0, 1.2, 1.4]
## P3-BAL-CLEAR-TOKEN-HALF-001: クリア魔晶石基礎帯（旧35–65の半減。ティア倍率は reward_mult）
const CLEAR_TOKEN_MIN: int = 18
const CLEAR_TOKEN_MAX: int = 33
## 群れの率・質（P3-BAL-SWARM-002 → P3-BAL-TIER-ENC-A-001 上書き）。N / H / NM。
const SWARM_CHANCE_MULT: Array[float] = [1.0, 1.35, 1.75]
const SWARM_SIZE_BONUS: Array[int] = [0, 1, 2]
const SWARM_MIXED_CHANCE: Array[float] = [0.50, 0.65, 0.80]
const SWARM_SIZE_CAP: int = 5
## NM エリート部屋: 双エリート＋薄い護衛 vs 単エリート＋厚い護衛の抽選（案A）。
const NM_ELITE_DUAL_CHANCE: float = 0.50

static var _cached_normal_cap: int = -1
static var _cached_normal_end_rec: int = -1


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


## ボス戦闘中の指定召喚（沼王招来等）。ノーマル不可・Hard+ のみ（P3-BAL-BOSS-SUMMON-HARD-PLUS-001）。
static func boss_midcombat_summon_allowed(tier: int = -1) -> bool:
	var t: int = tier
	if t < 0:
		t = int(GameState.current_dungeon_tier)
	return clamp_tier(t) >= TIER_HARD


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


## メインノーマル最終の推奨Lv（通常は N5-5）。H/NM ボーナスの起点。
static func main_normal_end_recommended_level() -> int:
	if _cached_normal_end_rec > 0:
		return _cached_normal_end_rec
	var rec: int = 1
	for biome_id: String in MAIN_BIOME_IDS:
		for stage: Variant in DataRegistry.get_stages_for_biome(biome_id):
			if stage == null:
				continue
			rec = maxi(rec, int(stage.recommended_level))
	_cached_normal_end_rec = maxi(1, rec)
	return _cached_normal_end_rec


## Hard / Nightmare の敵・推奨Lv加算（P3-BAL-NM-CAP99-001）。
## H終端推奨≈75、NM終端推奨≈99。旧 +cap/+2cap（H1-1>N5-5 強制）は廃止。
static func enemy_level_bonus(tier: int) -> int:
	var n_end: int = main_normal_end_recommended_level()
	match clamp_tier(tier):
		TIER_HARD:
			return maxi(0, TARGET_HARD_END_RECOMMENDED - n_end)
		TIER_NIGHTMARE:
			return maxi(0, TARGET_NIGHTMARE_END_RECOMMENDED - n_end)
		_:
			return 0


## ノーマル基準の推奨／敵Lvを、選択中ティアの実態に合わせる。
static func apply_tier_level(base_level: int, tier: int) -> int:
	if base_level <= 0:
		return 0
	return base_level + enemy_level_bonus(tier)


static func rarity_weight_mult(tier: int) -> float:
	return RARITY_WEIGHT_MULT[clamp_tier(tier)]


static func reward_mult(tier: int) -> float:
	return REWARD_MULT[clamp_tier(tier)]


## クリア時魔晶石（基礎18–33 × ティア報酬倍率、切り上げ）。深層マイルストーンとは別。
static func clear_token_reward(tier: int) -> int:
	var base: int = randi_range(CLEAR_TOKEN_MIN, CLEAR_TOKEN_MAX)
	var mult: float = reward_mult(tier)
	return maxi(1, int(ceil(float(base) * mult)))


static func swarm_chance_mult(tier: int) -> float:
	return SWARM_CHANCE_MULT[clamp_tier(tier)]


static func swarm_size_bonus(tier: int) -> int:
	return SWARM_SIZE_BONUS[clamp_tier(tier)]


static func swarm_mixed_chance(tier: int) -> float:
	return SWARM_MIXED_CHANCE[clamp_tier(tier)]


static func swarm_size_cap() -> int:
	return SWARM_SIZE_CAP


static func summary_text(tier: int) -> String:
	if tier <= TIER_NORMAL:
		return ""
	var bonus: int = enemy_level_bonus(tier)
	var rare: float = rarity_weight_mult(tier)
	var reward: float = reward_mult(tier)
	var swarm: float = swarm_chance_mult(tier)
	return "敵Lv+%d / レア×%.1f / 報酬×%.1f / 群れ×%.2f" % [bonus, rare, reward, swarm]


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
	_cached_normal_end_rec = -1
