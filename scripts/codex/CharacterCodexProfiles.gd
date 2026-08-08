class_name CharacterCodexProfiles
extends RefCounted

## 図鑑「キャラ」人物録のプロフィール SSOT（初期5）。
## 助っ人は `GachaHelperData` の同名フィールド。

const _RT := preload("res://scripts/codex/CodexRichText.gd")
const _CombatPassives := preload("res://scripts/combat/CombatPassives.gd")


## id → { hometown, height_cm, likes, dislikes, backstory, record_note, rarity }
const STARTER_PROFILES: Dictionary = {
	"adventurer_0": {
		"hometown": "アイアンヘイブン",
		"height_cm": 182,
		"likes": "夜明け前の訓練、直剣の手入れ",
		"dislikes": "遠回りな会議、冷えた飯",
		"backstory": (
			"前線を好む実直な剣士。言葉より先に一歩出る癖があり、訓練舎では「火が早い」とからかわれた。\n"
			+ "固有の戦いぶりは王炎の覇気と呼ばれるが、王族の血ではない——"
			+ "王国騎士の伝承に残る「覚悟の炎」を、現代の探索剣術が俗称として借りたものだ。\n"
			+ "合流すれば「遅れたな」と笑い、そのまま先頭を取る。"
		),
		"record_note": "「王炎」は伝承俗称。血縁の証ではない——記録部注。",
		"rarity": 3,
	},
	"adventurer_1": {
		"hometown": "ヴェルディア縁（グリーンホロウ近傍）",
		"height_cm": 168,
		"likes": "静かな見張り台、乾いた矢羽",
		"dislikes": "無駄な談笑、湿った弦",
		"backstory": (
			"寡黙な斥候。距離を保ち、足手まといになることを嫌う。\n"
			+ "狙いを刻む矢じりで標を付け、観察と追い討ちのあいだを往復する。\n"
			+ "人付き合いより地図の余白を信じ、報告は短い。"
			+ "「……合流する」の一言で、すでに周囲の風を読み始めている。"
		),
		"record_note": "報告は常に一行未満。欄外に「観察済み」とだけ残る。",
		"rarity": 3,
	},
	"adventurer_2": {
		"hometown": "アイアンヘイブン",
		"height_cm": 175,
		"likes": "野草の香り、新しい触媒器",
		"dislikes": "机だけの記録仕事、焦げた薬",
		"backstory": (
			"薬袋と触媒器（杖）を抱えた野戦向きの錬成士。\n"
			+ "記録部の机仕事より、現場で調合するほうが性に合う。\n"
			+ "戦闘に入るたび、いちばん傷ついた仲間へ応急を回す手際は、ギルドでも「野戦調合」と覚えられている。\n"
			+ "知恵をひけらかさず、「手伝わせてくれ」と静かに立つ。"
		),
		"record_note": "「野戦調合」の通称は訓練舎から定着。",
		"rarity": 3,
	},
	"adventurer_3": {
		"hometown": "アイアンヘイブン",
		"height_cm": 188,
		"likes": "重い盾、頼まれた背中",
		"dislikes": "無駄な自慢、薄い鎧の流行",
		"backstory": (
			"大盾を預かりたがる護衛気質の男。自分が傷を引けば調査は続く、という単純な信条で前に立つ。\n"
			+ "聖盾の砦と呼ばれる構えで敵の注目を集め、境界守の古い教練の名残だと言われるが、"
			+ "本人は「背中を預かっただけだ」としか言わない。"
		),
		"record_note": "境界守教練の名残を認めるが、家名は名乗らない。",
		"rarity": 3,
	},
	"adventurer_4": {
		"hometown": "アイアンヘイブン（随伴訓練舎）",
		"height_cm": 164,
		"likes": "ジャックの昼寝、森の足音",
		"dislikes": "無理な服従調教、生き物への蔑称",
		"backstory": (
			"生物の声と間合いを読む獣使い。翠の盟約を教条にはせず、まずは相手の呼吸を合わせることから始める。\n"
			+ "ギルドの随伴訓練舎でジャックの世話係を務めていた一人でもあり、隊への合流はジャックとの再会でもある。\n"
			+ "「ジャックと一緒に来たよ」——その一言に、職能と友情が重なる。"
		),
		"record_note": "ジャック世話係経歴あり。共鳴記録は訓練舎台帳に残る。",
		"rarity": 3,
	},
}


