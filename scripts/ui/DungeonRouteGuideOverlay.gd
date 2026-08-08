class_name DungeonRouteGuideOverlay
extends CanvasLayer

## 書籍手引き（ニーナ）。ダンジョン枠（P3-DG-ROUTE-GUIDE-001）＋拠点部屋初見ガイド。
## 書籍UIは HubSimpleGuideOverlay と同系統。

signal dismissed

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")

const GUIDE_EVENT: String = "event"
const GUIDE_DESCENT: String = "descent"
const GUIDE_ABYSS: String = "abyss"
const GUIDE_SURVEY: String = "survey"
const GUIDE_GACHA_INVITE: String = "gacha_invite"
const GUIDE_GACHA_SEAL: String = "gacha_seal"
const GUIDE_SHOWCASE: String = "showcase"
const GUIDE_PERMIT: String = "permit"

const FLAG_DESCENT: String = "dungeon_guide_descent_seen"
const FLAG_ABYSS: String = "dungeon_guide_abyss_seen"
const FLAG_SURVEY: String = "hub_guide_survey_seen"
const FLAG_GACHA_INVITE: String = "hub_guide_gacha_invite_seen"
const FLAG_GACHA_SEAL: String = "hub_guide_gacha_seal_seen"
const FLAG_SHOWCASE: String = "hub_guide_showcase_seen"
const FLAG_PERMIT: String = "hub_guide_privilege_boost_seen"
const PENDING_KEY: String = "pending_dungeon_route_guide"

const BG_PATH: String = "res://assets/ui/UI_BG_HubSimpleGuide.png"
const PANEL_MIN: Vector2 = Vector2(700, 680)
const FACE_ICON_PX: float = 88.0
const BG_CONTENT_MARGIN: int = 88
const HEADER_TOP_GAP: float = 28.0
const INK_TITLE: Color = Color(0.22, 0.12, 0.05, 1.0)
const INK_BODY: Color = Color(0.18, 0.11, 0.06, 1.0)
const INK_META: Color = Color(0.38, 0.26, 0.14, 1.0)
const INK_GOLD: Color = Color(0.36, 0.20, 0.05, 1.0)
const EMPH_PROPER: String = "#7A3E12"
const EMPH_KEY: String = "#9A5018"

