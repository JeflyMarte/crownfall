class_name CombatGambit
extends RefCounted

## カスタム戦術（ガンビット）のメタデータ（A1）。

const PLAN_ROW_COUNT: int = 5
const RANGE_VALUE_IDS: Array[String] = ["melee", "mid", "long"]

const SLOT_IDS: Array[String] = ["ultimate", "defend", "skill", "attack"]
const CONDITION_IDS: Array[String] = [
	"always", "self_hp_below", "enemy_is_boss", "enemy_is_elite", "enemy_count_gte",
	"ally_dead", "enemy_has_bleed", "enemy_has_poison", "enemy_has_mark",
	"enemy_has_stun", "enemy_has_vulnerable", "enemy_has_armor_break", "enemy_has_fear",
	"ultimate_ready", "self_range", "ally_injured",
]

const _SLOT_NAMES: Dictionary = {
	"ultimate": "必殺", "defend": "防御", "skill": "スキル", "attack": "通常攻撃",
}
const _CONDITION_NAMES: Dictionary = {
	"always": "常時",
	"self_hp_below": "自HPが%未満",
	"enemy_is_boss": "ボス戦",
	"enemy_is_elite": "エリート戦",
	"enemy_count_gte": "敵数≧",
	"ally_dead": "味方戦闘不能",
	"enemy_has_bleed": "敵が出血",
	"enemy_has_poison": "敵が毒",
	"enemy_has_mark": "敵が標的",
	"enemy_has_stun": "敵がスタン",
	"enemy_has_vulnerable": "敵が脆弱",
	"enemy_has_armor_break": "敵が防御DOWN",
	"enemy_has_fear": "敵が恐怖",
	"ultimate_ready": "必殺準備完了",
	"self_range": "射程が",
	"ally_injured": "味方負傷",
}
const _CONDITION_HINTS: Dictionary = {
	"always": "常にこの行を優先順で検討する。",
	"self_hp_below": "自分のHPが指定割合未満（0.30＝30%未満）。",
	"enemy_is_boss": "ボス部屋の戦闘中のみ成立。",
	"enemy_is_elite": "エリート部屋の戦闘中のみ成立。",
	"enemy_count_gte": "生存している敵の数が指定以上。",
	"ally_dead": "パーティに戦闘不能の味方がいる。",
	"enemy_has_bleed": "ターゲット敵に出血がある。",
	"enemy_has_poison": "ターゲット敵に毒がある。",
	"enemy_has_mark": "ターゲット敵に標的（mark）がある。",
	"enemy_has_stun": "ターゲット敵がスタン状態。",
	"enemy_has_vulnerable": "ターゲット敵が脆弱状態。",
	"enemy_has_armor_break": "ターゲット敵が防御DOWN状態。",
	"enemy_has_fear": "ターゲット敵が恐怖状態。",
	"ultimate_ready": "必殺技のCT・CDが整い発動可能。",
	"self_range": "自分の射程区分（melee/mid/long）が一致。",
	"ally_injured": "味方に負傷（HP低下）がいる。スキル温存と併用。",
}
const _TARGET_NAMES: Dictionary = {
	"front": "前衛優先", "lowest_hp": "HP最低", "highest_hp": "HP最高",
	"highest_atk": "攻撃最高", "enemy_with_status": "状態異常優先",
	"enemy_marked": "標的優先", "enemy_with_debuff": "デバフ優先", "back": "後衛優先",
}
const _RANGE_NAMES: Dictionary = {
	"melee": "近距離", "mid": "中距離", "long": "遠距離",
}

static func slot_label(slot_id: String) -> String:
	return str(_SLOT_NAMES.get(slot_id, slot_id))

static func condition_label(condition_id: String) -> String:
	return str(_CONDITION_NAMES.get(condition_id, condition_id))

static func condition_hint(condition_id: String) -> String:
	return str(_CONDITION_HINTS.get(condition_id, ""))

## 戦闘ログ [戦術] 行用の短い条件表示（P3-UX-002）。
static func condition_summary(rule: Dictionary) -> String:
	var cond: String = str(rule.get("condition", "always"))
	var base: String = condition_label(cond)
	if not condition_needs_value(cond):
		return base
	var raw_val = rule.get("value", default_value_for(cond))
	match cond:
		"self_hp_below":
			var pct: int = int(round(float(raw_val) * 100.0))
			return "自HPが%d%%未満" % pct
		"enemy_count_gte":
			return "敵数≧%s" % str(raw_val)
		"self_range":
			return "射程が%s" % range_label(str(raw_val))
	return base

static func target_label(target_id: String) -> String:
	return str(_TARGET_NAMES.get(target_id, target_id))

static func range_label(range_id: String) -> String:
	return str(_RANGE_NAMES.get(range_id, range_id))

## 行動ルール1行のプレビュー（編集UI・戦闘ログと同型 / P3-UX-GAMBIT-001/002）。
static func rule_preview(rule: Dictionary, member: Resource = null) -> String:
	return "%s → %s" % [condition_summary(rule), action_label(rule, member)]

static func action_key_from_rule(rule: Dictionary) -> String:
	var slot: String = str(rule.get("slot", "attack"))
	if slot == "skill":
		return "skill_%d" % clampi(int(rule.get("skill_index", 0)), 0, 1)
	return slot

static func rule_from_action_key(key: String) -> Dictionary:
	if key.begins_with("skill_"):
		var idx: int = int(key.substr(6))
		return {"slot": "skill", "skill_index": clampi(idx, 0, 1)}
	return {"slot": key}

