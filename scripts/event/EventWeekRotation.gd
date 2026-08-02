class_name EventWeekRotation
extends RefCounted

## 野外速報（P3-EVT-FIELD-001）。30分スロット＋重み付きプール。
## 旧名 EventWeekRotation を維持（呼び出し互換）。週次ローテは廃止。
## ノノカメモ（description）は種別ごと複数文面をスロット番号で決定的に選ぶ（P3-EVT-NONOKA-MEMO-001）。

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

## 注目区域用テンプレ（%s = Biome 表示名）。
const FEATURED_BIOME_DESCRIPTIONS: Array[String] = [
	"注目区域『%s』チェック必須！表示を見落とさないでね。\n区域外だとボーナスが乗らないよ〜。経験値もゴールドも欲しいなら、指定区域の周回がおすすめ。\n行き先、門番さんにもちゃんと伝えて？迷子隊長は記録に残すから！\n……残したら怒る？ふふ、残さないよ。たぶん。",
	"重点調査は『%s』だよ！掲示と行き先が一致してるか、出発前に指差し確認〜。\n区域外だと上乗せなし。回りたさだけで迷子にならないでね？\n門番さんにも『%s』って言えるようにしとこう。\nわたしは記録係席で待ってる！たぶんね？",
	"ギルド注目『%s』！今日のボーナス区域はここ。\n経験値もゴールドも、枠内だけ乗せるルールだよ。見落とし厳禁！\n帰りに『行った区域』を報告してね。照合が楽になるから。\nいい調査日誌、期待してる隊長！",
	"『%s』が重点区域〜。派手な変化じゃないけど、効率はここで差がつくよ。\n区域外周回は平常運転扱い。欲張りたいなら掲示どおりに！\n迷子メモはわたし宛……できれば書かせないで？\nたぶん、ちゃんと行けるよね？",
]

