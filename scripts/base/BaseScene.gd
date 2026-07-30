extends Control

const _HubNpcHelper := preload("res://scripts/ui/HubNpcHelper.gd")
const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderGiftBox := preload("res://scripts/commander/CommanderGiftBox.gd")
const _CommanderRankUpOverlay := preload("res://scripts/commander/CommanderRankUpOverlay.gd")
const _CurrencyGainFx := preload("res://scripts/ui/CurrencyGainFx.gd")
const _HubNinaNavigator := preload("res://scripts/ui/HubNinaNavigator.gd")
const _StarterJoinOverlay := preload("res://scripts/roster/StarterJoinOverlay.gd")
const _HubSimpleGuideOverlay := preload("res://scripts/ui/HubSimpleGuideOverlay.gd")
const _NinaDialogueOverlay := preload("res://scripts/ui/NinaDialogueOverlay.gd")
const _ChapterClearNinaLines := preload("res://scripts/ui/ChapterClearNinaLines.gd")
const _HubDebugMenuOverlay := preload("res://scripts/debug/HubDebugMenuOverlay.gd")

const DUNGEON_SELECT_SCENE: String = "res://scenes/dungeon/DungeonSelectScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const SURVEY_SCENE: String = "res://scenes/survey/SurveyScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"
const EQUIPMENT_CATALOG_SCENE: String = "res://scenes/equipment/EquipmentCatalogScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"
const COMMANDER_SCENE: String = "res://scenes/commander/CommanderScene.tscn"
const SETTINGS_SCENE: String = "res://scenes/settings/SettingsScene.tscn"
const EVENT_SCENE: String = "res://scenes/event/EventScene.tscn"
const _GOLD_ICON_PATH: String = "res://assets/ui/batch2/ICO_Gold.png"

@onready var _menu_vbox: VBoxContainer = $HubView/LeftMenuPanel/MenuScroll/MenuVBox
@onready var _label_gold: Label = $HubView/TopBar/TopBarRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $HubView/TopBar/TopBarRow/TokenChip/TokenRow/LabelToken
@onready var _label_player_name: Label = $HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PlayerInfo/LabelPlayerName
@onready var _label_player_level: Label = $HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PlayerInfo/LabelPlayerLevel
@onready var _portrait_art: TextureRect = $HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PortraitFrame/PortraitArt
@onready var _portrait_glyph: Label = $HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PortraitFrame/PortraitGlyph
@onready var _player_card: PanelContainer = $HubView/TopBar/TopBarRow/PlayerCard
@onready var _player_info: VBoxContainer = $HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PlayerInfo

var _rank_sp_bar: ProgressBar
@onready var _label_daily_reset: Label = $HubView/DailyMissionPanel/DailyVBox/DailyHeader/LabelDailyReset
@onready var _mission_list: VBoxContainer = $HubView/DailyMissionPanel/DailyVBox/MissionList
@onready var _label_daily_title: Label = $HubView/DailyMissionPanel/DailyVBox/DailyHeader/LabelDailyTitle
@onready var _label_menu_title: Label = $HubView/LeftMenuPanel/MenuScroll/MenuVBox/LabelMenuTitle

var _field_survey_banner: PanelContainer
var _field_survey_click_hint: TextureRect
var _field_survey_click_hint_tween: Tween
var _gift_badge: PanelContainer
var _nina_nav: Control

func _ready() -> void:
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.HOME)
	AudioManager.play_bgm("hub")
	_decorate_panels()
	_setup_field_survey_banner()
	_setup_nina_nav()
	_build_left_menu()
	DailyMissionSystem.missions_updated.connect(_refresh_daily_missions)
	EventSystem.event_updated.connect(_refresh_field_survey_banner)
	EventSystem.event_updated.connect(_refresh_nina_nav)
	$ResetTimer.timeout.connect(_on_hub_tick)
	_ensure_valid_dungeon_selection()
	DailyMissionSystem.ensure_refreshed()
	_update_display()
	_refresh_daily_missions()
	_apply_typography()
	_refresh_field_survey_banner()
	_refresh_nina_nav()
	GameState.base_initial_view = "hub"
	_player_card.gui_input.connect(_on_player_card_gui_input)
	_setup_gift_badge()
	_ensure_rank_sp_bar()
	call_deferred("_layout_hub_if_needed")
	call_deferred("_maybe_show_rank_up")


func _ensure_rank_sp_bar() -> void:
	if _rank_sp_bar != null and is_instance_valid(_rank_sp_bar):
		return
	_label_player_level.visible = false
	_rank_sp_bar = ProgressBar.new()
	_rank_sp_bar.name = "RankSpBar"
	_rank_sp_bar.min_value = 0.0
	_rank_sp_bar.max_value = 1.0
	_rank_sp_bar.value = 0.0
	_rank_sp_bar.show_percentage = false
	_rank_sp_bar.custom_minimum_size = Vector2(0, 8)
	_rank_sp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rank_sp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.1, 0.14, 0.9)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.86, 0.74, 0.45, 0.95)
	fill.set_corner_radius_all(3)
	_rank_sp_bar.add_theme_stylebox_override("background", bg)
	_rank_sp_bar.add_theme_stylebox_override("fill", fill)
	_player_info.add_child(_rank_sp_bar)


