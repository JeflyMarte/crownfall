extends Control

# 戦闘演出用アクセントフォント（重厚ゴシック）。ダメージ数値/スキル名のインパクト用。
# preload だと未インポート時にスクリプト全体のロードが失敗するため、ランタイム load＋null許容にする。
const ACCENT_FONT_PATH: String = "res://assets/fonts/DelaGothicOne-Regular.ttf"
var _accent_font: Font = null

const FALLBACK_ATTACK: int = 10
const CRITICAL_MULTIPLIER: float = 1.5
# 敵DEFの逓減軽減係数。軽減率 = K/(K+DEF)。flat減算は小ダメージ多段で0化するため割合式を採用。
const DEFENSE_MITIGATION_K: float = 100.0
## Biome 属性相性（P3-D099）。有利属性一致時の与ダメ倍率。
const BIOME_FAVORED_BONUS: float = 1.15
const HEAL_AMOUNT: int = 10
# P3-D084: CT/ATB の 1 パルス（1 行動）間隔。x1=通常 / x2=倍速。
const SPEED_X1: float = 0.55
const SPEED_X2: float = 0.28
const AUTO_DELAY_X1: float = 1.2
const AUTO_DELAY_X2: float = 0.6
# 味方CHRの「見える体格」を揃える目標高さ（実体=α領域の高さ基準）
const CHR_BODY_TARGET_PX: float = 140.0
const _LOG_MAX: int = 60

const ENEMY_SPRITE_MAP: Dictionary = {
	"sepia_hound": "res://resources/animation/ENM_SepiaHound.tres",
	"rune_roach": "res://resources/animation/ENM_RuneRoach.tres",
	"crystal_hedgehog": "res://resources/animation/ENM_CrystalHedgehog.tres",
	"crown_eater_rat": "res://resources/animation/ENM_CrownEaterRat.tres",
	"clock_moth": "res://resources/animation/ENM_ClockMoth.tres",
}
const BOSS_SPRITE_MAP: Dictionary = {
	"mourngate": "res://resources/animation/BOSS_Serdion.tres",
}
const CHR_SPRITE_MAP: Dictionary = {
	"swordsman": "res://resources/animation/CHR_Swordsman.tres",
	"ranger": "res://resources/animation/CHR_Ranger.tres",
	"alchemist": "res://resources/animation/CHR_Alchemist.tres",
	"vanguard": "res://resources/animation/CHR_Vanguard.tres",
	"beast_tamer": "res://resources/animation/CHR_BeastTamer.tres",
}
const BATTLE_BG_MAP: Dictionary = {
	"mourngate": "res://assets/dungeon/mourngate/env/BG_Battle_Mourngate.png",
}
const STATUS_ICON_DEF: Dictionary = {
	"poison": {"abbrev": "毒", "color": Color(0.25, 0.75, 0.3)},
	"chill": {"abbrev": "冷", "color": Color(0.35, 0.65, 0.95)},
	"shock": {"abbrev": "感", "color": Color(0.95, 0.85, 0.2)},
	"ignite": {"abbrev": "炎", "color": Color(0.95, 0.4, 0.15)},
	"curse": {"abbrev": "呪", "color": Color(0.55, 0.25, 0.75)},
	"stun": {"abbrev": "麻", "color": Color(0.7, 0.7, 0.75)},
	"fear": {"abbrev": "恐", "color": Color(0.55, 0.35, 0.6)},
	"vulnerable": {"abbrev": "脆", "color": Color(0.95, 0.45, 0.45)},
	"armor_break": {"abbrev": "破", "color": Color(0.8, 0.6, 0.3)},
	"mark": {"abbrev": "標", "color": Color(0.95, 0.35, 0.55)},
	"empower": {"abbrev": "攻", "color": Color(0.95, 0.55, 0.2)},
	"guard": {"abbrev": "防", "color": Color(0.4, 0.55, 0.85)},
}
const HEAL_SKILL_BASE: int = 14
const STATUS_ICON_SIZE: float = 26.0
const STATUS_ICON_GAP: float = 3.0
const VFX_HIT_PATH: String = "res://resources/animation/FX_Hit_Normal.tres"
const VFX_HEAL_PATH: String = "res://resources/animation/FX_Heal.tres"
## 属性ごとの演出色（命中VFXの modulate / スキル名フォント色に共用）。
## 未設定/無属性は WHITE（VFX）・既定の青系（スキル名）にフォールバック。
const ELEMENT_COLOR: Dictionary = {
	"fire": Color(1.0, 0.5, 0.2),
	"ice": Color(0.45, 0.82, 1.0),
	"thunder": Color(1.0, 0.93, 0.35),
	"dark": Color(0.78, 0.5, 1.0),
	"holy": Color(1.0, 0.93, 0.6),
}
## 属性別の専用命中VFX（任意）。CC0素材から作った SpriteFrames を置けば自動採用。
## 未配置の属性は FX_Hit_Normal をティント着色してフォールバックする（非破壊）。
const ELEMENT_VFX_PATH: Dictionary = {
	"fire": "res://resources/animation/FX_Hit_Fire.tres",
	"ice": "res://resources/animation/FX_Hit_Ice.tres",
	"thunder": "res://resources/animation/FX_Hit_Thunder.tres",
	"dark": "res://resources/animation/FX_Hit_Dark.tres",
	"holy": "res://resources/animation/FX_Hit_Holy.tres",
}
const SkillExecutorScript: Script = preload("res://scripts/combat/SkillExecutor.gd")
const ElementResolverScript: Script = preload("res://scripts/combat/ElementResolver.gd")
const AffixStatCalculatorScript: Script = preload("res://scripts/equipment/AffixStatCalculator.gd")
const JobStatCalculatorScript: Script = preload("res://scripts/equipment/JobStatCalculator.gd")

var _auto_delay: float = AUTO_DELAY_X1
var _auto_progress_paused_remaining: float = 0.0
var _auto_progress_finishes: bool = false
var _discovery_toast_tween: Tween
var _skill_executor: RefCounted = SkillExecutorScript.new()
var _is_paused: bool = false
var _fast_run_enabled: bool = false
var _btn_fast_run: Button = null
# ラウンド処理中フラグ（P3-D083・逐次awaitの多重実行防止）
var _round_active: bool = false
var _request_scroll_to_bottom: bool = false

@onready var _boss_sprite: AnimatedSprite2D = $BossSprite
@onready var _enemy_sprite: AnimatedSprite2D = $EnemySprite
@onready var _hit_vfx_sprite: AnimatedSprite2D = $HitVfxSprite
@onready var _heal_vfx_sprite: AnimatedSprite2D = $HealVfxSprite
@onready var _damage_numbers_layer: CanvasLayer = $DamageNumbers
@onready var _discovery_toast: PanelContainer = $DiscoveryToastLayer/DiscoveryToast
@onready var _label_discovery_text: Label = $DiscoveryToastLayer/DiscoveryToast/LabelDiscoveryText
@onready var _chr_sprite_0: AnimatedSprite2D = $ChrSprite0
@onready var _chr_sprite_1: AnimatedSprite2D = $ChrSprite1
@onready var _chr_sprite_2: AnimatedSprite2D = $ChrSprite2
@onready var _chr_sprite_3: AnimatedSprite2D = $ChrSprite3

@onready var _battle_log_scroll: ScrollContainer = $MainVBox/BattleLogPanel/BattleLogScroll
@onready var _battle_log_content: VBoxContainer = $MainVBox/BattleLogPanel/BattleLogScroll/BattleLogContent
@onready var _party_status_panel: PanelContainer = $MainVBox/PartyStatusPanel
@onready var _party_cards_row: HBoxContainer = $MainVBox/PartyStatusPanel/PartyCardsRow
@onready var _narrative_panel: PanelContainer = $MainVBox/NarrativePanel
@onready var _label_narrative: Label = $MainVBox/NarrativePanel/LabelNarrative
@onready var _label_dungeon_name: Label = $MainVBox/HeaderBar/LabelDungeonName
@onready var _label_room: Label = $MainVBox/HeaderBar/LabelRoom
@onready var _label_enemy: Label = $MainVBox/BottomZone/LabelEnemy
@onready var _room_tile_bg: TextureRect = $MainVBox/BattlefieldArea/RoomTileBg
@onready var _room_object: TextureRect = $MainVBox/BattlefieldArea/RoomObject
@onready var _combat_tier_frame: PanelContainer = $MainVBox/BattlefieldArea/CombatTierFrame
@onready var _label_combat_tier: Label = $MainVBox/BattlefieldArea/CombatTierFrame/LabelCombatTier
@onready var _label_status_enemy: Label = $MainVBox/BottomZone/LabelStatusEnemy
@onready var _label_status_party: Label = $MainVBox/BottomZone/LabelStatusParty
@onready var _auto_combat_row: HBoxContainer = $MainVBox/BottomZone/AutoCombatRow
@onready var _non_combat_zone: VBoxContainer = $MainVBox/BottomZone/NonCombatZone
@onready var _btn_next_room: Button = $MainVBox/BottomZone/NonCombatZone/ButtonNextRoom
@onready var _btn_finish: Button = $MainVBox/BottomZone/NonCombatZone/ButtonFinish
@onready var _menu_overlay: PanelContainer = $MenuOverlay
@onready var _pause_overlay: Control = $PauseOverlay
@onready var _hp_bar_chr0: ProgressBar = $HpBarChr0
@onready var _hp_bar_chr1: ProgressBar = $HpBarChr1
@onready var _hp_bar_chr2: ProgressBar = $HpBarChr2
@onready var _hp_bar_chr3: ProgressBar = $HpBarChr3
@onready var _hp_bar_enemy: ProgressBar = $HpBarEnemy
@onready var _enemy_nameplate: Label = $EnemyNamePlate
@onready var _transition_overlay: ColorRect = $TransitionLayer/TransitionOverlay
@onready var _label_transition: Label = $TransitionLayer/TransitionOverlay/LabelTransition

var _chr_sprites: Array[AnimatedSprite2D] = []
# 1フレームのみの idle 素材（Ranger/Alchemist 等）向けのコード擬似 idle（呼吸）tween 保持
var _chr_idle_tweens: Array = [null, null, null, null]
# メンバーごとの表示中スキル名ラベル（重なり防止のため tick 毎に置換・段組み）
var _chr_skill_labels: Array = [[], [], [], []]
# 同一メンバーが同 tick に複数スキルを発動した際、ラベルを縦にずらす間隔(px)
const SKILL_LABEL_STACK_GAP: float = 34.0
var _chr_hp_bars: Array[ProgressBar] = []
var _party_card_hp_bars: Array[ProgressBar] = []
var _party_card_hp_labels: Array[Label] = []
var _party_card_roots: Array[Control] = []
var _status_icon_swarm_rows: Array[HBoxContainer] = []
var _status_icon_chr_rows: Array[HBoxContainer] = []

# 群れ（複数敵）表示スロット（P3-D082）。slot0 は既存ノード（_enemy_sprite/_hp_bar_enemy/_enemy_nameplate）を流用し、
# 2体目以降は duplicate で動的生成する。ボス戦では使用しない（BossSprite を使う）。
var _swarm_sprites: Array[AnimatedSprite2D] = []
var _swarm_hp_bars: Array[ProgressBar] = []
var _swarm_nameplates: Array[Label] = []
const SWARM_SPACING: float = 145.0
const SWARM_BASE_X: float = 500.0
const SWARM_BASE_Y: float = 515.0
# 編成スロット別の戦闘配置（DungeonScene ルート座標・足元基準）。
# スロット 0,1=前衛 / 2,3=後衛（combat_index ではなく formation_slot で参照）。
const FORMATION_SLOT_POSITIONS: Array[Vector2] = [
	Vector2(265, 668),  # 0 前衛左
	Vector2(395, 718),  # 1 前衛右（敵寄り）
	Vector2(125, 728),  # 2 後衛左（奥）
	Vector2(265, 748),  # 3 後衛右
]
const PARTY_CARD_SLOT_COUNT: int = 4
const PARTY_CARD_ICON_PX: float = 80.0
const PARTY_CARD_EMPTY_MODULATE: Color = Color(0.45, 0.45, 0.5, 0.55)
const PARTY_CARD_DEAD_MODULATE: Color = Color(0.55, 0.55, 0.55, 0.75)
const UI_TEXT_PRIMARY: Color = Color(0.98, 0.96, 0.92, 1.0)
const UI_TEXT_SECONDARY: Color = Color(0.92, 0.90, 0.84, 1.0)
const UI_TEXT_WEAPON: Color = Color(0.95, 0.91, 0.82, 1.0)
const CHR_HP_BAR_FRONT_Y_OFFSET: float = 50.0
const CHR_HP_BAR_BACK_Y_OFFSET: float = -50.0
const CHR_HP_BAR_GAP_ABOVE_SPRITE: float = 12.0
const CHR_HP_BAR_HEIGHT: float = 8.0
const CHR_STATUS_GAP_ABOVE_BAR: float = 4.0

# 行動順（ターンオーダー）表示（P3-D083）。
var _turn_order_row: HBoxContainer
var _turn_order_items: Array = []  # [{kind, index, node, icon}]
const TURN_ORDER_ICON_PX: float = 72.0
const TURN_ORDER_FRAME_PAD: float = 6.0
const TURN_ORDER_GAP: float = 10.0
const TURN_ORDER_CENTER_X: float = 360.0
const TURN_ORDER_Y: float = 52.0

func _ready() -> void:
	_btn_next_room.pressed.connect(_on_next_room_pressed)
	_btn_finish.pressed.connect(_on_finish_button_pressed)
	$CombatTimer.timeout.connect(_on_combat_timer_timeout)
	$AutoProgressTimer.timeout.connect(_on_auto_progress_timeout)
	$MainVBox/HeaderBar/ButtonMenu.pressed.connect(_on_menu_button_pressed)
	$MainVBox/HeaderBar/ButtonSpeedX1.pressed.connect(_on_speed_x1_pressed)
	$MainVBox/HeaderBar/ButtonSpeedX2.pressed.connect(_on_speed_x2_pressed)
	_ensure_fast_run_button()
	$MainVBox/HeaderBar/ButtonStop.pressed.connect(_on_stop_pressed)
	_menu_overlay.get_node("MenuVBox/ButtonFinishFromMenu").pressed.connect(_on_menu_finish_pressed)
	_menu_overlay.get_node("MenuVBox/ButtonCloseMenu").pressed.connect(_on_close_menu_pressed)
	$MainVBox/BottomZone/AutoCombatRow/ButtonPause.pressed.connect(_on_pause_button_pressed)
	_pause_overlay.get_node("PausePanel/PauseVBox/ButtonPauseResume").pressed.connect(_on_pause_resume_pressed)
	_pause_overlay.get_node("PausePanel/PauseVBox/ButtonPauseRetire").pressed.connect(_on_pause_retire_pressed)
	EventBus.weapon_obtained.connect(_on_weapon_obtained)
	_hit_vfx_sprite.animation_finished.connect(func(): _hit_vfx_sprite.visible = false)
	_heal_vfx_sprite.animation_finished.connect(func(): _heal_vfx_sprite.visible = false)
	_chr_sprites = [_chr_sprite_0, _chr_sprite_1, _chr_sprite_2, _chr_sprite_3]
	_chr_hp_bars = [_hp_bar_chr0, _hp_bar_chr1, _hp_bar_chr2, _hp_bar_chr3]
	_init_status_icon_rows()
	_init_turn_order_row()
	for sprite: AnimatedSprite2D in _chr_sprites:
		sprite.animation_finished.connect(func():
			if sprite.visible and sprite.sprite_frames != null:
				if sprite.animation in ["attack", "hurt"]:
					sprite.play("idle")
		)
	_enemy_sprite.animation_finished.connect(func():
		if _enemy_sprite.visible and _enemy_sprite.sprite_frames != null:
			if _enemy_sprite.animation in ["attack", "hurt"]:
				_enemy_sprite.play("idle")
	)
	_boss_sprite.animation_finished.connect(func():
		if _boss_sprite.visible and _boss_sprite.sprite_frames != null:
			if _boss_sprite.animation in ["attack", "hurt"]:
				_boss_sprite.play("idle")
	)
	_style_hp_bars()
	var dungeon_id: String = GameState.get_active_dungeon_id()
	$DungeonController.start_dungeon(dungeon_id)
	$CombatController.reset_party_hp_for_run()
	GameState.last_run_accessory_dropped = ""
	GameState.last_run_relic_dropped = ""
	GameState.last_run_outcome = ""
	GameState.last_run_exploration_policy = ""
	GameState.begin_run_material_tracking()
	_update_room_label()
	_update_room_art()
	_update_enemy_label()
	_update_hp_bars()
	_update_next_room_button()
	var dungeon_name: String = "ダンジョン"
	if $DungeonController.current_dungeon_data != null:
		dungeon_name = $DungeonController.current_dungeon_data.display_name
		_label_dungeon_name.text = dungeon_name
	_setup_weather()
	var weather_suffix: String = ""
	if not GameState.get_weather().is_empty():
		weather_suffix = "（天候: %s）" % CombatWeather.label(GameState.get_weather())
	_set_narrative("%s の探索を開始した%s" % [dungeon_name, weather_suffix])
	if not dungeon_id.is_empty():
		_try_register_discovery("dungeon", dungeon_id)
	_update_combat_visibility()
	_start_auto_progress()

# 天候の可視化（P3-D101）。HUD ラベル併記＋procedural オーバーレイ（新規アセット無し）。
func _setup_weather() -> void:
	var weather: String = GameState.get_weather()
	if weather.is_empty():
		return
	if is_instance_valid(_label_dungeon_name):
		_label_dungeon_name.text += "  〔%s〕" % CombatWeather.label(weather)
	var layer := CanvasLayer.new()
	layer.name = "WeatherLayer"
	layer.layer = 3
	add_child(layer)
	var view: Vector2 = get_viewport_rect().size
	match weather:
		CombatWeather.NIGHT:
			var tint := ColorRect.new()
			tint.color = Color(0.04, 0.06, 0.16, 0.30)
			tint.set_anchors_preset(Control.PRESET_FULL_RECT)
			tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(tint)
		CombatWeather.FOG:
			var haze := ColorRect.new()
			haze.color = Color(0.76, 0.78, 0.82, 0.16)
			haze.set_anchors_preset(Control.PRESET_FULL_RECT)
			haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(haze)
			var tw := create_tween().set_loops()
			tw.tween_property(haze, "color:a", 0.24, 2.2).set_trans(Tween.TRANS_SINE)
			tw.tween_property(haze, "color:a", 0.10, 2.2).set_trans(Tween.TRANS_SINE)
		CombatWeather.RAIN:
			var rain := CPUParticles2D.new()
			rain.texture = _make_raindrop_texture()
			rain.amount = 150
			rain.lifetime = 0.7
			rain.local_coords = false
			rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			rain.emission_rect_extents = Vector2(view.x * 0.6, 2.0)
			rain.position = Vector2(view.x * 0.5, -12.0)
			rain.direction = Vector2(0.1, 1.0)
			rain.spread = 4.0
			rain.gravity = Vector2(20.0, 900.0)
			rain.initial_velocity_min = 420.0
			rain.initial_velocity_max = 540.0
			rain.modulate = Color(0.75, 0.82, 1.0, 0.7)
			rain.emitting = true
			layer.add_child(rain)

func _make_raindrop_texture() -> Texture2D:
	var img := Image.create(2, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.86, 1.0, 0.55))
	return ImageTexture.create_from_image(img)

func _process(_delta: float) -> void:
	if _request_scroll_to_bottom:
		_request_scroll_to_bottom = false
		_battle_log_scroll.scroll_vertical = _battle_log_scroll.get_v_scroll_bar().max_value

func _set_narrative(text: String) -> void:
	_label_narrative.text = text

func _append_log(text: String) -> void:
	for line: String in text.split("\n"):
		if line.is_empty():
			continue
		var entry := Label.new()
		entry.text = line
		entry.add_theme_color_override("font_color", _log_color(line))
		entry.add_theme_constant_override("outline_size", 2)
		entry.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		entry.add_theme_font_size_override("font_size", 24)
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_battle_log_content.add_child(entry)
	# 上限超過分を間引く。queue_free() は遅延削除で get_child_count() が即座に減らず
	# while が無限ループ→フリーズするため、remove_child() で即時 detach してから解放する。
	while _battle_log_content.get_child_count() > _LOG_MAX:
		var oldest: Node = _battle_log_content.get_child(0)
		_battle_log_content.remove_child(oldest)
		oldest.queue_free()
	_request_scroll_to_bottom = true

func _log_color(line: String) -> Color:
	if "CRITICAL" in line:
		return Color(1.0, 0.9, 0.2)
	if "敵の攻撃" in line:
		return Color(1.0, 0.55, 0.55)
	if line.begins_with("【ボス】") or line.begins_with("【エリート】") or line.begins_with("【中ボス】"):
		return Color(1.0, 0.65, 0.2)
	return Color.WHITE

func _style_hp_bars() -> void:
	_style_hp_bar_readable(_hp_bar_enemy, Color(0.85, 0.25, 0.25))
	for bar: ProgressBar in _chr_hp_bars:
		_style_hp_bar_readable(bar, Color(0.25, 0.82, 0.32))
	_style_enemy_nameplate(_enemy_nameplate)

func _style_hp_bar_readable(bar: ProgressBar, fill_color: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.06, 0.08, 0.9)
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color(0, 0, 0, 0.95)
	bg_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg_style)

func _style_readable_label(label: Label, color: Color, outline_size: int = 3) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))

func _style_enemy_nameplate(label: Label) -> void:
	_style_readable_label(label, Color(1.0, 0.97, 0.88, 1.0), 5)

