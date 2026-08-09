class_name ChapterClearNinaLines
extends RefCounted

## 章クリア後のニーナ功績／加入予告文案（Biome 別）。


static func merit_lines(stage_display_name: String) -> Array[String]:
	## 後方互換。Biome 不明時は汎用。
	return merit_lines_for_stage("", stage_display_name)


static func merit_lines_for_stage(stage_id: String, override_display_name: String = "") -> Array[String]:
	var biome_id: String = _biome_id_from_stage(stage_id)
	var stage_name: String = override_display_name.strip_edges()
	if stage_name.is_empty():
		stage_name = stage_display_name(stage_id)
	if stage_name.is_empty():
		stage_name = "この調査"
	match biome_id:
		"mourngate":
			return [
				"隊長、王都地下モーンゲートの記録、一通り閉じました。地下の層まで踏み込んだ報告、重いですよ。",
				"この功績、ギルドにも共有します。王都の下を踏破した隊は、そう多くありませんから。",
			]
		"whisperwood":
			return [
				"隊長、囁きの森ウィスパーウッドの記録、ちゃんと残しました。森の声に飲まれず戻ってこられて、よかったです。",
				"この功績、ギルドにも共有しますね。緑の奥まで手が届いた報告は、図鑑の欄外が賑わいます。",
			]
		"mistfen":
			return [
				"隊長、霧沼ミストフェンの記録、締めました。視界の悪い沼を押し切った調査、記録部としても胸を張ります。",
				"この功績、ギルドにも共有します。霧の向こうで何を見たのか——続きは図鑑と現地で、ですね。",
			]
		"blackshore":
			return [
				"隊長、沈没航路ブラックショアの記録、残しました。潮と残骸のあいだを抜けた報告、手に汗握りました。",
				"この功績、ギルドにも共有しますね。外洋寄りの航路を開いた隊として、評議会も黙ってはいられません。",
			]
		"frostridge":
			return [
				"隊長、最果て氷裂フロストリッジ——ノーマル難易度の踏破、記録に残しました。始祖の竜まで届いた調査、本当によくやりましたね。",
				"この功績、ギルドにも共有します。あわせて——ハード難易度が解禁されました。氷の裂け目は、まだ続きがありますよ。",
			]
		_:
			return [
				"隊長、%s の記録、ちゃんと残しました！よくやりましたね。" % stage_name,
				"この功績、ギルドにも共有しておきますね。",
			]


static func recruit_teaser_lines() -> Array[String]:
	return recruit_teaser_lines_for_stage("")


static func recruit_teaser_lines_for_stage(stage_id: String) -> Array[String]:
	var biome_id: String = _biome_id_from_stage(stage_id)
	match biome_id:
		"mourngate":
			return [
				"モーンゲートの報告が届いてから、地下調査に手を貸したい探索者が訪ねてきました。",
				"指揮官の隊に入りたいそうです。よろしければ、これからご紹介しますね。",
			]
		"whisperwood":
			return [
				"ウィスパーウッドの踏破が噂になって、森の偵察を買って出たい探索者が来ています。",
				"指揮官の調査隊に加入したいそうです。よろしければ、ご紹介しますね。",
			]
		"mistfen":
			return [
				"ミストフェンの記録を読んで、霧の調査を支えたい探索者が申し出ました。",
				"指揮官の隊へ合流したいそうです。よろしければ、これからご紹介しますね。",
			]
		"blackshore":
			return [
				"ブラックショアの航路報告を聞いて、海寄りの危険地帯を担いたい探索者が来ています。",
				"指揮官の調査隊に加入したいそうです。よろしければ、ご紹介しますね。",
			]
		"frostridge":
			return [
				"フロストリッジまでの本線踏破を聞いて、極冠の調査に同行したい探索者が現れました。",
				"指揮官の隊に入りたいそうです。よろしければ、これからご紹介しますね。",
			]
		_:
			return [
				"指揮官の調査隊に加入したい探索者がいるみたいですよ！",
				"よろしければ、これからご紹介しますね。",
			]


## ミストフェン初回クリア後・初期キャラ加入に続くノノカ調査室合流（P3-SURVEY-NONOKA-JOIN-001）。
## NinaDialogueOverlay 向け。speaker 付き Dictionary（nina / nonoka）。
static func nonoka_survey_join_lines() -> Array:
	return [
		{
			"speaker": "nina",
			"text": "隊長、ミストフェンの報告を受けて——記録庁から、もう一人調査室に入ってもらうことになりました。",
		},
		{
			"speaker": "nina",
			"text": "研究員のノノカです。考古担当で、机より現場の資料あさりが得意な子です。",
		},
		{
			"speaker": "nonoka",
			"text": "はーい！ノノカですっ。遺跡のホコリより仮説のほうが好き……たぶんね？ これから調査、よろしくっ！",
		},
		{
			"speaker": "nina",
			"text": "これからは調査室で、ノノカも一緒に配置できます。よろしくお願いしますね。",
		},
	]


static func stage_display_name(stage_id: String) -> String:
	if stage_id.is_empty():
		return ""
	var stage: Resource = DataRegistry.get_stage_data(stage_id)
	if stage != null and "display_name" in stage and not str(stage.display_name).is_empty():
		return str(stage.display_name)
	return stage_id


static func _biome_id_from_stage(stage_id: String) -> String:
	if stage_id.is_empty():
		return ""
	var stage: Resource = DataRegistry.get_stage_data(stage_id)
	if stage != null and "biome_id" in stage:
		return str(stage.biome_id).strip_edges()
	return ""