static func _all_guides() -> Dictionary:
	return {
	GUIDE_EVENT: {
		"topic": "イベントダンジョンとは",
		"flag_key": "",
		"pages": [
			{
				"title": "1. 期間限定の短編",
				"body": (
					"隊長、[color=#9A5018][b]イベントダンジョン[/b][/color]は、"
					+ "メイン進行とは別の[color=#9A5018][b]期間限定の短編[/b][/color]です。\n\n"
					+ "開催中のあいだだけ、ダンジョン選択の"
					+ "[color=#7A3E12][b]イベント[/b][/color]タブに並びます。"
					+ "閉まっているときは一覧に出ません。"
				),
			},
			{
				"title": "2. いつ挑戦できるか",
				"body": (
					"曜日や時間帯で門が開くものがあります。"
					+ "多くは[color=#9A5018][b]一日1回[/b][/color]までの挑戦です"
					+ "（朝5時・日本時間でリセット）。\n\n"
					+ "[color=#7A3E12][b]コズミックダックの裂け目[/b][/color]や"
					+ "[color=#7A3E12][b]宝冠レイヴンの巣[/b][/color]などは、"
					+ "育成や装備の足しにしやすい短編です。"
				),
			},
			{
				"title": "3. メインとの違い",
				"body": (
					"メインルートの章クリアとは別枠です。"
					+ "無理に全部取らなくても大丈夫。\n\n"
					+ "開催中だけサッと覗く、くらいの使い方で十分です。"
					+ "なお時間帯だけの[color=#9A5018][b]降臨[/b][/color]は別枠なので、"
					+ "「降臨とは？」からも確認してくださいね。"
				),
			},
		],
	},
	GUIDE_DESCENT: {
		"topic": "降臨ダンジョンとは",
		"flag_key": FLAG_DESCENT,
		"pages": [
			{
				"title": "1. 時間帯だけの強敵",
				"body": (
					"[color=#9A5018][b]降臨[/b][/color]は、決まった時間帯だけ門が開く"
					+ "[color=#9A5018][b]強敵イベント[/b][/color]です。\n\n"
					+ "例：[color=#7A3E12][b]時環の共鳴龍　降臨[/b][/color]（時王の霊廟）、"
					+ "[color=#7A3E12][b]境界の番　降臨[/b][/color]（ストームクラウン境界廊）。\n\n"
					+ "曜日の短編イベントとも、探索中の放浪とも別物です。"
				),
			},
			{
				"title": "2. 門と難度",
				"body": (
					"門が開いているあいだだけ挑戦できます。"
					+ "閉まっているときは入れません。\n\n"
					+ "降臨は[color=#9A5018][b]ノーマル／ハード／ナイトメア[/b][/color]があり、"
					+ "戦力に合わせて選べます。"
					+ "出現中はイベント一覧の[color=#9A5018][b]いちばん上[/b][/color]に並びます。"
					+ "拠点のわたしも、気づいたらお知らせしますね。"
				),
			},
			{
				"title": "3. 報酬の位置づけ",
				"body": (
					"ここでしか手に入りにくい[color=#9A5018][b]専用の装備[/b][/color]や報酬があります。"
					+ "メインや無限の頂点より手前の、特別枠だと思ってください。\n\n"
					+ "時間勝負になりやすいので、無理な編成は禁物。"
					+ "準備ができたら、門が開いているうちにどうぞ！"
				),
			},
		],
	},
	GUIDE_ABYSS: {
		"topic": "無限ダンジョンとは",
		"flag_key": FLAG_ABYSS,
		"pages": [
			{
				"title": "1. 終わりの先へ",
				"body": (
					"[color=#9A5018][b]無限ダンジョン[/b][/color]は、メインのボスを倒したあとに開く"
					+ "[color=#9A5018][b]エンド向けの長い探索[/b][/color]です。\n\n"
					+ "名前のとおり階がどこまでも伸びます。"
					+ "表示名は「[color=#7A3E12][b]無限〇〇の最果て[/b][/color]」の形です。"
				),
			},
			{
				"title": "2. 解放と難度",
				"body": (
					"対応するメインダンジョンの[color=#9A5018][b]ノーマルBossクリア[/b][/color]で、"
					+ "その無限が解放されます。\n\n"
					+ "階が上がるほど敵も強くなります。"
					+ "途中で戻っても、[color=#9A5018][b]最高到達階[/b][/color]は記録されます。"
					+ "焦らず、届くところまでで大丈夫です。"
				),
			},
			{
				"title": "3. 節目と本命報酬",
				"body": (
					"[color=#9A5018][b]33／66／99階[/b][/color]に節目の報酬があります。"
					+ "99階では、その土地だけの[color=#9A5018][b]専用の伝説装備[/b][/color]が本命です。\n\n"
					+ "99を越えても続けられます。"
					+ "メインの周回とは別の、長く挑む枠——そう覚えておいてくださいね。"
				),
			},
		],
	},
	GUIDE_SURVEY: {
		"topic": "調査室とは",
		"flag_key": FLAG_SURVEY,
		"pages": [
			{
				"title": "1. 机の調査",
				"body": (
					"隊長、ここは[color=#9A5018][b]調査室[/b][/color]です。"
					+ "ダンジョンで集めた資料を調べ、"
					+ "[color=#7A3E12][b]図鑑[/b][/color]と報酬を進めます。\n\n"
					+ "現場に潜らなくても、拠点で研究を回せるのがこの部屋の役割です。"
				),
			},
			{
				"title": "2. 育成にも使える",
				"body": (
					"調査に出したメンバーには、完了時に[color=#9A5018][b]経験値[/b][/color]が入ります。"
					+ "つまり調査室は、資料集めだけでなく"
					+ "[color=#9A5018][b]キャラの育成[/b][/color]にも使えます。\n\n"
					+ "戦場に出せない時間でも、机の仕事で少しずつ強くできますよ。"
				),
			},
			{
				"title": "3. 進め方",
				"body": (
					"調べるダンジョンとメンバーを選び、時間コースを決めて出発。"
					+ "終わったら[color=#9A5018][b]必ず受取[/b][/color]してください"
					+ "（放置したままでは次へ進めません）。\n\n"
					+ "迷ったら右上の[color=#9A5018][b]？[/b][/color]から、いつでもこの手引きを開けます。"
				),
			},
		],
	},
	GUIDE_GACHA_INVITE: {
		"topic": "招待状とは",
		"flag_key": FLAG_GACHA_INVITE,
		"pages": [
			{
				"title": "1. 仲間を迎える門",
				"body": (
					"[color=#9A5018][b]ギルドへの招待状[/b][/color]は、"
					+ "[color=#7A3E12][b]魔晶石[/b][/color]で探索者を迎える召喚です。\n\n"
					+ "助っ人が増えると編成の幅が広がり、調査も戦闘も楽になります。"
				),
			},
			{
				"title": "2. 引き方",
				"body": (
					"排出率は画面の詳細から確認できます。"
					+ "無料券があるときは、それを先に使うのも手です。\n\n"
					+ "武器の方は隣の[color=#9A5018][b]封じられし武庫（封蔵）[/b][/color]。"
					+ "矢印で切り替えられます。"
				),
			},
		],
	},
	GUIDE_GACHA_SEAL: {
		"topic": "封蔵とは",
		"flag_key": FLAG_GACHA_SEAL,
		"pages": [
			{
				"title": "1. 封じられし武庫",
				"body": (
					"[color=#9A5018][b]封蔵[/b][/color]は、ギルドが封印してきた武具の庫——"
					+ "いわば[color=#9A5018][b]装備の召喚[/b][/color]です。\n\n"
					+ "招待状が人を迎える門なら、封蔵は[color=#7A3E12][b]武器・防具・装飾[/b][/color]を引き出す門。"
					+ "世界観上も「封印を解く」扱いです。"
				),
			},
			{
				"title": "2. 灰冠の九",
				"body": (
					"封蔵の目玉に、[color=#9A5018][b]灰冠の九（かいかんのく）[/b][/color]があります。"
					+ "九王戦争〜静寂期に跋扈したと伝わる[color=#9A5018][b]精鋭略奪団[/b][/color]が、"
					+ "奪い・使った武具です。\n\n"
					+ "王の正統な遺産そのものではなく、"
					+ "[color=#9A5018][b]盗まれた写し・戦時特注・封じ武具[/b][/color]を灰冠が私兵化した——"
					+ "そんな建前の[color=#9A5018][b]限定装備[/b][/color]です。"
					+ "通常ドロップや鍛冶生産とは別枠です。"
				),
			},
			{
				"title": "3. 使い方の注意",
				"body": (
					"灰冠装備は強力ですが、多くは[color=#9A5018][b]メリデメ[/b][/color]がはっきりしています。"
					+ "編成と相談して選んでください。\n\n"
					+ "迷ったら[color=#9A5018][b]？[/b][/color]で、この手引きを読み返せます。"
				),
			},
		],
	},
	GUIDE_SHOWCASE: {
		"topic": "展示室とは",
		"flag_key": FLAG_SHOWCASE,
		"pages": [
			{
				"title": "1. 隊の見せ場",
				"body": (
					"[color=#9A5018][b]展示室[/b][/color]は、育てた仲間と装備を並べて"
					+ "[color=#9A5018][b]総合戦力[/b][/color]を確認する部屋です。\n\n"
					+ "自分の編成を飾るほか、ビルド作例も眺められます。"
				),
			},
			{
				"title": "2. 使い方",
				"body": (
					"展示するメンバーを入れ替えたり、装備を確認したりできます。"
					+ "戦力の数字は目安——現場の相性も大事ですよ。\n\n"
					+ "また読みたくなったら[color=#9A5018][b]？[/b][/color]を押してください。"
				),
			},
		],
	},
	GUIDE_PERMIT: {
		"topic": "特権強化とは",
		"flag_key": FLAG_PERMIT,
		"pages": [
			{
				"title": "1. S級からの特典",
				"body": (
					"隊長、調査許可が[color=#9A5018][b]S級[/b][/color]に達すると、"
					+ "マイページから[color=#9A5018][b]特権強化[/b][/color]を開けます。\n\n"
					+ "S のあとも [color=#7A3E12][b]S+1、S+2…[/b][/color]と続き、"
					+ "段が上がるたびに[color=#9A5018][b]許可点[/b][/color]が1つ貯まります。"
				),
			},
			{
				"title": "2. 三つの振り分け",
				"body": (
					"許可点は[color=#9A5018][b]略奪／成長／戦力[/b][/color]のどれかに振り分けます。\n\n"
					+ "[color=#7A3E12][b]略奪[/b][/color] … ゴールドや素材まわり\n"
					+ "[color=#7A3E12][b]成長[/b][/color] … 戦闘の経験値\n"
					+ "[color=#7A3E12][b]戦力[/b][/color] … パーティの耐久\n\n"
					+ "いつでも無料で振り直せます。迷ったら少しずつ試してください。"
				),
			},
			{
				"title": "3. どこから開くか",
				"body": (
					"拠点の[color=#9A5018][b]マイページ[/b][/color]（隊長台帳）にある"
					+ "[color=#9A5018][b]特権強化[/b][/color]ボタンから入れます。\n\n"
					+ "また読みたくなったら、特権強化の画面の"
					+ "[color=#9A5018][b]？[/b][/color]でも同じ手引きを開けます。"
				),
			},
		],
	},
}