func _update_hp_bars() -> void:
	var in_combat: bool = $CombatController.is_in_combat
	var on_combat_floor: bool = $DungeonController.is_combat_room()
	if _boss_sprite.visible:
		# ボス: 単体オーバーレイ
		_hp_bar_enemy.visible = in_combat
		if _hp_bar_enemy.visible:
			_hp_bar_enemy.max_value = $CombatController.get_enemy_max_hp()
			_hp_bar_enemy.value = $CombatController.current_enemy_hp
			_position_enemy_overlays(_boss_sprite)
		else:
			_enemy_nameplate.visible = false
	else:
		# 通常/群れ: スロットごとに HPバー＋ネームプレートを更新（死亡スロットは隠す）
		for slot in _swarm_sprites.size():
			var spr: AnimatedSprite2D = _swarm_sprites[slot]
			var bar: ProgressBar = _swarm_hp_bars[slot]
			var np: Label = _swarm_nameplates[slot]
			var alive: bool = $CombatController.is_enemy_slot_alive(slot)
			var show: bool = in_combat and spr.visible and alive
			bar.visible = show
			if show:
				bar.max_value = $CombatController.get_enemy_max_hp_at(slot)
				bar.value = $CombatController.get_enemy_hp_at(slot)
				_position_swarm_overlay(slot)
			else:
				np.visible = false
	for i: int in _chr_hp_bars.size():
		var bar: ProgressBar = _chr_hp_bars[i]
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		bar.visible = sprite.visible and on_combat_floor
		if bar.visible and i < $CombatController.party_combat_hp.size():
			bar.max_value = $CombatController.party_max_hp[i]
			bar.value = $CombatController.party_combat_hp[i]
			_set_hp_bar_above_sprite(bar, sprite, _formation_slot_for_combat_index(i))
	_update_party_cards_hp()

func _chr_hp_bar_row_y_offset(formation_slot: int) -> float:
	if formation_slot <= 1:
		return CHR_HP_BAR_FRONT_Y_OFFSET
	if formation_slot <= 3:
		return CHR_HP_BAR_BACK_Y_OFFSET
	return 0.0

func _chr_hp_bar_top_y(sprite: AnimatedSprite2D, formation_slot: int) -> float:
	return _sprite_top_y(sprite) - CHR_HP_BAR_GAP_ABOVE_SPRITE - CHR_HP_BAR_HEIGHT + _chr_hp_bar_row_y_offset(formation_slot)

func _sprite_visual_center(sprite: AnimatedSprite2D) -> Vector2:
	return sprite.global_position + sprite.offset

func _set_hp_bar_above_sprite(bar: ProgressBar, sprite: AnimatedSprite2D, formation_slot: int = 0) -> void:
	const BAR_HALF_W: float = 40.0
	var center: Vector2 = _sprite_visual_center(sprite)
	var bar_ty: float = _chr_hp_bar_top_y(sprite, formation_slot)
	bar.offset_left = center.x - BAR_HALF_W
	bar.offset_top = bar_ty
	bar.offset_right = center.x + BAR_HALF_W
	bar.offset_bottom = bar_ty + CHR_HP_BAR_HEIGHT

# 注: 以下 _sprite_top_y は offset 補正込み
func _sprite_top_y(sprite: AnimatedSprite2D) -> float:
	if sprite.sprite_frames != null:
		var anim: String = sprite.animation
		if not sprite.sprite_frames.has_animation(anim):
			anim = "idle"
		if sprite.sprite_frames.has_animation(anim):
			var tex: Texture2D = sprite.sprite_frames.get_frame_texture(anim, 0)
			if tex != null:
				var frame_h: float = float(tex.get_height()) * absf(sprite.scale.y)
				var center_y: float = _sprite_visual_center(sprite).y
				return center_y - frame_h * 0.5
	return sprite.global_position.y

# 敵HPバー＋頭上ネームプレートを、スプライト実上端の上に積んで配置（重なり回避）。
# 小型敵は従来位置を下限に維持し、大型(ボス)時のみ上方向へ押し上げる。
func _position_enemy_overlays(sprite: AnimatedSprite2D) -> void:
	const BAR_HALF_W: float = 40.0
	const BAR_HEIGHT: float = 10.0
	const NAME_HALF_W: float = 120.0
	const NAME_HEIGHT: float = 30.0
	const GAP_ABOVE_SPRITE: float = 12.0
	const GAP_BAR_NAME: float = 6.0
	var center: Vector2 = _sprite_visual_center(sprite)
	var cx: float = center.x
	var top_y: float = _sprite_top_y(sprite)
	# HPバー: 従来 -50 を下限に、スプライト上端より上に来るよう調整
	var bar_ty: float = minf(center.y - 50.0, top_y - GAP_ABOVE_SPRITE - BAR_HEIGHT)
	_hp_bar_enemy.offset_left = cx - BAR_HALF_W
	_hp_bar_enemy.offset_top = bar_ty
	_hp_bar_enemy.offset_right = cx + BAR_HALF_W
	_hp_bar_enemy.offset_bottom = bar_ty + BAR_HEIGHT
	var enemy_data: Resource = $CombatController.current_enemy_data
	if enemy_data == null:
		_enemy_nameplate.visible = false
		return
	var lv: int = $CombatController.enemy_level
	_enemy_nameplate.text = "Lv%d %s" % [lv, enemy_data.display_name]
	# 名前は HPバーのさらに上
	var name_ty: float = bar_ty - GAP_BAR_NAME - NAME_HEIGHT
	_enemy_nameplate.offset_left = cx - NAME_HALF_W
	_enemy_nameplate.offset_top = name_ty
	_enemy_nameplate.offset_right = cx + NAME_HALF_W
	_enemy_nameplate.offset_bottom = name_ty + NAME_HEIGHT
	_enemy_nameplate.visible = true

func _init_status_icon_rows() -> void:
	for _i in _chr_sprites.size():
		var row: HBoxContainer = _make_status_icon_row()
		add_child(row)
		_status_icon_chr_rows.append(row)

func _ensure_swarm_status_icon_rows(n: int) -> void:
	while _status_icon_swarm_rows.size() < n:
		var row: HBoxContainer = _make_status_icon_row()
		add_child(row)
		_status_icon_swarm_rows.append(row)

func _make_status_icon_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(STATUS_ICON_GAP))
	row.visible = false
	return row

func _build_status_icon(entry: Dictionary) -> PanelContainer:
	var effect_id: String = entry.get("effect_id", "")
	var def: Dictionary = STATUS_ICON_DEF.get(effect_id, {"abbrev": "?", "color": Color(0.45, 0.45, 0.45)})
	var stacks: int = int(entry.get("stacks", 1))
	var abbrev: String = def["abbrev"]
	if stacks > 1:
		abbrev += str(stacks)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = def["color"]
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = Color(0, 0, 0, 0.85)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = abbrev
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)
	var display_name: String = entry.get("display_name", effect_id)
	var tooltip: String = display_name
	if stacks > 1:
		tooltip += "×%d" % stacks
	var ticks: int = int(entry.get("remaining_ticks", 0))
	if ticks > 0:
		tooltip += " (%dt)" % ticks
	panel.tooltip_text = tooltip
	return panel

func _populate_status_icon_row(row: HBoxContainer, statuses: Array) -> void:
	for child: Node in row.get_children():
		child.queue_free()
	for entry: Dictionary in statuses:
		row.add_child(_build_status_icon(entry))

func _set_status_row_above_sprite(row: HBoxContainer, sprite: AnimatedSprite2D, statuses: Array, formation_slot: int = -1) -> void:
	_populate_status_icon_row(row, statuses)
	var show: bool = sprite.visible and not statuses.is_empty()
	row.visible = show
	if not show:
		return
	var count: int = statuses.size()
	var total_w: float = count * STATUS_ICON_SIZE + maxf(0.0, float(count - 1)) * STATUS_ICON_GAP
	var center: Vector2 = _sprite_visual_center(sprite)
	var icon_y: float
	if formation_slot >= 0:
		icon_y = _chr_hp_bar_top_y(sprite, formation_slot) - CHR_STATUS_GAP_ABOVE_BAR - STATUS_ICON_SIZE
	else:
		var top_y: float = _sprite_top_y(sprite)
		icon_y = top_y - STATUS_ICON_SIZE - 4.0
	row.position = Vector2(center.x - total_w * 0.5, icon_y)

func _update_status_icons() -> void:
	var in_combat: bool = $CombatController.is_in_combat
	if not in_combat:
		for row: HBoxContainer in _status_icon_swarm_rows:
			row.visible = false
		for row: HBoxContainer in _status_icon_chr_rows:
			row.visible = false
		return
	# ボスはドット絵が大きく状態異常アイコンが重なるため非表示。
	if _boss_sprite.visible:
		for row: HBoxContainer in _status_icon_swarm_rows:
			row.visible = false
	else:
		_ensure_swarm_status_icon_rows(_swarm_sprites.size())
		for slot: int in _swarm_sprites.size():
			if slot >= _status_icon_swarm_rows.size():
				continue
			var row: HBoxContainer = _status_icon_swarm_rows[slot]
			if not $CombatController.is_enemy_slot_alive(slot):
				row.visible = false
				continue
			_set_status_row_above_sprite(
				row,
				_swarm_sprites[slot],
				$CombatController.get_enemy_status_list_at(slot)
			)
	for i: int in _status_icon_chr_rows.size():
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		var statuses: Array = $CombatController.get_member_status_list(i)
		_set_status_row_above_sprite(
			_status_icon_chr_rows[i],
			sprite,
			statuses,
			_formation_slot_for_combat_index(i)
		)

func _get_room_type_name() -> String:
	match $DungeonController.current_room_type:
		Enums.RoomType.START:    return "開始"
		Enums.RoomType.COMBAT:   return "戦闘"
		Enums.RoomType.EVENT:    return "イベント"
		Enums.RoomType.TREASURE: return "宝箱"
		Enums.RoomType.ELITE:    return "エリート"
		Enums.RoomType.TRAP:     return "罠"
		Enums.RoomType.BOSS:     return "ボス"
		Enums.RoomType.EXIT:     return "出口"
		Enums.RoomType.HEAL:     return "回復"
	return ""

func _update_room_label() -> void:
	if $DungeonController.current_dungeon_data == null:
		_label_room.text = "部屋 — / —"
		return
	var idx: int = $DungeonController.current_room_index + 1
	var total: int = $DungeonController.get_total_rooms()
	_label_room.text = "B1 — 部屋 %d/%d [%s]" % [idx, total, _get_room_type_name()]
	var badge_color: Color = Color.WHITE
	match $DungeonController.current_room_type:
		Enums.RoomType.ELITE: badge_color = Color(1.0, 0.7, 0.2)
		Enums.RoomType.TRAP: badge_color = Color(1.0, 0.45, 0.25)
		Enums.RoomType.BOSS: badge_color = Color(1.0, 0.35, 0.35)
	_label_room.add_theme_color_override("font_color", badge_color)

func _on_next_room_pressed() -> void:
	_advance_to_next_room()

func _advance_to_next_room() -> void:
	$DungeonController.advance_room()
	_update_room_label()
	_update_room_art()
	_update_boss_sprite_visibility()
	if $DungeonController.is_combat_room():
		var group: Array[Resource] = $DungeonController.pick_combat_enemy_group()
		if not group.is_empty():
			var lead: Resource = group[0]
			$CombatController.start_combat_group(group, $DungeonController.get_enemy_level())
			_try_exploration_trap()
			_skill_executor.reset()
			_round_active = false
			_ct_status_accum = 0.0
			_passive_cd.clear()
			_relic_cd.clear()
			_relic_attack_hits.clear()
			_clear_party_links()
			_set_paused(false)
			var enemy_ids: Array = []
			for e in group:
				enemy_ids.append(e.id)
			_show_enemy_swarm(enemy_ids)
			_show_chr_sprites()
			if $DungeonController.current_room_type == Enums.RoomType.ELITE:
				_append_log("【エリート】%s があらわれた" % lead.display_name)
			elif $DungeonController.current_room_type == Enums.RoomType.BOSS:
				_append_log("【ボス】%s があらわれた" % lead.display_name)
			elif group.size() > 1:
				if _enemy_group_is_mixed(group):
					var names: PackedStringArray = []
					for e: Resource in group:
						names.append(e.display_name)
					_append_log("【混成】%s" % " / ".join(names))
				else:
					_append_log("%s の群れ（%d体）があらわれた" % [lead.display_name, group.size()])
			else:
				_append_log("%s があらわれた" % lead.display_name)
			_update_turn_order_ui($CombatController.get_ct_order())
			_fire_combat_start_passives()
			if _try_combat_skip():
				return
			$CombatTimer.start()
		else:
			_set_narrative("敵が現れなかった")
			_hide_enemy_sprite()
			_hide_chr_sprites()
	else:
		_hide_enemy_sprite()
		_hide_chr_sprites()
		match $DungeonController.current_room_type:
			Enums.RoomType.EXIT:
				_set_narrative("脱出口に到着した — 探索終了")
				_auto_progress_finishes = true
				_start_auto_progress()
			Enums.RoomType.HEAL:
				var heal_amount: int = _apply_healing_bonus(HEAL_AMOUNT)
				$CombatController.heal_party(heal_amount)
				_play_heal_vfx()
				_set_narrative("回復の部屋: 生存メンバーを%d回復" % heal_amount)
				_start_auto_progress()
			Enums.RoomType.TREASURE:
				var treasure: Dictionary = $DungeonController.generate_treasure_loot()
				var explore_treasure: PackedStringArray = _apply_exploration_treasure_skills(treasure)
				var log_text: String = "宝箱を発見: Gold +%d" % treasure["gold"]
				if not (treasure["accessory_id"] as String).is_empty():
					log_text += "\n宝箱から装飾品を入手: " + DataRegistry.get_accessory_name(treasure["accessory_id"])
					GameState.last_run_accessory_dropped = treasure["accessory_id"]
				for line: String in explore_treasure:
					log_text += "\n" + line
				_set_narrative(log_text)
				_start_auto_progress()
			Enums.RoomType.EVENT:
				_handle_event_room()
			Enums.RoomType.TRAP:
				_resolve_trap_room()
			_:
				_set_narrative(_get_room_type_name() + "の部屋に入った")
				_start_auto_progress()
	_update_enemy_label()
	_update_status_labels()
	_update_hp_bars()
	_update_next_room_button()
	_register_discoveries_for_room()

func _on_weapon_obtained(weapon_id: String) -> void:
	_try_register_discovery("weapon", weapon_id)

func _try_register_discovery(category: String, entry_id: String) -> void:
	if DiscoveryRegistry.register(category, entry_id):
		_append_discovery_log(category, entry_id)

func _append_discovery_log(category: String, entry_id: String) -> void:
	_show_discovery_toast(category, entry_id)
	if $CombatController.is_in_combat:
		var cat_label: String = DiscoveryRegistry.get_category_label(category)
		var name_label: String = DiscoveryRegistry.get_display_label(category, entry_id)
		_append_log("図鑑登録: [%s] %s" % [cat_label, name_label])

