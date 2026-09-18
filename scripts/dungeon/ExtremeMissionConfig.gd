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

## 任務メタ（dungeon_id キー）。tres の DungeonData と対になる表示・ルール層。
## orders[].id はセーブキー。label は UI／Result 用。
const MISSIONS: Dictionary = {
	EX01_DUNGEON_ID: {
		"code": EX01_CODE,
		"short_name": "王墓封鎖",
		"parent_biome_id": "mourngate",
		"boss_id": "serdion",
		"floor_count": 5,
		"special_condition": {
			"id": "heal_down",
			"label": "回復効果低下",
			"desc": "この任務中、回復効果が大幅に下がる。",
		},
		"orders": [
			{"id": "no_ko", "label": "戦闘不能者なし"},
			{"id": "time_limit", "label": "規定時間以内"},
			{"id": "no_heal_skill", "label": "回復スキルなし"},
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
			"label": "敵群れ圧力増加",
			"desc": "この任務中、敵の群れ出現と規模が増える。",
		},
		"orders": [
			{"id": "no_ko", "label": "戦闘不能者なし"},
			{"id": "time_limit", "label": "規定時間以内"},
			{"id": "no_same_job", "label": "同一ジョブなし"},
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
			"label": "長期戦敵強化",
			"desc": "戦闘が長引くほど敵の攻撃が強くなる。",
		},
		"orders": [
			{"id": "time_limit", "label": "規定時間以内"},
			{"id": "ultimate_limit", "label": "必殺使用回数制限"},
			{"id": "no_ko", "label": "戦闘不能者なし"},
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
			"label": "後衛攻撃圧力増加",
			"desc": "この任務中、後衛への攻撃圧力が増える。",
		},
		"orders": [
			{"id": "no_rear_ko", "label": "後衛戦闘不能なし"},
			{"id": "no_same_job", "label": "同一ジョブなし"},
			{"id": "time_limit", "label": "規定時間以内"},
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
			"label": "回復効果低下",
			"desc": "この任務中、回復効果が大幅に下がる。",
		},
		"orders": [
			{"id": "no_ko", "label": "戦闘不能者なし"},
			{"id": "no_heal_skill", "label": "回復スキルなし"},
			{"id": "time_limit", "label": "規定時間以内"},
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
			"label": "状態異常中の敵強化",
			"desc": "特定の状態異常中の敵が強化される。",
		},
		"orders": [
			{"id": "no_banned_status", "label": "対象状態異常を使用しない"},
			{"id": "no_ko", "label": "戦闘不能者なし"},
			{"id": "no_same_job", "label": "同一ジョブなし"},
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
			"label": "必殺チャージ抑制",
			"desc": "この任務中、必殺ゲージのチャージが抑制される。",
		},
		"orders": [
			{"id": "no_ultimate", "label": "必殺なし"},
			{"id": "time_limit", "label": "規定時間以内"},
			{"id": "no_ko", "label": "戦闘不能者なし"},
		],
	},
	EX08_DUNGEON_ID: {
		"code": "EX-08",
		"short_name": "潮圧包囲",
		"parent_biome_id": "blackshore",
		"boss_id": "nereion",
		"floor_count": 5,
		"special_condition": {
			"id": "elite_swarm_up",
			"label": "ELITE・群れ構成強化",
			"desc": "この任務中、ELITEと群れの圧力が増える。",
		},
		"orders": [
			{"id": "no_ko", "label": "戦闘不能者なし"},
			{"id": "no_same_job", "label": "同一ジョブなし"},
			{"id": "time_limit", "label": "規定時間以内"},
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
			"label": "必殺使用不可",
			"desc": "この任務中、必殺技は使用できない。",
		},
		"orders": [
			{"id": "no_ko", "label": "戦闘不能者なし"},
			{"id": "time_limit", "label": "規定時間以内"},
			{"id": "all_unique_jobs", "label": "4人全員異なるジョブ"},
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
			"label": "長期戦敵強化",
			"desc": "戦闘が長引くほど敵の攻撃が強くなる。",
		},
		"orders": [
			{"id": "no_ko", "label": "戦闘不能者なし"},
			{"id": "time_limit", "label": "規定時間以内"},
			{"id": "no_same_job", "label": "同一ジョブなし"},
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


static func order_defs(dungeon_id: String) -> Array:
	var def: Dictionary = mission_def(dungeon_id)
	var orders: Variant = def.get("orders", [])
	return orders if orders is Array else []


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
	var lines: PackedStringArray = PackedStringArray()
	var def: Dictionary = mission_def(dungeon_id)
	if def.is_empty():
		return lines
	var parent: String = str(def.get("parent_biome_id", ""))
	var boss: String = str(def.get("boss_id", ""))
	var parent_name: String = parent
	var boss_name: String = boss
	var parent_data: Resource = DataRegistry.get_dungeon_data(parent) if not parent.is_empty() else null
	if parent_data != null:
		parent_name = str(parent_data.display_name)
	var boss_data: Resource = DataRegistry.get_enemy_data(boss) if not boss.is_empty() else null
	if boss_data != null and "display_name" in boss_data:
		boss_name = str(boss_data.display_name)
	lines.append("Biome: %s" % parent_name)
	lines.append("Boss: %s" % boss_name)
	var cond_label: String = special_condition_label(dungeon_id)
	if not cond_label.is_empty():
		lines.append("特殊条件: %s" % cond_label)
	var order_labels: PackedStringArray = PackedStringArray()
	for raw: Variant in order_defs(dungeon_id):
		if raw is Dictionary:
			order_labels.append(str((raw as Dictionary).get("label", "")))
	if not order_labels.is_empty():
		lines.append("極限指令: %s" % " / ".join(order_labels))
	var best: int = GameState.get_extreme_mission_best_stars(dungeon_id)
	if best > 0:
		lines.append("最高評価: ★%d" % best)
	else:
		lines.append("最高評価: —")
	if GameState.is_extreme_mission_cleared(dungeon_id):
		lines.append("CLEAR")
	return lines


static func art_biome_id(dungeon_id: String) -> String:
	## 戦闘BG／バナー解決用。親 Biome を流用。
	var parent: String = parent_biome_id(dungeon_id)
	return parent if not parent.is_empty() else dungeon_id