## 拠点NPC（図鑑人物録）。順序は `NPC_ORDER`。
## `codex_revealed=true` のみ一覧で名前・アイコン開示（台詞／立ち絵実装済み）。
const NPC_ORDER: Array[String] = [
	"npc_oren", "npc_nina", "npc_nonoka", "npc_galo", "npc_selma", "npc_tobias", "npc_mael",
]

const NPC_PROFILES: Dictionary = {
	"npc_oren": {
		"display_name": "オーレン",
		"role_name": "ギルド長",
		"portrait_path": "",
		"codex_revealed": false,
		"hometown": "アイアンヘイブン",
		"height_cm": 172,
		"likes": "静かな報告書、正しい空白",
		"dislikes": "功を急ぐ声、持ち帰っただけの遺産自慢",
		"backstory": (
			"老齢の記録家であり、ギルド評議会・本部の顔。慎重で言葉少ない。\n"
			+ "「遺産を持ち帰るな、歴史を持ち帰れ」を体現し、功を急ぐ探索者を諫める。\n"
			+ "任務の承認と調査の重みを、若い隊長へ静かに渡す。"
		),
		"record_note": "ギルド本部／任務・ダンジョン選択の顔。評議会の合議を束ねる代表。",
		"quote": "歴史を持ち帰れ。",
		"rarity": 0,
	},
	"npc_nina": {
		"display_name": "ニーナ",
		"role_name": "記録官",
		## セリフ挿入時の対話バスト（NinaDialogueOverlay / IntroUiAssets.NINA_DIALOGUE_BUST）。
		"portrait_path": "res://assets/npc/ICO_NPC_Nina_Dialogue.png",
		"codex_revealed": true,
		"hometown": "アイアンヘイブン",
		"height_cm": 158,
		"likes": "整った欄外メモ、新しい調査報告",
		"dislikes": "抜けのある報告書、「選ばれし英雄」扱い",
		"backstory": (
			"アイアンヘイブン生まれの若い記録官。野外調査の経験は浅いが、"
			+ "図鑑の欄外メモを読む速さでは記録庁随一と噂される。\n"
			+ "新発見の報告が上がると目を輝かせ、逆に記録の抜けを見つけると、"
			+ "隊長にも遠慮なく「足りません」と言う。\n"
			+ "口調は簡潔で実務的だ。英雄譚より手順を好み、「詳細は図鑑と現地で」と繰り返す。"
			+ "それでも迷子の探索者を見捨てず、だいたい戻ってこられる道筋を残しておく。\n"
			+ "灯火の信仰を教義として語ることはないが、記録庁の机には小さな灯皿があり、"
			+ "調査票を閉じる前に一度だけ火を確かめる癖がある。"
		),
		"record_note": "導入時の案内役。プレイヤーを英雄扱いしない——記録部の作法そのもの。",
		"quote": "詳細は図鑑と現地で。",
		"rarity": 0,
	},
	"npc_nonoka": {
		"display_name": "ノノカ",
		"role_name": "研究員",
		## 調査室／手引きで使う顔アイコン（セリフ・案内の表示用）。
		"portrait_path": "res://assets/npc/ICO_NPC_Nonoka.png",
		"codex_revealed": true,
		"hometown": "アイアンヘイブン",
		"height_cm": 156,
		"likes": "現場の資料あさり、仮説の並べ方",
		"dislikes": "机に縛られただけの調査、根拠なしの断定",
		"backstory": (
			"記録庁系の新人研究員。丸メガネ越しに仮説を並べるおちゃめな調査員。\n"
			+ "観察は真面目だが口は軽く、「データは嘘つかない。……たぶんね？」が口癖。\n"
			+ "ニーナと同じ記録庁の廊下出身だが、机仕事より現場の資料あさりを好む。\n"
			+ "調査室では考古担当として、隊長の調査サイクルに混成配置される。"
		),
		"record_note": "調査室専用スタッフ（戦闘ロスター外）。考古担当。",
		"quote": "データは嘘つかない。……たぶんね？",
		"rarity": 0,
	},
	"npc_galo": {
		"display_name": "ガロ",
		"role_name": "鍛冶師",
		"portrait_path": "",
		"codex_revealed": false,
		"hometown": "レッドフォージ（廃都）→アイアンヘイブン",
		"height_cm": 178,
		"likes": "由来の分かる素材、使い継がれた刃",
		"dislikes": "出所不明の結晶、安易な量産自慢",
		"backstory": (
			"廃都レッドフォージ出身を誇る無骨な職人。赤鉄の工房を預かる。\n"
			+ "鍛冶王〜星屑の鍛冶師ラグナの系譜を自任し、素材の由来にうるさい。\n"
			+ "炉研ぎは技術であると同時に、「受け継いで使う」思想の延長だと本人は言う。"
		),
		"record_note": "赤鉄の工房／鍛冶・クラフトの顔。炉印の俗説にも口を出す。",
		"quote": "由来のない鋼は、ただの鉄だ。",
		"rarity": 0,
	},
	"npc_selma": {
		"display_name": "セルマ",
		"role_name": "商人",
		"portrait_path": "",
		"codex_revealed": false,
		"hometown": "王の大街道沿い（隊商育ち）",
		"height_cm": 165,
		"likes": "正しい値付け、各地の噂",
		"dislikes": "偽の遺物、感情だけの値切り",
		"backstory": (
			"隊商あがりの目利き。中央市場で遺物・素材の真贋を見極める。\n"
			+ "各地の噂にも通じ、抜け目ない交渉者として知られる。\n"
			+ "ゴールドと魔晶石の住み分けを、新人隊長にもはっきり教える。"
		),
		"record_note": "中央市場／売買・目利きの顔。補給部との仲介にも立つ。",
		"quote": "噂は安く、真贋は高い。",
		"rarity": 0,
	},
	"npc_tobias": {
		"display_name": "トビアス",
		"role_name": "宿の主",
		"portrait_path": "",
		"codex_revealed": false,
		"hometown": "アイアンヘイブン",
		"height_cm": 180,
		"likes": "温かい席、灯皿の火、旅人の無事",
		"dislikes": "喧嘩の煽り、灯を踏み消す者",
		"backstory": (
			"辻灯亭の面倒見のよい亭主。各地から集う探索者をつなぎ、灯火の習わしを静かに守る。\n"
			+ "噂話（ロア）の供給源でもあり、在野のユニーク探索者が立ち寄る場の守り手だ。\n"
			+ "招待状の合流も、多くの場合この灯の下で始まる。"
		),
		"record_note": "辻灯亭／助っ人勧誘・編成の顔。灯火の信仰を教義ではなく作法として守る。",
		"quote": "灯があるうちは、戻ってこい。",
		"rarity": 0,
	},
	"npc_mael": {
		"display_name": "マエル",
		"role_name": "認定官",
		"portrait_path": "",
		"codex_revealed": false,
		"hometown": "アイアンヘイブン（元・上級探索者）",
		"height_cm": 176,
		"likes": "正確な試験、一専門を究めた証",
		"dislikes": "形だけの称号、試験の手抜き",
		"backstory": (
			"元・上級探索者の厳格な試験官。認定所で専門資格（到達形）の認定を司る。\n"
			+ "言葉は少なく、基準は曲げない。\n"
			+ "「強さ」ではなく「究めた専門」を見る、と本人は繰り返す。"
		),
		"record_note": "認定所／ジョブ認定（到達形）の顔。上級探索者資格の門番。",
		"quote": "究めたか。それだけだ。",
		"rarity": 0,
	},
}