func _layout_hub_if_needed() -> void:
	## 実機のみ: TopBar 追従＋日課下端スタック。Mac はシーン座標のまま。
	HubLayoutHelper.layout_hub_home_content(self)
	_place_field_survey_banner()
	_place_nina_nav()


func _maybe_show_rank_up() -> void:
	## 章クリア加入があるとき: ニーナ功績 → 解放 → 等級 → 加入予告 → 加入 → ノノカ合流。
	## 直前オーバーレイの queue_free 待ちは _hub_overlay_blocking でスキップ判定。
	if GameState.pending_clear_nina_merit:
		if _hub_overlay_blocking("NinaDialogueOverlay"):
			return
		if _hub_overlay_blocking("DungeonUnlockOverlay"):
			return
		if _hub_overlay_blocking("StarterJoinOverlay"):
			return
		var stage_id: String = GameState.pending_clear_stage_id
		var stage_name: String = _ChapterClearNinaLines.stage_display_name(stage_id)
		var merit: CanvasLayer = _NinaDialogueOverlay.show_on(
			self, _ChapterClearNinaLines.merit_lines_for_stage(stage_id, stage_name)
		)
		merit.dismissed.connect(_on_clear_nina_merit_dismissed)
		return
	const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
	if _ContentUnlockNotice.has_pending():
		if _hub_overlay_blocking("DungeonUnlockOverlay"):
			return
		if _hub_overlay_blocking("DungeonRouteGuideOverlay"):
			return
		if _hub_overlay_blocking("NinaDialogueOverlay"):
			return
		var unlock_overlay: CanvasLayer = _ContentUnlockNotice.show_pending_on(
			self, Callable(self, "_continue_hub_clear_flow")
		)
		if unlock_overlay != null:
			return
	## 無限ガイドなど、解放ポップ後の手引きが残っていれば先に出す。
	const _DungeonRouteGuide := preload("res://scripts/ui/DungeonRouteGuideOverlay.gd")
	if _DungeonRouteGuide.has_pending_auto():
		if _hub_overlay_blocking("DungeonRouteGuideOverlay"):
			return
		if _hub_overlay_blocking("DungeonUnlockOverlay"):
			return
		var route_guide: CanvasLayer = _DungeonRouteGuide.try_show_pending_on(
			self, Callable(self, "_continue_hub_clear_flow")
		)
		if route_guide != null:
			return
	const _NinaRareAcquireGuide := preload("res://scripts/ui/NinaRareAcquireGuide.gd")
	if _NinaRareAcquireGuide.has_pending_guide():
		if _hub_overlay_blocking("NinaDialogueOverlay"):
			return
		if _hub_overlay_blocking("DungeonUnlockOverlay"):
			return
		if _hub_overlay_blocking("DungeonRouteGuideOverlay"):
			return
		var guide_kind: String = _NinaRareAcquireGuide.peek_pending_guide_kind()
		var rare_guide: CanvasLayer = _NinaDialogueOverlay.show_on(
			self, _NinaRareAcquireGuide.guide_lines_for(guide_kind)
		)
		rare_guide.dismissed.connect(_on_nina_rare_guide_dismissed.bind(guide_kind))
		return
	_CommanderProfile.bootstrap_acknowledged_rank_if_needed()
	var pending: String = _CommanderProfile.pending_rank_up()
	if not pending.is_empty():
		if _hub_overlay_blocking("CommanderRankUpOverlay"):
			return
		var overlay: CanvasLayer = _CommanderRankUpOverlay.show_on(self, pending)
		overlay.dismissed.connect(_on_rank_up_dismissed)
		return
	_maybe_show_clear_nina_teaser()


func _continue_hub_clear_flow() -> void:
	## 解放キュー消化後／遅延再開用。
	_maybe_show_rank_up()


func _on_clear_nina_merit_dismissed() -> void:
	GameState.pending_clear_nina_merit = false
	SaveManager.save_game()
	## NinaDialogueOverlay の queue_free 後に解放→加入へ続ける。
	call_deferred("_continue_hub_clear_flow")


func _on_nina_rare_guide_dismissed(kind: String) -> void:
	const _NinaRareAcquireGuide := preload("res://scripts/ui/NinaRareAcquireGuide.gd")
	var pending_kind: String = _NinaRareAcquireGuide.pop_pending_guide_kind()
	if pending_kind.is_empty():
		pending_kind = kind
	_NinaRareAcquireGuide.mark_guide_done(pending_kind)
	SaveManager.save_game()
	_refresh_nina_nav()
	call_deferred("_continue_hub_clear_flow")


func _on_rank_up_dismissed(_rank_code: String) -> void:
	_update_player_card()
	## 複数段ジャンプ時は次の到達分を続けて表示しない（到達等級を一括 ack 済み）。
	call_deferred("_maybe_show_clear_nina_teaser")


func _maybe_show_clear_nina_teaser() -> void:
	if GameState.pending_clear_nina_teaser and not GameState.pending_starter_recruit_id.is_empty():
		if _hub_overlay_blocking("NinaDialogueOverlay"):
			return
		if _hub_overlay_blocking("DungeonUnlockOverlay"):
			return
		if _hub_overlay_blocking("CommanderRankUpOverlay"):
			return
		if _hub_overlay_blocking("StarterJoinOverlay"):
			return
		var teaser: CanvasLayer = _NinaDialogueOverlay.show_on(
			self,
			_ChapterClearNinaLines.recruit_teaser_lines_for_stage(
				GameState.pending_clear_stage_id
			)
		)
		teaser.dismissed.connect(_on_clear_nina_teaser_dismissed)
		return
	GameState.pending_clear_nina_teaser = false
	_maybe_show_starter_join()


