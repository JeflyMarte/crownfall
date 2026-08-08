class_name CombatTactics
extends RefCounted

## 行動方針（旧・戦術）— 6択＋重み付きルーレット。
## カスタム行動ルールはオミット。実行は DungeonScene が roll_turn_plan に従う。
## P3-BAL-TACTICS-SUPPORT-001: 回復閾値・バフ再付与・スキルスロット内カテゴリ偏り。
##
## slot: "ultimate" | "defend" | "skill" | "attack"
## Target: front | lowest_hp | highest_hp | highest_atk | enemy_with_status | enemy_marked | enemy_with_debuff | back

const DEFAULT_TACTICS_ID: String = "balanced"
const DEFAULT_TARGET: String = "front"
const TARGET_RULES: Array[String] = [
	"front", "lowest_hp", "highest_hp", "highest_atk", "enemy_with_status", "enemy_marked", "enemy_with_debuff", "back",
]

## 最傷 HP がこの未満なら方針閾値より優先して回復可。
const HEAL_EMERGENCY_RATIO: float = 0.35

## 旧プリセット ID → 新行動方針。
const LEGACY_ID_MAP: Dictionary = {
	"aggressive": "attack_focus",
	"cautious": "defend_focus",
	"survival": "defend_focus",
	"sweep": "attack_focus",
	"fodder_focus": "attack_focus",
	"boss_focus": "attack_focus",
	"attack_only": "ultimate_focus",
}

const _DEFS: Dictionary = {
	"balanced": {
		"display_name": "バランス",
		"summary_hint": "スキル・必殺・防御を状況で混ぜる。毎回少しブレる。",
		"target": "front",
	},
	"attack_focus": {
		"display_name": "攻撃特化",
		"summary_hint": "防御せず、スキル・必殺・通常攻撃で攻める。軽傷では回復しにくい。",
		"target": "lowest_hp",
	},
	"conserve_ultimate": {
		"display_name": "必殺温存",
		"summary_hint": "普段は必殺を温存。ボス・エリートやピンチで使いやすい。",
		"target": "front",
	},
	"ultimate_focus": {
		"display_name": "必殺優先",
		"summary_hint": "チャージが溜まり次第、必殺を惜しまず撃つ。",
		"target": "lowest_hp",
	},
	"defend_focus": {
		"display_name": "防御重視",
		"summary_hint": "防御を選びやすい。火力は控えめ。",
		"target": "lowest_hp",
	},
	"support_focus": {
		"display_name": "サポート優先",
		"summary_hint": "回復・バフ系スキルを優先。無いときはバランス寄り。",
		"target": "front",
	},
}

const _ORDER: Array[String] = [
	"balanced",
	"attack_focus",
	"conserve_ultimate",
	"ultimate_focus",
	"defend_focus",
	"support_focus",
]

## 方針ごとの回復可閾値（最傷味方 HP 割合がこの未満）。
const _HEAL_HP_THRESHOLD: Dictionary = {
	"attack_focus": 0.45,
	"conserve_ultimate": 0.55,
	"ultimate_focus": 0.50,
	"balanced": 0.65,
	"defend_focus": 0.70,
	"support_focus": 0.80,
}

## スキルスロット内カテゴリ重み。
const _SKILL_CATEGORY_WEIGHTS: Dictionary = {
	"attack_focus": {"damage": 70.0, "heal": 15.0, "buff": 15.0},
	"conserve_ultimate": {"damage": 55.0, "heal": 25.0, "buff": 20.0},
	"ultimate_focus": {"damage": 65.0, "heal": 20.0, "buff": 15.0},
	"balanced": {"damage": 45.0, "heal": 30.0, "buff": 25.0},
	"defend_focus": {"damage": 35.0, "heal": 35.0, "buff": 30.0},
	"support_focus": {"damage": 20.0, "heal": 45.0, "buff": 35.0},
}

static func tactics_list() -> Array:
	var out: Array = []
	for id in _ORDER:
		out.append({
			"id": id,
			"display_name": _DEFS[id]["display_name"],
			"summary_hint": str(_DEFS[id].get("summary_hint", "")),
		})
	return out

static func normalize_id(tactics_id: String) -> String:
	if _DEFS.has(tactics_id):
		return tactics_id
	if LEGACY_ID_MAP.has(tactics_id):
		return str(LEGACY_ID_MAP[tactics_id])
	return DEFAULT_TACTICS_ID

