class_name ExtremeMissionConfig
extends RefCounted

## 極限任務（P3-DG-EXTREME-001 / Decision 143）。
## EX-02〜は MISSIONS へのデータ追加中心。任務専用ロジックの横増殖を避ける。
## 特殊条件は special_condition.id → 共通 modifier API。

const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")

const ROUTE_TYPE: String = "extreme"
const EX01_DUNGEON_ID: String = "ex_tomb_seal"
const EX01_CODE: String = "EX-01"
const EX02_DUNGEON_ID: String = "ex_grave_siege"
const EX03_DUNGEON_ID: String = "ex_spore_dense"
const EX04_DUNGEON_ID: String = "ex_hunter_woods"
const EX05_DUNGEON_ID: String = "ex_miasma_sat"
const EX06_DUNGEON_ID: String = "ex_infect_chain"
const EX07_DUNGEON_ID: String = "ex_wreck_assault"
const EX08_DUNGEON_ID: String = "ex_tide_siege"
const EX09_DUNGEON_ID: String = "ex_polar_silence"
const EX10_DUNGEON_ID: String = "ex_white_night"

## ---------------------------------------------------------------------------
## TUNING / provisional — ProjectDocs 未確定の数値。完了報告で列挙。散在禁止。
## ---------------------------------------------------------------------------
const TUNING := {
	## 回復効果倍率（1.0=通常）。heal_down 特殊条件。
	"heal_effectiveness_mult": 0.50,
	## 極限指令「規定時間以内」のラン経過秒（ポーズ除外・戦闘倍速非連動）。
## UI 表示は「10分以内にクリア」（600秒と一致）。判定値は変更しない。
	"order_time_limit_sec": 600,
	## EX-01 敵／推奨Lv（本編終端〜征討序盤帯の仮置き）。
	"ex01_enemy_level": 55,
	"ex01_recommended_level": 55,
	## ---- Phase 2 provisional ----
	"ex02_enemy_level": 56,
	"ex02_recommended_level": 56,
	"ex03_enemy_level": 57,
	"ex03_recommended_level": 57,
	"ex04_enemy_level": 58,
	"ex04_recommended_level": 58,
	"ex05_enemy_level": 59,
	"ex05_recommended_level": 59,
	"ex06_enemy_level": 60,
	"ex06_recommended_level": 60,
	"ex07_enemy_level": 61,
	"ex07_recommended_level": 61,
	"ex08_enemy_level": 62,
	"ex08_recommended_level": 62,
	"ex09_enemy_level": 63,
	"ex09_recommended_level": 63,
	"ex10_enemy_level": 64,
	"ex10_recommended_level": 64,
	## swarm_pressure: 群れ出現率への加算／体数ボーナス。
	"swarm_chance_bonus": 0.35,
	"swarm_size_bonus": 1,
	## long_battle_ramp: 経過秒後から敵与ダメ増加。
	"long_battle_ramp_start_sec": 180,
	"long_battle_ramp_per_60sec": 0.15,
	"long_battle_ramp_max_mult": 2.0,
	## rear_pressure: 後衛被ダメ倍率（陣形軽減に追加乗算）。
	"rear_incoming_mult": 1.75,
	## status_empower: 対象状態異常中の敵与ダメ倍率。
	"status_empower_ids": ["poison", "bleed"],
	"status_empower_outgoing_mult": 1.50,
	## ultimate_suppress: 必殺チャージ獲得倍率。
	"ultimate_charge_suppress_mult": 0.35,
	## 指令「必殺使用回数制限」上限。
	"ultimate_use_limit": 3,
}

## 極限指令のプレイヤー向け表示（id はセーブキーのまま。判定ロジック不変）。
const ORDER_DISPLAY_LABELS: Dictionary = {
	"no_ko": "戦闘不能者なし",
	"time_limit": "10分以内にクリア",
	"no_heal_skill": "回復スキルを使用しない",
	"no_same_job": "同じジョブを編成しない",
	"all_unique_jobs": "4人全員を異なるジョブで編成",
	"no_rear_ko": "後衛の戦闘不能なし",
	"ultimate_limit": "必殺技の使用3回以内",
	"no_ultimate": "必殺技を使用しない",
	"no_banned_status": "毒・出血を使用しない",
}