func _on_clear_nina_teaser_dismissed() -> void:
	GameState.pending_clear_nina_teaser = false
	SaveManager.save_game()
	call_deferred("_maybe_show_starter_join")


func _maybe_show_starter_join() -> void:
	var pending_id: String = GameState.pending_starter_recruit_id.strip_edges()
	if pending_id.is_empty():
		_maybe_show_nonoka_survey_join()
		return
	if _hub_overlay_blocking("StarterJoinOverlay"):
		return
	if _hub_overlay_blocking("CommanderRankUpOverlay"):
		return
	if _hub_overlay_blocking("HubSimpleGuideOverlay"):
		return
	if _hub_overlay_blocking("NinaDialogueOverlay"):
		return
	if _hub_overlay_blocking("DungeonUnlockOverlay"):
		return
	var overlay: CanvasLayer = _StarterJoinOverlay.show_on(self, pending_id)
	overlay.dismissed.connect(_on_starter_join_dismissed)


func _on_starter_join_dismissed(adventurer_id: String) -> void:
	_update_display()
	_refresh_nina_nav()
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	if _PetSystem.is_pet_id(adventurer_id):
		GameState.pending_hub_pet_grant_id = ""
		SaveManager.save_game()
		_maybe_grant_starting_tokens_fx()
		return
	## 初期キャラ加入の直後にノノカ調査室合流（ミストフェン初回クリア時）。
	call_deferred("_maybe_show_nonoka_survey_join")


func _maybe_show_nonoka_survey_join() -> void:
	if not GameState.pending_nonoka_survey_join:
		_maybe_show_hub_simple_guide()
		return
	if GameState.survey_staff_nonoka_unlocked and not GameState.debug_full_unlock:
		## 解放済みなら待ちを落とす（二重表示防止）。
		GameState.pending_nonoka_survey_join = false
		SaveManager.save_game()
		_maybe_show_hub_simple_guide()
		return
	if _hub_overlay_blocking("NinaDialogueOverlay"):
		return
	if _hub_overlay_blocking("StarterJoinOverlay"):
		return
	if _hub_overlay_blocking("DungeonUnlockOverlay"):
		return
	if _hub_overlay_blocking("CommanderRankUpOverlay"):
		return
	if _hub_overlay_blocking("HubSimpleGuideOverlay"):
		return
	var join_lines: CanvasLayer = _NinaDialogueOverlay.show_on(
		self, _ChapterClearNinaLines.nonoka_survey_join_lines()
	)
	join_lines.dismissed.connect(_on_nonoka_survey_join_dismissed)


func _on_nonoka_survey_join_dismissed() -> void:
	## 会話の次に加入ショーケース（ガチャ風リビールなし）。解放はショーケース閉じ後。
	call_deferred("_maybe_show_nonoka_join_showcase")


func _maybe_show_nonoka_join_showcase() -> void:
	if not GameState.pending_nonoka_survey_join:
		_maybe_show_hub_simple_guide()
		return
	if _hub_overlay_blocking("StarterJoinOverlay"):
		return
	if _hub_overlay_blocking("NinaDialogueOverlay"):
		return
	if _hub_overlay_blocking("DungeonUnlockOverlay"):
		return
	if _hub_overlay_blocking("CommanderRankUpOverlay"):
		return
	if _hub_overlay_blocking("HubSimpleGuideOverlay"):
		return
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	var overlay: CanvasLayer = _StarterJoinOverlay.show_showcase_only(
		self, _SurveyStaff.ID_NONOKA
	)
	overlay.dismissed.connect(_on_nonoka_join_showcase_dismissed)


func _on_nonoka_join_showcase_dismissed(_member_id: String) -> void:
	GameState.commit_nonoka_survey_join()
	SaveManager.save_game()
	_refresh_nina_nav()
	call_deferred("_maybe_show_hub_simple_guide")


func _maybe_show_hub_simple_guide() -> void:
	if not _HubSimpleGuideOverlay.should_show():
		_maybe_show_hub_pet_join()
		return
	if get_node_or_null("HubSimpleGuideOverlay") != null:
		return
	if get_node_or_null("CommanderRankUpOverlay") != null:
		return
	if get_node_or_null("StarterJoinOverlay") != null:
		return
	if get_node_or_null("NinaDialogueOverlay") != null:
		return
	if get_node_or_null("HubDebugMenuOverlay") != null:
		return
	if GameState.pending_clear_nina_merit or GameState.pending_clear_nina_teaser:
		return
	if GameState.pending_nonoka_survey_join:
		return
	const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
	if _ContentUnlockNotice.has_pending():
		return
	var overlay: CanvasLayer = _HubSimpleGuideOverlay.show_on(self)
	if overlay != null and not overlay.dismissed.is_connected(_on_hub_simple_guide_dismissed):
		overlay.dismissed.connect(_on_hub_simple_guide_dismissed)


