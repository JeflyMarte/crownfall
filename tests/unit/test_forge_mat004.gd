extends GutTest

## P3-MAT-004 / P3-FORGE-002 / P3-FORGE-003

const _Enh = preload("res://scripts/equipment/EquipmentEnhancer.gd")

func test_enhancement_material_ids_are_five() -> void:
	assert_eq(_Enh.ENHANCEMENT_MATERIAL_IDS.size(), 5)
	assert_true(_Enh.is_enhancement_material("base_ore"))
	assert_true(_Enh.is_enhancement_material("epic_ore"))

func test_common_weapon_forge_cost_uses_base_ore() -> void:
	var costs: Dictionary = _Enh.get_material_cost(1, Enums.Rarity.COMMON)
	assert_eq(costs.get(_Enh.COMMON_MATERIAL_ID), 1)
	assert_eq(costs.get(_Enh.BASE_ORE_ID), 1)

func test_rare_forge_plus4_adds_epic_ore() -> void:
	var costs: Dictionary = _Enh.get_material_cost(4, Enums.Rarity.RARE)
	assert_true(costs.has(_Enh.EPIC_ORE_ID))

func test_armor_enhance_adds_def_and_hp() -> void:
	var armor: Resource = ArmorInstance.new()
	armor.armor_id = "leather_armor"
	## 移行済み扱い（空 mods だと ensure_migrated がマスタ基礎へ正規化する）
	armor.rolled_defense = 40
	armor.hp_bonus = 5
	armor.is_appraised = true
	armor.enhance_level = 2
	armor.random_mods = [{
		"id": "hp_up", "label": "HPアップ", "kind": "hp_up",
		"value": 5, "min_v": 1, "max_v": 5, "perfect": false, "meta": {},
	}]
	assert_eq(
		_Enh.effective_armor_defense(armor),
		_Enh.scale_equip_stat(40, 1, 0) + 2 * BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL
	)
	assert_eq(
		_Enh.effective_armor_hp(armor),
		_Enh.scale_equip_stat(5, 1, 0) + 2 * BalanceConfig.EQUIP_FORGE_HP_PER_LEVEL
	)

func test_dismantle_common_weapon_yields_base_and_common() -> void:
	## 生産可能◇は 80%キャップ＋最低1。表は基礎3だがコスト1のため実返却は基礎1＋共通1。
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = "iron_sword"
	weapon.is_appraised = true
	GameState.inventory.append(weapon)
	var preview: Dictionary = _Enh.dismantle_preview(weapon)
	assert_true(preview.get("ok", false))
	assert_eq(preview["materials"].get(_Enh.BASE_ORE_ID), 1)
	assert_eq(preview["materials"].get(_Enh.COMMON_MATERIAL_ID), 1)


func test_can_dismantle_has_no_materials_preview_has() -> void:
	## 確認UIは dismantle_preview（materials 付き）。can_dismantle は可否のみ。
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = "iron_sword"
	weapon.is_appraised = true
	GameState.inventory.append(weapon)
	var can: Dictionary = _Enh.can_dismantle_item(weapon)
	assert_true(bool(can.get("ok", false)))
	assert_false(can.has("materials"))
	var preview: Dictionary = _Enh.dismantle_preview(weapon)
	assert_true(bool(preview.get("ok", false)))
	assert_true(preview.has("materials"))
	assert_gt((preview.get("materials", {}) as Dictionary).size(), 0)


func test_dismantle_craft_cap_is_eighty_percent_with_min_one() -> void:
	assert_eq(_Enh.DISMANTLE_CRAFT_RETURN_CAP, 0.8)
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = "iron_sword"
	weapon.is_appraised = true
	var mats: Dictionary = _Enh.dismantle_preview(weapon).get("materials", {})
	assert_gte(int(mats.get(_Enh.BASE_ORE_ID, 0)), 1)
	assert_gte(int(mats.get(_Enh.COMMON_MATERIAL_ID, 0)), 1)


func test_dismantle_rare_craftable_keeps_primary_ore() -> void:
	## ◆生産可能: 蒼古コスト1 → 80%でも最低1を残す（旧 floor だと0）。
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = "tinder_bow"
	weapon.is_appraised = true
	assert_eq(_Enh.item_rarity(weapon), Enums.Rarity.RARE)
	var mats: Dictionary = _Enh.dismantle_preview(weapon).get("materials", {})
	assert_eq(int(mats.get(_Enh.RARE_ORE_ID, 0)), 1)
	assert_gte(int(mats.get(_Enh.COMMON_MATERIAL_ID, 0)), 1)

func test_bulk_dismantle_only_common_and_rare() -> void:
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	var common_w: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	common_w.weapon_id = "iron_sword"
	common_w.is_appraised = true
	GameState.inventory.append(common_w)
	var candidates: Array = _Enh.list_bulk_dismantle_candidates()
	assert_eq(candidates.size(), 1)
	_Enh.dismantle_bulk_common_rare()
	assert_eq(GameState.inventory.size(), 0)
