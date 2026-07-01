class_name CombatTactics
extends RefCounted

## 戦術（AI最上位設定）— P3-D086。
## メンバーの 1 行動で「どのスロットをどの優先度・条件で使うか」を定義する。
## スロット選択の実行は DungeonScene が本ヘルパの plan に従って行う。
##
## slot: "ultimate" | "defend" | "skill" | "attack"
## condition: "always" | "self_hp_below" | "enemy_is_boss" | "enemy_is_elite"
##          | "enemy_count_gte" | "ally_dead"
##          | "enemy_has_bleed" | "enemy_has_poison" | "enemy_has_mark" | "ultimate_ready"
##          | "enemy_has_stun" | "enemy_has_vulnerable" | "enemy_has_armor_break" | "enemy_has_fear"（P3-D127）
##          | "self_range"（P3-D108・フェーズB-5）
##          | "ally_injured"（P3-D113・味方に負傷者がいる）
## value: 条件の閾値（self_hp_below=HP割合 / enemy_count_gte=体数 / self_range=melee|mid|long）。
##
## plan は優先度順（Very High → Low）。DungeonScene は先頭から評価し、
## 条件成立かつ実際に発動できた最初のスロットで行動を確定する。
## Target 層（P3-D100/D111）: 各メンバーが戦術 target で個別に狙う（混成時に分散可能）。
## ルール: front | lowest_hp | highest_hp | highest_atk | enemy_with_status | enemy_marked | enemy_with_debuff | back

const DEFAULT_TACTICS_ID: String = "balanced"
const DEFAULT_TARGET: String = "front"
const TARGET_RULES: Array[String] = [
	"front", "lowest_hp", "highest_hp", "highest_atk", "enemy_with_status", "enemy_marked", "enemy_with_debuff", "back",
]

const _DEFS: Dictionary = {
	"balanced": {
		"display_name": "バランス",
		"target": "front",
		"plan": [
			{"slot": "ultimate", "condition": "ultimate_ready"},
			{"slot": "defend", "condition": "self_hp_below", "value": 0.30},
			{"slot": "skill", "condition": "always"},
			{"slot": "attack", "condition": "always"},
		],
	},
	"aggressive": {
		"display_name": "積極攻撃",
		"target": "lowest_hp",
		"plan": [
			{"slot": "ultimate", "condition": "ultimate_ready"},
			{"slot": "skill", "condition": "enemy_has_mark"},
			{"slot": "skill", "condition": "enemy_has_bleed"},
			{"slot": "skill", "condition": "always"},
			{"slot": "attack", "condition": "always"},
		],
	},
	"cautious": {
		"display_name": "慎重",
		"target": "back",
		"plan": [
			{"slot": "defend", "condition": "self_hp_below", "value": 0.50},
			{"slot": "ultimate", "condition": "ultimate_ready"},
			{"slot": "skill", "condition": "enemy_has_stun"},
			{"slot": "skill", "condition": "self_range", "value": "mid"},
			{"slot": "attack", "condition": "always"},
		],
	},
	"survival": {
		"display_name": "生存優先",
		"target": "lowest_hp",
		"plan": [
			{"slot": "defend", "condition": "self_hp_below", "value": 0.60},
			{"slot": "skill", "condition": "always"},
			{"slot": "ultimate", "condition": "ultimate_ready"},
			{"slot": "attack", "condition": "always"},
		],
	},
	"boss_focus": {
		"display_name": "ボス集中",
		"target": "highest_hp",
		"plan": [
			{"slot": "ultimate", "condition": "enemy_is_boss"},
			{"slot": "ultimate", "condition": "enemy_is_elite"},
			{"slot": "defend", "condition": "self_hp_below", "value": 0.30},
			{"slot": "skill", "condition": "always"},
			{"slot": "attack", "condition": "always"},
		],
	},
	"sweep": {
		"display_name": "雑魚掃討",
		"target": "enemy_with_debuff",
		"plan": [
			{"slot": "ultimate", "condition": "enemy_count_gte", "value": 2},
			{"slot": "skill", "condition": "enemy_has_mark"},
			{"slot": "skill", "condition": "enemy_has_vulnerable"},
			{"slot": "skill", "condition": "enemy_has_poison"},
			{"slot": "attack", "condition": "always"},
		],
	},
}

