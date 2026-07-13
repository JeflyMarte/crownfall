class_name UltimatePresentationConfig
extends RefCounted

## 必殺技 resolve 演出のタイミング SSOT（P3-UX-ULTIMATE-001）。

const ANNOUNCE_SEC: float = 1.0
const WINDUP_SEC: float = 0.65
const RELEASE_SEC: float = 0.25


static func total_resolve_sec() -> float:
	return ANNOUNCE_SEC + WINDUP_SEC + RELEASE_SEC


static func scaled(speed_mult: float) -> Dictionary:
	var m: float = speed_mult if speed_mult > 0.0 else 1.0
	m = maxf(m, 0.01)
	return {
		"announce": ANNOUNCE_SEC / m,
		"windup": WINDUP_SEC / m,
		"release": RELEASE_SEC / m,
		"total": total_resolve_sec() / m,
	}
