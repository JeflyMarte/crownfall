class_name ApexConquestConfig
extends RefCounted

## 征討（apex）パイロット共通設定 — P3-DG-APEX-ENV-001。
## 天候重みは CombatWeather。ここは階帯の雑魚敵Lvのみ。


## 表示階 → ノーマル敵Lv（Hard/NM は呼び出し側でティア加算）。
static func enemy_level_for_floor(display_floor: int) -> int:
	var f: int = maxi(1, display_floor)
	if f <= 7:
		return 50
	if f <= 14:
		return 54
	## 15〜19（および誤って20で呼ばれた場合の雑魚フォールバック）
	return 58