var _guide_id: String = GUIDE_EVENT
var _pages: Array = []
var _flag_key: String = ""
var _page_index: int = 0
var _preview_only: bool = false
var _dim: ColorRect
var _panel_shell: Control
var _panel: PanelContainer
var _header_top_spacer: Control
var _title_label: Label
var _topic_label: Label
var _body_scroll: ScrollContainer
var _body_label: RichTextLabel
var _page_label: Label
var _next_btn: Button
var _skip_btn: Button
var _tween: Tween


func _ready() -> void:
	layer = 89
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


static func is_seen(guide_id: String) -> bool:
	var flag: String = _flag_for(guide_id)
	if flag.is_empty():
		return false
	return bool(GameState.tutorial_flags.get(flag, false))


static func mark_seen(guide_id: String) -> void:
	var flag: String = _flag_for(guide_id)
	if flag.is_empty():
		return
	GameState.tutorial_flags[flag] = true
	SaveManager.save_game()


static func queue_auto_if_unseen(guide_id: String) -> void:
	## flag のある手引きのみ（イベント枠など flag 無しは対象外）。
	if _flag_for(guide_id).is_empty():
		return
	if is_seen(guide_id):
		return
	GameState.tutorial_flags[PENDING_KEY] = guide_id


static func has_pending_auto() -> bool:
	var pending: String = str(GameState.tutorial_flags.get(PENDING_KEY, "")).strip_edges()
	if pending.is_empty():
		return false
	if is_seen(pending):
		GameState.tutorial_flags.erase(PENDING_KEY)
		return false
	return _all_guides().has(pending)