func _on_hub_simple_guide_dismissed() -> void:
	## preview 再演はフラグを立てない → 支給しない。
	if not _HubSimpleGuideOverlay.is_done():
		return
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	if not _PetSystem.is_starter_pet_granted():
		GameState.pending_hub_pet_grant_id = _PetSystem.STARTER_PET_ID
		SaveManager.save_game()
	## ガイドは queue_free 直後もツリーに残るため、次フレームでジャック支給へ。
	call_deferred("_maybe_show_hub_pet_join")


func _maybe_show_hub_pet_join() -> void:
	var pet_id: String = GameState.pending_hub_pet_grant_id.strip_edges()
	if pet_id.is_empty():
		_maybe_grant_starting_tokens_fx()
		return
	if _hub_overlay_blocking("StarterJoinOverlay"):
		return
	if _hub_overlay_blocking("HubSimpleGuideOverlay"):
		return
	if _hub_overlay_blocking("CommanderRankUpOverlay"):
		return
	if _hub_overlay_blocking("NinaDialogueOverlay"):
		return
	var overlay: CanvasLayer = _StarterJoinOverlay.show_on(self, pet_id)
	if overlay != null and not overlay.dismissed.is_connected(_on_starter_join_dismissed):
		overlay.dismissed.connect(_on_starter_join_dismissed)


func _hub_overlay_blocking(node_name: String) -> bool:
	var n: Node = get_node_or_null(node_name)
	if n == null:
		return false
	return not n.is_queued_for_deletion()


const HUB_STARTING_TOKENS_FLAG: String = "hub_starting_tokens_granted"


func _maybe_grant_starting_tokens_fx() -> void:
	if bool(GameState.tutorial_flags.get(HUB_STARTING_TOKENS_FLAG, false)):
		return
	if not _HubSimpleGuideOverlay.is_done():
		return
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	## ジャック支給演出が残っている間はトークンを後回し。
	if not GameState.pending_hub_pet_grant_id.strip_edges().is_empty():
		return
	if not _PetSystem.is_starter_pet_granted():
		return
	GameState.tutorial_flags[HUB_STARTING_TOKENS_FLAG] = true
	var amount: int = GachaSystem.STARTING_TOKENS
	GameState.gacha_token += amount
	SaveManager.save_game()
	var token_chip: Control = $HubView/TopBar/TopBarRow/TokenChip as Control
	var token_tex: Texture2D = CurrencyHelper.get_icon_texture()
	var from_global: Vector2 = get_viewport_rect().get_center()
	if token_tex == null or token_chip == null:
		_update_display()
		return
	## 付与後に表示を一度 0→付与前相当へ戻し、飛込完了で最終値を見せる。
	var shown_before: int = maxi(0, GameState.gacha_token - amount)
	_label_token.text = CurrencyHelper.format_amount(shown_before)
	_CurrencyGainFx.play(
		self,
		from_global,
		[{"texture": token_tex, "target": token_chip, "amount": amount}],
		_update_display
	)


func _setup_gift_badge() -> void:
	_gift_badge = PanelContainer.new()
	_gift_badge.name = "GiftBadge"
	_gift_badge.visible = false
	_gift_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gift_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gift_badge.offset_left = -24.0
	_gift_badge.offset_top = -6.0
	_gift_badge.offset_right = 4.0
	_gift_badge.offset_bottom = 14.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.82, 0.22, 0.18, 0.95)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(2.0)
	_gift_badge.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.name = "GiftBadgeLabel"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiTypography.apply_display(lbl, 10, Color(1.0, 0.95, 0.9), UiTypography.OUTLINE_STRONG)
	_gift_badge.add_child(lbl)
	_player_card.add_child(_gift_badge)

func _setup_field_survey_banner() -> void:
	if not EventSystem.PERIODIC_EVENTS_ENABLED:
		return
	_field_survey_banner = PanelContainer.new()
	_field_survey_banner.name = "FieldSurveyBanner"
	_field_survey_banner.mouse_filter = Control.MOUSE_FILTER_STOP
	_field_survey_banner.gui_input.connect(_on_field_survey_banner_input)
	_field_survey_banner.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10.0
	row.offset_top = 4.0
	row.offset_right = -10.0
	row.offset_bottom = -4.0
	row.add_theme_constant_override("separation", 8)
	_field_survey_banner.add_child(row)
	var tag := Label.new()
	tag.name = "LabelFieldTag"
	tag.text = EventSystem.DISPLAY_NAME
	row.add_child(tag)
	var body := Label.new()
	body.name = "LabelFieldBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.clip_text = true
	body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(body)
	var timer := Label.new()
	timer.name = "LabelFieldTimer"
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(timer)
	## バナー右上に載せるタップ誘導ロゴ（バナー本体の上に少しはみ出す）。
	_field_survey_click_hint = TextureRect.new()
	_field_survey_click_hint.name = "FieldSurveyClickHint"
	_field_survey_click_hint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_field_survey_click_hint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_field_survey_click_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	_field_survey_click_hint.tooltip_text = "タップでギルド情報誌を開く"
	_field_survey_click_hint.gui_input.connect(_on_field_survey_banner_input)
	_field_survey_click_hint.pivot_offset = Vector2(140.0, 48.0)
	var hint_tex: Texture2D = IconPaths.get_icon_texture("guild_bulletin_click", "hub")
	if hint_tex != null:
		_field_survey_click_hint.texture = hint_tex
	$HubView.add_child(_field_survey_banner)
	$HubView.add_child(_field_survey_click_hint)
	_place_field_survey_banner()

