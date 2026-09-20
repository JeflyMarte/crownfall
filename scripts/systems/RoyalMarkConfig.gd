class_name RoyalMarkConfig
extends RefCounted

## 王痕育成定数（P3-DG-ROYAL-MARK-001 / Decision 144＋146 分岐）。
## Rank 効果・コスト・★到達片・方針倍率の正本。

const MAX_RANK: int = 5
const MIN_LEVEL: int = 50
const REPEAT_CHANCE: float = 0.25
## 表示スケール×10（難易度比は据置。旧セーブは SAVE v20 で所持×10）。
const SHARD_DISPLAY_SCALE: int = 10
const REPEAT_SHARDS: int = 10

## Decision 146: 王痕方針。
const PATH_UNSELECTED: String = "unselected"
const PATH_OFFENSE: String = "offense"
const PATH_DEFENSE: String = "defense"
const PATH_TECHNIQUE: String = "technique"
const PATH_SELECTABLE: Array[String] = [PATH_OFFENSE, PATH_DEFENSE, PATH_TECHNIQUE]

## Rank I..V への昇格コスト（index 0 = Rank 0→I）。
const UPGRADE_SHARD_COST: Array[int] = [100, 150, 200, 250, 300]
const UPGRADE_GOLD_COST: Array[int] = [5000, 10000, 15000, 25000, 45000]

## ★帯ごとの初回到達片（★1..4）。表示×10。
const STAR_SHARD_REWARD: Array[int] = [0, 30, 30, 40, 50]
## SAVE <20 遡及用（旧単位）。v20 で所持を ×SHARD_DISPLAY_SCALE。
const LEGACY_STAR_SHARD_REWARD: Array[int] = [0, 3, 3, 4, 5]

## Rank → 累積ステ倍率（HP/ATK/DEF）。
const RANK_HP_MULT: Array[float] = [1.00, 1.03, 1.03, 1.03, 1.05, 1.08]
const RANK_ATK_MULT: Array[float] = [1.00, 1.00, 1.03, 1.03, 1.05, 1.08]
const RANK_DEF_MULT: Array[float] = [1.00, 1.00, 1.00, 1.03, 1.05, 1.08]

## 方針解放／Ult ゲート。
const PATH_MIN_RANK: int = 3
const SKILL_ENHANCE_MIN_RANK: int = 3
const ULTIMATE_ENHANCE_MIN_RANK: int = 5

## 旧 III Job Skill（unselected 専用・Decision 144 相当）。
const JOB_DAMAGE_POWER_MULT: float = 1.10
const JOB_HEAL_POWER_MULT: float = 1.15
const JOB_STATUS_CHANCE_ADD: float = 0.10
const JOB_BUFF_DURATION_ADD: int = 1
const JOB_TRAP_POWER_MULT: float = 1.10

## 技巧（index = Rank 0..5）。
const TECH_DAMAGE_POWER_MULT: Array[float] = [1.0, 1.0, 1.0, 1.10, 1.15, 1.20]
const TECH_HEAL_POWER_MULT: Array[float] = [1.0, 1.0, 1.0, 1.15, 1.20, 1.25]
const TECH_TRAP_POWER_MULT: Array[float] = [1.0, 1.0, 1.0, 1.10, 1.15, 1.20]
const TECH_STATUS_CHANCE_ADD: Array[float] = [0.0, 0.0, 0.0, 0.10, 0.15, 0.20]
const TECH_BUFF_DURATION_ADD: int = 1
const TECH_COUNTER_ADD: int = 1

## 攻勢 outgoing／守勢 incoming（index = Rank）。
const OFFENSE_OUTGOING_MULT: Array[float] = [1.0, 1.0, 1.0, 1.02, 1.04, 1.06]
const DEFENSE_INCOMING_MULT: Array[float] = [1.0, 1.0, 1.0, 0.97, 0.95, 0.92]

const ULT_DAMAGE_POWER_MULT: float = 1.08
const ULT_HEAL_POWER_ADD: float = 0.03
const ULT_HEAL_POWER_ADD_SMALL: float = 0.02
const STATUS_CHANCE_CAP: float = 1.0

## Rank III 対象外スキル。
const SKILL_ENHANCE_EXCLUDE_IDS: Array[String] = ["trail_ward"]

## Rank V 個別 Ultimate（skill_id → 補正辞書）。Decision 146 最低保証込み。
const ULTIMATE_OVERRIDES: Dictionary = {
	"vg_gate_counter": {"counter_add": 1, "duration_add": 1},
	"eng_full_arm_cascade": {"cascade_add": 1},
	"eng_armor_gekigeki": {"vs_armor_break_mult": 1.45},
	## 火鷹: duration 維持＋威力最低保証（146）
	"critical_storm": {"duration_add": 1, "damage_mult": 1.08},
	"blood_drain": {"duration_add": 1},
	"heartbeat": {"heal_add": 0.02, "duration_add": 1},
	"elemental_boost": {"duration_add": 1},
	"grand_elixir": {"heal_add": 0.03},
	## レノール: 付与満額のため威力最低保証（146）
	"curse_burst": {"damage_mult": 1.08},
}


