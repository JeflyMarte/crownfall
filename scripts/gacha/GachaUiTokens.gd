class_name GachaUiTokens
extends RefCounted

## 招待状 UI chrome（P3-UI-GACHA / P3-GACHA-COPY-001）。ロジックは GachaSystem のまま。

const ROOT: String = "res://assets/ui/gacha_ui/"

const BG: String = ROOT + "UI_BG_Gacha.png"
## 招待枠（チケット上）内の聖堂キーアート。台座込み。
const BANNER_BG: String = ROOT + "UI_Gacha_Banner_BG.png"
## 招待枠上部のタイトル／キャッチコピー焼込プレート。
const BANNER_TITLE: String = ROOT + "UI_Gacha_Banner_Title.png"
const BANNER_CATCHCOPY_ART: String = ROOT + "UI_Gacha_Banner_Catchcopy.png"
## フィーチャーキャラ背後の紫光柱・塵（モック光柱。画面全体モヤではない）。
const FEATURED_BEAM: String = ROOT + "UI_Gacha_FeaturedBeam.png"
const FEATURED_MOTE: String = ROOT + "UI_Gacha_FeaturedMote.png"
const ORNAMENT_DIAMOND: String = ROOT + "UI_Ornament_Diamond.png"
const ICO_BACK: String = ROOT + "UI_Ico_Back_Gold.png"
const SECTION_RULE: String = ROOT + "UI_Gacha_SectionRule.png"
const BANNER_FRAME: String = ROOT + "UI_Gacha_Banner_Frame.png"
const BTN_1PULL: String = ROOT + "UI_Gacha_Btn_1Pull.png"
const BTN_1PULL_DISABLED: String = ROOT + "UI_Gacha_Btn_1Pull_Disabled.png"
const LINEUP_CELL: String = ROOT + "UI_Gacha_LineupCell.png"
const PANEL_DARK: String = ROOT + "UI_Gacha_Panel_Dark.png"
const BTN_DETAIL: String = ROOT + "UI_Gacha_Btn_Detail.png"
const ICO_TOKEN: String = ROOT + "ICO_Gacha_Token.png"
const REVEAL_FRAME: String = ROOT + "UI_Gacha_Reveal_Frame.png"
const INVITE_SEALED: String = ROOT + "UI_Gacha_Invite_Sealed.png"
const INVITE_SEALED_STAR2: String = ROOT + "UI_Gacha_Invite_Sealed_Star2.png"
const INVITE_OPENING: String = ROOT + "UI_Gacha_Invite_Opening.png"
const INVITE_OPEN_FRAME: String = ROOT + "UI_Gacha_Invite_OpenFrame.png"
const INVITE_GLOW: String = ROOT + "UI_Gacha_Invite_Glow.png"
const INVITE_SEAL_SHARD: String = ROOT + "UI_Gacha_Invite_SealShard.png"

const SCREEN_TITLE: String = "ギルドへの招待状"
const LINEUP_SECTION_TITLE: String = "招きの候補"
const BANNER_CATCHCOPY: String = "各地の探索者へ、ギルドからの招き"

const BANNER_MIN_HEIGHT: int = 280
## 招待枠内タイトル／キャッチコピー画像の表示高さ（幅は親に追従・アスペクト維持）。
const BANNER_TITLE_HEIGHT: int = 120
const BANNER_CATCHCOPY_HEIGHT: int = 48
const LINEUP_CELL_PX: int = 120
const PULL_BTN_HEIGHT: int = 88
const PULL_BTN_MIN_WIDTH: int = 220

static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func back_icon() -> Texture2D:
	return load_tex(ICO_BACK)

static func token_icon() -> Texture2D:
	return load_tex(ICO_TOKEN)

static func ornament_diamond() -> Texture2D:
	return load_tex(ORNAMENT_DIAMOND)

static func texture_stylebox(path: String, margins: Vector4i = Vector4i(12, 12, 12, 12)) -> StyleBoxTexture:
	var tex: Texture2D = load_tex(path)
	var sb := StyleBoxTexture.new()
	if tex == null:
		return sb
	sb.texture = tex
	sb.texture_margin_left = margins.x
	sb.texture_margin_top = margins.y
	sb.texture_margin_right = margins.z
	sb.texture_margin_bottom = margins.w
	sb.set_content_margin_all(8.0)
	return sb

static func banner_frame_style() -> StyleBox:
	## 枠線のみ（中央は塗らない）— 招待枠内の Banner_BG を隠さない。
	var sb: StyleBox = texture_stylebox(BANNER_FRAME, Vector4i(20, 18, 20, 22))
	if sb is StyleBoxTexture:
		var tex_sb := sb as StyleBoxTexture
		tex_sb.draw_center = false
		tex_sb.modulate_color = Color(1.05, 0.98, 0.88, 1.0)
		## 余白を抑えてキーアートを枠いっぱいに。
		tex_sb.set_content_margin_all(4.0)
	return sb

static func panel_dark_style() -> StyleBox:
	return texture_stylebox(PANEL_DARK, Vector4i(16, 14, 16, 14))

static func lineup_cell_style() -> StyleBox:
	return texture_stylebox(LINEUP_CELL, Vector4i(12, 12, 12, 28))

static func pull_1_style() -> StyleBox:
	return texture_stylebox(BTN_1PULL, Vector4i(18, 14, 18, 14))

static func pull_disabled_style() -> StyleBox:
	var sb: StyleBox = texture_stylebox(BTN_1PULL_DISABLED, Vector4i(18, 14, 18, 14))
	if sb is StyleBoxTexture and (sb as StyleBoxTexture).texture != null:
		return sb
	return _fallback_pull_style(false)

static func detail_button_style() -> StyleBox:
	return texture_stylebox(BTN_DETAIL, Vector4i(12, 10, 12, 10))

static func reveal_frame_style() -> StyleBox:
	return texture_stylebox(REVEAL_FRAME, Vector4i(20, 20, 20, 20))

static func apply_pull_button(btn: Button, enabled: bool) -> void:
	var style: StyleBox = pull_1_style() if enabled else pull_disabled_style()
	if style is StyleBoxTexture and (style as StyleBoxTexture).texture == null:
		style = _fallback_pull_style(enabled)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", pull_disabled_style())
	btn.disabled = not enabled
	btn.custom_minimum_size = Vector2(PULL_BTN_MIN_WIDTH, PULL_BTN_HEIGHT)

static func decorate_title(label: Label) -> void:
	UiTypography.apply_screen_title(label, UiTypography.SIZE_DISPLAY)

static func _fallback_pull_style(enabled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.18, 0.34, 1.0) if enabled else Color(0.12, 0.11, 0.14, 0.9)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8.0)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.88, 0.72, 0.30, 0.9) if enabled else Color(0.35, 0.33, 0.38, 0.7)
	return sb