func _show_discovery_toast(category: String, entry_id: String) -> void:
	var cat_label: String = DiscoveryRegistry.get_category_label(category)
	var name_label: String = DiscoveryRegistry.get_display_label(category, entry_id)
	_label_discovery_text.text = "図鑑に登録: [%s] %s" % [cat_label, name_label]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.08, 0.92)
	style.border_color = Color(0.85, 0.7, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_discovery_toast.add_theme_stylebox_override("panel", style)
	_discovery_toast.visible = true
	_discovery_toast.modulate.a = 0.0
	if _discovery_toast_tween != null and _discovery_toast_tween.is_valid():
		_discovery_toast_tween.kill()
	_discovery_toast_tween = create_tween()
	_discovery_toast_tween.tween_property(_discovery_toast, "modulate:a", 1.0, 0.25)
	_discovery_toast_tween.tween_interval(2.5)
	_discovery_toast_tween.tween_property(_discovery_toast, "modulate:a", 0.0, 0.35)
	_discovery_toast_tween.tween_callback(func() -> void:
		_discovery_toast.visible = false
	)

func _format_material_reward_log(material_id: String, amount: int, fallback_label: String) -> String:
	var display_name: String = fallback_label
	var mat_data: Resource = DataRegistry.get_material_data(material_id)
	if mat_data != null and not mat_data.display_name.is_empty():
		display_name = mat_data.display_name
	elif display_name.is_empty():
		display_name = material_id
	return "%s x%d" % [display_name, amount]

func _register_discoveries_for_room() -> void:
	var room_type: int = $DungeonController.current_room_type
	if DiscoveryRegistry.is_special_room(room_type):
		_try_register_discovery("room", DiscoveryRegistry.room_type_to_id(room_type))
	if $CombatController.is_in_combat and $CombatController.current_enemy_data != null:
		_try_register_discovery("enemy", $CombatController.current_enemy_data.id)

# ---- Event ----

func _handle_event_room() -> void:
	var event: Dictionary = $DungeonController.pick_event()
	if event.is_empty():
		_set_narrative("イベントの部屋に入った")
		_start_auto_progress()
		return
	var event_id: String = event.get("id", "")
	if not event_id.is_empty():
		_try_register_discovery("event", event_id)
	var outcome: Dictionary = $DungeonController.auto_resolve_event()
	var log_text: String
	match outcome.get("type", "nothing"):
		"heal":
			var amount: int = _apply_healing_bonus(outcome.get("amount", 5))
			$CombatController.heal_party(amount)
			_play_heal_vfx()
			log_text = "パーティが%dHP回復した" % amount
			_update_hp_bars()
		"gold":
			var amount: int = outcome.get("amount", 0)
			$DungeonController.accumulate_rewards(0, amount)
			log_text = "Gold +%d を得た" % amount
		"buff":
			var mult: float = outcome.get("multiplier", 1.0)
			$DungeonController.run_damage_multiplier = mult
			log_text = "攻撃力が一時的に強化された（x%.2f）" % mult
		"material":
			var mat_id: String = outcome.get("material_id", outcome.get("discovery_id", "relic_shard"))
			var amount: int = _apply_material_bonus(int(outcome.get("amount", 1)))
			GameState.add_material(mat_id, amount)
			log_text = _format_material_reward_log(mat_id, amount, outcome.get("label", ""))
			_try_register_discovery("material", mat_id)
		"lore":
			var lore_id: String = outcome.get("discovery_id", "unknown_lore")
			var body: String = CatalogHelper.get_lore_body(lore_id)
			_try_register_discovery("lore", lore_id)
			if not body.is_empty():
				log_text = "【碑文】%s\n%s" % [outcome.get("label", "碑文"), body]
			else:
				log_text = "%s を記録した。" % outcome.get("label", "碑文")
		"event_helper":
			var job_ids: Array = ["swordsman", "ranger", "alchemist"]
			var job_names: Dictionary = {
				"swordsman": "ソードマン",
				"ranger": "レンジャー",
				"alchemist": "アルケミスト",
			}
			var job_id: String = job_ids[randi() % job_ids.size()]
			var adv_class: Script = load("res://scripts/domain/Adventurer.gd")
			var stats_class: Script = load("res://scripts/domain/Stats.gd")
			var helper: Resource = adv_class.new()
			helper.id = "event_helper"
			helper.job_id = job_id
			helper.display_name = str(job_names.get(job_id, job_id))
			helper.base_stats = stats_class.new()
			helper.level = 1
			GameState.set_event_helper(helper)
			log_text = "%s が一時的に同行を申し出た" % helper.display_name
		_:
			log_text = "何も起こらなかった"
	var explore_lines: PackedStringArray = _apply_exploration_event_skills(outcome)
	for line: String in explore_lines:
		log_text += "\n" + line
	_set_narrative("%s\n%s" % [event["description"], log_text])
	_start_auto_progress()

# ---- 高速周回（P3-D118） ----

func _ensure_fast_run_button() -> void:
	var header: HBoxContainer = $MainVBox/HeaderBar
	if header.get_node_or_null("ButtonFastRun") != null:
		_btn_fast_run = header.get_node("ButtonFastRun")
		return
	_btn_fast_run = Button.new()
	_btn_fast_run.name = "ButtonFastRun"
	_btn_fast_run.toggle_mode = true
	var stop_idx: int = header.get_node("ButtonStop").get_index()
	header.add_child(_btn_fast_run)
	header.move_child(_btn_fast_run, stop_idx)
	_btn_fast_run.pressed.connect(_on_fast_run_pressed)
	_refresh_fast_run_button()

func _on_fast_run_pressed() -> void:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	if not CombatFastRun.can_enable(dungeon_id):
		_fast_run_enabled = false
		_refresh_fast_run_button()
		return
	_fast_run_enabled = _btn_fast_run.button_pressed if _btn_fast_run != null else false
	if _fast_run_enabled:
		_on_speed_x2_pressed()
	_refresh_fast_run_button()

func _refresh_fast_run_button() -> void:
	if _btn_fast_run == null:
		return
	var can_use: bool = CombatFastRun.can_enable(GameState.get_active_dungeon_id())
	_btn_fast_run.disabled = not can_use
	_btn_fast_run.button_pressed = _fast_run_enabled and can_use
	_btn_fast_run.text = "周回ON" if _btn_fast_run.button_pressed else "周回"

func _try_combat_skip() -> bool:
	var room_type: int = $DungeonController.current_room_type
	if not CombatFastRun.can_skip_room(room_type, _fast_run_enabled):
		return false
	if not CombatFastRun.can_enable(GameState.get_active_dungeon_id()):
		return false
	_execute_combat_skip()
	return true

func _execute_combat_skip() -> void:
	_append_log(CombatFastRun.skip_log_message($DungeonController.current_room_type))
	$CombatTimer.stop()
	var slots: Array[int] = []
	for i: int in $CombatController.swarm_hp.size():
		if $CombatController.is_enemy_slot_alive(i):
			slots.append(i)
	for slot: int in slots:
		if $CombatController.living_enemy_count() <= 0:
			break
		var hp: int = $CombatController.get_enemy_hp_at(slot)
		if hp > 0:
			$CombatController.apply_damage_to_enemy_slot(slot, hp)
		if $CombatController.get_enemy_hp_at(slot) <= 0:
			if _on_enemy_slot_killed(slot):
				return
	if $CombatController.living_enemy_count() == 0:
		_finalize_combat_cleared()

# ---- 探索スキル（P3-D117） ----

func _apply_exploration_treasure_skills(treasure: Dictionary) -> PackedStringArray:
	var members: Array = GameState.party_members
	var room_type: int = Enums.RoomType.TREASURE
	var lines: PackedStringArray = []
	if ExplorationSkills.has_skill_for_room(members, "mine", room_type):
		var bonus_gold: int = 12
		$DungeonController.accumulate_rewards(0, bonus_gold)
		treasure["gold"] = int(treasure.get("gold", 0)) + bonus_gold
		lines.append("[探索] 採掘: Gold +%d" % bonus_gold)
	if ExplorationSkills.has_skill_for_room(members, "lockpick", room_type):
		if str(treasure.get("accessory_id", "")).is_empty() and randf() < 0.35:
			var acc_id: String = $DungeonController.generate_accessory_loot()
			if not acc_id.is_empty():
				treasure["accessory_id"] = acc_id
				lines.append(
					"[探索] 鍵開け: 装飾品を入手 — %s" % DataRegistry.get_accessory_name(acc_id)
				)
	return lines

func _apply_exploration_event_skills(outcome: Dictionary) -> PackedStringArray:
	var members: Array = GameState.party_members
	var room_type: int = Enums.RoomType.EVENT
	var lines: PackedStringArray = []
	var outcome_type: String = str(outcome.get("type", ""))
	if ExplorationSkills.has_skill_for_room(members, "gather", room_type):
		if outcome_type == "material":
			var mat_id: String = str(outcome.get("material_id", outcome.get("discovery_id", "relic_shard")))
			var bonus_amt: int = _apply_material_bonus(1)
			GameState.add_material(mat_id, bonus_amt)
			lines.append("[探索] 採取: %s" % _format_material_reward_log(mat_id, bonus_amt, ""))
			_try_register_discovery("material", mat_id)
		elif randf() < 0.40:
			var shard_amt: int = _apply_material_bonus(1)
			GameState.add_material("relic_shard", shard_amt)
			lines.append("[探索] 採取: %s" % _format_material_reward_log("relic_shard", shard_amt, ""))
			_try_register_discovery("material", "relic_shard")
	if (
		outcome_type == "lore"
		and ExplorationSkills.has_skill_for_room(members, "decipher", room_type)
	):
		var bonus_gold: int = 20
		$DungeonController.accumulate_rewards(0, bonus_gold)
		lines.append("[探索] 解読: Gold +%d" % bonus_gold)
	return lines

func _try_exploration_trap() -> void:
	var room_type: int = $DungeonController.current_room_type
	if room_type != Enums.RoomType.COMBAT and room_type != Enums.RoomType.ELITE:
		return
	if not ExplorationSkills.should_roll_trap():
		return
	var members: Array = GameState.party_members
	if ExplorationSkills.can_disarm(members):
		_append_log("[探索] 罠解除: パーティは無事だった")
		return
	var dmg: int = ExplorationSkills.trap_damage()
	var living: Array[int] = []
	for i: int in members.size():
		if $CombatController.is_member_alive(i):
			living.append(i)
	if living.is_empty():
		return
	var target: int = living[randi() % living.size()]
	$CombatController.apply_damage_to_member(target, dmg)
	_on_member_damaged(target)
	var m: Resource = GameState.get_combatant(target)
	var nm: String = m.display_name if m != null else "?"
	_append_log("[探索] 罠: %s に %d ダメージ" % [nm, dmg])
	_update_hp_bars()

func _resolve_trap_room() -> void:
	$CombatController.ensure_party_hp_for_combat()
	var narratives: Array = $DungeonController.TRAP_ROOM_NARRATIVES
	var narrative: String = narratives[randi() % narratives.size()] if not narratives.is_empty() else "罠が作動した"
	var members: Array = GameState.party_members
	if ExplorationSkills.can_disarm_trap_room(members):
		_set_narrative(narrative)
		_append_log("[罠] 罠解除: パーティは無事だった")
		_start_auto_progress()
		return
	var dmg: int = ExplorationSkills.trap_damage()
	var living: Array[int] = []
	for i: int in members.size():
		if $CombatController.is_member_alive(i):
			living.append(i)
	if living.is_empty():
		_set_narrative(narrative)
		_start_auto_progress()
		return
	var target: int = living[randi() % living.size()]
	$CombatController.apply_damage_to_member(target, dmg)
	_on_member_damaged(target)
	var m: Resource = GameState.get_combatant(target)
	var nm: String = m.display_name if m != null else "?"
	_set_narrative("%s — %s に %d ダメージ" % [narrative, nm, dmg])
	_append_log("[罠] %s に %d ダメージ" % [nm, dmg])
	_update_hp_bars()
	if $CombatController.is_party_wiped():
		_handle_party_wipe()
		return
	_start_auto_progress()

# ---- Combat timer ----

# P3-D084: CT/ATB 制。CombatTimer の 1 パルス＝CT クロックを次の行動者まで進め、
# その 1 体だけが行動する。速いユニットほど CT が早く溜まり多く動く。スキルCDは進行した
# CT 量で、状態異常は一定 CT（CT_PER_STATUS_TICK）ごとに 1 tick 進める。
# 同期実行（await無し）のため再入は起きないが、安全のため _round_active を残す。
const CT_PER_STATUS_TICK: float = 2.0
var _ct_status_accum: float = 0.0
# パッシブCD（P3-D088）。key="<member_idx>:<passive_id>" → 残りCT。
var _passive_cd: Dictionary = {}
# 遺物発火CD / 攻撃カウント（P3-D114）。
var _relic_cd: Dictionary = {}
var _relic_attack_hits: Dictionary = {}
# パーティ連携連鎖（P3-D115）。
var _taunt_link_source: int = -1
var _taunt_link_charges: int = 0
var _debuff_marks: Dictionary = {}
var _heal_rally_member: int = -1

func _on_combat_timer_timeout() -> void:
	if not $CombatController.is_in_combat:
		$CombatTimer.stop()
		return
	if _round_active:
		return
	_round_active = true
	_run_combat_step()
	_round_active = false

func _run_combat_step() -> void:
	if not $CombatController.is_in_combat:
		return
	var actor: Dictionary = $CombatController.advance_to_next_actor()
	var delta: float = $CombatController.consume_last_ct_step()
	# スキルCD・パッシブCDは進行した CT 量だけ進める
	if delta > 0.0:
		_skill_executor.tick(delta)
		_tick_passive_cd(delta)
	# 状態異常（DoT/バフ等）は一定 CT ごとに 1 tick
	_ct_status_accum += delta
	while _ct_status_accum >= CT_PER_STATUS_TICK:
		_ct_status_accum -= CT_PER_STATUS_TICK
		_process_status_ticks()
		if $CombatController.living_enemy_count() == 0:
			return
		if $CombatController.is_party_wiped():
			_handle_party_wipe()
			return
	if actor.is_empty():
		return
	var kind: String = actor["kind"]
	var idx: int = actor["index"]
	if kind == "party":
		if $CombatController.is_member_alive(idx):
			_do_member_turn(idx)
			if $CombatController.living_enemy_count() == 0:
				return
	else:
		if $CombatController.is_enemy_slot_alive(idx):
			_do_enemy_turn(idx)
			if $CombatController.is_party_wiped():
				_handle_party_wipe()
				return
	_update_hp_bars()
	_update_status_labels()
	# CT 表示を更新し、次に動くユニット（CT 残量最小＝先頭）を強調
	var order: Array[Dictionary] = $CombatController.get_ct_order()
	_update_turn_order_ui(order)
	if not order.is_empty():
		_set_turn_order_active(order[0])

# 敵スロット1体の行動（P3-D083）。アクティブ敵のみ 鈍化判定＋ボス/エリートのスキル発動を行い、
# それ以外は通常攻撃。状態異常/スキルはアクティブ敵のみに作用（P3-D082）。
func _do_enemy_turn(slot: int) -> void:
	if $CombatController.has_pending_cast("enemy", slot):
		_advance_enemy_cast(slot)
		return
	if $CombatController.should_enemy_skip_action_at(slot):
		var skip_label: String = $CombatController.get_enemy_skip_action_label_at(slot)
		if skip_label.is_empty():
			skip_label = "鈍化"
		_append_log("[%s] 敵の行動が遅れた" % skip_label)
		return
	if slot == $CombatController.active_enemy_index:
		if _try_enemy_skill():
			return
	_do_enemy_attack(slot)

func _process_status_ticks() -> void:
	$CombatController.decay_threat()
	for result: Dictionary in $CombatController.tick_all_statuses():
		var unit_id: String = result.get("unit_id", "")
		var dmg: int = result.get("damage", 0)
		var display_name: String = result.get("display_name", "")
		if dmg <= 0:
			continue
		if unit_id.begins_with("enemy_"):
			var slot: int = int(unit_id.substr(6))
			$CombatController.apply_damage_to_enemy_slot(slot, dmg)
			_check_boss_phase_transition(slot)
			if slot < _swarm_sprites.size() and _swarm_sprites[slot].visible:
				_spawn_damage_number(str(dmg), _swarm_sprites[slot].global_position, Color(1.0, 0.6, 0.0))
			if $CombatController.get_enemy_hp_at(slot) <= 0:
				if _on_enemy_slot_killed(slot):
					return
		elif unit_id.begins_with("party_"):
			var idx: int = int(unit_id.substr(7))
			$CombatController.apply_damage_to_member(idx, dmg)
			if idx < _chr_sprites.size():
				_spawn_damage_number(str(dmg), _chr_sprites[idx].global_position, Color(1.0, 0.45, 0.1))
		_append_log("[%s] %dダメージ" % [display_name, dmg])
	_update_hp_bars()

func _try_apply_skill_status() -> void:
	if $CombatController.is_enemy_defeated():
		return
	var member_idx: int = _first_alive_member_index()
	var skill_data: Resource = _get_player_skill_data(member_idx)
	if skill_data == null or skill_data.apply_status_id.is_empty():
		return
	if skill_data.apply_status_chance <= 0.0 or randf() > skill_data.apply_status_chance:
		return
	var base_info: Dictionary = _calc_attack_base(member_idx)
	if not $CombatController.apply_status_to_active_enemy(
		skill_data.apply_status_id,
		1,
		base_info["base_damage"]
	):
		return
	var effect: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
	var label: String = skill_data.apply_status_id
	if effect != null:
		label = effect.display_name
	_append_log("[%s] 付与" % label)

func _try_apply_secondary_skill_status() -> void:
	if $CombatController.is_enemy_defeated():
		return
	var member_idx: int = _first_alive_member_index()
	var skill_data: Resource = _get_job_skill_data(member_idx)
	if skill_data == null or skill_data.apply_status_id.is_empty():
		return
	var primary: Resource = _get_player_skill_data(member_idx)
	if primary != null and skill_data.id == primary.id:
		return
	if skill_data.apply_status_chance <= 0.0 or randf() > skill_data.apply_status_chance:
		return
	var base_info: Dictionary = _calc_attack_base(member_idx)
	if not $CombatController.apply_status_to_active_enemy(
		skill_data.apply_status_id,
		1,
		base_info["base_damage"]
	):
		return
	var effect: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
	var label: String = skill_data.apply_status_id
	if effect != null:
		label = effect.display_name
	_append_log("[%s] 付与" % label)

func _try_apply_affix_statuses(member_index: int) -> void:
	if not _member_has_living_target(member_index):
		return
	var bonuses: Dictionary = AffixStatCalculatorScript.get_bonuses(member_index)
	var rules: Array[Dictionary] = [
		{"chance_key": "shock_chance", "status_id": "shock", "label": "感電"},
		{"chance_key": "ignite_chance", "status_id": "ignite", "label": "炎上"},
		{"chance_key": "chill_chance", "status_id": "chill", "label": "冷却"},
		{"chance_key": "poison_chance", "status_id": "poison", "label": "毒"},
	]
	for rule: Dictionary in rules:
		var chance: float = float(bonuses.get(rule["chance_key"], 0.0))
		if chance <= 0.0 or randf() > chance:
			continue
		if not _apply_status_to_member_target(member_index, rule["status_id"], 1, 0):
			continue
		_append_log("[%s] 付与" % rule["label"])

# 単一スキルの発動（ダメージ＋状態異常付与）。CDはメンバー×スキルで独立管理。
# cast_index: この tick でそのメンバーが発動した順番（0始まり）。ラベル段組みに使用。
func _execute_member_skill(member_idx: int, skill_data: Resource, cast_index: int = 0) -> String:
	if not _member_has_living_target(member_idx):
		return ""
	match skill_data.effect_type:
		"heal":
			return _execute_member_heal(member_idx, skill_data, cast_index)
		"buff":
			return _execute_member_buff(member_idx, skill_data, cast_index)
	var target_slot: int = $CombatController.get_member_target_slot(member_idx)
	var cd_key: String = "%d:%s" % [member_idx, skill_data.id]
	var base_info: Dictionary = _calc_attack_base(member_idx)
	var is_critical: bool = randf() < base_info["crit_rate"]
	var run_mult: float = $DungeonController.run_damage_multiplier
	var result: Dictionary = _skill_executor.execute_damage_skill(
		skill_data,
		base_info["base_damage"],
		is_critical,
		CRITICAL_MULTIPLIER,
		run_mult,
		cd_key
	)
	if not result.get("executed", false):
		return ""
	var attack_element: String = _resolve_skill_element(skill_data, member_idx)
	var action_range: String = CombatRange.resolve_for_action(member_idx, skill_data)
	var form_tag: String = GameState.formation_range_log_tag(member_idx, action_range)
	var skill_dmg: int = maxi(
		1,
		int(float(result["damage"]) * $CombatController.get_member_outgoing_damage_multiplier(member_idx, action_range))
	)
	var elem_result: Dictionary = _apply_enemy_mitigation(skill_dmg, attack_element, member_idx, target_slot)
	var final_dmg: int = maxi(
		1,
		int(float(elem_result["damage"]) * $CombatController.get_enemy_incoming_damage_multiplier_at(target_slot))
	)
	final_dmg += _consume_combo_bonus(
		member_idx, final_dmg, _member_action_tags(member_idx, skill_data), skill_data, target_slot
	)
	var skill_is_crit: bool = result.get("is_critical", false)
	var spawn_pos: Vector2 = _enemy_slot_pos(target_slot)
	_spawn_hit_vfx(spawn_pos, attack_element)
	_spawn_damage_number(str(final_dmg), spawn_pos + Vector2(12.0, 0.0), Color(1.0, 0.9, 0.0), 1.25 if skill_is_crit else 1.0)
	if cast_index == 0:
		_clear_member_skill_labels(member_idx)
	_spawn_skill_name(result["display_name"], member_idx, float(cast_index) * SKILL_LABEL_STACK_GAP, attack_element)
	var crit_tag: String = "  CRITICAL!" if skill_is_crit else ""
	var tgt_tag: String = _member_target_tag(member_idx)
	var log_line: String = "\n【スキル】%s: %dダメージ%s%s%s%s" % [
		result["display_name"], final_dmg, crit_tag, elem_result["element_tag"], form_tag, tgt_tag,
	]
	if _deal_member_damage_to_enemy(member_idx, final_dmg, target_slot):
		return log_line
	_apply_skill_status(member_idx, skill_data)
	_apply_skill_secondary_status(member_idx, skill_data)
	return log_line

# スキルの状態異常付与（apply_status_id / apply_status_chance）。
func _apply_skill_status(member_idx: int, skill_data: Resource) -> void:
	if not _member_has_living_target(member_idx):
		return
	if skill_data == null or skill_data.apply_status_id.is_empty():
		return
	if skill_data.apply_status_chance <= 0.0 or randf() > skill_data.apply_status_chance:
		return
	var base_info: Dictionary = _calc_attack_base(member_idx)
	if not _apply_status_to_member_target(member_idx, skill_data.apply_status_id, 1, base_info["base_damage"]):
		return
	var effect: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
	var label: String = skill_data.apply_status_id
	if effect != null:
		label = effect.display_name
	_append_log("[%s] 付与" % label)

# スキルの副次状態付与（apply_status_id2 / apply_status_chance2・P3-D107）。
# 主状態のロール成否とは独立に判定する。
func _apply_skill_secondary_status(member_idx: int, skill_data: Resource) -> void:
	if not _member_has_living_target(member_idx):
		return
	if skill_data == null or skill_data.apply_status_id2.is_empty():
		return
	if skill_data.apply_status_chance2 <= 0.0 or randf() > skill_data.apply_status_chance2:
		return
	var base_info: Dictionary = _calc_attack_base(member_idx)
	if not _apply_status_to_member_target(member_idx, skill_data.apply_status_id2, 1, base_info["base_damage"]):
		return
	var effect2: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id2)
	var label2: String = skill_data.apply_status_id2
	if effect2 != null:
		label2 = effect2.display_name
	_append_log("[%s] 付与" % label2)

# 回復スキル: 最も負傷した生存メンバーを回復する。負傷者が居なければCDを消費せず発動しない。
func _execute_member_heal(member_idx: int, skill_data: Resource, cast_index: int = 0) -> String:
	var target_idx: int = $CombatController.get_most_injured_member_index()
	if target_idx < 0:
		return ""
	var cd_key: String = "%d:%s" % [member_idx, skill_data.id]
	var result: Dictionary = _skill_executor.execute_support_skill(skill_data, cd_key)
	if not result.get("executed", false):
		return ""
	var heal_amount: int = _apply_healing_bonus(int(round(skill_data.power_multiplier * float(HEAL_SKILL_BASE))))
	var healed: int = $CombatController.heal_member(target_idx, heal_amount)
	_set_heal_rally(target_idx)
	_update_hp_bars()
	if cast_index == 0:
		_clear_member_skill_labels(member_idx)
	_spawn_skill_name(result["display_name"], member_idx, float(cast_index) * SKILL_LABEL_STACK_GAP)
	if target_idx >= 0 and target_idx < _chr_sprites.size() and _chr_sprites[target_idx].visible:
		var heal_pos: Vector2 = _chr_sprites[target_idx].global_position + Vector2(0.0, -CHR_BODY_TARGET_PX * 0.5)
		_spawn_damage_number("+%d" % healed, heal_pos, Color(0.45, 1.0, 0.5), 1.1)
	var target_name: String = ""
	var target_member: Resource = GameState.get_combatant(target_idx)
	if target_member != null:
		target_name = target_member.display_name
	return "\n【スキル】%s: %s を %d回復" % [result["display_name"], target_name, healed]

# バフスキル: 生存中のメイン編成全員に apply_status_id（鼓舞=与ダメ上昇）を付与する。
func _execute_member_buff(member_idx: int, skill_data: Resource, cast_index: int = 0) -> String:
	if skill_data.apply_status_id.is_empty():
		return ""
	var cd_key: String = "%d:%s" % [member_idx, skill_data.id]
	var result: Dictionary = _skill_executor.execute_support_skill(skill_data, cd_key)
	if not result.get("executed", false):
		return ""
	var applied: int = 0
	for i: int in GameState.party_members.size():
		if not $CombatController.is_member_alive(i):
			continue
		if $CombatController.apply_status("party_%d" % i, skill_data.apply_status_id, 1, 0):
			applied += 1
	_update_status_icons()
	if cast_index == 0:
		_clear_member_skill_labels(member_idx)
	_spawn_skill_name(result["display_name"], member_idx, float(cast_index) * SKILL_LABEL_STACK_GAP)
	var effect: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
	var label: String = skill_data.apply_status_id
	if effect != null:
		label = effect.display_name
	return "\n【スキル】%s: 味方%d体に[%s]" % [result["display_name"], applied, label]

func _get_player_skill_data(member_index: int = -1) -> Resource:
	var skill_id: String = Constants.DEFAULT_PLAYER_SKILL_ID
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon != null and not weapon.weapon_id.is_empty():
		var weapon_data: Resource = DataRegistry.get_weapon_data(weapon.weapon_id)
		if weapon_data != null and not weapon_data.fixed_skill_id.is_empty():
			skill_id = weapon_data.fixed_skill_id
	var skill_data: Resource = DataRegistry.get_skill_data(skill_id)
	if skill_data != null:
		return skill_data
	return DataRegistry.get_skill_data(Constants.DEFAULT_PLAYER_SKILL_ID)

func _get_equipped_weapon_display_name(member_index: int = -1) -> String:
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon == null or weapon.weapon_id.is_empty():
		return ""
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon.weapon_id)
	if weapon_data == null or weapon_data.display_name.is_empty():
		return weapon.weapon_id
	return weapon_data.display_name

