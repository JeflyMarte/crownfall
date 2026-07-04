class_name EvolutionTraits
extends RefCounted

## 昇格特質（進化後に職ごと2つ自動解放 / P3-EVO-TRAIT-001 / P3-D167）。
## 常時倍率。CombatPassives（トリガー型）とは別カテゴリ。

const _JOB_TRAIT_IDS: Dictionary = {
	"swordsman": ["evo_saber_blade_art", "evo_saber_element_edge"],
	"alchemist": ["evo_sage_mending", "evo_sage_arcane"],
	"ranger": ["evo_sniper_bounty", "evo_sniper_dead_eye"],
	"vanguard": ["evo_paladin_smite", "evo_paladin_aegis"],
	"beast_tamer": ["evo_lord_predator", "evo_lord_wild_sense"],
}

const _DEFS: Dictionary = {
	"evo_saber_blade_art": {
		"display_name": "剣術極意",
		"description": "与ダメ+8%（剣/大剣装備時+12%）",
	},
	"evo_saber_element_edge": {
		"display_name": "属性刃",
		"description": "弱点属性攻撃の与ダメ×1.12",
	},
	"evo_sage_mending": {
		"display_name": "癒しの秘術",
		"description": "回復スキル量+20%",
	},
	"evo_sage_arcane": {
		"display_name": "深淵の理",
		"description": "杖装備時スキル与ダメ+10%・状態異常付与率+10%",
	},
	"evo_sniper_bounty": {
		"display_name": "狩人の眼",
		"description": "編成中パーティの武器ドロップ率+10%",
	},
	"evo_sniper_dead_eye": {
		"display_name": "必中の狙い",
		"description": "会心率+8%（弓装備時+12%）",
	},
	"evo_paladin_smite": {
		"display_name": "聖別の一撃",
		"description": "与ダメ+5%（聖属性攻撃+10%）",
	},
	"evo_paladin_aegis": {
		"display_name": "堅盾の誓い",
		"description": "被ダメ-8%",
	},
	"evo_lord_predator": {
		"display_name": "捕食者の印",
		"description": "状態異常付与率+15%",
	},
	"evo_lord_wild_sense": {
		"display_name": "野生の勘",
		"description": "編成中パーティの撃破EXP+12%",
	},
}

static func for_member(member: Resource) -> Array:
	if member == null or not bool(member.is_evolved):
		return []
	var job_id: String = str(member.job_id)
	if member.id.begins_with("gacha_") or member.id.begins_with("helper_"):
		return []
	var out: Array = []
	for raw_id in _JOB_TRAIT_IDS.get(job_id, []):
		var def: Dictionary = _def_with_id(str(raw_id))
		if not def.is_empty():
			out.append(def)
	return out

static func preview_for_job(job_id: String) -> Array:
	var out: Array = []
	for raw_id in _JOB_TRAIT_IDS.get(job_id, []):
		var def: Dictionary = _def_with_id(str(raw_id))
		if not def.is_empty():
			out.append(def)
	return out

static func trait_summary_lines(member: Resource) -> PackedStringArray:
	var lines: PackedStringArray = []
	for t: Dictionary in for_member(member):
		lines.append("%s — %s" % [str(t.get("display_name", "")), str(t.get("description", ""))])
	return lines

static func preview_summary_lines(job_id: String) -> PackedStringArray:
	var lines: PackedStringArray = []
	for t: Dictionary in preview_for_job(job_id):
		lines.append("%s — %s" % [str(t.get("display_name", "")), str(t.get("description", ""))])
	return lines

static func _def_with_id(trait_id: String) -> Dictionary:
	var def: Dictionary = _DEFS.get(trait_id, {}).duplicate()
	if def.is_empty():
		return {}
	def["id"] = trait_id
	return def

static func _member_has_trait(member: Resource, trait_id: String) -> bool:
	if member == null or not bool(member.is_evolved):
		return false
	for t: Dictionary in for_member(member):
		if str(t.get("id", "")) == trait_id:
			return true
	return false

static func _party_member(index: int) -> Resource:
	if index < 0 or index >= GameState.party_members.size():
		return null
	return GameState.party_members[index]

static func _member_weapon_type(member_index: int) -> String:
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon == null or str(weapon.weapon_id).is_empty():
		return ""
	var weapon_data: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	if weapon_data == null:
		return ""
	return str(weapon_data.weapon_type)

static func member_outgoing_mult(member_index: int, is_skill: bool = false, attack_element: String = "") -> float:
	var member: Resource = _party_member(member_index)
	if member == null:
		return 1.0
	var mult: float = 1.0
	var job_id: String = str(member.job_id)
	var weapon_type: String = _member_weapon_type(member_index)
	if job_id == "swordsman" and _member_has_trait(member, "evo_saber_blade_art"):
		mult *= 1.12 if weapon_type in ["sword", "greatsword"] else 1.08
	if job_id == "vanguard" and _member_has_trait(member, "evo_paladin_smite"):
		mult *= 1.10 if attack_element == "holy" else 1.05
	if job_id == "alchemist" and _member_has_trait(member, "evo_sage_arcane"):
		if is_skill and weapon_type == "staff":
			mult *= 1.10
	return mult

static func member_weakness_mult(member_index: int, elem_mult: float) -> float:
	if elem_mult <= 1.0:
		return 1.0
	var member: Resource = _party_member(member_index)
	if member == null:
		return 1.0
	if str(member.job_id) == "swordsman" and _member_has_trait(member, "evo_saber_element_edge"):
		return 1.12
	return 1.0

static func member_incoming_mult(member_index: int) -> float:
	var member: Resource = _party_member(member_index)
	if member == null:
		return 1.0
	if str(member.job_id) == "vanguard" and _member_has_trait(member, "evo_paladin_aegis"):
		return 0.92
	return 1.0

static func member_crit_add(member_index: int) -> float:
	var member: Resource = _party_member(member_index)
	if member == null:
		return 0.0
	if str(member.job_id) != "ranger" or not _member_has_trait(member, "evo_sniper_dead_eye"):
		return 0.0
	var weapon_type: String = _member_weapon_type(member_index)
	return 0.12 if weapon_type == "bow" else 0.08

static func member_heal_mult(member_index: int) -> float:
	var member: Resource = _party_member(member_index)
	if member == null:
		return 1.0
	if str(member.job_id) == "alchemist" and _member_has_trait(member, "evo_sage_mending"):
		return 1.20
	return 1.0

static func member_status_chance_mult(member_index: int) -> float:
	var member: Resource = _party_member(member_index)
	if member == null:
		return 1.0
	var mult: float = 1.0
	if str(member.job_id) == "alchemist" and _member_has_trait(member, "evo_sage_arcane"):
		if _member_weapon_type(member_index) == "staff":
			mult *= 1.10
	if str(member.job_id) == "beast_tamer" and _member_has_trait(member, "evo_lord_predator"):
		mult *= 1.15
	return mult

static func party_weapon_drop_mult() -> float:
	for member: Resource in GameState.party_members:
		if member != null and str(member.job_id) == "ranger" and _member_has_trait(member, "evo_sniper_bounty"):
			return 1.10
	return 1.0

static func party_exp_mult() -> float:
	for member: Resource in GameState.party_members:
		if member != null and str(member.job_id) == "beast_tamer" and _member_has_trait(member, "evo_lord_wild_sense"):
			return 1.12
	return 1.0

static func effective_status_chance(member_index: int, base_chance: float) -> float:
	return minf(1.0, base_chance * member_status_chance_mult(member_index))