static func peek_pending_auto() -> String:
	if not has_pending_auto():
		return ""
	return str(GameState.tutorial_flags.get(PENDING_KEY, ""))


static func clear_pending_auto() -> void:
	GameState.tutorial_flags.erase(PENDING_KEY)


static func _flag_for(guide_id: String) -> String:
	var def: Variant = _all_guides().get(guide_id, {})
	if not def is Dictionary:
		return ""
	return str((def as Dictionary).get("flag_key", ""))


static func show_on(
	parent: Node, guide_id: String, preview_only: bool = false
) -> CanvasLayer:
	if parent == null or not _all_guides().has(guide_id):
		return null
	var existing: Node = parent.get_node_or_null("DungeonRouteGuideOverlay")
	if existing != null:
		existing.queue_free()
	var overlay := new()
	overlay.name = "DungeonRouteGuideOverlay"
	parent.add_child(overlay)
	overlay.present(guide_id, preview_only)
	return overlay


## 未閲覧なら初回自動表示。閲覧済みなら null。
static func try_auto_show(parent: Node, guide_id: String) -> CanvasLayer:
	if parent == null or not _all_guides().has(guide_id):
		return null
	if is_seen(guide_id):
		return null
	if parent.get_node_or_null("DungeonRouteGuideOverlay") != null:
		return null
	return show_on(parent, guide_id, false)