func _try_cast_player_skill() -> String:
	if $CombatController.is_enemy_defeated():
		return ""
	var member_idx: int = _first_alive_member_index()
	var skill_data: Resource = _get_player_skill_data(member_idx)
	if skill_data == null:
		return ""
	var base_info: Dictionary = _calc_attack_base(member_idx)
	var is_critical: bool = randf() < base_info["crit_rate"]
	var run_mult: float = $DungeonController.run_damage_multiplier
	var result: Dictionary = _skill_executor.execute_damage_skill(
		skill_data,
		base_info["base_damage"],
		is_critical,
		CRITICAL_MULTIPLIER,
		run_mult
	)
	if not result.get("executed", false):
		return ""
	var attack_element: String = _resolve_skill_element(skill_data, member_idx)
	var action_range: String = CombatRange.resolve_for_action(member_idx, skill_data)
	var form_tag: String = GameState.formation_range_log_tag(member_idx, action_range)
	var skill_dmg: int = maxi(
		1,
		int(float(result["damage"]) * $CombatController.get_member_outgoing_damage_multiplier(member_idx, action_range))
	)
	var elem_result: Dictionary = _apply_enemy_mitigation(skill_dmg, attack_element)
	var final_dmg: int = maxi(
		1,
		int(
			float(elem_result["damage"])
			* $CombatController.get_enemy_incoming_damage_multiplier()
		)
	)
	final_dmg += _consume_combo_bonus(member_idx, final_dmg, _member_action_tags(member_idx, skill_data), skill_data)
	$CombatController.apply_damage_to_enemy(final_dmg)
	$CombatController.add_threat(member_idx, float(final_dmg) * CombatController.THREAT_DAMAGE_K)
	var skill_is_crit: bool = result.get("is_critical", false)
	var skill_spawn_pos: Vector2 = _active_enemy_pos()
	_spawn_hit_vfx(skill_spawn_pos, attack_element)
	_spawn_damage_number(str(final_dmg), skill_spawn_pos + Vector2(12.0, 0.0), Color(1.0, 0.9, 0.0), 1.25 if skill_is_crit else 1.0)
	_spawn_skill_name(result["display_name"], member_idx, 0.0, attack_element)
	var skill_crit_tag: String = "  CRITICAL!" if skill_is_crit else ""
	var weapon_name: String = _get_equipped_weapon_display_name(member_idx)
	var skill_header: String = result["display_name"]
	if not weapon_name.is_empty():
		skill_header = "%s / %s" % [weapon_name, result["display_name"]]
	return "\n【スキル】%s: %dダメージ%s%s%s" % [
		skill_header,
		final_dmg,
		skill_crit_tag,
		elem_result["element_tag"],
		form_tag,
	]

func _get_job_skill_data(member_index: int) -> Resource:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return null
	var member: Resource = GameState.party_members[member_index]
	if member == null or member.job_id.is_empty():
		return null
	var job_data: Resource = DataRegistry.get_job_data(member.job_id)
	if job_data == null or job_data.starting_skill_ids.is_empty():
		return null
	return DataRegistry.get_skill_data(job_data.starting_skill_ids[0])

func _try_cast_secondary_skill(primary_skill_id: String) -> String:
	if $CombatController.is_enemy_defeated():
		return ""
	var member_idx: int = _first_alive_member_index()
	var skill_data: Resource = _get_job_skill_data(member_idx)
	if skill_data == null:
		return ""
	if skill_data.id == primary_skill_id:
		return ""
	var base_info: Dictionary = _calc_attack_base(member_idx)
	var is_critical: bool = randf() < base_info["crit_rate"]
	var run_mult: float = $DungeonController.run_damage_multiplier
	var result: Dictionary = _skill_executor.execute_damage_skill(
		skill_data,
		base_info["base_damage"],
		is_critical,
		CRITICAL_MULTIPLIER,
		run_mult
	)
	if not result.get("executed", false):
		return ""
	var attack_element: String = _resolve_skill_element(skill_data, member_idx)
	var action_range: String = CombatRange.resolve_for_action(member_idx, skill_data)
	var form_tag: String = GameState.formation_range_log_tag(member_idx, action_range)
	var skill_dmg: int = maxi(
		1,
		int(float(result["damage"]) * $CombatController.get_member_outgoing_damage_multiplier(member_idx, action_range))
	)
	var elem_result: Dictionary = _apply_enemy_mitigation(skill_dmg, attack_element)
	var final_dmg: int = maxi(
		1,
		int(
			float(elem_result["damage"])
			* $CombatController.get_enemy_incoming_damage_multiplier()
		)
	)
	final_dmg += _consume_combo_bonus(member_idx, final_dmg, _member_action_tags(member_idx, skill_data), skill_data)
	$CombatController.apply_damage_to_enemy(final_dmg)
	$CombatController.add_threat(member_idx, float(final_dmg) * CombatController.THREAT_DAMAGE_K)
	var sec_is_crit: bool = result.get("is_critical", false)
	var sec_spawn_pos: Vector2 = _active_enemy_pos()
	_spawn_hit_vfx(sec_spawn_pos, attack_element)
	_spawn_damage_number(str(final_dmg), sec_spawn_pos + Vector2(-12.0, 8.0), Color(1.0, 0.9, 0.0), 1.25 if sec_is_crit else 1.0)
	_spawn_skill_name(result["display_name"], member_idx, 34.0, attack_element)
	var skill_crit_tag: String = "  CRITICAL!" if sec_is_crit else ""
	return "\n【ジョブスキル】%s: %dダメージ%s%s%s" % [
		result["display_name"],
		final_dmg,
		skill_crit_tag,
		elem_result["element_tag"],
		form_tag,
	]

func _get_weapon_element(member_index: int = -1) -> String:
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon != null and not weapon.weapon_id.is_empty():
		var weapon_data: Resource = DataRegistry.get_weapon_data(weapon.weapon_id)
		if weapon_data != null and not weapon_data.element.is_empty():
			return weapon_data.element
	return ""

func _resolve_skill_element(skill_data: Resource, member_index: int = -1) -> String:
	if skill_data != null and not skill_data.element.is_empty():
		return skill_data.element
	return _get_weapon_element(member_index)

# 敵の属性(弱点×1.25 / 耐性×0.75)と防御(逓減軽減)を与ダメージへ反映する
# Biome 属性相性（P3-D099）。現在ダンジョンの favored_element と攻撃属性が一致するか。
func _is_biome_favored(attack_element: String) -> bool:
	if attack_element.is_empty():
		return false
	var dungeon: Resource = $DungeonController.current_dungeon_data
	if dungeon == null:
		return false
	return str(dungeon.favored_element) == attack_element

func _apply_enemy_mitigation(
	damage: int,
	attack_element: String,
	member_index: int = -1,
	target_slot: int = -1
) -> Dictionary:
	var element_tag: String = ""
	if target_slot < 0:
		target_slot = $CombatController.get_member_target_slot(member_index) if member_index >= 0 else $CombatController.active_enemy_index
	var enemy_data: Resource = $CombatController.get_enemy_data_at(target_slot)
	if enemy_data == null or damage <= 0:
		return {"damage": damage, "element_tag": element_tag}
	var elem_mult: float = ElementResolverScript.get_damage_multiplier(
		attack_element,
		enemy_data.element_weakness,
		enemy_data.element_resist
	)
	var elem_name: String = ElementResolverScript.get_display_name(attack_element)
	if elem_mult > 1.0:
		damage = maxi(1, int(float(damage) * elem_mult))
		if not elem_name.is_empty():
			element_tag = "  [弱点:%s]" % elem_name
	elif elem_mult < 1.0:
		damage = maxi(1, int(float(damage) * elem_mult))
		if not elem_name.is_empty():
			element_tag = "  [耐性:%s]" % elem_name
	# 生態特効（P3-D087）: 武器 bane_class が敵 codex_class と一致で増幅。属性と乗算。
	if member_index >= 0:
		var bane: Dictionary = _get_weapon_bane(member_index)
		var bane_class: String = str(bane.get("class", ""))
		if not bane_class.is_empty() and bane_class == str(enemy_data.codex_class):
			damage = maxi(1, int(round(float(damage) * float(bane.get("mult", 1.0)))))
			element_tag += "  [特効:%s]" % bane_class
	# 同系統タグ・シナジー（P3-D095）: 属性をパーティで複数人共有なら、その属性の与ダメ増幅。
	var synergy: float = $CombatController.get_element_synergy_bonus(attack_element)
	if synergy > 0.0:
		damage = maxi(1, int(round(float(damage) * (1.0 + synergy))))
		element_tag += "  [シナジー:%s]" % ElementResolverScript.get_display_name(attack_element)
	# Biome 属性相性（P3-D099）: ダンジョンの有利属性と一致なら与ダメ増幅。
	if _is_biome_favored(attack_element):
		damage = maxi(1, int(round(float(damage) * BIOME_FAVORED_BONUS)))
		element_tag += "  [地形:%s]" % ElementResolverScript.get_display_name(attack_element)
	# 天候（環境変化・P3-D101）: 属性別補正＋全体与ダメ補正。
	var weather: String = GameState.get_weather()
	var weather_mult: float = CombatWeather.element_multiplier(weather, attack_element) * CombatWeather.outgoing_multiplier(weather)
	if weather_mult != 1.0:
		damage = maxi(1, int(round(float(damage) * weather_mult)))
		element_tag += "  [天候:%s]" % CombatWeather.label(weather)
	# 防御DOWN（armor_break・P3-D107）: 敵 DEF を減少率ぶん下げてから逓減軽減。
	var def_reduction: float = $CombatController.get_enemy_defense_reduction_at(target_slot)
	if def_reduction > 0.0:
		element_tag += "  [防御DOWN]"
	damage = _apply_enemy_defense(damage, enemy_data, def_reduction)
	return {"damage": damage, "element_tag": element_tag}

# 状態異常コンボ起爆（P3-D089）。味方の攻撃ヒット時、アクティブ敵に前提状態が
# 乗っていれば 1 つだけ起爆し、追加ダメージを返してその状態を消費する。
# 戻り値は攻撃ダメージへ上乗せする（既存の撃破判定をそのまま通すため）。
func _consume_enemy_combo_bonus(
	member_idx: int,
	hit_damage: int,
	attacker_tags: Array = [],
	target_slot: int = -1
) -> int:
	if target_slot < 0:
		target_slot = $CombatController.get_member_target_slot(member_idx)
	if not $CombatController.is_enemy_slot_alive(target_slot):
		return 0
	for trigger_id: String in CombatCombos.trigger_ids():
		var stacks: int = $CombatController.get_enemy_status_stacks_at(target_slot, trigger_id)
		if stacks <= 0:
			continue
		if not CombatCombos.tag_eligible(trigger_id, attacker_tags):
			continue
		var bonus: int = CombatCombos.bonus_for(trigger_id, stacks, hit_damage)
		if bonus <= 0:
			continue
		$CombatController.consume_enemy_status_at(target_slot, trigger_id)
		var label: String = str(CombatCombos.rule(trigger_id).get("label", "コンボ"))
		var pos: Vector2 = _enemy_slot_pos(target_slot)
		_spawn_damage_number("%s +%d" % [label, bonus], pos + Vector2(0.0, -34.0), Color(1.0, 0.55, 0.15), 1.15)
		_append_log("[コンボ] %s +%d" % [label, bonus])
		return bonus
	return 0

# 1ヒット1コンボ（敵側優先→味方バフ側・P3-D109）＋パーティ連携（P3-D115・コンボと併用可）。
func _consume_combo_bonus(
	member_idx: int,
	hit_damage: int,
	attacker_tags: Array = [],
	skill_data: Resource = null,
	target_slot: int = -1
) -> int:
	var total: int = 0
	var enemy_bonus: int = _consume_enemy_combo_bonus(member_idx, hit_damage, attacker_tags, target_slot)
	if enemy_bonus > 0:
		total += enemy_bonus
	else:
		total += _consume_ally_combo_bonus(member_idx, hit_damage, attacker_tags, skill_data)
	total += _consume_link_bonus(member_idx, hit_damage, target_slot)
	return total

# 味方バフコンボ（鼓舞→必殺等）。攻撃者自身のバフ状態を消費する。
func _consume_ally_combo_bonus(
	member_idx: int,
	hit_damage: int,
	attacker_tags: Array = [],
	skill_data: Resource = null
) -> int:
	if skill_data == null or str(skill_data.slot_type) != "ultimate":
		return 0
	for trigger_id: String in CombatCombos.ally_trigger_ids():
		var stacks: int = $CombatController.get_member_status_stacks(member_idx, trigger_id)
		if stacks <= 0:
			continue
		if not CombatCombos.ally_tag_eligible(trigger_id, attacker_tags):
			continue
		var bonus: int = CombatCombos.ally_bonus_for(trigger_id, stacks, hit_damage)
		if bonus <= 0:
			continue
		$CombatController.consume_member_status(member_idx, trigger_id)
		_update_status_icons()
		var label: String = str(CombatCombos.ally_rule(trigger_id).get("label", "コンボ"))
		var slot: int = $CombatController.get_member_target_slot(member_idx)
		var pos: Vector2 = _enemy_slot_pos(slot)
		_spawn_damage_number("%s +%d" % [label, bonus], pos + Vector2(0.0, -48.0), Color(1.0, 0.75, 0.35), 1.2)
		_append_log("[コンボ] %s +%d" % [label, bonus])
		return bonus
	return 0

# メンバーの現在アクションのシナジータグ（P3-D094）。武器タグ∪スキルタグ。未知idは除外。
func _member_action_tags(member_idx: int, skill_data: Resource = null) -> Array:
	var tags: Array = []
	var winst: Resource = GameState.get_member_equipped_weapon(member_idx)
	if winst != null and not str(winst.weapon_id).is_empty():
		var wd: Resource = DataRegistry.get_weapon_data(winst.weapon_id)
		if wd != null and "tags" in wd:
			for t in wd.tags:
				if CombatTags.is_known(str(t)) and str(t) not in tags:
					tags.append(str(t))
	if skill_data != null and "tags" in skill_data:
		for t in skill_data.tags:
			if CombatTags.is_known(str(t)) and str(t) not in tags:
				tags.append(str(t))
	return tags

# 装備武器の生態特効（{class, mult}）。特効なしは class="" / mult=1.0。
func _get_weapon_bane(member_index: int) -> Dictionary:
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon != null and not weapon.weapon_id.is_empty():
		var wd: Resource = DataRegistry.get_weapon_data(weapon.weapon_id)
		if wd != null and "bane_class" in wd and not str(wd.bane_class).is_empty():
			return {"class": str(wd.bane_class), "mult": float(wd.bane_multiplier)}
	return {"class": "", "mult": 1.0}

# 敵DEFによる逓減軽減: damage × K/(K+DEF)。最低1。
# def_reduction（armor_break・P3-D107）で実効 DEF を下げてから計算する。
func _apply_enemy_defense(damage: int, enemy_data: Resource, def_reduction: float = 0.0) -> int:
	if enemy_data == null or damage <= 0:
		return damage
	var def: float = float(enemy_data.defense)
	if def_reduction > 0.0:
		def *= (1.0 - clampf(def_reduction, 0.0, 0.95))
	if def <= 0.0:
		return damage
	var mult: float = DEFENSE_MITIGATION_K / (DEFENSE_MITIGATION_K + def)
	return maxi(1, int(round(float(damage) * mult)))

func _calc_attack_base(member_index: int = -1) -> Dictionary:
	var damage: int = FALLBACK_ATTACK
	var crit_rate: float = 0.0
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon != null:
		damage = weapon.rolled_attack
		crit_rate = weapon.critical_rate
	var acc: Resource = GameState.get_member_equipped_accessory(member_index)
	if acc != null:
		var acc_data: Resource = load("res://resources/accessories/" + acc.accessory_id + ".tres")
		if acc_data != null:
			damage += acc_data.attack_bonus
			crit_rate += acc_data.crit_rate_bonus
	var affix_bonuses: Dictionary = AffixStatCalculatorScript.get_bonuses(member_index)
	damage += int(affix_bonuses.get("attack_flat", 0))
	crit_rate += float(affix_bonuses.get("crit_rate_add", 0.0))
	# ロール編成ボーナス（scout×2=会心+8%・P3-D097）
	crit_rate += $CombatController.get_party_role_crit_add()
	if member_index >= 0 and member_index < GameState.party_members.size():
		damage += LevelSystem.level_attack_bonus(GameState.party_members[member_index].level)
	damage = _apply_job_attack_multiplier(damage, member_index)
	return {"base_damage": damage, "crit_rate": crit_rate}

func _apply_job_attack_multiplier(base_damage: int, member_index: int) -> int:
	if base_damage <= 0 or member_index < 0 or member_index >= GameState.party_members.size():
		return base_damage
	var member: Resource = GameState.party_members[member_index]
	var job_mods: Dictionary = JobStatCalculatorScript.get_member_modifiers(member)
	var atk_mult: float = float(job_mods.get("attack_multiplier", JobStatCalculator.DEFAULT_MULTIPLIER))
	var weapon_inst: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon_inst != null and not weapon_inst.weapon_id.is_empty():
		var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_inst.weapon_id)
		atk_mult *= JobStatCalculatorScript.get_preferred_weapon_multiplier(member, weapon_data)
	return maxi(0, int(round(float(base_damage) * atk_mult)))

func _first_alive_member_index() -> int:
	for i in GameState.party_members.size():
		if $CombatController.is_member_alive(i):
			return i
	return -1

# 戦闘中のアクティブ敵スプライト（群れ時は先頭生存スロット、ボス部屋は BossSprite）を返す
func _active_enemy_sprite() -> AnimatedSprite2D:
	if _boss_sprite.visible:
		return _boss_sprite
	var ai: int = $CombatController.active_enemy_index
	if ai >= 0 and ai < _swarm_sprites.size():
		return _swarm_sprites[ai]
	return _enemy_sprite

# VFX/ドロップの発生位置に使うアクティブ敵のグローバル座標。
func _active_enemy_pos() -> Vector2:
	return _enemy_slot_pos($CombatController.active_enemy_index)

func _enemy_slot_pos(slot: int) -> Vector2:
	if slot >= 0 and slot < _swarm_sprites.size() and _swarm_sprites[slot].visible:
		return _swarm_sprites[slot].global_position
	return _active_enemy_sprite().global_position

func _member_target_tag(member_idx: int) -> String:
	if $CombatController.living_enemy_count() <= 1:
		return ""
	var slot: int = $CombatController.get_member_target_slot(member_idx)
	var data: Resource = $CombatController.get_enemy_data_at(slot)
	if data == null:
		return ""
	return " → %s" % data.display_name

func _member_has_living_target(member_idx: int) -> bool:
	return $CombatController.is_enemy_slot_alive($CombatController.get_member_target_slot(member_idx))

# 味方攻撃ダメージをメンバー個別ターゲットへ適用。撃破時は true（全滅で戦闘終了）。
func _deal_member_damage_to_enemy(member_idx: int, damage: int, target_slot: int = -1) -> bool:
	if target_slot < 0:
		target_slot = $CombatController.get_member_target_slot(member_idx)
	if not $CombatController.is_enemy_slot_alive(target_slot):
		return false
	$CombatController.apply_damage_to_enemy_slot(target_slot, damage)
	$CombatController.add_threat(member_idx, float(damage) * CombatController.THREAT_DAMAGE_K)
	_check_boss_phase_transition(target_slot)
	if damage > 0:
		_fire_member_relic_triggers(
			member_idx, "on_attack", {"damage": damage, "target_slot": target_slot}
		)
	if $CombatController.get_enemy_hp_at(target_slot) <= 0:
		return _on_enemy_slot_killed(target_slot)
	return false

func _apply_status_to_member_target(
	member_idx: int,
	effect_id: String,
	stacks: int = 1,
	source_attack: int = 0
) -> bool:
	var slot: int = $CombatController.get_member_target_slot(member_idx)
	var applied: bool = $CombatController.apply_status_to_enemy_slot(slot, effect_id, stacks, source_attack)
	if applied and CombatLinks.is_debuff_mark_status(effect_id):
		_debuff_marks[slot] = member_idx
	return applied

# ボス/エリートのスキル発動を試行。発動したら true（通常攻撃をスキップ）。
func _try_enemy_skill() -> bool:
	var enemy_data: Resource = $CombatController.current_enemy_data
	if enemy_data == null or enemy_data.skill_ids.is_empty():
		return false
	var slot: int = $CombatController.active_enemy_index
	var enemy_id: String = $CombatController.get_enemy_id_at(slot)
	var phase_idx: int = $CombatController.get_enemy_phase_index(slot)
	var use_chance: float = CombatBossPhases.skill_use_chance(
		enemy_id, phase_idx, float(enemy_data.skill_use_chance)
	)
	if use_chance <= 0.0 or randf() > use_chance:
		return false
	var phase_def: Dictionary = CombatBossPhases.phase_def(enemy_id, phase_idx)
	var skill: Resource = _pick_enemy_skill(enemy_data, phase_def)
	if skill == null:
		return false
	return _try_cast_enemy_skill(slot, skill)

func _pick_enemy_skill(enemy_data: Resource, phase_def: Dictionary) -> Resource:
	var weights: Dictionary = phase_def.get("skill_weight", {})
	var pool: Array = []
	var total: float = 0.0
	for sid in enemy_data.skill_ids:
		var sd: Resource = DataRegistry.get_skill_data(str(sid))
		if sd == null:
			continue
		if not _skill_executor.can_cast(sd, "enemy:%s" % sd.id):
			continue
		var w: float = float(weights.get(str(sid), 1.0))
		pool.append({"skill": sd, "weight": w})
		total += w
	if pool.is_empty():
		return null
	var roll: float = randf() * total
	var acc: float = 0.0
	for item: Dictionary in pool:
		acc += float(item["weight"])
		if roll <= acc:
			return item["skill"]
	return pool[pool.size() - 1]["skill"]

