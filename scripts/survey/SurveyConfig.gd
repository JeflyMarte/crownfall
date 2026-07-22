class_name SurveyConfig
extends RefCounted

## P3-HUB-SURVEY-001 Phase1 仮数値（Decision §10）。

const SURVEY_CLEAR_PERCENT: float = 70.0
const SURVEY_COMPLETE_PERCENT: float = 100.0

const PRESET_SHORT: String = "short"
const PRESET_STANDARD: String = "standard"

const SHORT_DURATION_SEC: float = 20.0 * 60.0
const STANDARD_DURATION_SEC: float = 3.0 * 60.0 * 60.0

const INVESTIGATOR_SLOTS: int = 3
const INVESTIGATOR_SLOT_LOCKED: int = 3 ## 4枠目はロック表示用 index
const MAX_SPEED_BONUS: float = 0.40

const SURVEY_ADD_CLEAR: float = 4.0
const SURVEY_ADD_BOSS_FIRST: float = 8.0
const SURVEY_ADD_CODEX_STAGE: float = 2.0
const SURVEY_ADD_CYCLE_SHORT: float = 3.0
const SURVEY_ADD_CYCLE_STANDARD: float = 6.0
const SURVEY_ROOM_DAILY_CAP: float = 12.0

const WEAPON_P_STAR1: float = 0.12
const WEAPON_P_STAR2: float = 0.05
const WEAPON_P_STAR3: float = 0.015

const TOKEN_SHORT_MIN: int = 20
const TOKEN_SHORT_MAX: int = 40
const TOKEN_STANDARD_MIN: int = 80
const TOKEN_STANDARD_MAX: int = 140

const MATERIAL_SHORT_MIN: int = 2
const MATERIAL_SHORT_MAX: int = 4
const MATERIAL_STANDARD_MIN: int = 5
const MATERIAL_STANDARD_MAX: int = 9

const ROLE_IDS: Array[String] = ["archaeology", "geology", "documents"]
const ROLE_DISPLAY: Dictionary = {
	"archaeology": "考古担当",
	"geology": "地質担当",
	"documents": "文書担当",
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