## 九王（伝承）。台詞・立ち絵未実装のため図鑑一覧は ???（データ残置）。
const LEGEND_KING_ORDER: Array[String] = [
	"legend_king_orgran", "legend_king_valkein", "legend_king_seradis",
	"legend_king_eldion", "legend_king_aurex", "legend_king_luminas",
	"legend_king_nereios", "legend_king_sylvaria", "legend_king_caelum",
]

const LEGEND_KING_PROFILES: Dictionary = {
	"legend_king_orgran": {
		"display_name": "オルグラン",
		"role_name": "九王・鍛冶王",
		"hometown": "鍛冶諸侯連合（レッドフォージ）",
		"likes": "受け継がれて使われ続けるもの",
		"dislikes": "",
		"backstory": (
			"東の山稜に星炉を築き、数多の王遺産を鍛えたと伝わる王。理念は鍛造。\n"
			+ "「受け継がれて使われ続けるものこそ価値がある」という信条は、"
			+ "後世のギルド理念「歴史を持ち帰れ」と遠く響き合う。\n"
			+ "技は九英雄ラグナへ、さらに現代の赤鉄の工房へと連なるとされる。"
		),
		"record_note": "王遺産⑥星炉の槌／星鍛槌グランフォージ。炉印（同一紋様）の問いあり。",
		"rarity": 0,
	},
	"legend_king_valkein": {
		"display_name": "ヴァルケイン",
		"role_name": "九王・守護王",
		"hometown": "守護の砦国（ストームクラウン麓）",
		"likes": "境界を見定め内側を守ること",
		"dislikes": "",
		"backstory": (
			"最高峰ストームクラウンの麓に砦の国を築いた王。理念は守護。\n"
			+ "「何を守り、どこを境とするか」を統治の核に据えた。\n"
			+ "現代の前衛職（ヴァンガード／パラディン）の精神的源流として引き合いに出される。"
		),
		"record_note": "王遺産②王盾アイギス／守護槍バスティオン。境界守の系譜の源。",
		"rarity": 0,
	},
	"legend_king_seradis": {
		"display_name": "セラディス",
		"role_name": "九王・学識王",
		"hometown": "学府都市（王立図書院）",
		"likes": "集め、記し、必要なら封じること",
		"dislikes": "",
		"backstory": (
			"各地の知識を王立図書院へ集めた王。理念は知識。\n"
			+ "錬成の体系化もその学府に連なるとされ、アルケミストの知の遠い源と語られる。\n"
			+ "同時に「集めた知のいくつかを、あえて封じた王」としても伝わる。"
		),
		"record_note": "王遺産③叡智の書庫鍵／叡智の杖ノエシス。封緘書庫は公開問い。",
		"rarity": 0,
	},
	"legend_king_eldion": {
		"display_name": "エルディオン",
		"role_name": "九王・開拓王",
		"hometown": "辺境開拓諸侯（ノースリーチ／フロストウォール）",
		"likes": "未知を既知へ変えること",
		"dislikes": "",
		"backstory": (
			"既知世界の外縁を歩き、地図の余白を埋めた王。理念は開拓。\n"
			+ "黎明の羅針盤は征服の道具ではなく、「まだ誰も記していない場所がある」という指針の象徴。\n"
			+ "その姿勢は九英雄アステルを経て、ギルド任務「地図更新」へ受け継がれる。"
		),
		"record_note": "王遺産①黎明の羅針盤／王剣レクス。北境に「エルディオンの針」。",
		"rarity": 0,
	},
	"legend_king_aurex": {
		"display_name": "アウレクス",
		"role_name": "九王・信義王",
		"hometown": "盟約諸国（アイゼンプレイン）",
		"likes": "約束を国家の礎とすること",
		"dislikes": "",
		"backstory": (
			"異なる王国のあいだに盟約を結び、力ではなく約束で秩序を保とうとした王。理念は信義。\n"
			+ "中央平原の盟約諸国は交易と外交の要だったが、九王戦争の決裂とともに脆く崩れた。\n"
			+ "盟約と信用を重んじる気風は、いまの隊商網やギルドの契約文化に影を落とす。"
		),
		"record_note": "王遺産④盟約の指環／盟約剣フィデス。",
		"rarity": 0,
	},
	"legend_king_luminas": {
		"display_name": "ルミナス",
		"role_name": "九王・巡礼王",
		"hometown": "巡礼自由都市網（王の大街道沿い）",
		"likes": "人と文化を結ぶ道",
		"dislikes": "",
		"backstory": (
			"王の大街道を整備し、都市と都市、人と文化を結んだ王。理念は道。\n"
			+ "街道の多くは崩落後に寸断されたが、いまも隊商がその名残をたどって安全圏を結び直している。\n"
			+ "道沿いに灯を守り継ぐ風習は、後の灯火の信仰とも溶け合ったとされる。"
		),
		"record_note": "王遺産⑤巡礼の杖／巡礼弓ルーメン。",
		"rarity": 0,
	},
	"legend_king_nereios": {
		"display_name": "ネレイオス",
		"role_name": "九王・海統王",
		"hometown": "海洋連合（シーゲート／島々）",
		"likes": "海路を統べ、彼方とつなぐこと",
		"dislikes": "",
		"backstory": (
			"潮の境を読み、海路を統治した王。理念は航海。\n"
			+ "潮境の海図は陸の地図とは別の「海の記憶」を記したものと伝わる。\n"
			+ "港町シーゲートは九王戦争を生き延びた数少ない都市のひとつ。"
		),
		"record_note": "王遺産⑦潮境の海図／潮槍ネレイス。九英雄マレクの航海録が系譜を継ぐ。",
		"rarity": 0,
	},
	"legend_king_sylvaria": {
		"display_name": "シルヴァリア",
		"role_name": "九王・森護王",
		"hometown": "森の盟約国（ヴェルディア）",
		"likes": "森と循環を守ること",
		"dislikes": "",
		"backstory": (
			"西の大森林ヴェルディアを治めた王。理念は生命。\n"
			+ "人が森を所有するのではなく、互いを侵さない——翠の盟約——を根本に据えたと伝わる。\n"
			+ "思想は九英雄カイルや、現代のビーストテイマーにも通じる。"
		),
		"record_note": "王遺産⑧生命の種子／翠杖ヴェルド。世界樹への敬意は公開問い。",
		"rarity": 0,
	},
	"legend_king_caelum": {
		"display_name": "カエルム",
		"role_name": "九王・継承王",
		"hometown": "中央王統（王都アステリア）",
		"likes": "「次の者へ」受け渡すこと",
		"dislikes": "",
		"backstory": (
			"中央の王都アステリアにあって諸国をゆるやかに束ねた王統の長。理念は継承。\n"
			+ "武力でも知でもなく、「受け継ぐこと」そのものを統治の核に据えた。\n"
			+ "「最後の継承者」として語られることが多いが、何を誰へ継ごうとしたかは崩落とともに途切れる。"
		),
		"record_note": "王遺産⑨継承の書／継承剣レガート。王冠の問いと深く結ぶ。",
		"rarity": 0,
	},
}


