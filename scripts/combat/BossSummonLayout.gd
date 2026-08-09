class_name BossSummonLayout
extends RefCounted

## ボス専用スプライト据置のまま、呼び出し敵を左右＋手前へ置く（P3-UX-BOSS-SUMMON-LAYOUT-001）。
## add_index = 召喚連れの 0 始まり（swarm slot - 1）。
## 余白延長: 立ち位置拡大＋連れ HP/名前の胴体クリアランス。
## 2体召喚時はボス錨を左へ寄せ、右連れが X_MAX クランプで胴に戻るのを防ぐ。

const X_MIN_RATIO: float = 0.34
const X_MAX_RATIO: float = 0.96
const Y_MIN_RATIO: float = 0.28
const Y_MAX_RATIO: float = 0.72
## ボス z_index（DungeonScene の BossSprite）より手前へ。
const BOSS_Z: int = 12
const ADD_Z_ABOVE_BOSS: int = 3
## 立ち位置オフセット（ボス比）。胴体と名前が被らないよう左右・手前を広めに。
const X_OFF_BASE: float = 0.24
const X_OFF_PER_RING: float = 0.10
const Y_OFF_BASE: float = 0.16
const Y_OFF_PER_RING: float = 0.04
## 2体以上召喚時のボス錨 X（左右対称の余白を確保）。
const BOSS_ANCHOR_DUAL_X: float = 0.60
## 連れオーバーレイをボス胴から離す（720 論理 px）。
const OVERLAY_OUTWARD_PX: float = 28.0
const OVERLAY_EXTRA_GAP_Y: float = 20.0
const OVERLAY_DUAL_MULT: float = 1.25


## 生存連れ数に応じたボス錨。2体以上は左寄せで左右ともクランプしにくくする。
static func layout_boss_ratio(base_ratio: Vector2, add_count: int) -> Vector2:
	if add_count >= 2:
		return Vector2(BOSS_ANCHOR_DUAL_X, base_ratio.y)
	return base_ratio


static func position_ratio(boss_ratio: Vector2, add_index: int) -> Vector2:
	var side: float = -1.0 if (add_index % 2) == 0 else 1.0
	var ring: int = int(add_index / 2)
	var x_off: float = side * (X_OFF_BASE + float(ring) * X_OFF_PER_RING)
	var y_off: float = Y_OFF_BASE + float(ring) * Y_OFF_PER_RING
	return Vector2(
		clampf(boss_ratio.x + x_off, X_MIN_RATIO, X_MAX_RATIO),
		clampf(boss_ratio.y + y_off, Y_MIN_RATIO, Y_MAX_RATIO)
	)


## 連れ HP／名前／技名ポップ用。x=外側（左右符号付き）、y=上方向の追加ギャップ。
static func overlay_nudge_px(add_index: int, add_count: int = 1) -> Vector2:
	var side: float = -1.0 if (add_index % 2) == 0 else 1.0
	var mult: float = OVERLAY_DUAL_MULT if add_count >= 2 else 1.0
	return Vector2(side * OVERLAY_OUTWARD_PX * mult, OVERLAY_EXTRA_GAP_Y * mult)


static func add_z_index(add_index: int) -> int:
	var ring: int = int(add_index / 2)
	return BOSS_Z + ADD_Z_ABOVE_BOSS + ring


static func is_boss_lead_enemy(data: Resource) -> bool:
	if data == null:
		return false
	return int(data.enemy_type) == Enums.EnemyType.BOSS