# 敵スキルの詠唱開始または即時発動（P3-D112）。
func _try_cast_enemy_skill(slot: int, skill: Resource) -> bool:
	if skill == null:
		return false
	var cast_time: float = float(skill.cast_time)
	if cast_time <= 0.0:
		return _execute_enemy_skill(skill)
	var cd_key: String = "enemy:%s" % skill.id
	if not _skill_executor.can_cast(skill, cd_key):
		return false
	var turns: int = int(ceil(cast_time))
	$CombatController.begin_enemy_cast(slot, skill.id, turns)
	_play_enemy_slot_animation(slot, "attack")
	_spawn_enemy_cast_name(skill.display_name, slot)
	_append_log("敵が【%s】を詠唱している" % skill.display_name)
	return true

func _advance_enemy_cast(slot: int) -> void:
	if $CombatController.should_enemy_skip_action_at(slot):
		var skip_label: String = $CombatController.get_enemy_skip_action_label_at(slot)
		if skip_label.is_empty():
			skip_label = "鈍化"
		_append_log("[%s] 敵の詠唱が中断された" % skip_label)
		return
	var pending: Dictionary = $CombatController.get_pending_cast("enemy", slot)
	if pending.is_empty():
		return
	var skill: Resource = DataRegistry.get_skill_data(str(pending.get("skill_id", "")))
	if skill == null:
		$CombatController.clear_pending_cast("enemy", slot)
		return
	var state: String = $CombatController.advance_pending_cast("enemy", slot)
	if state == "chant":
		_play_enemy_slot_animation(slot, "attack")
		_spawn_enemy_cast_name(skill.display_name, slot)
		_append_log("敵の【%s】詠唱中…" % skill.display_name)
		return
	$CombatController.clear_pending_cast("enemy", slot)
	_execute_enemy_skill(skill)

func _execute_enemy_skill(skill: Resource) -> bool:
	var res: Dictionary = _skill_executor.execute_support_skill(skill, "enemy:%s" % skill.id)
	if not res.get("executed", false):
		return false
	match skill.effect_type:
		"buff":
			_execute_enemy_buff(skill)
			return true
		"damage":
			_execute_enemy_damage(skill)
			return true
	return false

# 敵の自己強化スキル（激昂など）。enemy ユニットに状態付与し与ダメを上昇。
func _execute_enemy_buff(skill: Resource) -> void:
	_play_active_enemy_animation("attack")
	_spawn_enemy_skill_name(skill.display_name)
	var label: String = skill.display_name
	if not skill.apply_status_id.is_empty():
		$CombatController.apply_status_to_active_enemy(skill.apply_status_id, 1, 0)
		var eff: Resource = DataRegistry.get_status_effect(skill.apply_status_id)
		if eff != null:
			label = eff.display_name
	_append_log("敵スキル【%s】: 自身に[%s]" % [skill.display_name, label])

# 敵の攻撃スキル（全体/列/単体）。power_multiplier 分のダメージを対象へ。
func _execute_enemy_damage(skill: Resource) -> void:
	_play_active_enemy_animation("attack")
	_spawn_enemy_skill_name(skill.display_name)
	var party_size: int = $CombatController.party_combat_hp.size()
	var target_type: String = str(skill.target_type)
	var used_fallback: bool = false
	var targets: Array[int] = []
	var dist_tag: String = ""
	if target_type in [CombatFormation.TARGET_PARTY_FRONT, CombatFormation.TARGET_PARTY_BACK]:
		var resolved: Dictionary = CombatFormation.resolve_column_members_with_fallback(
			target_type,
			party_size,
			Callable($CombatController, "is_member_alive")
		)
		targets = resolved["indices"]
		used_fallback = bool(resolved.get("fallback", false))
		if not targets.is_empty():
			var shares: Dictionary = CombatFormation.threat_damage_shares(
				targets, Callable($CombatController, "get_member_threat")
			)
			dist_tag = CombatFormation.column_distribution_log_tag(targets)
			_apply_enemy_damage_to_targets(skill, targets, shares, dist_tag, target_type, used_fallback)
			return
	else:
		targets = CombatFormation.resolve_enemy_party_targets(
			skill,
			party_size,
			Callable($CombatController, "is_member_alive"),
			Callable($CombatController, "pick_enemy_target_for_melee_attack").bind(
				$CombatController.active_enemy_index
			)
		)
	if targets.is_empty():
		var empty_tag: String = CombatFormation.enemy_target_row_log_tag(target_type, used_fallback)
		_append_log("敵スキル【%s】%s\n  対象なし" % [skill.display_name, empty_tag])
		return
	var equal_shares: Dictionary = {}
	for ti: int in targets:
		equal_shares[ti] = 1.0
	_apply_enemy_damage_to_targets(skill, targets, equal_shares, dist_tag, target_type, used_fallback)

func _apply_enemy_damage_to_targets(
	skill: Resource,
	targets: Array[int],
	shares: Dictionary,
	dist_tag: String,
	target_type: String,
	used_fallback: bool
) -> void:
	var row_tag: String = CombatFormation.enemy_target_row_log_tag(target_type, used_fallback)
	var lines: PackedStringArray = []
	var atk_slot: int = $CombatController.active_enemy_index
	for ti: int in targets:
		var share: float = float(shares.get(ti, 0.0))
		if share <= 0.0:
			continue
		var power: float = float(skill.power_multiplier) * share
		var dmg: int = _calc_enemy_damage_to_member(ti, power, -1, atk_slot)["final"]
		if targets.size() > 1:
			dmg = maxi(1, dmg)
		$CombatController.apply_damage_to_member(ti, dmg)
		$CombatController.add_threat(ti, float(dmg) * CombatController.THREAT_TAKEN_K)
		_play_chr_hurt(ti)
		if dmg > 0 and ti < _chr_sprites.size():
			_spawn_hit_vfx(_chr_sprites[ti].global_position)
			_spawn_damage_number(str(dmg), _chr_sprites[ti].global_position, Color(1.0, 0.35, 0.35))
		var member: Resource = GameState.get_combatant(ti)
		var mname: String = member.display_name if member != null else "?"
		var density_tag: String = $CombatController.get_density_log_tag(ti)
		if not $CombatController.is_member_alive(ti):
			if ti < _chr_sprites.size():
				_chr_sprites[ti].visible = false
			lines.append("%s に %d（撃破）%s" % [mname, dmg, density_tag])
		else:
			lines.append("%s に %d%s" % [mname, dmg, density_tag])
		_on_member_damaged(ti)
	_append_log("敵スキル【%s】%s%s\n  %s" % [skill.display_name, row_tag, dist_tag, " / ".join(lines)])

# 敵スキル発動時、敵ドット絵の頭上にスキル名を赤系でポップ表示
func _spawn_enemy_skill_name(skill_name: String) -> void:
	if skill_name.is_empty():
		return
	var spr: AnimatedSprite2D = _active_enemy_sprite()
	if not spr.visible:
		return
	const ENEMY_SKILL_FONT_SIZE: int = 26
	var lbl := Label.new()
	lbl.text = skill_name
	var af: Font = _get_accent_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", ENEMY_SKILL_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 0.95))
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	var base_y: float = spr.global_position.y - 150.0
	lbl.pivot_offset = Vector2(float(skill_name.length()) * ENEMY_SKILL_FONT_SIZE * 0.5, ENEMY_SKILL_FONT_SIZE * 0.5)
	lbl.position = Vector2(
		spr.global_position.x - float(skill_name.length()) * ENEMY_SKILL_FONT_SIZE * 0.5,
		base_y
	)
	# ボス/敵技は一瞬大きく出して威圧感を出す
	lbl.scale = Vector2(1.3, 1.3)
	lbl.modulate.a = 0.0
	_damage_numbers_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.12)
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "position:y", base_y - 26.0, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.35)
	tw.chain().tween_callback(lbl.queue_free)

# 敵の詠唱中ポップ（P3-D112・紫系で通常スキル名と差別化）
func _spawn_enemy_cast_name(skill_name: String, slot: int) -> void:
	if skill_name.is_empty():
		return
	if slot < 0 or slot >= _swarm_sprites.size():
		_spawn_enemy_skill_name(skill_name)
		return
	var spr: AnimatedSprite2D = _swarm_sprites[slot]
	if not spr.visible:
		_spawn_enemy_skill_name(skill_name)
		return
	const CAST_FONT_SIZE: int = 22
	var lbl := Label.new()
	lbl.text = "◆ %s" % skill_name
	var af: Font = _get_accent_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", CAST_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.55, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.0, 0.12, 0.95))
	lbl.add_theme_constant_override("outline_size", 6)
	var base_y: float = spr.global_position.y - 130.0
	lbl.position = Vector2(
		spr.global_position.x - float(lbl.text.length()) * CAST_FONT_SIZE * 0.28,
		base_y
	)
	lbl.modulate.a = 0.0
	_damage_numbers_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.12)
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "position:y", base_y - 18.0, 0.55)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4).set_delay(0.25)
	tw.chain().tween_callback(lbl.queue_free)

func _do_enemy_attack(slot: int = -1) -> void:
	if $CombatController.current_enemy_data == null:
		return
	var target_idx: int = $CombatController.pick_enemy_target_for_melee_attack(slot)
	if target_idx < 0:
		return
	if slot >= 0:
		_play_enemy_slot_animation(slot, "attack")
	else:
		_play_active_enemy_animation("attack")
	var attacker_atk: int = $CombatController.get_enemy_attack_at(slot) if slot >= 0 else -1
	var enemy_result: Dictionary = _calc_enemy_damage_to_member(target_idx, 1.0, attacker_atk, slot)
	$CombatController.apply_damage_to_member(target_idx, enemy_result["final"])
	$CombatController.add_threat(target_idx, float(enemy_result["final"]) * CombatController.THREAT_TAKEN_K)
	_play_chr_hurt(target_idx)
	if enemy_result["final"] > 0 and target_idx < _chr_sprites.size():
		_spawn_hit_vfx(_chr_sprites[target_idx].global_position)
		_spawn_damage_number(str(enemy_result["final"]), _chr_sprites[target_idx].global_position, Color(1.0, 0.35, 0.35))
	if not $CombatController.is_member_alive(target_idx) and target_idx < _chr_sprites.size():
		_chr_sprites[target_idx].visible = false
	var target_combatant: Resource = GameState.get_combatant(target_idx)
	var member_name: String = target_combatant.display_name if target_combatant != null else "?"
	var guard_prefix: String = ""
	if target_combatant != null and target_combatant.job_id == "swordsman" and not GameState.is_helper_combatant(target_idx):
		guard_prefix = "[前衛] "
	var resist_tag: String = ""
	if enemy_result.get("elem_resisted", false):
		resist_tag = "  [耐性:%s]" % ElementResolverScript.get_display_name(_enemy_attack_element_at(slot))
	var density_tag: String = $CombatController.get_density_log_tag(target_idx)
	var log_text: String
	if enemy_result["mitigated"] > 0:
		log_text = "敵の攻撃: %s%s に %dダメージ（軽減%d）%s%s" % [
			guard_prefix, member_name, enemy_result["final"], enemy_result["mitigated"], density_tag, resist_tag,
		]
	else:
		log_text = "敵の攻撃: %s%s に %dダメージ%s%s" % [
			guard_prefix, member_name, enemy_result["final"], density_tag, resist_tag,
		]
	if not $CombatController.is_member_alive(target_idx):
		log_text += "\n%s が倒れた！" % member_name
	_append_log(log_text)
	_on_member_damaged(target_idx)
	_try_apply_enemy_hit_status(target_idx, slot)

func _try_apply_enemy_hit_status(target_idx: int, attacker_slot: int = -1) -> void:
	var slot: int = attacker_slot if attacker_slot >= 0 else $CombatController.active_enemy_index
	var enemy_data: Resource = $CombatController.get_enemy_data_at(slot)
	if enemy_data == null or enemy_data.on_hit_status_id.is_empty():
		return
	if enemy_data.on_hit_status_id == "curse":
		var room_type: int = $DungeonController.current_room_type
		var is_elevated: bool = (
			room_type == Enums.RoomType.ELITE
			or room_type == Enums.RoomType.BOSS
		)
		if not is_elevated:
			return
	if enemy_data.on_hit_status_chance <= 0.0 or randf() > enemy_data.on_hit_status_chance:
		return
	var unit_id: String = "party_%d" % target_idx
	var source_atk: int = $CombatController.get_enemy_attack_at(slot)
	if not $CombatController.apply_status(unit_id, enemy_data.on_hit_status_id, 1, source_atk):
		return
	var effect: Resource = DataRegistry.get_status_effect(enemy_data.on_hit_status_id)
	var label: String = enemy_data.on_hit_status_id
	if effect != null:
		label = effect.display_name
	var hit_target: Resource = GameState.get_combatant(target_idx)
	var member_name: String = hit_target.display_name if hit_target != null else "?"
	_append_log("[%s] %s に付与" % [label, member_name])

func _calc_damage(member_index: int = -1, target_slot: int = -1) -> Dictionary:
	if target_slot < 0 and member_index >= 0:
		target_slot = $CombatController.get_member_target_slot(member_index)
	var base_info: Dictionary = _calc_attack_base(member_index)
	var is_critical: bool = randf() < base_info["crit_rate"]
	var damage: int = base_info["base_damage"]
	if is_critical:
		damage = int(damage * CRITICAL_MULTIPLIER)
	damage = int(damage * $DungeonController.run_damage_multiplier)
	var action_range: String = CombatRange.resolve_for_action(member_index)
	damage = maxi(1, int(float(damage) * $CombatController.get_member_outgoing_damage_multiplier(member_index, action_range)))
	var elem_result: Dictionary = _apply_enemy_mitigation(
		damage, _get_weapon_element(member_index), member_index, target_slot
	)
	damage = elem_result["damage"]
	if target_slot < 0:
		target_slot = $CombatController.active_enemy_index
	damage = maxi(
		1,
		int(float(damage) * $CombatController.get_enemy_incoming_damage_multiplier_at(target_slot))
	)
	return {
		"damage": damage,
		"is_critical": is_critical,
		"element_tag": elem_result["element_tag"],
		"formation_tag": GameState.formation_range_log_tag(member_index, action_range),
		"target_slot": target_slot,
	}

func _calc_enemy_damage_to_member(
	target_index: int,
	power_multiplier: float = 1.0,
	attacker_atk: int = -1,
	attacker_slot: int = -1
) -> Dictionary:
	var atk: int = attacker_atk if attacker_atk >= 0 else $CombatController.get_enemy_attack()
	var base_dmg: int = int(float(atk) * power_multiplier)
	var out_slot: int = attacker_slot if attacker_slot >= 0 else $CombatController.active_enemy_index
	var enemy_id: String = $CombatController.get_enemy_id_at(out_slot)
	var phase_mult: float = CombatBossPhases.attack_mult(
		enemy_id, $CombatController.get_enemy_phase_index(out_slot)
	)
	base_dmg = maxi(1, int(round(float(base_dmg) * phase_mult)))
	base_dmg = maxi(1, int(float(base_dmg) * $CombatController.get_enemy_outgoing_damage_multiplier_at(out_slot)))
	var defense: int = 0
	var armor: Resource = GameState.get_member_equipped_armor(target_index)
	if armor != null:
		defense = armor.rolled_defense
	var acc: Resource = GameState.get_member_equipped_accessory(target_index)
	if acc != null:
		var acc_data: Resource = load("res://resources/accessories/" + acc.accessory_id + ".tres")
		if acc_data != null:
			defense += acc_data.defense_bonus
	defense += int(AffixStatCalculatorScript.get_bonuses(target_index).get("defense_flat", 0))
	if target_index >= 0 and target_index < GameState.party_members.size():
		var job_mods: Dictionary = JobStatCalculatorScript.get_member_modifiers(
			GameState.party_members[target_index]
		)
		var def_mult: float = float(job_mods.get("defense_multiplier", JobStatCalculator.DEFAULT_MULTIPLIER))
		defense = maxi(0, int(round(float(defense) * def_mult)))
	var final_dmg: int = max(1, base_dmg - defense)
	# 防御(guard)等の被ダメ補正（P3-D085）。
	var incoming_mult: float = $CombatController.get_member_incoming_damage_multiplier(target_index)
	if not is_equal_approx(incoming_mult, 1.0):
		final_dmg = maxi(0, int(round(float(final_dmg) * incoming_mult)))
	# 防具の属性耐性（P3-D103）: 敵攻撃属性が防具 resist_elements と一致なら軽減。
	var elem_resisted: bool = false
	var atk_elem: String = _enemy_attack_element_at(out_slot)
	if _member_resists_element(target_index, atk_elem):
		final_dmg = maxi(0, int(round(float(final_dmg) * ARMOR_RESIST_MULTIPLIER)))
		elem_resisted = true
	var mitigated: int = base_dmg - final_dmg
	return {"final": final_dmg, "base": base_dmg, "mitigated": mitigated, "elem_resisted": elem_resisted}

# 防御側属性耐性（P3-D103）。被ダメ軽減倍率。
const ARMOR_RESIST_MULTIPLIER: float = 0.75

func _active_enemy_attack_element() -> String:
	return _enemy_attack_element_at($CombatController.active_enemy_index)

func _enemy_attack_element_at(slot: int) -> String:
	var ed: Resource = $CombatController.get_enemy_data_at(slot)
	return str(ed.attack_element) if ed != null else ""

func _member_resists_element(target_index: int, attack_element: String) -> bool:
	if attack_element.is_empty():
		return false
	var armor: Resource = GameState.get_member_equipped_armor(target_index)
	if armor == null:
		return false
	var armor_data: Resource = load("res://resources/armors/" + str(armor.armor_id) + ".tres")
	if armor_data == null or not ("resist_elements" in armor_data):
		return false
	return attack_element in armor_data.resist_elements

# 敵の codex_materials を rarity 別確率で実ドロップ（P3-D067 / 図鑑↔経済の一本化）
const ECOLOGY_DROP_CHANCE: Dictionary = {0: 0.65, 1: 0.35, 2: 0.12, 3: 0.05}
const CODEX_INVESTIGATION_EXP_BONUS: float = 1.10
const CODEX_INVESTIGATION_MATERIAL_MULT: float = 1.50

func _roll_ecology_material_drops(enemy_data: Resource, log_lines: PackedStringArray) -> void:
	if enemy_data == null:
		return
	var codex_boost: bool = (
		GameState.get_exploration_policy() == "codex"
		and GameState.get_enemy_stage(str(enemy_data.id)) < 5
	)
	for raw_mat_id in enemy_data.codex_materials:
		var mat_id: String = str(raw_mat_id)
		if mat_id.is_empty():
			continue
		var mat_data: Resource = DataRegistry.get_material_data(mat_id)
		var rarity: int = 0 if mat_data == null else int(mat_data.rarity)
		var chance: float = float(ECOLOGY_DROP_CHANCE.get(rarity, 0.05))
		if codex_boost:
			chance = minf(chance * CODEX_INVESTIGATION_MATERIAL_MULT, 1.0)
		if randf() > chance:
			continue
		var amount: int = _apply_material_bonus(1)
		GameState.add_material(mat_id, amount)
		log_lines.append("採取: %s" % _format_material_reward_log(mat_id, amount, ""))
		_try_register_discovery("material", mat_id)

# アクティブ敵 1体の撃破ブックキーピング（P3-D082/D083/D111）。
func _award_enemy_kill_at(killed_slot: int) -> void:
	var room_type: int = $DungeonController.current_room_type
	$CombatController.clear_enemy_slot_status(killed_slot)
	$CombatController.capture_rewards_at(killed_slot)
	var defeated_enemy: Resource = $CombatController.get_enemy_data_at(killed_slot)
	var codex_investigation: bool = false
	if defeated_enemy != null:
		codex_investigation = (
			GameState.get_exploration_policy() == "codex"
			and GameState.get_enemy_stage(str(defeated_enemy.id)) < 5
		)
		GameState.add_enemy_kill(defeated_enemy.id)
		# 探索方針（図鑑優先）撃破1回につき図鑑進捗を加速（P3-D098）
		if GameState.get_exploration_policy() == "codex":
			GameState.add_enemy_kill(defeated_enemy.id)
	var mult: float = $DungeonController.get_reward_multiplier()
	var final_exp: int = int($CombatController.last_exp_reward * mult)
	var final_gold: int = int($CombatController.last_gold_reward * mult)
	if codex_investigation:
		final_exp = int(round(float(final_exp) * CODEX_INVESTIGATION_EXP_BONUS))
	$DungeonController.accumulate_rewards(final_exp, final_gold)
	if room_type == Enums.RoomType.BOSS:
		$DungeonController.update_discovery($DungeonController.DISCOVERY_BOSS_BONUS)
		_play_boss_animation("death")
	else:
		_play_enemy_slot_animation(killed_slot, "death")
		if killed_slot >= 0 and killed_slot < _swarm_hp_bars.size():
			_swarm_hp_bars[killed_slot].visible = false
			_swarm_nameplates[killed_slot].visible = false
	var bonus_tag: String = " (x%.1f)" % mult if mult > 1.0 else ""
	if codex_investigation:
		bonus_tag += " [図鑑調査]"
	var log_lines: PackedStringArray = [
		"撃破!  EXP +%d  Gold +%d%s" % [final_exp, final_gold, bonus_tag],
	]
	if room_type == Enums.RoomType.COMBAT and defeated_enemy != null:
		_roll_ecology_material_drops(defeated_enemy, log_lines)
	# P3-D074/D082: 撃破ごとの武器直ドロップ（各敵個別判定）
	var dropped_weapon: String = $DungeonController.roll_kill_weapon_drop(room_type)
	if not dropped_weapon.is_empty():
		GameState.last_run_weapon_dropped = dropped_weapon
		log_lines.append("武器ドロップ: %s" % DataRegistry.get_weapon_name(dropped_weapon))
		_spawn_weapon_drop(dropped_weapon, _enemy_slot_pos(killed_slot))
	if room_type == Enums.RoomType.ELITE:
		var elite_bonus: Dictionary = $DungeonController.apply_elite_bonus_loot()
		if not (elite_bonus["armor_id"] as String).is_empty():
			log_lines.append("エリート報酬: 防具 %s" % DataRegistry.get_armor_name(elite_bonus["armor_id"]))
		if not (elite_bonus["accessory_id"] as String).is_empty():
			log_lines.append("エリート報酬: 装飾品 %s" % DataRegistry.get_accessory_name(elite_bonus["accessory_id"]))
			GameState.last_run_accessory_dropped = elite_bonus["accessory_id"]
	# P3-D093: 撃破時の遺物ドロップ（解放型）
	var dropped_relic: String = $DungeonController.roll_kill_relic_drop(room_type)
	if not dropped_relic.is_empty():
		GameState.last_run_relic_dropped = dropped_relic
		log_lines.append("遺物入手: %s" % CombatRelics.display_name(dropped_relic))
	_append_log("\n".join(log_lines))

