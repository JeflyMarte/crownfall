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

## 一覧の EX 番号順（旧日替わりローテの並びを流用）。
const DAILY_ROTATION_IDS: Array[String] = [
	EX01_DUNGEON_ID,
	EX02_DUNGEON_ID,
	EX03_DUNGEON_ID,
	EX04_DUNGEON_ID,
	EX05_DUNGEON_ID,
	EX06_DUNGEON_ID,
	EX07_DUNGEON_ID,
	EX08_DUNGEON_ID,
	EX09_DUNGEON_ID,
	EX10_DUNGEON_ID,
]
## 旧日替わりアンカー（互換残置。出現判定には未使用）。
const DAILY_ROTATION_ANCHOR_DAY_KEY: String = "2026-09-20"

## テスト用。空なら DailyMissionSystem.current_day_key()。旧ローテ検証用残置。
static var debug_day_key_override: String = ""

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
	## swarm_pressure: 通常 COMBAT は常に群れ。体数+1。chance_bonus は互換残置（未使用）。
	"swarm_chance_bonus": 0.0,
	"swarm_size_bonus": 1,
	"swarm_force_all_combat": true,
	## long_battle_ramp: 廃止（キーは互換のため残置）。
	"long_battle_ramp_start_sec": 180,
	"long_battle_ramp_per_60sec": 0.15,
	"long_battle_ramp_max_mult": 2.0,
	## damage_reflect: 廃止（EX-03 は skill_resist へ）。キーは互換のため残置。
	"damage_reflect_flat_per_hit": 35,
	"damage_reflect_pct": 0.12,
	## skill_resist (EX-03): ダメージスキル与ダメ倍率。通常攻撃・罠作動・状態／DoTは対象外。
	"skill_resist_outgoing_mult": 0.40,
	## rear_pressure: 後衛被ダメ倍率（陣形軽減に追加乗算）。
	"rear_incoming_mult": 1.75,
	## miasma_saturate (EX-05): 敵HP倍率（控えめ初期値）／DoT持続延長。
	"miasma_enemy_hp_mult": 1.25,
	"miasma_dot_duration_mult": 1.35,
	"miasma_dot_status_ids": ["poison", "bleed", "ignite"],
	## status_require (EX-06): 状態異常なしの敵への味方与ダメ倍率。
	"status_require_outgoing_mult": 0.70,
	## non_crit_pressure: 廃止（EX-08 は shell_pressure へ）。キーは互換のため残置。
	"non_crit_hit_outgoing_mult": 0.70,
	## shell_pressure (EX-08): 障壁による被ダメ軽減。貫通／破甲で無視。
	"shell_incoming_mult": 0.65,
	## element_weakness_pressure (EX-10): 非弱点（無属性含む）の与ダメ倍率。
	"non_weakness_outgoing_mult": 0.70,
	## ultimate_suppress: 廃止（EX-07 は pet_primary へ）。キーは互換のため残置。
	"ultimate_charge_suppress_mult": 0.35,
	## pet_primary (EX-07): 人間与ダメ倍率／ペット与ダメ倍率。
	"pet_primary_human_outgoing_mult": 0.70,
	"pet_primary_pet_outgoing_mult": 1.10,
	## 指令「必殺使用回数制限」上限。
	"ultimate_use_limit": 3,
	## 極限のみ: 装備レア抽選で LEGENDARY を絶対+10pt（別枠先行抽選）。
	"equip_legendary_chance_bonus": 0.10,
	## 極限のみ: ボス再クリア神話確率へ加算（基 1% → 11%）。
	"boss_mythic_chance_bonus": 0.10,
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

## Featured／説明欄の指令見出し補足。
const ORDERS_SECTION_INTRO: String = (
	"以下を達成すると報酬アップ。キャラを王痕強化できる破片を入手できます。"
)

