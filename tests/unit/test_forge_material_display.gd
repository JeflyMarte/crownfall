extends GutTest

## P3-MAT-CODEx-001 / P3-MAT-RARITY-001

func test_forge_material_display_names_matches_enhancement_ids() -> void:
	var names: PackedStringArray = EquipmentEnhancer.forge_material_display_names()
	assert_eq(names.size(), EquipmentEnhancer.ENHANCEMENT_MATERIAL_IDS.size())
	assert_eq(names.size(), 3)
	for mat_id in EquipmentEnhancer.ENHANCEMENT_MATERIAL_IDS:
		assert_true(EquipmentEnhancer.is_enhancement_material(str(mat_id)))
	for i in range(names.size()):
		assert_false(str(names[i]).is_empty(), "display name empty for index %d" % i)
		assert_false(str(names[i]).begins_with("【希少】"))