static func display_name(tactics_id: String) -> String:
	return str(_DEFS[normalize_id(tactics_id)]["display_name"])

static func summary_hint(tactics_id: String) -> String:
	return str(_DEFS[normalize_id(tactics_id)].get("summary_hint", ""))

static func get_target_rule(tactics_id: String) -> String:
	var rule: String = str(_DEFS[normalize_id(tactics_id)].get("target", DEFAULT_TARGET))
	return rule if rule in TARGET_RULES else DEFAULT_TARGET

## UI／コピー用の代表プラン（実行時は roll_turn_plan を使う）。
static func get_slot_plan(tactics_id: String) -> Array:
	match normalize_id(tactics_id):
		"attack_focus":
			return [
				{"slot": "ultimate", "condition": "always"},
				{"slot": "skill", "condition": "always"},
				{"slot": "attack", "condition": "always"},
			]
		"ultimate_focus":
			return [
				{"slot": "ultimate", "condition": "always"},
				{"slot": "skill", "condition": "always"},
				{"slot": "attack", "condition": "always"},
			]
		"defend_focus":
			return [
				{"slot": "defend", "condition": "self_hp_below", "value": 0.55},
				{"slot": "skill", "condition": "always"},
				{"slot": "attack", "condition": "always"},
			]
		"conserve_ultimate":
			return [
				{"slot": "ultimate", "condition": "enemy_is_boss"},
				{"slot": "ultimate", "condition": "enemy_is_elite"},
				{"slot": "skill", "condition": "always"},
				{"slot": "attack", "condition": "always"},
			]
		"support_focus":
			return [
				{"slot": "skill", "condition": "always"},
				{"slot": "attack", "condition": "always"},
			]
		_:
			return [
				{"slot": "ultimate", "condition": "enemy_is_boss"},
				{"slot": "defend", "condition": "self_hp_below", "value": 0.20},
				{"slot": "skill", "condition": "always"},
				{"slot": "attack", "condition": "always"},
			]

## 1ターン分の行動候補を重み付きで並べる（先頭が本命、以降フォールバック）。
static func roll_turn_plan(
	tactics_id: String,
	ctx: Dictionary,
	member: Resource = null,
	rng: RandomNumberGenerator = null
) -> Array:
	var id: String = normalize_id(tactics_id)
	if id == "support_focus" and not member_has_support_skill(member):
		id = DEFAULT_TACTICS_ID
	var weights: Dictionary = _slot_weights(id, ctx)
	var slots: Array[String] = []
	var wlist: Array[float] = []
	for slot in ["ultimate", "defend", "skill", "attack"]:
		var w: float = float(weights.get(slot, 0.0))
		if w > 0.0:
			slots.append(slot)
			wlist.append(w)
	if slots.is_empty():
		return [{"slot": "attack", "condition": "always"}]
	var picked: String = _weighted_pick(slots, wlist, rng)
	var ordered: Array[String] = [picked]
	## 残りは重み降順でフォールバック（攻撃は最後の安全網）。
	var rest: Array = []
	for i in slots.size():
		var s: String = slots[i]
		if s == picked:
			continue
		rest.append({"slot": s, "w": wlist[i]})
	rest.sort_custom(_weight_entry_desc)
	for entry in rest:
		var s2: String = str(entry["slot"])
		if s2 not in ordered:
			ordered.append(s2)
	if "attack" not in ordered:
		ordered.append("attack")
	var plan: Array = []
	for slot in ordered:
		plan.append({"slot": slot, "condition": "always"})
	return plan

static func member_has_support_skill(member: Resource) -> bool:
	return preferred_support_skill_index(member) >= 0

static func preferred_support_skill_index(member: Resource) -> int:
	if member == null:
		return -1
	var ids: Array[String] = GameState.get_equipped_skill_ids(member)
	for i in ids.size():
		if _is_support_skill(DataRegistry.get_skill_data(str(ids[i]))):
			return i
	return -1

static func _is_support_skill(skill_data: Resource) -> bool:
	if skill_data == null:
		return false
	var effect: String = str(skill_data.get("effect_type"))
	if effect == "heal" or effect == "buff":
		return true
	var target: String = str(skill_data.get("target_type"))
	if target == "ally" or target == "party":
		return true
	if "tags" in skill_data and skill_data.tags is Array:
		for tag in skill_data.tags:
			var t: String = str(tag)
			if t == "support" or t == "heal" or t == "buff":
				return true
	return false

