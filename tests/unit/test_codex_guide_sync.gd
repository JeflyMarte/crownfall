extends GutTest

## 図鑑手引きが現行仕様・P3-W-031 とずれていないこと（P3-CODEX-GUIDE-001〜003）。


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
	assert_false(g007.contains("×0.10"), "チャージ係数を出さない")
	assert_false(g007.contains("×0.20"), "チャージ係数を出さない")

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
	assert_true(eq002.contains("限界突破"), "限界突破を案内")


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


func test_combat_guides_player_facing_no_internal_formulas() -> void:
	var by_id: Dictionary = {}
	for entry: Dictionary in GuideCatalog.get_entries():
		by_id[str(entry.get("id", ""))] = str(entry.get("description", ""))

	var g002: String = str(by_id.get("COMBAT-G002", ""))
	assert_false(g002.is_empty())
	assert_true(g002.contains("毒"), "状態異常の代表に言及")
	assert_false(g002.contains("/刻、5 刻、最大 3 スタック"), "刻ごとの固定値羅列を避ける")

	var g010: String = str(by_id.get("COMBAT-G010", ""))
	assert_true(g010.contains("脅威"), "脅威の説明あり")
	assert_false(g010.contains("+0.10"), "与ダメあたり係数を出さない")
	assert_false(g010.contains("+0.15"), "被ダメあたり係数を出さない")
	assert_false(g010.contains("90％ 減衰"), "減衰式を出さない")

	var g011: String = str(by_id.get("COMBAT-G011", ""))
	assert_true(g011.contains("防御"), "防御の影響に言及")
	assert_false(g011.contains("逓減"), "内部用語を出さない")
	assert_false(g011.contains("/("), "防御式を出さない")
	assert_false(g011.contains("×1.25"), "弱点倍率の羅列を避ける")


func test_hub_and_field_guide_entries_exist() -> void:
	var by_id: Dictionary = {}
	for entry: Dictionary in GuideCatalog.get_entries():
		by_id[str(entry.get("id", ""))] = str(entry.get("description", ""))

	var survey: String = str(by_id.get("SYS-G001", ""))
	assert_false(survey.is_empty(), "調査室の条がある")
	assert_true(survey.contains("70"), "②解放の調査ゲージ条件")
	assert_true(survey.contains("20"), "短調査20分")
	assert_true(survey.contains("3 時間") or survey.contains("3時間"), "標準調査3時間")

	var otomo: String = str(by_id.get("SYS-G002", ""))
	assert_true(otomo.contains("ジャック"), "オトモ名")
	assert_true(otomo.contains("前衛"), "常時前衛")
	assert_true(otomo.contains("招待状"), "招待状対象外に言及")

	var field: String = str(by_id.get("SYS-G003", ""))
	assert_true(field.contains("今日のダンジョン状態"), "UI名")
	assert_true(field.contains("30"), "30分スロット")
	assert_true(field.contains("穏やか"), "穏やか最頻")

	var event_dg: String = str(by_id.get("SYS-G004", ""))
	assert_true(event_dg.contains("裂け目") or event_dg.contains("エルダ"), "ダックDG")
	assert_true(event_dg.contains("巣") or event_dg.contains("レイヴン"), "レイヴンDG")
	assert_true(event_dg.contains("一日"), "日次挑戦")

	var wander: String = str(by_id.get("SYS-G005", ""))
	assert_true(wander.contains("ダック"), "放浪ダック")
	assert_true(wander.contains("レイヴン"), "放浪レイヴン")
	assert_true(wander.contains("逃走") or wander.contains("経験"), "ダック特性")
	assert_true(wander.contains("装備") or wander.contains("神話"), "レイヴン特性")

	var daily: String = str(by_id.get("SYS-G006", ""))
	assert_false(daily.is_empty(), "日課の条がある")
	assert_true(daily.contains("3"), "毎日3件")
	assert_true(daily.contains("5:00") or daily.contains("5：00"), "JST5時リセット")

	var rooms: String = str(by_id.get("SYS-G007", ""))
	assert_false(rooms.is_empty(), "部屋と罠の条がある")
	assert_true(rooms.contains("罠"), "罠に言及")
	assert_true(rooms.contains("安全優先"), "探索方針との関係")

	var formation: String = str(by_id.get("COMBAT-G003", ""))
	assert_true(formation.contains("ジャック"), "陣形にオトモ関係")
	assert_true(formation.contains("密集"), "密集とジャックの関係")

	var eq002: String = str(by_id.get("EQUIP-G002", ""))
	assert_true(eq002.contains("限界突破"), "限界突破の厚み")
	assert_true(eq002.contains("パッシブ"), "突破でパッシブ強化")


func test_cosmic_rift_flavor_uses_elda_rift() -> void:
	var dg: Resource = load("res://resources/dungeons/cosmic_rift.tres")
	assert_ne(dg, null)
	var flavor: String = str(dg.get("flavor_text"))
	assert_true(flavor.contains("エルダの裂け目"), "正称はエルダの裂け目")
	assert_false(flavor.contains("異界の裂け目"), "異界は民間俗称のためDG文から除去")


func test_world_guide_entries_cover_canon_basics() -> void:
	var by_id: Dictionary = {}
	for entry: Dictionary in GuideCatalog.get_entries():
		by_id[str(entry.get("id", ""))] = str(entry.get("description", ""))

	var required: Array[String] = [
		"WORLD-G001", "WORLD-G002", "WORLD-G003", "WORLD-G004", "WORLD-G005",
		"WORLD-G006", "WORLD-G007", "WORLD-G008", "WORLD-G009", "WORLD-G010",
		"WORLD-G011", "WORLD-G012",
	]
	for wid: String in required:
		assert_false(str(by_id.get(wid, "")).is_empty(), "%s がある" % wid)

	assert_true(str(by_id.get("WORLD-G002", "")).contains("魔法"), "魔法不在に言及")
	assert_true(str(by_id.get("WORLD-G002", "")).contains("エルダ"), "エルダ定義")
	assert_true(str(by_id.get("WORLD-G003", "")).contains("調査"), "ギルドは調査機関")
	assert_true(str(by_id.get("WORLD-G003", "")).contains("冒険者組合ではない"), "組合否定")
	assert_true(str(by_id.get("WORLD-G008", "")).contains("異界"), "民間俗称に触れつつ否定")
	assert_true(str(by_id.get("WORLD-G011", "")).contains("鉱物化"), "モーンゲート生態")
	assert_true(str(by_id.get("WORLD-G012", "")).contains("共生"), "ウィスパーウッド生態")


func test_mourngate_flavor_matches_postwar_ecology() -> void:
	var dg: Resource = load("res://resources/dungeons/mourngate.tres")
	assert_ne(dg, null)
	var flavor: String = str(dg.get("flavor_text"))
	assert_true(flavor.contains("鉱物化") or flavor.contains("排水"), "正典の地下生態")
	assert_false(flavor.contains("魔法"), "魔法表現を撤去")
	assert_false(flavor.contains("亡霊"), "亡霊表現を撤去")
