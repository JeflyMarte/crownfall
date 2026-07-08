class_name ExpBarPresenter
extends RefCounted

## EXP バーアニメのタイミング SSOT（P3-UX-RESULT-002）。

const FILL_SEC: float = 0.95
const LEVEL_UP_FLASH_SEC: float = 0.35
const BETWEEN_MEMBER_SEC: float = 0.12
const FAST_MULT: float = 0.5

const COLOR_BAR: Color = Color(0.35, 0.82, 0.95)
const COLOR_BAR_LEVELUP: Color = Color(1.0, 0.86, 0.28)
const COLOR_HEADER: Color = Color("#FFD700")


static func timings(fast: bool) -> Dictionary:
	var mult: float = FAST_MULT if fast else 1.0
	return {
		"fill": FILL_SEC * mult,
		"level_up": LEVEL_UP_FLASH_SEC * mult,
		"between": BETWEEN_MEMBER_SEC * mult,
	}
