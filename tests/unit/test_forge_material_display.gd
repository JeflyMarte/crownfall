extends GutTest

## P3-MAT-CODEx-001: 図鑑 S5 採取欄＝炉研ぎ共通3種。

func test_forge_material_display_names_matches_enhancement_ids() -> void:
	var names: PackedStringArray = EquipmentEnhancer.forge_material_display_names()
	assert_eq(names.size(), EquipmentEnhancer.ENHANCEMENT_MATERIAL_IDS.size())
	assert_eq(names.size(), 3)
	for mat_id in EquipmentEnhancer.ENHANCEMENT_MATERIAL_IDS:
		assert_true(EquipmentEnhancer.is_enhancement_material(str(mat_id)))
	# 表示名は空でなく、希少プレフィックスは rarity>=1 のみ
	for i in range(names.size()):
		assert_false(str(names[i]).is_empty(), "display name empty for index %d" % i)
	var elite_idx: int = EquipmentEnhancer.ENHANCEMENT_MATERIAL_IDS.find("elite_relic_shard")
	assert_gte(elite_idx, 0)
	assert_true(str(names[elite_idx]).begins_with("【希少】"))