func _place_field_survey_banner() -> void:
	if _field_survey_banner == null:
		return
	var menu: Control = $HubView/LeftMenuPanel as Control
	if menu == null:
		return
	## 左メニュー直下・画面幅いっぱいに配置（メニューと重ねない）。
	## 右上ロゴ分の余白を上に確保する（CurrencyStrip 撤去後は少し上げる）。
	const HINT_W: float = 280.0
	const HINT_H: float = 96.0
	const HINT_OVERLAP: float = 36.0
	## クリック誘導アイコンだけバナーより上へ（バナー位置は据え置き）。
	const HINT_LIFT: float = 28.0
	const BANNER_H: float = 40.0
	const GAP: float = 4.0
	var top: float = menu.offset_bottom + GAP + (HINT_H - HINT_OVERLAP)
	_field_survey_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_field_survey_banner.offset_left = 12.0
	_field_survey_banner.offset_right = -12.0
	_field_survey_banner.offset_top = top
	_field_survey_banner.offset_bottom = top + BANNER_H
	if _field_survey_click_hint != null:
		_field_survey_click_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_field_survey_click_hint.offset_left = -12.0 - HINT_W
		_field_survey_click_hint.offset_right = -12.0
		_field_survey_click_hint.offset_top = top - (HINT_H - HINT_OVERLAP) - HINT_LIFT
		_field_survey_click_hint.offset_bottom = top + HINT_OVERLAP - HINT_LIFT
		_field_survey_click_hint.z_index = _field_survey_banner.z_index + 1
		_field_survey_click_hint.pivot_offset = Vector2(HINT_W * 0.5, HINT_H * 0.5)


func _setup_nina_nav() -> void:
	_nina_nav = _HubNinaNavigator.new() as Control
	$HubView.add_child(_nina_nav)
	if _nina_nav.has_signal("survey_pressed"):
		_nina_nav.connect("survey_pressed", _on_survey_button_pressed)
	_place_nina_nav()


func _place_nina_nav() -> void:
	if _nina_nav == null:
		return
	var top_bar: Control = $HubView/TopBar as Control
	if _nina_nav.has_method("place_below_top_bar"):
		_nina_nav.call("place_below_top_bar", top_bar)


func _refresh_nina_nav() -> void:
	if _nina_nav == null:
		return
	var had_notices: bool = not GameState.pending_nina_nav_notices.is_empty()
	if _nina_nav.has_method("refresh_messages"):
		_nina_nav.call("refresh_messages")
	if had_notices:
		SaveManager.save_game()

func _refresh_field_survey_banner() -> void:
	if _field_survey_banner == null:
		return
	if not EventSystem.PERIODIC_EVENTS_ENABLED or not EventSystem.is_event_running():
		_field_survey_banner.visible = false
		_stop_field_survey_click_hint_blink()
		if _field_survey_click_hint != null:
			_field_survey_click_hint.visible = false
		return
	_place_field_survey_banner()
	_field_survey_banner.visible = true
	if _field_survey_click_hint != null:
		_field_survey_click_hint.visible = true
		_start_field_survey_click_hint_blink()
	var row: HBoxContainer = _field_survey_banner.get_child(0) as HBoxContainer
	if row == null:
		return
	var tag: Label = row.get_node_or_null("LabelFieldTag") as Label
	var body: Label = row.get_node_or_null("LabelFieldBody") as Label
	var timer: Label = row.get_node_or_null("LabelFieldTimer") as Label
	var event_data: Resource = EventSystem.get_active_event()
	if event_data == null:
		_field_survey_banner.visible = false
		_stop_field_survey_click_hint_blink()
		if _field_survey_click_hint != null:
			_field_survey_click_hint.visible = false
		return
	if tag != null:
		UiTypography.apply_caption(tag, UiTypography.COLOR_GOLD)
	if body != null:
		body.text = "%s — %s" % [str(event_data.title), EventSystem.active_modifier_summary()]
		UiTypography.apply_body(body, UiTypography.SIZE_BODY_SMALL)
	if timer != null:
		timer.text = EventSystem.countdown_text()
		UiTypography.apply_caption(timer)


func _start_field_survey_click_hint_blink() -> void:
	if _field_survey_click_hint == null:
		return
	_stop_field_survey_click_hint_blink()
	## 調査室ショートカット（HubNinaNavigator.SURVEY_PULSE_SEC=0.75）と同じ速度で明滅。
	const PULSE_SEC: float = 0.75
	_field_survey_click_hint.modulate = Color(1, 1, 1, 1)
	_field_survey_click_hint.scale = Vector2.ONE
	_field_survey_click_hint_tween = create_tween().set_loops()
	_field_survey_click_hint_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_field_survey_click_hint_tween.tween_property(
		_field_survey_click_hint, "modulate:a", 0.42, PULSE_SEC
	)
	_field_survey_click_hint_tween.tween_property(
		_field_survey_click_hint, "modulate:a", 1.0, PULSE_SEC
	)


func _stop_field_survey_click_hint_blink() -> void:
	if _field_survey_click_hint_tween != null and is_instance_valid(_field_survey_click_hint_tween):
		_field_survey_click_hint_tween.kill()
	_field_survey_click_hint_tween = null
	if _field_survey_click_hint != null:
		_field_survey_click_hint.modulate = Color(1, 1, 1, 1)
		_field_survey_click_hint.scale = Vector2.ONE