## 九英雄（伝承）。台詞・立ち絵未実装のため図鑑一覧は ???（データ残置）。
const LEGEND_HERO_ORDER: Array[String] = [
	"legend_hero_astel", "legend_hero_elenas", "legend_hero_lucien",
	"legend_hero_ilia", "legend_hero_ragna", "legend_hero_ceres",
	"legend_hero_kyle", "legend_hero_marek", "legend_hero_nameless",
]

const LEGEND_HERO_PROFILES: Dictionary = {
	"legend_hero_astel": {
		"display_name": "アステル",
		"role_name": "九英雄・地平の探求者",
		"hometown": "外縁（伝承）",
		"likes": "地図の余白",
		"dislikes": "",
		"backstory": (
			"未知の外縁を歩き、地図の余白を埋め続けた探求者。\n"
			+ "開拓王エルディオンの精神を継ぎ、ギルド任務「地図更新」の規範を築いたとされる。"
		),
		"record_note": "城壁の外を一歩でも遠くへ——新人探索者へ最初に語られる姿勢。",
		"rarity": 0,
	},
	"legend_hero_elenas": {
		"display_name": "エレナス",
		"role_name": "九英雄・王遺産の守り手",
		"hometown": "伝承（領域不詳）",
		"likes": "後世へ受け継ぐ記録",
		"dislikes": "",
		"backstory": (
			"王遺産を「誰かの所有物」ではなく「後世へ受け継ぐべき記録」として扱う倫理を示した。\n"
			+ "ギルドの言葉「遺産を持ち帰るな、歴史を持ち帰れ」の源とされる。"
		),
		"record_note": "探索者の行動規範そのものに名が残る。",
		"rarity": 0,
	},
	"legend_hero_lucien": {
		"display_name": "リュシアン",
		"role_name": "九英雄・深淵を踏破した者",
		"hometown": "地下深部（伝承）",
		"likes": "調査対象としての未知",
		"dislikes": "",
		"backstory": (
			"地下深部や未知の領域を、恐怖ではなく調査対象として記録した。\n"
			+ "危険区域へ踏み込む生態調査の作法は、その記録に基づくと語られる。"
		),
		"record_note": "モーンゲートのような縦に深い遺構を探る者が名を引く。",
		"rarity": 0,
	},
	"legend_hero_ilia": {
		"display_name": "イリア",
		"role_name": "九英雄・灯火を継いだ巫女",
		"hometown": "伝承（灯火）",
		"likes": "絶やさない灯と祈り",
		"dislikes": "",
		"backstory": (
			"戦乱のさなかでも灯火と祈りを絶やさなかった巫女。\n"
			+ "ここでの巫女は神官ではなく、灯と記憶を守り伝える者の呼び名。\n"
			+ "灯火の信仰——記憶と継承を絶やさぬ象徴——の核となった。"
		),
		"record_note": "「誰もその灯火を消させようとはしなかった」——公開問い。",
		"rarity": 0,
	},
	"legend_hero_ragna": {
		"display_name": "ラグナ",
		"role_name": "九英雄・星屑の鍛冶師",
		"hometown": "レッドフォージ系譜（伝承）",
		"likes": "使い継ぐ装備",
		"dislikes": "",
		"backstory": (
			"星屑鍛造の基礎を築いた鍛冶師。鍛冶王オルグランの星炉の技を受け継いだとされる。\n"
			+ "現代アイアンヘイブンの赤鉄の工房もその系譜に連なると伝わる。"
		),
		"record_note": "同一紋様（炉印）の証言にもしばしば名が挙がる。",
		"rarity": 0,
	},
	"legend_hero_ceres": {
		"display_name": "セレス",
		"role_name": "九英雄・失われた王都の記録者",
		"hometown": "王都アステリア（崩落時）",
		"likes": "最後まで書き留めること",
		"dislikes": "",
		"backstory": (
			"崩壊していく王都アステリアを、最後まで書き留め続けた記録者。\n"
			+ "通称アステリア陥落録は、その手によるものだとされる。\n"
			+ "欠落と破損が多く、全容は判明していない。"
		),
		"record_note": "記録部の最重要史料。解読しきれない断片が残る。",
		"rarity": 0,
	},
	"legend_hero_kyle": {
		"display_name": "カイル",
		"role_name": "九英雄・竜と盟約を結んだ者",
		"hometown": "伝承（古龍種との距離）",
		"likes": "戦うのでも従えるのでもない距離",
		"dislikes": "",
		"backstory": (
			"「竜」と呼ばれた巨大生物（古龍種）と、戦うのでも従えるのでもない距離を見出したと伝わる。\n"
			+ "現代のビーストテイマーは、そのカイル盟約を主題に掲げる。"
		),
		"record_note": "森護王の翠の盟約とも精神を同じくする。",
		"rarity": 0,
	},
	"legend_hero_marek": {
		"display_name": "マレク",
		"role_name": "九英雄・世界の果てを見た航海者",
		"hometown": "西海（伝承）",
		"likes": "海の彼方の記録",
		"dislikes": "",
		"backstory": (
			"海の彼方へ航海し、帰還後に多くの記録を残した航海者。\n"
			+ "海統王ネレイオスの海図術を継いだとされ、遠い海域の伝承の多くは彼の航海録に由来する。"
		),
		"record_note": "ブラックショアの潮見表・失われた航路の断片と結ぶ。",
		"rarity": 0,
	},
	"legend_hero_nameless": {
		"display_name": "名を残さなかった継承者",
		"role_name": "九英雄・無名",
		"hometown": "伝承（継承）",
		"likes": "名ではなく意思を託すこと",
		"dislikes": "",
		"backstory": (
			"名ではなく意思だけを後世へ託したとされる存在。確かな記録は残っていない。\n"
			+ "「次の者へ受け渡す」という思想そのものを体現した者として語り継がれる。\n"
			+ "探索者（プレイヤー）の立場——知らぬ間に何かを継いでいく一人——と静かに響き合う。"
		),
		"record_note": "公開は問いのみ。真相は内部正典側。",
		"rarity": 0,
	},
}


