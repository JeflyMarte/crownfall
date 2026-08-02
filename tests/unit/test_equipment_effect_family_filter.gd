extends GutTest

const _WeaponInstance := preload("res://scripts/domain/WeaponInstance.gd")
const _ArmorInstance := preload("res://scripts/domain/ArmorInstance.gd")


func test_kind_maps_to_expected_families() -> void:
	var w: Resource = _WeaponInstance.new()
	w.weapon_id = "iron_sword"
	w.random_mods = [{
		"kind": EquipmentRandomMods.KIND_ON_HIT,
		"value": 0.1,
		"label": "状態付与",
		"meta": {"status_id": "poison"},
	}]
	assert_true(
		EquipmentEffectFamilyFilter.item_matches_family(
			w, "weapon", EquipmentEffectFamilyFilter.FAMILY_STATUS
		)
	)
	assert_false(
		EquipmentEffectFamilyFilter.item_matches_family(
			w, "weapon", EquipmentEffectFamilyFilter.FAMILY_CRIT
		)
	)


func test_filter_entries_or_across_families() -> void:
	var atk: Resource = _WeaponInstance.new()
	atk.weapon_id = "iron_sword"
	atk.random_mods = [{"kind": EquipmentRandomMods.KIND_ATTACK_UP, "value": 5, "label": "攻"}]
	var crit: Resource = _WeaponInstance.new()
	crit.weapon_id = "iron_sword"
	crit.random_mods = [{"kind": EquipmentRandomMods.KIND_CRIT_RATE, "value": 0.05, "label": "会"}]
	var gold: Resource = _WeaponInstance.new()
	gold.weapon_id = "iron_sword"
	gold.random_mods = [{"kind": EquipmentRandomMods.KIND_GOLD_GAIN, "value": 0.1, "label": "金"}]
	var entries: Array = [
		{"item": atk, "category": "weapon"},
		{"item": crit, "category": "weapon"},
		{"item": gold, "category": "weapon"},
	]
	var filtered: Array = EquipmentEffectFamilyFilter.filter_entries(
		entries,
		[
			EquipmentEffectFamilyFilter.FAMILY_OFFENSE,
			EquipmentEffectFamilyFilter.FAMILY_CRIT,
		]
	)
	assert_eq(filtered.size(), 2)


func test_empty_selection_returns_all() -> void:
	var w: Resource = _WeaponInstance.new()
	w.weapon_id = "iron_sword"
	w.random_mods = []
	var entries: Array = [{"item": w, "category": "weapon"}]
	assert_eq(EquipmentEffectFamilyFilter.filter_entries(entries, []).size(), 1)


func test_button_summary() -> void:
	assert_eq(EquipmentEffectFamilyFilter.button_summary([]), "効果")
	assert_eq(
		EquipmentEffectFamilyFilter.button_summary([EquipmentEffectFamilyFilter.FAMILY_ECONOMY]),
		"効果:稼ぎ"
	)
	assert_eq(
		EquipmentEffectFamilyFilter.button_summary(
			[
				EquipmentEffectFamilyFilter.FAMILY_OFFENSE,
				EquipmentEffectFamilyFilter.FAMILY_STATUS,
			]
		),
		"効果×2"
	)


func test_catalog_has_effect_button() -> void:
	var packed: PackedScene = load("res://scenes/equipment/EquipmentCatalogScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	var btn: Node = scene.get_node_or_null("MainVBox/InventoryHeaderRow/ButtonEffect")
	assert_not_null(btn)
	assert_true(btn is Button)


func test_catalog_has_relic_category_tab() -> void:
	var packed: PackedScene = load("res://scenes/equipment/EquipmentCatalogScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene._category_panels.has("relic"), "relic category chip")
	var relic_ids: Array = CombatPassives.relic_passive_ids()
	if relic_ids.is_empty():
		pending("no relic passives")
		return
	var rid: String = str(relic_ids[0])
	GameState.unlock_relic(rid)
	scene._on_category_pressed("relic")
	await get_tree().process_frame
	assert_eq(str(scene._inventory_filter), "relic")
	assert_gte(scene._inventory_grid.get_child_count(), 1)
	assert_true(scene._btn_effect.disabled, "effect filter disabled on relic tab")


func test_equipment_scene_has_effect_button() -> void:
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	var btn: Node = scene.get_node_or_null(
		"VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryHeaderRow/ButtonEffect"
	)
	assert_not_null(btn)
	assert_true(btn is Button)


func test_armor_resist_counts_as_defense_family() -> void:
	var armor: Resource = _ArmorInstance.new()
	armor.armor_id = "bone_armor"
	armor.random_mods = []
	## bone_armor はマスタに闇耐性を持つ想定。無ければスキップ相当で false でもよいが存在する前提。
	var data: Resource = DataRegistry.get_armor_data("bone_armor")
	if data == null:
		pending("bone_armor missing")
		return
	var resists: Array = data.resist_elements if "resist_elements" in data else []
	if resists.is_empty():
		pending("bone_armor has no resist_elements")
		return
	assert_true(
		EquipmentEffectFamilyFilter.item_matches_family(
			armor, "armor", EquipmentEffectFamilyFilter.FAMILY_DEFENSE
		)
	)
