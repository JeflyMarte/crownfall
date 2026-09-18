class_name RoyalMarkConfig
extends RefCounted

## 王痕育成定数（P3-DG-ROYAL-MARK-001 / Decision 144）。
## Rank 効果・コスト・★到達片・累積倍率の正本。

const MAX_RANK: int = 5
const MIN_LEVEL: int = 50
const REPEAT_CHANCE: float = 0.25
const REPEAT_SHARDS: int = 1

## Rank I..V への昇格コスト（index 0 = Rank 0→I）。
const UPGRADE_SHARD_COST: Array[int] = [10, 15, 20, 25, 30]
const UPGRADE_GOLD_COST: Array[int] = [5000, 10000, 15000, 25000, 45000]

## ★帯ごとの初回到達片（★1..4）。
const STAR_SHARD_REWARD: Array[int] = [0, 3, 3, 4, 5]

## Rank → 累積ステ倍率（HP/ATK/DEF）。
const RANK_HP_MULT: Array[float] = [1.00, 1.03, 1.03, 1.03, 1.05, 1.08]
const RANK_ATK_MULT: Array[float] = [1.00, 1.00, 1.03, 1.03, 1.05, 1.08]
const RANK_DEF_MULT: Array[float] = [1.00, 1.00, 1.00, 1.03, 1.05, 1.08]

## Phase 2: Job Skill / Ultimate 強化ゲート。
const SKILL_ENHANCE_MIN_RANK: int = 3
const ULTIMATE_ENHANCE_MIN_RANK: int = 5
const JOB_DAMAGE_POWER_MULT: float = 1.10
const JOB_HEAL_POWER_MULT: float = 1.15
const JOB_STATUS_CHANCE_ADD: float = 0.10
const JOB_BUFF_DURATION_ADD: int = 1
const JOB_TRAP_POWER_MULT: float = 1.10
const ULT_DAMAGE_POWER_MULT: float = 1.08
const ULT_HEAL_POWER_ADD: float = 0.03
const ULT_HEAL_POWER_ADD_SMALL: float = 0.02
const STATUS_CHANCE_CAP: float = 1.0

## Rank III 対象外スキル。
const SKILL_ENHANCE_EXCLUDE_IDS: Array[String] = ["trail_ward"]

## Rank V 個別 Ultimate（skill_id → 補正辞書）。巨大 if 連鎖を避ける。
const ULTIMATE_OVERRIDES: Dictionary = {
	## ボルグ: 応撃 +1
	"vg_gate_counter": {"counter_add": 1, "duration_add": 1},
	## ブリキ: cascade +1
	"eng_full_arm_cascade": {"cascade_add": 1},
	## アンヴィ: 甲砕中倍率
	"eng_armor_gekigeki": {"vs_armor_break_mult": 1.45},
	## 火鷹: crit_surge 時間（Passive 非変更）
	"critical_storm": {"duration_add": 1},
	## ルーシェ: blood_drain 時間
	"blood_drain": {"duration_add": 1},
	## ウォール: tag heal +2pp
	"heartbeat": {"heal_add": 0.02, "duration_add": 1},
	## エリアス: attune 時間
	"elemental_boost": {"duration_add": 1},
	## セリン: heal +3pp
	"grand_elixir": {"heal_add": 0.03},
}


static func ultimate_override_for(skill_id: String) -> Dictionary:
	if skill_id.is_empty() or not ULTIMATE_OVERRIDES.has(skill_id):
		return {}
	return (ULTIMATE_OVERRIDES[skill_id] as Dictionary).duplicate(true)


static func clamp_rank(rank: int) -> int:
	return clampi(rank, 0, MAX_RANK)


## Adventurer.id 形式へ正規化。pet／空は空文字。
static func normalize_character_id(raw: String) -> String:
	var id: String = raw.strip_edges()
	if id.is_empty():
		return ""
	if id.begins_with("pet_"):
		return ""
	if id.begins_with("adventurer_") or id.begins_with("gacha_helper_"):
		return id
	if id.begins_with("gacha_"):
		## 既に gacha_helper_* 以外の gacha_ は対象外
		return ""
	if id.begins_with("helper_"):
		return "gacha_%s" % id
	return ""