## 随伴ペット（図鑑人物録）。PetData と併記。
const PET_PROFILES: Dictionary = {
	"pet_jack": {
		"role_name": "随伴ペット",
		"hometown": "アイアンヘイブン随伴訓練舎",
		"height_cm": 46,
		"likes": "前衛の匂い、昼寝、ミレイの声",
		"dislikes": "長い待機、無理な服従の声",
		"backstory": (
			"探索者ギルドが新人調査隊へ貸与する小型の随伴伴侶獣。\n"
			+ "装備もパッシブも持たず、群れ指揮・介抱・守り吠えで隊を支えるサポート役。"
			+ "物語上の入手はストーリーのみ（招待状では招かない）。\n"
			+ "隊長登録が通った時点で隊に付き、人間メンバーの入れ替わりと無関係に同行する。"
			+ "ミレイは訓練舎時代の世話係であり、他の初期隊員にとっても「最初からいた仲間」である。"
		),
		"record_note": "人間4枠の外。脅威は後列相当以下。全滅判定は人間側が正。",
		"rarity": 1,
	},
	"pet_ash": {
		"role_name": "随伴ペット",
		"hometown": "アイアンヘイブン随伴訓練舎（夜間索敵組）",
		"height_cm": 48,
		"likes": "狩り、灰白の茂み、短い号令",
		"dislikes": "長すぎる待機、散らかった陣形",
		"backstory": (
			"ギルド随伴訓練舎の夜間索敵組。ジャックの同期で、灰白の毛並みが目印。\n"
			+ "噛みつき火力を主軸に、隊列の手数を増やす攻撃役として育てられた。"
			+ "ウィスパーウッドの完全調査を終えた隊へ、追加貸与されることがある。"
		),
		"record_note": "ウィスパーウッド調査100%景品。ジャックとLv/EXP共有の色変え個体。",
		"rarity": 1,
	},
	"pet_ink": {
		"role_name": "随伴ペット",
		"hometown": "アイアンヘイブン随伴訓練舎（珍毛枠）",
		"height_cm": 42,
		"likes": "影、毒と麻痺の合図、短い狩りのあと",
		"dislikes": "明るい広場での長話、遅すぎる指示",
		"backstory": (
			"訓練舎の珍毛個体。黒紫の影毛が特徴で、毒・麻痺など状態異常特化の伴侶獣として育てられた。\n"
			+ "ジャックやアッシュと同型の骨格だが、間合いの取り方はより鋭い。"
			+ "ブラックショアの完全調査を終えた隊へ、追加貸与されることがある。"
		),
		"record_note": "ブラックショア調査100%景品。ジャックとLv/EXP共有の色変え個体。",
		"rarity": 1,
	},
}