## 任務メタ（dungeon_id キー）。tres の DungeonData と対になる表示・ルール層。
## orders[].id はセーブキー。表示文は ORDER_DISPLAY_LABELS（label は互換用）。
## special_condition: label=制約名／desc=具体効果／tip=短い攻略補足。
const MISSIONS: Dictionary = {
	EX01_DUNGEON_ID: {
		"code": EX01_CODE,
		"short_name": "王墓封鎖",
		"parent_biome_id": "mourngate",
		"boss_id": "serdion",
		"floor_count": 10,
		"special_condition": {
			"id": "heal_down",
			"label": "回復効果半減",
			"hud_label": "回復50%",
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
		"floor_count": 10,
		"special_condition": {
			"id": "swarm_pressure",
			"label": "敵の群れ増加",
			"hud_label": "常時群れ",
			"desc": "通常戦闘フロアはすべて群れになります。群れの敵数が1体増えます。",
			"tip": "範囲攻撃や群れ処理を用意しましょう。",
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
		"floor_count": 10,
		"special_condition": {
			"id": "skill_resist",
			"label": "スキル耐性",
			"hud_label": "スキル耐性",
			"desc": "スキル攻撃の与ダメージが大きく下がります。通常攻撃・罠・状態異常は普通に効きます。",
			"tip": "通常攻撃で削り、罠や状態異常で補助しましょう。",
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
		"floor_count": 10,
		"special_condition": {
			"id": "rear_pressure",
			"label": "後衛へのダメージ増加",
			"hud_label": "後衛被ダメ増",
			"desc": "編成の後衛位置が受けるダメージが大きく増加します。",
			"tip": "前衛を厚くし、後衛の被弾を減らしましょう。",
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
		"floor_count": 10,
		"special_condition": {
			"id": "miasma_saturate",
			"label": "敵耐久とDoT延長",
			"hud_label": "敵耐久・DoT延長",
			"desc": "敵のHPが上昇し、敵に付与した毒・出血・炎上の持続が延びます。",
			"tip": "DoTや持続火力で削りましょう。",
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
		"floor_count": 10,
		"special_condition": {
			"id": "status_require",
			"label": "状態異常必須",
			"hud_label": "異常必須",
			"desc": "状態異常のない敵への与ダメージが低下します。",
			"tip": "先に毒・出血などの状態異常を付与しましょう。",
		},
		"orders": [
			{"id": "no_ko"},
			{"id": "time_limit"},
			{"id": "no_same_job"},
		],
	},
	EX07_DUNGEON_ID: {
		"code": "EX-07",
		"short_name": "沈船強襲",
		"parent_biome_id": "blackshore",
		"boss_id": "nereion",
		"floor_count": 10,
		"special_condition": {
			"id": "pet_primary",
			"label": "ペット主砲",
			"hud_label": "ペット主砲",
			"desc": "人間メンバーの与ダメージが低下します。ペットの与ダメージは強化されます。",
			"tip": "ペットを編成し、獣使いなどで強化しましょう。",
		},
		"orders": [
			{"id": "no_ko"},
			{"id": "time_limit"},
			{"id": "no_same_job"},
		],
	},
	EX08_DUNGEON_ID: {
		"code": "EX-08",
		"short_name": "潮圧包囲",
		"parent_biome_id": "blackshore",
		"boss_id": "nereion",
		"floor_count": 10,
		"special_condition": {
			"id": "shell_pressure",
			"label": "敵の障壁",
			"hud_label": "敵に障壁",
			"desc": "敵が障壁で被ダメージを軽減します。貫通属性や破甲（防御DOWN）があると障壁を無視できます。",
			"tip": "刺突（貫通）武器・スキルや破甲を用意しましょう。",
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
		"floor_count": 10,
		"special_condition": {
			"id": "ultimate_disabled",
			"label": "必殺技使用不可",
			"hud_label": "必殺不可",
			"desc": "この任務では必殺技を使用できません。",
			"tip": "通常攻撃と装備スキルだけで攻略しましょう。",
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
		"floor_count": 10,
		"special_condition": {
			"id": "element_weakness_pressure",
			"label": "弱点属性必須",
			"hud_label": "弱点必須",
			"desc": "敵の弱点以外の属性攻撃（無属性を含む）の与ダメージが低下します。",
			"tip": "ボスは炎弱点。弱点属性の武器・スキルで攻めましょう。",
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


## 章番号の代わりに出すルート表記（互換・短文フォールバック）。
## 正式な表示名は format_mission_display_name / format_mission_chapter_label。
const STAGE_ROUTE_LABEL: String = "極限任務"
const DISPLAY_SEP: String = "　"


static func is_extreme_stage(stage: Resource) -> bool:
	if stage == null:
		return false
	return is_extreme_mission(str(stage.biome_id))


static func mission_code(dungeon_id: String) -> String:
	var def: Dictionary = mission_def(dungeon_id)
	return str(def.get("code", "")).strip_edges()


## 一覧ソート用。EX-01→1 … EX-10→10。不明は大きめ。
static func list_sort_key(dungeon_id: String) -> int:
	var code: String = mission_code(dungeon_id)
	if code.begins_with("EX-"):
		var num_s: String = code.substr(3).strip_edges()
		if num_s.is_valid_int():
			return int(num_s)
	var rot_i: int = DAILY_ROTATION_IDS.find(dungeon_id)
	if rot_i >= 0:
		return rot_i + 1
	return 999


## 例: EX-02　極限任務　【墓守の包囲】
static func format_mission_display_name(dungeon_id: String) -> String:
	var code: String = mission_code(dungeon_id)
	var sn: String = short_name(dungeon_id).strip_edges()
	if code.is_empty() and sn.is_empty():
		return STAGE_ROUTE_LABEL
	if sn.is_empty():
		if code.is_empty():
			return STAGE_ROUTE_LABEL
		return "%s%s%s" % [code, DISPLAY_SEP, STAGE_ROUTE_LABEL]
	if code.is_empty():
		return "%s%s【%s】" % [STAGE_ROUTE_LABEL, DISPLAY_SEP, sn]
	return "%s%s%s%s【%s】" % [code, DISPLAY_SEP, STAGE_ROUTE_LABEL, DISPLAY_SEP, sn]


## 戦闘ヘッダー短文。例: EX-02　極限任務
static func format_mission_chapter_label(dungeon_id: String) -> String:
	var code: String = mission_code(dungeon_id)
	if code.is_empty():
		return STAGE_ROUTE_LABEL
	return "%s%s%s" % [code, DISPLAY_SEP, STAGE_ROUTE_LABEL]


## ステージから正式表示名（本編の「1-1 〜」相当）。
static func format_stage_display_name(stage: Resource) -> String:
	if stage == null:
		return STAGE_ROUTE_LABEL
	var dungeon_id: String = str(stage.biome_id).strip_edges()
	if is_extreme_mission(dungeon_id):
		return format_mission_display_name(dungeon_id)
	var nm: String = str(stage.display_name).strip_edges()
	if nm.is_empty():
		return STAGE_ROUTE_LABEL
	return "%s%s%s" % [STAGE_ROUTE_LABEL, DISPLAY_SEP, nm]


static func is_playable(dungeon_id: String) -> bool:
	return Constants.is_extreme_mission_playable(dungeon_id)


static func mission_def(dungeon_id: String) -> Dictionary:
	var raw: Variant = MISSIONS.get(dungeon_id, {})
	return raw if raw is Dictionary else {}


static func parent_biome_id(dungeon_id: String) -> String:
	var def: Dictionary = mission_def(dungeon_id)
	return str(def.get("parent_biome_id", ""))


## 右上 FieldLegend 用 HUD 短文の上限（天候最長14字未満）。
const HUD_LABEL_MAX_LEN: int = 13


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


## ダンジョン右上凡例用の短文。未設定時は label を上限で切る。
static func special_condition_hud_label(dungeon_id: String) -> String:
	if not is_extreme_mission(dungeon_id):
		return ""
	var def: Dictionary = mission_def(dungeon_id)
	var cond: Variant = def.get("special_condition", {})
	if not (cond is Dictionary):
		return ""
	var hud: String = str((cond as Dictionary).get("hud_label", "")).strip_edges()
	if hud.is_empty():
		hud = str((cond as Dictionary).get("label", "")).strip_edges()
	if hud.length() > HUD_LABEL_MAX_LEN:
		return hud.substr(0, HUD_LABEL_MAX_LEN)
	return hud


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


## 極限任務中のみ。装備ドロップの LEGENDARY 別枠確率（絶対加算）。
static func equip_legendary_chance_bonus_for_active_run() -> float:
	if not is_extreme_mission(GameState.get_active_dungeon_id()):
		return 0.0
	return clampf(float(TUNING.get("equip_legendary_chance_bonus", 0.0)), 0.0, 1.0)


## 極限任務中のみ。ボス再クリア神話への加算（基 MythicLoot.CHANCE に足す）。
static func boss_mythic_chance_bonus_for_active_run() -> float:
	if not is_extreme_mission(GameState.get_active_dungeon_id()):
		return 0.0
	return clampf(float(TUNING.get("boss_mythic_chance_bonus", 0.0)), 0.0, 1.0)


## 互換API。常時群れ化後は加算なし（0）。forces_combat_swarm を正とする。
static func swarm_chance_bonus_for_active_run() -> float:
	if _active_condition_id() != "swarm_pressure":
		return 0.0
	return float(TUNING.get("swarm_chance_bonus", 0.0))


static func swarm_size_bonus_for_active_run() -> int:
	if _active_condition_id() != "swarm_pressure":
		return 0
	return maxi(0, int(TUNING.get("swarm_size_bonus", 0)))


## EX-02: 通常 COMBAT フロアを常に群れにする（探索方針・序盤緩和より優先）。
static func forces_combat_swarm_for_active_run() -> bool:
	if _active_condition_id() != "swarm_pressure":
		return false
	return bool(TUNING.get("swarm_force_all_combat", true))


static func rear_pressure_incoming_mult_for_active_run() -> float:
	if _active_condition_id() != "rear_pressure":
		return 1.0
	return maxf(0.01, float(TUNING.get("rear_incoming_mult", 1.0)))


static func ultimate_charge_gain_mult_for_active_run() -> float:
	var cid: String = _active_condition_id()
	if cid == "ultimate_disabled":
		return 0.0
	## ultimate_suppress は EX-07 差し替え後未使用。互換のため分岐は残置。
	if cid == "ultimate_suppress":
		return maxf(0.0, float(TUNING.get("ultimate_charge_suppress_mult", 1.0)))
	return 1.0


static func is_ultimate_disabled_for_active_run() -> bool:
	return _active_condition_id() == "ultimate_disabled"


## EX-07: 人間与ダメ低下／ペット与ダメ強化。member_index 不明時は人間扱い。
static func pet_primary_outgoing_mult_for_active_run(member_index: int) -> float:
	if _active_condition_id() != "pet_primary":
		return 1.0
	if member_index >= 0 and GameState.is_pet_combatant(member_index):
		return maxf(0.01, float(TUNING.get("pet_primary_pet_outgoing_mult", 1.0)))
	return maxf(0.01, float(TUNING.get("pet_primary_human_outgoing_mult", 1.0)))


## EX-05: 敵HP倍率。非該当時 1.0。
static func enemy_hp_mult_for_active_run() -> float:
	if _active_condition_id() != "miasma_saturate":
		return 1.0
	return maxf(1.0, float(TUNING.get("miasma_enemy_hp_mult", 1.0)))


## EX-05: 敵への DoT（poison/bleed/ignite）持続倍率。非該当・対象外 id は 1.0。
static func enemy_dot_duration_mult_for_active_run(status_id: String) -> float:
	if _active_condition_id() != "miasma_saturate":
		return 1.0
	var sid: String = status_id.strip_edges()
	if sid.is_empty():
		return 1.0
	for raw: Variant in miasma_dot_status_ids():
		if str(raw) == sid:
			return maxf(1.0, float(TUNING.get("miasma_dot_duration_mult", 1.0)))
	return 1.0


static func miasma_dot_status_ids() -> Array:
	var raw: Variant = TUNING.get("miasma_dot_status_ids", [])
	return raw if raw is Array else []


## combat: CombatController。null 可。EX-06: デバフなしなら与ダメ低下。
static func status_require_outgoing_mult_for_active_run(
	combat: Object = null, target_slot: int = -1
) -> float:
	if _active_condition_id() != "status_require":
		return 1.0
	if combat == null or target_slot < 0:
		return maxf(0.01, float(TUNING.get("status_require_outgoing_mult", 1.0)))
	if enemy_has_non_beneficial_status(combat, target_slot):
		return 1.0
	return maxf(0.01, float(TUNING.get("status_require_outgoing_mult", 1.0)))


## EX-08: 障壁。貫通／破甲なら 1.0、それ以外は shell_incoming_mult。
static func shell_incoming_mult_for_active_run(pierce_bypass: bool) -> float:
	if _active_condition_id() != "shell_pressure":
		return 1.0
	if pierce_bypass:
		return 1.0
	return maxf(0.01, float(TUNING.get("shell_incoming_mult", 1.0)))


## 互換スタブ（旧 non_crit）。常に 1.0。
static func hit_outgoing_mult_for_active_run(_is_critical: bool) -> float:
	return 1.0


## 武器／スキルの pierce・vs_armor_break、または対象の armor_break で障壁無視。
static func attack_pierces_shell(
	member_index: int, skill_data: Resource = null, combat: Object = null, target_slot: int = -1
) -> bool:
	if combat != null and target_slot >= 0 and combat.has_method("get_enemy_status_stacks_at"):
		if int(combat.call("get_enemy_status_stacks_at", target_slot, "armor_break")) > 0:
			return true
		if int(combat.call("get_enemy_status_stacks_at", target_slot, "armor_break_light")) > 0:
			return true
	if skill_data != null and "tags" in skill_data:
		var stags: Variant = skill_data.tags
		if stags is Array:
			if (stags as Array).has("pierce") or (stags as Array).has("vs_armor_break"):
				return true
	if member_index < 0:
		return false
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon == null or str(weapon.weapon_id).is_empty():
		return false
	var wdata: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	if wdata == null or not ("tags" in wdata):
		return false
	var wtags: Variant = wdata.tags
	return wtags is Array and (wtags as Array).has("pierce")


## EX-03: ダメージスキル与ダメ倍率。通常攻撃（is_skill=false）・非該当は 1.0。
## 罠作動／DoT はこの API を通らない（経路分離）。
static func skill_resist_outgoing_mult_for_active_run(is_skill: bool) -> float:
	if _active_condition_id() != "skill_resist":
		return 1.0
	if not is_skill:
		return 1.0
	return maxf(0.01, float(TUNING.get("skill_resist_outgoing_mult", 1.0)))


## EX-03 旧: ヒット1回分の反射ダメージ（攻撃者へ）。制約差し替え後は常に 0。
static func reflect_damage_for_hit(dealt_damage: int) -> int:
	if _active_condition_id() != "damage_reflect":
		return 0
	if dealt_damage <= 0:
		return 0
	var flat: int = maxi(0, int(TUNING.get("damage_reflect_flat_per_hit", 0)))
	var pct: float = maxf(0.0, float(TUNING.get("damage_reflect_pct", 0.0)))
	return maxi(1, flat + int(round(float(dealt_damage) * pct)))


## EX-10: 弱点一致なら 1.0。弱点未設定の敵はペナルティなし（攻略不能回避）。
static func element_match_outgoing_mult_for_active_run(
	attack_element: String, enemy_data: Resource
) -> float:
	if _active_condition_id() != "element_weakness_pressure":
		return 1.0
	if enemy_data == null:
		return 1.0
	var weakness: Array = []
	if "element_weakness" in enemy_data:
		var raw_w: Variant = enemy_data.element_weakness
		if raw_w is Array:
			weakness = raw_w as Array
	if weakness.is_empty():
		return 1.0
	var resist: Array = []
	if "element_resist" in enemy_data:
		var raw_r: Variant = enemy_data.element_resist
		if raw_r is Array:
			resist = raw_r as Array
	## PackedStringArray / Array[String] を Array[String] に寄せる。
	var weak_ids: Array[String] = []
	for w: Variant in weakness:
		var ws: String = str(w).strip_edges()
		if not ws.is_empty():
			weak_ids.append(ws)
	var resist_ids: Array[String] = []
	for r: Variant in resist:
		var rs: String = str(r).strip_edges()
		if not rs.is_empty():
			resist_ids.append(rs)
	if weak_ids.is_empty():
		return 1.0
	var elem_mult: float = ElementResolver.get_damage_multiplier(
		attack_element, weak_ids, resist_ids
	)
	if elem_mult > 1.0:
		return 1.0
	return maxf(0.01, float(TUNING.get("non_weakness_outgoing_mult", 1.0)))


## combat: CombatController（将来拡張用）。長期戦ランプは廃止。
static func enemy_outgoing_modifier_mult_for_active_run(
	combat: Object = null, attacker_slot: int = -1
) -> float:
	## attacker_slot / combat は将来拡張用にシグネチャ維持。
	if combat != null and attacker_slot >= 0:
		pass
	return 1.0


static func _long_battle_ramp_mult() -> float:
	## 廃止互換。常に 1.0。
	return 1.0


static func enemy_has_non_beneficial_status(combat: Object, slot: int) -> bool:
	if combat == null or slot < 0:
		return false
	if not combat.has_method("get_enemy_status_list_at"):
		return false
	var list: Variant = combat.call("get_enemy_status_list_at", slot)
	if list is not Array:
		return false
	const _StatusResolver := preload("res://scripts/combat/StatusResolver.gd")
	for raw: Variant in list:
		if raw is not Dictionary:
			continue
		var sid: String = str((raw as Dictionary).get("effect_id", ""))
		if sid.is_empty():
			continue
		if _StatusResolver.is_beneficial_status(sid):
			continue
		return true
	return false


## 旧 EX-06 status_empower 指令用。制約再設計後は常に false（互換スタブ）。
static func is_banned_status_for_active_run(_status_id: String) -> bool:
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


## ギルド日（朝5時JST）の day_key。
static func current_rotation_day_key() -> String:
	var ov: String = str(debug_day_key_override).strip_edges()
	if not ov.is_empty():
		return ov
	return DailyMissionSystem.current_day_key()


static func day_index_for_day_key(day_key: String) -> int:
	const _Schedule := preload("res://scripts/event/EventScheduleHelper.gd")
	var key: String = day_key.strip_edges()
	if key.is_empty():
		return 0
	var n: int = DAILY_ROTATION_IDS.size()
	if n <= 0:
		return 0
	var anchor_unix: int = _Schedule.jst_day_start_unix(DAILY_ROTATION_ANCHOR_DAY_KEY)
	var day_unix: int = _Schedule.jst_day_start_unix(key)
	var delta_days: int = int(floor(float(day_unix - anchor_unix) / 86400.0))
	return posmod(delta_days, n)


static func mission_id_for_day_key(day_key: String) -> String:
	var idx: int = day_index_for_day_key(day_key)
	if idx < 0 or idx >= DAILY_ROTATION_IDS.size():
		return ""
	return DAILY_ROTATION_IDS[idx]


static func todays_mission_id() -> String:
	return mission_id_for_day_key(current_rotation_day_key())


## 出現中か。解放条件を満たせば常時出現（日替わり廃止）。
static func is_open_now(dungeon_id: String) -> bool:
	return is_extreme_mission(dungeon_id)


static func open_schedule_label(_dungeon_id: String = "") -> String:
	return "常設（解放後いつでも）"


## 旧日替わり向け。常時出現のため常に空。
static func next_open_label(_dungeon_id: String) -> String:
	return ""


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
		lines.append("極限指令｜%s" % ORDERS_SECTION_INTRO)
		for ol: String in order_labels:
			lines.append("◇ %s" % ol)
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
		parts.append(
			"[color=#%s]極限指令[/color]｜[color=#%s]%s[/color]"
			% [HEX_GOLD, HEX_BODY, ORDERS_SECTION_INTRO]
		)
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
