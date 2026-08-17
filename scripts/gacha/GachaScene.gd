extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"
const _GachaLimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")
const _GachaRevealPresenter := preload("res://scripts/gacha/GachaRevealPresenter.gd")
const _GachaEquipSystem := preload("res://scripts/gacha/GachaEquipSystem.gd")
const _ChrIdlePortraitView := preload("res://scripts/ui/ChrIdlePortraitView.gd")
const _RoomGuide := preload("res://scripts/ui/DungeonRouteGuideOverlay.gd")
const _ShopOverlay := preload("res://scripts/ui/ShopOverlay.gd")

const PAGE_INVITE: int = 0
const PAGE_SEAL: int = 1

const COLOR_NEW: Color = Color(0.95, 0.78, 0.35)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_OWNED: Color = Color(0.55, 0.88, 0.5)
const FEATURED_ROTATE_SEC: float = 5.0
const FEATURED_CROSSFADE_SEC: float = 0.3
const REVEAL_IDLE_PX: float = 280.0
const REVEAL_PANEL_HALF_W: float = 320.0
const REVEAL_PANEL_HALF_H: float = 540.0
const REVEAL_CONFETTI_NEW: int = 72
const REVEAL_CONFETTI_DUP: int = 48

@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _token_icon: TextureRect = $Header/HeaderRow/TokenChip/TokenRow/TokenIcon
@onready var _hero_banner: PanelContainer = $MainColumn/HeroBanner
@onready var _banner_art_host: Control = $MainColumn/HeroBanner/BannerVBox/BannerArtHost
@onready var _label_catchcopy: Label = $MainColumn/HeroBanner/BannerVBox/LabelCatchcopy
@onready var _label_rate: Label = $MainColumn/HeroBanner/BannerVBox/RateRow/LabelRate
@onready var _btn_rate_detail: Button = $MainColumn/HeroBanner/BannerVBox/RateRow/BtnRateDetail
@onready var _lineup_carousel_scroll: ScrollContainer = $MainColumn/LineupCarouselScroll
@onready var _detail_overlay: Control = $DetailOverlay
@onready var _detail_dim: ColorRect = $DetailOverlay/Dim
@onready var _detail_panel: PanelContainer = $DetailOverlay/DetailPanel
@onready var _lineup_container: VBoxContainer = $DetailOverlay/DetailPanel/DetailVBox/LineupScrollContainer/LineupContainer
@onready var _btn_detail_close: Button = $DetailOverlay/DetailPanel/DetailVBox/DetailHeader/BtnDetailClose
@onready var _label_result: Label = $SummonActionBar/LabelResult
@onready var _button_pull: Button = $SummonActionBar/PullRow/ButtonPull
@onready var _button_pull_ticket: Button = $SummonActionBar/PullRow/ButtonPullTicket
@onready var _summon_layer: CanvasLayer = $SummonRevealLayer
@onready var _summon_dim: ColorRect = $SummonRevealLayer/Dim
@onready var _invite_glow: TextureRect = $SummonRevealLayer/InviteGlow
@onready var _reveal_panel: PanelContainer = $SummonRevealLayer/RevealPanel
@onready var _invite_art: TextureRect = $SummonRevealLayer/RevealPanel/RevealVBox/InviteArt
@onready var _flash_icon: TextureRect = $SummonRevealLayer/RevealPanel/RevealVBox/FlashIcon
@onready var _portrait_frame: PanelContainer = $SummonRevealLayer/RevealPanel/RevealVBox/PortraitFrame
@onready var _portrait_icon: TextureRect = $SummonRevealLayer/RevealPanel/RevealVBox/PortraitFrame/PortraitIcon
@onready var _label_banner: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelBanner
@onready var _label_reveal_name: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelRevealName
@onready var _label_reveal_sub: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelRevealSub
@onready var _label_tap_hint: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelTapHint

var _label_quote: Label = null
## 封蔵（装備）リビール専用: 名前横のレアリティ色文字／分類／ステータス／効果。
var _label_reveal_rarity: Label = null
var _label_reveal_category: Label = null
var _equip_meta_row: HBoxContainer = null
var _equip_reveal_extra: VBoxContainer = null
var _equip_stats_host: VBoxContainer = null
var _equip_effect_lbl: Label = null
## 封蔵アイコンは招待状の Idle 立ち絵より小さく表示。
const EQUIP_REVEAL_ICON_PX: float = 140.0
const EQUIP_REVEAL_TEXT_PX: int = 14
var _summon_active: bool = false
var _summon_can_dismiss: bool = false
var _summon_tween: Tween = null
var _reveal_presenter: RefCounted = null
var _reveal_idle: Control = null
var _confetti_host: Control = null
var _featured_helper_id: String = ""
var _featured_helpers: Array = []
var _featured_equip_entries: Array = []
var _featured_index: int = 0
var _featured_shell: Dictionary = {}
var _featured_timer: Timer = null
var _featured_tween: Tween = null
var _featured_animating: bool = false
var _reveal_is_new: bool = false
var _gacha_page: int = PAGE_INVITE
var _btn_page_prev: Button = null
var _btn_page_next: Button = null
var _pool_marquee_active: bool = false
var _pool_marquee_loop_w: float = 0.0
const POOL_MARQUEE_SPEED: float = 36.0
## ロゴ帯付近（枠上端から）にページ矢印を置く。
const PAGE_ARROW_TOP: float = 20.0
const PAGE_ARROW_SIZE: float = 56.0
var _pending_equip_reveal: Dictionary = {}

var _pull_confirm: ConfirmationDialog
var _pending_pull_ticket: bool = false
## 確認ダイアログ表示時点のページ（←→切替で消費系統がズレないように固定）。
var _pending_pull_page: int = PAGE_INVITE
var _pull_confirm_open: bool = false
var _btn_room_guide: Button = null


func _ready() -> void:
	if not Constants.are_gacha_helpers_playable():
		# オミット中は拠点へ戻す（ナビ直リンク等の保険）
		SceneRouter.change_scene(HOME_SCENE)
		return
	AudioManager.play_bgm("gacha")
	_setup_gacha_chrome()
	_setup_shop_entry()
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.GACHA)
	_btn_back.pressed.connect(_on_back_pressed)
	_btn_rate_detail.pressed.connect(_on_rate_detail_pressed)
	_btn_detail_close.pressed.connect(_on_detail_close_pressed)
	_detail_dim.gui_input.connect(_on_detail_dim_input)
	_button_pull.pressed.connect(_on_pull_pressed)
	_button_pull_ticket.pressed.connect(_on_pull_ticket_pressed)
	_summon_dim.gui_input.connect(_on_summon_overlay_input)
	_reveal_panel.gui_input.connect(_on_summon_overlay_input)
	_portrait_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_setup_reveal_idle()
	_setup_reveal_quote_label()
	_setup_reveal_rarity_label()
	_setup_equip_reveal_extra()
	_setup_confetti_host()
	_setup_reveal_presenter()
	_setup_pull_confirm()
	## Featured が BannerArtHost を清空するため、矢印はシェル構築のあと。
	_setup_featured_preview()
	_setup_page_arrows()
	_setup_room_guide_help()
	call_deferred("_finalize_gacha_layout")
	_summon_layer.visible = false
	_detail_overlay.visible = false
	_refresh()
	call_deferred("_try_show_room_guide")


func _room_guide_id() -> String:
	return _RoomGuide.GUIDE_GACHA_SEAL if _is_seal_page() else _RoomGuide.GUIDE_GACHA_INVITE


func _setup_room_guide_help() -> void:
	var row: Control = $Header/HeaderRow as Control
	if row == null or row.get_node_or_null("HubRoomGuideHelpBtn") != null:
		return
	## 右端は封蔵切替→と被るので、戻るの直後（左）に置く。
	_btn_room_guide = _RoomGuide.attach_help_button(row, self, _room_guide_id(), "？")
	if _btn_room_guide == null:
		return
	var back: Node = row.get_node_or_null("ButtonBack")
	if back != null:
		row.move_child(_btn_room_guide, back.get_index() + 1)
	_btn_room_guide.custom_minimum_size = Vector2(40, 40)
	_btn_room_guide.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _sync_room_guide_help() -> void:
	_RoomGuide.set_help_guide_id(_btn_room_guide, _room_guide_id())


