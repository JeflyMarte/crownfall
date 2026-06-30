class_name CombatTactics
extends RefCounted

## 戦術（AI最上位設定）— P3-D086。
## メンバーの 1 行動で「どのスロットをどの優先度・条件で使うか」を定義する。
## スロット選択の実行は DungeonScene が本ヘルパの plan に従って行う。
##
## slot: "ultimate" | "defend" | "skill" | "attack"
## condition: "always" | "self_hp_below" | "enemy_is_boss" | "enemy_is_elite"
##          | "enemy_count_gte" | "ally_dead"
## value: 条件の閾値（self_hp_below=HP割合 / enemy_count_gte=体数）。
##
## plan は優先度順（Very High → Low）。DungeonScene は先頭から評価し、
## 条件成立かつ実際に発動できた最初のスロットで行動を確定する。
## Target 層（敵個体の狙い分け・P3-D100）: 各戦術に target ルールを持たせ、
## 戦闘ステップ開始時に隊長の戦術 target で生存敵からフォーカス1体を選び全員集中する。
## ルール: "front"（先頭＝従来）| "lowest_hp" | "highest_hp" | "highest_atk"。
## 個別ターゲット/混成エンカウント/敵別状態異常は後続（P3-D100-2）。

const DEFAULT_TACTICS_ID: String = "balanced"
const DEFAULT_TARGET: String = "front"
const TARGET_RULES: Array[String] = ["front", "lowest_hp", "highest_hp", "highest_atk"]

const _DEFS: Dictionary = {
	"balanced": {
		"display_name": "バランス",
		"target": "front",
		"plan": [
			{"slot": "ultimate", "condition": "always"},
			{"slot": "defend", "condition": "self_hp_below", "value": 0.30},
			{"slot": "skill", "condition": "always"},
			{"slot": "attack", "condition": "always"},
		],
	},
	"aggressive": {
		"display_name": "積極攻撃",
		"target": "lowest_hp",
		"plan": [
			{"slot": "ultimate", "condition": "always"},
			{"slot": "skill", "condition": "always"},
			{"slot": "attack", "condition": "always"},
		],
	},
	"cautious": {
		"display_name": "慎重",
		"target": "front",
		"plan": [
			{"slot": "defend", "condition": "self_hp_below", "value": 0.50},
			{"slot": "ultimate", "condition": "always"},
			{"slot": "skill", "condition": "always"},
			{"slot": "attack", "condition": "always"},
		],
	},
	"survival": {
		"display_name": "生存優先",
		"target": "lowest_hp",
		"plan": [
			{"slot": "defend", "condition": "self_hp_below", "value": 0.60},
			{"slot": "skill", "condition": "always"},
			{"slot": "ultimate", "condition": "always"},
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
		"target": "lowest_hp",
		"plan": [
			{"slot": "ultimate", "condition": "enemy_count_gte", "value": 2},
			{"slot": "skill", "condition": "always"},
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
#       enemy_count:int, ally_dead:bool}
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
	return false
