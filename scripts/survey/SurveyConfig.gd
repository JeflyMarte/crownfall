class_name SurveyConfig
extends RefCounted

## P3-HUB-SURVEY-001 / P3-BAL-SURVEY-001（Decision §10）。

const SURVEY_CLEAR_PERCENT: float = 70.0
const SURVEY_COMPLETE_PERCENT: float = 100.0

const PRESET_SHORT: String = "short"
const PRESET_STANDARD: String = "standard"

const SHORT_DURATION_SEC: float = 20.0 * 60.0
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


static func duration_sec(preset: String) -> float:
	if preset == PRESET_SHORT:
		return SHORT_DURATION_SEC
	return STANDARD_DURATION_SEC


static func cycle_survey_add(preset: String) -> float:
	if preset == PRESET_SHORT:
		return SURVEY_ADD_CYCLE_SHORT
	return SURVEY_ADD_CYCLE_STANDARD
