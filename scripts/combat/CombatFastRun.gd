class_name CombatFastRun
extends RefCounted

## 高速周回・戦闘スキップ（P3-D118）。
## ダンジョン初回クリア後、通常戦闘(COMBAT)のみ即時撃破して周回時間を短縮する。

static func can_enable(dungeon_id: String) -> bool:
	return GameState.is_dungeon_cleared(dungeon_id)

static func can_skip_room(room_type: int, fast_run_enabled: bool) -> bool:
	if not fast_run_enabled:
		return false
	return room_type == Enums.RoomType.COMBAT or room_type == Enums.RoomType.ELITE

static func skip_log_message(room_type: int) -> String:
	if room_type == Enums.RoomType.ELITE:
		return "[周回] エリート戦闘をスキップ"
	return "[周回] 戦闘をスキップ"