## スキル効果カテゴリ: damage | heal | buff（その他は damage 扱い）。
static func skill_category(skill_data: Resource) -> String:
	if skill_data == null:
		return "damage"
	var effect: String = str(skill_data.get("effect_type"))
	if effect == "heal":
		return "heal"
	if effect == "buff":
		return "buff"
	return "damage"

static func heal_hp_threshold(tactics_id: String) -> float:
	var id: String = normalize_id(tactics_id)
	return float(_HEAL_HP_THRESHOLD.get(id, _HEAL_HP_THRESHOLD[DEFAULT_TACTICS_ID]))

## 最傷味方 HP 割合に対し、この方針で回復スキルを撃ってよいか。
static func heal_allowed(tactics_id: String, ally_lowest_hp_ratio: float) -> bool:
	var id: String = normalize_id(tactics_id)
	if ally_lowest_hp_ratio < 0.0:
		## 負傷者なし（全快）は不可。呼び出し側は ratio=1.0 を渡す。
		return false
	if ally_lowest_hp_ratio < HEAL_EMERGENCY_RATIO:
		return true
	return ally_lowest_hp_ratio < heal_hp_threshold(id)

## バフ再付与を抑止するか（true=撃たない）。ctx に status 被覆情報を要する。
static func buff_reapply_blocked(skill_data: Resource, tactics_id: String, ctx: Dictionary) -> bool:
	if skill_data == null:
		return false
	if str(skill_data.get("effect_type")) != "buff":
		return false
	var status_id: String = ""
	if "apply_status_id" in skill_data:
		status_id = str(skill_data.apply_status_id)
	if status_id.is_empty():
		return false
	var target: String = str(skill_data.get("target_type"))
	var self_only: bool = target == "self"
	if "tags" in skill_data and skill_data.tags is Array:
		for tag in skill_data.tags:
			if str(tag) == "self":
				self_only = true
				break
	var pet_only: bool = target == "pet"
	if "tags" in skill_data and skill_data.tags is Array:
		for tag in skill_data.tags:
			if str(tag) == "pet_only":
				pet_only = true
				break
	var self_status: Dictionary = ctx.get("self_status", {}) as Dictionary
	var pet_status: Dictionary = ctx.get("pet_status", {}) as Dictionary
	var ally_target_has: Dictionary = ctx.get("ally_buff_target_has", {}) as Dictionary
	var holders_map: Dictionary = ctx.get("status_holders", {}) as Dictionary
	if self_only:
		return bool(self_status.get(status_id, false))
	if pet_only:
		return bool(pet_status.get(status_id, false))
	if target == "ally":
		return bool(ally_target_has.get(status_id, false))
	## all_party / party / 既定全体
	var living: int = int(ctx.get("living_ally_count", 0))
	if living <= 0:
		return false
	var holders: int = int(holders_map.get(status_id, 0))
	if normalize_id(tactics_id) == "support_focus":
		return holders >= living
	## 過半が所持なら温存
	return holders * 2 > living

static func skill_category_weights(tactics_id: String) -> Dictionary:
	var id: String = normalize_id(tactics_id)
	if _SKILL_CATEGORY_WEIGHTS.has(id):
		return (_SKILL_CATEGORY_WEIGHTS[id] as Dictionary).duplicate()
	return (_SKILL_CATEGORY_WEIGHTS[DEFAULT_TACTICS_ID] as Dictionary).duplicate()

## 利用可能なカテゴリから1つを重み付き抽選。空なら ""。
static func pick_skill_category(
	tactics_id: String,
	available_categories: Array,
	rng: RandomNumberGenerator = null
) -> String:
	if available_categories.is_empty():
		return ""
	var base: Dictionary = skill_category_weights(tactics_id)
	var cats: Array[String] = []
	var wlist: Array[float] = []
	for cat_v in available_categories:
		var cat: String = str(cat_v)
		var w: float = float(base.get(cat, 0.0))
		if w <= 0.0:
			w = 1.0
		cats.append(cat)
		wlist.append(w)
	return _weighted_pick(cats, wlist, rng)

## カテゴリ重み降順のリスト（フォールバック用）。
static func skill_category_order(tactics_id: String) -> Array[String]:
	var base: Dictionary = skill_category_weights(tactics_id)
	var entries: Array = []
	for cat in ["damage", "heal", "buff"]:
		entries.append({"cat": cat, "w": float(base.get(cat, 0.0))})
	entries.sort_custom(_weight_entry_desc)
	var out: Array[String] = []
	for e in entries:
		out.append(str(e["cat"]))
	return out