# 敵スロット撃破時。全滅なら true（戦闘終了済み）。
func _on_enemy_slot_killed(killed_slot: int) -> bool:
	$CombatController.clear_pending_cast("enemy", killed_slot)
	_debuff_marks.erase(killed_slot)
	_award_enemy_kill_at(killed_slot)
	if killed_slot == $CombatController.active_enemy_index:
		$CombatController.advance_active_enemy()
	elif not $CombatController.is_enemy_slot_alive($CombatController.active_enemy_index):
		$CombatController.advance_active_enemy()
	if $CombatController.living_enemy_count() == 0:
		_finalize_combat_cleared()
		return true
	_append_log("残り %d 体" % $CombatController.living_enemy_count())
	_update_status_labels()
	_update_hp_bars()
	_update_turn_order_ui($CombatController.get_ct_order())
	return false

func _on_active_enemy_killed() -> bool:
	return _on_enemy_slot_killed($CombatController.active_enemy_index)

# 群れ全滅で戦闘を終了する（P3-D083）。
func _finalize_combat_cleared() -> void:
	$CombatTimer.stop()
	$CombatController.end_combat()
	_update_status_labels()
	_clear_turn_order_ui()
	_append_log("累計  EXP %d  Gold %d" % [
		$DungeonController.run_exp_reward,
		$DungeonController.run_gold_reward,
	])
	_update_enemy_label()
	_update_hp_bars()
	_update_next_room_button()
	_start_auto_progress()

# 単体メンバーの 1 行動（P3-D086）。戦術プラン（優先度＋発動条件）に従い、
# 条件成立かつ実際に発動できた最初のスロットで行動を確定する。
func _do_member_turn(member_idx: int) -> void:
	if not $CombatController.is_member_alive(member_idx):
		return
	if $CombatController.has_pending_cast("party", member_idx):
		_advance_member_cast(member_idx)
		return
	var member: Resource = GameState.get_combatant(member_idx)
	$CombatController.resolve_member_target(member_idx, CombatGambit.target_from_member(member))
	var ctx: Dictionary = _build_tactics_context(member_idx)
	for rule: Dictionary in CombatGambit.plan_from_member(member):
		if not CombatTactics.condition_met(rule, ctx):
			continue
		var fired: bool = false
		match str(rule.get("slot", "")):
			"ultimate":
				fired = _try_member_ultimate(member_idx)
			"defend":
				fired = _do_member_defend_slot(member_idx)
			"skill":
				fired = _try_member_equipped_skill(member_idx)
			"attack":
				_do_member_basic_attack(member_idx)
				fired = true
		if fired:
			return
	# 安全フォールバック（プランが空/全不発の場合）
	_do_member_basic_attack(member_idx)

# 群れ(2体以上)時のみ作用（P3-D110: 敵別状態スロットで個体ごと保持・切替可）。
# 廃止（P3-D111）: パーティ一括フォーカス → メンバー個別ターゲットへ移行。

# 戦術条件の評価に使う戦闘コンテキスト。
func _build_tactics_context(member_idx: int) -> Dictionary:
	var hp_ratio: float = 1.0
	if member_idx >= 0 and member_idx < $CombatController.party_max_hp.size():
		var maxhp: int = $CombatController.party_max_hp[member_idx]
		if maxhp > 0:
			hp_ratio = float($CombatController.party_combat_hp[member_idx]) / float(maxhp)
	var room_type: int = $DungeonController.current_room_type
	var ally_dead: bool = false
	for i: int in GameState.party_members.size():
		if not $CombatController.is_member_alive(i):
			ally_dead = true
			break
	var target_slot: int = $CombatController.get_member_target_slot(member_idx)
	return {
		"self_hp_ratio": hp_ratio,
		"enemy_is_boss": room_type == Enums.RoomType.BOSS,
		"enemy_is_elite": room_type == Enums.RoomType.ELITE,
		"enemy_count": $CombatController.living_enemy_count(),
		"ally_dead": ally_dead,
		"enemy_has_bleed": $CombatController.get_enemy_status_stacks_at(target_slot, "bleed") > 0,
		"enemy_has_poison": $CombatController.get_enemy_status_stacks_at(target_slot, "poison") > 0,
		"enemy_has_mark": _any_enemy_has_status("mark"),
		"enemy_has_stun": _any_enemy_has_status("stun"),
		"enemy_has_vulnerable": _any_enemy_has_status("vulnerable"),
		"enemy_has_armor_break": _any_enemy_has_status("armor_break"),
		"enemy_has_fear": _any_enemy_has_status("fear"),
		"ultimate_ready": _is_member_ultimate_ready(member_idx),
		"self_range": _member_combat_range(member_idx),
		"ally_injured": $CombatController.get_most_injured_member_index() >= 0,
	}

# 必殺技が CT/CD 待ちなしで撃てるか（P3-D108 ultimate_ready）。
func _is_member_ultimate_ready(member_idx: int) -> bool:
	var ult: Resource = _get_member_ultimate_skill(member_idx)
	if ult == null:
		return false
	return _skill_executor.can_cast(ult, "%d:%s" % [member_idx, ult.id])

# 戦術「距離」判定用（CombatRange SSOT に委譲）。
func _member_combat_range(member_idx: int) -> String:
	return CombatRange.resolve_member_default(member_idx)

func _any_enemy_has_status(status_id: String) -> bool:
	for slot: int in $CombatController.get_living_enemy_indices():
		if $CombatController.get_enemy_status_stacks_at(slot, status_id) > 0:
			return true
	return false

# 必殺技スロット（長CD・高威力）。発動できたら true。
func _try_member_ultimate(member_idx: int) -> bool:
	var ult: Resource = _get_member_ultimate_skill(member_idx)
	if ult == null:
		return false
	return _try_cast_member_skill(member_idx, ult, true)

# 防御スロット（被ダメ減バフを自身に付与）。発動条件は戦術プラン側で判定する。
# 既に guard 中なら不発（毎行動の重ね掛けで硬直しないようガード）。付与できたら true。
func _do_member_defend_slot(member_idx: int) -> bool:
	if _member_has_status(member_idx, "guard"):
		return false
	if not $CombatController.apply_status("party_%d" % member_idx, "guard", 1, 0):
		return false
	# 防御＝挑発（Threat スパイク・P3-D104）。身を固めて敵の attention を引く。
	$CombatController.apply_taunt(member_idx)
	_activate_taunt_link(member_idx)
	_update_status_icons()
	_clear_member_skill_labels(member_idx)
	_spawn_skill_name("防御", member_idx, 0.0)
	var m: Resource = GameState.get_combatant(member_idx)
	var nm: String = m.display_name if m != null else "?"
	_append_log("[防御] %s は身を固めた" % nm)
	return true

# スキル①②スロット（装備スキル）。ローテ＋温存を考慮し発動可能な1つを撃つ（P3-D113）。
func _try_member_equipped_skill(member_idx: int) -> bool:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return false
	var ids: Array[String] = GameState.get_equipped_skill_ids(member)
	if ids.is_empty():
		return false
	var ctx: Dictionary = _build_tactics_context(member_idx)
	var start: int = $CombatController.get_skill_rotation_index(member_idx) % ids.size()
	for attempt: int in ids.size():
		var pick: int = (start + attempt) % ids.size()
		var sd: Resource = DataRegistry.get_skill_data(ids[pick])
		if sd == null:
			continue
		if not CombatTactics.skill_reserve_met(sd, ctx):
			continue
		if _try_cast_member_skill(member_idx, sd, false):
			$CombatController.set_skill_rotation_after_cast(member_idx, pick, ids.size())
			return true
	return false

# スキル詠唱開始または即時発動（P3-D112）。Action Lock 中は _do_member_turn がここを経由しない。
func _try_cast_member_skill(member_idx: int, skill_data: Resource, is_ultimate: bool) -> bool:
	if skill_data == null:
		return false
	var cd_key: String = "%d:%s" % [member_idx, skill_data.id]
	if not _skill_executor.can_cast(skill_data, cd_key):
		return false
	match skill_data.effect_type:
		"heal":
			if $CombatController.get_most_injured_member_index() < 0:
				return false
		"damage":
			if not _member_has_living_target(member_idx):
				return false
	var cast_time: float = float(skill_data.cast_time)
	if cast_time <= 0.0:
		var log_text: String = _execute_member_skill(member_idx, skill_data, 0).strip_edges()
		if log_text.is_empty():
			return false
		if is_ultimate:
			_append_log("【必殺】" + log_text.trim_prefix("【スキル】"))
		else:
			_append_log(log_text)
		_update_hp_bars()
		return true
	var target_slot: int = $CombatController.get_member_target_slot(member_idx)
	var turns: int = int(ceil(cast_time))
	$CombatController.begin_party_cast(member_idx, skill_data.id, target_slot, turns)
	var member: Resource = GameState.get_combatant(member_idx)
	var mname: String = member.display_name if member != null else "?"
	_append_log("[詠唱] %s が%sを唱え始めた" % [mname, skill_data.display_name])
	_spawn_cast_chant_label(skill_data.display_name, member_idx)
	return true

func _advance_member_cast(member_idx: int) -> void:
	var pending: Dictionary = $CombatController.get_pending_cast("party", member_idx)
	if pending.is_empty():
		return
	var skill_data: Resource = DataRegistry.get_skill_data(str(pending.get("skill_id", "")))
	if skill_data == null:
		$CombatController.clear_pending_cast("party", member_idx)
		return
	var state: String = $CombatController.advance_pending_cast("party", member_idx)
	if state == "chant":
		_append_log("[詠唱] %s…" % skill_data.display_name)
		_spawn_cast_chant_label(skill_data.display_name, member_idx)
		return
	$CombatController.clear_pending_cast("party", member_idx)
	if pending.has("target_slot"):
		var frozen: int = int(pending["target_slot"])
		if member_idx >= 0 and member_idx < $CombatController.member_target_slot.size():
			$CombatController.member_target_slot[member_idx] = frozen
	var log_text: String = _execute_member_skill(member_idx, skill_data, 0).strip_edges()
	if log_text.is_empty():
		return
	if str(skill_data.slot_type) == "ultimate":
		_append_log("【必殺】" + log_text.trim_prefix("【スキル】"))
	else:
		_append_log(log_text)
	_update_hp_bars()

# 通常攻撃スロット（武器ベース）。
func _do_member_basic_attack(member_idx: int) -> void:
	if not _member_has_living_target(member_idx):
		return
	var target_slot: int = $CombatController.get_member_target_slot(member_idx)
	var result: Dictionary = _calc_damage(member_idx, target_slot)
	result["damage"] = int(result["damage"]) + _consume_combo_bonus(
		member_idx, int(result["damage"]), _member_action_tags(member_idx), null, target_slot
	)
	var member: Resource = GameState.get_combatant(member_idx)
	var mname: String = member.display_name if member != null else "?"
	var crit_tag: String = "  CRITICAL!" if result["is_critical"] else ""
	var elem_tag: String = result.get("element_tag", "")
	var form_tag: String = result.get("formation_tag", "")
	var tgt_tag: String = _member_target_tag(member_idx)
	var dmg: int = int(result["damage"])
	if dmg > 0:
		_play_hit_vfx(_get_weapon_element(member_idx))
		_play_chr_attack_one(member_idx)
		_spawn_damage_number(
			str(dmg),
			_enemy_slot_pos(target_slot),
			Color(1.0, 0.9, 0.0),
			1.25 if result["is_critical"] else 1.0
		)
	_append_log("%s の攻撃: %dダメージ%s%s%s%s" % [mname, dmg, crit_tag, elem_tag, form_tag, tgt_tag])
	if _deal_member_damage_to_enemy(member_idx, dmg, target_slot):
		return
	if $CombatController.is_enemy_slot_alive(target_slot):
		_play_enemy_slot_animation(target_slot, "hurt")
	_try_apply_affix_statuses(member_idx)
	_update_hp_bars()

# 必殺技スロットのスキル（ジョブ ultimate_skill_id → 既定 ultimate_strike）。
func _get_member_ultimate_skill(member_idx: int) -> Resource:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return null
	var ult_id: String = Constants.DEFAULT_ULTIMATE_SKILL_ID
	if not str(member.job_id).is_empty():
		var job: Resource = DataRegistry.get_job_data(member.job_id)
		if job != null and "ultimate_skill_id" in job and not str(job.ultimate_skill_id).is_empty():
			ult_id = str(job.ultimate_skill_id)
	if ult_id.is_empty():
		return null
	return DataRegistry.get_skill_data(ult_id)

func _member_has_status(member_idx: int, effect_id: String) -> bool:
	for e: Dictionary in $CombatController.get_member_status_list(member_idx):
		if str(e.get("effect_id", "")) == effect_id:
			return true
	return false

# ---- パッシブ / リアクション（P3-D088） ----

func _tick_passive_cd(delta: float) -> void:
	for k in _passive_cd.keys():
		_passive_cd[k] = maxf(0.0, float(_passive_cd[k]) - delta)
	for k in _relic_cd.keys():
		_relic_cd[k] = maxf(0.0, float(_relic_cd[k]) - delta)

# 戦闘開始時パッシブを生存メンバーで発火。
func _fire_combat_start_passives() -> void:
	for i: int in GameState.party_members.size():
		if $CombatController.is_member_alive(i):
			_fire_member_passives(i, "on_combat_start")

# メンバー被弾フック: 生存なら on_hit_taken、死亡なら生存者の on_ally_death を発火。
func _on_member_damaged(target_idx: int) -> void:
	if $CombatController.is_member_alive(target_idx):
		_fire_member_passives(target_idx, "on_hit_taken")
		_fire_member_relic_triggers(target_idx, "on_hit_taken")
		return
	$CombatController.clear_pending_cast("party", target_idx)
	for i: int in GameState.party_members.size():
		if i == target_idx:
			continue
		if $CombatController.is_member_alive(i):
			_fire_member_passives(i, "on_ally_death")
			_fire_member_relic_triggers(i, "on_ally_death")

# 指定メンバーの該当 trigger パッシブを順に試行。
func _fire_member_passives(member_idx: int, trigger: String) -> void:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return
	for p: Dictionary in CombatPassives.for_job(str(member.job_id)):
		if str(p.get("trigger", "")) != trigger:
			continue
		_try_fire_passive(member_idx, p)

func _try_fire_passive(member_idx: int, p: Dictionary) -> void:
	var pid: String = str(p.get("id", ""))
	var key: String = "%d:%s" % [member_idx, pid]
	if float(_passive_cd.get(key, 0.0)) > 0.0:
		return
	# 条件
	if str(p.get("condition", "always")) == "self_hp_below":
		var ratio: float = 1.0
		if member_idx < $CombatController.party_max_hp.size():
			var maxhp: int = $CombatController.party_max_hp[member_idx]
			if maxhp > 0:
				ratio = float($CombatController.party_combat_hp[member_idx]) / float(maxhp)
		if ratio >= float(p.get("value", 0.0)):
			return
	# 効果
	var applied: bool = false
	match str(p.get("effect", "")):
		"apply_status":
			var sid: String = str(p.get("status_id", ""))
			if sid.is_empty():
				return
			if str(p.get("target", "self")) == "party":
				for i: int in GameState.party_members.size():
					if $CombatController.is_member_alive(i):
						applied = $CombatController.apply_status("party_%d" % i, sid, 1, 0) or applied
			else:
				applied = $CombatController.apply_status("party_%d" % member_idx, sid, 1, 0)
			_update_status_icons()
		"heal":
			var amount: int = _apply_healing_bonus(int(p.get("value", 10)))
			$CombatController.heal_party(amount)
			_update_hp_bars()
			applied = true
	if not applied:
		return
	var cd: float = float(p.get("cooldown", 0.0))
	if cd > 0.0:
		_passive_cd[key] = cd
	_clear_member_skill_labels(member_idx)
	_spawn_skill_name("◇" + str(p.get("display_name", "")), member_idx, 0.0)
	_append_log("[パッシブ] %s 発動" % str(p.get("display_name", "")))

# ---- 遺物発火（P3-D114） ----

func _fire_member_relic_triggers(member_idx: int, trigger: String, ctx: Dictionary = {}) -> void:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return
	var def: Dictionary = CombatRelics.trigger_def(GameState.get_member_relic_id(member))
	if def.is_empty() or str(def.get("trigger", "")) != trigger:
		return
	if trigger == "on_attack":
		var every_n: int = int(def.get("every_n", 0))
		if every_n > 0:
			var hits: int = int(_relic_attack_hits.get(member_idx, 0)) + 1
			_relic_attack_hits[member_idx] = hits
			if hits % every_n != 0:
				return
	_try_fire_relic_trigger(member_idx, def, ctx)

func _try_fire_relic_trigger(member_idx: int, def: Dictionary, ctx: Dictionary = {}) -> void:
	var rid: String = str(def.get("id", ""))
	var key: String = "%d:%s" % [member_idx, rid]
	if float(_relic_cd.get(key, 0.0)) > 0.0:
		return
	if str(def.get("condition", "always")) == "self_hp_below":
		var ratio: float = 1.0
		if member_idx < $CombatController.party_max_hp.size():
			var maxhp: int = $CombatController.party_max_hp[member_idx]
			if maxhp > 0:
				ratio = float($CombatController.party_combat_hp[member_idx]) / float(maxhp)
		if ratio >= float(def.get("value", 0.0)):
			return
	var applied: bool = false
	match str(def.get("effect", "")):
		"apply_status":
			var sid: String = str(def.get("status_id", ""))
			if sid.is_empty():
				return
			if str(def.get("target", "self")) == "party":
				for i: int in GameState.party_members.size():
					if $CombatController.is_member_alive(i):
						applied = $CombatController.apply_status("party_%d" % i, sid, 1, 0) or applied
			else:
				applied = $CombatController.apply_status("party_%d" % member_idx, sid, 1, 0)
			_update_status_icons()
		"bonus_damage":
			var slot: int = int(ctx.get("target_slot", -1))
			var base_dmg: int = int(ctx.get("damage", 0))
			var frac: float = float(def.get("bonus_fraction", 0.25))
			var bonus: int = maxi(1, int(round(float(base_dmg) * frac))) if base_dmg > 0 else 0
			if slot >= 0 and bonus > 0 and $CombatController.is_enemy_slot_alive(slot):
				$CombatController.apply_damage_to_enemy_slot(slot, bonus)
				$CombatController.add_threat(member_idx, float(bonus) * CombatController.THREAT_DAMAGE_K)
				_update_hp_bars()
				applied = true
				_check_boss_phase_transition(slot)
				if $CombatController.get_enemy_hp_at(slot) <= 0:
					_on_enemy_slot_killed(slot)
	if not applied:
		return
	var cd: float = float(def.get("cooldown", 0.0))
	if cd > 0.0:
		_relic_cd[key] = cd
	_clear_member_skill_labels(member_idx)
	_spawn_skill_name("◈" + str(def.get("display_name", "")), member_idx, 0.0)
	_append_log("[遺物] %s 発動" % str(def.get("display_name", "")))

# ---- パーティ連携連鎖（P3-D115） ----

func _clear_party_links() -> void:
	_taunt_link_source = -1
	_taunt_link_charges = 0
	_debuff_marks.clear()
	_heal_rally_member = -1

func _activate_taunt_link(source_idx: int) -> void:
	_taunt_link_source = source_idx
	_taunt_link_charges = CombatLinks.taunt_max_charges()

func _set_heal_rally(member_idx: int) -> void:
	if member_idx >= 0 and $CombatController.is_member_alive(member_idx):
		_heal_rally_member = member_idx

func _consume_link_bonus(member_idx: int, hit_damage: int, target_slot: int = -1) -> int:
	if hit_damage <= 0:
		return 0
	if target_slot < 0:
		target_slot = $CombatController.get_member_target_slot(member_idx)
	if not $CombatController.is_enemy_slot_alive(target_slot):
		return 0
	if _heal_rally_member == member_idx:
		var rally_bonus: int = CombatLinks.bonus_for("heal_rally", hit_damage)
		if rally_bonus > 0:
			_heal_rally_member = -1
			_report_link_bonus("heal_rally", rally_bonus, member_idx, target_slot)
			return rally_bonus
	if _debuff_marks.has(target_slot):
		var applier: int = int(_debuff_marks[target_slot])
		if applier != member_idx:
			var mark_bonus: int = CombatLinks.bonus_for("debuff_mark", hit_damage)
			if mark_bonus > 0:
				_debuff_marks.erase(target_slot)
				_report_link_bonus("debuff_mark", mark_bonus, member_idx, target_slot)
				return mark_bonus
	if _taunt_link_charges > 0 and member_idx != _taunt_link_source:
		var taunt_bonus: int = CombatLinks.bonus_for("taunt_link", hit_damage)
		if taunt_bonus > 0:
			_taunt_link_charges -= 1
			if _taunt_link_charges <= 0:
				_taunt_link_source = -1
			_report_link_bonus("taunt_link", taunt_bonus, member_idx, target_slot)
			return taunt_bonus
	return 0

