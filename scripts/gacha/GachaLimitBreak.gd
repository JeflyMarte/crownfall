class_name GachaLimitBreak
extends RefCounted

## ガチャ助っ人の限界突破（P3-GACHA-LIMIT-001 / 案B）。
## owned_helpers 所持数: 1=未凸、2..=+1〜。上限 +5（所持6以上は効果頭打ち）。

const MAX_BREAKTHROUGH: int = 5
const PER_STACK_EFFECT: float = 0.10


static func owned_count(helper_id: String) -> int:
	if helper_id.is_empty():
		return 0
	return int(GameState.owned_helpers.get(helper_id, 0))


static func breakthrough_from_owned_count(count: int) -> int:
	return clampi(count - 1, 0, MAX_BREAKTHROUGH)


static func breakthrough_for_helper_id(helper_id: String) -> int:
	return breakthrough_from_owned_count(owned_count(helper_id))


static func breakthrough_for_member(member: Resource) -> int:
	if member == null:
		return 0
	var mid: String = str(member.id)
	if not mid.begins_with("gacha_"):
		return 0
	return breakthrough_for_helper_id(mid.trim_prefix("gacha_"))


static func effect_scale(breakthrough: int) -> float:
	var n: int = clampi(breakthrough, 0, MAX_BREAKTHROUGH)
	return 1.0 + PER_STACK_EFFECT * float(n)


static func tag_text(breakthrough: int) -> String:
	var n: int = clampi(breakthrough, 0, MAX_BREAKTHROUGH)
	if n <= 0:
		return ""
	return "限界突破 +%d" % n


static func format_member_display_name(member: Resource) -> String:
	if member == null:
		return ""
	var base: String = str(member.display_name)
	var tag: String = tag_text(breakthrough_for_member(member))
	if tag.is_empty():
		return base
	return "%s（%s）" % [base, tag]


static func scale_passive_def(def: Dictionary, breakthrough: int) -> Dictionary:
	if def.is_empty():
		return {}
	var scale: float = effect_scale(breakthrough)
	if scale <= 1.001:
		return def.duplicate(true)
	var out: Dictionary = def.duplicate(true)
	for key: String in [
		"outgoing_mult",
		"first_attack_mult",
		"ultimate_power_mult",
		"skill_power_mult",
		"exp_gain_mult",
		"party_exp_gain_mult",
		"speed_mult",
	]:
		if out.has(key):
			out[key] = _scale_mult_above_one(float(out[key]), scale)
	if out.has("incoming_mult"):
		out["incoming_mult"] = _scale_mult_below_one(float(out["incoming_mult"]), scale)
	for key: String in ["evasion_rate_add", "status_chance", "incoming_block_chance"]:
		if out.has(key):
			out[key] = minf(1.0, float(out[key]) * scale)
	if out.has("heal_max_hp_fraction"):
		out["heal_max_hp_fraction"] = minf(0.5, float(out["heal_max_hp_fraction"]) * scale)
	if str(out.get("effect", "")) == "heal" and out.has("value"):
		out["value"] = maxi(1, int(round(float(out["value"]) * scale)))
	if str(out.get("condition", "")) == "self_hp_below" and out.has("value"):
		## 閾値を上げて発火しやすく（効果強化の代替）
		out["value"] = minf(0.9, float(out["value"]) * scale)
	if out.has("cooldown") and float(out["cooldown"]) > 0.0:
		out["cooldown"] = maxf(0.5, float(out["cooldown"]) / scale)
	return out


static func _scale_mult_above_one(mult: float, scale: float) -> float:
	if mult > 1.0:
		return 1.0 + (mult - 1.0) * scale
	if mult < 1.0 and mult > 0.0:
		return 1.0 - (1.0 - mult) * scale
	return mult


static func _scale_mult_below_one(mult: float, scale: float) -> float:
	## 被ダメ倍率: 1未満＝軽減。軽減幅を scale 倍。
	if mult < 1.0 and mult > 0.0:
		return maxf(0.05, 1.0 - (1.0 - mult) * scale)
	if mult > 1.0:
		return 1.0 + (mult - 1.0) * scale
	return mult
