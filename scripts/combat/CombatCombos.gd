class_name CombatCombos
extends RefCounted

## 状態異常コンボ（P3-D089 / P3-D109）。
## 味方の攻撃が敵に当たる瞬間、前提状態が乗っていれば「起爆」し、
## 追加ダメージを与えてその状態を消費する（1ヒット1コンボ）。
##
## 敵側 trigger: 敵の状態異常を消費（既存）。
## 味方側 ally trigger: 攻撃者自身のバフ等を消費（バフ→必殺・P3-D109）。
##
## ルール: trigger 状態 → { label, per_stack, hit_fraction, require_tag }
##   bonus = per_stack * stacks + round(hit_fraction * hit_damage)
##   require_tag … 攻撃側がこのシナジータグ(CombatTags)を持つ時のみ起爆（空=無条件）。
## 数値は調整可。

const _RULES: Dictionary = {
	"poison": {"label": "毒爆発", "per_stack": BalanceConfig.COMBO_POISON_PER_STACK, "hit_fraction": 0.0, "require_tag": ""},
	"bleed": {"label": "出血追撃", "per_stack": BalanceConfig.COMBO_BLEED_PER_STACK, "hit_fraction": 0.0, "require_tag": "slash"},
	"chill": {"label": "粉砕", "per_stack": 0, "hit_fraction": 0.5, "require_tag": ""},
	"shock": {"label": "感電", "per_stack": 0, "hit_fraction": 0.4, "require_tag": "lightning"},
}

# 評価順（先に成立したものを1つだけ起爆）。
const _ORDER: Array = ["poison", "bleed", "chill", "shock"]

# 味方自身のバフを消費するコンボ（P3-D109）。敵コンボ不成立時のみ評価。
const _ALLY_RULES: Dictionary = {
	"empower": {
		"label": "鼓舞必殺",
		"per_stack": 0,
		"hit_fraction": 0.35,
		"require_tag": "ultimate",
	},
}

const _ALLY_ORDER: Array = ["empower"]

static func trigger_ids() -> Array:
	return _ORDER

static func ally_trigger_ids() -> Array:
	return _ALLY_ORDER

static func rule(trigger_id: String) -> Dictionary:
	return _RULES.get(trigger_id, {})

static func ally_rule(trigger_id: String) -> Dictionary:
	return _ALLY_RULES.get(trigger_id, {})

# 起爆に必要な攻撃側タグ（空=無条件）。
static func require_tag(trigger_id: String) -> String:
	return str(_RULES.get(trigger_id, {}).get("require_tag", ""))

static func ally_require_tag(trigger_id: String) -> String:
	return str(_ALLY_RULES.get(trigger_id, {}).get("require_tag", ""))

# 攻撃側タグ条件を満たすか。
static func tag_eligible(trigger_id: String, attacker_tags: Array) -> bool:
	var req: String = require_tag(trigger_id)
	return req.is_empty() or req in attacker_tags

static func ally_tag_eligible(trigger_id: String, attacker_tags: Array) -> bool:
	var req: String = ally_require_tag(trigger_id)
	return req.is_empty() or req in attacker_tags

static func bonus_for(trigger_id: String, stacks: int, hit_damage: int) -> int:
	var r: Dictionary = _RULES.get(trigger_id, {})
	if r.is_empty() or stacks <= 0:
		return 0
	var bonus: int = int(r.get("per_stack", 0)) * stacks
	bonus += int(round(float(r.get("hit_fraction", 0.0)) * float(hit_damage)))
	return maxi(0, bonus)

static func ally_bonus_for(trigger_id: String, stacks: int, hit_damage: int) -> int:
	var r: Dictionary = _ALLY_RULES.get(trigger_id, {})
	if r.is_empty() or stacks <= 0:
		return 0
	var bonus: int = int(r.get("per_stack", 0)) * stacks
	bonus += int(round(float(r.get("hit_fraction", 0.0)) * float(hit_damage)))
	return maxi(0, bonus)