func _try_show_room_guide() -> void:
	if _summon_active or _pull_confirm_open:
		return
	_RoomGuide.try_auto_show(self, _room_guide_id())


func _setup_pull_confirm() -> void:
	_pull_confirm = ConfirmationDialog.new()
	_pull_confirm.title = "招待状"
	_pull_confirm.ok_button_text = "引く"
	_pull_confirm.cancel_button_text = "やめる"
	_pull_confirm.confirmed.connect(_on_pull_confirmed)
	_pull_confirm.canceled.connect(_on_pull_canceled)
	add_child(_pull_confirm)


func _setup_page_arrows() -> void:
	## Featured 再構築で queue_free された参照が残ると再生成されない。
	if not is_instance_valid(_btn_page_prev):
		_btn_page_prev = null
	if not is_instance_valid(_btn_page_next):
		_btn_page_next = null
	if _btn_page_prev != null and _btn_page_next != null:
		_raise_page_arrows()
		return
	if _btn_page_prev != null:
		_btn_page_prev.queue_free()
		_btn_page_prev = null
	if _btn_page_next != null:
		_btn_page_next.queue_free()
		_btn_page_next = null
	_btn_page_prev = Button.new()
	_btn_page_prev.name = "BtnGachaPagePrev"
	_btn_page_prev.text = "←"
	_btn_page_prev.focus_mode = Control.FOCUS_NONE
	_btn_page_prev.custom_minimum_size = Vector2(PAGE_ARROW_SIZE, PAGE_ARROW_SIZE)
	_btn_page_prev.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_btn_page_prev.offset_left = 8
	_btn_page_prev.offset_right = 8 + PAGE_ARROW_SIZE
	_btn_page_prev.offset_top = PAGE_ARROW_TOP
	_btn_page_prev.offset_bottom = PAGE_ARROW_TOP + PAGE_ARROW_SIZE
	_btn_page_prev.z_index = 40
	_btn_page_prev.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_page_prev.pressed.connect(_on_page_prev_pressed)
	_banner_art_host.add_child(_btn_page_prev)
	_btn_page_next = Button.new()
	_btn_page_next.name = "BtnGachaPageNext"
	_btn_page_next.text = "→"
	_btn_page_next.focus_mode = Control.FOCUS_NONE
	_btn_page_next.custom_minimum_size = Vector2(PAGE_ARROW_SIZE, PAGE_ARROW_SIZE)
	_btn_page_next.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_page_next.offset_left = -(8 + PAGE_ARROW_SIZE)
	_btn_page_next.offset_right = -8
	_btn_page_next.offset_top = PAGE_ARROW_TOP
	_btn_page_next.offset_bottom = PAGE_ARROW_TOP + PAGE_ARROW_SIZE
	_btn_page_next.z_index = 40
	_btn_page_next.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_page_next.pressed.connect(_on_page_next_pressed)
	_banner_art_host.add_child(_btn_page_next)
	_raise_page_arrows()


func _raise_page_arrows() -> void:
	if _banner_art_host == null:
		return
	if is_instance_valid(_btn_page_prev):
		_banner_art_host.move_child(_btn_page_prev, -1)
		_btn_page_prev.visible = true
	if is_instance_valid(_btn_page_next):
		_banner_art_host.move_child(_btn_page_next, -1)
		_btn_page_next.visible = true


func _on_page_prev_pressed() -> void:
	if _summon_active or _pull_confirm_open:
		return
	AudioManager.play_sfx("ui_click")
	_set_gacha_page(PAGE_INVITE if _gacha_page == PAGE_SEAL else PAGE_SEAL)


func _on_page_next_pressed() -> void:
	if _summon_active or _pull_confirm_open:
		return
	AudioManager.play_sfx("ui_click")
	_set_gacha_page(PAGE_SEAL if _gacha_page == PAGE_INVITE else PAGE_INVITE)


func _set_gacha_page(page: int) -> void:
	_gacha_page = page
	_featured_index = 0
	_featured_helper_id = ""
	_sync_pool_strip_for_page()
	_reload_featured_content(true)
	_sync_room_guide_help()
	_refresh()
	call_deferred("_try_show_room_guide")


func _is_seal_page() -> bool:
	return _gacha_page == PAGE_SEAL


func _sync_pool_strip_for_page() -> void:
	if _featured_shell.is_empty():
		return
	var strip: Control = _featured_shell.get("pool_strip") as Control
	if strip == null:
		return
	_stop_pool_marquee()
	if _is_seal_page():
		GachaUiHelper.fill_pool_strip_equipment(strip)
		strip.visible = true
		_wire_pool_icon_buttons()
		if strip is ScrollContainer:
			ScrollTouchHelper.enable(strip as ScrollContainer, false)
			if not strip.gui_input.is_connected(_on_pool_strip_gui_input):
				strip.gui_input.connect(_on_pool_strip_gui_input)
		GachaUiHelper.set_equip_icon_back_visible(_featured_shell, true)
		GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
		call_deferred("_start_pool_marquee")
	else:
		GachaUiHelper.fill_pool_strip_helpers(strip)
		strip.visible = true
		_wire_pool_icon_buttons()
		GachaUiHelper.set_equip_icon_back_visible(_featured_shell, false)
		GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)


func _on_pool_strip_gui_input(event: InputEvent) -> void:
	## 手動ドラッグ中は自動スクロールを一時停止。
	if event is InputEventScreenDrag:
		_pause_pool_marquee_temporarily()
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask != 0:
		_pause_pool_marquee_temporarily()


func _pause_pool_marquee_temporarily() -> void:
	if not _is_seal_page():
		return
	_pool_marquee_active = false
	set_process(false)
	if has_meta("_pool_marquee_resume_queued") and bool(get_meta("_pool_marquee_resume_queued")):
		return
	set_meta("_pool_marquee_resume_queued", true)
	get_tree().create_timer(1.6).timeout.connect(_resume_pool_marquee_after_drag)


func _resume_pool_marquee_after_drag() -> void:
	set_meta("_pool_marquee_resume_queued", false)
	if _is_seal_page():
		_start_pool_marquee()


func _start_pool_marquee() -> void:
	if not _is_seal_page() or _featured_shell.is_empty():
		_stop_pool_marquee()
		return
	var strip: Control = _featured_shell.get("pool_strip") as Control
	var loop_w: float = GachaUiHelper.pool_marquee_loop_width(strip)
	if loop_w < 8.0:
		## レイアウト未確定のときは再試行。
		call_deferred("_retry_pool_marquee_width")
		return
	_pool_marquee_loop_w = loop_w
	_pool_marquee_active = true
	set_process(true)


func _retry_pool_marquee_width() -> void:
	if not _is_seal_page() or _featured_shell.is_empty():
		return
	var strip: Control = _featured_shell.get("pool_strip") as Control
	if strip != null:
		var row: Control = strip.get_node_or_null("PoolIconRow") as Control
		if row != null:
			row.queue_sort()
	var loop_w: float = GachaUiHelper.pool_marquee_loop_width(strip)
	if loop_w < 8.0:
		_pool_marquee_active = false
		set_process(false)
		return
	_pool_marquee_loop_w = loop_w
	_pool_marquee_active = true
	set_process(true)

func _stop_pool_marquee() -> void:
	_pool_marquee_active = false
	set_process(false)
	if _featured_shell.is_empty():
		return
	var strip: Control = _featured_shell.get("pool_strip") as Control
	if strip is ScrollContainer:
		(strip as ScrollContainer).scroll_horizontal = 0


func _process(delta: float) -> void:
	if not _pool_marquee_active or _featured_shell.is_empty():
		return
	var strip: Control = _featured_shell.get("pool_strip") as Control
	if not strip is ScrollContainer:
		return
	var sc: ScrollContainer = strip as ScrollContainer
	var next_x: float = float(sc.scroll_horizontal) + POOL_MARQUEE_SPEED * delta
	if next_x >= _pool_marquee_loop_w:
		next_x -= _pool_marquee_loop_w
	sc.scroll_horizontal = int(next_x)

