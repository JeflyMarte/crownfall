class_name ShadowStalkerLoot
extends RefCounted

## 影狩限定「死告」武器（P3-EQ-SHADOW-DEATHREAP-001）。

const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _WeaponInstance := preload("res://scripts/domain/WeaponInstance.gd")
const _JobStatCalculator := preload("res://scripts/equipment/JobStatCalculator.gd")
const _WanderingEnemyConfig := preload("res://scripts/dungeon/WanderingEnemyConfig.gd")

const WEAPON_IDS: Array[String] = [
	"deathreap_sword",
	"deathreap_dual",
	"deathreap_bow",
	"deathreap_staff",
]

const RECLEAR_CHANCE: float = 0.25
const PASSIVE_ID: String = "eq_wpn_deathreap"


static func is_deathreap_id(weapon_id: String) -> bool:
	return weapon_id in WEAPON_IDS


## 通常雑魚のみ。放浪（影狩本体含む）・ELITE・BOSS は不可。
static func is_instant_kill_eligible(enemy_data: Resource) -> bool:
	if enemy_data == null:
		return false
	if int(enemy_data.enemy_type) != Enums.EnemyType.NORMAL:
		return false
	if bool(enemy_data.is_wandering):
		return false
	if _WanderingEnemyConfig.is_wandering_id(str(enemy_data.id)):
		return false
	return true


static func owns_any() -> bool:
	for item in GameState.inventory:
		if item != null and is_deathreap_id(str(item.weapon_id)):
			return true
	return false


static func _owns(weapon_id: String) -> bool:
	for item in GameState.inventory:
		if item != null and str(item.weapon_id) == weapon_id:
			return true
	return false


## 影狩撃破時。付与した weapon_id。無しなら ""。
static func try_grant_on_kill() -> String:
	var pick: String = ""
	if not owns_any():
		pick = _pick_weapon_for_party()
	else:
		if randf() >= RECLEAR_CHANCE:
			return ""
		pick = _pick_reclear_piece()
	if pick.is_empty():
		return ""
	if not _grant_weapon(pick):
		return ""
	return pick


static func _pick_weapon_for_party() -> String:
	var preferred: Array[String] = []
	var unowned: Array[String] = []
	for wid in WEAPON_IDS:
		var id: String = str(wid)
		if _owns(id):
			continue
		unowned.append(id)
		var data: Resource = DataRegistry.get_weapon_data(id)
		if data == null:
			continue
		for member in GameState.party_members:
			if member == null:
				continue
			if _JobStatCalculator.can_equip_weapon_data(member, data):
				preferred.append(id)
				break
	if not preferred.is_empty():
		return preferred[randi() % preferred.size()]
	if not unowned.is_empty():
		return unowned[randi() % unowned.size()]
	return str(WEAPON_IDS[randi() % WEAPON_IDS.size()])


static func _pick_reclear_piece() -> String:
	var missing: Array[String] = []
	for wid in WEAPON_IDS:
		var id: String = str(wid)
		if not _owns(id):
			missing.append(id)
	if not missing.is_empty():
		var preferred_missing: Array[String] = []
		for id in missing:
			var data: Resource = DataRegistry.get_weapon_data(id)
			if data == null:
				continue
			for member in GameState.party_members:
				if member == null:
					continue
				if _JobStatCalculator.can_equip_weapon_data(member, data):
					preferred_missing.append(id)
					break
		if not preferred_missing.is_empty():
			return preferred_missing[randi() % preferred_missing.size()]
		return missing[randi() % missing.size()]
	return str(WEAPON_IDS[randi() % WEAPON_IDS.size()])


static func _grant_weapon(weapon_id: String) -> bool:
	if not is_deathreap_id(weapon_id):
		return false
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		return false
	var instance: Resource = _WeaponInstance.new()
	instance.instance_id = "deathreap_%s_%d_%d" % [weapon_id, Time.get_ticks_msec(), randi() % 100000]
	instance.weapon_id = weapon_id
	_WeaponStatResolver.apply_drop_stats(instance, weapon_data)
	instance.is_appraised = true
	if not GameState.try_add_weapon_instance(instance):
		return false
	if EventBus.has_signal("weapon_obtained"):
		EventBus.weapon_obtained.emit(weapon_id)
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	GameState.record_last_run_equipment_drop(instance, "weapon")
	return true