# ---- ボスフェーズ移行（P3-D116） ----

func _check_boss_phase_transition(slot: int) -> void:
	if not $CombatController.is_enemy_slot_alive(slot):
		return
	var enemy_id: String = $CombatController.get_enemy_id_at(slot)
	if not CombatBossPhases.has_phases(enemy_id):
		return
	var ratio: float = $CombatController.get_enemy_hp_ratio_at(slot)
	var new_idx: int = CombatBossPhases.resolve_phase_index(enemy_id, ratio)
	var cur_idx: int = $CombatController.get_enemy_phase_index(slot)
	if new_idx <= cur_idx:
		return
	$CombatController.set_enemy_phase_index(slot, new_idx)
	var phase: Dictionary = CombatBossPhases.phase_def(enemy_id, new_idx)
	var log_line: String = str(phase.get("log", ""))
	if log_line.is_empty():
		log_line = "【フェーズ移行】%s" % str(phase.get("label", ""))
	_append_log(log_line)
	GameState.mark_boss_phase_seen(enemy_id, new_idx)
	if slot == $CombatController.active_enemy_index:
		_play_boss_animation("attack")
		_spawn_enemy_skill_name(str(phase.get("label", "")))

func _report_link_bonus(link_id: String, bonus: int, member_idx: int, target_slot: int) -> void:
	var label: String = CombatLinks.label_for(link_id)
	var pos: Vector2 = _enemy_slot_pos(target_slot)
	_spawn_damage_number("%s +%d" % [label, bonus], pos + Vector2(0.0, -62.0), Color(0.45, 0.9, 1.0), 1.18)
	_append_log("[連携] %s +%d" % [label, bonus])

func _play_chr_attack_one(idx: int) -> void:
	if idx < 0 or idx >= _chr_sprites.size():
		return
	var s: AnimatedSprite2D = _chr_sprites[idx]
	if s.visible and s.sprite_frames != null and s.sprite_frames.has_animation("attack"):
		s.play("attack")

func _handle_party_wipe() -> void:
	$CombatTimer.stop()
	$CombatController.end_combat()
	_update_status_labels()
	_clear_turn_order_ui()
	# 勝利した敵はその場に残す（撃破ではなく味方全滅の演出）
	_play_active_enemy_animation("idle")
	_hide_chr_sprites()
	_update_combat_visibility()
	_non_combat_zone.visible = false
	_append_log("全員が倒れた... 探索失敗")
	GameState.last_run_exp_reward = $DungeonController.run_exp_reward
	GameState.last_run_gold_reward = $DungeonController.run_gold_reward
	GameState.last_run_token_reward = 0
	GameState.last_run_weapon_dropped = ""
	GameState.last_run_armor_dropped = ""
	GameState.last_run_accessory_dropped = ""
	GameState.last_run_relic_dropped = ""
	GameState.last_run_outcome = GameState.RUN_OUTCOME_WIPE
	GameState.snapshot_last_run_context()
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	GameState.clear_event_helper()
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")

func _apply_healing_bonus(base_amount: int) -> int:
	var amount: int = AffixStatCalculatorScript.apply_healing_bonus(base_amount)
	# ロール編成ボーナス（support×2=治癒+20%・P3-D097）
	var heal_mult: float = $CombatController.get_party_role_heal_multiplier()
	return maxi(0, int(round(float(amount) * heal_mult)))

func _apply_material_bonus(base_amount: int) -> int:
	return AffixStatCalculatorScript.apply_material_bonus(base_amount)

func _update_enemy_label() -> void:
	# 敵名は頭上ネームプレート(_position_enemy_overlays)へ集約（モック準拠）。
	# 下部固定ラベルは常に非表示にする。
	_label_enemy.text = ""
	_label_enemy.visible = false

func _update_status_labels() -> void:
	_update_status_icons()
	if not $CombatController.is_in_combat:
		_label_status_enemy.text = ""
		_label_status_enemy.visible = false
		_label_status_party.text = ""
		_label_status_party.visible = false
		return
	_label_status_enemy.visible = false
	_label_status_party.visible = false

func _update_enemy_hp_label() -> void:
	_update_hp_bars()

func _update_party_hp_label() -> void:
	_update_hp_bars()

func _update_next_room_button() -> void:
	_btn_next_room.visible = false
	_update_combat_visibility()

func _update_combat_visibility() -> void:
	# レイアウトは「戦闘中フラグ」ではなく「戦闘フロアか」で切り替える。
	# これにより撃破直後（is_in_combat=false）でも次フロア進入までバトルログ等を残し、
	# 非戦闘フロアに入った時点で初めて消す（敵味方位置のズレ防止）。
	var on_combat_floor: bool = $DungeonController.is_combat_room()
	_non_combat_zone.visible = not on_combat_floor
	_auto_combat_row.visible = on_combat_floor
	$MainVBox/BattleLogPanel.visible = on_combat_floor
	_party_status_panel.visible = on_combat_floor
	_narrative_panel.visible = not on_combat_floor
	_update_combat_tier_frame()

func _update_combat_tier_frame() -> void:
	var show: bool = false
	var tier_text: String = ""
	var border_color: Color = Color.WHITE
	if $CombatController.is_in_combat:
		match $DungeonController.current_room_type:
			Enums.RoomType.ELITE:
				show = true
				tier_text = "⚔ エリート戦"
				border_color = Color(1.0, 0.7, 0.2)
			Enums.RoomType.BOSS:
				show = true
				tier_text = "⚔ ボス戦"
				border_color = Color(1.0, 0.25, 0.25)
	_combat_tier_frame.visible = show
	if not show:
		return
	# 「⚔ ボス戦/エリート戦」テキストはドット絵と重なるため非表示。種別は枠色で表現する。
	_label_combat_tier.text = ""
	_label_combat_tier.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(border_color.r, border_color.g, border_color.b, 0.1)
	style.border_color = border_color
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	_combat_tier_frame.add_theme_stylebox_override("panel", style)

func _start_auto_progress() -> void:
	if _is_paused:
		_auto_progress_paused_remaining = _auto_delay
		return
	$AutoProgressTimer.wait_time = _auto_delay
	$AutoProgressTimer.start()

func _on_auto_progress_timeout() -> void:
	if _auto_progress_finishes:
		_auto_progress_finishes = false
		_on_finish_button_pressed()
	else:
		_transition_to_next_room()

# 部屋移動の軽量トランジション（フェード＋部屋名キャプション・速度連動）
func _transition_to_next_room() -> void:
	var half: float = clampf(_auto_delay * 0.3, 0.12, 0.3)
	var tw: Tween = create_tween()
	tw.tween_property(_transition_overlay, "modulate:a", 1.0, half)
	tw.tween_callback(_advance_with_caption)
	tw.tween_property(_transition_overlay, "modulate:a", 0.0, half)

func _advance_with_caption() -> void:
	_advance_to_next_room()
	_label_transition.text = _label_room.text

func _on_finish_button_pressed() -> void:
	_btn_finish.disabled = true
	$CombatTimer.stop()
	$CombatController.end_combat()
	$DungeonController.generate_run_loot()
	GameState.last_run_exp_reward = $DungeonController.run_exp_reward
	GameState.last_run_level_ups = LevelSystem.grant_exp_to_party($DungeonController.run_exp_reward)
	GameState.last_run_gold_reward = $DungeonController.run_gold_reward
	GameState.last_run_token_reward = randi_range(1, 2)
	GameState.last_run_weapon_dropped = $DungeonController.last_weapon_dropped
	GameState.last_run_armor_dropped = $DungeonController.last_armor_dropped
	if not $DungeonController.last_accessory_dropped.is_empty():
		GameState.last_run_accessory_dropped = $DungeonController.last_accessory_dropped
	GameState.mark_dungeon_cleared(GameState.get_active_dungeon_id())
	GameState.last_run_outcome = GameState.RUN_OUTCOME_CLEAR
	GameState.snapshot_last_run_context()
	GameState.clear_event_helper()
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")

# ---- Menu Overlay ----

func _on_menu_button_pressed() -> void:
	_menu_overlay.visible = true

func _on_close_menu_pressed() -> void:
	_menu_overlay.visible = false

func _on_menu_finish_pressed() -> void:
	_menu_overlay.visible = false
	_on_finish_button_pressed()

# ---- Speed / Pause ----

func _on_speed_x1_pressed() -> void:
	_set_paused(false)
	_auto_delay = AUTO_DELAY_X1
	$CombatTimer.wait_time = SPEED_X1
	if $CombatController.is_in_combat:
		$CombatTimer.start()
	if $AutoProgressTimer.time_left > 0:
		$AutoProgressTimer.start(_auto_delay)

func _on_speed_x2_pressed() -> void:
	_set_paused(false)
	_auto_delay = AUTO_DELAY_X2
	$CombatTimer.wait_time = SPEED_X2
	if $CombatController.is_in_combat:
		$CombatTimer.start()
	if $AutoProgressTimer.time_left > 0:
		$AutoProgressTimer.start(_auto_delay)

func _set_paused(paused: bool) -> void:
	if _is_paused == paused:
		return
	_is_paused = paused
	var resume_label: String = "再開" if paused else "一時停止"
	$MainVBox/BottomZone/AutoCombatRow/ButtonPause.text = resume_label
	$MainVBox/HeaderBar/ButtonStop.text = "再開" if paused else "停止"
	_pause_overlay.visible = paused
	if paused:
		$CombatTimer.stop()
		_auto_progress_paused_remaining = $AutoProgressTimer.time_left
		$AutoProgressTimer.stop()
	else:
		if $CombatController.is_in_combat:
			$CombatTimer.start()
		if _auto_progress_paused_remaining > 0:
			$AutoProgressTimer.start(_auto_progress_paused_remaining)
			_auto_progress_paused_remaining = 0.0

func _on_pause_button_pressed() -> void:
	_set_paused(not _is_paused)

func _on_stop_pressed() -> void:
	_set_paused(not _is_paused)

func _on_pause_resume_pressed() -> void:
	_set_paused(false)

func _on_pause_retire_pressed() -> void:
	if not _is_paused:
		return
	_retire_from_dungeon()

func _retire_from_dungeon() -> void:
	_pause_overlay.visible = false
	_is_paused = false
	$CombatTimer.stop()
	$AutoProgressTimer.stop()
	if $CombatController.is_in_combat:
		$CombatController.end_combat()
	_append_log("リタイアして帰還した")
	GameState.last_run_exp_reward = $DungeonController.run_exp_reward
	GameState.last_run_level_ups = LevelSystem.grant_exp_to_party($DungeonController.run_exp_reward)
	GameState.last_run_gold_reward = $DungeonController.run_gold_reward
	GameState.last_run_token_reward = 0
	if GameState.last_run_armor_dropped.is_empty():
		GameState.last_run_armor_dropped = $DungeonController.last_armor_dropped
	GameState.last_run_outcome = GameState.RUN_OUTCOME_RETIRE
	GameState.snapshot_last_run_context()
	GameState.clear_event_helper()
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")

# ---- Enemy Sprite ----

func _show_enemy_sprite(enemy_id: String) -> void:
	if $DungeonController.current_room_type == Enums.RoomType.BOSS:
		_enemy_sprite.visible = false
		return
	var path: String = ENEMY_SPRITE_MAP.get(enemy_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		_enemy_sprite.visible = false
		return
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames == null:
		_enemy_sprite.visible = false
		return
	_enemy_sprite.sprite_frames = frames
	_normalize_enemy_scale(_enemy_sprite, frames)
	_enemy_sprite.play("idle")
	_enemy_sprite.visible = true

# 敵セルサイズが種別で異なる（通常 96px / エリート 128px 等）ため表示高さを揃える。
# 固定 scale だと 128px が突出して巨大化するのを防ぐ。
func _normalize_enemy_scale(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	# 味方CHR(_normalize_chr_scale)と同様、フレーム高ではなく実体(α非透明領域)の高さを
	# 基準にスケールする。モック準拠で「敵≒味方サイズ(やや大)」へ揃える（縮小も許可）。
	const ENEMY_BODY_TARGET_PX: float = 132.0
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var frame_h: float = tex.get_height()
	if frame_h <= 0.0:
		return
	var body_h: float = frame_h
	var img: Image = tex.get_image()
	if img != null:
		var used: Rect2i = img.get_used_rect()
		if used.size.y > 0:
			body_h = float(used.size.y)
	var s: float = clampf(ENEMY_BODY_TARGET_PX / body_h, 0.05, 20.0)
	sprite.scale = Vector2(s, s)
	sprite.centered = true

func _hide_enemy_sprite() -> void:
	_clear_swarm_slots()
	_clear_turn_order_ui()
	_enemy_sprite.visible = false
	_hp_bar_enemy.visible = false
	_enemy_nameplate.visible = false

# ---- 群れ表示（P3-D082） ----

# 動的生成した 2体目以降のスロットを解放し、スロット配列を空に戻す（slot0 の既存ノードは残す）。
func _clear_swarm_slots() -> void:
	for i in range(1, _swarm_sprites.size()):
		if is_instance_valid(_swarm_sprites[i]):
			_swarm_sprites[i].queue_free()
	for i in range(1, _swarm_hp_bars.size()):
		if is_instance_valid(_swarm_hp_bars[i]):
			_swarm_hp_bars[i].queue_free()
	for i in range(1, _swarm_nameplates.size()):
		if is_instance_valid(_swarm_nameplates[i]):
			_swarm_nameplates[i].queue_free()
	for i in range(_status_icon_swarm_rows.size()):
		if is_instance_valid(_status_icon_swarm_rows[i]):
			_status_icon_swarm_rows[i].queue_free()
	_swarm_sprites.clear()
	_swarm_hp_bars.clear()
	_swarm_nameplates.clear()
	_status_icon_swarm_rows.clear()

# 必要なスロット数を確保する。slot0 は既存ノードを流用、追加分は duplicate で生成。
func _ensure_swarm_slots(n: int) -> void:
	if _swarm_sprites.is_empty():
		_swarm_sprites.append(_enemy_sprite)
		_swarm_hp_bars.append(_hp_bar_enemy)
		_swarm_nameplates.append(_enemy_nameplate)
	while _swarm_sprites.size() < n:
		var spr: AnimatedSprite2D = _enemy_sprite.duplicate()
		add_child(spr)
		var spr_ref := spr
		spr.animation_finished.connect(func():
			if spr_ref.visible and spr_ref.sprite_frames != null:
				if spr_ref.animation in ["attack", "hurt"]:
					spr_ref.play("idle"))
		var bar: ProgressBar = _hp_bar_enemy.duplicate()
		add_child(bar)
		_style_hp_bar_readable(bar, Color(0.85, 0.25, 0.25))
		var np: Label = _enemy_nameplate.duplicate()
		add_child(np)
		_style_enemy_nameplate(np)
		_swarm_sprites.append(spr)
		_swarm_hp_bars.append(bar)
		_swarm_nameplates.append(np)
	_ensure_swarm_status_icon_rows(n)

func _enemy_group_is_mixed(group: Array) -> bool:
	if group.size() < 2:
		return false
	var lead_id: String = str(group[0].id)
	for i in range(1, group.size()):
		if str(group[i].id) != lead_id:
			return true
	return false

# 群れ（または単体）の敵スプライトを横並びで表示する。ボス戦は BossSprite を使うため対象外。
func _show_enemy_swarm(enemy_ids: Array) -> void:
	_clear_swarm_slots()
	if $DungeonController.current_room_type == Enums.RoomType.BOSS:
		_enemy_sprite.visible = false
		_hp_bar_enemy.visible = false
		_enemy_nameplate.visible = false
		return
	var n: int = enemy_ids.size()
	if n <= 0:
		_hide_enemy_sprite()
		return
	_ensure_swarm_slots(n)
	# 群れは名前が密集するため小さめフォントに、単体は従来サイズ。
	var name_fs: int = 15 if n > 1 else 22
	var start_x: float = SWARM_BASE_X - float(n - 1) * SWARM_SPACING * 0.5
	for i in n:
		_style_enemy_nameplate(_swarm_nameplates[i])
		_swarm_nameplates[i].add_theme_font_size_override("font_size", name_fs)
		var spr: AnimatedSprite2D = _swarm_sprites[i]
		var id: String = str(enemy_ids[i])
		var path: String = ENEMY_SPRITE_MAP.get(id, "")
		if path.is_empty() or not ResourceLoader.exists(path):
			spr.visible = false
			continue
		var frames: SpriteFrames = load(path) as SpriteFrames
		if frames == null:
			spr.visible = false
			continue
		spr.sprite_frames = frames
		_normalize_enemy_scale(spr, frames)
		spr.position = Vector2(start_x + float(i) * SWARM_SPACING, SWARM_BASE_Y)
		spr.play("idle")
		spr.visible = true
	for j in range(n, _swarm_sprites.size()):
		_swarm_sprites[j].visible = false

# 指定スロットの HPバー＋ネームプレートをスプライト上端の上に配置
func _position_swarm_overlay(slot: int) -> void:
	if slot < 0 or slot >= _swarm_sprites.size():
		return
	var sprite: AnimatedSprite2D = _swarm_sprites[slot]
	var bar: ProgressBar = _swarm_hp_bars[slot]
	var np: Label = _swarm_nameplates[slot]
	const BAR_HALF_W: float = 36.0
	const BAR_HEIGHT: float = 10.0
	const NAME_HALF_W: float = 66.0
	const NAME_HEIGHT: float = 24.0
	const GAP_ABOVE_SPRITE: float = 12.0
	const GAP_BAR_NAME: float = 6.0
	var center: Vector2 = _sprite_visual_center(sprite)
	var cx: float = center.x
	var top_y: float = _sprite_top_y(sprite)
	var bar_ty: float = minf(center.y - 50.0, top_y - GAP_ABOVE_SPRITE - BAR_HEIGHT)
	bar.offset_left = cx - BAR_HALF_W
	bar.offset_top = bar_ty
	bar.offset_right = cx + BAR_HALF_W
	bar.offset_bottom = bar_ty + BAR_HEIGHT
	var data: Resource = $CombatController.get_enemy_data_at(slot)
	if data == null:
		np.visible = false
		return
	np.text = "Lv%d %s" % [$CombatController.enemy_level, data.display_name]
	var name_ty: float = bar_ty - GAP_BAR_NAME - NAME_HEIGHT
	np.offset_left = cx - NAME_HALF_W
	np.offset_top = name_ty
	np.offset_right = cx + NAME_HALF_W
	np.offset_bottom = name_ty + NAME_HEIGHT
	np.visible = true

func _play_enemy_animation(anim: String) -> void:
	_play_enemy_slot_animation($CombatController.active_enemy_index, anim)

# 指定スロットの敵スプライトにアニメを再生する。
func _play_enemy_slot_animation(slot: int, anim: String) -> void:
	if slot < 0 or slot >= _swarm_sprites.size():
		return
	var spr: AnimatedSprite2D = _swarm_sprites[slot]
	if spr.visible and spr.sprite_frames != null and spr.sprite_frames.has_animation(anim):
		spr.play(anim)

# 戦闘中の敵（通常は アクティブスロット、ボス部屋は BossSprite）にアニメを再生
func _play_active_enemy_animation(anim: String) -> void:
	if _boss_sprite.visible:
		_play_boss_animation(anim)
	else:
		_play_enemy_slot_animation($CombatController.active_enemy_index, anim)

# ---- CHR Sprites ----

func _show_chr_sprites() -> void:
	if OS.is_debug_build():
		var jobs: Array = GameState.party_members.map(func(m): return m.job_id if m != null else "null")
		print("[CHR] _show_chr_sprites: party=%d combatants=%d jobs=%s" % [GameState.party_members.size(), GameState.combatant_count(), str(jobs)])
	# 既存の擬似 idle tween を一旦全停止（死亡/再入室時の残留防止。生存者は下で再付与）
	for ti in _chr_idle_tweens.size():
		var old_tw = _chr_idle_tweens[ti]
		if old_tw != null and is_instance_valid(old_tw) and old_tw.is_valid():
			old_tw.kill()
		_chr_idle_tweens[ti] = null
	for i in GameState.combatant_count():
		if i >= _chr_sprites.size():
			break
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		if not $CombatController.is_member_alive(i):
			sprite.visible = false
			continue
		var member: Resource = GameState.get_combatant(i)
		var path: String = CHR_SPRITE_MAP.get(member.job_id, "")
		if path.is_empty() or not ResourceLoader.exists(path):
			sprite.visible = false
			continue
		var frames: SpriteFrames = load(path) as SpriteFrames
		if frames == null:
			sprite.visible = false
			continue
		sprite.sprite_frames = frames
		_normalize_chr_scale(sprite, frames)
		var slot: int = _formation_slot_for_combat_index(i)
		if slot < FORMATION_SLOT_POSITIONS.size():
			sprite.position = FORMATION_SLOT_POSITIONS[slot]
			sprite.z_index = 12 if slot < 2 else 10
		sprite.play("idle")
		sprite.visible = true
		_setup_chr_idle_motion(i, sprite, frames)
	_rebuild_party_cards()

# idle が1フレームのみの素材は SpriteFrames でフレーム送りできず静止する。
# その場合のみ offset を上下させる「呼吸」idle をコードで付与する（HPバー等は position 基準のため非干渉）。
func _setup_chr_idle_motion(idx: int, sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	if idx < 0 or idx >= _chr_idle_tweens.size():
		return
	var existing = _chr_idle_tweens[idx]
	if existing != null and is_instance_valid(existing) and existing.is_valid():
		existing.kill()
	_chr_idle_tweens[idx] = null
	if frames == null or frames.get_frame_count("idle") > 1:
		return
	var base_y: float = sprite.offset.y
	var sy: float = sprite.scale.y if absf(sprite.scale.y) > 0.001 else 1.0
	var bob_local: float = 6.0 / sy  # 画面上 ~6px の上下動
	var tw: Tween = create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sprite, "offset:y", base_y - bob_local, 0.85)
	tw.tween_property(sprite, "offset:y", base_y, 0.85)
	_chr_idle_tweens[idx] = tw

# バトルログ下のパーティカード列（左:アイコン80px / 右:HP・名前・職業・武器）
func _rebuild_party_cards() -> void:
	for c in _party_cards_row.get_children():
		c.queue_free()
	_party_card_hp_bars.clear()
	_party_card_hp_labels.clear()
	_party_card_roots.clear()
	for slot in PARTY_CARD_SLOT_COUNT:
		if slot < GameState.combatant_count():
			var member: Resource = GameState.get_combatant(slot)
			if member == null:
				_party_cards_row.add_child(_make_empty_party_card())
				continue
			var built: Dictionary = _make_party_card(member, slot)
			_party_cards_row.add_child(built["card"])
			_party_card_hp_bars.append(built["hp_bar"])
			_party_card_hp_labels.append(built["hp_label"])
			_party_card_roots.append(built["card"])
		else:
			_party_cards_row.add_child(_make_empty_party_card())
	_update_party_cards_hp()

func _make_party_card(member: Resource, combat_index: int) -> Dictionary:
	var card := HBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 6)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(PARTY_CARD_ICON_PX, PARTY_CARD_ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tex: Texture2D = _get_chr_icon_texture(member.job_id)
	if tex != null:
		icon.texture = tex
	card.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 1)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 4)
	var hp_bar := ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, 12)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_hp_bar_readable(hp_bar, Color(0.25, 0.82, 0.32))
	hp_row.add_child(hp_bar)
	var hp_label := Label.new()
	hp_label.custom_minimum_size = Vector2(48, 0)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_label.add_theme_font_size_override("font_size", 13)
	_style_readable_label(hp_label, UI_TEXT_PRIMARY)
	hp_row.add_child(hp_label)
	info.add_child(hp_row)
	var name_label := Label.new()
	name_label.text = member.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 16)
	_style_readable_label(name_label, UI_TEXT_PRIMARY)
	info.add_child(name_label)
	var job_label := Label.new()
	job_label.text = _get_member_job_display_name(member)
	job_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	job_label.clip_text = true
	job_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	job_label.add_theme_font_size_override("font_size", 13)
	_style_readable_label(job_label, UI_TEXT_SECONDARY)
	info.add_child(job_label)
	var weapon_label := Label.new()
	var wname: String = _get_equipped_weapon_display_name(combat_index)
	weapon_label.text = wname if not wname.is_empty() else "素手"
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	weapon_label.clip_text = true
	weapon_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	weapon_label.add_theme_font_size_override("font_size", 13)
	_style_readable_label(weapon_label, UI_TEXT_WEAPON)
	info.add_child(weapon_label)
	card.add_child(info)
	return {"card": card, "hp_bar": hp_bar, "hp_label": hp_label}