func _on_field_survey_banner_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if ResourceLoader.exists(EVENT_SCENE):
				SceneRouter.change_scene(EVENT_SCENE)

func _apply_typography() -> void:
	## 隊長名は本文フォント（可読優先）。装飾見出しだと誤読・溢れやすい。
	UiTypography.apply_body(_label_player_name, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_player_level, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	HeaderCurrencyHelper.apply_to_row($HubView/TopBar/TopBarRow)
	UiTypography.apply_display(_label_daily_title, UiTypography.SIZE_BODY_SMALL)
	UiTypography.apply_caption(_label_daily_reset)
	UiTypography.apply_display(_portrait_glyph, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_menu_title, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)

func _decorate_panels() -> void:
	_player_card.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$HubView/LeftMenuPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	$HubView/DailyMissionPanel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	## CurrencyStrip（所持金〜発見）は非表示。データ帯は TopBar のみ。
	var strip: Control = $HubView/CurrencyStrip as Control
	if strip != null:
		strip.visible = false
	$HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PortraitFrame.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)

func _build_left_menu() -> void:
	var to_remove: Array[Node] = []
	for child in _menu_vbox.get_children():
		if child.name != "LabelMenuTitle" and child.name != "SepMenu":
			to_remove.append(child)
	for child in to_remove:
		child.free()
	for entry in BottomNavHelper.SIDE_MENU_ENTRIES:
		var card_entry: Dictionary = entry.duplicate()
		if str(entry.get("id", "")) == "gacha" and not Constants.are_gacha_helpers_playable():
			card_entry["locked"] = true
		var card := NavUiTokens.make_side_menu_row(card_entry)
		var btn := _find_side_menu_button(card)
		if btn != null and not bool(card_entry.get("locked", false)):
			btn.pressed.connect(_on_menu_entry_pressed.bind(str(card_entry["id"])))
		_menu_vbox.add_child(card)
	if GameState.debug_full_unlock:
		var debug_entry := {
			"id": "debug",
			"title": "デバッグ",
			"icon_category": "",
			"icon_id": "",
			"locked": false,
		}
		var debug_card := NavUiTokens.make_side_menu_row(debug_entry)
		var debug_btn := _find_side_menu_button(debug_card)
		if debug_btn != null:
			debug_btn.pressed.connect(_on_menu_entry_pressed.bind("debug"))
		_menu_vbox.add_child(debug_card)

func _find_side_menu_button(card: Control) -> Button:
	for child in card.get_children():
		if child is Button:
			return child as Button
	return null

func _on_menu_entry_pressed(entry_id: String) -> void:
	if entry_id != "debug":
		_HubNpcHelper.queue_hint(entry_id)
	match entry_id:
		"adventure":
			_on_dungeon_button_pressed()
		"equipment":
			_on_equipment_button_pressed()
		"equipment_catalog":
			_on_equipment_catalog_pressed()
		"roster":
			_on_roster_button_pressed()
		"blacksmith":
			_on_blacksmith_button_pressed()
		"gacha":
			_on_gacha_button_pressed()
		"codex":
			_on_codex_button_pressed()
		"commander":
			_on_commander_button_pressed()
		"settings":
			_on_settings_button_pressed()
		"debug":
			_on_debug_menu_pressed()


func _on_debug_menu_pressed() -> void:
	if not GameState.debug_full_unlock:
		return
	if get_node_or_null("HubDebugMenuOverlay") != null:
		return
	var overlay: CanvasLayer = _HubDebugMenuOverlay.show_on(self)
	overlay.event_requested.connect(_on_debug_event_requested)
	overlay.closed.connect(func() -> void: pass)


func _on_debug_event_requested(entry_id: String) -> void:
	## はじめガイドはキューではなく即表示（他演出待ちに埋もれない）。
	if entry_id == "hub_guide":
		call_deferred("_debug_show_hub_guide")
		return
	## 調査室サイクル受取ポップも即表示（付与なしプレビュー）。
	if entry_id == "survey_claim_result":
		call_deferred("_debug_show_survey_claim_result")
		return
	## 2回目以降のレア入手通知は吹き出しへ即反映。
	if entry_id.begins_with("nina_rare_nav:"):
		call_deferred("_refresh_nina_nav")
		return
	## キュー後に拠点の演出チェーンを開始。
	call_deferred("_maybe_show_rank_up")


func _debug_show_hub_guide() -> void:
	## 再演は preview のみ。済みフラグを消すと Continue で再発する（既知バグ）。
	_HubSimpleGuideOverlay.show_on(self, true)


func _debug_show_survey_claim_result() -> void:
	## サンプル成果のみ。セーブ／所持は触らない。
	if get_node_or_null("SurveyClaimResultOverlay") != null:
		return
	var overlay := SurveyClaimResultOverlay.new()
	overlay.name = "SurveyClaimResultOverlay"
	add_child(overlay)
	overlay.present({
		"material_id": EquipmentEnhancer.BASE_ORE_ID,
		"material_qty": 24,
		"gold": 50,
		"token": 10,
		"weapon_id": "",
	})


func _ensure_valid_dungeon_selection() -> void:
	if not _is_dungeon_available(GameState.current_dungeon_id):
		GameState.current_dungeon_id = Constants.DEFAULT_DUNGEON_ID

