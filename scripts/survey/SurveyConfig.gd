class_name SurveyConfig
extends RefCounted

## P3-HUB-SURVEY-001 / P3-BAL-SURVEY-001（Decision §10）。

const SURVEY_CLEAR_PERCENT: float = 70.0
const SURVEY_COMPLETE_PERCENT: float = 100.0

const PRESET_SHORT: String = "short"
const PRESET_STANDARD: String = "standard"
## 表示名（P3-UX-SURVEY-PRESET-NAME-001）。内部 id は short／standard 据置。
const DISPLAY_SHORT: String = "簡易調査"
const DISPLAY_STANDARD: String = "本格調査"

## P3-BAL-SURVEY-TIME-EXP-001: 簡易 1 時間／本格 3 時間据置。
const SHORT_DURATION_SEC: float = 60.0 * 60.0
const STANDARD_DURATION_SEC: float = 3.0 * 60.0 * 60.0

const INVESTIGATOR_SLOTS: int = 4
## UI 表示枠（常時全開放）。
const INVESTIGATOR_UI_SLOTS: int = 4
const MAX_SPEED_BONUS: float = 0.40

## 調査員速度ボーナス（案A: 装備込み ATK+DEF+HP に比例）。
## power = REF_LOW → +MIN、REF_HIGH → +MAX。担当ロールは別途 +ROLE。
const SPEED_BONUS_MIN: float = 0.04
const SPEED_BONUS_MAX: float = 0.14
const SPEED_BONUS_ROLE: float = 0.01
const SPEED_POWER_REF_LOW: float = 800.0
const SPEED_POWER_REF_HIGH: float = 2800.0

const SURVEY_ADD_CLEAR: float = 4.0
const SURVEY_ADD_BOSS_FIRST: float = 8.0
const SURVEY_ADD_CODEX_STAGE: float = 2.0
const SURVEY_ADD_CYCLE_SHORT: float = 3.0
const SURVEY_ADD_CYCLE_STANDARD: float = 6.0
const SURVEY_ROOM_DAILY_CAP: float = 12.0

const WEAPON_P_STAR1: float = 0.12
const WEAPON_P_STAR2: float = 0.05
const WEAPON_P_STAR3: float = 0.015

## 表示用: 装備ドロップ合算率（★1〜3）。
static func weapon_drop_chance() -> float:
	return WEAPON_P_STAR1 + WEAPON_P_STAR2 + WEAPON_P_STAR3

## P3-BAL-SURVEY-001: 潜行クリア（35–65）より大幅に下＋確率付与。
const TOKEN_GRANT_CHANCE: float = 0.40
const TOKEN_SHORT_MIN: int = 4
const TOKEN_SHORT_MAX: int = 10
const TOKEN_STANDARD_MIN: int = 8
const TOKEN_STANDARD_MAX: int = 18
## 調査室日次 SURVEY 上限到達後の受取は魔晶石（と連動 Gold）を半減。
const ROOM_OVER_CAP_TOKEN_MULT: float = 0.5

const MATERIAL_SHORT_MIN: int = 2
const MATERIAL_SHORT_MAX: int = 4
const MATERIAL_STANDARD_MIN: int = 5
const MATERIAL_STANDARD_MAX: int = 9

## 派遣先 Biome 別の鍛冶素材重み（P3-SURVEY-REWARD-VAR-001）。総量帯は据置・中身だけ多様。
## キー=material_id、値=相対重み。
const MATERIAL_WEIGHTS_BY_DUNGEON: Dictionary = {
	"mourngate": {"base_ore": 70, "relic_shard": 30},
	"whisperwood": {"base_ore": 55, "relic_shard": 30, "ancient_bone": 15},
	"mistfen": {"base_ore": 45, "relic_shard": 30, "ancient_bone": 25},
	"blackshore": {"base_ore": 35, "relic_shard": 30, "ancient_bone": 25, "epic_ore": 10},
	"frostridge": {
		"base_ore": 30,
		"relic_shard": 25,
		"ancient_bone": 25,
		"epic_ore": 15,
		"elite_relic_shard": 5,
	},
}
const MATERIAL_WEIGHTS_DEFAULT: Dictionary = {"base_ore": 70, "relic_shard": 30}

## P3-SURVEY-DISPATCH-EXP-001／P3-BAL-SURVEY-TIME-EXP-001 — 戦闘員向け EXP。
## 参照＝対象 DG 雑魚クリア相当 EXP（短・標準とも 100%）。スタッフ／ペットは対象外。
const EXP_RATIO_SHORT: float = 1.0
const EXP_RATIO_STANDARD: float = 1.0
## 雑魚クリア推定: 平均EXP × (room_count-1) × 群れ平均。
const EXP_TRASH_SWARM_AVG: float = 1.5

const ROLE_IDS: Array[String] = ["archaeology", "geology", "documents", "liaison"]
const ROLE_DISPLAY: Dictionary = {
	"archaeology": "考古担当",
	"geology": "地質担当",
	"documents": "文書担当",
	"liaison": "連絡担当",
}

## 図鑑実績マイルストーン（埋め％ → 報酬）。
const ACHIEVE_MILESTONES: Array[Dictionary] = [
	{"id": "enemy_fill_25", "title": "生態調査 25%", "need_pct": 25.0, "gold": 500, "token": 20},
	{"id": "enemy_fill_50", "title": "生態調査 50%", "need_pct": 50.0, "gold": 1500, "token": 50},
	{"id": "enemy_fill_75", "title": "生態調査 75%", "need_pct": 75.0, "gold": 3000, "token": 100},
	{"id": "enemy_fill_100", "title": "生態調査 完了", "need_pct": 100.0, "gold": 8000, "token": 200},
]


static func material_weights_for(dungeon_id: String) -> Dictionary:
	var raw: Variant = MATERIAL_WEIGHTS_BY_DUNGEON.get(dungeon_id, MATERIAL_WEIGHTS_DEFAULT)
	if raw is Dictionary and not (raw as Dictionary).is_empty():
		return (raw as Dictionary).duplicate()
	return MATERIAL_WEIGHTS_DEFAULT.duplicate()


static func roll_material_id(dungeon_id: String, rng: RandomNumberGenerator = null) -> String:
	var weights: Dictionary = material_weights_for(dungeon_id)
	var total: int = 0
	for w in weights.values():
		total += maxi(0, int(w))
	if total <= 0:
		return "base_ore"
	var roll: int
	if rng != null:
		roll = rng.randi_range(1, total)
	else:
		roll = randi_range(1, total)
	var acc: int = 0
	for mid in weights.keys():
		acc += maxi(0, int(weights[mid]))
		if roll <= acc:
			return str(mid)
	return str(weights.keys()[0])


static func duration_sec(preset: String) -> float:
	if preset == PRESET_SHORT:
		return SHORT_DURATION_SEC
	return STANDARD_DURATION_SEC


static func display_name(preset: String) -> String:
	if preset == PRESET_SHORT:
		return DISPLAY_SHORT
	return DISPLAY_STANDARD


## 例: 簡易調査（1時間）／本格調査（3時間）
static func display_name_with_duration(preset: String) -> String:
	if preset == PRESET_SHORT:
		return "%s（1時間）" % DISPLAY_SHORT
	return "%s（3時間）" % DISPLAY_STANDARD


static func cycle_survey_add(preset: String) -> float:
	if preset == PRESET_SHORT:
		return SURVEY_ADD_CYCLE_SHORT
	return SURVEY_ADD_CYCLE_STANDARD
