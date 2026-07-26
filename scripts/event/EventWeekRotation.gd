class_name EventWeekRotation
extends RefCounted

## 野外速報（P3-EVT-FIELD-001）。30分スロット＋重み付きプール。
## 旧名 EventWeekRotation を維持（呼び出し互換）。週次ローテは廃止。

const _Schedule := preload("res://scripts/event/EventScheduleHelper.gd")
const _EventData := preload("res://scripts/data/EventData.gd")

const ANCHOR_DATE_JST: String = "2026-07-01"
## 30分スロット（全端末同時）。
const SLOT_SECONDS: int = 30 * 60
## 旧テスト互換エイリアス（週秒数は使わない）。
const WEEK_SECONDS: int = SLOT_SECONDS

const MAIN_BIOME_IDS: Array[String] = [
	Constants.MOURNGATE_DUNGEON_ID,
	"whisperwood",
	"mistfen",
	"blackshore",
	"frostridge",
]

## id / weight / modifier_type / modifier_mult / title / banner_desc
## / field_notes（現場メモ）/ article（情報誌本文）/ effect_summary（効果）
## / description（調査部ノノカのメモ＝手書き口調）
## ＋任意: weather_id
const SLOT_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "none",
		"weight": 40,
		"modifier_type": "none",
		"modifier_mult": 1.0,
		"title": "穏やかな野外",
		"banner_desc": "特記なし",
		"field_notes": "・第2班：「異常なし。鳥もいつもどおり」\n・補給局：「追加配分の予定なし」\n・見張り台：「水平線は静穏」",
		"article": "大きな偏りは観測されていない。平時の調査計画で問題ない。",
		"effect_summary": "・特記事項なし",
		"description": "隊長〜、今日は特記なしだよ！平常運転で大丈夫。\n出発前に装備の耐久と回復薬だけサッと見てね。\n無理な強行突破より、確実な周回のほうがギルド評価は安定するって、わたしのおすすめ。\n帰ってきたらお茶でもどう？……仕事の話だけど！",
	},
	{
		"id": "weather_rain",
		"weight": 7,
		"modifier_type": "weather",
		"modifier_mult": 1.0,
		"weather_id": "rain",
		"title": "雨の気配",
		"banner_desc": "天候：雨が続きやすい",
		"field_notes": "・第1班：「靴がすぐ重い。足跡は残る」\n・門番：「入構者のマントが全員びしょ濡れ」\n・気象係：「降雨帯が動かない」",
		"article": "広域で降雨が優勢。靴も装備も濡れやすいが、足跡は読みやすい——との現場報告。",
		"effect_summary": "・探索中の天候が雨に固定されやすい",
		"description": "びしょびしょ警報〜！視界より足元を優先してね。\n石床はすべるし、雨音で気配が紛れやすいから隊列は詰めて、合図は大きめに！\n撤退路の水たまりにも注意。びしょ濡れマントで帰ってきたら、わたしが乾かしてあげる……冗談だよ？\n記録は濡れない袋に入れてね。",
	},
	{
		"id": "weather_night",
		"weight": 7,
		"modifier_type": "weather",
		"modifier_mult": 1.0,
		"weather_id": "night",
		"title": "夜の帳",
		"banner_desc": "天候：夜が続きやすい",
		"field_notes": "・第4班：「昼でも灯りが要る」\n・見張り台：「影の移動が多い」\n・図鑑係：「夜行性の反応が厚い」",
		"article": "日照が弱く、夜寄りの気象が優勢。灯りに寄る個体と、闇に潜む個体の両方が増えている。",
		"effect_summary": "・探索中の天候が夜に固定されやすい",
		"description": "今日は夜より〜。灯りと索敵はセットでお願い！\n先頭だけ先走ると夾撃コースだから、みんな一緒にね。\n不意打ちに備えて、回復枠は普段より多めに残しておくのが賢い隊長さん。\n暗がりで迷子になったら、わたしが地図広げて待ってるから！",
	},
	{
		"id": "weather_fog",
		"weight": 7,
		"modifier_type": "weather",
		"modifier_mult": 1.0,
		"weather_id": "fog",
		"title": "霧の蔓延",
		"banner_desc": "天候：霧が続きやすい",
		"field_notes": "・第3班：「十歩先が見えない」\n・門番：「呼び声が届きにくい」\n・測量係：「距離の感覚が狂う」",
		"article": "視程不良の霧が広がっている。距離感が狂いやすく、隊列を崩さないことが肝要だ。",
		"effect_summary": "・探索中の天候が霧に固定されやすい",
		"description": "もやもや注意報！離れすぎ厳禁だよ〜。\n合流合図と退避地点は、出発前にちゃんと言い合わせてね。\n霧の中では『見えたつもり』が増えるから、確認してから踏み込むこと！\n迷子メモはわたし宛に。できれば迷子にならないで？",
	},
	{
		"id": "wander_duck",
		"weight": 6,
		"modifier_type": "wander_duck",
		"modifier_mult": 4.0,
		"title": "コズミックダック目撃増",
		"banner_desc": "放浪ダック出現率↑",
		"field_notes": "・第3班：「上空に光跡。裂け目ではない」\n・見張り台：「羽ばたきが通常の倍」\n・補給局：「回収袋の予備を増やした」",
		"article": "通常ルートでも、空に浮かぶ異形のダックが相次いで目撃されている。裂け目とは別枠の反応らしく、調査部は出没帯の拡大を警戒している。",
		"effect_summary": "・通常探索での放浪ダック出現率↑",
		"description": "ダック注意！日次裂け目の子とは別カウントだよ。\n通常探索でもコズミックダックが出やすい時間帯みたい。\n見かけたら距離を取りつつ記録して、無理な単独追撃はなし！戦利品より生存報告が優先〜。\nかわいいからって手は出さないでね？……でも写真は撮ってきて！",
	},
	{
		"id": "wander_raven",
		"weight": 6,
		"modifier_type": "wander_raven",
		"modifier_mult": 4.0,
		"title": "宝冠レイヴン目撃増",
		"banner_desc": "放浪レイヴン出現率↑",
		"field_notes": "・第5班：「冠の光が樹間に落ちた」\n・見張り台：「巣の方角以外からも影」\n・鍛冶：「くちばし傷の報告が増」",
		"article": "宝冠を戴くレイヴンの目撃が相次いでいる。巣とは別枠の出没で、探索路の上空にも影が落ちやすい。",
		"effect_summary": "・通常探索での放浪レイヴン出現率↑",
		"description": "冠レイヴン注意報！日次の巣とは別枠だよ。\n通常探索でも上空から来るかも。上を見るのを忘れないでね？\n戦うなら装備の余力と退却路を確保してから！かっこいい冠にうっとりしすぎ注意。\nくちばし傷の報告、増やさないでね〜。",
	},
	{
		"id": "enemy_level",
		"weight": 5,
		"modifier_type": "enemy_level",
		"modifier_mult": 2.0,
		"title": "強敵の波",
		"banner_desc": "敵レベル +2",
		"field_notes": "・第2班：「同じ群れでも一回り大きい」\n・衛生班：「負傷報告が早い」\n・門番：「撤退隊が増えた」",
		"article": "危険度の高い個体の比率が上がっている。いつもの編成でも、一段階強い相手に当たりやすい。",
		"effect_summary": "・敵レベル ＋2",
		"description": "今日の敵、ちょっとムキムキだよ！無理押しは禁物。\n同じ部屋でも消耗が早いから、撤退判断は早めに、回復も前倒しでね。\n『いつも通り』は今日の基準じゃないから、隊長も気合い入れすぎ注意？\n無事に帰ってきたら、わたしが評価メモ書いてあげる！",
	},
	{
		"id": "swarm",
		"weight": 5,
		"modifier_type": "swarm",
		"modifier_mult": 2.5,
		"title": "群れの季節",
		"banner_desc": "敵の群れ出現率↑",
		"field_notes": "・第1班：「単体だと思ったら後続が来た」\n・見張り台：「足跡が束になっている」\n・補給局：「矢の消費が跳ねた」",
		"article": "群れ行動が増えている。単体なら押し切れる相手でも、まとまると消耗が激しい——現場の定評だ。",
		"effect_summary": "・戦闘で複数体遭遇しやすくなる",
		"description": "わらわら警報！範囲技と回復の順番、決め打ちしとこう。\n散開されると詰むから、先頭の引きつけと後衛の一斉処理を意識してね。\n矢の消費が増えがちなので、補給も多めがおすすめ。\n『一匹だけ』は疑ってかかって！わたしは信じてないよ？",
	},
	{
		"id": "elite_rooms",
		"weight": 4,
		"modifier_type": "elite_rooms",
		"modifier_mult": 2.0,
		"title": "エリート目撃増",
		"banner_desc": "エリート部屋出現↑",
		"field_notes": "・第6班：「精鋭の気配が濃い部屋が増」\n・測量係：「反応点がいつもより多い」\n・鍛冶：「良質素材の持ち込み増」",
		"article": "精鋭級の反応が強い。探索ルート上で、いつもよりエリートの気配に遭遇しやすい。",
		"effect_summary": "・エリート部屋の出現率が上がる",
		"description": "精鋭チャンス（とピンチ）！エリートは強敵だけど収穫も大きいよ。\n挑むなら耐久と回復を厚くして、スキップも立派な選択肢！\n連続交戦は事故の元だから、調子に乗らないでね〜。\nいい素材持ち帰れたら、わたしにも見せて？記録用！",
	},
	{
		"id": "exp",
		"weight": 3,
		"modifier_type": "exp",
		"modifier_mult": 1.2,
		"title": "経験記録の微増",
		"banner_desc": "戦闘経験値 ×1.2",
		"field_notes": "・記録係：「同じ戦闘でも記録が厚い」\n・教官：「短時間班の伸びがよい」\n・第2班：「レベルが早い」",
		"article": "戦闘データの取得効率がわずかに上がっている。同じ戦いでも、記録に残る経験が厚い。",
		"effect_summary": "・戦闘経験値 ×1.2",
		"description": "育ちどき警報！短時間周回でも経験値ののりがよいみたい。\nレベルが近い仲間を優先して連れ出すと、枠のムダが減るよ。\n記録係もニヤニヤしてるし……隊長も伸びしろの時間だね！\n帰ったらレベル報告、ワクワク待ちしてる！",
	},
	{
		"id": "gold",
		"weight": 3,
		"modifier_type": "gold",
		"modifier_mult": 1.2,
		"title": "調査報酬の微増",
		"banner_desc": "戦闘ゴールド ×1.2",
		"field_notes": "・補給局：「上乗せ配分を開始」\n・会計：「検収袋が重い」\n・門番：「帰隊時の笑顔が増えた（主観）」",
		"article": "補給局が小規模な追加報酬を配分した。現場回収分に上乗せがある、との通達。",
		"effect_summary": "・戦闘ゴールド ×1.2",
		"description": "小銭タイム！積もると立派なお金になるよ。\nゴールド上乗せ中は検収を丁寧にね。通達はスロット終了で切れるから、先送りしすぎないで！\n門番さんも笑顔が増えたらしいし……隊長の笑顔も期待してる？\nわたしのおやつ代は別会計で！",
	},
	{
		"id": "weapon_drop",
		"weight": 3,
		"modifier_type": "weapon_drop",
		"modifier_mult": 1.2,
		"title": "遺物反応の微増",
		"banner_desc": "武器ドロップ率 ×1.2",
		"field_notes": "・遺物係：「針が振れやすい」\n・第4班：「床に直落ちが増」\n・鍛冶：「持ち込み武器の検品が混む」",
		"article": "遺物反応がやや活発。現場で武器が直に落ちる気配が、平時よりわずかに強い。",
		"effect_summary": "・武器ドロップ率 ×1.2",
		"description": "ガチャ……じゃなくて遺物反応が元気！拾得確認は急いでね。\n所持枠が埋まりやすいから、不要品の解体・売却を先に済ませてから潜ろう。\n床にキラッと光ってたら、忘れずに〜！わたしの記録も増えるし。\nいい武器見つけたら自慢していいよ？",
	},
	{
		"id": "codex",
		"weight": 3,
		"modifier_type": "codex",
		"modifier_mult": 1.5,
		"title": "生態活発のひととき",
		"banner_desc": "図鑑調査 ×1.5",
		"field_notes": "・図鑑係：「未登録の影が多い」\n・第3班：「初めて見る模様」\n・見張り台：「観察向きの天候」",
		"article": "未確認個体の目撃が一時的に増えている。図鑑係からは『記録の好機』との連絡。",
		"effect_summary": "・図鑑調査効率 ×1.5",
		"description": "図鑑の時間だよ！未登録・進捗の浅い個体を優先して記録してね。\n討伐より観察が先、の場面もあるから、焦らないで。\n写真（記録）を残せば、わたしがきれいに整理しておく！\n珍しい模様見つけたら、真っ先に報告して？興奮しちゃうから。",
	},
	{
		"id": "featured_biome",
		"weight": 3,
		"modifier_type": "featured_biome",
		"modifier_mult": 1.2,
		"title": "注目区域調査",
		"banner_desc": "注目区域 経験値/ゴールド ×1.2",
		"field_notes": "・指令：「重点区域を掲示せよ」\n・補給局：「区域限定の上乗せあり」\n・門番：「行きと帰りで行き先を確認」",
		"article": "ギルドが重点調査区域を指定。該当区域では記録・補給の効率がわずかに上がる。",
		"effect_summary": "・注目区域の経験値／ゴールド ×1.2",
		"description": "注目区域チェック必須！表示を見落とさないでね。\n区域外だとボーナスが乗らないよ〜。経験値もゴールドも欲しいなら、指定区域の周回がおすすめ。\n行き先、門番さんにもちゃんと伝えて？迷子隊長は記録に残すから！\n……残したら怒る？ふふ、残さないよ。たぶん。",
	},
	{
		"id": "elite_material",
		"weight": 3,
		"modifier_type": "elite_material",
		"modifier_mult": 1.2,
		"title": "高品質素材のひととき",
		"banner_desc": "エリート素材 ×1.2",
		"field_notes": "・鍛冶：「良品の持ち込みが続く」\n・第6班：「精鋭落ちが厚い」\n・倉庫：「仕分けが追いつかない」",
		"article": "エリート級からの素材採取が一時的に好調。精錬・鍛冶向けの良品が集まりやすい。",
		"effect_summary": "・エリート素材入手量 ×1.2",
		"description": "素材どき〜！鍛冶の在庫とレシピを見てから周回してね。\nエリート素材が余っても、必要枠が分からないと持ち帰りが雑になるよ。\n解体前に要件をメモ！わたしも一緒にリスト作ってあげる。\n倉庫がパンクする前に、仕分けお願いね？隊長！",
	},
]