func _setup_reveal_quote_label() -> void:
	if _label_quote != null:
		return
	var vbox := $SummonRevealLayer/RevealPanel/RevealVBox as VBoxContainer
	if vbox == null:
		return
	_label_quote = Label.new()
	_label_quote.name = "LabelQuote"
	_label_quote.visible = false
	_label_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_quote.clip_text = false
	_label_quote.custom_minimum_size = Vector2(0, 0)
	_label_quote.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(_label_quote, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	var insert_at: int = _label_reveal_name.get_index() + 1
	vbox.add_child(_label_quote)
	vbox.move_child(_label_quote, insert_at)


## 封蔵（装備）リビール専用: 名前の下にレアリティ＋分類（灰冠の九・武器 等）を横並びで出す。
func _setup_reveal_rarity_label() -> void:
	if _equip_meta_row != null:
		return
	var vbox := $SummonRevealLayer/RevealPanel/RevealVBox as VBoxContainer
	if vbox == null:
		return
	_equip_meta_row = HBoxContainer.new()
	_equip_meta_row.name = "EquipMetaRow"
	_equip_meta_row.visible = false
	_equip_meta_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_equip_meta_row.add_theme_constant_override("separation", 10)
	_equip_meta_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_reveal_rarity = Label.new()
	_label_reveal_rarity.name = "LabelRevealRarity"
	UiTypography.apply_display(_label_reveal_rarity, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	_equip_meta_row.add_child(_label_reveal_rarity)
	_label_reveal_category = Label.new()
	_label_reveal_category.name = "LabelRevealCategory"
	UiTypography.apply_body(_label_reveal_category, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
	_equip_meta_row.add_child(_label_reveal_category)
	var insert_at: int = _label_reveal_name.get_index() + 1
	vbox.add_child(_equip_meta_row)
	vbox.move_child(_equip_meta_row, insert_at)


## 封蔵（装備）リビール専用: ステータス・効果を表示するブロック。
func _setup_equip_reveal_extra() -> void:
	if _equip_reveal_extra != null:
		return
	var vbox := $SummonRevealLayer/RevealPanel/RevealVBox as VBoxContainer
	if vbox == null or _equip_meta_row == null:
		return
	_equip_reveal_extra = VBoxContainer.new()
	_equip_reveal_extra.name = "EquipRevealExtra"
	_equip_reveal_extra.visible = false
	_equip_reveal_extra.add_theme_constant_override("separation", 3)
	_equip_reveal_extra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_stats_host = VBoxContainer.new()
	_equip_stats_host.name = "EquipStatsHost"
	_equip_stats_host.add_theme_constant_override("separation", 0)
	_equip_stats_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_reveal_extra.add_child(_equip_stats_host)
	_equip_effect_lbl = Label.new()
	_equip_effect_lbl.name = "EquipEffectLabel"
	_equip_effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equip_effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(_equip_effect_lbl, UiTypography.SIZE_CAPTION, UiTypography.COLOR_BODY)
	_equip_effect_lbl.add_theme_font_size_override("font_size", EQUIP_REVEAL_TEXT_PX)
	_equip_reveal_extra.add_child(_equip_effect_lbl)
	var insert_at: int = _equip_meta_row.get_index() + 1
	vbox.add_child(_equip_reveal_extra)
	vbox.move_child(_equip_reveal_extra, insert_at)


func _setup_reveal_idle() -> void:
	_portrait_frame.custom_minimum_size = Vector2(REVEAL_IDLE_PX + 16.0, REVEAL_IDLE_PX + 16.0)
	if _portrait_icon != null:
		_portrait_icon.visible = false
	_reveal_idle = _ChrIdlePortraitView.new()
	_reveal_idle.name = "RevealIdle"
	_reveal_idle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_idle.offset_left = 8.0
	_reveal_idle.offset_top = 8.0
	_reveal_idle.offset_right = -8.0
	_reveal_idle.offset_bottom = -8.0
	if _reveal_idle.has_method("set_portrait_size"):
		_reveal_idle.call("set_portrait_size", REVEAL_IDLE_PX)
	_reveal_idle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_reveal_idle)


func _setup_confetti_host() -> void:
	_confetti_host = Control.new()
	_confetti_host.name = "ConfettiHost"
	_confetti_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confetti_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summon_layer.add_child(_confetti_host)

func _setup_reveal_presenter() -> void:
	_reveal_presenter = _GachaRevealPresenter.new()
	_reveal_presenter.bind(
		self,
		_summon_dim,
		_reveal_panel,
		_invite_glow,
		_invite_art,
		_flash_icon,
		_portrait_frame,
		[_label_banner, _label_reveal_name, _label_quote, _label_reveal_sub, _label_tap_hint],
		GachaUiTokens.load_tex(GachaUiTokens.INVITE_SEALED),
		GachaUiTokens.load_tex(GachaUiTokens.INVITE_SEALED_STAR2),
		GachaUiTokens.load_tex(GachaUiTokens.INVITE_OPENING)
	)

func _setup_shop_entry() -> void:
	var chip: Control = $Header/HeaderRow/TokenChip as Control
	if chip == null:
		return
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.tooltip_text = "ショップ"
	if not chip.gui_input.is_connected(_on_token_chip_input):
		chip.gui_input.connect(_on_token_chip_input)


func _on_token_chip_input(event: InputEvent) -> void:
	var pressed: bool = (
		(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if not pressed:
		return
	var chip: Control = $Header/HeaderRow/TokenChip as Control
	if chip != null:
		chip.accept_event()
	_open_shop()


func _open_shop() -> void:
	var shop: Node = _ShopOverlay.present(self)
	if shop == null:
		return
	var sig: Signal = shop.get("tokens_changed")
	if not sig.is_connected(_refresh):
		sig.connect(_refresh)


func _shop_is_open() -> bool:
	var shop: Node = get_node_or_null("ShopOverlay")
	return shop != null and bool(shop.get("visible"))


func _setup_gacha_chrome() -> void:
	_setup_gacha_atmosphere()
	HeaderCurrencyHelper.apply_to_row($Header/HeaderRow)
	## 枠上のロゴが正。ヘッダ文言「ギルドへの招待状」は出さない（スペーサのみ）。
	_label_title.text = ""
	$DetailOverlay/DetailPanel/DetailVBox/DetailHeader/LabelDetailTitle.text = (
		GachaUiTokens.LINEUP_SECTION_TITLE
	)
	var back_tex: Texture2D = GachaUiTokens.back_icon()
	if back_tex != null:
		_btn_back.text = ""
		_btn_back.icon = back_tex
		_btn_back.expand_icon = true
		_btn_back.custom_minimum_size = Vector2(40, 40)
	var token_tex: Texture2D = GachaUiTokens.token_icon()
	if token_tex != null:
		_token_icon.texture = token_tex
		_flash_icon.texture = token_tex
	_hero_banner.add_theme_stylebox_override("panel", GachaUiTokens.banner_frame_style())
	_detail_panel.add_theme_stylebox_override("panel", GachaUiTokens.panel_dark_style())
	_reveal_panel.add_theme_stylebox_override("panel", GachaUiTokens.reveal_frame_style())
	_layout_reveal_panel()
	_flatten_banner_art_frame()
	GachaUiHelper.setup_banner_header(
		$MainColumn/HeroBanner/BannerVBox as VBoxContainer,
		_label_catchcopy
	)
	GachaUiHelper.setup_pull_button(_button_pull, true)
	GachaUiHelper.setup_ticket_pull_button(_button_pull_ticket, true)
	_apply_button_style(_btn_rate_detail, GachaUiTokens.detail_button_style())
	_apply_button_style(_btn_detail_close, GachaUiTokens.detail_button_style())
	UiTypography.apply_body(_label_result, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_display(_label_banner, UiTypography.SIZE_DISPLAY_TITLE)
	UiTypography.apply_display(_label_reveal_name, UiTypography.SIZE_BODY, UiTypography.COLOR_BODY)
	if _label_quote != null:
		UiTypography.apply_display(_label_quote, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_reveal_sub, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
	UiTypography.apply_caption(_label_tap_hint, UiTypography.COLOR_MUTED)
	UiTypography.apply_caption(_label_rate)
	UiTypography.apply_display(
		$DetailOverlay/DetailPanel/DetailVBox/DetailHeader/LabelDetailTitle,
		UiTypography.SIZE_BODY_SMALL
	)


## 入手フレームを画面中央に大きく配置（720×1280 想定）。
func _layout_reveal_panel() -> void:
	if _reveal_panel == null:
		return
	_reveal_panel.set_anchors_preset(Control.PRESET_CENTER)
	_reveal_panel.offset_left = -REVEAL_PANEL_HALF_W
	_reveal_panel.offset_right = REVEAL_PANEL_HALF_W
	_reveal_panel.offset_top = -REVEAL_PANEL_HALF_H
	_reveal_panel.offset_bottom = REVEAL_PANEL_HALF_H
	_reveal_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_reveal_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var vbox := $SummonRevealLayer/RevealPanel/RevealVBox as VBoxContainer
	if vbox != null:
		vbox.add_theme_constant_override("separation", 12)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	if _invite_art != null:
		_invite_art.custom_minimum_size = Vector2(360, 250)
	if _portrait_frame != null:
		_portrait_frame.custom_minimum_size = Vector2(REVEAL_IDLE_PX + 24.0, REVEAL_IDLE_PX + 24.0)


## 確率行などを枠外へ出し、HeroBanner 内はキーアート＋タイトルのみ（黒余白なし）。
func _flatten_banner_art_frame() -> void:
	var vbox := $MainColumn/HeroBanner/BannerVBox as VBoxContainer
	var main := $MainColumn as VBoxContainer
	if vbox == null or main == null:
		return
	var insert_at: int = _hero_banner.get_index() + 1
	for node_name in ["LabelCatchcopy", "RateRow", "LabelPeriod"]:
		var n: Node = vbox.get_node_or_null(node_name)
		if n == null:
			continue
		vbox.remove_child(n)
		main.add_child(n)
		main.move_child(n, insert_at)
		insert_at += 1
	## ArtHost だけが枠内に残り、縦いっぱいに伸びる。
	_banner_art_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	## 実機で台座キャラが確実に入る高さ。
	_banner_art_host.custom_minimum_size = Vector2(0, 320)
	_banner_art_host.clip_contents = false


## 画面全体は落ち着いた暗背景。聖堂キーアートは招待枠内（Banner_BG）のみ。
func _setup_gacha_atmosphere() -> void:
	var stale := get_node_or_null("GachaAtmosphere")
	if stale != null:
		stale.queue_free()
	## 全画面 UI_BG_Gacha は枠内キーアートと二重になるため使わない。
	var bg := get_node_or_null("BgTexture") as TextureRect
	if bg != null:
		bg.visible = false
		bg.texture = null
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flat := get_node_or_null("BgFlat") as ColorRect
	if flat == null:
		flat = ColorRect.new()
		flat.name = "BgFlat"
		flat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		flat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flat.z_index = -20
		add_child(flat)
		move_child(flat, 0)
	flat.color = Color(0.035, 0.03, 0.055, 1.0)
	flat.visible = true


func _apply_button_style(btn: Button, style: StyleBox) -> void:
	if style is StyleBoxTexture and (style as StyleBoxTexture).texture != null:
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)


func _refresh() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()
	## 枠上ロゴが正。ヘッダ中央タイトルは出さない（封蔵・招待とも）。
	_label_title.text = ""
	if _is_seal_page():
		_label_rate.text = _GachaEquipSystem.rate_display_text()
		_label_catchcopy.text = _GachaEquipSystem.catchcopy()
		_pull_confirm.title = "封じられし武庫"
		_button_pull_ticket.visible = true
		$DetailOverlay/DetailPanel/DetailVBox/DetailHeader/LabelDetailTitle.text = "封蔵の排出"
	else:
		_label_rate.text = GachaSystem.rate_display_text()
		_label_catchcopy.text = GachaUiHelper.catchcopy()
		_pull_confirm.title = "招待状"
		_button_pull_ticket.visible = true
		$DetailOverlay/DetailPanel/DetailVBox/DetailHeader/LabelDetailTitle.text = (
			GachaUiTokens.LINEUP_SECTION_TITLE
		)
	_set_pull_controls_enabled(not _summon_active)
	if _is_seal_page():
		GachaUiHelper.setup_pull_button_ex(
			_button_pull,
			not _button_pull.disabled,
			"匣を開く",
			_GachaEquipSystem.pull_cost()
		)
		GachaUiHelper.setup_seal_ticket_pull_button(
			_button_pull_ticket, not _button_pull_ticket.disabled
		)
	else:
		GachaUiHelper.setup_pull_button(_button_pull, not _button_pull.disabled)
		GachaUiHelper.setup_ticket_pull_button(_button_pull_ticket, not _button_pull_ticket.disabled)
	if not _summon_active:
		if _is_seal_page():
			var seal_n: int = TicketSystem.free_seal_qty()
			if seal_n > 0:
				_label_result.text = "封蔵開封券 ×%d（右ボタンで使用）" % seal_n
			elif _label_result.text.begins_with("封蔵開封券") or _label_result.text.begins_with("招待無料券"):
				_label_result.text = ""
		else:
			var free_n: int = TicketSystem.free_gacha_qty()
			if free_n > 0:
				_label_result.text = "招待無料券 ×%d（右ボタンで使用）" % free_n
			elif _label_result.text.begins_with("招待無料券") or _label_result.text.begins_with("封蔵開封券"):
				_label_result.text = ""
	_sync_featured_rotation_state()
	_rebuild_lineup()


func _setup_featured_preview() -> void:
	if _lineup_carousel_scroll != null:
		_lineup_carousel_scroll.visible = false
		_lineup_carousel_scroll.custom_minimum_size = Vector2.ZERO
	_banner_art_host.custom_minimum_size = Vector2(0, 320)
	_banner_art_host.clip_contents = false
	if _featured_shell.is_empty():
		_featured_shell = GachaUiHelper.build_featured_shell(_banner_art_host)
		_wire_pool_icon_buttons()
		if not _banner_art_host.gui_input.is_connected(_on_featured_host_input):
			_banner_art_host.gui_input.connect(_on_featured_host_input)
		if not _banner_art_host.resized.is_connected(_on_featured_host_resized):
			_banner_art_host.resized.connect(_on_featured_host_resized)
		call_deferred("_on_featured_host_resized")
	if _featured_timer == null:
		_featured_timer = Timer.new()
		_featured_timer.name = "FeaturedRotateTimer"
		_featured_timer.wait_time = FEATURED_ROTATE_SEC
		_featured_timer.one_shot = false
		_featured_timer.timeout.connect(_on_featured_rotate_timeout)
		add_child(_featured_timer)
	_reload_featured_content(true)


func _wire_pool_icon_buttons() -> void:
	if _featured_shell.is_empty():
		return
	var strip: Control = _featured_shell.get("pool_strip") as Control
	if strip == null:
		return
	var row: Node = strip.get_node_or_null("PoolIconRow")
	if row == null:
		return
	for child in row.get_children():
		if child is BaseButton:
			var btn: BaseButton = child as BaseButton
			if not btn.pressed.is_connected(_on_pool_icon_pressed):
				btn.pressed.connect(_on_pool_icon_pressed.bind(btn))


func _on_pool_icon_pressed(btn: BaseButton) -> void:
	if _summon_active or _featured_animating or btn == null:
		return
	if _is_seal_page():
		var item_id: String = str(btn.get_meta("item_id", ""))
		if item_id.is_empty():
			return
		for i in _featured_equip_entries.size():
			if str(_featured_equip_entries[i].get("id", "")) == item_id:
				_show_featured_at(i, true)
				if _featured_timer != null:
					_featured_timer.start()
				return
		## 防・飾など Featured 回転外も枠内プレビュー可。
		var entry: Dictionary = _GachaEquipSystem.pool_entry_by_id(item_id)
		if entry.is_empty() or _featured_shell.is_empty():
			return
		GachaUiHelper.apply_featured_equipment(_featured_shell, entry)
		GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
		if _featured_timer != null:
			_featured_timer.start()
		return
	var helper_id: String = str(btn.get_meta("helper_id", ""))
	if helper_id.is_empty():
		helper_id = str(btn.get_meta("item_id", ""))
	if helper_id.is_empty():
		return
	for i in _featured_helpers.size():
		if str(_featured_helpers[i].id) == helper_id:
			_show_featured_at(i, true)
			if _featured_timer != null:
				_featured_timer.start()
			return
	## ★2 など Featured 回転外も枠内プレビュー可。
	for helper in GachaUiHelper.sorted_helpers():
		if helper == null or str(helper.id) != helper_id:
			continue
		_featured_helper_id = helper_id
		if _featured_shell.is_empty():
			return
		GachaUiHelper.apply_featured_helper(_featured_shell, helper)
		GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
		if _featured_timer != null:
			_featured_timer.start()
		return

func _on_featured_host_resized() -> void:
	if _featured_shell.is_empty():
		return
	GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
	if _pool_marquee_active:
		var strip: Control = _featured_shell.get("pool_strip") as Control
		var loop_w: float = GachaUiHelper.pool_marquee_loop_width(strip)
		if loop_w >= 8.0:
			_pool_marquee_loop_w = loop_w


## Featured 枠と説明パネルを再レイアウト（chrome は BottomNavHelper／実機のみ）。
func _finalize_gacha_layout() -> void:
	_setup_page_arrows()

	## Mac では apply_chrome は no-op。ここでは Featured 再配置のみ。
	if _featured_shell.is_empty():
		return
	GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
	if _is_seal_page():
		if not _featured_equip_entries.is_empty():
			GachaUiHelper.apply_featured_equipment(
				_featured_shell,
				_featured_equip_entries[_featured_index]
			)
	else:
		GachaUiHelper.apply_featured_helper(
			_featured_shell,
			_featured_helpers[_featured_index] if not _featured_helpers.is_empty() else null
		)


func _reload_featured_content(force_show: bool = false) -> void:
	if _is_seal_page():
		_featured_equip_entries = _GachaEquipSystem.featured_entries()
		_featured_helpers = []
		if _featured_equip_entries.is_empty():
			_featured_index = 0
			_set_featured_timer_running(false)
			return
		_featured_index = posmod(_featured_index, _featured_equip_entries.size())
		_show_featured_at(_featured_index, false)
		if force_show:
			_sync_featured_rotation_state()
		return
	_reload_featured_helpers(force_show)


func _reload_featured_helpers(force_show: bool = false) -> void:
	_featured_helpers = GachaUiHelper.featured_helpers()
	_featured_equip_entries = []
	if _featured_helpers.is_empty():
		_featured_index = 0
		_featured_helper_id = ""
		_set_featured_timer_running(false)
		return
	var prefer_id: String = _featured_helper_id
	var idx: int = 0
	if not prefer_id.is_empty():
		for i in _featured_helpers.size():
			if str(_featured_helpers[i].id) == prefer_id:
				idx = i
				break
	_featured_index = idx
	_show_featured_at(_featured_index, false)
	if force_show:
		_sync_featured_rotation_state()


func _show_featured_at(index: int, animate: bool) -> void:
	if _featured_shell.is_empty():
		return
	if _is_seal_page():
		if _featured_equip_entries.is_empty():
			return
		var next_e: int = posmod(index, _featured_equip_entries.size())
		_featured_index = next_e
		var entry: Dictionary = _featured_equip_entries[next_e]
		var stage_e: Control = _featured_shell.get("stage") as Control
		var stats_e: Control = _featured_shell.get("stats_wrap") as Control
		var fade_e: Array[Control] = []
		if stage_e != null:
			fade_e.append(stage_e)
		if stats_e != null:
			fade_e.append(stats_e)
		if not animate:
			GachaUiHelper.apply_featured_equipment(_featured_shell, entry)
			GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
			for t in fade_e:
				t.modulate = Color(1, 1, 1, 1)
			return
		if _featured_animating:
			return
		_featured_animating = true
		if fade_e.is_empty():
			GachaUiHelper.apply_featured_equipment(_featured_shell, entry)
			_featured_animating = false
			return
		if _featured_tween != null and _featured_tween.is_valid():
			_featured_tween.kill()
		_featured_tween = create_tween()
		_featured_tween.set_parallel(true)
		for t2 in fade_e:
			_featured_tween.tween_property(t2, "modulate:a", 0.0, FEATURED_CROSSFADE_SEC * 0.5)
		_featured_tween.set_parallel(false)
		_featured_tween.tween_callback(func() -> void:
			GachaUiHelper.apply_featured_equipment(_featured_shell, entry)
			GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
		)
		_featured_tween.set_parallel(true)
		for t3 in fade_e:
			_featured_tween.tween_property(t3, "modulate:a", 1.0, FEATURED_CROSSFADE_SEC * 0.5)
		_featured_tween.set_parallel(false)
		_featured_tween.tween_callback(func() -> void:
			_featured_animating = false
		)
		return
	if _featured_helpers.is_empty():
		return
	var next_i: int = posmod(index, _featured_helpers.size())
	var helper: Resource = _featured_helpers[next_i]
	_featured_index = next_i
	_featured_helper_id = str(helper.id)
	var stage: Control = _featured_shell.get("stage") as Control
	var stats_wrap: Control = _featured_shell.get("stats_wrap") as Control
	## 背景・タイトルは固定。キャラ台座＋説明だけクロスフェードする。
	var fade_targets: Array[Control] = []
	if stage != null:
		fade_targets.append(stage)
	if stats_wrap != null:
		fade_targets.append(stats_wrap)
	if not animate:
		GachaUiHelper.apply_featured_helper(_featured_shell, helper)
		GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
		for t in fade_targets:
			t.modulate = Color(1, 1, 1, 1)
		return
	if _featured_animating:
		return
	_featured_animating = true
	if fade_targets.is_empty():
		GachaUiHelper.apply_featured_helper(_featured_shell, helper)
		_featured_animating = false
		return
	if _featured_tween != null and _featured_tween.is_valid():
		_featured_tween.kill()
	_featured_tween = create_tween()
	_featured_tween.set_parallel(true)
	for t in fade_targets:
		_featured_tween.tween_property(t, "modulate:a", 0.0, FEATURED_CROSSFADE_SEC * 0.5)
	_featured_tween.set_parallel(false)
	_featured_tween.tween_callback(func() -> void:
		GachaUiHelper.apply_featured_helper(_featured_shell, helper)
		GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
	)
	_featured_tween.set_parallel(true)
	for t in fade_targets:
		_featured_tween.tween_property(t, "modulate:a", 1.0, FEATURED_CROSSFADE_SEC * 0.5)
	_featured_tween.set_parallel(false)
	_featured_tween.tween_callback(func() -> void:
		_featured_animating = false
	)


func _advance_featured(manual: bool = false) -> void:
	var n: int = (
		_featured_equip_entries.size() if _is_seal_page() else _featured_helpers.size()
	)
	if n <= 1:
		return
	if _summon_active or _featured_animating:
		return
	_show_featured_at(_featured_index + 1, true)
	if manual and _featured_timer != null:
		_featured_timer.start()


func _on_featured_rotate_timeout() -> void:
	_advance_featured(false)


func _on_featured_host_input(event: InputEvent) -> void:
	if _summon_active:
		return
	var pressed: bool = (
		(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if pressed:
		_advance_featured(true)


func _set_featured_timer_running(running: bool) -> void:
	if _featured_timer == null:
		return
	var n: int = (
		_featured_equip_entries.size() if _is_seal_page() else _featured_helpers.size()
	)
	if running and n > 1 and not _summon_active:
		if _featured_timer.is_stopped():
			_featured_timer.start()
	else:
		_featured_timer.stop()


func _sync_featured_rotation_state() -> void:
	if _featured_shell.is_empty():
		_setup_featured_preview()
		return
	if _is_seal_page():
		if _featured_equip_entries.is_empty():
			_reload_featured_content(false)
	elif _featured_helpers.is_empty():
		_reload_featured_helpers(false)
	_set_featured_timer_running(not _summon_active)


func _set_pull_controls_enabled(enabled: bool) -> void:
	if _is_seal_page():
		_button_pull.disabled = not enabled
		_button_pull_ticket.disabled = not enabled or not _GachaEquipSystem.can_pull_with_ticket()
	else:
		_button_pull.disabled = not enabled
		_button_pull_ticket.disabled = not enabled or not GachaSystem.can_pull_with_ticket()
	_btn_back.disabled = not enabled
	_btn_rate_detail.disabled = not enabled
	if _btn_page_prev != null:
		_btn_page_prev.disabled = not enabled
	if _btn_page_next != null:
		_btn_page_next.disabled = not enabled
	for nav_btn in $BottomNav/NavRow.get_children():
		if nav_btn is Button:
			(nav_btn as Button).disabled = not enabled


func _rebuild_lineup() -> void:
	for child in _lineup_container.get_children():
		child.queue_free()
	if _is_seal_page():
		var rate_lbl := Label.new()
		rate_lbl.text = _GachaEquipSystem.rate_detail_text()
		rate_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiTypography.apply_caption(rate_lbl, UiTypography.COLOR_SUB)
		_lineup_container.add_child(rate_lbl)
		var head := Label.new()
		head.text = "— 灰冠限定（LEGEND内 60%）—"
		UiTypography.apply_body(head, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
		_lineup_container.add_child(head)
		var entries: Array = _GachaEquipSystem.POOL
		for entry in entries:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			_lineup_container.add_child(GachaUiHelper.make_equip_lineup_row(entry))
		var foot := Label.new()
		foot.text = "既存LEGEND %d件／Epic %d件（部位均等・一覧省略）" % [
			_GachaEquipSystem.other_l_pool_count(),
			_GachaEquipSystem.epic_pool_count(),
		]
		foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiTypography.apply_caption(foot, UiTypography.COLOR_MUTED)
		_lineup_container.add_child(foot)
		return
	var helpers: Array = GachaUiHelper.sorted_helpers()
	if helpers.is_empty():
		var lbl := Label.new()
		lbl.text = "（排出対象なし）"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lineup_container.add_child(lbl)
		return
	for helper in helpers:
		if helper == null:
			continue
		_lineup_container.add_child(GachaUiHelper.make_lineup_row(helper))


func _on_rate_detail_pressed() -> void:
	_detail_overlay.visible = true
	_set_page_arrows_visible(false)

func _on_detail_close_pressed() -> void:
	_detail_overlay.visible = false
	_set_page_arrows_visible(true)

func _on_detail_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_detail_overlay.visible = false
		_set_page_arrows_visible(true)
	elif event is InputEventScreenTouch and event.pressed:
		_detail_overlay.visible = false
		_set_page_arrows_visible(true)


func _set_page_arrows_visible(visible: bool) -> void:
	if _btn_page_prev != null:
		_btn_page_prev.visible = visible
	if _btn_page_next != null:
		_btn_page_next.visible = visible

func _on_pull_pressed() -> void:
	_ask_pull(false)


func _on_pull_ticket_pressed() -> void:
	_ask_pull(true)


func _ask_pull(use_ticket: bool) -> void:
	if _summon_active or _pull_confirm_open:
		return
	if _is_seal_page():
		if not GameState.can_add_equipment():
			_label_result.text = "装備袋がいっぱいです（%s）。鍛冶で分解してください。" % (
				GameState.equipment_inventory_count_label()
			)
			return
		if use_ticket:
			if not _GachaEquipSystem.can_pull_with_ticket():
				_label_result.text = "封蔵開封券が足りません。"
				return
			_pull_confirm.dialog_text = "封蔵開封券を1枚使って匣を開きますか？"
		else:
			if not _GachaEquipSystem.can_pull():
				_label_result.text = "%sが足りません。ショップで入手できます。" % CurrencyHelper.DISPLAY_NAME
				_open_shop()
				return
			_pull_confirm.dialog_text = "%s %d を使って匣を開きますか？" % [
				CurrencyHelper.DISPLAY_NAME, _GachaEquipSystem.PULL_COST,
			]
		_begin_pull_confirm(use_ticket)
		return
	if use_ticket:
		if not GachaSystem.can_pull_with_ticket():
			_label_result.text = "招待無料券が足りません。"
			return
		_pull_confirm.dialog_text = "招待無料券を1枚使って引きますか？"
	else:
		if not GachaSystem.can_pull():
			_label_result.text = "%sが足りません。ショップで入手できます。" % CurrencyHelper.DISPLAY_NAME
			_open_shop()
			return
		_pull_confirm.dialog_text = "%s %d を使って引きますか？" % [
			CurrencyHelper.DISPLAY_NAME, GachaSystem.PULL_COST,
		]
	_begin_pull_confirm(use_ticket)


func _begin_pull_confirm(use_ticket: bool) -> void:
	## 確認中はページ・再押下をロックし、確定時は開いたページで消費する。
	_pending_pull_ticket = use_ticket
	_pending_pull_page = _gacha_page
	_pull_confirm_open = true
	_set_featured_timer_running(false)
	_set_pull_controls_enabled(false)
	_pull_confirm.popup_centered()


func _on_pull_canceled() -> void:
	AudioManager.play_sfx("ui_cancel")
	_pull_confirm_open = false
	_set_pull_controls_enabled(true)
	_set_featured_timer_running(true)


func _on_pull_confirmed() -> void:
	_pull_confirm_open = false
	_start_pull(_pending_pull_ticket, _pending_pull_page)


func _start_pull(use_ticket: bool, page: int = -1) -> void:
	if _summon_active:
		return
	var pull_page: int = page if page >= 0 else _gacha_page
	if pull_page == PAGE_SEAL:
		var eq_result: Dictionary = _GachaEquipSystem.pull(use_ticket)
		SaveManager.save_game()
		if not bool(eq_result.get("ok", false)):
			var eq_reason: String = str(eq_result.get("reason", ""))
			if eq_reason == "no_ticket":
				_label_result.text = "封蔵開封券が足りません。"
			elif eq_reason == "no_token":
				_label_result.text = "%sが足りません。ショップで入手できます。" % CurrencyHelper.DISPLAY_NAME
				_open_shop()
			elif eq_reason == "inventory_full":
				_label_result.text = "装備袋がいっぱいです（%s）。鍛冶で分解してください。" % (
					GameState.equipment_inventory_count_label()
				)
			else:
				_label_result.text = "開封できませんでした。時間をおいて再度お試しください。"
			_set_pull_controls_enabled(true)
			_set_featured_timer_running(true)
			_refresh()
			return
		DailyMissionSystem.report_progress("gacha_pull")
		_play_equip_reveal(eq_result)
		return
	var result: Dictionary = GachaSystem.pull(use_ticket)
	SaveManager.save_game()
	if not bool(result.get("ok", false)):
		var reason: String = str(result.get("reason", ""))
		if reason == "no_ticket":
			_label_result.text = "招待無料券が足りません。"
		elif reason == "no_token":
			_label_result.text = "%sが足りません。ショップで入手できます。" % CurrencyHelper.DISPLAY_NAME
			_open_shop()
		else:
			_label_result.text = "招きを完了できませんでした。時間をおいて再度お試しください。"
		_set_pull_controls_enabled(true)
		_set_featured_timer_running(true)
		_refresh()
		return
	DailyMissionSystem.report_progress("gacha_pull")
	_play_summon_reveal(result)


func _play_equip_reveal(result: Dictionary) -> void:
	_summon_active = true
	_summon_can_dismiss = false
	_pending_equip_reveal = result.duplicate()
	_set_featured_timer_running(false)
	_set_pull_controls_enabled(false)
	_summon_layer.visible = true
	AudioManager.play_sfx("gacha_reveal")
	_reveal_is_new = true
	var name_str: String = str(result.get("display_name", ""))
	var rarity: int = clampi(int(result.get("rarity", Enums.Rarity.LEGENDARY)), 0, 4)
	_reveal_panel.add_theme_stylebox_override("panel", GachaUiTokens.reveal_equip_frame_style())
	_portrait_frame.custom_minimum_size = Vector2(EQUIP_REVEAL_ICON_PX + 16.0, EQUIP_REVEAL_ICON_PX + 16.0)
	if _reveal_idle != null and _reveal_idle.has_method("set_portrait_size"):
		_reveal_idle.call("set_portrait_size", EQUIP_REVEAL_ICON_PX)
	_populate_equip_reveal_content(result)
	_label_result.add_theme_color_override("font_color", COLOR_NEW)
	var pool_tag: String = str(result.get("pool", "kaiwan"))
	if pool_tag == "kaiwan":
		_label_result.text = "灰冠の武具を入手！ %s" % name_str
	elif pool_tag == "other_l":
		_label_result.text = "レジェンド装備を入手！ %s" % name_str
	else:
		_label_result.text = "エピック装備を入手！ %s" % name_str
	if _reveal_presenter == null:
		_setup_reveal_presenter()
	## 最小案: 演出は招待状と同フロー。封印／開封絵だけ匣に差替。
	_reveal_presenter.set_sealed_art(
		GachaUiTokens.load_tex(GachaUiTokens.CRATE_SEALED),
		GachaUiTokens.load_tex(GachaUiTokens.CRATE_SEALED),
		GachaUiTokens.load_tex(GachaUiTokens.CRATE_OPENING)
	)
	var on_done := func() -> void:
		_summon_can_dismiss = true
		## 結果確定（開封演出が終わった）タイミングで初めてステータス等を出す。
		if _equip_meta_row != null:
			_equip_meta_row.visible = true
		if _equip_reveal_extra != null:
			_equip_reveal_extra.visible = true
	var on_portrait := func() -> void:
		_spawn_reveal_confetti(REVEAL_CONFETTI_NEW)
	_reveal_presenter.play(rarity, on_done, on_portrait)


func _populate_equip_reveal_content(result: Dictionary) -> void:
	var kind: String = str(result.get("kind", ""))
	var item_id: String = str(result.get("item_id", ""))
	var item: Resource = result.get("instance", null)
	var name_str: String = str(result.get("display_name", item_id))
	if item != null:
		name_str = EquipmentItemDetailHelper.short_name(item, kind)
	var blurb: String = str(result.get("blurb", ""))
	var rarity: int = clampi(int(result.get("rarity", Enums.Rarity.LEGENDARY)), 0, 4)
	var pool_tag: String = str(result.get("pool", ""))
	_label_banner.visible = false
	_label_banner.text = ""
	_label_reveal_sub.visible = false
	_label_reveal_sub.text = ""
	var category_text: String = ""
	match pool_tag:
		"kaiwan":
			category_text = "灰冠の九・%s" % _GachaEquipSystem.kind_label(kind)
		"other_l":
			category_text = "既存レジェンド・%s" % _GachaEquipSystem.kind_label(kind)
		_:
			category_text = "エピック・%s" % _GachaEquipSystem.kind_label(kind)
	_label_reveal_name.text = name_str
	## 開封演出が終わるまでは非表示（_play_equip_reveal の on_done で表示する）。
	if _equip_meta_row != null:
		_equip_meta_row.visible = false
	if _label_reveal_rarity != null:
		_label_reveal_rarity.text = "EPIC" if rarity == Enums.Rarity.EPIC else "LEGEND"
		_label_reveal_rarity.add_theme_color_override(
			"font_color", BlacksmithUiHelper.rarity_name_color(rarity)
		)
	if _label_reveal_category != null:
		_label_reveal_category.text = category_text
	if _label_quote != null:
		_label_quote.text = ""
		_label_quote.visible = false
	var tex: Texture2D = IconPaths.get_icon_texture(item_id, kind)
	if _reveal_idle != null and _reveal_idle.has_method("set_static_texture") and tex != null:
		_reveal_idle.call("set_static_texture", tex)
	elif _portrait_icon != null:
		_portrait_icon.texture = tex
	_populate_equip_reveal_extra(item, kind, item_id, blurb)


## ステータス行のみ（封蔵リビール。説明文は出さない）。
func _populate_equip_reveal_extra(item: Resource, kind: String, _item_id: String, _blurb: String) -> void:
	if _equip_reveal_extra == null or _equip_stats_host == null:
		return
	## 表示自体は _play_equip_reveal 側の on_done で開封後に行う。ここでは中身だけ用意する。
	for child in _equip_stats_host.get_children():
		child.queue_free()
	if item != null:
		for row: Variant in EquipmentItemDetailHelper.stat_rows(item, kind):
			if not (row is Dictionary):
				continue
			var r: Dictionary = row
			var label: String = str(r.get("label", ""))
			var value: String = str(r.get("value", ""))
			var line: String = "%s %s" % [label, value] if not label.is_empty() else value
			var stat_lbl := Label.new()
			stat_lbl.text = line
			stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UiTypography.apply_body(stat_lbl, UiTypography.SIZE_CAPTION, UiTypography.COLOR_BODY)
			stat_lbl.add_theme_font_size_override("font_size", EQUIP_REVEAL_TEXT_PX)
			_equip_stats_host.add_child(stat_lbl)
	## 装備説明（effect / blurb）は結果画面では出さない。
	if _equip_effect_lbl != null:
		_equip_effect_lbl.text = ""
		_equip_effect_lbl.visible = false


func _play_summon_reveal(result: Dictionary) -> void:
	_summon_active = true
	_summon_can_dismiss = false
	_pending_equip_reveal.clear()
	_set_featured_timer_running(false)
	_set_pull_controls_enabled(false)
	_summon_layer.visible = true
	AudioManager.play_sfx("gacha_reveal")
	_reveal_panel.add_theme_stylebox_override("panel", GachaUiTokens.reveal_frame_style())
	_portrait_frame.custom_minimum_size = Vector2(REVEAL_IDLE_PX + 16.0, REVEAL_IDLE_PX + 16.0)
	if _reveal_idle != null and _reveal_idle.has_method("set_portrait_size"):
		_reveal_idle.call("set_portrait_size", REVEAL_IDLE_PX)
	if _equip_meta_row != null:
		_equip_meta_row.visible = false
	if _equip_reveal_extra != null:
		_equip_reveal_extra.visible = false

	var helper_id: String = str(result.get("helper_id", ""))
	var is_new: bool = bool(result.get("is_new", false))
	_reveal_is_new = is_new
	var refund: int = int(result.get("refund", 0))
	var breakthrough: int = int(result.get("breakthrough", 0))
	var breakthrough_gained: bool = bool(result.get("breakthrough_gained", false))
	var helper_data: Resource = DataRegistry.get_gacha_helper_data(helper_id)
	var name_str: String = helper_id if helper_data == null else str(helper_data.display_name)
	var rarity: int = int(helper_data.rarity) if helper_data != null else 3
	_populate_reveal_content(helper_id, is_new, refund, helper_data, breakthrough, breakthrough_gained)

	if is_new:
		_label_result.add_theme_color_override("font_color", COLOR_NEW)
		_label_result.text = "招きに応じた！ %s" % name_str
	else:
		_label_result.add_theme_color_override("font_color", COLOR_SUB)
		if breakthrough_gained:
			_label_result.text = "%s（限凸 +%d） → %s %d 還元" % [
				name_str, breakthrough, CurrencyHelper.DISPLAY_NAME, refund,
			]
		else:
			_label_result.text = "%s（上限） → %s %d 還元" % [
				name_str, CurrencyHelper.DISPLAY_NAME, refund,
			]

	if _reveal_presenter == null:
		_setup_reveal_presenter()
	_reveal_presenter.set_sealed_art(
		GachaUiTokens.load_tex(GachaUiTokens.INVITE_SEALED),
		GachaUiTokens.load_tex(GachaUiTokens.INVITE_SEALED_STAR2),
		GachaUiTokens.load_tex(GachaUiTokens.INVITE_OPENING)
	)
	var on_done := func() -> void:
		_summon_can_dismiss = true
	var on_portrait := func() -> void:
		_spawn_reveal_confetti(
			REVEAL_CONFETTI_NEW if _reveal_is_new else REVEAL_CONFETTI_DUP
		)
	_reveal_presenter.play(rarity, on_done, on_portrait)


func _on_summon_overlay_input(event: InputEvent) -> void:
	var pressed: bool = (
		(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if not pressed:
		return
	if not _summon_active:
		return
	if not _summon_can_dismiss and _reveal_presenter != null:
		if _reveal_presenter.request_skip():
			_summon_can_dismiss = true
		return
	if _summon_can_dismiss:
		_dismiss_summon_reveal()

func _dismiss_summon_reveal() -> void:
	if not _summon_active:
		return
	_summon_can_dismiss = false
	_clear_reveal_confetti()
	if _reveal_presenter != null:
		_reveal_presenter.kill()
	if _summon_tween != null and _summon_tween.is_valid():
		_summon_tween.kill()
	_summon_tween = create_tween()
	_summon_tween.tween_property(_summon_dim, "modulate:a", 0.0, 0.2)
	_summon_tween.parallel().tween_property(_reveal_panel, "modulate:a", 0.0, 0.2)
	_summon_tween.parallel().tween_property(_invite_glow, "modulate:a", 0.0, 0.2)
	_summon_tween.chain().tween_callback(func() -> void:
		_summon_layer.visible = false
		_summon_active = false
		_pending_equip_reveal.clear()
		_reload_featured_content(true)
		_refresh()
	)


func _spawn_reveal_confetti(piece_count: int) -> void:
	if _confetti_host == null:
		return
	_clear_reveal_confetti()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var area: Rect2 = get_viewport_rect()
	var width: float = maxf(area.size.x, 1.0)
	var height: float = maxf(area.size.y, 1.0)
	for _i: int in piece_count:
		var piece := ColorRect.new()
		piece.size = Vector2(rng.randf_range(5.0, 12.0), rng.randf_range(8.0, 18.0))
		piece.color = Color.from_hsv(rng.randf(), rng.randf_range(0.7, 1.0), 1.0, 0.95)
		piece.rotation = rng.randf_range(-0.9, 0.9)
		piece.position = Vector2(
			rng.randf_range(0.0, width),
			rng.randf_range(-40.0, height * 0.28)
		)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_confetti_host.add_child(piece)
		var drift_x: float = rng.randf_range(-140.0, 140.0)
		var fall_y: float = height + rng.randf_range(30.0, 90.0)
		var duration: float = rng.randf_range(1.1, 2.4)
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(piece, "position:y", fall_y, duration).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_IN
		)
		tw.tween_property(piece, "position:x", piece.position.x + drift_x, duration)
		tw.tween_property(piece, "rotation", piece.rotation + rng.randf_range(-2.8, 2.8), duration)
		tw.tween_property(piece, "modulate:a", 0.0, 0.45).set_delay(maxf(0.0, duration - 0.45))
		tw.chain().tween_callback(piece.queue_free)


func _clear_reveal_confetti() -> void:
	if _confetti_host == null:
		return
	for child in _confetti_host.get_children():
		child.queue_free()


## UI 監査用: 演出完了状態のリビールを即時表示（セーブ・通貨は変更しない）。
func preview_summon_reveal_for_audit(helper_id: String = "", is_new: bool = true) -> void:
	var hid: String = helper_id
	if hid.is_empty():
		var helpers: Array = GachaUiHelper.sorted_helpers()
		if not helpers.is_empty():
			hid = str(helpers[0].id)
	var helper_data: Resource = DataRegistry.get_gacha_helper_data(hid)
	var rarity: int = int(helper_data.rarity) if helper_data != null else 3
	var refund: int = GachaRarityConfig.get_refund(rarity) if not is_new else 0
	_reveal_is_new = is_new
	_populate_reveal_content(hid, is_new, refund, helper_data, 3 if not is_new else 0, not is_new)
	_summon_active = true
	_summon_can_dismiss = true
	_set_pull_controls_enabled(false)
	_summon_layer.visible = true
	_summon_dim.modulate = Color(1, 1, 1, 1)
	_reveal_panel.modulate = Color(1, 1, 1, 1)
	_invite_glow.visible = true
	_invite_glow.modulate = Color(1, 1, 1, _GachaRevealPresenter.glow_alpha_for(rarity))
	_invite_art.visible = false
	_flash_icon.visible = false
	_portrait_frame.visible = true
	_portrait_frame.scale = Vector2.ONE
	_portrait_frame.modulate = Color(1, 1, 1, 1)
	## バナー表示は _populate_reveal_content（新規のみ）に従う。
	_label_reveal_name.visible = true
	_label_reveal_sub.visible = true
	_label_tap_hint.visible = true
	_spawn_reveal_confetti(REVEAL_CONFETTI_NEW if is_new else REVEAL_CONFETTI_DUP)


func _populate_reveal_content(
	hid: String,
	is_new: bool,
	refund: int,
	helper_data: Resource,
	breakthrough: int = 0,
	breakthrough_gained: bool = false
) -> void:
	var name_str: String = hid if helper_data == null else str(helper_data.display_name)
	var job_id: String = str(helper_data.job_id) if helper_data != null else ""

	## 入手フレームに「仲間を獲得しました」焼込済みのためバナーは出さない。
	_label_banner.visible = false
	_label_banner.text = ""
	if is_new:
		_label_reveal_sub.text = "ロスターに追加されました"
	else:
		if refund > 0 and breakthrough_gained and breakthrough > 0:
			_label_reveal_sub.text = "限凸 +%d！  %s %d 還元" % [
				breakthrough, CurrencyHelper.DISPLAY_NAME, refund,
			]
		elif refund > 0 and breakthrough >= _GachaLimitBreak.MAX_BREAKTHROUGH:
			_label_reveal_sub.text = "限凸上限  %s %d 還元" % [CurrencyHelper.DISPLAY_NAME, refund]
		elif refund > 0:
			_label_reveal_sub.text = "%s %d 還元" % [CurrencyHelper.DISPLAY_NAME, refund]
		elif breakthrough_gained:
			_label_reveal_sub.text = "限凸 +%d" % breakthrough
		else:
			_label_reveal_sub.text = ""

	var name_line: String = name_str
	if breakthrough > 0:
		name_line = "%s（限凸 +%d）" % [name_str, breakthrough]
	var job_label: String = GachaUiHelper.job_display_name_for_helper(helper_data)
	if helper_data != null:
		_label_reveal_name.text = "%s\n%s  %s" % [
			name_line,
			RosterUiHelper.stars_text(int(helper_data.rarity)),
			job_label,
		]
	else:
		_label_reveal_name.text = name_line

	var quote: String = GachaUiHelper.summon_quote_for_helper(helper_data)
	if _label_quote != null:
		if quote.is_empty():
			_label_quote.text = ""
			_label_quote.visible = false
		else:
			_label_quote.text = "「%s」" % quote
			_label_quote.visible = true

	if _reveal_idle != null and _reveal_idle.has_method("set_from_helper_id"):
		_reveal_idle.call("set_from_helper_id", hid, job_id)
	elif _portrait_icon != null:
		var portrait_tex: Texture2D = helper_data.get_portrait_texture() if helper_data != null else null
		if portrait_tex == null:
			portrait_tex = IconPaths.get_icon_texture(job_id, "chr")
		_portrait_icon.texture = portrait_tex
	if not hid.is_empty():
		_featured_helper_id = hid
		for i in _featured_helpers.size():
			if str(_featured_helpers[i].id) == hid:
				_featured_index = i
				break

func _on_back_pressed() -> void:
	if _summon_active:
		_dismiss_summon_reveal()
		return
	if _shop_is_open():
		var shop: Node = get_node_or_null("ShopOverlay")
		if shop != null and shop.has_method("close"):
			shop.call("close")
		return
	if _detail_overlay.visible:
		_detail_overlay.visible = false
		return
	_go_to(HOME_SCENE)

func _go_to(path: String) -> void:
	if _summon_active:
		return
	if path == GACHA_SCENE:
		return
	if ResourceLoader.exists(path):
		SceneRouter.change_scene(path)
