extends GutTest

const _Helper := preload("res://scripts/ui/AccessoryIconHelper.gd")


func test_infer_type_separates_ring_charm_talisman_seal() -> void:
	assert_eq(_Helper.infer_type("verdant_ring"), _Helper.TYPE_RING)
	assert_eq(_Helper.infer_type("frost_fang_charm"), _Helper.TYPE_CHARM)
	assert_eq(_Helper.infer_type("granvel_fang_talisman"), _Helper.TYPE_TALISMAN)
	assert_eq(_Helper.infer_type("mourngate_sigil"), _Helper.TYPE_SEAL)
	assert_eq(_Helper.infer_type("clockwing_brooch"), _Helper.TYPE_CHARM)


func test_explicit_accessory_type_overrides_id() -> void:
	assert_eq(_Helper.infer_type("weird_id", "seal"), _Helper.TYPE_SEAL)


func test_generic_paths_exist_and_differ() -> void:
	var paths: Array[String] = []
	for t in [_Helper.TYPE_RING, _Helper.TYPE_CHARM, _Helper.TYPE_TALISMAN, _Helper.TYPE_SEAL]:
		var path: String = _Helper.generic_path(t)
		assert_true(ResourceLoader.exists(path), path)
		paths.append(path)
	assert_eq(paths.size(), 4)
	assert_ne(paths[0], paths[1])
	assert_ne(paths[0], paths[2])
	assert_ne(paths[0], paths[3])
	assert_ne(paths[1], paths[2])
	assert_ne(paths[1], paths[3])
	assert_ne(paths[2], paths[3])


func test_biome_accessories_use_shape_generics() -> void:
	var ring_path: String = str(IconPaths.ICON_MAP.get("accessory:verdant_ring", ""))
	var charm_path: String = str(IconPaths.ICON_MAP.get("accessory:spore_charm", ""))
	var tal_path: String = str(IconPaths.ICON_MAP.get("accessory:granvel_fang_talisman", ""))
	assert_true(ring_path.ends_with("ICO_ACC_Generic_Ring.png"), ring_path)
	assert_true(charm_path.ends_with("ICO_ACC_Generic_Charm.png"), charm_path)
	assert_true(tal_path.ends_with("ICO_ACC_Generic_Talisman.png"), tal_path)
	assert_ne(ring_path, charm_path)


func test_hand_drawn_accessories_keep_unique_icons() -> void:
	var kaiwan: String = str(IconPaths.ICON_MAP.get("accessory:kaiwan_initio", ""))
	var seal: String = str(IconPaths.ICON_MAP.get("accessory:council_hegemony_seal", ""))
	assert_true(kaiwan.ends_with("ICO_ACC_KaiwanInitio.png"), kaiwan)
	assert_true(seal.ends_with("ICO_ACC_CouncilHegemonySeal.png"), seal)
