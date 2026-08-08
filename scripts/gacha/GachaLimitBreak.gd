class_name GachaLimitBreak
extends RefCounted

## 助っ人（および初期5）の限界突破（P3-GACHA-LIMIT-001 / 案B）。
## ガチャ: owned_helpers 所持数 1=未凸、2..=+1〜。上限 +5（所持6以上は効果頭打ち）。
## 初期5: Adventurer.limit_breakthrough（0..5）。★3券で消費。

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
	if mid.begins_with("gacha_"):
		return breakthrough_for_helper_id(mid.trim_prefix("gacha_"))
	## 初期5人など: Adventurer.limit_breakthrough
	return clampi(int(member.limit_breakthrough), 0, MAX_BREAKTHROUGH)


static func effect_scale(breakthrough: int) -> float:
	var n: int = clampi(breakthrough, 0, MAX_BREAKTHROUGH)
	return 1.0 + PER_STACK_EFFECT * float(n)


static func tag_text(breakthrough: int) -> String:
	var n: int = clampi(breakthrough, 0, MAX_BREAKTHROUGH)
	if n <= 0:
		return ""
	return "限凸 +%d" % n


static func plus_suffix(breakthrough: int) -> String:
	## 名前横の短縮表記（例: +2）。
	var n: int = clampi(breakthrough, 0, MAX_BREAKTHROUGH)
	if n <= 0:
		return ""
	return "+%d" % n


static func format_member_display_name(member: Resource) -> String:
	if member == null:
		return ""
	var base: String = str(member.display_name)
	var tag: String = tag_text(breakthrough_for_member(member))
	if tag.is_empty():
		return base
	return "%s（%s）" % [base, tag]


static func format_member_name_plus(member: Resource) -> String:
	## キャラ画面向け: 「名前 +N」（未凸は名前のみ）。
	if member == null:
		return ""
	var base: String = str(member.display_name)
	var suf: String = plus_suffix(breakthrough_for_member(member))
	if suf.is_empty():
		return base
	return "%s %s" % [base, suf]


static func scale_passive_def(def: Dictionary, breakthrough: int) -> Dictionary:
	if def.is_empty():
		return {}
	var scale: float = effect_scale(breakthrough)
	if scale <= 1.001:
		return def.duplicate(true)
	var out: Dictionary = def.duplicate(true)
	for key: String in [
		"outgoing_mult",
		"outgoing_vs_status_mult",
		"elemental_outgoing_mult",
		"first_attack_mult",
		"ultimate_power_mult",
		"skill_power_mult",
		"exp_gain_mult",
		"party_exp_gain_mult",
		"speed_mult",
		"pet_outgoing_mult",
		"pet_defense_mult",
		"pet_max_hp_mult",
	]:
		if out.has(key):
			out[key] = _scale_mult_above_one(float(out[key]), scale)
	if out.has("incoming_mult"):
		out["incoming_mult"] = _scale_mult_below_one(float(out["incoming_mult"]), scale)
	if out.has("party_incoming_mult"):
		out["party_incoming_mult"] = _scale_mult_below_one(float(out["party_incoming_mult"]), scale)
	for key: String in [
		"evasion_rate_add",
		"back_row_evasion_rate_add",
		"evasion_add",
		"status_chance",
		"incoming_block_chance",
		"death_save_chance",
		"threat_base_add",
		"pet_revive_on_combat_end_chance",
		"pet_heal_on_action_max_hp_fraction",
		"pet_revive_max_hp_fraction",
	]:
		if out.has(key):
			if key == "threat_base_add":
				out[key] = float(out[key]) * scale
			else:
				out[key] = minf(1.0, float(out[key]) * scale)
	if out.has("heal_max_hp_fraction"):
		out["heal_max_hp_fraction"] = minf(0.5, float(out["heal_max_hp_fraction"]) * scale)
	if out.has("combat_regen_max_hp_fraction"):
		out["combat_regen_max_hp_fraction"] = minf(
			0.05, float(out["combat_regen_max_hp_fraction"]) * scale
		)
	if out.has("lifesteal_ratio"):
		out["lifesteal_ratio"] = minf(0.35, float(out["lifesteal_ratio"]) * scale)
	if str(out.get("effect", "")) == "grant_party_incoming_mult" and out.has("mult"):
		out["mult"] = _scale_mult_below_one(float(out["mult"]), scale)
	if str(out.get("effect", "")) == "heal" and out.has("value"):
		out["value"] = maxi(1, int(round(float(out["value"]) * scale)))
	if str(out.get("condition", "")) in ["self_hp_below", "ally_hp_below"] and out.has("value"):
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
