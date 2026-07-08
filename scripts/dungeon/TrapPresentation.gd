class_name TrapPresentation
extends RefCounted

## 罠ヒット演出の数値 SSOT（P3-UX-TRAP-001）。

const ROOM_DMG_SCALE: float = 1.35
const EXPLORE_DMG_SCALE: float = 1.2
const SHAKE_INTENSITY: float = 5.0
const ALERT_ALPHAS: Array[float] = [0.32, 0.22, 0.14]
const ALERT_ALPHAS_FAST: Array[float] = [0.16, 0.11]


static func pulse_count(trap_room: bool, fast_run: bool) -> int:
	if fast_run:
		return 2
	return 3 if trap_room else 2


static func damage_scale(trap_room: bool) -> float:
	return ROOM_DMG_SCALE if trap_room else EXPLORE_DMG_SCALE


static func peak_alphas(trap_room: bool, fast_run: bool) -> Array[float]:
	var pulses: int = pulse_count(trap_room, fast_run)
	var source: Array[float] = ALERT_ALPHAS_FAST if fast_run else ALERT_ALPHAS
	var out: Array[float] = []
	for i: int in pulses:
		out.append(source[mini(i, source.size() - 1)])
	return out