## ヘッダ等に「？」再表示ボタンを足す。`scene_root` にオーバーレイを載せる。
static func attach_help_button(
	host: Control,
	scene_root: Node,
	guide_id: String,
	label: String = "？",
	min_size: Vector2 = Vector2(48, 48)
) -> Button:
	if host == null or scene_root == null or not _all_guides().has(guide_id):
		return null
	var btn := Button.new()
	btn.name = "HubRoomGuideHelpBtn"
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = min_size
	btn.set_meta("hub_room_guide_id", guide_id)
	btn.tooltip_text = str((_all_guides()[guide_id] as Dictionary).get("topic", "手引き"))
	UiTypography.apply_menu_button(btn)
	var root: Node = scene_root
	btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		var gid: String = str(btn.get_meta("hub_room_guide_id", ""))
		if not gid.is_empty():
			show_on(root, gid, true)
	)
	host.add_child(btn)
	return btn


static func set_help_guide_id(btn: Button, guide_id: String) -> void:
	if btn == null or not _all_guides().has(guide_id):
		return
	btn.set_meta("hub_room_guide_id", guide_id)
	btn.tooltip_text = str((_all_guides()[guide_id] as Dictionary).get("topic", "手引き"))


## 解放キュー消化後など。pending があれば表示し、なければ on_done。
static func try_show_pending_on(parent: Node, on_done: Callable = Callable()) -> CanvasLayer:
	if parent == null:
		if on_done.is_valid():
			on_done.call()
		return null
	var pending: String = peek_pending_auto()
	if pending.is_empty():
		if on_done.is_valid():
			on_done.call()
		return null
	clear_pending_auto()
	var overlay: CanvasLayer = show_on(parent, pending, false)
	if overlay == null:
		if on_done.is_valid():
			on_done.call()
		return null
	overlay.dismissed.connect(func() -> void:
		if on_done.is_valid():
			on_done.call()
	)
	return overlay


func present(guide_id: String, preview_only: bool = false) -> void:
	_guide_id = guide_id
	_preview_only = preview_only
	var def: Dictionary = _all_guides().get(guide_id, {}) as Dictionary
	_pages = def.get("pages", []) as Array
	_flag_key = str(def.get("flag_key", ""))
	_page_index = 0
	if _topic_label != null:
		_topic_label.text = str(def.get("topic", "手引き"))
	_refresh_page()
	visible = true
	_play_intro()
	call_deferred("_play_sfx")


func _play_sfx() -> void:
	AudioManager.play_sfx("ui_confirm")