static func ultimate_override_for(skill_id: String) -> Dictionary:
	if skill_id.is_empty() or not ULTIMATE_OVERRIDES.has(skill_id):
		return {}
	return (ULTIMATE_OVERRIDES[skill_id] as Dictionary).duplicate(true)


static func clamp_rank(rank: int) -> int:
	return clampi(rank, 0, MAX_RANK)


static func normalize_path(raw: Variant) -> String:
	var p: String = str(raw).strip_edges()
	if p.is_empty() or p == PATH_UNSELECTED:
		return PATH_UNSELECTED
	if p in PATH_SELECTABLE:
		return p
	return PATH_UNSELECTED


static func is_selected_path(path: String) -> bool:
	return normalize_path(path) in PATH_SELECTABLE


static func path_display_name(path: String) -> String:
	match normalize_path(path):
		PATH_OFFENSE:
			return "攻勢"
		PATH_DEFENSE:
			return "守勢"
		PATH_TECHNIQUE:
			return "技巧"
		_:
			return "未選択"


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


static func offense_outgoing_mult_for_rank(rank: int) -> float:
	return float(OFFENSE_OUTGOING_MULT[clamp_rank(rank)])


static func defense_incoming_mult_for_rank(rank: int) -> float:
	return float(DEFENSE_INCOMING_MULT[clamp_rank(rank)])


static func tech_damage_mult_for_rank(rank: int) -> float:
	return float(TECH_DAMAGE_POWER_MULT[clamp_rank(rank)])


static func tech_heal_mult_for_rank(rank: int) -> float:
	return float(TECH_HEAL_POWER_MULT[clamp_rank(rank)])


static func tech_trap_mult_for_rank(rank: int) -> float:
	return float(TECH_TRAP_POWER_MULT[clamp_rank(rank)])


static func tech_status_add_for_rank(rank: int) -> float:
	return float(TECH_STATUS_CHANCE_ADD[clamp_rank(rank)])


## ★到達差分の片合計。prev_best と stars は 0..4。
static func star_shards_for_progress(prev_best: int, stars: int) -> int:
	return _star_shards_for_progress_with_table(prev_best, stars, STAR_SHARD_REWARD)


## SAVE v17→v18 遡及専用（旧単位）。v20 で ×SHARD_DISPLAY_SCALE。
static func legacy_star_shards_for_progress(prev_best: int, stars: int) -> int:
	return _star_shards_for_progress_with_table(prev_best, stars, LEGACY_STAR_SHARD_REWARD)


static func _star_shards_for_progress_with_table(
	prev_best: int, stars: int, table: Array[int]
) -> int:
	var prev: int = clampi(prev_best, 0, 4)
	var cur: int = clampi(stars, 0, 4)
	if cur <= prev:
		return 0
	var total: int = 0
	for s: int in range(prev + 1, cur + 1):
		total += int(table[s])
	return total


static func retroactive_shards_for_best(best_stars: int) -> int:
	return star_shards_for_progress(0, clampi(best_stars, 0, 4))


static func legacy_retroactive_shards_for_best(best_stars: int) -> int:
	return legacy_star_shards_for_progress(0, clampi(best_stars, 0, 4))


static func effect_label_for_rank(rank: int, path: String = PATH_UNSELECTED) -> String:
	var r: int = clamp_rank(rank)
	var p: String = normalize_path(path)
	var base: String = ""
	match r:
		0:
			return "効果なし"
		1:
			base = "HP +3%"
		2:
			base = "HP +3%／ATK +3%"
		3:
			base = "HP +3%／ATK +3%／DEF +3%"
		4:
			base = "HP/ATK/DEF +5%"
		5:
			base = "HP/ATK/DEF +8%／必殺強化"
		_:
			return "効果なし"
	if r < PATH_MIN_RANK:
		return base
	match p:
		PATH_OFFENSE:
			return "%s／攻勢" % base
		PATH_DEFENSE:
			return "%s／守勢" % base
		PATH_TECHNIQUE:
			return "%s／技巧" % base
		_:
			if r >= PATH_MIN_RANK:
				return "%s／装備スキル強化" % base
			return base


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


static func step_effect_label(to_rank: int) -> String:
	match clamp_rank(to_rank):
		1:
			return "HP +3%"
		2:
			return "ATK +3%"
		3:
			return "DEF +3%／方針解放"
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


static func path_effect_summary(path: String, rank: int) -> String:
	var r: int = clamp_rank(rank)
	var p: String = normalize_path(path)
	if r < PATH_MIN_RANK:
		return "—"
	match p:
		PATH_OFFENSE:
			var pct: int = int(round((offense_outgoing_mult_for_rank(r) - 1.0) * 100.0))
			return "与ダメージ +%d%%" % pct
		PATH_DEFENSE:
			var red: int = int(round((1.0 - defense_incoming_mult_for_rank(r)) * 100.0))
			return "被ダメージ -%d%%" % red
		PATH_TECHNIQUE:
			return "装備スキル強化"
		_:
			return "装備スキル強化"
