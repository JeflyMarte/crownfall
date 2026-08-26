extends GutTest
## P3-UX-AUTO-DISMANTLE-001 — ダンジョン拾得◇◆の自動分解。

const _SettingsPrefs := preload("res://scripts/settings/SettingsPrefs.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")

var _prev_settings: String = ""


func before_each() -> void:
	_SettingsPrefs._loaded = false
	_SettingsPrefs._reset_defaults()
	if FileAccess.file_exists(_SettingsPrefs.PATH):
		_prev_settings = FileAccess.get_file_as_string(_SettingsPrefs.PATH)
		DirAccess.open("user://").remove("settings.cfg")
	else:
		_prev_settings = ""
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.material_inventory.clear()
	GameState.clear_last_run_equipment_drops()
	GameState.gold = 0


func after_each() -> void:
	if FileAccess.file_exists(_SettingsPrefs.PATH):
		DirAccess.open("user://").remove("settings.cfg")
	if not _prev_settings.is_empty():
		var f: FileAccess = FileAccess.open(_SettingsPrefs.PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(_prev_settings)
			f.close()
	_SettingsPrefs._loaded = false
	_SettingsPrefs.load_from_disk()
	_SettingsPrefs._loaded = true


func _make_drop_weapon(weapon_id: String) -> Resource:
	var cls = load("res://scripts/domain/WeaponInstance.gd")
	var item: Resource = cls.new()
	item.instance_id = "auto_dm_%s_%d" % [weapon_id, randi()]
	item.weapon_id = weapon_id
	item.is_appraised = true
	item.equip_level = 1
	var data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if data != null:
		_WeaponStatResolver.apply_drop_stats(item, data)
	GameState.inventory.append(item)
	GameState.record_last_run_equipment_drop(item, "weapon")
	return item


func test_setting_default_off() -> void:
	_SettingsPrefs.ensure_loaded()
	assert_false(_SettingsPrefs.is_auto_dismantle_common_rare())


func test_off_keeps_common_in_inventory() -> void:
	_SettingsPrefs.set_auto_dismantle_common_rare(false)
	var item: Resource = _make_drop_weapon("iron_sword")
	assert_eq(EquipmentEnhancer.item_rarity(item), Enums.Rarity.COMMON)
	assert_false(EquipmentEnhancer.maybe_auto_dismantle_dungeon_drop(item))
	assert_true(item in GameState.inventory)


func test_on_dismantles_common_drop_only() -> void:
	_SettingsPrefs.set_auto_dismantle_common_rare(true)
	## 既所持として残す分
	var kept: Resource = _make_drop_weapon("iron_sword")
	GameState.clear_last_run_equipment_drops()
	## 今回ドロップ扱い
	var drop: Resource = _make_drop_weapon("iron_sword")
	assert_true(EquipmentEnhancer.maybe_auto_dismantle_dungeon_drop(drop))
	assert_false(drop in GameState.inventory)
	assert_true(kept in GameState.inventory, "既存所持はノータッチ")
	assert_gt(int(GameState.material_inventory.get(EquipmentEnhancer.BASE_ORE_ID, 0)), 0)
	assert_true(bool(GameState.last_run_equipment_drops[0].get("auto_dismantled", false)))


func test_on_skips_epic_or_higher() -> void:
	_SettingsPrefs.set_auto_dismantle_common_rare(true)
	var epic_id: String = ""
	for data: Resource in DataRegistry.get_all_weapon_data():
		if data != null and int(data.rarity) >= Enums.Rarity.EPIC:
			epic_id = str(data.id)
			break
	if epic_id.is_empty():
		pending("no epic+ weapon in registry")
		return
	var item: Resource = _make_drop_weapon(epic_id)
	assert_false(EquipmentEnhancer.maybe_auto_dismantle_dungeon_drop(item))
	assert_true(item in GameState.inventory)
