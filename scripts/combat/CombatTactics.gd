class_name CombatTactics
extends RefCounted

## 行動方針（旧・戦術）— 7択＋重み付きルーレット。
## カスタム行動ルールはオミット。実行は DungeonScene が roll_turn_plan に従う。
##
## slot: "ultimate" | "defend" | "skill" | "attack"
## Target: front | lowest_hp | highest_hp | highest_atk | enemy_with_status | enemy_marked | enemy_with_debuff | back

const DEFAULT_TACTICS_ID: String = "balanced"
const DEFAULT_TARGET: String = "front"
const TARGET_RULES: Array[String] = [
	"front", "lowest_hp", "highest_hp", "highest_atk", "enemy_with_status", "enemy_marked", "enemy_with_debuff", "back",
]

## 旧プリセット ID → 新行動方針。
const LEGACY_ID_MAP: Dictionary = {
	"aggressive": "fodder_focus",
	"cautious": "defend_focus",
	"survival": "defend_focus",
	"sweep": "fodder_focus",
}

const _DEFS: Dictionary = {
	"balanced": {
		"display_name": "バランス",
		"summary_hint": "スキル・必殺・防御を状況で混ぜる。毎回少しブレる。",
		"target": "front",
	},
	"conserve_ultimate": {
		"display_name": "必殺温存",
		"summary_hint": "普段は必殺を温存。ボス・エリートやピンチで使いやすい。",
		"target": "front",
	},
	"defend_focus": {
		"display_name": "防御重視",
		"summary_hint": "防御を選びやすい。火力は控えめ。",
		"target": "lowest_hp",
	},
	"fodder_focus": {
		"display_name": "雑魚優先",
		"summary_hint": "弱い敵から狙う。群れでは必殺も出やすい。",
		"target": "lowest_hp",
	},
	"boss_focus": {
		"display_name": "強敵優先",
		"summary_hint": "強い敵へ火力を寄せる。必殺も強敵向け。",
		"target": "highest_hp",
	},
	"support_focus": {
		"display_name": "サポート優先",
		"summary_hint": "回復・バフ系スキルを優先。無いときはバランス寄り。",
		"target": "front",
	},
	"attack_only": {
		"display_name": "通常攻撃のみ",
		"summary_hint": "スキル・必殺・防御を使わず殴るだけ。",
		"target": "front",
	},
}

const _ORDER: Array[String] = [
	"balanced",
	"conserve_ultimate",
	"defend_focus",
	"fodder_focus",
	"boss_focus",
	"support_focus",
	"attack_only",
]

static func tactics_list() -> Array:
	var out: Array = []
	for id in _ORDER:
		out.append({"id": id, "display_name": _DEFS[id]["display_name"]})
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
		"attack_only":
			return [{"slot": "attack", "condition": "always"}]
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
		"fodder_focus":
			return [
				{"slot": "ultimate", "condition": "enemy_count_gte", "value": 2},
				{"slot": "skill", "condition": "always"},
				{"slot": "attack", "condition": "always"},
			]
		"boss_focus":
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
				{"slot": "defend", "condition": "self_hp_below", "value": 0.30},
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
	var support_idx: int = preferred_support_skill_index(member)
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
		var rule: Dictionary = {"slot": slot, "condition": "always"}
		if slot == "skill" and support_idx >= 0 and id == "support_focus":
			rule["skill_index"] = support_idx
		plan.append(rule)
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

static func _slot_weights(tactics_id: String, ctx: Dictionary) -> Dictionary:
	var hp: float = float(ctx.get("self_hp_ratio", 1.0))
	var boss: bool = bool(ctx.get("enemy_is_boss", false))
	var elite: bool = bool(ctx.get("enemy_is_elite", false))
	var strong: bool = boss or elite
	var enemies: int = int(ctx.get("enemy_count", 1))
	match tactics_id:
		"attack_only":
			return {"ultimate": 0.0, "defend": 0.0, "skill": 0.0, "attack": 100.0}
		"conserve_ultimate":
			var ult: float = 0.0
			if strong:
				ult = 48.0
			elif hp < 0.25:
				ult = 22.0
			var defend: float = 12.0
			if hp < 0.35:
				defend = 40.0
			return {"ultimate": ult, "defend": defend, "skill": 48.0, "attack": 32.0}
		"defend_focus":
			var defend2: float = 48.0
			if hp < 0.55:
				defend2 = 70.0
			var ult2: float = 8.0
			if strong:
				ult2 = 28.0
			return {"ultimate": ult2, "defend": defend2, "skill": 22.0, "attack": 18.0}
		"fodder_focus":
			var ult3: float = 8.0
			if enemies >= 2:
				ult3 = 36.0
			return {"ultimate": ult3, "defend": 10.0, "skill": 44.0, "attack": 30.0}
		"boss_focus":
			var ult4: float = 12.0
			if strong:
				ult4 = 50.0
			var defend3: float = 8.0
			if hp < 0.30:
				defend3 = 35.0
			return {"ultimate": ult4, "defend": defend3, "skill": 38.0, "attack": 24.0}
		"support_focus":
			var ult5: float = 6.0
			if strong:
				ult5 = 24.0
			var defend4: float = 12.0
			if hp < 0.35:
				defend4 = 30.0
			return {"ultimate": ult5, "defend": defend4, "skill": 58.0, "attack": 22.0}
		_:
			## balanced
			var ult6: float = 10.0
			if strong:
				ult6 = 38.0
			var defend5: float = 10.0
			if hp < 0.30:
				defend5 = 42.0
			return {"ultimate": ult6, "defend": defend5, "skill": 42.0, "attack": 28.0}

static func _weight_entry_desc(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("w", 0.0)) > float(b.get("w", 0.0))


static func _weighted_pick(slots: Array[String], weights: Array[float], rng: RandomNumberGenerator) -> String:
	var total: float = 0.0
	for w in weights:
		total += maxf(0.0, w)
	if total <= 0.0:
		return "attack"
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
			return bool(ctx.get("ally_injured", false))
	return false

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
