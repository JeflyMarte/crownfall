class_name CombatRelics
extends RefCounted

## 遺物（Relics・P3-D090）。「どう戦うか」を書き換える第3の装備枠（MVP）。
## 1 メンバー 1 遺物（`Adventurer.relic_id`）。カタログはコード内静的定義（tres 非増設）。
## 効果は戦闘の中央フックへ配線:
##   常時倍率 … outgoing_mult / incoming_mult / speed_mult（既定1.0）
##   発火型 … trigger + effect（Passives と同型。P3-D114）

const NONE_ID: String = ""

const _DEFS: Dictionary = {
	"war_banner": {
		"display_name": "王国軍旗",
		"description": "与ダメージ +10%",
		"outgoing_mult": 1.10,
	},
	"aegis_shard": {
		"display_name": "王盾の欠片",
		"description": "被ダメージ -10%",
		"incoming_mult": 0.90,
	},
	"old_hourglass": {
		"display_name": "古い砂時計",
		"description": "行動速度 +10%（CT短縮）",
		"speed_mult": 1.10,
	},
	"berserker_charm": {
		"display_name": "狂戦士の護符",
		"description": "与ダメ +20% / 被ダメ +15%",
		"outgoing_mult": 1.20,
		"incoming_mult": 1.15,
	},
	"hunter_sigil": {
		"display_name": "狩人の印",
		"description": "4回与ダメごとに追撃（30%）",
		"trigger": "on_attack",
		"every_n": 4,
		"effect": "bonus_damage",
		"bonus_fraction": 0.30,
		"cooldown": 0.0,
	},
	"reactive_aegis": {
		"display_name": "反応の盾片",
		"description": "被弾時 HP50%未満で防御付与",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below",
		"value": 0.5,
		"effect": "apply_status",
		"status_id": "guard",
		"target": "self",
		"cooldown": 8.0,
	},
	"lament_ring": {
		"display_name": "弔鐘の指輪",
		"description": "味方戦闘不能時に自身を鼓舞",
		"trigger": "on_ally_death",
		"effect": "apply_status",
		"status_id": "empower",
		"target": "self",
		"cooldown": 0.0,
	},
	"scout_lens": {
		"display_name": "斥候の片眼",
		"description": "行動速度 +5% / 与ダメ +5%",
		"outgoing_mult": 1.05,
		"speed_mult": 1.05,
	},
}

# 選択肢順（UI 用）。先頭は「なし」。
const _ORDER: Array = [
	"", "war_banner", "aegis_shard", "old_hourglass", "berserker_charm",
	"hunter_sigil", "reactive_aegis", "lament_ring", "scout_lens",
]

# カタログ全遺物 id（「なし」を除く）。ドロップ候補/解放判定に使用。
static func all_ids() -> Array:
	var out: Array = []
	for rid: String in _ORDER:
		if not rid.is_empty():
			out.append(rid)
	return out

static func normalize_id(relic_id: String) -> String:
	return relic_id if _DEFS.has(relic_id) else NONE_ID

static func display_name(relic_id: String) -> String:
	if _DEFS.has(relic_id):
		return str(_DEFS[relic_id]["display_name"])
	return "なし"

# UI 一覧（{id, display_name}）。先頭＝なし。
static func relic_list() -> Array:
	var out: Array = []
	for rid: String in _ORDER:
		out.append({"id": rid, "display_name": display_name(rid)})
	return out

# 効果倍率（既定 1.0）をマージして返す。未知/なしは全て 1.0。
static func effects_for(relic_id: String) -> Dictionary:
	var eff: Dictionary = {"outgoing_mult": 1.0, "incoming_mult": 1.0, "speed_mult": 1.0}
	var def: Dictionary = _DEFS.get(relic_id, {})
	for key: String in eff.keys():
		if def.has(key):
			eff[key] = float(def[key])
	return eff

static func has_trigger(relic_id: String) -> bool:
	var def: Dictionary = _DEFS.get(relic_id, {})
	return not str(def.get("trigger", "")).is_empty()

# 発火型遺物の定義（id 付きコピー）。常時倍率のみの遺物は {}。
static func trigger_def(relic_id: String) -> Dictionary:
	var rid: String = normalize_id(relic_id)
	if rid.is_empty() or not has_trigger(rid):
		return {}
	var out: Dictionary = _DEFS[rid].duplicate()
	out["id"] = rid
	return out
