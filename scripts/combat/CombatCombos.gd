class_name CombatCombos
extends RefCounted

## 状態異常コンボ（P3-D089）。
## 味方の攻撃が敵に当たる瞬間、敵に前提状態が乗っていれば「起爆」し、
## 追加ダメージを与えてその状態を消費する（1ヒット1コンボ）。
##
## ルール: trigger 状態 → { label, per_stack, hit_fraction }
##   bonus = per_stack * stacks + round(hit_fraction * hit_damage)
## 数値は調整可。シナジータグ（Slash/Fire 等）の正式タクソノミは後続。

const _RULES: Dictionary = {
	"poison": {"label": "毒爆発", "per_stack": 8, "hit_fraction": 0.0},
	"chill": {"label": "粉砕", "per_stack": 0, "hit_fraction": 0.5},
}

# 評価順（先に成立したものを1つだけ起爆）。
const _ORDER: Array = ["poison", "chill"]

static func trigger_ids() -> Array:
	return _ORDER

static func rule(trigger_id: String) -> Dictionary:
	return _RULES.get(trigger_id, {})

static func bonus_for(trigger_id: String, stacks: int, hit_damage: int) -> int:
	var r: Dictionary = _RULES.get(trigger_id, {})
	if r.is_empty() or stacks <= 0:
		return 0
	var bonus: int = int(r.get("per_stack", 0)) * stacks
	bonus += int(round(float(r.get("hit_fraction", 0.0)) * float(hit_damage)))
	return maxi(0, bonus)
