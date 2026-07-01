class_name CombatLinks
extends RefCounted

## パーティ連携連鎖（P3-D115）。メンバー間の協力ボーナス。
## 状態コンボ（CombatCombos）とは別枠。1ヒットで link は1種のみ（コンボとは併用可）。

const DEBUFF_MARK_STATUSES: Array = [
	"mark", "poison", "bleed", "vulnerable", "fear", "armor_break", "curse", "slow", "stun", "chill",
]

const _RULES: Dictionary = {
	"taunt_link": {"label": "連携斬", "hit_fraction": 0.25, "max_charges": 3},
	"debuff_mark": {"label": "追い込み", "hit_fraction": 0.20},
	"heal_rally": {"label": "治癒連携", "hit_fraction": 0.15},
}

static func is_debuff_mark_status(status_id: String) -> bool:
	return status_id in DEBUFF_MARK_STATUSES

static func taunt_max_charges() -> int:
	return int(_RULES["taunt_link"].get("max_charges", 3))

static func bonus_for(link_id: String, hit_damage: int) -> int:
	var rule: Dictionary = _RULES.get(link_id, {})
	if rule.is_empty() or hit_damage <= 0:
		return 0
	return maxi(0, int(round(float(rule.get("hit_fraction", 0.0)) * float(hit_damage))))

static func label_for(link_id: String) -> String:
	return str(_RULES.get(link_id, {}).get("label", "連携"))

# 装備画面用の固定説明（常時有効な連携ルール）。
static func hint_lines() -> PackedStringArray:
	return PackedStringArray([
		"挑発後 味方攻撃+25%（最大3回）",
		"デバフ付与→他員追撃+20%",
		"回復対象の次攻撃+15%",
	])
