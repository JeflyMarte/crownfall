class_name ExtremeMissionConfig
extends RefCounted

## 極限任務（P3-DG-EXTREME-001 / Decision 143）。
## EX-02〜は MISSIONS へのデータ追加中心。任務専用ロジックの横増殖を避ける。

const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")

const ROUTE_TYPE: String = "extreme"
const EX01_DUNGEON_ID: String = "ex_tomb_seal"
const EX01_CODE: String = "EX-01"

## ---------------------------------------------------------------------------
## TUNING / provisional — ProjectDocs 未確定の数値。完了報告で列挙。散在禁止。
## ---------------------------------------------------------------------------
const TUNING := {
	## 回復効果倍率（1.0=通常）。EX-01「回復効果低下」。
	"heal_effectiveness_mult": 0.50,
	## 極限指令「規定時間以内」のラン経過秒（ポーズ除外・戦闘倍速非連動）。
	"order_time_limit_sec": 600,
	## EX-01 敵／推奨Lv（本編終端〜征討序盤帯の仮置き）。
	"ex01_enemy_level": 55,
	"ex01_recommended_level": 55,
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


static func heal_effectiveness_mult_for_active_run() -> float:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	if not is_extreme_mission(dungeon_id):
		return 1.0
	var def: Dictionary = mission_def(dungeon_id)
	var cond: Variant = def.get("special_condition", {})
	if cond is Dictionary and str((cond as Dictionary).get("id", "")) == "heal_down":
		return float(TUNING.get("heal_effectiveness_mult", 1.0))
	return 1.0


static func order_time_limit_sec() -> int:
	return maxi(1, int(TUNING.get("order_time_limit_sec", 600)))


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
			_:
				out[oid] = false
	return out


static func _run_elapsed_sec() -> float:
	## ポーズ除外の積算秒（DungeonScene._process）。壁時計は使わない。
	return maxf(0.0, float(GameState.extreme_run_elapsed_sec))


## CLEAR 時に呼び出し。進捗保存＋ last_run_* を埋める。
static func commit_clear_result(dungeon_id: String) -> void:
	if not is_extreme_mission(dungeon_id):
		return
	var order_ok: Dictionary = evaluate_orders_for_run(dungeon_id)
	var stars: int = stars_for_clear(order_ok)
	var prev_best: int = GameState.get_extreme_mission_best_stars(dungeon_id)
	var new_record: bool = stars > prev_best
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