static func absolute_slot_index(now_unix: int) -> int:
	var anchor: int = _Schedule.jst_day_start_unix(ANCHOR_DATE_JST)
	if now_unix < anchor:
		return 0
	return int((now_unix - anchor) / SLOT_SECONDS)


## 旧 API 互換。
static func absolute_week_index(now_unix: int) -> int:
	return absolute_slot_index(now_unix)


static func total_weight() -> int:
	var total: int = 0
	for def: Dictionary in SLOT_DEFINITIONS:
		total += maxi(0, int(def.get("weight", 0)))
	return maxi(1, total)


static func definition_index_for_slot(slot_index: int) -> int:
	var total: int = total_weight()
	var roll: int = _stable_roll(slot_index, total)
	var acc: int = 0
	for i: int in SLOT_DEFINITIONS.size():
		acc += maxi(0, int(SLOT_DEFINITIONS[i].get("weight", 0)))
		if roll < acc:
			return i
	return SLOT_DEFINITIONS.size() - 1


static func week_in_cycle(now_unix: int) -> int:
	## 旧テスト互換: スロット種別インデックス。
	return definition_index_for_slot(absolute_slot_index(now_unix))


static func featured_biome_id(now_unix: int) -> String:
	if MAIN_BIOME_IDS.is_empty():
		return ""
	var slot: int = absolute_slot_index(now_unix)
	return MAIN_BIOME_IDS[slot % MAIN_BIOME_IDS.size()]