func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.02, 0.03, 0.06, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel_shell = Control.new()
	_panel_shell.name = "PanelShell"
	_panel_shell.custom_minimum_size = PANEL_MIN
	_panel_shell.clip_contents = true
	_panel_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_panel_shell)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.clip_contents = true
	_panel.gui_input.connect(_on_dim_gui_input)
	var empty := StyleBoxEmpty.new()
	_panel.add_theme_stylebox_override("panel", empty)
	_panel_shell.add_child(_panel)

	var bg := TextureRect.new()
	bg.name = "BookBg"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture = _IntroUiAssets.load_tex(BG_PATH)
	_panel.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", BG_CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_right", BG_CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_top", BG_CONTENT_MARGIN - 4)
	margin.add_theme_constant_override("margin_bottom", BG_CONTENT_MARGIN - 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 14)
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner)

	_header_top_spacer = Control.new()
	_header_top_spacer.custom_minimum_size = Vector2(0, HEADER_TOP_GAP)
	_header_top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_header_top_spacer)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(header)

	## 羊皮紙グリッドが顔に透けないよう、不透明下地＋本体不透明ICO。
	var face_host := Control.new()
	face_host.custom_minimum_size = Vector2(FACE_ICON_PX, FACE_ICON_PX)
	face_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	face_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face_host.clip_contents = true
	face_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face_plate := ColorRect.new()
	face_plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face_plate.color = Color(0.78, 0.68, 0.50, 1.0)
	face_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_host.add_child(face_plate)
	var face := TextureRect.new()
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.texture = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_ICON_GUIDE)
	face_host.add_child(face)
	header.add_child(face_host)

	var header_col := VBoxContainer.new()
	header_col.add_theme_constant_override("separation", 4)
	header_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_col)

	var eyebrow := Label.new()
	eyebrow.text = "記録官ニーナの手引き"
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(eyebrow, UiTypography.SIZE_CAPTION, INK_GOLD, 0)
	header_col.add_child(eyebrow)

	_topic_label = Label.new()
	_topic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_topic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(_topic_label, UiTypography.SIZE_BODY_SMALL, INK_TITLE, 0)
	header_col.add_child(_topic_label)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_title_label)

	_body_scroll = ScrollContainer.new()
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_body_scroll.resized.connect(_sync_body_label_wrap_width)
	inner.add_child(_body_scroll)

	_body_label = RichTextLabel.new()
	_body_label.bbcode_enabled = true
	_body_label.fit_content = true
	_body_label.scroll_active = false
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_label.add_theme_color_override("default_color", INK_BODY)
	_body_label.add_theme_font_size_override("normal_font_size", 18)
	_body_label.add_theme_font_size_override("bold_font_size", 18)
	var body_font: Font = UiTypography.display_font()
	if body_font != null:
		_body_label.add_theme_font_override("normal_font", body_font)
		_body_label.add_theme_font_override("bold_font", body_font)
	_body_scroll.add_child(_body_label)

	_page_label = Label.new()
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(_page_label, UiTypography.SIZE_CAPTION, INK_META, 0)
	inner.add_child(_page_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.mouse_filter = Control.MOUSE_FILTER_STOP
	inner.add_child(btn_row)

	_skip_btn = Button.new()
	_skip_btn.text = "スキップ"
	_skip_btn.custom_minimum_size = Vector2(140, 48)
	_skip_btn.pressed.connect(_on_skip_pressed)
	UiTypography.apply_button(_skip_btn)
	btn_row.add_child(_skip_btn)

	_next_btn = Button.new()
	_next_btn.text = "次へ"
	_next_btn.custom_minimum_size = Vector2(160, 48)
	_next_btn.pressed.connect(_on_next_pressed)
	UiTypography.apply_button(_next_btn)
	btn_row.add_child(_next_btn)


func _refresh_page() -> void:
	if _pages.is_empty():
		return
	var page: Dictionary = _pages[_page_index] as Dictionary
	_title_label.text = str(page.get("title", ""))
	UiTypography.apply_display(_title_label, UiTypography.SIZE_DISPLAY, INK_TITLE, 0)
	_body_label.text = str(page.get("body", ""))
	_page_label.text = "%d / %d" % [_page_index + 1, _pages.size()]
	var last: bool = _page_index >= _pages.size() - 1
	_next_btn.text = "閉じる" if last else "次へ"
	## スキップは非表示ではなく透明（ページ高さのブレ防止）。
	_skip_btn.modulate.a = 0.0 if last else 1.0
	_skip_btn.disabled = last
	_skip_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE if last else Control.MOUSE_FILTER_STOP
	call_deferred("_sync_body_label_wrap_width")


func _sync_body_label_wrap_width() -> void:
	if _body_scroll == null or _body_label == null:
		return
	var w: float = _body_scroll.size.x
	if w > 4.0:
		_body_label.custom_minimum_size.x = w


func _play_intro() -> void:
	var anim_target: Control = _panel_shell if _panel_shell != null else _panel
	anim_target.modulate.a = 0.0
	anim_target.scale = Vector2(0.86, 0.86)
	anim_target.pivot_offset = PANEL_MIN * 0.5
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(anim_target, "modulate:a", 1.0, 0.16)
	_tween.parallel().tween_property(anim_target, "scale", Vector2(1.04, 1.04), 0.24).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_property(anim_target, "scale", Vector2.ONE, 0.1)


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_advance_or_close()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_advance_or_close()


func _on_next_pressed() -> void:
	_advance_or_close()


func _on_skip_pressed() -> void:
	_finish()


func _advance_or_close() -> void:
	if _page_index < _pages.size() - 1:
		_page_index += 1
		_refresh_page()
		AudioManager.play_sfx("ui_confirm", 0.9, 0.0)
		return
	_finish()


func _finish() -> void:
	if not _preview_only and not _flag_key.is_empty():
		GameState.tutorial_flags[_flag_key] = true
		SaveManager.save_game()
	AudioManager.play_sfx("ui_confirm")
	var p: Node = get_parent()
	if p != null:
		p.remove_child(self)
	dismissed.emit()
	queue_free()
