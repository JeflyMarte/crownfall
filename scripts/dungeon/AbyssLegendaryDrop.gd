class_name AbyssLegendaryDrop
extends RefCounted

## 深層レジェンド低確率ドロップ＋ソフト天井（P3-DG-ABYSS-001-D）。
## 99初回付与後、100/110/… 到達ごとに抽選。失敗で天井進捗。

const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
const _AbyssLegendaryWeapons := preload("res://scripts/dungeon/AbyssLegendaryWeapons.gd")

## 抽選開始階（99初回クリア後のエンドレス帯）。
const DROP_FLOOR_START: int = 100
const DROP_FLOOR_STEP: int = 10
## 10Fマーカー到達ごとの基本確率。
const BASE_CHANCE: float = 0.05
## 連続ハズレ回数。この回数に達した次のマーカーで確定。
const SOFT_CEILING: int = 10

const PITY_SAVE_KEY: String = "abyss_leg_pity"


## floor 到達時の抽選。付与したら drop summary、対象外は {}、ハズレは kind=miss。
## force_roll: 0..1 を渡すと rng の代わりに使う（テスト用）。負なら通常抽選。
static func try_on_floor(
	dungeon_id: String,
	floor_1based: int,
	rng: RandomNumberGenerator = null,
	force_roll: float = -1.0
) -> Dictionary:
	if not _is_eligible_floor(dungeon_id, floor_1based):
		return {}
	var pity: int = get_pity(dungeon_id)
	var guaranteed: bool = pity >= SOFT_CEILING
	var roll: float = force_roll
	if roll < 0.0:
		roll = rng.randf() if rng != null else randf()
	if not guaranteed and roll > BASE_CHANCE:
		set_pity(dungeon_id, pity + 1)
		return {
			"kind": "miss",
			"floor": floor_1based,
			"pity": pity + 1,
			"soft_ceiling": SOFT_CEILING,
		}
	var granted: Resource = _AbyssLegendaryWeapons.grant_for_abyss(dungeon_id)
	var wname: String = _AbyssLegendaryWeapons.display_name_for_abyss(dungeon_id)
	set_pity(dungeon_id, 0)
	if granted == null:
		return {
			"kind": "fail",
			"floor": floor_1based,
			"weapon_name": wname,
		}
	var label: String = "深層レジェンド再滴：%s" % wname
	if guaranteed:
		label = "深層レジェンド天井：%s" % wname
	_append_run_notice(label)
	return {
		"kind": "drop",
		"floor": floor_1based,
		"guaranteed": guaranteed,
		"weapon_id": _AbyssLegendaryWeapons.weapon_id_for_abyss(dungeon_id),
		"weapon_name": wname,
		"label": label,
		"pity": 0,
	}


static func _is_eligible_floor(dungeon_id: String, floor_1based: int) -> bool:
	if not _AbyssDungeonConfig.is_abyss_dungeon_id(dungeon_id):
		return false
	if floor_1based < DROP_FLOOR_START:
		return false
	if floor_1based % DROP_FLOOR_STEP != 0:
		return false
	## 99初回未達成なら抽選しない（初回本体はマイルストーン側）。
	if not _has_claimed_first_99(dungeon_id):
		return false
	return true


static func _has_claimed_first_99(dungeon_id: String) -> bool:
	var progress: Dictionary = GameState.dungeon_progress.get(dungeon_id, {})
	var root: Variant = progress.get("abyss_milestones", {})
	if root is not Dictionary:
		return false
	var first: Variant = (root as Dictionary).get("first", {})
	if first is not Dictionary:
		return false
	return bool((first as Dictionary).get("99", false))


static func get_pity(dungeon_id: String) -> int:
	var progress: Dictionary = GameState.dungeon_progress.get(dungeon_id, {})
	return maxi(0, int(progress.get(PITY_SAVE_KEY, 0)))


static func set_pity(dungeon_id: String, value: int) -> void:
	var progress: Dictionary = GameState.dungeon_progress.get(dungeon_id, {})
	progress[PITY_SAVE_KEY] = maxi(0, value)
	GameState.dungeon_progress[dungeon_id] = progress


static func is_decade_floor(floor_1based: int) -> bool:
	return floor_1based >= DROP_FLOOR_START and floor_1based % DROP_FLOOR_STEP == 0


static func _append_run_notice(line: String) -> void:
	if line.is_empty():
		return
	if not (GameState.last_run_abyss_notices is Array):
		GameState.last_run_abyss_notices = []
	GameState.last_run_abyss_notices.append(line)
