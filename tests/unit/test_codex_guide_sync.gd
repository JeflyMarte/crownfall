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
	assert_true(g007.contains("時間"), "時間チャージに言及")
	assert_true(g007.contains("100"), "満タン目安100秒")
	assert_false(g007.contains("50 秒"), "旧50秒表記を撤去")
	assert_false(g007.contains("持ち込みが半分"), "ELITE/BOSS圧力説明を撤去")
	assert_false(g007.contains("与ダメージと被ダメージでチャージ"), "旧ダメ連動を撤去")
	assert_false(g007.contains("時間経過では溜まらない"), "旧否定文を撤去")
	assert_false(g007.contains("×0.10"), "チャージ係数を出さない")
	assert_false(g007.contains("×0.20"), "チャージ係数を出さない")

	var g015: String = str(by_id.get("COMBAT-G015", ""))
	assert_true(g015.contains("指揮の軍旗"), "レリック改変後の名称")
	assert_true(g015.contains("連撃の歯車"), "レリック改変後の名称")
	assert_false(g015.contains("王国軍旗"), "旧レリック名を撤去")
	assert_false(g015.contains("古い砂時計"), "旧レリック名を撤去")

	var g013: String = str(by_id.get("COMBAT-G013", ""))
	assert_true(g013.contains("天候シンクロ"), "天候レジェンド連動に言及")
	assert_true(g013.contains("炎天"), "炎天を列挙")
	assert_true(g013.contains("吹雪"), "吹雪を列挙")
	assert_true(g013.contains("+10%") or g013.contains("＋10%"), "雨等の現行倍率")
	assert_false(g013.contains("×1.15"), "旧倍率を撤去")
	assert_false(g013.contains("55％") or g013.contains("55%"), "旧晴れ出現率を撤去")

	var g002: String = str(by_id.get("COMBAT-G002", ""))
	assert_false(g002.contains("固定ダメージ"), "DoTは攻撃力追従")
	assert_true(g002.contains("長め") and g002.contains("短め"), "毒／炎上の役割")

	var g016: String = str(by_id.get("COMBAT-G016", ""))
	assert_false(g016.contains("職共通パッシブを使う"), "助っ人も固有あり")
	assert_true(g016.contains("招待状"), "招待状探索者の固有に言及")

	var g018: String = str(by_id.get("COMBAT-G018", ""))
	assert_false(g018.is_empty(), "パーティ連携の手引きがある")
	assert_true(g018.contains("連携斬"), "連携斬を記載")
	assert_true(g018.contains("追い込み"), "追い込みを記載")
	assert_true(g018.contains("治癒連携"), "治癒連携を記載")

	var g019: String = str(by_id.get("COMBAT-G019", ""))
	assert_false(g019.is_empty(), "戦術タブの手引きがある")
	assert_true(g019.contains("戦術"), "戦術に言及")

	var eq010: String = str(by_id.get("EQUIP-G010", ""))
	assert_true(eq010.contains("錬成"), "錬成手引き")
	assert_true(eq010.contains("神話"), "神話の錬成コストに言及")
	assert_true(eq010.contains("ゴールド") or eq010.contains("高"), "錬成コストの案内")

	assert_true(str(by_id.get("SYS-G008", "")).contains("指揮官"), "指揮官ランク")
	assert_true(str(by_id.get("SYS-G009", "")).contains("封蔵") or str(by_id.get("SYS-G009", "")).contains("灰冠"), "封蔵")
	assert_true(str(by_id.get("SYS-G010", "")).contains("展示室"), "展示室")
	assert_true(str(by_id.get("SYS-G011", "")).contains("無限"), "無限DG")
	assert_true(str(by_id.get("SYS-G012", "")).contains("全滅") or str(by_id.get("SYS-G012", "")).contains("敗因"), "全滅敗因")

	var eq001: String = str(by_id.get("EQUIP-G001", ""))
	assert_false(eq001.contains("4 段階"), "神話を含む")
	assert_true(eq001.contains("神話"), "神話帯を記載")

	var eq002: String = str(by_id.get("EQUIP-G002", ""))
	assert_false(eq002.contains("休止中"), "招待状は常時ON")
	assert_true(eq002.contains("魔晶石"), "魔晶石に言及")
	assert_true(eq002.contains("限界突破"), "限界突破を案内")
	assert_true(eq002.contains("①") or eq002.contains("フロストリッジ") or eq002.contains("5-5"), "初期仲間の章範囲")
	assert_true(eq002.contains("増えず") or eq002.contains("加入"), "5-5加入なしに言及")


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
	assert_true(desc.contains("神話"), "神話の錬成コストに言及")
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
	assert_false(survey.contains("70"), "②解放に調査ゲージ条件を書かない")
	assert_false(survey.contains("SURVEY"), "内部英語SURVEYを出さない")
	assert_true(survey.contains("ボス"), "①ボス討伐で②解放")
	assert_true(survey.contains("簡易調査"), "簡易調査の呼称")
	assert_true(survey.contains("本格調査"), "本格調査の呼称")
	assert_true(survey.contains("1 時間") or survey.contains("1時間"), "簡易調査1時間")
	assert_true(survey.contains("3 時間") or survey.contains("3時間"), "本格調査3時間")

	var otomo: String = str(by_id.get("SYS-G002", ""))
	assert_true(otomo.contains("ジャック"), "ペット名")
	assert_true(otomo.contains("ペット") or otomo.contains("随伴ペット"), "ペット表記")
	assert_true(otomo.contains("前衛"), "常時前衛")
	assert_true(otomo.contains("招待状"), "招待状対象外に言及")

	var field: String = str(by_id.get("SYS-G003", ""))
	assert_true(field.contains("ギルド情報誌"), "UI名")
	assert_true(field.contains("30"), "30分スロット")
	assert_true(field.contains("穏やか"), "穏やか最頻")
	assert_false(field.contains("図鑑が厚く"), "図鑑×1.5オミット後は案内しない")

	var event_dg: String = str(by_id.get("SYS-G004", ""))
	assert_true(event_dg.contains("裂け目") or event_dg.contains("エルダ"), "ダックDG")
	assert_true(event_dg.contains("巣") or event_dg.contains("レイヴン"), "レイヴンDG")
	assert_true(event_dg.contains("一日"), "日次挑戦")
	assert_true(event_dg.contains("ビッグコズミック") or event_dg.contains("×2"), "曜日報酬／裂け目ボスに言及")

	var wander: String = str(by_id.get("SYS-G005", ""))
	assert_true(wander.contains("ダック"), "放浪ダック")
	assert_true(wander.contains("レイヴン"), "放浪レイヴン")
	assert_true(wander.contains("逃走") or wander.contains("経験"), "ダック特性")
	assert_true(wander.contains("装備") or wander.contains("神話"), "レイヴン特性")
	assert_true(wander.contains("Hard") or wander.contains("ビッグ"), "Hard+昇格に言及")

	var daily: String = str(by_id.get("SYS-G006", ""))
	assert_false(daily.is_empty(), "日課の条がある")
	assert_true(daily.contains("3"), "毎日3件")
	assert_true(daily.contains("5:00") or daily.contains("5：00"), "JST5時リセット")

	var rooms: String = str(by_id.get("SYS-G007", ""))
	assert_false(rooms.is_empty(), "部屋と罠の条がある")
	assert_true(rooms.contains("罠"), "罠に言及")
	assert_true(rooms.contains("罠解除"), "罠解除に言及")
	assert_true(rooms.contains("採取") or rooms.contains("報酬"), "報酬系オミットに言及")
	assert_true(rooms.contains("抽選") or rooms.contains("部屋"), "部屋抽選に言及")
	assert_true(rooms.contains("分かれ道"), "戦闘後分かれ道に言及")

	var formation: String = str(by_id.get("COMBAT-G003", ""))
	assert_true(formation.contains("ジャック"), "陣形にペット関係")
	assert_true(formation.contains("密集"), "密集とジャックの関係")
	assert_true(formation.contains("ペット") or formation.contains("随伴ペット"), "陣形のペット表記")

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
	for entry: Dictionary in GuideCatalog.get_world_entries():
		by_id[str(entry.get("id", ""))] = str(entry.get("description", ""))

	var required: Array[String] = [
		"WORLD-G001", "WORLD-G002", "WORLD-G003", "WORLD-G004", "WORLD-G005",
		"WORLD-G006", "WORLD-G007", "WORLD-G008", "WORLD-G009", "WORLD-G010",
		"WORLD-G011", "WORLD-G012",
		"WORLD-G013", "WORLD-G014", "WORLD-G015", "WORLD-G016", "WORLD-G017",
		"WORLD-G018", "WORLD-G019", "WORLD-G020", "WORLD-G021", "WORLD-G022",
		"WORLD-G023", "WORLD-G024", "WORLD-G025", "WORLD-G026", "WORLD-G027",
		"WORLD-G028",
		"WORLD-G029", "WORLD-G030", "WORLD-G031", "WORLD-G032", "WORLD-G033",
		"WORLD-G034", "WORLD-G035", "WORLD-G036", "WORLD-G037", "WORLD-G038",
		"WORLD-G039", "WORLD-G040", "WORLD-G041", "WORLD-G042", "WORLD-G043",
		"WORLD-G044", "WORLD-G045", "WORLD-G046", "WORLD-G047", "WORLD-G048",
		"WORLD-G049", "WORLD-G050",
	]
	for wid: String in required:
		assert_false(str(by_id.get(wid, "")).is_empty(), "%s がある" % wid)

	var world_count: int = 0
	for wid in by_id.keys():
		if str(wid).begins_with("WORLD-G"):
			world_count += 1
	assert_eq(world_count, 50, "世界観手引きは50件")

	## 手引きタブ側には WORLD を載せない（案B）。
	for entry: Dictionary in GuideCatalog.get_entries():
		assert_false(str(entry.get("id", "")).begins_with("WORLD-G"), "手引きからWORLD除外")

	assert_true(str(by_id.get("WORLD-G002", "")).contains("魔法"), "魔法不在に言及")
	assert_true(str(by_id.get("WORLD-G002", "")).contains("エルダ"), "エルダ定義")
	assert_true(str(by_id.get("WORLD-G003", "")).contains("調査"), "ギルドは調査機関")
	assert_true(str(by_id.get("WORLD-G003", "")).contains("冒険者組合ではない"), "組合否定")
	assert_true(str(by_id.get("WORLD-G008", "")).contains("異界"), "民間俗称に触れつつ否定")
	assert_true(str(by_id.get("WORLD-G011", "")).contains("鉱物化"), "モーンゲート生態")
	assert_true(str(by_id.get("WORLD-G011", "")).contains("吐き門") or str(by_id.get("WORLD-G011", "")).contains("下鍛冶"), "モーンゲート地名")
	assert_true(str(by_id.get("WORLD-G012", "")).contains("共生"), "ウィスパーウッド生態")
	assert_true(str(by_id.get("WORLD-G012", "")).contains("葉隠れ") or str(by_id.get("WORLD-G012", "")).contains("糸網"), "囁きの森地名")
	assert_true(str(by_id.get("WORLD-G013", "")).contains("専門"), "ジョブは専門資格")
	assert_true(str(by_id.get("WORLD-G014", "")).contains("英雄ではない"), "隊長は選ばれし英雄ではない")
	assert_true(str(by_id.get("WORLD-G015", "")).contains("生存"), "動機の三層")
	assert_true(str(by_id.get("WORLD-G016", "")).contains("灯火"), "灯火の信仰")
	assert_true(str(by_id.get("WORLD-G017", "")).contains("魔物"), "魔物呼びを否定")
	assert_true(str(by_id.get("WORLD-G018", "")).contains("探索者の時代"), "六時代")
	assert_true(str(by_id.get("WORLD-G020", "")).contains("辻灯亭"), "在野と辻灯亭")
	assert_true(str(by_id.get("WORLD-G021", "")).contains("ゴールド"), "通貨")
	assert_true(str(by_id.get("WORLD-G022", "")).contains("隊商"), "街道と隊商")
	assert_true(str(by_id.get("WORLD-G023", "")).contains("腐生"), "霧沼生態")
	assert_true(str(by_id.get("WORLD-G023", "")).contains("リブリス"), "リブリス環")
	assert_true(str(by_id.get("WORLD-G024", "")).contains("潮汐"), "ブラックショア生態")
	assert_true(str(by_id.get("WORLD-G024", "")).contains("沈旗"), "沈旗列")
	assert_true(str(by_id.get("WORLD-G025", "")).contains("寒冷"), "フロストリッジ生態")
	assert_true(str(by_id.get("WORLD-G025", "")).contains("エルディオンの針") or str(by_id.get("WORLD-G025", "")).contains("地図なし"), "北境標")
	assert_true(str(by_id.get("WORLD-G026", "")).contains("開拓王"), "九王理念")
	assert_true(str(by_id.get("WORLD-G027", "")).contains("灯断ち"), "崩落前後")
	assert_true(str(by_id.get("WORLD-G027", "")).contains("三説") or str(by_id.get("WORLD-G027", "")).contains("継承"), "盟議の諸説")
	assert_true(str(by_id.get("WORLD-G028", "")).contains("記録"), "断片の読み方")
	assert_true(str(by_id.get("WORLD-G029", "")).contains("ソードマン"), "基本職")
	assert_true(str(by_id.get("WORLD-G029", "")).contains("回収部") or str(by_id.get("WORLD-G029", "")).contains("ソードセイバー"), "職の厚み")
	assert_true(str(by_id.get("WORLD-G033", "")).contains("ビーストテイマー"), "テイマー")
	assert_true(str(by_id.get("WORLD-G034", "")).contains("潮見") or str(by_id.get("WORLD-G034", "")).contains("航海"), "シーゲート厚み")
	assert_true(str(by_id.get("WORLD-G039", "")).contains("調査許可等級"), "等級")
	assert_true(str(by_id.get("WORLD-G039", "")).contains("准探索者") or str(by_id.get("WORLD-G039", "")).contains("討伐数"), "等級の厚み")
	assert_true(str(by_id.get("WORLD-G040", "")).contains("伝説個体"), "伝説個体")
	assert_true(str(by_id.get("WORLD-G046", "")).contains("五部門"), "五部門")
	assert_true(str(by_id.get("WORLD-G047", "")).contains("継承祭") or str(by_id.get("WORLD-G047", "")).contains("暮らし"), "安全圏暮らし厚み")
	assert_true(str(by_id.get("WORLD-G050", "")).contains("到達形"), "到達形")
	assert_true(str(by_id.get("WORLD-G050", "")).contains("対等") or str(by_id.get("WORLD-G050", "")).contains("認定"), "到達形厚み")


func test_mourngate_flavor_matches_postwar_ecology() -> void:
	var dg: Resource = load("res://resources/dungeons/mourngate.tres")
	assert_ne(dg, null)
	var flavor: String = str(dg.get("flavor_text"))
	assert_true(flavor.contains("鉱物化") or flavor.contains("排水"), "正典の地下生態")
	assert_false(flavor.contains("魔法"), "魔法表現を撤去")
	assert_false(flavor.contains("亡霊"), "亡霊表現を撤去")
