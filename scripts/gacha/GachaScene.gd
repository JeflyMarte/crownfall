extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const COLOR_NEW: Color = Color(0.95, 0.78, 0.35)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_OWNED: Color = Color(0.55, 0.88, 0.5)

@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _token_icon: TextureRect = $Header/HeaderRow/TokenChip/TokenRow/TokenIcon
@onready var _btn_tab_pickup: Button = $MainColumn/TabRow/BtnTabPickup
@onready var _btn_tab_premium: Button = $MainColumn/TabRow/BtnTabPremium
@onready var _btn_tab_normal: Button = $MainColumn/TabRow/BtnTabNormal
@onready var _hero_banner: PanelContainer = $MainColumn/HeroBanner
@onready var _banner_art_host: Control = $MainColumn/HeroBanner/BannerVBox/BannerArtHost
@onready var _label_catchcopy: Label = $MainColumn/HeroBanner/BannerVBox/LabelCatchcopy
@onready var _label_rate: Label = $MainColumn/HeroBanner/BannerVBox/RateRow/LabelRate
@onready var _btn_rate_detail: Button = $MainColumn/HeroBanner/BannerVBox/RateRow/BtnRateDetail
@onready var _label_pity_caption: Label = $MainColumn/PityPanel/PityVBox/LabelPityCaption
@onready var _pity_bar: ProgressBar = $MainColumn/PityPanel/PityVBox/PityBar
@onready var _lineup_carousel: HBoxContainer = $MainColumn/LineupCarouselScroll/LineupCarousel
@onready var _detail_overlay: Control = $DetailOverlay
@onready var _detail_dim: ColorRect = $DetailOverlay/Dim
@onready var _detail_panel: PanelContainer = $DetailOverlay/DetailPanel
@onready var _lineup_container: VBoxContainer = $DetailOverlay/DetailPanel/DetailVBox/LineupScrollContainer/LineupContainer
@onready var _btn_detail_close: Button = $DetailOverlay/DetailPanel/DetailVBox/DetailHeader/BtnDetailClose
@onready var _label_result: Label = $SummonActionBar/LabelResult
@onready var _button_pull: Button = $SummonActionBar/PullRow/ButtonPull
@onready var _button_pull_10: Button = $SummonActionBar/PullRow/Pull10Wrap/ButtonPull10
@onready var _label_ribbon_10: Label = $SummonActionBar/PullRow/Pull10Wrap/LabelRibbon10
@onready var _button_buy_crystal: Button = $SummonActionBar/ButtonBuyCrystal
@onready var _summon_layer: CanvasLayer = $SummonRevealLayer
@onready var _summon_dim: ColorRect = $SummonRevealLayer/Dim
@onready var _reveal_panel: PanelContainer = $SummonRevealLayer/RevealPanel
@onready var _flash_icon: TextureRect = $SummonRevealLayer/RevealPanel/RevealVBox/FlashIcon
@onready var _portrait_frame: PanelContainer = $SummonRevealLayer/RevealPanel/RevealVBox/PortraitFrame
@onready var _portrait_icon: TextureRect = $SummonRevealLayer/RevealPanel/RevealVBox/PortraitFrame/PortraitIcon
@onready var _label_banner: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelBanner
@onready var _label_reveal_name: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelRevealName
@onready var _label_reveal_sub: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelRevealSub
@onready var _label_tap_hint: Label = $SummonRevealLayer/RevealPanel/RevealVBox/LabelTapHint

var _summon_active: bool = false
var _summon_can_dismiss: bool = false
var _summon_tween: Tween = null
var _tab_buttons: Array[Button] = []
var _active_tab_index: int = GachaUiTokens.ACTIVE_TAB_INDEX
var _featured_helper_id: String = ""

func _ready() -> void:
	_setup_gacha_chrome()
	_setup_tabs()
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.GACHA)
	_btn_back.pressed.connect(_on_back_pressed)
	_btn_rate_detail.pressed.connect(_on_rate_detail_pressed)
	_btn_detail_close.pressed.connect(_on_detail_close_pressed)
	_detail_dim.gui_input.connect(_on_detail_dim_input)
	_button_pull.pressed.connect(_on_pull_pressed)
	_button_pull_10.pressed.connect(_on_pull_10_pressed)
	_button_buy_crystal.pressed.connect(_on_buy_crystal_pressed)
	_summon_dim.gui_input.connect(_on_summon_overlay_input)
	_reveal_panel.gui_input.connect(_on_summon_overlay_input)
	_portrait_frame.add_theme_stylebox_override("panel", GachaUiTokens.lineup_cell_style())
	_summon_layer.visible = false
	_detail_overlay.visible = false
	_refresh()