func _is_dungeon_available(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	return DataRegistry.get_dungeon_data(dungeon_id) != null

func _update_display() -> void:
	_update_currency()
	_update_player_card()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	## 数値のみ。表示名「魔晶石」を TopBar に出さない（tooltip 残留・誤読防止）。
	_label_token.text = CurrencyHelper.format_amount()
	var token_chip: Control = $HubView/TopBar/TopBarRow/TokenChip as Control
	if token_chip != null:
		token_chip.tooltip_text = ""

func _update_player_card() -> void:
	_CommanderProfile.ensure_commander()
	var rank_text: String = _CommanderProfile.rank_display(false)
	var commander_name: String = _CommanderProfile.get_commander_name()
	## 隊長カードは等級＋名前。下段に次等級までの SP バー（P3-CMD-RANK-REWARD-001-4）。
	_label_player_name.text = "%s %s" % [rank_text, commander_name]
	_label_player_name.clip_text = false
	_label_player_name.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_label_player_level.text = ""
	_label_player_level.visible = false
	_ensure_rank_sp_bar()
	var progress: Dictionary = _CommanderProfile.progress_to_next_rank()
	_rank_sp_bar.value = float(progress.get("progress", 0.0))
	var next_rank: String = str(progress.get("next_rank", ""))
	if next_rank.is_empty():
		_rank_sp_bar.tooltip_text = "調査許可・最大等級"
	else:
		_rank_sp_bar.tooltip_text = "次等級 %s級まで %s" % [
			next_rank,
			str(progress.get("label", "")),
		]
	_portrait_art.texture = _CommanderProfile.rank_icon_texture()
	var has_rank_icon: bool = _portrait_art.texture != null
	_portrait_art.visible = has_rank_icon
	_portrait_glyph.visible = not has_rank_icon
	_portrait_glyph.text = _CommanderProfile.rank_glyph()
	var frame_tier: String = CombatUiFrames.TIER_NORMAL
	if _CommanderProfile.is_rank_at_least(_CommanderProfile.GOLD_SEAL_RANK):
		frame_tier = CombatUiFrames.TIER_CARD_ACTIVE
	$HubView/TopBar/TopBarRow/PlayerCard/PlayerRow/PortraitFrame.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(frame_tier)
	)
	var tooltip := "マイページを開く"
	var pending: int = _CommanderGiftBox.pending_count()
	if pending > 0:
		tooltip += "（配布物 %d）" % pending
	var sp_tip: String = ""
	if _rank_sp_bar != null:
		sp_tip = str(_rank_sp_bar.tooltip_text)
	if not sp_tip.is_empty():
		tooltip += "\n%s" % sp_tip
	_player_card.tooltip_text = tooltip
	if _gift_badge != null:
		var lbl: Label = _gift_badge.get_node_or_null("GiftBadgeLabel") as Label
		if lbl != null:
			lbl.text = str(pending) if pending < 100 else "99+"
		_gift_badge.visible = pending > 0

func _on_player_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_commander_button_pressed()

func _on_commander_button_pressed() -> void:
	if ResourceLoader.exists(COMMANDER_SCENE):
		SceneRouter.change_scene(COMMANDER_SCENE)

func _on_settings_button_pressed() -> void:
	if ResourceLoader.exists(SETTINGS_SCENE):
		SceneRouter.open_settings(SceneRouter.HOME_SCENE)

func _refresh_daily_missions() -> void:
	_update_daily_reset_label()
	_label_daily_title.text = (
		"デイリーミッション ●" if DailyMissionSystem.has_claimable() else "デイリーミッション"
	)
	for child in _mission_list.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = DailyMissionSystem.get_entries()
	for i in entries.size():
		_mission_list.add_child(_make_daily_row(i, entries[i]))
	_refresh_nina_nav()

func _update_daily_reset_label() -> void:
	_label_daily_reset.text = "リセットまで %s" % DailyMissionSystem.reset_countdown_text()


func _on_hub_tick() -> void:
	_update_daily_reset_label()
	EventSystem.ensure_active()
	_refresh_field_survey_banner()