static func _slot_weights(tactics_id: String, ctx: Dictionary) -> Dictionary:
	var hp: float = float(ctx.get("self_hp_ratio", 1.0))
	var boss: bool = bool(ctx.get("enemy_is_boss", false))
	var elite: bool = bool(ctx.get("enemy_is_elite", false))
	var strong: bool = boss or elite
	match tactics_id:
		"ultimate_focus":
			## 必殺を惜しまず。溜まり次第最優先に寄せる。
			var ult_uf: float = 58.0
			if strong:
				ult_uf = 72.0
			var defend_uf: float = 4.0
			if hp < 0.20:
				defend_uf = 12.0
			return {"ultimate": ult_uf, "defend": defend_uf, "skill": 24.0, "attack": 18.0}
		"attack_focus":
			## P3-BAL-TACTICS-SUPPORT-001: スキルやや下げ・通常を厚く。
			var ult_af: float = 18.0
			if strong:
				ult_af = 48.0
			return {"ultimate": ult_af, "defend": 0.0, "skill": 36.0, "attack": 46.0}
		"conserve_ultimate":
			var ult: float = 0.0
			if strong:
				ult = 48.0
			elif hp < 0.25:
				ult = 22.0
			## P3-BAL-DEFEND-WEIGHT-001 案A: ピンチ防御半減。
			var defend: float = 6.0
			if hp < 0.25:
				defend = 20.0
			return {"ultimate": ult, "defend": defend, "skill": 48.0, "attack": 32.0}
		"defend_focus":
			## 防御重視は据置（方針そのものが防御寄り）。
			var defend2: float = 48.0
			if hp < 0.55:
				defend2 = 70.0
			var ult2: float = 8.0
			if strong:
				ult2 = 28.0
			return {"ultimate": ult2, "defend": defend2, "skill": 22.0, "attack": 18.0}
		"support_focus":
			var ult5: float = 6.0
			if strong:
				ult5 = 24.0
			var defend4: float = 6.0
			if hp < 0.25:
				defend4 = 15.0
			return {"ultimate": ult5, "defend": defend4, "skill": 58.0, "attack": 22.0}
		_:
			## balanced — P3-BAL-DEFEND-WEIGHT-001 案A
			var ult6: float = 10.0
			if strong:
				ult6 = 38.0
			var defend5: float = 5.0
			if hp < 0.20:
				defend5 = 18.0
			return {"ultimate": ult6, "defend": defend5, "skill": 42.0, "attack": 28.0}

static func _weight_entry_desc(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("w", 0.0)) > float(b.get("w", 0.0))


static func _weighted_pick(slots: Array[String], weights: Array[float], rng: RandomNumberGenerator) -> String:
	var total: float = 0.0
	for w in weights:
		total += maxf(0.0, w)
	if total <= 0.0:
		return slots[0] if not slots.is_empty() else "attack"
	var roll: float
	if rng != null:
		roll = rng.randf() * total
	else:
		roll = randf() * total
	var acc: float = 0.0
	for i in slots.size():
		acc += maxf(0.0, weights[i])
		if roll <= acc:
			return slots[i]
	return slots[slots.size() - 1]

# 1 ルールの条件が戦闘コンテキストで成立するか。
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
			## 互換: 軽傷含む欠損あり。回復可否は heal_allowed を使う。
			return bool(ctx.get("ally_injured", false))
		"ally_hp_below":
			return float(ctx.get("ally_lowest_hp_ratio", 1.0)) < float(rule.get("value", 0.0))
	return false

static func skill_reserve_met(skill_data: Resource, ctx: Dictionary) -> bool:
	if skill_data == null:
		return true
	var tactics_id: String = str(ctx.get("tactics_id", DEFAULT_TACTICS_ID))
	var effect: String = str(skill_data.get("effect_type"))
	if effect == "heal":
		var ratio: float = float(ctx.get("ally_lowest_hp_ratio", 1.0))
		if not heal_allowed(tactics_id, ratio):
			return false
	elif effect == "buff":
		if buff_reapply_blocked(skill_data, tactics_id, ctx):
			return false
	var cond: String = ""
	if "reserve_condition" in skill_data:
		cond = str(skill_data.reserve_condition)
	## 旧 ally_injured 温存は heal_allowed に吸収（二重ゲートを避ける）。
	if cond == "ally_injured" and effect == "heal":
		return true
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