## 任務メタ（dungeon_id キー）。tres の DungeonData と対になる表示・ルール層。
## orders[].id はセーブキー。表示文は ORDER_DISPLAY_LABELS（label は互換用）。
## special_condition: label=制約名／desc=具体効果／tip=短い攻略補足。
const MISSIONS: Dictionary = {
	EX01_DUNGEON_ID: {
		"code": EX01_CODE,
		"short_name": "王墓封鎖",
		"parent_biome_id": "mourngate",
		"boss_id": "serdion",
		"floor_count": 5,
		"special_condition": {
			"id": "heal_down",
			"label": "回復効果半減",
			"desc": "味方が受ける回復効果が50%になります。",
			"tip": "回復に頼りすぎない編成が重要です。",
		},
		"orders": [
			{"id": "no_ko"},
			{"id": "time_limit"},
			{"id": "no_heal_skill"},
		],
	},
	EX02_DUNGEON_ID: {
		"code": "EX-02",
		"short_name": "墓守の包囲",
		"parent_biome_id": "mourngate",
		"boss_id": "serdion",
		"floor_count": 5,
		"special_condition": {
			"id": "swarm_pressure",
			"label": "敵の群れ増加",
			"desc": "敵の群れが出現しやすくなり、群れの敵数も1体増加します。",
			"tip": "複数の敵への対策が重要です。",
		},
		"orders": [
			{"id": "no_ko"},
			{"id": "time_limit"},
			{"id": "no_same_job"},
		],
	},
	EX03_DUNGEON_ID: {
		"code": "EX-03",
		"short_name": "胞子過密域",
		"parent_biome_id": "whisperwood",
		"boss_id": "granvel",
		"floor_count": 5,
		"special_condition": {
			"id": "long_battle_ramp",
			"label": "長期戦で敵が強化",
			"desc": "180秒経過後、時間が経つほど敵の攻撃が強力になります。",
			"tip": "長期戦になるほど危険です。",
		},
		"orders": [
			{"id": "time_limit"},
			{"id": "ultimate_limit"},
			{"id": "no_ko"},
		],
	},
	EX04_DUNGEON_ID: {
		"code": "EX-04",
		"short_name": "狩人の森",
		"parent_biome_id": "whisperwood",
		"boss_id": "granvel",
		"floor_count": 5,
		"special_condition": {
			"id": "rear_pressure",
			"label": "後衛へのダメージ増加",
			"desc": "後衛が受けるダメージが大きく増加します。",
			"tip": "後衛の生存対策が重要です。",
		},
		"orders": [
			{"id": "no_rear_ko"},
			{"id": "no_same_job"},
			{"id": "time_limit"},
		],
	},
	EX05_DUNGEON_ID: {
		"code": "EX-05",
		"short_name": "瘴気飽和",
		"parent_biome_id": "mistfen",
		"boss_id": "moldgar",
		"floor_count": 5,
		"special_condition": {
			"id": "heal_down",
			"label": "回復効果半減",
			"desc": "味方が受ける回復効果が50%になります。",
			"tip": "回復に頼りすぎない編成が重要です。",
		},
		"orders": [
			{"id": "no_ko"},
			{"id": "no_heal_skill"},
			{"id": "time_limit"},
		],
	},
	EX06_DUNGEON_ID: {
		"code": "EX-06",
		"short_name": "感染連鎖",
		"parent_biome_id": "mistfen",
		"boss_id": "moldgar",
		"floor_count": 5,
		"special_condition": {
			"id": "status_empower",
			"label": "毒・出血で敵が強化",
			"desc": "毒・出血状態の敵は、与えるダメージが50%増加します。",
			"tip": "状態異常の使用には注意が必要です。",
		},
		"orders": [
			{"id": "no_banned_status"},
			{"id": "no_ko"},
			{"id": "no_same_job"},
		],
	},
	EX07_DUNGEON_ID: {
		"code": "EX-07",
		"short_name": "沈船強襲",
		"parent_biome_id": "blackshore",
		"boss_id": "nereion",
		"floor_count": 5,
		"special_condition": {
			"id": "ultimate_suppress",
			"label": "必殺チャージ大幅低下",
			"desc": "必殺ゲージの獲得量が35%になります。",
			"tip": "必殺技に頼らない戦い方が重要です。",
		},
		"orders": [
			{"id": "no_ultimate"},
			{"id": "time_limit"},
			{"id": "no_ko"},
		],
	},
	EX08_DUNGEON_ID: {
		"code": "EX-08",
		"short_name": "潮圧包囲",
		"parent_biome_id": "blackshore",
		"boss_id": "nereion",
		"floor_count": 5,
		## 表示は実装に合わせる（elite_swarm_up は群れ圧力と同処理。ELITE固有処理なし）。
		"special_condition": {
			"id": "elite_swarm_up",
			"label": "敵の群れ増加",
			"desc": "敵の群れが出現しやすくなり、群れの敵数も1体増加します。",
			"tip": "複数の敵への対策が重要です。",
		},
		"orders": [
			{"id": "no_ko"},
			{"id": "no_same_job"},
			{"id": "time_limit"},
		],
	},
	EX09_DUNGEON_ID: {
		"code": "EX-09",
		"short_name": "極冠静寂",
		"parent_biome_id": "frostridge",
		"boss_id": "eldion",
		"floor_count": 5,
		"special_condition": {
			"id": "ultimate_disabled",
			"label": "必殺技使用不可",
			"desc": "この任務では必殺技を使用できません。",
			"tip": "通常攻撃と装備スキルだけで攻略する必要があります。",
		},
		"orders": [
			{"id": "no_ko"},
			{"id": "time_limit"},
			{"id": "all_unique_jobs"},
		],
	},
	EX10_DUNGEON_ID: {
		"code": "EX-10",
		"short_name": "白夜決戦",
		"parent_biome_id": "frostridge",
		"boss_id": "eldion",
		"floor_count": 5,
		"special_condition": {
			"id": "long_battle_ramp",
			"label": "長期戦で敵が強化",
			"desc": "180秒経過後、時間が経つほど敵の攻撃が強力になります。",
			"tip": "長期戦になるほど危険です。",
		},
		"orders": [
			{"id": "no_ko"},
			{"id": "time_limit"},
			{"id": "no_same_job"},
		],
	},
}