func _make_daily_row(index: int, entry: Dictionary) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	wrap.add_child(row)
	var icon_host := Control.new()
	icon_host.custom_minimum_size = Vector2(36, 36)
	icon_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_host)
	var icon := TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = DailyMissionSystem.genre_icon_texture(str(entry.get("genre_id", "")))
	icon_host.add_child(icon)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = false
	title.text = str(entry.get("title", ""))
	UiTypography.apply_body(title, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	row.add_child(title)
	var progress_label := Label.new()
	var progress: int = int(entry.get("progress", 0))
	var target: int = int(entry.get("target_count", 1))
	progress_label.text = "%d/%d" % [progress, target]
	UiTypography.apply_caption(progress_label)
	row.add_child(progress_label)
	var reward := Label.new()
	reward.text = _format_daily_reward(entry)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_caption(reward)
	row.add_child(reward)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(60, 32)
	UiTypography.apply_menu_button(btn, false)
	var claimed: bool = bool(entry.get("claimed", false))
	var mission_id: String = str(entry.get("mission_id", ""))
	if claimed:
		btn.text = "済"
		btn.disabled = true
	elif bool(entry.get("can_claim", false)):
		btn.text = "受取"
		btn.pressed.connect(_on_daily_claim_pressed.bind(index))
	else:
		btn.text = "移動"
		var dest: String = _daily_mission_dest_scene(mission_id)
		if dest.is_empty():
			btn.disabled = true
		else:
			btn.disabled = false
			btn.pressed.connect(_on_daily_go_pressed.bind(dest))
	row.add_child(btn)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = maxf(float(target), 1.0)
	bar.value = float(progress)
	bar.show_percentage = false
	wrap.add_child(bar)
	return wrap

func _format_daily_reward(entry: Dictionary) -> String:
	var parts: PackedStringArray = []
	var gold: int = int(entry.get("reward_gold", 0))
	var token: int = int(entry.get("reward_gacha_token", 0))
	var mat_id: String = str(entry.get("reward_material_id", ""))
	var mat_qty: int = int(entry.get("reward_material_qty", 0))
	if gold > 0:
		parts.append("%dG" % gold)
	if token > 0:
		parts.append("%s×%d" % [CurrencyHelper.DISPLAY_NAME, token])
	if not mat_id.is_empty() and mat_qty > 0:
		parts.append("%s×%d" % [DataRegistry.get_material_name(mat_id), mat_qty])
	if parts.is_empty():
		return "—"
	return " / ".join(parts)

func _on_daily_claim_pressed(index: int) -> void:
	var from_global: Vector2 = _daily_claim_origin_global(index)
	var result: Dictionary = DailyMissionSystem.claim(index)
	if not bool(result.get("ok", false)):
		return
	SaveManager.save_game()
	_refresh_daily_missions()
	_play_daily_claim_fx(from_global, result)


func _daily_claim_origin_global(index: int) -> Vector2:
	if index >= 0 and index < _mission_list.get_child_count():
		var row: Control = _mission_list.get_child(index) as Control
		if row != null:
			return row.get_global_rect().get_center()
	return _mission_list.get_global_rect().get_center()


func _play_daily_claim_fx(from_global: Vector2, result: Dictionary) -> void:
	var gold_chip: Control = $HubView/TopBar/TopBarRow/GoldChip as Control
	var token_chip: Control = $HubView/TopBar/TopBarRow/TokenChip as Control
	var rewards: Array = []
	var gold: int = int(result.get("gold", 0))
	if gold > 0:
		var gold_tex: Texture2D = load(_GOLD_ICON_PATH) as Texture2D
		if gold_tex != null and gold_chip != null:
			rewards.append({"texture": gold_tex, "target": gold_chip, "amount": gold})
	var tokens: int = int(result.get("gacha_token", 0))
	if tokens > 0:
		var token_tex: Texture2D = CurrencyHelper.get_icon_texture()
		if token_tex != null and token_chip != null:
			rewards.append({"texture": token_tex, "target": token_chip, "amount": tokens})
	var mat_id: String = str(result.get("material_id", ""))
	var mat_qty: int = int(result.get("material_qty", 0))
	if not mat_id.is_empty() and mat_qty > 0:
		var mat_tex: Texture2D = IconPaths.get_icon_texture(mat_id, "material")
		## CurrencyStrip 撤去後は TopBar 金チップへ飛ばす。
		var mat_target: Control = gold_chip
		if mat_tex != null and mat_target != null:
			rewards.append({"texture": mat_tex, "target": mat_target, "amount": mat_qty})
	if rewards.is_empty():
		_update_display()
		return
	_CurrencyGainFx.play(self, from_global, rewards, _update_display)

func _on_dungeon_button_pressed() -> void:
	SceneRouter.change_scene(DUNGEON_SELECT_SCENE)

func _daily_mission_dest_scene(mission_id: String) -> String:
	match mission_id:
		"daily_clear_run", "daily_kill_enemies", "daily_kill_elite", "daily_kill_boss":
			return DUNGEON_SELECT_SCENE
		"daily_craft_item", "daily_enhance_item", "daily_alchemy_item", "daily_dismantle_item":
			return BLACKSMITH_SCENE
		"daily_gacha_pull":
			return GACHA_SCENE if ResourceLoader.exists(GACHA_SCENE) else ""
		_:
			return DUNGEON_SELECT_SCENE

func _on_daily_go_pressed(scene_path: String) -> void:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return
	SceneRouter.change_scene(scene_path)

func _on_equipment_button_pressed() -> void:
	SceneRouter.change_scene(EQUIPMENT_SCENE)

func _on_equipment_catalog_pressed() -> void:
	if ResourceLoader.exists(EQUIPMENT_CATALOG_SCENE):
		SceneRouter.change_scene(EQUIPMENT_CATALOG_SCENE)

func _on_blacksmith_button_pressed() -> void:
	SceneRouter.change_scene(BLACKSMITH_SCENE)

func _on_survey_button_pressed() -> void:
	SceneRouter.change_scene(SURVEY_SCENE)

func _on_codex_button_pressed() -> void:
	SceneRouter.change_scene(CODEX_SCENE)

func _on_gacha_button_pressed() -> void:
	if not Constants.are_gacha_helpers_playable():
		return
	if ResourceLoader.exists(GACHA_SCENE):
		SceneRouter.change_scene(GACHA_SCENE)

func _on_roster_button_pressed() -> void:
	if ResourceLoader.exists(ROSTER_SCENE):
		SceneRouter.change_scene(ROSTER_SCENE)
