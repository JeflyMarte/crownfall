extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"
const _GachaLimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")
const _GachaRevealPresenter := preload("res://scripts/gacha/GachaRevealPresenter.gd")
const _ChrIdlePortraitView := preload("res://scripts/ui/ChrIdlePortraitView.gd")

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
var _summon_active: bool = false
var _summon_can_dismiss: bool = false
var _summon_tween: Tween = null
var _reveal_presenter: RefCounted = null
var _reveal_idle: Control = null
var _confetti_host: Control = null
var _featured_helper_id: String = ""
var _featured_helpers: Array = []
var _featured_index: int = 0
var _featured_shell: Dictionary = {}
var _featured_timer: Timer = null
var _featured_tween: Tween = null
var _featured_animating: bool = false
var _reveal_is_new: bool = false

var _pull_confirm: ConfirmationDialog
var _pending_pull_ticket: bool = false


func _ready() -> void:
	if not Constants.are_gacha_helpers_playable():
		# オミット中は拠点へ戻す（ナビ直リンク等の保険）
		SceneRouter.change_scene(HOME_SCENE)
		return
	_setup_gacha_chrome()
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
	_setup_confetti_host()
	_setup_reveal_presenter()
	_setup_featured_preview()
	_setup_pull_confirm()
	call_deferred("_finalize_gacha_layout")
	_summon_layer.visible = false
	_detail_overlay.visible = false
	_refresh()