static func build_active_event(now_unix: int) -> Resource:
	var slot: int = absolute_slot_index(now_unix)
	var def_idx: int = definition_index_for_slot(slot)
	var def: Dictionary = SLOT_DEFINITIONS[def_idx]
	var event: Resource = _EventData.new()
	event.id = "field_slot_%s_%d" % [str(def.get("id", def_idx)), slot]
	event.title = str(def.get("title", ""))
	event.tag_text = EventSystem.DISPLAY_NAME
	event.banner_desc = str(def.get("banner_desc", ""))
	event.description = str(def.get("description", ""))
	if "article" in event:
		event.article = str(def.get("article", ""))
	if "field_notes" in event:
		event.field_notes = str(def.get("field_notes", ""))
	if "effect_summary" in event:
		event.effect_summary = str(def.get("effect_summary", ""))
	event.modifier_type = str(def.get("modifier_type", ""))
	event.modifier_mult = float(def.get("modifier_mult", 1.0))
	var weather_id: String = str(def.get("weather_id", ""))
	if "weather_id" in event:
		event.weather_id = weather_id
	var start_unix: int = _Schedule.jst_day_start_unix(ANCHOR_DATE_JST) + slot * SLOT_SECONDS
	var end_unix: int = start_unix + SLOT_SECONDS
	event.start_date_jst = _unix_to_jst_datetime(start_unix)
	event.end_date_jst = _unix_to_jst_datetime(end_unix)
	if str(event.modifier_type) == "featured_biome":
		event.featured_biome_id = featured_biome_id(now_unix)
		var biome: Resource = DataRegistry.get_dungeon_data(event.featured_biome_id)
		if biome != null and not str(biome.display_name).is_empty():
			var biome_name: String = str(biome.display_name)
			event.title = "注目区域 — %s" % biome_name
			event.banner_desc = "%s で 経験値/ゴールド ×%.1f" % [
				biome_name,
				event.modifier_mult,
			]
			if "article" in event:
				event.article = "ギルドが重点調査区域として『%s』を指定。該当区域では記録・補給の効率がわずかに上がる。" % biome_name
			if "field_notes" in event:
				event.field_notes = "・指令：「重点区域は %s」\n・補給局：「区域限定の上乗せあり」\n・門番：「行き先を掲示と照合」" % biome_name
			if "effect_summary" in event:
				event.effect_summary = "・%s の経験値／ゴールド ×%.1f" % [biome_name, event.modifier_mult]
			event.description = (
				"注目区域『%s』チェック必須！表示を見落とさないでね。\n"
				+ "区域外だとボーナスが乗らないよ〜。経験値もゴールドも欲しいなら、指定区域の周回がおすすめ。\n"
				+ "行き先、門番さんにもちゃんと伝えて？迷子隊長は記録に残すから！\n"
				+ "……残したら怒る？ふふ、残さないよ。たぶん。"
			) % biome_name
	return event


