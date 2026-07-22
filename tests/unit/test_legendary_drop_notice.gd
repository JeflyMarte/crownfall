extends GutTest

const _DungeonController := preload("res://scripts/dungeon/DungeonController.gd")
const _SfxCatalog := preload("res://scripts/audio/SfxCatalog.gd")


func test_legendary_drop_weight_is_rarer_than_pre_patch() -> void:
	## 旧: 40/15/5/1 → 新: 120/45/15/1。LEGENDARY 相対は約 1/3。
	var w: Dictionary = _DungeonController.RARITY_DROP_WEIGHT
	assert_eq(int(w[Enums.Rarity.COMMON]), 120)
	assert_eq(int(w[Enums.Rarity.RARE]), 45)
	assert_eq(int(w[Enums.Rarity.EPIC]), 15)
	assert_eq(int(w[Enums.Rarity.LEGENDARY]), 1)
	var total: int = (
		int(w[Enums.Rarity.COMMON])
		+ int(w[Enums.Rarity.RARE])
		+ int(w[Enums.Rarity.EPIC])
		+ int(w[Enums.Rarity.LEGENDARY])
	)
	var leg_share: float = float(w[Enums.Rarity.LEGENDARY]) / float(total)
	assert_lt(leg_share, 0.01)
	assert_gt(leg_share, 0.0)


func test_legendary_drop_sfx_wired() -> void:
	var path: String = _SfxCatalog.path_for(_SfxCatalog.ID_LEGENDARY_DROP)
	assert_false(path.is_empty())
	assert_true(ResourceLoader.exists(path))
