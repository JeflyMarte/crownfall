class_name WeaponFlavorHelper
extends RefCounted

## 武器フレーバー（P3-LORE-002）。rarity≥EPIC の公開断片。`world/02_Relics §3` を素材源とする。

const FLAVOR_BY_ID: Dictionary = {
	# --- レジェンド（九王系・伝承断片） ---
	"eldion_frostbrand": "辺境の石標に刻まれた一行——「ここより先、地図なし。剣は道なき道を選ぶ」。",
	"nereidas_tideblade": "海図の余白に走り書き——「失われた航路は、潮が覚えている」。",
	"pharoslight_staff": "なぜ、誰もその灯火を消させようとはしなかったのか。──灯台の芯石にだけ残る問い。",
	"seradion_storm_staff": "図書院の封じられた扉の前で見つかる覚書——「開く鍵は、閉ざすためにも要る」。",
	"volgrave_thunderblade": "砦跡の崩れた門に残る句——「盾は退かず、槍は越えさせず」。",
	"veld_branch_staff": "森の祠に残る詩片——「種は一つにあらず、樹もまた一つにあらず」。",
	"silvaria_oathblade": "森護王にまつわる盟約の刻——「ここより先、森が濃い。火を絶やすな」。",
	"sanctified_dagger": "王座の深淵の崩れた石に——「継ぐ者へ。これは終わりの剣ではない」。",
	"consecrated_maul": "巡礼の道標に薄く残る——「迷う者あらば、弓を引け。矢の落ちる先に道がある」。",
	"umbra_terminus_staff": "王都地下の写しの欄外——「これは九王の遺産ではない」。原本は、すでに失われている。",
	# --- エピック（Biome テーマ短句） ---
	"white_needle": "北境の吹雪記録に添えられた一行——「標は見えず、矢だけが先を指す」。",
	"permafrost_edge": "永久凍土の境界標——「ここより先、地図なし」。",
	"beacon_needle": "灯台の残響——「潮が引くとき灯を上げ、満ちるとき火を継げ」。",
	"sanctum_tide_edge": "干潮の聖別に触れた刃。潮位の変化を刻む者だけが扱えると伝わる。",
	"volt_needle": "沼の雷鳴を射抜いた矢。帯電した雨粒の跡が弦に残る。",
	"thunderfen_edge": "崩落街道の橋脚に落ちた雷痕。刃先にだけ、古い放電の匂いが宿る。",
	"umbral_fang": "王都地下の風化碑文——「王冠は倒れた」。その先は、読めない。",
	"symbiont_edge": "森番の刻印——「ここより先、森が濃い。火を絶やすな」。",
	"storm_edge": "九王戦争の崩れた門——「盾は退かず、槍は越えさせず」。",
	"mist_piercer": "封緘書庫の蝋印——何を封じたかを問う記録だけが残る。",
	"heater_blade": "炉壁の銘——「九つはひとつの炉より生まれた」。",
	"glacier_staff": "氷河の果てに眠る古龍の伝承。霜の結晶だけが杖芯を覆う。",
	"frost_blade": "開拓隊の隠し倉に残された凍結保存の刃。雪庇の下でだけ研ぎ直された。",
	"ember_fang": "梢のささやき——「森がささやき返す日は、聞くな」。",
	"bolt_knife": "帯電した沼苔を裂いた双刃。雷の走りが刃筋に一瞬だけ残る。",
}

static func get_flavor_text(weapon_data: Resource) -> String:
	if weapon_data == null:
		return ""
	if int(weapon_data.rarity) < Enums.Rarity.EPIC:
		return ""
	if "flavor_text" in weapon_data:
		var custom: String = str(weapon_data.flavor_text).strip_edges()
		if not custom.is_empty():
			return custom
	var weapon_id: String = str(weapon_data.id)
	return str(FLAVOR_BY_ID.get(weapon_id, ""))

static func get_flavor_text_for_item(item: Resource) -> String:
	if item == null or not ("weapon_id" in item):
		return ""
	var weapon_data: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
	return get_flavor_text(weapon_data)