# 戦術の target ルール（既定 front）。
static func get_target_rule(tactics_id: String) -> String:
	var rule: String = str(_DEFS[normalize_id(tactics_id)].get("target", DEFAULT_TARGET))
	return rule if rule in TARGET_RULES else DEFAULT_TARGET

# 選択UI用の順序付きリスト。各要素 {"id","display_name"}。
const _ORDER: Array[String] = [
	"balanced", "aggressive", "cautious", "survival", "boss_focus", "sweep",
]

static func tactics_list() -> Array:
	var out: Array = []
	for id in _ORDER:
		out.append({"id": id, "display_name": _DEFS[id]["display_name"]})
	return out

static func normalize_id(tactics_id: String) -> String:
	if _DEFS.has(tactics_id):
		return tactics_id
	return DEFAULT_TACTICS_ID

static func display_name(tactics_id: String) -> String:
	return str(_DEFS[normalize_id(tactics_id)]["display_name"])

# 優先度順のスロット計画を返す。
static func get_slot_plan(tactics_id: String) -> Array:
	return _DEFS[normalize_id(tactics_id)]["plan"]

# 1 ルールの条件が戦闘コンテキストで成立するか。
# ctx: {self_hp_ratio:float, enemy_is_boss:bool, enemy_is_elite:bool,
#       enemy_count:int, ally_dead:bool,
#       enemy_has_bleed:bool, enemy_has_poison:bool, enemy_has_mark:bool,
#       enemy_has_stun:bool, enemy_has_vulnerable:bool, enemy_has_armor_break:bool, enemy_has_fear:bool,
#       ultimate_ready:bool,
#       self_range:String, ally_injured:bool}  # P3-D108 / P3-D113
static func condition_met(rule: Dictionary, ctx: Dictionary) -> bool:
	match str(rule.get("condition", "always")):
		"always":
			return true
		"self_hp_below":
			return float(ctx.get("self_hp_ratio", 1.0)) < float(rule.get("value", 0.0))
		"enemy_is_boss":
			return bool(ctx.get("enemy_is_boss", false))
		"enemy_is_elite":
			return bool(ctx.get("enemy_is_elite", false))
		"enemy_count_gte":
			return int(ctx.get("enemy_count", 1)) >= int(rule.get("value", 1))
		"ally_dead":
			return bool(ctx.get("ally_dead", false))
		"enemy_has_bleed":
			return bool(ctx.get("enemy_has_bleed", false))
		"enemy_has_poison":
			return bool(ctx.get("enemy_has_poison", false))
		"enemy_has_mark":
			return bool(ctx.get("enemy_has_mark", false))
		"enemy_has_stun":
			return bool(ctx.get("enemy_has_stun", false))
		"enemy_has_vulnerable":
			return bool(ctx.get("enemy_has_vulnerable", false))
		"enemy_has_armor_break":
			return bool(ctx.get("enemy_has_armor_break", false))
		"enemy_has_fear":
			return bool(ctx.get("enemy_has_fear", false))
		"ultimate_ready":
			return bool(ctx.get("ultimate_ready", false))
		"self_range":
			return str(ctx.get("self_range", "melee")) == str(rule.get("value", "melee"))
		"ally_injured":
			return bool(ctx.get("ally_injured", false))
	return false

# スキル温存（P3-D113）。reserve_condition 空なら常に使用可。
static func skill_reserve_met(skill_data: Resource, ctx: Dictionary) -> bool:
	if skill_data == null:
		return true
	var cond: String = ""
	if "reserve_condition" in skill_data:
		cond = str(skill_data.reserve_condition)
	if cond.is_empty():
		return true
	var rule: Dictionary = {"condition": cond}
	if "reserve_value" in skill_data:
		var raw_val: String = str(skill_data.reserve_value)
		if not raw_val.is_empty():
			if raw_val.is_valid_float():
				rule["value"] = float(raw_val)
			else:
				rule["value"] = raw_val
	return condition_met(rule, ctx)