func _make_empty_party_card() -> Control:
	var card := HBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.modulate = PARTY_CARD_EMPTY_MODULATE
	card.add_theme_constant_override("separation", 6)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(PARTY_CARD_ICON_PX, PARTY_CARD_ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 1)
	for line in ["—", "—", "—", "—"]:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.55, 0.54, 0.5, 0.8))
		info.add_child(label)
	card.add_child(info)
	return card

func _get_member_job_display_name(member: Resource) -> String:
	var mods: Dictionary = JobStatCalculatorScript.get_member_modifiers(member)
	return str(mods.get("display_name", ""))

func _get_chr_icon_texture(job_id: String) -> Texture2D:
	# 専用バストアイコンを優先（無ければ全身idleフレームにフォールバック）
	var icon: Texture2D = IconPaths.get_icon_texture(job_id, "chr")
	if icon != null:
		return icon
	var path: String = CHR_SPRITE_MAP.get(job_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames == null or not frames.has_animation("idle"):
		return null
	return frames.get_frame_texture("idle", 0)

func _get_enemy_icon_texture(enemy_id: String) -> Texture2D:
	var icon: Texture2D = IconPaths.get_icon_texture(enemy_id, "enemy")
	if icon != null:
		return icon
	var path: String = ENEMY_SPRITE_MAP.get(enemy_id, "")
	if path.is_empty() and $DungeonController.current_dungeon_data != null:
		path = BOSS_SPRITE_MAP.get($DungeonController.current_dungeon_data.id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames == null or not frames.has_animation("idle"):
		return null
	return frames.get_frame_texture("idle", 0)

func _make_turn_order_frame_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.94)
	style.border_color = Color(0.95, 0.78, 0.35, 1.0) if active else Color(0.55, 0.48, 0.32, 1.0)
	style.set_border_width_all(3 if active else 2)
	style.set_corner_radius_all(8)
	style.content_margin_left = TURN_ORDER_FRAME_PAD
	style.content_margin_top = TURN_ORDER_FRAME_PAD
	style.content_margin_right = TURN_ORDER_FRAME_PAD
	style.content_margin_bottom = TURN_ORDER_FRAME_PAD
	return style

func _turn_order_cell_size() -> float:
	return TURN_ORDER_ICON_PX + TURN_ORDER_FRAME_PAD * 2.0

# ---- 行動順（CT プレビュー）表示（P3-D084 / P3-ALPHA-003 UI改善） ----

func _init_turn_order_row() -> void:
	_turn_order_row = HBoxContainer.new()
	_turn_order_row.add_theme_constant_override("separation", int(TURN_ORDER_GAP))
	_turn_order_row.visible = false
	_turn_order_row.z_index = 30
	add_child(_turn_order_row)

# CT 順アイコン列を再構築する（枠付き・大きめ表示）。
func _update_turn_order_ui(order: Array) -> void:
	if _turn_order_row == null:
		return
	for c in _turn_order_row.get_children():
		c.queue_free()
	_turn_order_items.clear()
	if not $DungeonController.is_combat_room() or order.is_empty():
		_turn_order_row.visible = false
		return
	var cell: float = _turn_order_cell_size()
	for entry: Dictionary in order:
		var holder := PanelContainer.new()
		holder.custom_minimum_size = Vector2(cell, cell)
		holder.add_theme_stylebox_override("panel", _make_turn_order_frame_style(false))
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(TURN_ORDER_ICON_PX, TURN_ORDER_ICON_PX)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var tex: Texture2D = null
		if entry["kind"] == "party":
			var m: Resource = GameState.get_combatant(entry["index"])
			if m != null:
				tex = _get_chr_icon_texture(m.job_id)
		else:
			var d: Resource = $CombatController.get_enemy_data_at(entry["index"])
			if d != null:
				tex = _get_enemy_icon_texture(d.id)
		icon.texture = tex
		icon.modulate = Color(1.0, 1.0, 1.0, 0.7)
		holder.add_child(icon)
		_turn_order_row.add_child(holder)
		_turn_order_items.append({
			"kind": entry["kind"],
			"index": entry["index"],
			"icon": icon,
			"frame": holder,
		})
	_turn_order_row.visible = true
	var n: int = order.size()
	var total_w: float = float(n) * cell + float(maxi(0, n - 1)) * TURN_ORDER_GAP
	_turn_order_row.position = Vector2(TURN_ORDER_CENTER_X - total_w * 0.5, TURN_ORDER_Y)

# 次に行動するユニットの枠を強調する。
func _set_turn_order_active(entry: Dictionary) -> void:
	for item: Dictionary in _turn_order_items:
		var icon: TextureRect = item["icon"]
		var frame: PanelContainer = item["frame"]
		var active: bool = item["kind"] == entry["kind"] and item["index"] == entry["index"]
		frame.add_theme_stylebox_override("panel", _make_turn_order_frame_style(active))
		frame.scale = Vector2(1.08, 1.08) if active else Vector2.ONE
		icon.modulate = Color(1.0, 1.0, 1.0, 1.0) if active else Color(1.0, 1.0, 1.0, 0.55)

func _clear_turn_order_ui() -> void:
	if _turn_order_row == null:
		return
	for c in _turn_order_row.get_children():
		c.queue_free()
	_turn_order_items.clear()
	_turn_order_row.visible = false

func _update_party_cards_hp() -> void:
	for i in _party_card_hp_bars.size():
		if i >= $CombatController.party_max_hp.size() or i >= $CombatController.party_combat_hp.size():
			continue
		var bar: ProgressBar = _party_card_hp_bars[i]
		bar.max_value = $CombatController.party_max_hp[i]
		bar.value = $CombatController.party_combat_hp[i]
		_party_card_hp_labels[i].text = "%d/%d" % [
			$CombatController.party_combat_hp[i], $CombatController.party_max_hp[i]
		]
		if i < _party_card_roots.size():
			var card: Control = _party_card_roots[i]
			card.modulate = Color.WHITE if $CombatController.is_member_alive(i) else PARTY_CARD_DEAD_MODULATE

func _normalize_chr_scale(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	# 実体（α非透明領域）のバウンディングボックスを CHR_BODY_TARGET_PX に揃える。
	# 足元（下端中央）をノード position に合わせる。
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var frame_w: float = tex.get_width()
	var frame_h: float = tex.get_height()
	if frame_h <= 0.0:
		return
	var body_w: float = frame_w
	var body_h: float = frame_h
	var body_cx: float = frame_w / 2.0
	var body_bottom: float = frame_h
	var img: Image = tex.get_image()
	if img != null:
		var used: Rect2i = img.get_used_rect()
		if used.size.y > 0:
			body_w = float(used.size.x)
			body_h = float(used.size.y)
			body_cx = float(used.position.x) + body_w * 0.5
			body_bottom = float(used.position.y + used.size.y)
	var body_max: float = maxf(body_w, body_h)
	var s: float = clampf(CHR_BODY_TARGET_PX / body_max, 0.05, 20.0)
	sprite.scale = Vector2(s, s)
	sprite.centered = true
	sprite.offset = Vector2(frame_w / 2.0 - body_cx, frame_h / 2.0 - body_bottom)

func _is_event_helper_combat_index(member_index: int) -> bool:
	return GameState.event_helper != null and member_index == GameState.party_members.size()

func _formation_slot_for_combat_index(combat_index: int) -> int:
	if _is_event_helper_combat_index(combat_index):
		return clampi(GameState.party_members.size(), 0, 3)
	return GameState.get_combatant_formation_slot(combat_index)

func _hide_chr_sprites() -> void:
	for i in _chr_idle_tweens.size():
		var tw = _chr_idle_tweens[i]
		if tw != null and is_instance_valid(tw) and tw.is_valid():
			tw.kill()
		_chr_idle_tweens[i] = null
	for i in _chr_skill_labels.size():
		_clear_member_skill_labels(i)
	for sprite: AnimatedSprite2D in _chr_sprites:
		sprite.visible = false

func _play_chr_attack() -> void:
	for sprite: AnimatedSprite2D in _chr_sprites:
		if sprite.visible and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("attack"):
			sprite.play("attack")

func _play_chr_hurt(member_idx: int) -> void:
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if sprite.visible and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")

# ---- VFX ----

func _play_hit_vfx(element: String = "") -> void:
	# 後方互換: 引数なし呼び出しは敵スプライト位置で発火
	if not _enemy_sprite.visible and not _boss_sprite.visible:
		return
	var enemy_pos: Vector2 = _active_enemy_pos()
	_spawn_hit_vfx(enemy_pos, element)

# 命中ごとに使い捨ての Hit VFX を生成（敵味方両対応・同一tick内の複数ヒットも個別表示）。
# 属性専用VFX(ELEMENT_VFX_PATH)があればそれを無着色で再生、無ければ
# FX_Hit_Normal を ELEMENT_COLOR でティント着色してフォールバックする。
func _spawn_hit_vfx(world_pos: Vector2, element: String = "") -> void:
	var elem_path: String = str(ELEMENT_VFX_PATH.get(element, ""))
	var use_dedicated: bool = not elem_path.is_empty() and ResourceLoader.exists(elem_path)
	var frames: SpriteFrames = null
	if use_dedicated:
		frames = load(elem_path) as SpriteFrames
	# 専用素材が無い/未インポートで読めない場合は通常VFXをティント着色してフォールバック
	if frames == null:
		use_dedicated = false
		if not ResourceLoader.exists(VFX_HIT_PATH):
			return
		frames = load(VFX_HIT_PATH) as SpriteFrames
	if frames == null:
		return
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.scale = _hit_vfx_sprite.scale
	spr.global_position = world_pos
	# 専用素材は元の色を尊重（無着色）、フォールバック時のみ属性色でティント
	spr.modulate = Color.WHITE if use_dedicated else ELEMENT_COLOR.get(element, Color.WHITE)
	add_child(spr)
	spr.play("default")
	spr.animation_finished.connect(func() -> void: spr.queue_free())

# アクセントフォントを遅延ロード（未インポートなら null のまま＝既定フォントで描画）
func _get_accent_font() -> Font:
	if _accent_font == null and ResourceLoader.exists(ACCENT_FONT_PATH):
		_accent_font = load(ACCENT_FONT_PATH) as Font
	return _accent_font

func _spawn_damage_number(text: String, world_pos: Vector2, color: Color = Color.WHITE, scale: float = 1.0) -> void:
	const DMG_FONT_SIZE: int = 40
	const DMG_OUTLINE_SIZE: int = 10
	var is_crit: bool = scale > 1.0
	var lbl := Label.new()
	lbl.text = text
	# ゲームらしい打撃感: 重厚ゴシック体＋太い黒縁＋ドロップシャドウ
	var af: Font = _get_accent_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", DMG_FONT_SIZE)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	lbl.add_theme_constant_override("outline_size", DMG_OUTLINE_SIZE)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 4)
	lbl.pivot_offset = Vector2(DMG_FONT_SIZE * 0.5, DMG_FONT_SIZE * 0.5)
	lbl.position = world_pos + Vector2(-DMG_FONT_SIZE * 0.5, -DMG_FONT_SIZE)
	var target_scale: Vector2 = Vector2(scale, scale)
	lbl.scale = target_scale * 0.35
	_damage_numbers_layer.add_child(lbl)
	var rise: float = -64.0 if is_crit else -56.0
	var tw: Tween = create_tween()
	# 出現: ポップ（オーバーシュート）
	tw.tween_property(lbl, "scale", target_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# クリティカルは回転ワブルで強調
	if is_crit:
		tw.tween_property(lbl, "rotation_degrees", -5.0, 0.05)
		tw.tween_property(lbl, "rotation_degrees", 5.0, 0.05)
		tw.tween_property(lbl, "rotation_degrees", 0.0, 0.05)
	# 上昇＋減衰（フェードは上昇に並列）
	tw.tween_property(lbl, "position:y", lbl.position.y + rise, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)

# スキル発動時、発動者(ドット絵)の頭上にスキル名をポップ表示する
func _spawn_skill_name(skill_name: String, member_idx: int, stack_offset: float = 0.0, element: String = "") -> void:
	if skill_name.is_empty():
		return
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if not sprite.visible:
		return
	const SKILL_FONT_SIZE: int = 24
	var lbl := Label.new()
	lbl.text = skill_name
	var af: Font = _get_accent_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", SKILL_FONT_SIZE)
	# 属性スキルは属性色、無属性は既定の青系で表示
	lbl.add_theme_color_override("font_color", ELEMENT_COLOR.get(element, Color(0.72, 0.93, 1.0)))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.05, 0.12, 0.95))
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	# 頭上（足元基準スプライトの上方）に中央寄せで配置
	var head_top: float = sprite.global_position.y - CHR_BODY_TARGET_PX - 40.0 + stack_offset
	var base_x: float = sprite.global_position.x - float(skill_name.length()) * SKILL_FONT_SIZE * 0.5
	lbl.pivot_offset = Vector2(float(skill_name.length()) * SKILL_FONT_SIZE * 0.5, SKILL_FONT_SIZE * 0.5)
	lbl.position = Vector2(base_x, head_top)
	# スライドイン（左から）＋ポップ
	lbl.position.x -= 18.0
	lbl.scale = Vector2(0.7, 0.7)
	lbl.modulate.a = 0.0
	_damage_numbers_layer.add_child(lbl)
	if member_idx < _chr_skill_labels.size():
		_chr_skill_labels[member_idx].append(lbl)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:x", base_x, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.12)
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "position:y", head_top - 26.0, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.35)
	tw.chain().tween_callback(func() -> void:
		if member_idx < _chr_skill_labels.size():
			_chr_skill_labels[member_idx].erase(lbl)
		lbl.queue_free()
	)

# 味方の詠唱中ポップ（P3-D112）
func _spawn_cast_chant_label(skill_name: String, member_idx: int) -> void:
	if skill_name.is_empty() or member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if not sprite.visible:
		return
	const CAST_FONT_SIZE: int = 20
	var lbl := Label.new()
	lbl.text = "◆ %s" % skill_name
	var af: Font = _get_accent_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", CAST_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.78, 0.62, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.0, 0.14, 0.95))
	lbl.add_theme_constant_override("outline_size", 6)
	var head_top: float = sprite.global_position.y - CHR_BODY_TARGET_PX - 52.0
	var base_x: float = sprite.global_position.x - float(lbl.text.length()) * CAST_FONT_SIZE * 0.28
	lbl.position = Vector2(base_x, head_top)
	lbl.modulate.a = 0.0
	_damage_numbers_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.1)
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "position:y", head_top - 20.0, 0.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.35).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)

# メンバーの表示中スキル名ラベルを即時除去（新しい tick の発動で旧ラベルを置換する）
func _clear_member_skill_labels(member_idx: int) -> void:
	if member_idx < 0 or member_idx >= _chr_skill_labels.size():
		return
	for lbl in _chr_skill_labels[member_idx]:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_chr_skill_labels[member_idx] = []

# P3-D074: 撃破→敵が消えた後にドロップ武器アイコンをポップさせ、入手アニメで吸い込む
func _spawn_weapon_drop(weapon_id: String, world_pos: Vector2) -> void:
	var tex: Texture2D = IconPaths.get_icon_texture(weapon_id, "weapon")
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.global_position = world_pos
	spr.scale = Vector2(0.1, 0.1)
	spr.z_index = 50
	add_child(spr)
	var settle_y: float = world_pos.y - 24.0
	var pickup_target: Vector2 = world_pos + Vector2(0.0, 200.0)
	var tw: Tween = create_tween()
	# 敵の死亡アニメ後に出現させるための待機
	tw.tween_interval(0.35)
	# ポップ（拡大＋上方へ放物）
	tw.tween_property(spr, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(spr, "global_position:y", world_pos.y - 56.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 着地
	tw.tween_property(spr, "global_position:y", settle_y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 入手（吸い込み＋縮小＋フェード）
	tw.tween_interval(0.2)
	tw.tween_property(spr, "global_position", pickup_target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(spr, "scale", Vector2(0.3, 0.3), 0.35)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.35)
	tw.tween_callback(spr.queue_free)

func _play_heal_vfx() -> void:
	if not ResourceLoader.exists(VFX_HEAL_PATH):
		return
	var frames: SpriteFrames = load(VFX_HEAL_PATH) as SpriteFrames
	if frames == null:
		return
	_heal_vfx_sprite.sprite_frames = frames
	_heal_vfx_sprite.play("default")
	_heal_vfx_sprite.visible = true

# ---- Boss Sprite ----

func _update_boss_sprite_visibility() -> void:
	var is_boss_room: bool = $DungeonController.current_room_type == Enums.RoomType.BOSS
	if not is_boss_room:
		_boss_sprite.visible = false
		return
	var dungeon_id: String = ""
	if $DungeonController.current_dungeon_data != null:
		dungeon_id = $DungeonController.current_dungeon_data.id
	var path: String = BOSS_SPRITE_MAP.get(dungeon_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		_boss_sprite.visible = false
		return
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames == null:
		_boss_sprite.visible = false
		return
	_boss_sprite.sprite_frames = frames
	_boss_sprite.play("idle")
	_boss_sprite.visible = true

func _play_boss_animation(anim: String) -> void:
	if not _boss_sprite.visible:
		return
	if _boss_sprite.sprite_frames != null and _boss_sprite.sprite_frames.has_animation(anim):
		_boss_sprite.play(anim)

# ---- Room Art ----

const _MG_ENV: String = "res://assets/dungeon/mourngate/env/"

func _update_room_art() -> void:
	var room_type: int = $DungeonController.current_room_type
	var dungeon_id: String = ""
	if $DungeonController.current_dungeon_data != null:
		dungeon_id = $DungeonController.current_dungeon_data.id
	var bg_path: String = BATTLE_BG_MAP.get(dungeon_id, BATTLE_BG_MAP[Constants.MOURNGATE_DUNGEON_ID])
	_set_room_texture(_room_tile_bg, bg_path)
	var obj_path: String = ""
	if room_type == Enums.RoomType.TREASURE:
		obj_path = _MG_ENV + "OBJ_TreasureChest_Open.png"
	elif room_type == Enums.RoomType.EXIT:
		obj_path = _MG_ENV + "OBJ_ExitGate_Mourngate.png"
	_set_room_texture(_room_object, obj_path)

func _set_room_texture(node: TextureRect, path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		node.texture = null
		node.visible = false
		return
	node.texture = load(path) as Texture2D
	node.visible = true
