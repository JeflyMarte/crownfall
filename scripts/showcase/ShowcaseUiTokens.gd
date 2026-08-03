class_name ShowcaseUiTokens
extends RefCounted

## 展示室 UI chrome（背景・構図座標）。720×1280 論理座標。

const ROOT: String = "res://assets/ui/showcase/"
const BG: String = ROOT + "UI_BG_Showcase.png"
const POWER_FRAME: String = ROOT + "UI_Showcase_PowerFrame.png"

## FIT 済みモック（元 863×1823）上の配置。
const BACK_RECT := Rect2(66, 36, 52, 52)
## 背景焼込の「自分の展示／スタッフ作例」ヒット領域。
const MODE_TAB_OWN := Rect2(78, 152, 282, 72)
const MODE_TAB_STAFF := Rect2(360, 152, 282, 72)
const MODE_ROW := Rect2(78, 152, 564, 72)
const EQUIP_RECT := Rect2(70, 175, 168, 580)
const STATS_RECT := Rect2(482, 175, 168, 460)
const IDLE_CENTER := Vector2(360, 688)
const IDLE_HOST_SIZE := Vector2(260, 320)
## 名前テキストのみ（枠なし）。台座下〜下ナビ上へ。
const FOOTER_RECT := Rect2(100, 1030, 520, 90)
## 総合戦力（名札上）。横幅は「自分の展示」タブと同寸。9-slice 禁止（黒マット伸び）。
const POWER_RECT := Rect2(222, 918, 282, 68)
## 名札枠上辺の欠けた横線を補完（焼込角飾り ≈ y1033・左右内側）。
const NAME_FRAME_TOP_RULE := Rect2(242, 1032, 236, 3)
## 自慢キャラ未設定時に背景焼込の名札枠を隠す覆い（BG切り抜き。黒塗り禁止）。
const NAME_FRAME_MASK_RECT := Rect2(120, 1015, 480, 135)
## 自分の展示：キャラ変更／スタッフ作例：スタッフキャラ（同位置・装備とステのあいだ）。
const CHANGE_MEMBER_RECT := Rect2(248, 248, 188, 44)
const STAFF_LIST_RECT := Rect2(248, 248, 188, 44)
const EMPTY_RECT := Rect2(90, 210, 540, 400)
const BODY_BOTTOM_PAD: float = 128.0
## 装備セル相対オフセット（パネル左上基準）。レア枠付きセル中央寄せ。
const EQUIP_ICON_OFFSETS: Array[Vector2] = [
	Vector2(44, 168),
	Vector2(44, 318),
	Vector2(44, 478),
]
## 装備品一覧に近い可読サイズ（レア枠・背景・N/R/E/L 表示）。
const EQUIP_CELL_PX: int = 80
## 個別ステは焼込見出し直下から（総合戦力は POWER_RECT）。
const STAT_HEADER_PAD: float = 142.0
const STAT_ROW_H: float = 45.0
const STAT_ICON_LEFT: float = 10.0
const STAT_ICON_PX: float = 26.0
const STAT_VALUE_LEFT: float = 44.0
const STAGE_IDLE_PX: float = 228.0
const STAT_VALUE_FONT_SIZE: int = 20
const STAT_POWER_FONT_SIZE: int = 24
const STAT_KEYS: Array[String] = [
	"hp",
	"attack",
	"defense",
	"speed",
	"crit_rate",
	"crit_damage",
]

## 選択中タブは暗く、非選択は明るめの金文字。
const COLOR_TAB_ACTIVE_BG := Color(0.02, 0.02, 0.04, 0.72)
const COLOR_TAB_INACTIVE_BG := Color(0.08, 0.10, 0.16, 0.28)
const COLOR_TAB_ACTIVE_BORDER := Color(0.55, 0.48, 0.28, 0.85)
const COLOR_TAB_INACTIVE_BORDER := Color(0.78, 0.68, 0.38, 0.55)
const COLOR_TAB_ACTIVE_FONT := Color(0.55, 0.50, 0.38, 1.0)
const COLOR_TAB_INACTIVE_FONT := Color(0.94, 0.86, 0.55, 1.0)
const COLOR_NAME_CARD_BG := Color(0.05, 0.04, 0.06, 1.0)
const COLOR_NAME_CARD_BORDER := Color(0.86, 0.72, 0.36, 1.0)


static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func power_frame_texture() -> Texture2D:
	## 黒マット付き枠は StyleBoxTexture 9-slice 禁止（角に黒が伸びる）。TextureRect 直置き。
	return load_tex(POWER_FRAME)


static func content_panel_style() -> StyleBoxEmpty:
	## 装備／ステは背景焼込枠を使う。Godot 側に枠・塗りを置かない。
	return StyleBoxEmpty.new()


static func name_card_style() -> StyleBoxEmpty:
	## キャラ名はテキストのみ（枠・塗りなし）。
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 4.0
	sb.content_margin_top = 2.0
	sb.content_margin_right = 4.0
	sb.content_margin_bottom = 2.0
	return sb


static func detail_panel_style() -> StyleBoxFlat:
	## 装備詳細オーバーレイ用（不透明カード）。
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_NAME_CARD_BG
	sb.draw_center = true
	sb.set_border_width_all(2)
	sb.border_color = COLOR_NAME_CARD_BORDER
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 14.0
	sb.content_margin_bottom = 10.0
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb


static func empty_panel_style() -> StyleBoxEmpty:
	## キャラ未設定の選択UI。黒カードは置かず余白だけ確保。
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 16.0
	sb.content_margin_top = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 16.0
	return sb


static func mode_tab_style(active: bool) -> StyleBoxFlat:
	## 自分の展示／スタッフ作例。選択中は暗くする。
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_TAB_ACTIVE_BG if active else COLOR_TAB_INACTIVE_BG
	sb.set_border_width_all(0)
	sb.border_color = COLOR_TAB_ACTIVE_BORDER if active else COLOR_TAB_INACTIVE_BORDER
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 10.0
	return sb


static func staff_chip_style(active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_TAB_ACTIVE_BG if active else Color(0.05, 0.05, 0.07, 0.88)
	sb.set_border_width_all(2 if active else 1)
	sb.border_color = COLOR_TAB_ACTIVE_BORDER if active else COLOR_TAB_INACTIVE_BORDER
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 10.0
	return sb


static func transparent_button_style() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()