func _setup_pull_confirm() -> void:
	_pull_confirm = ConfirmationDialog.new()
	_pull_confirm.title = "招待状"
	_pull_confirm.ok_button_text = "引く"
	_pull_confirm.cancel_button_text = "やめる"
	_pull_confirm.confirmed.connect(_on_pull_confirmed)
	_pull_confirm.canceled.connect(func() -> void: AudioManager.play_sfx("ui_cancel"))
	add_child(_pull_confirm)


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
	UiTypography.apply_display(_label_quote, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	var insert_at: int = _label_reveal_name.get_index() + 1
	vbox.add_child(_label_quote)
	vbox.move_child(_label_quote, insert_at)


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

func _setup_gacha_chrome() -> void:
	_setup_gacha_atmosphere()
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
		UiTypography.apply_display(_label_quote, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
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
	_label_rate.text = GachaSystem.rate_display_text()
	_label_catchcopy.text = GachaUiHelper.catchcopy()
	_set_pull_controls_enabled(not _summon_active)
	GachaUiHelper.setup_pull_button(_button_pull, not _button_pull.disabled)
	GachaUiHelper.setup_ticket_pull_button(_button_pull_ticket, not _button_pull_ticket.disabled)
	if not _summon_active:
		var free_n: int = TicketSystem.free_gacha_qty()
		if free_n > 0:
			_label_result.text = "招待無料券 ×%d（右ボタンで使用）" % free_n
		elif _label_result.text.begins_with("招待無料券"):
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
	_reload_featured_helpers(true)


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
	var helper_id: String = str(btn.get_meta("helper_id", ""))
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


## Featured 枠と説明パネルを再レイアウト（chrome は BottomNavHelper／実機のみ）。
func _finalize_gacha_layout() -> void:
	## Mac では apply_chrome は no-op。ここでは Featured 再配置のみ。
	if not _featured_shell.is_empty():
		GachaUiHelper.relayout_featured_shell(_featured_shell, _banner_art_host)
		GachaUiHelper.apply_featured_helper(
			_featured_shell,
			_featured_helpers[_featured_index] if not _featured_helpers.is_empty() else null
		)


func _reload_featured_helpers(force_show: bool = false) -> void:
	_featured_helpers = GachaUiHelper.featured_helpers()
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
	if _featured_helpers.is_empty() or _featured_shell.is_empty():
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
	if _featured_helpers.size() <= 1:
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
	if running and _featured_helpers.size() > 1 and not _summon_active:
		if _featured_timer.is_stopped():
			_featured_timer.start()
	else:
		_featured_timer.stop()


func _sync_featured_rotation_state() -> void:
	if _featured_shell.is_empty():
		_setup_featured_preview()
		return
	if _featured_helpers.is_empty():
		_reload_featured_helpers(false)
	_set_featured_timer_running(not _summon_active)


func _set_pull_controls_enabled(enabled: bool) -> void:
	_button_pull.disabled = not enabled or not GachaSystem.can_pull()
	_button_pull_ticket.disabled = not enabled or not GachaSystem.can_pull_with_ticket()
	_btn_back.disabled = not enabled
	_btn_rate_detail.disabled = not enabled
	for nav_btn in $BottomNav/NavRow.get_children():
		if nav_btn is Button:
			(nav_btn as Button).disabled = not enabled

func _rebuild_lineup() -> void:
	for child in _lineup_container.get_children():
		child.queue_free()
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

func _on_detail_close_pressed() -> void:
	_detail_overlay.visible = false

func _on_detail_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_detail_overlay.visible = false
	elif event is InputEventScreenTouch and event.pressed:
		_detail_overlay.visible = false

func _on_pull_pressed() -> void:
	_ask_pull(false)


func _on_pull_ticket_pressed() -> void:
	_ask_pull(true)


func _ask_pull(use_ticket: bool) -> void:
	if _summon_active:
		return
	if use_ticket:
		if not GachaSystem.can_pull_with_ticket():
			_label_result.text = "招待無料券が足りません。"
			return
		_pull_confirm.dialog_text = "招待無料券を1枚使って引きますか？"
	else:
		if not GachaSystem.can_pull():
			_label_result.text = "%sが足りません。" % CurrencyHelper.DISPLAY_NAME
			return
		_pull_confirm.dialog_text = "%s %d を使って引きますか？" % [
			CurrencyHelper.DISPLAY_NAME, GachaSystem.PULL_COST,
		]
	_pending_pull_ticket = use_ticket
	_pull_confirm.popup_centered()


func _on_pull_confirmed() -> void:
	_start_pull(_pending_pull_ticket)


func _start_pull(use_ticket: bool) -> void:
	if _summon_active:
		return
	var result: Dictionary = GachaSystem.pull(use_ticket)
	SaveManager.save_game()
	if not bool(result.get("ok", false)):
		var reason: String = str(result.get("reason", ""))
		if reason == "no_ticket":
			_label_result.text = "招待無料券が足りません。"
		elif reason == "no_token":
			_label_result.text = "%sが足りません。" % CurrencyHelper.DISPLAY_NAME
		else:
			_label_result.text = "招きに失敗しました（%s）。" % reason
		_refresh()
		return
	_play_summon_reveal(result)

func _play_summon_reveal(result: Dictionary) -> void:
	_summon_active = true
	_summon_can_dismiss = false
	_set_featured_timer_running(false)
	_set_pull_controls_enabled(false)
	_summon_layer.visible = true
	AudioManager.play_sfx("level_up")

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
			_label_result.text = "%s（限界突破 +%d） → %s %d 還元" % [
				name_str, breakthrough, CurrencyHelper.DISPLAY_NAME, refund,
			]
		else:
			_label_result.text = "%s（上限） → %s %d 還元" % [
				name_str, CurrencyHelper.DISPLAY_NAME, refund,
			]

	if _reveal_presenter == null:
		_setup_reveal_presenter()
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
		_reload_featured_helpers(true)
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
			_label_reveal_sub.text = "限界突破 +%d！  %s %d 還元" % [
				breakthrough, CurrencyHelper.DISPLAY_NAME, refund,
			]
		elif refund > 0 and breakthrough >= _GachaLimitBreak.MAX_BREAKTHROUGH:
			_label_reveal_sub.text = "限界突破上限  %s %d 還元" % [CurrencyHelper.DISPLAY_NAME, refund]
		elif refund > 0:
			_label_reveal_sub.text = "%s %d 還元" % [CurrencyHelper.DISPLAY_NAME, refund]
		elif breakthrough_gained:
			_label_reveal_sub.text = "限界突破 +%d" % breakthrough
		else:
			_label_reveal_sub.text = ""

	var name_line: String = name_str
	if breakthrough > 0:
		name_line = "%s（限界突破 +%d）" % [name_str, breakthrough]
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
