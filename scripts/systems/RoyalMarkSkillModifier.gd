class_name RoyalMarkSkillModifier
extends RefCounted

## 王痕 Rank III（装備 Job Skill）／Rank V（固有 Ultimate）の実行時補正。
## Decision 144 Phase 2。ステ倍率は RoyalMarkConfig／System 側（変更しない）。

const _Config := preload("res://scripts/systems/RoyalMarkConfig.gd")
const _System := preload("res://scripts/systems/RoyalMarkSystem.gd")

const META_DURATION_ADD: String = "royal_mark_duration_add"
const META_COUNTER_ADD: String = "royal_mark_counter_add"
const META_CASCADE_ADD: String = "royal_mark_cascade_add"
const META_VS_AB_MULT: String = "royal_mark_vs_armor_break_mult"
const META_ENHANCED: String = "royal_mark_enhanced"


static func skill_enhance_active(rank: int) -> bool:
	return _Config.clamp_rank(rank) >= _Config.SKILL_ENHANCE_MIN_RANK


static func ultimate_enhance_active(rank: int) -> bool:
	return _Config.clamp_rank(rank) >= _Config.ULTIMATE_ENHANCE_MIN_RANK


static func is_excluded_skill(skill_data: Resource) -> bool:
	if skill_data == null:
		return true
	var sid: String = str(skill_data.id)
	if sid.is_empty():
		return true
	if sid in _Config.SKILL_ENHANCE_EXCLUDE_IDS:
		return true
	if skill_data.tags.has("equip_passive"):
		return true
	if str(skill_data.effect_type) == "none":
		return true
	return false


static func is_equipped_job_skill(member: Resource, skill_id: String) -> bool:
	if member == null or skill_id.is_empty():
		return false
	var ids: Array[String] = GameState.get_equipped_skill_ids(member)
	for id: String in ids:
		if id == skill_id:
			return true
	return false


## 戦闘実行直前。必要なら duplicate して補正済み Resource を返す（元は変更しない）。
static func enhance_for_combat(skill_data: Resource, member: Resource) -> Resource:
	if skill_data == null or member == null:
		return skill_data
	if is_excluded_skill(skill_data):
		return skill_data
	var rank: int = _System.rank_of_member(member)
	var is_ult: bool = str(skill_data.slot_type) == "ultimate"
	if is_ult:
		if not ultimate_enhance_active(rank):
			return skill_data
		var ult_copy: Resource = skill_data.duplicate(true)
		_apply_ultimate_enhance(ult_copy)
		ult_copy.set_meta(META_ENHANCED, true)
		return ult_copy
	if not skill_enhance_active(rank):
		return skill_data
	if not is_equipped_job_skill(member, str(skill_data.id)):
		return skill_data
	var job_copy: Resource = skill_data.duplicate(true)
	_apply_job_skill_enhance(job_copy)
	job_copy.set_meta(META_ENHANCED, true)
	return job_copy


static func _has_offensive_status(skill_data: Resource) -> bool:
	if skill_data == null:
		return false
	if not str(skill_data.apply_status_id).is_empty() and float(skill_data.apply_status_chance) > 0.0:
		return true
	if not str(skill_data.apply_status_id2).is_empty() and float(skill_data.apply_status_chance2) > 0.0:
		return true
	if not str(skill_data.apply_status_id3).is_empty() and float(skill_data.apply_status_chance3) > 0.0:
		return true
	return false


static func _clamp_chance(v: float) -> float:
	return clampf(v, 0.0, _Config.STATUS_CHANCE_CAP)


static func _add_status_chances(skill_data: Resource, add: float) -> void:
	if not str(skill_data.apply_status_id).is_empty() and float(skill_data.apply_status_chance) > 0.0:
		skill_data.apply_status_chance = _clamp_chance(float(skill_data.apply_status_chance) + add)
	if not str(skill_data.apply_status_id2).is_empty() and float(skill_data.apply_status_chance2) > 0.0:
		skill_data.apply_status_chance2 = _clamp_chance(float(skill_data.apply_status_chance2) + add)
	if not str(skill_data.apply_status_id3).is_empty() and float(skill_data.apply_status_chance3) > 0.0:
		skill_data.apply_status_chance3 = _clamp_chance(float(skill_data.apply_status_chance3) + add)


static func _apply_job_skill_enhance(skill_data: Resource) -> void:
	if skill_data.tags.has("trap_place"):
		skill_data.power_multiplier = float(skill_data.power_multiplier) * _Config.JOB_TRAP_POWER_MULT
		return
	match str(skill_data.effect_type):
		"heal":
			skill_data.power_multiplier = float(skill_data.power_multiplier) * _Config.JOB_HEAL_POWER_MULT
		"damage":
			if _has_offensive_status(skill_data):
				_add_status_chances(skill_data, _Config.JOB_STATUS_CHANCE_ADD)
			else:
				skill_data.power_multiplier = (
					float(skill_data.power_multiplier) * _Config.JOB_DAMAGE_POWER_MULT
				)
		"buff":
			skill_data.set_meta(META_DURATION_ADD, _Config.JOB_BUFF_DURATION_ADD)
			for raw_tag: Variant in skill_data.tags:
				if str(raw_tag).begins_with("counter_charges_"):
					skill_data.set_meta(META_COUNTER_ADD, 1)
					break
		_:
			pass