static func is_extreme_mission(dungeon_id: String) -> bool:
	return MISSIONS.has(dungeon_id)


static func is_playable(dungeon_id: String) -> bool:
	return Constants.is_extreme_mission_playable(dungeon_id)


static func mission_def(dungeon_id: String) -> Dictionary:
	var raw: Variant = MISSIONS.get(dungeon_id, {})
	return raw if raw is Dictionary else {}


static func parent_biome_id(dungeon_id: String) -> String:
	var def: Dictionary = mission_def(dungeon_id)
	return str(def.get("parent_biome_id", ""))


static func short_name(dungeon_id: String) -> String:
	var def: Dictionary = mission_def(dungeon_id)
	return str(def.get("short_name", ""))


static func special_condition_id(dungeon_id: String) -> String:
	var def: Dictionary = mission_def(dungeon_id)
	var cond: Variant = def.get("special_condition", {})
	if cond is Dictionary:
		return str((cond as Dictionary).get("id", ""))
	return ""


static func special_condition_label(dungeon_id: String) -> String:
	var def: Dictionary = mission_def(dungeon_id)
	var cond: Variant = def.get("special_condition", {})
	if cond is Dictionary:
		return str((cond as Dictionary).get("label", ""))
	return ""


static func special_condition_desc(dungeon_id: String) -> String:
	var def: Dictionary = mission_def(dungeon_id)
	var cond: Variant = def.get("special_condition", {})
	if cond is Dictionary:
		return str((cond as Dictionary).get("desc", ""))
	return ""


static func special_condition_tip(dungeon_id: String) -> String:
	var def: Dictionary = mission_def(dungeon_id)
	var cond: Variant = def.get("special_condition", {})
	if cond is Dictionary:
		return str((cond as Dictionary).get("tip", ""))
	return ""


static func order_defs(dungeon_id: String) -> Array:
	var def: Dictionary = mission_def(dungeon_id)
	var orders: Variant = def.get("orders", [])
	return orders if orders is Array else []


## 指令 id → プレイヤー向け表示。MISSIONS 内 label より ORDER_DISPLAY_LABELS を優先。
static func order_display_label(order_id: String) -> String:
	var oid: String = order_id.strip_edges()
	if oid.is_empty():
		return ""
	if ORDER_DISPLAY_LABELS.has(oid):
		return str(ORDER_DISPLAY_LABELS[oid])
	return oid