static func seconds_until_slot_end(now_unix: int) -> int:
	var slot: int = absolute_slot_index(now_unix)
	var end_unix: int = _Schedule.jst_day_start_unix(ANCHOR_DATE_JST) + (slot + 1) * SLOT_SECONDS
	return maxi(0, end_unix - now_unix)


static func seconds_until_week_end(now_unix: int) -> int:
	return seconds_until_slot_end(now_unix)


static func featured_biome_display_name(now_unix: int) -> String:
	var biome_id: String = featured_biome_id(now_unix)
	if biome_id.is_empty():
		return ""
	var data: Resource = DataRegistry.get_dungeon_data(biome_id)
	if data == null:
		return biome_id
	return str(data.display_name)


static func _stable_roll(slot_index: int, modulo: int) -> int:
	if modulo <= 0:
		return 0
	## 決定的・端末間一致（hash はセッション非依存の文字列ハッシュ）。
	var h: int = int(hash("crownfall_field_slot_%d" % slot_index))
	return absi(h) % modulo


static func _unix_to_jst_datetime(unix: int) -> String:
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(unix + _Schedule.JST_OFFSET_SEC)
	return "%04d-%02d-%02d %02d:%02d" % [
		int(dict.year),
		int(dict.month),
		int(dict.day),
		int(dict.hour),
		int(dict.minute),
	]


static func _unix_to_jst_date(unix: int) -> String:
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(unix + _Schedule.JST_OFFSET_SEC)
	return "%04d-%02d-%02d" % [int(dict.year), int(dict.month), int(dict.day)]