static func starter_profile(adventurer_id: String) -> Dictionary:
	var raw: Variant = STARTER_PROFILES.get(adventurer_id, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate()
	return {}


static func npc_profile(npc_id: String) -> Dictionary:
	var raw: Variant = NPC_PROFILES.get(npc_id, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate()
	return {}


static func pet_profile(pet_id: String) -> Dictionary:
	var raw: Variant = PET_PROFILES.get(pet_id, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate()
	return {}


static func legend_king_profile(legend_id: String) -> Dictionary:
	var raw: Variant = LEGEND_KING_PROFILES.get(legend_id, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate()
	return {}


static func legend_hero_profile(legend_id: String) -> Dictionary:
	var raw: Variant = LEGEND_HERO_PROFILES.get(legend_id, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate()
	return {}


static func format_profile_body(
	hometown: String,
	height_cm: int,
	likes: String,
	dislikes: String,
	backstory: String,
	record_note: String,
	quote: String = "",
	passive_id: String = "",
	height_label: String = "身長"
) -> String:
	var lines: PackedStringArray = []
	lines.append(_RT.section("プロフィール"))
	if not hometown.is_empty():
		lines.append("%s %s" % [_RT.emph("出身地:"), hometown])
	if height_cm > 0:
		var hlab: String = height_label if not height_label.is_empty() else "身長"
		lines.append("%s %dcm" % [_RT.emph("%s:" % hlab), height_cm])
	if not likes.is_empty():
		lines.append("%s %s" % [_RT.emph("好きなもの:"), likes])
	if not dislikes.is_empty():
		lines.append("%s %s" % [_RT.emph("苦手なもの:"), dislikes])
	if not backstory.is_empty():
		lines.append("")
		lines.append(_RT.section("生い立ち"))
		lines.append(backstory)
	if not quote.is_empty():
		lines.append("")
		lines.append("「%s」" % quote)
	if not passive_id.is_empty():
		var pdef: Dictionary = _CombatPassives.get_def(passive_id)
		if not pdef.is_empty():
			lines.append("")
			lines.append("%s %s — %s" % [
				_RT.emph("固有:"),
				str(pdef.get("display_name", passive_id)),
				str(pdef.get("description", "")),
			])
	if not record_note.is_empty():
		lines.append("")
		lines.append(_RT.section("記録メモ"))
		lines.append(record_note)
	return "\n".join(lines)
