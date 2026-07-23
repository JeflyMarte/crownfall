extends GutTest

## 図鑑手引きが現行仕様・P3-W-031 とずれていないこと（P3-CODEX-GUIDE-001）。


func test_guide_no_outdated_combat_or_gacha_copy() -> void:
	var by_id: Dictionary = {}
	for entry: Dictionary in GuideCatalog.get_entries():
		by_id[str(entry.get("id", ""))] = str(entry.get("description", ""))

	var g006: String = str(by_id.get("COMBAT-G006", ""))
	assert_false(g006.is_empty())
	assert_false(g006.contains("2 枠"), "装備スキルは1本")
	assert_false(g006.contains("スキル①②"), "旧①②表記を撤去")
	assert_true(g006.contains("1 本"), "1本装備を明記")

	var g007: String = str(by_id.get("COMBAT-G007", ""))
	assert_false(g007.contains("長い再使用待ち"), "必殺はゲージ制")
	assert_true(g007.contains("必殺ゲージ"), "ゲージ説明あり")

	var g013: String = str(by_id.get("COMBAT-G013", ""))
	assert_true(g013.contains("天候シンクロ"), "天候レジェンド連動に言及")

	var g016: String = str(by_id.get("COMBAT-G016", ""))
	assert_false(g016.contains("職共通パッシブを使う"), "助っ人も固有あり")
	assert_true(g016.contains("招待状"), "招待状探索者の固有に言及")

	var eq001: String = str(by_id.get("EQUIP-G001", ""))
	assert_false(eq001.contains("4 段階"), "神話を含む")
	assert_true(eq001.contains("神話"), "神話帯を記載")

	var eq002: String = str(by_id.get("EQUIP-G002", ""))
	assert_false(eq002.contains("休止中"), "招待状は常時ON")
	assert_true(eq002.contains("魔晶石"), "魔晶石に言及")


func test_equip_level_guide_is_player_facing() -> void:
	var desc: String = ""
	for entry: Dictionary in GuideCatalog.get_entries():
		if str(entry.get("id", "")) == "EQUIP-G004":
			desc = str(entry.get("description", ""))
			break
	assert_false(desc.is_empty(), "EQUIP-G004 がある")
	assert_false(desc.contains("実効ステ"), "内部式を出さない")
	assert_false(desc.contains("成長率"), "内部用語を出さない")
	assert_false(desc.contains("端数切り捨て"), "実装用語を出さない")
	assert_false(desc.contains("10 + 現在装備レベル"), "必要EXP式を出さない")
	assert_false(desc.contains("敵レベル÷2"), "内部計算式を出さない")
	assert_true(desc.contains("錬成"), "錬成導線に言及")
	assert_true(desc.contains("神話"), "神話は錬成不可を案内")
	assert_true(desc.contains("炉研ぎ"), "炉研ぎと別枠であることに言及")


func test_cosmic_rift_flavor_uses_elda_rift() -> void:
	var dg: Resource = load("res://resources/dungeons/cosmic_rift.tres")
	assert_ne(dg, null)
	var flavor: String = str(dg.get("flavor_text"))
	assert_true(flavor.contains("エルダの裂け目"), "正称はエルダの裂け目")
	assert_false(flavor.contains("異界の裂け目"), "異界は民間俗称のためDG文から除去")