## id / weight / modifier_type / modifier_mult / title / banner_desc
## / field_notes（現場メモ）/ article（情報誌本文）/ effect_summary（効果）
## / descriptions（調査部ノノカのメモ＝手書き口調・複数。スロット決定的抽選）
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
		"descriptions": [
			"隊長〜、今日は特記なしだよ！平常運転で大丈夫。\n出発前に装備の耐久と回復薬だけサッと見てね。\n無理な強行突破より、確実な周回のほうがギルド評価は安定するって、わたしのおすすめ。\n帰ってきたらお茶でもどう？……仕事の話だけど！",
			"異常なし報告、山盛り〜。今日は『何も起きない』をちゃんと記録する日だよ。\n地味だけど大事！装備のネジだけ締めて出発してね。\n派手なネタがなくて情報誌が薄く見えるかも……でもデータは嘘つかない。たぶんね？\n無事報告、待ってる！",
			"特記なし……でも『なし』も仮説の材料だよ？たぶんね。\n平常運転で、無理な強行はわたしが記録に残すから！\n見張り台も『水平線は静穏』だって。鳥もいつもどおりらしい。\nこういう日ほど、靴紐と回復薬を見直す隊長が好き。",
			"穏やか警報（？）発令中。派手な出来事はないみたい。\n確実な周回がギルド評価に効くって、わたしのおすすめ！\n補給局も追加配分なし＝自前の準備が本番だよ。\n持ち物リスト、一緒に指差し確認しよ？",
			"変化なしの時間帯だよ。ネタがなくて情報誌が薄い……から、隊長の無事報告でページ埋めて？\n冗談。でも待ってる。\n静かな野外って、実は観察向き。いつも通りの生態をメモる価値あるよ？\n帰ったら見せて！",
			"今日は偏り観測ゼロ。記録係は書きやすい顔してる。\n隊長は平常心で、わたしは平常テンションで見守るね。\n『何もない』って報告、実は一番信用されるんだよ。\n嘘つかないデータ。……たぶんね？出発よし！",
			"特記なし日は、無理せず定番ルートで十分！\nニーナさんも案内が書きやすいって言ってたよ。\n隊長のおすすめ、今日は安定運用でいこう。\nわたしは仮説ノートの余白を眺めながら待ってる。",
			"穏やかすぎて眠くなる班がいるらしい。\nわたしはコーヒー（仮説）で起きてるから、隊長は転ばないでね。\n変化なし継続中——だからって手抜きはなし！\n平常運転の丁寧さが、あとで効いてくるタイプ。わたしもメモ丁寧にする。",
			"現場メモまとめ：『異常なし』『追加配分なし』『静穏』。\nつまり今日のキーワードは平常運転〜。\n強行突破より、確実な周回。それがわたしのおすすめ。\nお茶は仕事の話付きでね？",
			"特記事項、本当にゼロだよ。逆に珍しい？……ううん、よくある。\nよくある日を丁寧にこなすのが、調査部の基本！\n装備チェックだけサッと。あとは隊長の判断に任せるね。\n迷子にだけはならないで？メモ増えるから。",
			"変化なし——でも空気はいつもどおり美味しいっぽい（主観）。\n観測偏りなしなので、今日は育成・整備・短周回の日に向いてるよ。\n派手な獲物がなくても、ギルド評価は積み上がる！\n帰ってきたらレベル報告、ワクワク待ちしてる……平常運転版で。",
			"『穏やかな野外』継続中。情報誌の定番枠だよ。\n定番だからって、読まないで捨てないでね？念のため書いてあるんだから！\n出発前の耐久と回復薬、いつもの確認でOK。\nわたしは机で仮説を並べて待つ。……たぶん役に立つやつ。",
			"異常なしの連続って、記録係は嬉しいんだよ。欄が真っ白で済むし。\n隊長は真っ白じゃなくて、ちゃんと帰ってきてね？\n今日の野外は特記なし。平常運転、いってらっしゃい！\nお土産の話は、無事が先。そのあとで。",
			"偏りなし・補正なし・追加なし。三拍子そろった静かな時間帯。\nこういうときほど、足元の石につまずかないで？\nわたしのおすすめは確実周回。強行はまた偏りが出てから！\nデータは嘘つかない。……たぶんね？",
			"特記なしだよ隊長。今日は『何もしない勇気』じゃなくて『いつも通りの勇気』！\n看板に騙されないで、ちゃんと装備見てから出てね。\n門番さんも暇そう……主観だけど。\n暇な門番の前を、元気に通ってきて！",
			"穏やか枠、またきた。重量級の変化はないみたい。\nだからこそ、短時間でも記録を厚くできる日だよ。\n未完了の図鑑や、気になってた装備整備、今日向き！\nわたしは余白に星つけて待ってる。仕事の星ね？",
		],
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
		"descriptions": [
			"びしょびしょ警報〜！視界より足元を優先してね。\n石床はすべるし、雨音で気配が紛れやすいから隊列は詰めて、合図は大きめに！\n撤退路の水たまりにも注意。びしょ濡れマントで帰ってきたら、わたしが乾かしてあげる……冗談だよ？\n記録は濡れない袋に入れてね。",
			"雨優勢だよ隊長。靴が重い日は、歩幅を短くが基本！\n足跡は残るから追跡向き……でも自分が滑ったら元も子もないよ？\nマントが濡れても、中のメモは乾いたままがルール。\n帰ったら湯気と一緒に報告して？",
			"降雨帯が動かないって、気象係が言ってた。長引きそう。\n隊列詰めて、合図は大きめ。雨音に負けないでね！\n水たまり＝落とし穴扱い（仮）。たぶんね？\nびしょ濡れでも、笑顔の報告歓迎！",
			"雨の気配、濃いよ。装備の防湿、出発前チェック！\n濡れても戦える隊長が好き……でも風邪はダメ。\n記録袋は二重推奨。わたしの仮説ノートも雨嫌いだから。\n気をつけていってらっしゃい！",
		],
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
		"descriptions": [
			"今日は夜より〜。灯りと索敵はセットでお願い！\n先頭だけ先走ると夾撃コースだから、みんな一緒にね。\n不意打ちに備えて、回復枠は普段より多めに残しておくのが賢い隊長さん。\n暗がりで迷子になったら、わたしが地図広げて待ってるから！",
			"夜寄りの気象だよ。昼でも灯り持って！\n影の移動が多いって見張り台が言ってた。油断しないでね。\n夜行性の観察チャンスでもある……戦闘優先は忘れずに？\n暗所迷子メモ、増やさないで〜。",
			"帳が降りる時間帯。隊列は密着気味が安全！\n灯りに寄る子と、闇に潜む子、両方いるみたい。\n回復枠は多め。『見えたつもり』で踏み込まないでね。\nわたしは明るい机で待ってる。たぶんね？",
			"夜より注意報！索敵係を休ませないで。\n先頭だけ先行は夾撃コース——何度でも書くよ。\n無事に灯りの下へ帰ってきて。\n暗がりエピソードは、あとで聞かせて？記録用！",
		],
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
		"descriptions": [
			"もやもや注意報！離れすぎ厳禁だよ〜。\n合流合図と退避地点は、出発前にちゃんと言い合わせてね。\n霧の中では『見えたつもり』が増えるから、確認してから踏み込むこと！\n迷子メモはわたし宛に。できれば迷子にならないで？",
			"霧優勢。十歩先が見えない日は、声と手信号が相棒！\n距離感が狂うって測量係も困ってた。歩測あてにしないでね。\n隊列崩したら即合流。単独行動は禁止寄りのお願い。\nもやの向こうで待ってる……机の上でね。",
			"視程不良アラート。呼び声が届きにくいみたい。\nだから合図は大きめ・短め・繰り返し！\n『見えたつもり』で突っ込まない隊長が、わたしの推し。\n霧が晴れたら、ちゃんと顔見せて？",
			"霧の蔓延中〜。地図より足元、足元より仲間の位置！\n退避地点、出発前に決めてある？決めてないなら今！\n迷子メモは書きたくない派のわたしです。たぶんね？\n気をつけていってらっしゃい。",
		],
	},
	{
		"id": "weather_heat",
		"weight": 7,
		"modifier_type": "weather",
		"modifier_mult": 1.0,
		"weather_id": "heat",
		"title": "炎天の気配",
		"banner_desc": "天候：炎天が続きやすい",
		"field_notes": "・第1班：「影が短い。石が熱い」\n・門番：「入構者のマントが乾き切ってる」\n・気象係：「高温帯が動かない」",
		"article": "広域で高温が優勢。炎は通りやすく、氷は通りにくい——との現場報告。",
		"effect_summary": "・探索中の天候が炎天に固定されやすい",
		"descriptions": [
			"炎天警報〜！暑さで判断が鈍りやすい日だよ。\n炎属性は通しやすい反面、氷は控えめ。編成、意識してね！\n水分…じゃなくて回復枠、切らさないで。熱中症じゃなくて全滅予防！\n帰ったら涼しい報告、待ってる。",
			"日差しが強い日だよ隊長。石床が熱いって第1班が言ってた。\n炎寄せが活きやすい時間帯。氷武器は少し不利かも？\n無理な長時間探索は控えめに。ペース配分だいじ！\nわたしは日陰の机で待ってる。たぶんね？",
			"高温帯が動かないって気象係。長引きそう。\nマントが乾き切る日は、装備の過熱…主観だけど気をつけて。\n炎の日は記録も熱くなりがち。冷静にね？\nいってらっしゃい！日陰ルート推奨（仮）。",
			"炎天の気配、濃いよ。氷属性は少し通りにくい日！\n暑さで隊列が崩れたら即合流。単独はダメ絶対。\n炎ビルドの試し撃ち日、でも無理はなし。\n熱い報告、歓迎。やけど報告は減点……心配してるの。",
		],
	},
	{
		"id": "weather_snow",
		"weight": 7,
		"modifier_type": "weather",
		"modifier_mult": 1.0,
		"weather_id": "snow",
		"title": "吹雪の気配",
		"banner_desc": "天候：吹雪が続きやすい",
		"field_notes": "・第4班：「白くて足元が見えない」\n・見張り台：「風向きが読めない」\n・測量係：「距離の感覚が狂う」",
		"article": "吹雪が優勢。氷は通りやすく、炎は通りにくい。視界と体温管理が肝要だ。",
		"effect_summary": "・探索中の天候が吹雪に固定されやすい",
		"descriptions": [
			"吹雪注意報〜！白闇で距離感が狂うよ。\n氷属性は通しやすい反面、炎は控えめ。編成チェック！\n足元と隊列、いつもより詰めて。合図は大きめにね。\n凍えた報告より、無事の報告が優先〜。",
			"吹雪優勢だよ隊長。白くて足元が見えない日は歩幅短く！\n氷寄せが活きやすい時間帯。炎武器は少し不利かも？\n風向きが読めないって見張り台。無理な深追いはなし！\n湯気の立つ報告、待ってる。",
			"吹雪帯が動かないみたい。長引きそう。\n測量係も距離感狂うって困ってた。歩測あてにしないでね。\n隊列崩したら即合流。単独行動は禁止寄りのお願い。\n白い向こうで待ってる……机の上でね。",
			"吹雪の気配、濃いよ。炎属性は少し通りにくい日！\n体温…いえ回復枠、切らさないで。凍結全滅予防！\n氷ビルドの試し撃ち日、でも無理はなし。\n気をつけていってらっしゃい。たぶんね？",
		],
	},
	{
		"id": "wander_duck",
		"weight": 6,
		"modifier_type": "wander_duck",
		"modifier_mult": 4.0,
		"title": "コズミックダック目撃増",
		"banner_desc": "通常路でもコズミックダックの影が増える",
		"field_notes": "・第3班：「上空に光跡。裂け目ではない」\n・見張り台：「羽ばたきが通常の倍」\n・補給局：「回収袋の予備を増やした」",
		"article": "通常ルートでも、空に浮かぶ異形のダックが相次いで目撃されている。裂け目とは別枠の反応らしく、調査部は出没帯の拡大を警戒している。",
		"effect_summary": "・通常探索での放浪ダック出現率↑",
		"descriptions": [
			"ダック注意！日次裂け目の子とは別カウントだよ。\n通常探索でもコズミックダックが出やすい時間帯みたい。\n見かけたら距離を取りつつ記録して、無理な単独追撃はなし！戦利品より生存報告が優先〜。\nかわいいからって手は出さないでね？……でも写真は撮ってきて！",
			"放浪ダック目撃増！上空の光跡、裂け目じゃないらしい。\n羽ばたきが倍って見張り台が騒いでた。上を見て！\n追うなら余力と退却路を確保してから。単独はダメ絶対。\nかわいい報告、歓迎。怪我の報告は減点……冗談、心配してるの。",
			"コズミックダック注意報。回収袋の予備、補給局が増やしたよ。\nつまり『出るかも』判定。期待しすぎて油断しないでね？\n距離取って記録。戦利品より生存！\n写真（記録）はわたし宛で。興奮しちゃうから。",
			"ダック出没帯、拡大気味かも。たぶんね？\n日次イベントとは別枠——数え間違えないで。\n無理追撃禁止。隊長の無事が最優先データ！\nかわいい羽、見たら教えて？仮説の材料にする。",
		],
	},
	{
		"id": "wander_raven",
		"weight": 6,
		"modifier_type": "wander_raven",
		"modifier_mult": 4.0,
		"title": "宝冠レイヴン目撃増",
		"banner_desc": "宝冠レイヴンの影が探索路に落ちやすい",
		"field_notes": "・第5班：「冠の光が樹間に落ちた」\n・見張り台：「巣の方角以外からも影」\n・鍛冶：「くちばし傷の報告が増」",
		"article": "宝冠を戴くレイヴンの目撃が相次いでいる。巣とは別枠の出没で、探索路の上空にも影が落ちやすい。",
		"effect_summary": "・通常探索での放浪レイヴン出現率↑",
		"descriptions": [
			"冠レイヴン注意報！日次の巣とは別枠だよ。\n通常探索でも上空から来るかも。上を見るのを忘れないでね？\n戦うなら装備の余力と退却路を確保してから！かっこいい冠にうっとりしすぎ注意。\nくちばし傷の報告、増やさないでね〜。",
			"宝冠レイヴン目撃増。樹間に冠の光、って第5班が言ってた。\n巣以外からも影が落ちるらしい。空チェック習慣を！\nうっとりしすぎて被弾しないで。記録は無傷優先。\nかっこいい話は、帰ってから聞かせて？",
			"放浪レイヴン注意。鍛冶さんところ、くちばし傷の修理が増えてるよ。\nつまり当たってる人がいる……隊長は増やす側に回らないで！\n余力あるときだけ挑んで。撤退も立派な判断。\n冠のスケッチ、できたらわたしにも見せて？",
			"レイヴン出没気味。日次の巣イベントとは別カウントだよ〜。\n上空の影を見たら、まず隊列整えてからね。\n戦利品より生存報告。わたしの推し方針！\nたぶん、冠より隊長のほうが大事。たぶんね？",
		],
	},
	{
		"id": "enemy_level",
		"weight": 5,
		"modifier_type": "enemy_level",
		"modifier_mult": 2.0,
		"title": "強敵の波",
		"banner_desc": "一回り強い相手に当たりやすい",
		"field_notes": "・第2班：「同じ群れでも一回り大きい」\n・衛生班：「負傷報告が早い」\n・門番：「撤退隊が増えた」",
		"article": "危険度の高い個体の比率が上がっている。いつもの編成でも、一段階強い相手に当たりやすい。",
		"effect_summary": "・敵レベル ＋2",
		"descriptions": [
			"今日の敵、ちょっとムキムキだよ！無理押しは禁物。\n同じ部屋でも消耗が早いから、撤退判断は早めに、回復も前倒しでね。\n『いつも通り』は今日の基準じゃないから、隊長も気合い入れすぎ注意？\n無事に帰ってきたら、わたしが評価メモ書いてあげる！",
			"強敵の波きた。同じ群れでも一回り大きいらしい。\n負傷報告が早いって衛生班も言ってた。回復前倒し！\n撤退隊が増えてる＝賢い判断が増えてる、とも読めるよ。\n無理しない隊長が、わたしの推し。",
			"敵Lv寄り注意報。編成そのままでもキツく感じるかも。\n消耗早い日は、深追いより確実回収！\n気合いだけで押さないでね？データは撤退も評価する。……たぶんね？\n無事報告、最優先で待ってる。",
			"ムキムキ時間帯。門番さんの前、撤退隊が増えてるよ。\n恥ずかしいことじゃないから！生きて帰るのが調査。\n回復枠多め、判断早め。それで十分かっこいい。\n帰ったらお疲れメモ、厚めに書くね。",
		],
	},
	{
		"id": "swarm",
		"weight": 5,
		"modifier_type": "swarm",
		"modifier_mult": 2.5,
		"title": "群れの季節",
		"banner_desc": "まとまって現れやすい",
		"field_notes": "・第1班：「単体だと思ったら後続が来た」\n・見張り台：「足跡が束になっている」\n・補給局：「矢の消費が跳ねた」",
		"article": "群れ行動が増えている。単体なら押し切れる相手でも、まとまると消耗が激しい——現場の定評だ。",
		"effect_summary": "・戦闘で複数体遭遇しやすくなる",
		"descriptions": [
			"わらわら警報！範囲技と回復の順番、決め打ちしとこう。\n散開されると詰むから、先頭の引きつけと後衛の一斉処理を意識してね。\n矢の消費が増えがちなので、補給も多めがおすすめ。\n『一匹だけ』は疑ってかかって！わたしは信じてないよ？",
			"群れの季節だよ。足跡が束、って見張り台が言ってた。\n単体だと思ったら後続——定番の罠！疑ってかかって。\n矢の消費跳ねる日は、補給多めが正義。\nわらわらされても、隊列は崩さないでね。",
			"複数体遭遇しやすい時間帯。範囲と回復の順番、決めた？\n決めてないなら今決めて！机でもできる準備だよ。\n散開対応が鍵。先頭の引きつけ、頼んだ。\n『一匹だけ』は都市伝説扱い（今日限定）。",
			"わらわら注意。まとまると消耗が激しい、が現場の定評！\n押し切れる相手でも、数で負ける日があるよ。\n補給・回復・退却路、三点セットで出発してね。\n無事なら、群れの話たくさん聞かせて？記録増える！",
		],
	},
	{
		"id": "elite_rooms",
		"weight": 4,
		"modifier_type": "elite_rooms",
		"modifier_mult": 2.0,
		"title": "エリート目撃増",
		"banner_desc": "精鋭の気配が濃い区画が増える",
		"field_notes": "・第6班：「精鋭の気配が濃い部屋が増」\n・測量係：「反応点がいつもより多い」\n・鍛冶：「良質素材の持ち込み増」",
		"article": "精鋭級の反応が強い。探索ルート上で、いつもよりエリートの気配に遭遇しやすい。",
		"effect_summary": "・エリート部屋の出現率が上がる",
		"descriptions": [
			"精鋭チャンス（とピンチ）！エリートは強敵だけど収穫も大きいよ。\n挑むなら耐久と回復を厚くして、スキップも立派な選択肢！\n連続交戦は事故の元だから、調子に乗らないでね〜。\nいい素材持ち帰れたら、わたしにも見せて？記録用！",
			"エリート目撃増！反応点がいつもより多いらしい。\n挑む／スキップ、両方正解。隊長の余力で決めてね。\n連続は事故の元——調子に乗った報告、増やさないで？\n良質素材、鍛冶さんもニヤニヤ待ち。",
			"精鋭の気配が濃い時間帯。収穫もピンチもセットだよ。\n耐久と回復、厚め推奨！薄い編成での連続は禁止寄り。\nスキップして無事、も立派な調査成果。\nたぶんね？わたしは無事派。",
			"エリート部屋出やすめ。いい素材の持ち込み増、って鍛冶談。\nだからって全部挑まなくていいよ？選んでいい。\n調子に乗った隊長の評価メモは……心配多めになる。\n素材見せてくれるなら、星つけて整理する！",
		],
	},
	{
		"id": "exp",
		"weight": 3,
		"modifier_type": "exp",
		"modifier_mult": 1.2,
		"title": "経験記録の微増",
		"banner_desc": "戦いの記録が厚く残りやすい",
		"field_notes": "・記録係：「同じ戦闘でも記録が厚い」\n・教官：「短時間班の伸びがよい」\n・第2班：「レベルが早い」",
		"article": "戦闘データの取得効率がわずかに上がっている。同じ戦いでも、記録に残る経験が厚い。",
		"effect_summary": "・戦闘経験値 ×1.2",
		"descriptions": [
			"育ちどき警報！短時間周回でも経験値ののりがよいみたい。\nレベルが近い仲間を優先して連れ出すと、枠のムダが減るよ。\n記録係もニヤニヤしてるし……隊長も伸びしろの時間だね！\n帰ったらレベル報告、ワクワク待ちしてる！",
			"経験記録が厚い時間帯だよ。同じ戦闘でも伸びやすい！\n短時間班向け——教官もご機嫌らしい。\n近いレベルの仲間を優先してね。枠のムダ、もったいない。\nレベル報告、星付きで待ってる。",
			"育ちどき〜。無理な深追いより、安全な周回で積む日！\n経験値微増は、継続が勝つタイプ。\n記録係ニヤニヤ＝本当に厚い証拠。……たぶんね？\n伸びしろ、見せて？",
			"経験値×寄り注意報（良いほう）！育成枠の入れ替えどき。\n置いてけぼりの仲間がいたら、今日連れ出すのがおすすめ。\n派手な戦利品より、数字の積み上げ。\nわたしも成長曲線、楽しみにしてる！",
		],
	},
	{
		"id": "gold",
		"weight": 3,
		"modifier_type": "gold",
		"modifier_mult": 1.2,
		"title": "調査報酬の微増",
		"banner_desc": "補給局の上乗せ配分あり",
		"field_notes": "・補給局：「上乗せ配分を開始」\n・会計：「検収袋が重い」\n・門番：「帰隊時の笑顔が増えた（主観）」",
		"article": "補給局が小規模な追加報酬を配分した。現場回収分に上乗せがある、との通達。",
		"effect_summary": "・戦闘ゴールド ×1.2",
		"descriptions": [
			"小銭タイム！積もると立派なお金になるよ。\nゴールド上乗せ中は検収を丁寧にね。通達はスロット終了で切れるから、先送りしすぎないで！\n門番さんも笑顔が増えたらしいし……隊長の笑顔も期待してる？\nわたしのおやつ代は別会計で！",
			"調査報酬の微増中。補給局が上乗せ配分してるよ。\n検収袋が重い＝いい兆候！丁寧に数えよう。\nスロット終了で切れるから、先送りしすぎ注意。\nおやつ代は別。念のため何度でも書く。",
			"ゴールド寄りタイム。門番さん主観で笑顔増だって。\n隊長も笑顔で帰ってきて？検収が楽しくなるから。\n小銭でも積もれば装備に変わるよ。\n会計係、忙しそう……手伝わないけど応援はする！",
			"上乗せ配分ウィンドウだよ。短いから逃さないでね。\n現場回収＋通達分、両方もらい切ろう！\nわたしの仮説：笑顔とゴールドは相関する。たぶんね？\n無事と小銭、両方待ってる。",
		],
	},
	{
		"id": "weapon_drop",
		"weight": 3,
		"modifier_type": "weapon_drop",
		"modifier_mult": 1.2,
		"title": "遺物反応の微増",
		"banner_desc": "遺物の気配が床に落ちやすい",
		"field_notes": "・遺物係：「針が振れやすい」\n・第4班：「床に直落ちが増」\n・鍛冶：「持ち込み武器の検品が混む」",
		"article": "遺物反応がやや活発。現場で武器が直に落ちる気配が、平時よりわずかに強い。",
		"effect_summary": "・武器ドロップ率 ×1.2",
		"descriptions": [
			"ガチャ……じゃなくて遺物反応が元気！拾得確認は急いでね。\n所持枠が埋まりやすいから、不要品の解体・売却を先に済ませてから潜ろう。\n床にキラッと光ってたら、忘れずに〜！わたしの記録も増えるし。\nいい武器見つけたら自慢していいよ？",
			"遺物反応微増中。針が振れやすいって遺物係談。\n床直落ちが増える日は、足元チェック必須！\n所持枠、先に空けてから出発してね。\nいい武器は自慢OK。記録係もニヤニヤする。",
			"武器ドロップ寄りタイム。鍛冶の検品が混むらしい。\nつまり持ち込み増＝チャンス。枠パンク注意！\nキラッを見逃さない隊長が好き。\nたぶん、光ってる。たぶんね？",
			"反応活発だよ。平時よりわずかに強い——その『わずか』が積み上がる！\n解体・売却を先に済ませて、拾う余裕をつくろう。\n自慢は帰ってから。戦闘中は拾って逃げる？状況次第。\n記録、増やしてね隊長！",
		],
	},
	## P3-UX-FIELD-CODEX-OMIT-001: 図鑑調査×1.5 スロットはオミット（weight 0・定義は将来復帰用に残置）。
	{
		"id": "codex",
		"weight": 0,
		"modifier_type": "codex",
		"modifier_mult": 1.5,
		"title": "生態活発のひととき",
		"banner_desc": "未見の生態を記す好機",
		"field_notes": "・図鑑係：「未登録の影が多い」\n・第3班：「初めて見る模様」\n・見張り台：「観察向きの天候」",
		"article": "未確認個体の目撃が一時的に増えている。図鑑係からは『記録の好機』との連絡。",
		"effect_summary": "・図鑑調査効率 ×1.5",
		"descriptions": [
			"図鑑の時間だよ！未登録・進捗の浅い個体を優先して記録してね。\n討伐より観察が先、の場面もあるから、焦らないで。\n写真（記録）を残せば、わたしがきれいに整理しておく！\n珍しい模様見つけたら、真っ先に報告して？興奮しちゃうから。",
			"生態活発タイム！未登録の影が多いって図鑑係がはしゃいでた。\n観察向きの天候らしい。討伐衝動、ちょっと抑えて？\n進捗の浅い個体優先で、効率よく埋めよう。\n模様の話、机で待ってる！",
			"記録の好機だよ。初めて見る模様、増えてるかも。\n焦って倒すより、観察して残す日！\nわたし、整理担当やりたい気持ち全開。……たぶんね？\n報告、早く欲しい！",
			"図鑑×寄り。未確認の目撃が一時的に増えてるみたい。\n短いスロットだから、気になってた個体から狙ってね。\n写真（記録）は濡れない袋に。雨の日以外でも習慣！\n興奮しすぎて迷子にならないで？",
		],
	},
	{
		"id": "featured_biome",
		"weight": 3,
		"modifier_type": "featured_biome",
		"modifier_mult": 1.2,
		"title": "注目区域調査",
		"banner_desc": "重点区域では記録と補給が厚い",
		"field_notes": "・指令：「重点区域を掲示せよ」\n・補給局：「区域限定の上乗せあり」\n・門番：「行きと帰りで行き先を確認」",
		"article": "ギルドが重点調査区域を指定。該当区域では記録・補給の効率がわずかに上がる。",
		"effect_summary": "・注目区域の経験値／ゴールド ×1.2",
		## 実際の文面は FEATURED_BIOME_DESCRIPTIONS（Biome名埋め込み）。
		"descriptions": [
			"注目区域チェック必須！表示を見落とさないでね。\n区域外だとボーナスが乗らないよ〜。経験値もゴールドも欲しいなら、指定区域の周回がおすすめ。\n行き先、門番さんにもちゃんと伝えて？迷子隊長は記録に残すから！\n……残したら怒る？ふふ、残さないよ。たぶん。",
		],
	},
	{
		"id": "elite_material",
		"weight": 3,
		"modifier_type": "elite_material",
		"modifier_mult": 1.2,
		"title": "高品質素材のひととき",
		"banner_desc": "精錬向きの良品が集まりやすい",
		"field_notes": "・鍛冶：「良品の持ち込みが続く」\n・第6班：「精鋭落ちが厚い」\n・倉庫：「仕分けが追いつかない」",
		"article": "エリート級からの素材採取が一時的に好調。精錬・鍛冶向けの良品が集まりやすい。",
		"effect_summary": "・エリート素材入手量 ×1.2",
		"descriptions": [
			"素材どき〜！鍛冶の在庫とレシピを見てから周回してね。\nエリート素材が余っても、必要枠が分からないと持ち帰りが雑になるよ。\n解体前に要件をメモ！わたしも一緒にリスト作ってあげる。\n倉庫がパンクする前に、仕分けお願いね？隊長！",
			"高品質素材のひととき。鍛冶さん、良品の持ち込み続きで忙しそう。\nレシピ見てから潜ると、持ち帰りが賢いよ！\n倉庫の仕分け、追いついてないらしい。雑に積まないでね。\nリスト、机で一緒に作ろ？",
			"精鋭落ちが厚い時間帯だよ。素材目当てなら今！\n必要枠が分からないまま拾うと、あとで泣くよ？……たぶんね？\n解体前メモ推奨。わたしも手伝う。\nパンク前に仕分け、頼んだ隊長！",
			"エリート素材×寄り。精錬・鍛冶向けの良品が集まりやすいみたい。\n在庫と相談して周回ルート決めてね。\n余ったら整理、足りなければ追加周回——計画が勝つ！\nいい素材、見せて？記録用（と少し好奇心）。",
		],
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


## 種別ごとのノノカメモを、スロット番号で決定的に1本選ぶ。
static func pick_description(def: Dictionary, slot_index: int) -> String:
	var pool: Variant = def.get("descriptions", [])
	if typeof(pool) == TYPE_ARRAY:
		var arr: Array = pool as Array
		if not arr.is_empty():
			var idx: int = _stable_memo_index(slot_index, str(def.get("id", "")), arr.size())
			return str(arr[idx])
	return str(def.get("description", ""))


static func pick_featured_biome_description(slot_index: int, biome_name: String) -> String:
	var n: int = FEATURED_BIOME_DESCRIPTIONS.size()
	if n <= 0:
		return ""
	var idx: int = _stable_memo_index(slot_index, "featured_biome", n)
	var tmpl: String = FEATURED_BIOME_DESCRIPTIONS[idx]
	## テンプレ内の %s をすべて biome_name で埋める。
	return tmpl.replace("%s", biome_name)


static func build_active_event(now_unix: int) -> Resource:
	var slot: int = absolute_slot_index(now_unix)
	var def_idx: int = definition_index_for_slot(slot)
	var def: Dictionary = SLOT_DEFINITIONS[def_idx]
	var event: Resource = _EventData.new()
	event.id = "field_slot_%s_%d" % [str(def.get("id", def_idx)), slot]
	event.title = str(def.get("title", ""))
	event.tag_text = EventSystem.DISPLAY_NAME
	event.banner_desc = str(def.get("banner_desc", ""))
	event.description = pick_description(def, slot)
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
	## 天候の戦闘補正は情報誌の【天候の効果】欄（該当天候のみ）へ。効果欄は固定文言のみ。
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
			event.banner_desc = "重点区域『%s』では記録と補給が厚い" % biome_name
			if "article" in event:
				event.article = "ギルドが重点調査区域として『%s』を指定。該当区域では記録・補給の効率がわずかに上がる。" % biome_name
			if "field_notes" in event:
				event.field_notes = "・指令：「重点区域は %s」\n・補給局：「区域限定の上乗せあり」\n・門番：「行き先を掲示と照合」" % biome_name
			if "effect_summary" in event:
				event.effect_summary = "・%s の経験値／ゴールド ×%.1f" % [biome_name, event.modifier_mult]
			event.description = pick_featured_biome_description(slot, biome_name)
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


static func _stable_memo_index(slot_index: int, def_id: String, pool_size: int) -> int:
	if pool_size <= 0:
		return 0
	var h: int = int(hash("crownfall_nonoka_memo_%s_%d" % [def_id, slot_index]))
	return absi(h) % pool_size


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