## 編集UIの「使う技」選択肢（P3-UX-GAMBIT-002）。未装備スキルは出さない。
static func action_options_for_member(member: Resource) -> Array:
	var out: Array = []
	out.append({"key": "ultimate", "label": "必殺技"})
	out.append({"key": "defend", "label": "防御"})
	if member != null:
		var ids: Array[String] = GameState.get_equipped_skill_ids(member)
		for i in ids.size():
			out.append({"key": "skill_%d" % i, "label": equipped_skill_label(member, i)})
	out.append({"key": "attack", "label": "通常攻撃"})
	return out

static func equipped_skill_label(member: Resource, skill_index: int) -> String:
	if member == null:
		return "スキル%d" % (skill_index + 1)
	var ids: Array[String] = GameState.get_equipped_skill_ids(member)
	if skill_index < 0 or skill_index >= ids.size():
		return "スキル%d" % (skill_index + 1)
	var sd: Resource = DataRegistry.get_skill_data(str(ids[skill_index]))
	if sd != null and not str(sd.display_name).is_empty():
		return "『%s』" % sd.display_name
	return str(ids[skill_index])

static func action_label(rule: Dictionary, member: Resource = null) -> String:
	var slot: String = str(rule.get("slot", "attack"))
	match slot:
		"ultimate":
			return "必殺技"
		"defend":
			return "防御"
		"attack":
			return "通常攻撃"
		"skill":
			if member != null:
				return equipped_skill_label(member, int(rule.get("skill_index", 0)))
			return slot_label("skill")
	return slot_label(slot)

## プリセット戦術の一行サマリー。
static func preset_summary_line(tactics_id: String, max_rules: int = 4) -> String:
	var plan: Array = CombatTactics.get_slot_plan(tactics_id)
	if plan.is_empty():
		return ""
	var parts: PackedStringArray = []
	var limit: int = maxi(1, max_rules)
	for i in mini(plan.size(), limit):
		if plan[i] is Dictionary:
			parts.append(rule_preview(plan[i]))
	if plan.size() > limit:
		parts.append("…")
	return " → ".join(parts)

## UI表示用（30% → "30"）。
static func hp_percent_display(raw_val: Variant) -> String:
	var ratio: float = float(raw_val) if str(raw_val).is_valid_float() else 0.30
	return str(int(round(ratio * 100.0)))

## UI入力 → 保存値（"30" → 0.30）。
static func hp_percent_storage(text: String) -> float:
	var pct: float = float(text) if text.is_valid_float() else 30.0
	return clampf(pct / 100.0, 0.05, 0.95)

static func condition_needs_value(condition_id: String) -> bool:
	return condition_id in ["self_hp_below", "enemy_count_gte", "self_range"]

static func default_value_for(condition_id: String) -> String:
	match condition_id:
		"self_hp_below":
			return "0.30"
		"enemy_count_gte":
			return "2"
		"self_range":
			return "long"
		_:
			return ""

static func default_plan_row(index: int) -> Dictionary:
	match index:
		0:
			return {"slot": "ultimate", "condition": "ultimate_ready"}
		1:
			return {"slot": "defend", "condition": "self_hp_below", "value": 0.30}
		2:
			return {"slot": "skill", "skill_index": 0, "condition": "always"}
		3:
			return {"slot": "attack", "condition": "always"}
		_:
			return {"slot": "attack", "condition": "always"}

static func assign_skill_indices_for_copy(raw_plan: Array) -> Array:
	var out: Array = []
	var skill_slot: int = 0
	for entry in raw_plan:
		if not entry is Dictionary:
			continue
		var rule: Dictionary = (entry as Dictionary).duplicate()
		if str(rule.get("slot", "")) == "skill":
			rule["skill_index"] = skill_slot % 2
			skill_slot += 1
		out.append(rule)
	return out

static func plan_row_count() -> int:
	return PLAN_ROW_COUNT

static func normalize_plan(raw_plan: Array) -> Array:
	var out: Array = []
	for entry in raw_plan:
		if not entry is Dictionary:
			continue
		var slot: String = str(entry.get("slot", ""))
		if slot not in SLOT_IDS:
			continue
		var cond: String = str(entry.get("condition", "always"))
		if cond not in CONDITION_IDS:
			cond = "always"
		var rule: Dictionary = {"slot": slot, "condition": cond}
		if slot == "skill":
			if entry.has("skill_index"):
				rule["skill_index"] = clampi(int(entry.get("skill_index", 0)), 0, 1)
			else:
				rule["skill_index"] = 0
		if condition_needs_value(cond) and entry.has("value"):
			var raw_val: String = str(entry.get("value", ""))
			if not raw_val.is_empty():
				if cond == "self_hp_below" or cond == "enemy_count_gte":
					rule["value"] = float(raw_val) if raw_val.is_valid_float() else default_value_for(cond)
				else:
					rule["value"] = raw_val
		out.append(rule)
	return out

static func plan_from_member(member: Resource) -> Array:
	if member == null:
		return []
	if bool(member.get("tactics_custom_enabled")):
		var custom: Array = member.get("tactics_custom_plan") if "tactics_custom_plan" in member else []
		var normalized: Array = normalize_plan(custom)
		if not normalized.is_empty():
			return normalized
	var tid: String = CombatTactics.normalize_id(str(member.get("tactics_id") if "tactics_id" in member else ""))
	return CombatTactics.get_slot_plan(tid)

static func target_from_member(member: Resource) -> String:
	if member != null and bool(member.get("tactics_custom_enabled")):
		var custom_target: String = str(member.get("tactics_custom_target") if "tactics_custom_target" in member else "")
		if custom_target in CombatTactics.TARGET_RULES:
			return custom_target
	if member == null:
		return CombatTactics.DEFAULT_TARGET
	return CombatTactics.get_target_rule(CombatTactics.normalize_id(str(member.get("tactics_id") if "tactics_id" in member else "")))
