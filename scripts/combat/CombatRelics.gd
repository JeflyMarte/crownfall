class_name CombatRelics
extends RefCounted

## 遺物（Relics・P3-D090）。「どう戦うか」を書き換える第3の装備枠（MVP）。
## 1 メンバー 1 遺物（`Adventurer.relic_id`）。カタログはコード内静的定義（tres 非増設）。
## 効果は戦闘の中央フックへ配線する常時倍率:
##   outgoing_mult … 与ダメ倍率 / incoming_mult … 被ダメ倍率 / speed_mult … 行動速度（CT短縮）
## 入手/インベントリ/発火型（通常N回毎・前後列条件）は後続。

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
}

# 選択肢順（UI 用）。先頭は「なし」。
const _ORDER: Array = ["", "war_banner", "aegis_shard", "old_hourglass", "berserker_charm"]

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