func _setup_gacha_chrome() -> void:
	_label_title.text = ""
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
	$MainColumn/PityPanel.add_theme_stylebox_override("panel", GachaUiTokens.panel_dark_style())
	_detail_panel.add_theme_stylebox_override("panel", GachaUiTokens.panel_dark_style())
	_reveal_panel.add_theme_stylebox_override("panel", GachaUiTokens.reveal_frame_style())
	_pity_bar.add_theme_stylebox_override("background", GachaUiTokens.pity_bar_background_style())
	_pity_bar.add_theme_stylebox_override("fill", GachaUiTokens.pity_bar_fill_style())
	_pity_bar.max_value = float(GachaSystem.HARD_PITY)
	GachaUiHelper.setup_pull_button(_button_pull, 1, true, false)
	GachaUiHelper.setup_pull_button(_button_pull_10, 10, false, true)
	_apply_button_style(_btn_rate_detail, GachaUiTokens.detail_button_style())
	_apply_button_style(_btn_detail_close, GachaUiTokens.detail_button_style())
	_apply_button_style(_button_buy_crystal, GachaUiTokens.detail_button_style())
	UiTypography.apply_menu_button(_button_buy_crystal)
	_label_ribbon_10.text = GachaUiTokens.TEN_PULL_RIBBON_TEXT
	UiTypography.apply_menu_label(
		_label_ribbon_10,
		14,
		Color(1.0, 0.96, 0.88, 1.0),
		UiTypography.OUTLINE_STRONG
	)
	UiTypography.apply_body(_label_result, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_display(_label_banner, UiTypography.SIZE_DISPLAY_TITLE)
	UiTypography.apply_display(_label_reveal_name, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	UiTypography.apply_body(_label_reveal_sub, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
	UiTypography.apply_caption(_label_tap_hint, UiTypography.COLOR_MUTED)
	UiTypography.apply_body(_label_catchcopy, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	UiTypography.apply_caption(_label_rate)
	UiTypography.apply_caption(_label_pity_caption)
	UiTypography.apply_display(
		$DetailOverlay/DetailPanel/DetailVBox/DetailHeader/LabelDetailTitle,
		UiTypography.SIZE_BODY_SMALL
	)

func _setup_tabs() -> void:
	_tab_buttons = [_btn_tab_pickup, _btn_tab_premium, _btn_tab_normal]
	for i in GachaUiTokens.TAB_LABELS.size():
		if i >= _tab_buttons.size():
			break
		var btn: Button = _tab_buttons[i]
		btn.text = GachaUiTokens.TAB_LABELS[i]
		var locked: bool = i != GachaUiTokens.ACTIVE_TAB_INDEX
		btn.toggle_mode = not locked
		btn.button_pressed = i == GachaUiTokens.ACTIVE_TAB_INDEX
		GachaUiTokens.apply_tab_button(btn, i == GachaUiTokens.ACTIVE_TAB_INDEX, locked)
		if not locked:
			btn.pressed.connect(_on_tab_pressed.bind(i))

func _apply_button_style(btn: Button, style: StyleBox) -> void:
	if style is StyleBoxTexture and (style as StyleBoxTexture).texture != null:
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

func _refresh() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()
	_refresh_pity_bar()
	_label_rate.text = GachaSystem.rate_display_text()
	_label_catchcopy.text = GachaUiHelper.catchcopy_for_tab(_active_tab_index)
	_set_pull_controls_enabled(not _summon_active)
	GachaUiHelper.setup_pull_button(_button_pull, 1, not _button_pull.disabled, false)
	GachaUiHelper.setup_pull_button(_button_pull_10, 10, false, true)
	_button_buy_crystal.text = "%s購入（%dG）" % [CurrencyHelper.DISPLAY_NAME, GachaSystem.TOKEN_PURCHASE_GOLD]
	_button_buy_crystal.disabled = _summon_active or GameState.gold < GachaSystem.TOKEN_PURCHASE_GOLD
	_refresh_banner_art()
	_rebuild_lineup()

func _refresh_pity_bar() -> void:
	var pity: int = GameState.gacha_pity
	_label_pity_caption.text = GachaUiTokens.pity_caption(pity, GachaSystem.HARD_PITY)
	_pity_bar.value = float(pity)

func _refresh_banner_art() -> void:
	GachaUiHelper.populate_banner_portraits(_banner_art_host)

func _set_pull_controls_enabled(enabled: bool) -> void:
	_button_pull.disabled = not enabled or not GachaSystem.can_pull()
	_button_pull_10.disabled = true
	_btn_back.disabled = not enabled
	_btn_rate_detail.disabled = not enabled
	for nav_btn in $BottomNav/NavRow.get_children():
		if nav_btn is Button:
			(nav_btn as Button).disabled = not enabled

func _rebuild_lineup() -> void:
	for child in _lineup_container.get_children():
		child.queue_free()
	for child in _lineup_carousel.get_children():
		child.queue_free()
	var helpers: Array = GachaUiHelper.sorted_helpers()
	if helpers.is_empty():
		var lbl := Label.new()
		lbl.text = "（排出対象なし）"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lineup_container.add_child(lbl)
		return
	if _featured_helper_id.is_empty() or DataRegistry.get_gacha_helper_data(_featured_helper_id) == null:
		_featured_helper_id = str(helpers[0].id)
	for helper in helpers:
		if helper == null:
			continue
		var helper_id: String = str(helper.id)
		_lineup_container.add_child(GachaUiHelper.make_lineup_row(helper))
		var cell: PanelContainer = GachaUiHelper.make_carousel_cell(helper, helper_id == _featured_helper_id)
		cell.gui_input.connect(_on_carousel_cell_input.bind(helper_id))
		_lineup_carousel.add_child(cell)

func _on_tab_pressed(tab_index: int) -> void:
	if tab_index != GachaUiTokens.ACTIVE_TAB_INDEX:
		return
	_active_tab_index = tab_index
	_label_catchcopy.text = GachaUiHelper.catchcopy_for_tab(tab_index)
	for i in _tab_buttons.size():
		GachaUiTokens.apply_tab_button(
			_tab_buttons[i],
			i == tab_index,
			i != GachaUiTokens.ACTIVE_TAB_INDEX
		)

func _on_carousel_cell_input(event: InputEvent, helper_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_featured_helper_id = helper_id
		_rebuild_lineup()

func _on_rate_detail_pressed() -> void:
	_detail_overlay.visible = true

func _on_detail_close_pressed() -> void:
	_detail_overlay.visible = false

func _on_detail_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_detail_overlay.visible = false
	elif event is InputEventScreenTouch and event.pressed:
		_detail_overlay.visible = false

func _on_pull_10_pressed() -> void:
	pass

func _on_pull_pressed() -> void:
	if _summon_active:
		return
	var result: Dictionary = GachaSystem.pull()
	SaveManager.save_game()
	if not bool(result.get("ok", false)):
		var reason: String = str(result.get("reason", ""))
		if reason == "no_token":
			_label_result.text = "%sが足りません。" % CurrencyHelper.DISPLAY_NAME
		else:
			_label_result.text = "召喚に失敗しました（%s）。" % reason
		_refresh()
		return
	_play_summon_reveal(result)

func _play_summon_reveal(result: Dictionary) -> void:
	_summon_active = true
	_summon_can_dismiss = false
	_set_pull_controls_enabled(false)
	_reset_reveal_visuals()
	_summon_layer.visible = true

	var helper_id: String = str(result.get("helper_id", ""))
	var is_new: bool = bool(result.get("is_new", false))
	var refund: int = int(result.get("refund", 0))
	var helper_data: Resource = DataRegistry.get_gacha_helper_data(helper_id)
	var name_str: String = helper_id if helper_data == null else str(helper_data.display_name)
	_populate_reveal_content(helper_id, is_new, refund, helper_data)

	if is_new:
		_label_result.add_theme_color_override("font_color", COLOR_NEW)
		_label_result.text = "NEW! %s を獲得！" % name_str
	else:
		_label_result.add_theme_color_override("font_color", COLOR_SUB)
		_label_result.text = "%s（重複） → %s %d 還元" % [
			name_str, CurrencyHelper.DISPLAY_NAME, refund,
		]

	if _summon_tween != null and _summon_tween.is_valid():
		_summon_tween.kill()
	_summon_tween = create_tween()
	_summon_tween.set_parallel(false)
	_summon_tween.tween_property(_summon_dim, "modulate:a", 1.0, 0.22)
	_summon_tween.tween_property(_reveal_panel, "modulate:a", 1.0, 0.18)
	_summon_tween.tween_property(_flash_icon, "scale", Vector2(1.35, 1.35), 0.16).set_trans(Tween.TRANS_BACK)
	_summon_tween.tween_property(_flash_icon, "scale", Vector2(1.0, 1.0), 0.12)
	_summon_tween.tween_callback(func() -> void:
		_flash_icon.visible = false
		_portrait_frame.visible = true
		_portrait_frame.scale = Vector2(0.55, 0.55)
		_portrait_frame.modulate.a = 0.0
	)
	_summon_tween.tween_property(_portrait_frame, "scale", Vector2(1.0, 1.0), 0.24).set_trans(Tween.TRANS_BACK)
	_summon_tween.tween_property(_portrait_frame, "modulate:a", 1.0, 0.2)
	_summon_tween.tween_callback(func() -> void:
		_label_banner.visible = true
		_label_reveal_name.visible = true
		_label_reveal_sub.visible = true
		_label_tap_hint.visible = true
		_summon_can_dismiss = true
	)

func _reset_reveal_visuals() -> void:
	_summon_dim.modulate = Color(1, 1, 1, 0)
	_reveal_panel.modulate = Color(1, 1, 1, 0)
	_flash_icon.visible = true
	_flash_icon.scale = Vector2.ONE
	_portrait_frame.visible = false
	_portrait_frame.scale = Vector2.ONE
	_portrait_frame.modulate = Color(1, 1, 1, 1)
	_label_banner.visible = false
	_label_reveal_name.visible = false
	_label_reveal_sub.visible = false
	_label_tap_hint.visible = false

func _on_summon_overlay_input(event: InputEvent) -> void:
	if not _summon_can_dismiss:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dismiss_summon_reveal()
	elif event is InputEventScreenTouch and event.pressed:
		_dismiss_summon_reveal()

func _dismiss_summon_reveal() -> void:
	if not _summon_active:
		return
	_summon_can_dismiss = false
	if _summon_tween != null and _summon_tween.is_valid():
		_summon_tween.kill()
	_summon_tween = create_tween()
	_summon_tween.tween_property(_summon_dim, "modulate:a", 0.0, 0.2)
	_summon_tween.parallel().tween_property(_reveal_panel, "modulate:a", 0.0, 0.2)
	_summon_tween.chain().tween_callback(func() -> void:
		_summon_layer.visible = false
		_summon_active = false
		_refresh()
	)

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
	_populate_reveal_content(hid, is_new, refund, helper_data)
	_summon_active = true
	_summon_can_dismiss = true
	_set_pull_controls_enabled(false)
	_summon_layer.visible = true
	_summon_dim.modulate = Color(1, 1, 1, 1)
	_reveal_panel.modulate = Color(1, 1, 1, 1)
	_flash_icon.visible = false
	_portrait_frame.visible = true
	_portrait_frame.scale = Vector2.ONE
	_portrait_frame.modulate = Color(1, 1, 1, 1)
	_label_banner.visible = true
	_label_reveal_name.visible = true
	_label_reveal_sub.visible = true
	_label_tap_hint.visible = true

func _populate_reveal_content(
	hid: String,
	is_new: bool,
	refund: int,
	helper_data: Resource
) -> void:
	var name_str: String = hid if helper_data == null else str(helper_data.display_name)
	var job_id: String = str(helper_data.job_id) if helper_data != null else ""
	var portrait_tex: Texture2D = helper_data.get_portrait_texture() if helper_data != null else null
	if portrait_tex == null:
		portrait_tex = IconPaths.get_icon_texture(job_id, "chr")

	if is_new:
		_label_banner.text = "NEW!"
		_label_banner.add_theme_color_override("font_color", COLOR_NEW)
		_label_reveal_sub.text = "ロスターに追加されました"
	else:
		_label_banner.text = "重複"
		_label_banner.add_theme_color_override("font_color", COLOR_SUB)
		_label_reveal_sub.text = "%s %d 還元" % [CurrencyHelper.DISPLAY_NAME, refund]

	_label_reveal_name.text = name_str
	if helper_data != null:
		var job_data: Resource = DataRegistry.get_job_data(job_id)
		var role_id: String = str(job_data.role) if job_data != null else job_id
		var role_label: String = str(RosterUiHelper.ROLE_LABELS.get(role_id, job_id))
		_label_reveal_name.text = "%s\n%s  %s" % [
			name_str,
			RosterUiHelper.stars_text(int(helper_data.rarity)),
			role_label,
		]
	_portrait_icon.texture = portrait_tex
	if not hid.is_empty():
		_featured_helper_id = hid

func _on_buy_crystal_pressed() -> void:
	if _summon_active:
		return
	var success: bool = GachaSystem.buy_token()
	SaveManager.save_game()
	if success:
		_label_result.add_theme_color_override("font_color", COLOR_OWNED)
		_label_result.text = "%sを1個購入しました。" % CurrencyHelper.DISPLAY_NAME
	else:
		_label_result.add_theme_color_override("font_color", COLOR_SUB)
		_label_result.text = "ゴールドが足りません。"
	_refresh()

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