static func is_human_playable_id(character_id: String) -> bool:
	var id: String = normalize_character_id(character_id)
	if id.is_empty():
		return false
	return id.begins_with("adventurer_") or id.begins_with("gacha_helper_")


static func upgrade_shard_cost(from_rank: int) -> int:
	var r: int = clamp_rank(from_rank)
	if r >= MAX_RANK:
		return 0
	return int(UPGRADE_SHARD_COST[r])


static func upgrade_gold_cost(from_rank: int) -> int:
	var r: int = clamp_rank(from_rank)
	if r >= MAX_RANK:
		return 0
	return int(UPGRADE_GOLD_COST[r])


static func hp_mult_for_rank(rank: int) -> float:
	return float(RANK_HP_MULT[clamp_rank(rank)])


static func atk_mult_for_rank(rank: int) -> float:
	return float(RANK_ATK_MULT[clamp_rank(rank)])


static func def_mult_for_rank(rank: int) -> float:
	return float(RANK_DEF_MULT[clamp_rank(rank)])


static func stat_multipliers_for_rank(rank: int) -> Dictionary:
	var r: int = clamp_rank(rank)
	return {
		"hp": hp_mult_for_rank(r),
		"attack": atk_mult_for_rank(r),
		"defense": def_mult_for_rank(r),
	}


## ★到達差分の片合計。prev_best と stars は 0..4。
static func star_shards_for_progress(prev_best: int, stars: int) -> int:
	var prev: int = clampi(prev_best, 0, 4)
	var cur: int = clampi(stars, 0, 4)
	if cur <= prev:
		return 0
	var total: int = 0
	for s: int in range(prev + 1, cur + 1):
		total += int(STAR_SHARD_REWARD[s])
	return total


## 既存セーブ遡及: best_stars 1→3, 2→6, 3→10, 4→15。
static func retroactive_shards_for_best(best_stars: int) -> int:
	return star_shards_for_progress(0, clampi(best_stars, 0, 4))


## 現在 Rank の累積効果表示。
static func effect_label_for_rank(rank: int) -> String:
	match clamp_rank(rank):
		0:
			return "効果なし"
		1:
			return "HP +3%"
		2:
			return "HP +3%／ATK +3%"
		3:
			return "HP +3%／ATK +3%／DEF +3%／装備スキル強化"
		4:
			return "HP/ATK/DEF +5%／装備スキル強化"
		5:
			return "HP/ATK/DEF +8%／装備スキル強化／必殺強化"
		_:
			return "効果なし"


## UI 用: 累積効果を HP/ATK/DEF 行に分解（未付与は "—"）。
static func effect_stat_lines_for_rank(rank: int) -> PackedStringArray:
	var r: int = clamp_rank(rank)
	return PackedStringArray([
		_stat_line("HP", hp_mult_for_rank(r)),
		_stat_line("ATK", atk_mult_for_rank(r)),
		_stat_line("DEF", def_mult_for_rank(r)),
	])


static func _stat_line(label: String, mult: float) -> String:
	var pct: int = int(round((mult - 1.0) * 100.0))
	if pct <= 0:
		return "%s —" % label
	return "%s +%d%%" % [label, pct]


static func roman_for_rank(rank: int) -> String:
	var r: int = clamp_rank(rank)
	if r <= 0:
		return "—"
	return ["I", "II", "III", "IV", "V"][r - 1]


## Rank 昇格ステップの効果（表の1段階分）。
static func step_effect_label(to_rank: int) -> String:
	match clamp_rank(to_rank):
		1:
			return "HP +3%"
		2:
			return "ATK +3%"
		3:
			return "DEF +3%／装備スキル強化"
		4:
			return "HP/ATK/DEF +2%"
		5:
			return "HP/ATK/DEF +3%／必殺強化"
		_:
			return "—"


static func next_rank_effect_label(current_rank: int) -> String:
	var r: int = clamp_rank(current_rank)
	if r >= MAX_RANK:
		return "MAX"
	return step_effect_label(r + 1)


static func rank_display(rank: int) -> String:
	var r: int = clamp_rank(rank)
	if r <= 0:
		return "未覚醒"
	return "王痕 %s" % ["I", "II", "III", "IV", "V"][r - 1]
