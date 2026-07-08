class_name CombatPassives
extends RefCounted

## パッシブ / リアクション（P3-D088）。
## 共通フォーマット: Trigger → Condition → Effect → Cooldown。
## 基本5職ロスターはキャラ固有パッシブを優先、それ以外はジョブフォールバック。
##
## trigger: "on_combat_start" | "on_hit_taken" | "on_ally_death" | "on_attack"
## condition: "always" | "self_hp_below"（value=HP割合）
## effect: "apply_status" | "heal" | "bonus_damage" | "counter_attack" | "grant_next_attack_mult"
## stat_mod（常時）: evasion_rate_add / outgoing_mult / incoming_mult / first_attack_mult /
##   ultimate_power_mult / exp_gain_mult / party_exp_gain_mult
## cooldown: CT 秒（0 = 都度発火可。on_combat_start は実質1回）

const _DEFS: Dictionary = {
	# ---- 基本5職キャラ固有 ----
	"ald_royal_flame": {
		"display_name": "王炎の覇気",
		"description": "与ダメージが常時10%上昇する。",
		"outgoing_mult": 1.10,
	},
	"riva_lone_focus": {
		"display_name": "孤高の集中",
		"description": "味方が倒れたとき、反撃する（戦闘中1回）。",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "counter_attack",
		"once_per_combat": true,
		"cooldown": 0.0,
	},
	"elias_field_elixir": {
		"display_name": "野戦調合",
		"description": "味方が倒れたとき、パーティを15回復する。",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "heal", "target": "party", "value": 15,
		"cooldown": 0.0,
	},
	"galen_sacred_bastion": {
		"display_name": "聖盾の砦",
		"description": "攻撃を受けたとき、反撃する（CD 3秒）。",
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "counter_attack",
		"cooldown": 3.0,
	},
	"mirei_swarm_resonance": {
		"display_name": "群響の絆",
		"description": "3回攻撃するごとに追撃する（威力30%）。",
		"trigger": "on_attack",
		"every_n": 3,
		"effect": "bonus_damage",
		"bonus_fraction": 0.30,
		"cooldown": 0.0,
	},
	# ---- ジョブフォールバック（非基本ロスター・助っ人等） ----
	"bulwark": {
		"display_name": "鉄壁",
		"description": "攻撃を受けたとき、反撃する（CD 4秒）。",
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "counter_attack",
		"cooldown": 4.0,
	},
	"battle_fervor": {
		"display_name": "高揚",
		"description": "戦闘中最初の通常攻撃の威力が2倍になる。",
		"first_attack_mult": 2.0,
	},
	"field_medic": {
		"display_name": "野戦救護",
		"description": "自身の獲得経験値が15%増加する。",
		"exp_gain_mult": 1.15,
	},
	"pack_instinct": {
		"display_name": "群れの本能",
		"description": "3回攻撃するごとに追撃する（威力30%）。",
		"trigger": "on_attack",
		"every_n": 3,
		"effect": "bonus_damage",
		"bonus_fraction": 0.30,
		"cooldown": 0.0,
	},
	# ---- ガチャ助っ人固有（P3-GACHA-005） ----
	"leon_sword_focus": {
		"display_name": "剣勢の集中",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	"ivar_trail_sight": {
		"display_name": "狩場の目",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	"serin_quick_mend": {
		"display_name": "応急調合",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "heal", "target": "party", "value": 14,
		"cooldown": 0.0,
	},
	"mira_beast_call": {
		"display_name": "獣呼びの絆",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "party",
		"cooldown": 0.0,
	},
	"valden_iron_oath": {
		"display_name": "鉄誓の守護",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "apply_status", "status_id": "guard", "target": "self",
		"cooldown": 5.0,
	},
	# ---- ジョブフォールバック補完（P3-D155） ----
	"foresight": {
		"display_name": "先読み",
		"description": "回避率が20%上昇する。",
		"evasion_rate_add": 0.20,
	},
	# ---- ★3 職固有（P3-D155 / P3-GACHA-006 / P3-PASSIVE-V2） ----
	"sword_charge": {
		"display_name": "剣気充填",
		"description": "与ダメージが常時10%上昇する。",
		"outgoing_mult": 1.10,
	},
	"wind_reading": {
		"display_name": "風読み",
		"description": "回避率が12%上昇する。",
		"evasion_rate_add": 0.12,
	},
	"spare_vial": {
		"display_name": "予備薬瓶",
		"description": "HPが50%を下回ったとき、自身を12回復する（CD 10秒）。",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "heal", "target": "self", "heal_value": 12,
		"cooldown": 10.0,
	},
	"unyielding_stance": {
		"display_name": "不屈の構え",
		"description": "被ダメージが12%軽減される。",
		"incoming_mult": 0.88,
	},
	"tamer_whistle": {
		"display_name": "手懐けの笛",
		"description": "攻撃時20%の確率で敵を拘束する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "snare",
		"target": "enemy",
		"status_chance": 0.20,
		"cooldown": 0.0,
	},
	# ---- ★4 職固有（P3-D155 / P3-GACHA-006 / P3-PASSIVE-V2） ----
	"royal_sword_doctrine": {
		"display_name": "王軍剣範",
		"description": "必殺技の威力が50%上昇する。",
		"ultimate_power_mult": 1.50,
	},
	"formation_eye": {
		"display_name": "隊列の眼",
		"description": "味方が倒れたとき、生存者の次の通常攻撃の威力が2倍になる。",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "grant_next_attack_mult",
		"mult": 2.0,
		"target": "party_alive",
		"cooldown": 0.0,
	},
	"panacea_gift": {
		"display_name": "万能薬進呈",
		"description": "編成中パーティの獲得経験値が10%増加する。",
		"party_exp_gain_mult": 1.10,
	},
	"greatshield_order": {
		"display_name": "大盾の号令",
		"description": "被ダメージが10%軽減される。",
		"incoming_mult": 0.90,
	},
	"herd_king_roar": {
		"display_name": "群王の咆哮",
		"description": "戦闘開始時、敵全体に恐怖を付与する。",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "fear",
		"target": "enemy_all",
		"cooldown": 0.0,
	},
	# ---- レジェンド装備（P3-EQ-LEG-001） ----
	"eq_serdion_ward": {
		"display_name": "霊廟の守護",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "apply_status", "status_id": "guard", "target": "self",
		"cooldown": 6.0,
	},
	"eq_mourngate_royal": {
		"display_name": "王家の覇気",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "empower", "target": "self",
		"cooldown": 0.0,
	},
	# ---- レリック（解放型パッシブ・P3-RELIC-PASSIVE） ----
	"relic_war_banner": {
		"display_name": "王国軍旗",
		"category": "relic",
		"description": "与ダメージ +10%（前列のみ）",
		"outgoing_mult": 1.10,
		"passive_condition": "front_row_only",
	},
	"relic_aegis_shard": {
		"display_name": "王盾の欠片",
		"category": "relic",
		"description": "被ダメージ -10%",
		"incoming_mult": 0.90,
	},
	"relic_old_hourglass": {
		"display_name": "古い砂時計",
		"category": "relic",
		"description": "行動速度 +10%（CT短縮）",
		"speed_mult": 1.10,
	},
	"relic_berserker_charm": {
		"display_name": "狂戦士の護符",
		"category": "relic",
		"description": "与ダメ +20% / 被ダメ +15%",
		"outgoing_mult": 1.20,
		"incoming_mult": 1.15,
	},
	"relic_hunter_sigil": {
		"display_name": "狩人の印",
		"category": "relic",
		"description": "4回与ダメごとに追撃（30%）",
		"trigger": "on_attack",
		"every_n": 4,
		"effect": "bonus_damage",
		"bonus_fraction": 0.30,
		"cooldown": 0.0,
	},
	"relic_reactive_aegis": {
		"display_name": "反応の盾片",
		"category": "relic",
		"description": "被弾時 HP50%未満で防御付与",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below",
		"value": 0.5,
		"effect": "apply_status",
		"status_id": "guard",
		"target": "self",
		"cooldown": 8.0,
	},
	"relic_lament_ring": {
		"display_name": "弔鐘の指輪",
		"category": "relic",
		"description": "味方戦闘不能時に自身を鼓舞",
		"trigger": "on_ally_death",
		"effect": "apply_status",
		"status_id": "empower",
		"target": "self",
		"cooldown": 0.0,
	},
	"relic_scout_lens": {
		"display_name": "斥候の片眼",
		"category": "relic",
		"description": "行動速度 +5% / 与ダメ +5%",
		"outgoing_mult": 1.05,
		"speed_mult": 1.05,
	},
	"eq_wpn_consecrated_maul": {
		"display_name": "祝槌の癒し",
		"category": "weapon",
		"description": "攻撃のたびに自身のHPを5%回復する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "heal",
		"target": "self",
		"heal_max_hp_fraction": 0.05,
		"cooldown": 0.0,
	},
	"eq_wpn_silvaria_oathblade": {
		"display_name": "森護の誓盾",
		"category": "weapon",
		"description": "被弾時20%で受けるダメージを75%軽減する。",
		"incoming_block_chance": 0.20,
		"incoming_block_mult": 0.25,
	},
	"eq_wpn_veld_branch_staff": {
		"display_name": "翠枝の秘術",
		"category": "weapon",
		"description": "装備スキルの与ダメージ +35%。",
		"skill_power_mult": 1.35,
	},
	"eq_wpn_nereidas_tideblade": {
		"display_name": "潮汐の慧眼",
		"category": "weapon",
		"description": "会心率 +15% / 会心ダメ +50%。",
		"crit_rate_add": 0.15,
		"crit_damage_add": 0.50,
	},
	"eq_wpn_pharoslight_staff": {
		"display_name": "灯守の極意",
		"category": "weapon",
		"description": "必殺技の与ダメージ +50%。",
		"ultimate_power_mult": 1.50,
	},
	"eq_wpn_volgrave_thunderblade": {
		"display_name": "沼断ちの雷勢",
		"category": "weapon",
		"description": "属性値ロール確定 + 雷属性攻撃の与ダメ +25%。",
		"forced_element": "thunder",
		"guaranteed_element_power_roll": true,
		"element_outgoing_mult": {"thunder": 1.25},
	},
	"eq_wpn_seradion_storm_staff": {
		"display_name": "雷典の学識",
		"category": "weapon",
		"description": "装備キャラの獲得経験値が2倍になる。",
		"exp_gain_mult": 2.0,
	},
	"eq_wpn_eldion_frostbrand": {
		"display_name": "始祖の二律",
		"category": "weapon",
		"description": "属性値ロール確定 + 氷属性攻撃の与ダメ +25%。",
		"forced_element": "ice",
		"guaranteed_element_power_roll": true,
		"element_outgoing_mult": {"ice": 1.25},
	},
	"eq_wpn_umbra_terminus_staff": {
		"display_name": "終末の帳",
		"category": "weapon",
		"description": "攻撃のたびに敵へランダムな状態異常を付与する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "random_enemy_status",
		"status_pool": ["poison", "chill", "shock", "ignite", "curse", "fear", "bleed"],
		"cooldown": 0.0,
	},
	"eq_wpn_sanctified_dagger": {
		"display_name": "霊廟の呪詛",
		"category": "weapon",
		"description": "戦闘開始時、敵全体に呪いを付与する。",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "curse",
		"target": "enemy_all",
		"cooldown": 0.0,
	},
}

# 基本5職ロスター adventurer_id → キャラ固有パッシブ id
const RELIC_PASSIVE_ORDER: Array[String] = [
	"relic_war_banner", "relic_aegis_shard", "relic_old_hourglass", "relic_berserker_charm",
	"relic_hunter_sigil", "relic_reactive_aegis", "relic_lament_ring", "relic_scout_lens",
]

const RELIC_LEGACY_TO_PASSIVE: Dictionary = {
	"war_banner": "relic_war_banner",
	"aegis_shard": "relic_aegis_shard",
	"old_hourglass": "relic_old_hourglass",
	"berserker_charm": "relic_berserker_charm",
	"hunter_sigil": "relic_hunter_sigil",
	"reactive_aegis": "relic_reactive_aegis",
	"lament_ring": "relic_lament_ring",
	"scout_lens": "relic_scout_lens",
}

const _BASE_ROSTER_PASSIVES: Dictionary = {
	"adventurer_0": "ald_royal_flame",
	"adventurer_1": "riva_lone_focus",
	"adventurer_2": "elias_field_elixir",
	"adventurer_3": "galen_sacred_bastion",
	"adventurer_4": "mirei_swarm_resonance",
}

# ジョブ → パッシブ id（基本ロスター以外のフォールバック）
const _JOB_PASSIVES: Dictionary = {
	"vanguard": ["bulwark"],
	"swordsman": ["battle_fervor"],
	"ranger": ["foresight"],
	"alchemist": ["field_medic"],
	"beast_tamer": ["pack_instinct"],
}

# ★3 / ★4 ガチャ冒険者の職固有パッシブ（P3-D155 / P3-GACHA-006）。
# ★1〜2 は付与なし（初期ステ差のみ）。★4 は ★4 定義のみ（★3 と重複付与しない）。
const _STAR3_JOB_PASSIVES: Dictionary = {
	"swordsman": "sword_charge",
	"ranger": "wind_reading",
	"alchemist": "spare_vial",
	"vanguard": "unyielding_stance",
	"beast_tamer": "tamer_whistle",
}
const _STAR4_JOB_PASSIVES: Dictionary = {
	"swordsman": "royal_sword_doctrine",
	"ranger": "formation_eye",
	"alchemist": "panacea_gift",
	"vanguard": "greatshield_order",
	"beast_tamer": "herd_king_roar",
}

# レア度に応じた職固有ティアパッシブ定義（該当なしは空 Dictionary）。
static func tier_def_for(job_id: String, rarity: int) -> Dictionary:
	if rarity >= 4:
		return _def_with_id(str(_STAR4_JOB_PASSIVES.get(job_id, "")))
	if rarity == 3:
		return _def_with_id(str(_STAR3_JOB_PASSIVES.get(job_id, "")))
	return {}

static func get_def(passive_id: String) -> Dictionary:
	return _def_with_id(passive_id)

static func migrate_relic_passive_id(raw_id: String) -> String:
	var pid: String = str(raw_id)
	if pid.is_empty():
		return ""
	if _DEFS.has(pid):
		return pid
	return str(RELIC_LEGACY_TO_PASSIVE.get(pid, ""))

static func is_relic_passive(passive_id: String) -> bool:
	if passive_id.is_empty():
		return false
	var def: Dictionary = _DEFS.get(passive_id, {})
	return str(def.get("category", "")) == "relic"

static func is_weapon_passive(passive_id: String) -> bool:
	if passive_id.is_empty():
		return false
	var def: Dictionary = _DEFS.get(passive_id, {})
	return str(def.get("category", "")) == "weapon"

static func weapon_passive_def_for_member(member: Resource) -> Dictionary:
	if member == null:
		return {}
	var weapon: Resource = member.equipped_weapon if "equipped_weapon" in member else null
	if weapon == null or str(weapon.weapon_id).is_empty():
		return {}
	var weapon_data: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	if weapon_data == null:
		return {}
	var pid: String = str(weapon_data.fixed_passive_id) if "fixed_passive_id" in weapon_data else ""
	if pid.is_empty():
		return {}
	return get_def(pid)

static func weapon_stat_modifiers_for_member(member_index: int) -> Dictionary:
	var out: Dictionary = {
		"skill_power_mult": 1.0,
		"ultimate_power_mult": 1.0,
		"crit_rate_add": 0.0,
		"crit_damage_add": 0.0,
		"exp_gain_mult": 1.0,
		"incoming_block_chance": 0.0,
		"incoming_block_mult": 1.0,
		"element_outgoing_mult": {},
	}
	if member_index < 0 or member_index >= GameState.party_members.size():
		return out
	var def: Dictionary = weapon_passive_def_for_member(GameState.party_members[member_index])
	if def.is_empty():
		return out
	if def.has("skill_power_mult"):
		out["skill_power_mult"] = float(def["skill_power_mult"])
	if def.has("ultimate_power_mult"):
		out["ultimate_power_mult"] = float(def["ultimate_power_mult"])
	if def.has("crit_rate_add"):
		out["crit_rate_add"] = float(def["crit_rate_add"])
	if def.has("crit_damage_add"):
		out["crit_damage_add"] = float(def["crit_damage_add"])
	if def.has("exp_gain_mult"):
		out["exp_gain_mult"] = float(def["exp_gain_mult"])
	if def.has("incoming_block_chance"):
		out["incoming_block_chance"] = float(def["incoming_block_chance"])
	if def.has("incoming_block_mult"):
		out["incoming_block_mult"] = float(def["incoming_block_mult"])
	if def.has("element_outgoing_mult") and def["element_outgoing_mult"] is Dictionary:
		out["element_outgoing_mult"] = (def["element_outgoing_mult"] as Dictionary).duplicate()
	return out

static func character_stat_modifiers_for_member(member_index: int) -> Dictionary:
	var out: Dictionary = {
		"evasion_rate_add": 0.0,
		"ultimate_power_mult": 1.0,
		"exp_gain_mult": 1.0,
		"outgoing_mult": 1.0,
		"incoming_mult": 1.0,
		"first_attack_mult": 1.0,
	}
	if member_index < 0 or member_index >= GameState.party_members.size():
		return out
	var member: Resource = GameState.party_members[member_index]
	for raw_def: Variant in _core_passives_for_member(member):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if str(def.get("category", "")) in ["relic", "weapon"]:
			continue
		if def.has("evasion_rate_add"):
			out["evasion_rate_add"] += float(def["evasion_rate_add"])
		for key: String in ["ultimate_power_mult", "exp_gain_mult", "outgoing_mult", "incoming_mult", "first_attack_mult"]:
			if def.has(key):
				out[key] *= float(def[key])
	return out

static func skill_stat_modifiers_for_member(member_index: int) -> Dictionary:
	var out: Dictionary = weapon_stat_modifiers_for_member(member_index)
	var char_mods: Dictionary = character_stat_modifiers_for_member(member_index)
	out["ultimate_power_mult"] = float(out["ultimate_power_mult"]) * float(char_mods.get("ultimate_power_mult", 1.0))
	out["exp_gain_mult"] = float(out["exp_gain_mult"]) * float(char_mods.get("exp_gain_mult", 1.0))
	return out

static func party_exp_mult() -> float:
	var mult: float = 1.0
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		for raw_def: Variant in _core_passives_for_member(member):
			if raw_def is not Dictionary:
				continue
			var def: Dictionary = raw_def
			if def.has("party_exp_gain_mult"):
				mult *= float(def["party_exp_gain_mult"])
	return mult

static func weapon_passive_description(passive_id: String) -> String:
	var def: Dictionary = get_def(passive_id)
	if def.is_empty():
		return ""
	if def.has("description"):
		return str(def.get("description", ""))
	return relic_description(passive_id)

static func relic_passive_ids() -> Array[String]:
	return RELIC_PASSIVE_ORDER.duplicate()

static func relic_icon_key(passive_id: String) -> String:
	var pid: String = migrate_relic_passive_id(passive_id)
	if pid.begins_with("relic_"):
		return pid.trim_prefix("relic_")
	return pid

static func relic_display_name(passive_id: String) -> String:
	var def: Dictionary = get_def(migrate_relic_passive_id(passive_id))
	if def.is_empty():
		return "なし"
	return str(def.get("display_name", passive_id))

static func relic_description(passive_id: String) -> String:
	var def: Dictionary = get_def(migrate_relic_passive_id(passive_id))
	if def.is_empty():
		return ""
	if def.has("description"):
		return str(def.get("description", ""))
	return _passive_effect_summary(def)

static func selectable_relic_passive_ids() -> Array[String]:
	var out: Array[String] = []
	for pid: String in RELIC_PASSIVE_ORDER:
		if GameState.has_relic(pid):
			out.append(pid)
	return out

static func stat_multipliers_for_member(member: Resource, member_index: int) -> Dictionary:
	var eff: Dictionary = {"outgoing_mult": 1.0, "incoming_mult": 1.0, "speed_mult": 1.0}
	if member == null:
		return eff
	var relic_id: String = GameState.get_equipped_relic_passive_id(member)
	if relic_id.is_empty():
		return eff
	var def: Dictionary = get_def(relic_id)
	if def.is_empty():
		return eff
	for key: String in eff.keys():
		if def.has(key):
			var mult: float = float(def[key])
			if key == "outgoing_mult" and str(def.get("passive_condition", "")) == "front_row_only":
				if member_index >= 0 and GameState.is_member_back_row(member_index):
					mult = 1.0
			eff[key] = mult
	return eff

static func _passive_effect_summary(def: Dictionary) -> String:
	if def.has("description"):
		return str(def.get("description", ""))
	var parts: PackedStringArray = []
	if float(def.get("outgoing_mult", 1.0)) > 1.0:
		parts.append("与ダメ +%d%%" % int(round((float(def["outgoing_mult"]) - 1.0) * 100.0)))
	if float(def.get("incoming_mult", 1.0)) < 1.0:
		parts.append("被ダメ -%d%%" % int(round((1.0 - float(def["incoming_mult"])) * 100.0)))
	if float(def.get("incoming_mult", 1.0)) > 1.0:
		parts.append("被ダメ +%d%%" % int(round((float(def["incoming_mult"]) - 1.0) * 100.0)))
	if float(def.get("speed_mult", 1.0)) > 1.0:
		parts.append("速度 +%d%%" % int(round((float(def["speed_mult"]) - 1.0) * 100.0)))
	if float(def.get("evasion_rate_add", 0.0)) > 0.0:
		parts.append("回避 +%d%%" % int(round(float(def["evasion_rate_add"]) * 100.0)))
	if float(def.get("first_attack_mult", 1.0)) > 1.0:
		parts.append("初撃 ×%.1f" % float(def["first_attack_mult"]))
	if float(def.get("ultimate_power_mult", 1.0)) > 1.0:
		parts.append("必殺 +%d%%" % int(round((float(def["ultimate_power_mult"]) - 1.0) * 100.0)))
	if float(def.get("exp_gain_mult", 1.0)) > 1.0:
		parts.append("EXP +%d%%" % int(round((float(def["exp_gain_mult"]) - 1.0) * 100.0)))
	if float(def.get("party_exp_gain_mult", 1.0)) > 1.0:
		parts.append("パーティEXP +%d%%" % int(round((float(def["party_exp_gain_mult"]) - 1.0) * 100.0)))
	return " / ".join(parts)

static func equipment_passives_for_member(member: Resource) -> Array:
	return _equipment_passives_for_member(member)

static func _def_with_id(passive_id: String) -> Dictionary:
	var def: Dictionary = _DEFS.get(passive_id, {}).duplicate()
	if def.is_empty():
		return {}
	def["id"] = passive_id
	return def

# 指定メンバーのパッシブ定義一覧（装備固定＋装備中 optional）。
static func for_member(member: Resource) -> Array:
	if member == null:
		return []
	var out: Array = []
	var seen: Dictionary = {}
	for eq_def: Dictionary in _equipment_passives_for_member(member):
		var eq_id: String = str(eq_def.get("id", ""))
		if eq_id.is_empty() or seen.has(eq_id):
			continue
		seen[eq_id] = true
		out.append(eq_def)
	for pid: String in GameState.get_equipped_character_passive_ids(member):
		if seen.has(pid):
			continue
		var def: Dictionary = _def_with_id(pid)
		if def.is_empty():
			continue
		seen[pid] = true
		out.append(def)
	var relic_id: String = GameState.get_equipped_relic_passive_id(member)
	if not relic_id.is_empty() and not seen.has(relic_id):
		var relic_def: Dictionary = _def_with_id(relic_id)
		if not relic_def.is_empty():
			out.append(relic_def)
	return out

## 戦闘突入ログ用（装備固定＋選択パッシブ＋レリック、`for_member` と同集合）。
static func combat_loadout_log_entries(member: Resource) -> Array:
	var out: Array = []
	if member == null:
		return out
	for def: Dictionary in for_member(member):
		var pid: String = str(def.get("id", ""))
		if pid.is_empty():
			continue
		out.append({
			"tag": "レリック" if is_relic_passive(pid) else ("武器" if is_weapon_passive(pid) else "パッシブ"),
			"name": str(def.get("display_name", pid)),
		})
	return out

static func selectable_passive_ids(member: Resource) -> Array[String]:
	var out: Array[String] = []
	for def: Dictionary in _core_passives_for_member(member):
		var pid: String = str(def.get("id", ""))
		if pid.is_empty() or out.has(pid):
			continue
		out.append(pid)
	return out

static func _core_passives_for_member(member: Resource) -> Array:
	var out: Array = _base_passives_for_member(member)
	if member != null and _BASE_ROSTER_PASSIVES.has(str(member.id)):
		return out
	var rarity: int = int(member.rarity) if "rarity" in member else 0
	var tier_def: Dictionary = tier_def_for(str(member.job_id), rarity)
	if not tier_def.is_empty():
		out.append(tier_def)
	return out

static func _base_passives_for_member(member: Resource) -> Array:
	if member == null:
		return []
	var adv_id: String = str(member.id)
	if _BASE_ROSTER_PASSIVES.has(adv_id):
		var char_def: Dictionary = _def_with_id(str(_BASE_ROSTER_PASSIVES[adv_id]))
		if not char_def.is_empty():
			return [char_def]
	var out: Array = []
	if adv_id.begins_with("gacha_"):
		var helper: Resource = DataRegistry.get_gacha_helper_data(adv_id.trim_prefix("gacha_"))
		if helper != null and not str(helper.passive_id).is_empty():
			var helper_def: Dictionary = _def_with_id(str(helper.passive_id))
			if not helper_def.is_empty():
				out.append(helper_def)
	if out.is_empty():
		out = for_job(str(member.job_id))
	return out

static func _equipment_passives_for_member(member: Resource) -> Array:
	var out: Array = []
	if member == null:
		return out
	var armor_inst: Resource = member.equipped_armor if "equipped_armor" in member else null
	if armor_inst != null and not str(armor_inst.armor_id).is_empty():
		var armor_data: Resource = DataRegistry.get_armor_data(str(armor_inst.armor_id))
		if armor_data != null and not str(armor_data.fixed_passive_id).is_empty():
			var armor_def: Dictionary = _def_with_id(str(armor_data.fixed_passive_id))
			if not armor_def.is_empty():
				out.append(armor_def)
	var acc_inst: Resource = member.equipped_accessory if "equipped_accessory" in member else null
	if acc_inst != null and not str(acc_inst.accessory_id).is_empty():
		var acc_data: Resource = DataRegistry.get_accessory_data(str(acc_inst.accessory_id))
		if acc_data != null and not str(acc_data.fixed_passive_id).is_empty():
			var acc_def: Dictionary = _def_with_id(str(acc_data.fixed_passive_id))
			if not acc_def.is_empty():
				out.append(acc_def)
	var weapon_inst: Resource = member.equipped_weapon if "equipped_weapon" in member else null
	if weapon_inst != null and not str(weapon_inst.weapon_id).is_empty():
		var weapon_data: Resource = DataRegistry.get_weapon_data(str(weapon_inst.weapon_id))
		if weapon_data != null and not str(weapon_data.fixed_passive_id).is_empty():
			var weapon_def: Dictionary = _def_with_id(str(weapon_data.fixed_passive_id))
			if not weapon_def.is_empty():
				out.append(weapon_def)
	return out

# 指定ジョブのパッシブ定義一覧（id 込み）を返す。
static func for_job(job_id: String) -> Array:
	var out: Array = []
	for pid in _JOB_PASSIVES.get(job_id, []):
		var def: Dictionary = _def_with_id(str(pid))
		if def.is_empty():
			continue
		out.append(def)
	return out
