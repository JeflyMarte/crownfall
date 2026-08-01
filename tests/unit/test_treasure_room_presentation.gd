extends GutTest

const _Treasure = preload("res://scripts/dungeon/TreasureRoomPresentation.gd")
const _Colors = preload("res://scripts/dungeon/NonCombatNarrativeColors.gd")


func test_success_narrative_bbcode_colors_gold_and_gear() -> void:
	var bb: String = _Treasure.format_success_narrative_bbcode(
		"蓋が開いた", 120, "銀の指輪", "鉄の剣"
	)
	assert_true(bb.contains(_Colors.HEX_GOLD), "ゴールド色")
	assert_true(bb.contains("ゴールド +120"), "ゴールド行")
	assert_true(bb.contains(_Colors.HEX_WEAPON), "武器色")
	assert_true(bb.contains("鉄の剣"), "武器名")
	assert_true(bb.contains(_Colors.HEX_ACCESSORY), "装飾色")
	assert_true(bb.contains("銀の指輪"), "装飾名")


func test_plain_narrative_still_readable() -> void:
	var plain: String = _Treasure.format_success_narrative("開いた", 10, "A", "B")
	assert_true(plain.contains("ゴールド +10"))
	assert_true(plain.contains("武器: B"))
	assert_true(plain.contains("装飾品: A"))


func test_noncombat_colorize_lore_and_damage() -> void:
	var lore: String = _Colors.colorize_multiline("【碑文】記録\nゴールド +20\n加護: 次フロアの経験値 ×1.1")
	assert_true(lore.contains(_Colors.HEX_LORE_TITLE))
	assert_true(lore.contains(_Colors.HEX_GOLD))
	assert_true(lore.contains(_Colors.HEX_BUFF))
	var dmg: String = _Colors.colorize_line("アルド に 12 ダメージ！")
	assert_true(dmg.contains(_Colors.HEX_DAMAGE))


func test_reward_lines_include_generic_icons() -> void:
	var gold: String = _Colors.gold("ゴールド +20")
	assert_true(gold.contains("[img="), "ゴールド汎用アイコン")
	assert_true(gold.contains("ICO_Gold"), gold)
	var bless: String = _Colors.buff("加護: 次フロアの経験値 ×1.1")
	assert_true(bless.contains("[img="), "加護汎用アイコン")
	var lore: String = _Colors.lore_title("【碑文】記録")
	assert_true(lore.contains("[img="), "碑文タイトルアイコン")
	var setup: String = _Colors.format_setup_bbcode("壁面に刻印が浮かび上がっている…")
	assert_false(setup.contains("[img="), "説明文にはアイコンを付けない")


func test_strip_bbcode_keeps_plain_lines() -> void:
	var bb: String = _Treasure.format_success_narrative_bbcode("蓋が開いた", 50, "", "")
	var plain: String = _Colors.strip_bbcode(bb)
	assert_true(plain.contains("蓋が開いた"))
	assert_true(plain.contains("ゴールド +50"))
	assert_false(plain.contains("[color"), "タグ除去")
	assert_false(plain.contains("[img"), "img タグ除去")