static func order_labels_for_mission(dungeon_id: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for raw: Variant in order_defs(dungeon_id):
		if not (raw is Dictionary):
			continue
		var oid: String = str((raw as Dictionary).get("id", ""))
		var label: String = order_display_label(oid)
		if label.is_empty() and raw is Dictionary:
			label = str((raw as Dictionary).get("label", ""))
		if not label.is_empty():
			out.append(label)
	return out


static func _active_condition_id() -> String:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	if not is_extreme_mission(dungeon_id):
		return ""
	return special_condition_id(dungeon_id)


static func heal_effectiveness_mult_for_active_run() -> float:
	if _active_condition_id() != "heal_down":
		return 1.0
	return float(TUNING.get("heal_effectiveness_mult", 1.0))


static func swarm_chance_bonus_for_active_run() -> float:
	var cid: String = _active_condition_id()
	if cid != "swarm_pressure" and cid != "elite_swarm_up":
		return 0.0
	return float(TUNING.get("swarm_chance_bonus", 0.0))


static func swarm_size_bonus_for_active_run() -> int:
	var cid: String = _active_condition_id()
	if cid != "swarm_pressure" and cid != "elite_swarm_up":
		return 0
	return maxi(0, int(TUNING.get("swarm_size_bonus", 0)))


static func rear_pressure_incoming_mult_for_active_run() -> float:
	if _active_condition_id() != "rear_pressure":
		return 1.0
	return maxf(0.01, float(TUNING.get("rear_incoming_mult", 1.0)))


static func ultimate_charge_gain_mult_for_active_run() -> float:
	var cid: String = _active_condition_id()
	if cid == "ultimate_disabled":
		return 0.0
	if cid == "ultimate_suppress":
		return maxf(0.0, float(TUNING.get("ultimate_charge_suppress_mult", 1.0)))
	return 1.0


static func is_ultimate_disabled_for_active_run() -> bool:
	return _active_condition_id() == "ultimate_disabled"


## combat: CombatController（status_empower 判定用）。null 可。
static func enemy_outgoing_modifier_mult_for_active_run(
	combat: Object = null, attacker_slot: int = -1
) -> float:
	var mult: float = 1.0
	var cid: String = _active_condition_id()
	if cid == "long_battle_ramp":
		mult *= _long_battle_ramp_mult()
	if cid == "status_empower" and combat != null and attacker_slot >= 0:
		if enemy_has_empower_status(combat, attacker_slot):
			mult *= status_empower_outgoing_mult()
	return mult


static func _long_battle_ramp_mult() -> float:
	var elapsed: float = _run_elapsed_sec()
	var start_sec: float = float(TUNING.get("long_battle_ramp_start_sec", 180))
	if elapsed <= start_sec:
		return 1.0
	var per_min: float = float(TUNING.get("long_battle_ramp_per_60sec", 0.15))
	var minutes: float = (elapsed - start_sec) / 60.0
	var ramp: float = 1.0 + per_min * minutes
	var cap: float = float(TUNING.get("long_battle_ramp_max_mult", 2.0))
	return clampf(ramp, 1.0, maxf(1.0, cap))


static func status_empower_ids() -> Array:
	var raw: Variant = TUNING.get("status_empower_ids", [])
	return raw if raw is Array else []


static func status_empower_outgoing_mult() -> float:
	return maxf(1.0, float(TUNING.get("status_empower_outgoing_mult", 1.0)))


static func enemy_has_empower_status(combat: Object, slot: int) -> bool:
	if combat == null or slot < 0:
		return false
	if not combat.has_method("get_enemy_status_stacks_at"):
		return false
	for raw: Variant in status_empower_ids():
		var sid: String = str(raw)
		if sid.is_empty():
			continue
		if int(combat.call("get_enemy_status_stacks_at", slot, sid)) > 0:
			return true
	return false


static func is_banned_status_for_active_run(status_id: String) -> bool:
	if status_id.is_empty():
		return false
	if _active_condition_id() != "status_empower":
		return false
	for raw: Variant in status_empower_ids():
		if str(raw) == status_id:
			return true
	return false


static func order_time_limit_sec() -> int:
	return maxi(1, int(TUNING.get("order_time_limit_sec", 600)))


static func ultimate_use_limit() -> int:
	return maxi(0, int(TUNING.get("ultimate_use_limit", 3)))


## メイン5 Biome Normal 全クリア後（Hard 解放と同ゲート）。
static func is_content_unlocked() -> bool:
	if GameState.debug_full_unlock:
		return true
	return _DungeonTierConfig.is_main_campaign_tier_cleared(_DungeonTierConfig.TIER_NORMAL)


static func is_mission_unlocked(dungeon_id: String) -> bool:
	if not is_extreme_mission(dungeon_id):
		return false
	if not is_playable(dungeon_id):
		return false
	return is_content_unlocked()


static func stars_for_clear(order_ok: Dictionary) -> int:
	## ★1=CLEAR。各指令達成で +1（最大★4）。指令は独立。
	var stars: int = 1
	for raw: Variant in order_ok.values():
		if bool(raw):
			stars += 1
	return clampi(stars, 1, 4)


static func evaluate_orders_for_run(dungeon_id: String) -> Dictionary:
	## { order_id: bool }
	var out: Dictionary = {}
	if not is_extreme_mission(dungeon_id):
		return out
	for raw: Variant in order_defs(dungeon_id):
		if not (raw is Dictionary):
			continue
		var oid: String = str((raw as Dictionary).get("id", ""))
		if oid.is_empty():
			continue
		match oid:
			"no_ko":
				out[oid] = int(GameState.extreme_run_ko_count) <= 0
			"time_limit":
				out[oid] = _run_elapsed_sec() <= float(order_time_limit_sec())
			"no_heal_skill":
				out[oid] = not bool(GameState.extreme_run_heal_skill_used)
			"no_same_job":
				out[oid] = _party_jobs_unique(false)
			"all_unique_jobs":
				## 人間編成 ACTIVE_PARTY_SIZE 人すべて異なるジョブ（Jack=party_members 外・対象外）。
				out[oid] = _party_jobs_unique(true)
			"no_rear_ko":
				out[oid] = int(GameState.extreme_run_rear_ko_count) <= 0
			"ultimate_limit":
				out[oid] = int(GameState.extreme_run_ultimate_uses) <= ultimate_use_limit()
			"no_ultimate":
				out[oid] = int(GameState.extreme_run_ultimate_uses) <= 0
			"no_banned_status":
				out[oid] = not bool(GameState.extreme_run_banned_status_used)
			_:
				out[oid] = false
	return out


static func _party_jobs_unique(require_full_party: bool) -> bool:
	## party_members のみ（人間）。Jack は active_pet で枠外のためここに含まれない。
	var jobs: Dictionary = {}
	var counted: int = 0
	for m: Variant in GameState.party_members:
		if m == null:
			continue
		var jid: String = str(m.job_id).strip_edges()
		if jid.is_empty():
			continue
		if jobs.has(jid):
			return false
		jobs[jid] = true
		counted += 1
	if counted <= 0:
		return false
	if require_full_party and counted < GameState.ACTIVE_PARTY_SIZE:
		return false
	return true


static func _run_elapsed_sec() -> float:
	## ポーズ除外の積算秒（DungeonScene._process）。壁時計は使わない。
	return maxf(0.0, float(GameState.extreme_run_elapsed_sec))


## CLEAR 時に呼び出し。王痕片付与 → 進捗保存 → last_run_*。
## 同一ランの二重 commit は GameState.extreme_run_reward_committed で防止。
static func commit_clear_result(
	dungeon_id: String,
	rng: RandomNumberGenerator = null,
	force_repeat_roll: float = -1.0
) -> void:
	if not is_extreme_mission(dungeon_id):
		return
	const _RoyalMarkSystem := preload("res://scripts/systems/RoyalMarkSystem.gd")
	var order_ok: Dictionary = evaluate_orders_for_run(dungeon_id)
	var stars: int = stars_for_clear(order_ok)
	var prev_best: int = GameState.get_extreme_mission_best_stars(dungeon_id)
	var new_record: bool = stars > prev_best
	## prev_best 取得後・progress 更新前に報酬確定（二重 commit は System 側で遮断）。
	_RoyalMarkSystem.grant_extreme_clear_rewards(
		dungeon_id, prev_best, stars, rng, force_repeat_roll
	)
	GameState.record_extreme_mission_clear(dungeon_id, stars, order_ok)
	GameState.last_run_extreme_mission_id = dungeon_id
	GameState.last_run_extreme_stars = stars
	GameState.last_run_extreme_orders = order_ok.duplicate(true)
	GameState.last_run_extreme_best_stars = GameState.get_extreme_mission_best_stars(dungeon_id)
	GameState.last_run_extreme_new_record = new_record


static func featured_brief_lines(dungeon_id: String) -> PackedStringArray:
	## 平文版（テスト／フォールバック）。色付きは featured_brief_bbcode。
	var lines: PackedStringArray = PackedStringArray()
	var def: Dictionary = mission_def(dungeon_id)
	if def.is_empty():
		return lines
	var cond_label: String = special_condition_label(dungeon_id)
	var cond_desc: String = special_condition_desc(dungeon_id)
	var cond_tip: String = special_condition_tip(dungeon_id)
	if not cond_label.is_empty():
		lines.append("特殊制約｜%s" % cond_label)
	if not cond_desc.is_empty():
		lines.append(cond_desc)
	if not cond_tip.is_empty():
		lines.append(cond_tip)
	var order_labels: PackedStringArray = order_labels_for_mission(dungeon_id)
	if not order_labels.is_empty():
		lines.append("極限指令")
		for ol: String in order_labels:
			lines.append("◇ %s" % ol)
	lines.append("CLEAR ★｜指令1つで★+1｜最大★★★★")
	return lines


## Featured 詳細用 BBCode（色階層）。最高★／CLEAR は Meta 側に任せ重複しない。
static func featured_brief_bbcode(dungeon_id: String) -> String:
	const HEX_ACCENT := "e08a4a"
	const HEX_ACCENT_LIT := "f0b060"
	const HEX_GOLD := "fae07a"
	const HEX_BODY := "f2ebe0"
	const HEX_TIP := "b8b0a4"
	var parts: PackedStringArray = PackedStringArray()
	var def: Dictionary = mission_def(dungeon_id)
	if def.is_empty():
		return ""
	var cond_label: String = special_condition_label(dungeon_id)
	var cond_desc: String = special_condition_desc(dungeon_id)
	var cond_tip: String = special_condition_tip(dungeon_id)
	if not cond_label.is_empty():
		parts.append(
			"[color=#%s]特殊制約[/color]｜[color=#%s]%s[/color]"
			% [HEX_ACCENT, HEX_ACCENT_LIT, cond_label]
		)
	if not cond_desc.is_empty():
		parts.append("[color=#%s]%s[/color]" % [HEX_BODY, cond_desc])
	if not cond_tip.is_empty():
		parts.append("[color=#%s]%s[/color]" % [HEX_TIP, cond_tip])
	var order_labels: PackedStringArray = order_labels_for_mission(dungeon_id)
	if not order_labels.is_empty():
		parts.append("")
		parts.append("[color=#%s]極限指令[/color]" % HEX_GOLD)
		var saved: Dictionary = GameState.get_extreme_mission_orders(dungeon_id)
		for raw: Variant in order_defs(dungeon_id):
			if not (raw is Dictionary):
				continue
			var oid: String = str((raw as Dictionary).get("id", ""))
			var ol: String = order_display_label(oid)
			if ol.is_empty():
				continue
			var done: bool = bool(saved.get(oid, false))
			var hex: String = "73eb8c" if done else "c8c0b4"
			parts.append("[color=#%s]◇ %s[/color]" % [hex, ol])
	parts.append("")
	parts.append(
		"[color=#%s]CLEAR ★[/color]｜[color=#%s]指令1つで★+1[/color]｜[color=#%s]最大★★★★[/color]"
		% [HEX_BODY, HEX_BODY, HEX_GOLD]
	)
	return "\n".join(parts)


static func list_banner_blurb(dungeon_id: String) -> String:
	## 一覧バナー用の1行。長文にしない。
	var cond_label: String = special_condition_label(dungeon_id)
	if cond_label.is_empty():
		return ""
	return "特殊制約｜%s" % cond_label


static func art_biome_id(dungeon_id: String) -> String:
	## 戦闘BG／バナー解決用。親 Biome を流用。
	var parent: String = parent_biome_id(dungeon_id)
	return parent if not parent.is_empty() else dungeon_id