static func _apply_ultimate_enhance(skill_data: Resource) -> void:
	var sid: String = str(skill_data.id)
	var ov: Dictionary = _Config.ultimate_override_for(sid)
	if not ov.is_empty():
		_apply_ultimate_override(skill_data, ov)
		return
	## 汎用 Ultimate
	match str(skill_data.effect_type):
		"heal":
			skill_data.power_multiplier = float(skill_data.power_multiplier) + _Config.ULT_HEAL_POWER_ADD
		"damage":
			if _has_offensive_status(skill_data) and float(skill_data.power_multiplier) < 1.5:
				## Control寄りの薄いAoE: 付与穴埋め優先
				_add_status_chances(skill_data, _Config.JOB_STATUS_CHANCE_ADD)
			else:
				skill_data.power_multiplier = (
					float(skill_data.power_multiplier) * _Config.ULT_DAMAGE_POWER_MULT
				)
		"buff":
			skill_data.set_meta(META_DURATION_ADD, _Config.JOB_BUFF_DURATION_ADD)
			if skill_data.tags.has("party_maxhp_heal"):
				skill_data.power_multiplier = (
					float(skill_data.power_multiplier) + _Config.ULT_HEAL_POWER_ADD_SMALL
				)
		_:
			pass


static func _apply_ultimate_override(skill_data: Resource, ov: Dictionary) -> void:
	if ov.has("damage_mult"):
		skill_data.power_multiplier = float(skill_data.power_multiplier) * float(ov["damage_mult"])
	if ov.has("heal_add"):
		skill_data.power_multiplier = float(skill_data.power_multiplier) + float(ov["heal_add"])
	if ov.has("status_chance_add"):
		_add_status_chances(skill_data, float(ov["status_chance_add"]))
	if ov.has("duration_add"):
		skill_data.set_meta(META_DURATION_ADD, int(ov["duration_add"]))
	if ov.has("counter_add"):
		skill_data.set_meta(META_COUNTER_ADD, int(ov["counter_add"]))
	if ov.has("cascade_add"):
		skill_data.set_meta(META_CASCADE_ADD, int(ov["cascade_add"]))
	if ov.has("vs_armor_break_mult"):
		skill_data.set_meta(META_VS_AB_MULT, float(ov["vs_armor_break_mult"]))


static func duration_add_from_skill(skill_data: Resource) -> int:
	if skill_data == null or not skill_data.has_meta(META_DURATION_ADD):
		return 0
	return maxi(0, int(skill_data.get_meta(META_DURATION_ADD)))


static func resolve_status_duration(skill_data: Resource, status_id: String) -> int:
	var add: int = duration_add_from_skill(skill_data)
	if add <= 0 or status_id.is_empty():
		return -1
	var effect: Resource = DataRegistry.get_status_effect(status_id)
	if effect == null:
		return -1
	return maxi(1, int(effect.duration_ticks) + add)


static func counter_charges_from_skill(skill_data: Resource, base_from_tag: int) -> int:
	var add: int = 0
	if skill_data != null and skill_data.has_meta(META_COUNTER_ADD):
		add = maxi(0, int(skill_data.get_meta(META_COUNTER_ADD)))
	return maxi(0, base_from_tag + add)


static func cascade_max_from_skill(skill_data: Resource, base_max: int) -> int:
	var add: int = 0
	if skill_data != null and skill_data.has_meta(META_CASCADE_ADD):
		add = maxi(0, int(skill_data.get_meta(META_CASCADE_ADD)))
	return maxi(0, base_max + add)


static func vs_armor_break_mult_from_skill(skill_data: Resource, default_mult: float) -> float:
	if skill_data != null and skill_data.has_meta(META_VS_AB_MULT):
		return float(skill_data.get_meta(META_VS_AB_MULT))
	return default_mult


## UI 用: 装備 Job Skill の強化説明行。
static func describe_job_skill_enhance(skill_data: Resource) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if skill_data == null or is_excluded_skill(skill_data):
		lines.append("対象外")
		return lines
	if skill_data.tags.has("trap_place"):
		lines.append("罠威力 +10%")
		return lines
	match str(skill_data.effect_type):
		"heal":
			lines.append("回復量 +15%")
		"damage":
			if _has_offensive_status(skill_data):
				lines.append("状態異常付与 +10%")
			else:
				lines.append("ダメージ +10%")
		"buff":
			lines.append("バフ持続 +1")
		_:
			lines.append("強化なし")
	return lines


## UI 用: Ultimate 強化説明行。
static func describe_ultimate_enhance(skill_data: Resource) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if skill_data == null:
		lines.append("—")
		return lines
	var sid: String = str(skill_data.id)
	var ov: Dictionary = _Config.ultimate_override_for(sid)
	if not ov.is_empty():
		if ov.has("damage_mult"):
			var pct: int = int(round((float(ov["damage_mult"]) - 1.0) * 100.0))
			lines.append("ダメージ +%d%%" % pct)
		if ov.has("heal_add"):
			lines.append("回復 +%d%%" % int(round(float(ov["heal_add"]) * 100.0)))
		if ov.has("status_chance_add"):
			lines.append("状態異常付与 +%d%%" % int(round(float(ov["status_chance_add"]) * 100.0)))
		if ov.has("duration_add"):
			lines.append("効果時間 +%d" % int(ov["duration_add"]))
		if ov.has("counter_add"):
			lines.append("応撃回数 +%d" % int(ov["counter_add"]))
		if ov.has("cascade_add"):
			lines.append("カスケード +%d" % int(ov["cascade_add"]))
		if ov.has("vs_armor_break_mult"):
			lines.append("甲砕中ダメージ強化")
		if lines.is_empty():
			lines.append("強化")
		return lines
	match str(skill_data.effect_type):
		"heal":
			lines.append("回復 +3%")
		"damage":
			if _has_offensive_status(skill_data) and float(skill_data.power_multiplier) < 1.5:
				lines.append("状態異常付与 +10%")
			else:
				lines.append("ダメージ +8%")
		"buff":
			lines.append("効果時間 +1")
			if skill_data.tags.has("party_maxhp_heal"):
				lines.append("回復 +2%")
		_:
			lines.append("強化")
	return lines
