extends GutTest

const _Treasure = preload("res://scripts/dungeon/TreasureRoomPresentation.gd")


func test_success_narrative_bbcode_colors_gold_and_gear() -> void:
	var bb: String = _Treasure.format_success_narrative_bbcode(
		"蓋が開いた", 120, "銀の指輪", "鉄の剣"
	)
	assert_true(bb.contains(_Treasure.COLOR_GOLD_HEX), "ゴールド色")
	assert_true(bb.contains("ゴールド +120"), "ゴールド行")
	assert_true(bb.contains(_Treasure.COLOR_WEAPON_HEX), "武器色")
	assert_true(bb.contains("鉄の剣"), "武器名")
	assert_true(bb.contains(_Treasure.COLOR_ACCESSORY_HEX), "装飾色")
	assert_true(bb.contains("銀の指輪"), "装飾名")


func test_plain_narrative_still_readable() -> void:
	var plain: String = _Treasure.format_success_narrative("開いた", 10, "A", "B")
	assert_true(plain.contains("ゴールド +10"))
	assert_true(plain.contains("武器: B"))
	assert_true(plain.contains("装飾品: A"))
