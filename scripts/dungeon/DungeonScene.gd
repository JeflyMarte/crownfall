extends Control

const FALLBACK_ATTACK: int = 10
const CRITICAL_MULTIPLIER: float = 1.5
# 敵DEFの逓減軽減係数。軽減率 = K/(K+DEF)。flat減算は小ダメージ多段で0化するため割合式を採用。
const DEFENSE_MITIGATION_K: float = 100.0
const HEAL_AMOUNT: int = 10
const SPEED_X1: float = 1.5
const SPEED_X2: float = 0.75
const AUTO_DELAY_X1: float = 1.2
const AUTO_DELAY_X2: float = 0.6
# P3-D074: 味方/敵の攻撃アニメが重ならないよう、tick内の攻撃フェーズ間に挿入するディレイ（速度連動）
const ATTACK_STAGGER_X1: float = 0.4
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
	"empower": {"abbrev": "攻", "color": Color(0.95, 0.55, 0.2)},
}
const HEAL_SKILL_BASE: int = 14
const STATUS_ICON_SIZE: float = 26.0
const STATUS_ICON_GAP: float = 3.0
const STATUS_ICON_Y_OFFSET: float = -74.0
const VFX_HIT_PATH: String = "res://resources/animation/FX_Hit_Normal.tres"
const VFX_HEAL_PATH: String = "res://resources/animation/FX_Heal.tres"
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
var _status_icon_enemy: HBoxContainer
var _status_icon_chr_rows: Array[HBoxContainer] = []

func _ready() -> void:
	_btn_next_room.pressed.connect(_on_next_room_pressed)
	_btn_finish.pressed.connect(_on_finish_button_pressed)
	$CombatTimer.timeout.connect(_on_combat_timer_timeout)
	$AutoProgressTimer.timeout.connect(_on_auto_progress_timeout)
	$MainVBox/HeaderBar/ButtonMenu.pressed.connect(_on_menu_button_pressed)
	$MainVBox/HeaderBar/ButtonSpeedX1.pressed.connect(_on_speed_x1_pressed)
	$MainVBox/HeaderBar/ButtonSpeedX2.pressed.connect(_on_speed_x2_pressed)
	$MainVBox/HeaderBar/ButtonStop.pressed.connect(_on_stop_pressed)
	_menu_overlay.get_node("MenuVBox/ButtonFinishFromMenu").pressed.connect(_on_menu_finish_pressed)
	_menu_overlay.get_node("MenuVBox/ButtonCloseMenu").pressed.connect(_on_close_menu_pressed)
	$MainVBox/BottomZone/AutoCombatRow/ButtonPause.pressed.connect(_on_pause_button_pressed)
	EventBus.weapon_obtained.connect(_on_weapon_obtained)
	_hit_vfx_sprite.animation_finished.connect(func(): _hit_vfx_sprite.visible = false)
	_heal_vfx_sprite.animation_finished.connect(func(): _heal_vfx_sprite.visible = false)
	_chr_sprites = [_chr_sprite_0, _chr_sprite_1, _chr_sprite_2, _chr_sprite_3]
	_chr_hp_bars = [_hp_bar_chr0, _hp_bar_chr1, _hp_bar_chr2, _hp_bar_chr3]
	_init_status_icon_rows()
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
	GameState.last_run_accessory_dropped = ""
	_update_room_label()
	_update_room_art()
	_update_enemy_label()
	_update_hp_bars()
	_update_next_room_button()
	var dungeon_name: String = "ダンジョン"
	if $DungeonController.current_dungeon_data != null:
		dungeon_name = $DungeonController.current_dungeon_data.display_name
		_label_dungeon_name.text = dungeon_name
	_set_narrative("%s の探索を開始した" % dungeon_name)
	if not dungeon_id.is_empty():
		_try_register_discovery("dungeon", dungeon_id)
	_update_combat_visibility()
	_start_auto_progress()

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
		entry.text = "[%s] %s" % [_log_timestamp(), line]
		entry.add_theme_color_override("font_color", _log_color(line))
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

func _log_timestamp() -> String:
	return Time.get_time_string_from_system()

func _log_color(line: String) -> Color:
	if "CRITICAL" in line:
		return Color(1.0, 0.9, 0.2)
	if "敵の攻撃" in line:
		return Color(1.0, 0.55, 0.55)
	if line.begins_with("【ボス】") or line.begins_with("【エリート】") or line.begins_with("【中ボス】"):
		return Color(1.0, 0.65, 0.2)
	return Color.WHITE

func _style_hp_bars() -> void:
	var chr_style := StyleBoxFlat.new()
	chr_style.bg_color = Color(0.2, 0.8, 0.2)
	var enemy_style := StyleBoxFlat.new()
	enemy_style.bg_color = Color(0.8, 0.2, 0.2)
	for bar: ProgressBar in _chr_hp_bars:
		bar.add_theme_stylebox_override("fill", chr_style)
	_hp_bar_enemy.add_theme_stylebox_override("fill", enemy_style)

func _update_hp_bars() -> void:
	var in_combat: bool = $CombatController.is_in_combat
	var on_combat_floor: bool = $DungeonController.is_combat_room()
	var enemy_visible: bool = _enemy_sprite.visible or _boss_sprite.visible
	_hp_bar_enemy.visible = in_combat and enemy_visible
	if _hp_bar_enemy.visible:
		var enemy_data: Resource = $CombatController.current_enemy_data
		if enemy_data != null:
			_hp_bar_enemy.max_value = enemy_data.max_hp
			_hp_bar_enemy.value = $CombatController.current_enemy_hp
		var active_enemy: AnimatedSprite2D = _boss_sprite if _boss_sprite.visible else _enemy_sprite
		_set_hp_bar_above_sprite(_hp_bar_enemy, active_enemy)
		_update_enemy_nameplate(active_enemy)
	else:
		_enemy_nameplate.visible = false
	for i: int in _chr_hp_bars.size():
		var bar: ProgressBar = _chr_hp_bars[i]
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		bar.visible = sprite.visible and on_combat_floor
		if bar.visible and i < $CombatController.party_combat_hp.size():
			bar.max_value = $CombatController.party_max_hp[i]
			bar.value = $CombatController.party_combat_hp[i]
			_set_hp_bar_above_sprite(bar, sprite)
	_update_party_cards_hp()

func _set_hp_bar_above_sprite(bar: ProgressBar, sprite: AnimatedSprite2D) -> void:
	const BAR_HALF_W: float = 40.0
	const BAR_HEIGHT: float = 8.0
	const BAR_Y_OFFSET: float = -50.0
	var cx: float = sprite.position.x
	var ty: float = sprite.position.y + BAR_Y_OFFSET
	bar.offset_left = cx - BAR_HALF_W
	bar.offset_top = ty
	bar.offset_right = cx + BAR_HALF_W
	bar.offset_bottom = ty + BAR_HEIGHT

# 敵スプライト頭上（HPバーの上）に敵名を表示（モック UI_Reference_003_07 準拠）
func _update_enemy_nameplate(sprite: AnimatedSprite2D) -> void:
	var enemy_data: Resource = $CombatController.current_enemy_data
	if enemy_data == null:
		_enemy_nameplate.visible = false
		return
	const NAME_HALF_W: float = 100.0
	const NAME_HEIGHT: float = 22.0
	const NAME_Y_OFFSET: float = -74.0
	_enemy_nameplate.text = enemy_data.display_name
	var cx: float = sprite.position.x
	var ty: float = sprite.position.y + NAME_Y_OFFSET
	_enemy_nameplate.offset_left = cx - NAME_HALF_W
	_enemy_nameplate.offset_top = ty
	_enemy_nameplate.offset_right = cx + NAME_HALF_W
	_enemy_nameplate.offset_bottom = ty + NAME_HEIGHT
	_enemy_nameplate.visible = true

func _init_status_icon_rows() -> void:
	_status_icon_enemy = _make_status_icon_row()
	add_child(_status_icon_enemy)
	for _i in _chr_sprites.size():
		var row: HBoxContainer = _make_status_icon_row()
		add_child(row)
		_status_icon_chr_rows.append(row)

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
	label.add_theme_font_size_override("font_size", 12)
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

func _set_status_row_above_sprite(row: HBoxContainer, sprite: AnimatedSprite2D, statuses: Array) -> void:
	_populate_status_icon_row(row, statuses)
	var show: bool = sprite.visible and not statuses.is_empty()
	row.visible = show
	if not show:
		return
	var count: int = statuses.size()
	var total_w: float = count * STATUS_ICON_SIZE + maxf(0.0, float(count - 1)) * STATUS_ICON_GAP
	var cx: float = sprite.position.x
	row.position = Vector2(cx - total_w * 0.5, sprite.position.y + STATUS_ICON_Y_OFFSET)

func _update_status_icons() -> void:
	var in_combat: bool = $CombatController.is_in_combat
	if not in_combat:
		_status_icon_enemy.visible = false
		for row: HBoxContainer in _status_icon_chr_rows:
			row.visible = false
		return
	# ボスはドット絵が大きく状態異常アイコン（炎/感 等）が重なるため、ボス戦では敵側アイコンを非表示にする。
	if _boss_sprite.visible:
		_status_icon_enemy.visible = false
	else:
		_set_status_row_above_sprite(
			_status_icon_enemy,
			_enemy_sprite,
			$CombatController.get_enemy_status_list()
		)
	for i: int in _status_icon_chr_rows.size():
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		var statuses: Array = $CombatController.get_member_status_list(i)
		_set_status_row_above_sprite(_status_icon_chr_rows[i], sprite, statuses)

func _get_room_type_name() -> String:
	match $DungeonController.current_room_type:
		Enums.RoomType.START:    return "開始"
		Enums.RoomType.COMBAT:   return "戦闘"
		Enums.RoomType.EVENT:    return "イベント"
		Enums.RoomType.TREASURE: return "宝箱"
		Enums.RoomType.ELITE:    return "エリート"
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
		var enemy_data: Resource = $DungeonController.pick_combat_enemy_data()
		if enemy_data != null:
			$CombatController.start_combat(enemy_data)
			_skill_executor.reset()
			_is_paused = false
			$MainVBox/BottomZone/AutoCombatRow/ButtonPause.text = "一時停止"
			$MainVBox/HeaderBar/ButtonStop.text = "停止"
			$CombatTimer.start()
			_show_enemy_sprite(enemy_data.id)
			_show_chr_sprites()
			if $DungeonController.current_room_type == Enums.RoomType.ELITE:
				_append_log("【エリート】%s があらわれた" % enemy_data.display_name)
			elif $DungeonController.current_room_type == Enums.RoomType.BOSS:
				_append_log("【ボス】%s があらわれた" % enemy_data.display_name)
			else:
				_append_log("%s があらわれた" % enemy_data.display_name)
			if $CombatController.does_enemy_act_first():
				_append_log("[先制:敵]")
			else:
				_append_log("[先制:パーティ]")
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
				var log_text: String = "宝箱を発見: Gold +%d" % treasure["gold"]
				if not (treasure["accessory_id"] as String).is_empty():
					log_text += "\n宝箱から装飾品を入手: " + DataRegistry.get_accessory_name(treasure["accessory_id"])
					GameState.last_run_accessory_dropped = treasure["accessory_id"]
				_set_narrative(log_text)
				_start_auto_progress()
			Enums.RoomType.EVENT:
				_handle_event_room()
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
	_set_narrative("%s\n%s" % [event["description"], log_text])
	_start_auto_progress()

# ---- Combat timer ----

func _on_combat_timer_timeout() -> void:
	if not $CombatController.is_in_combat:
		$CombatTimer.stop()
		return
	_skill_executor.tick(Constants.COMBAT_TICK_INTERVAL)
	_process_status_ticks()
	if $CombatController.is_enemy_defeated():
		_handle_enemy_defeated()
		return
	if $CombatController.is_party_wiped():
		_handle_party_wipe()
		return
	if $CombatController.does_enemy_act_first():
		_run_enemy_combat_phase()
		if $CombatController.is_party_wiped():
			_handle_party_wipe()
			return
		await _attack_stagger_delay()
		if not _combat_still_active():
			return
		_run_party_combat_phase()
	else:
		_run_party_combat_phase()
		if $CombatController.is_enemy_defeated():
			_handle_enemy_defeated()
			return
		await _attack_stagger_delay()
		if not _combat_still_active():
			return
		_run_enemy_combat_phase()
	_update_hp_bars()
	_update_status_labels()
	if $CombatController.is_party_wiped():
		_handle_party_wipe()

# 攻撃フェーズ間ディレイ（速度連動）。味方→敵の攻撃アニメを視覚的に分離する。
func _attack_stagger_delay() -> void:
	var factor: float = $CombatTimer.wait_time / SPEED_X1
	var d: float = maxf(0.15, ATTACK_STAGGER_X1 * factor)
	await get_tree().create_timer(d).timeout

func _combat_still_active() -> bool:
	return is_inside_tree() and $CombatController.is_in_combat and not _is_paused

func _run_party_combat_phase() -> void:
	# 通常攻撃＋各メンバーの「装備スキル」発動（状態異常付与もスキル発動内で処理）。P3-D077。
	_do_party_attack()

func _run_enemy_combat_phase() -> void:
	if $CombatController.should_enemy_skip_action():
		var skip_label: String = $CombatController.get_enemy_skip_action_label()
		if skip_label.is_empty():
			skip_label = "鈍化"
		_append_log("[%s] 敵の行動が遅れた" % skip_label)
	elif not _try_enemy_skill():
		_do_enemy_attack()

func _process_status_ticks() -> void:
	for result: Dictionary in $CombatController.tick_all_statuses():
		var unit_id: String = result.get("unit_id", "")
		var dmg: int = result.get("damage", 0)
		var display_name: String = result.get("display_name", "")
		if dmg <= 0:
			continue
		if unit_id == "enemy":
			$CombatController.apply_damage_to_enemy(dmg)
			var dot_pos: Vector2 = _enemy_sprite.global_position if _enemy_sprite.visible else _boss_sprite.global_position
			_spawn_damage_number(str(dmg), dot_pos, Color(1.0, 0.6, 0.0))
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
	if not $CombatController.apply_status(
		"enemy",
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
	if not $CombatController.apply_status(
		"enemy",
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
	if $CombatController.is_enemy_defeated():
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
		if not $CombatController.apply_status("enemy", rule["status_id"], 1, 0):
			continue
		_append_log("[%s] 付与" % rule["label"])

func _do_party_attack() -> void:
	var total_dmg: int = 0
	var crit_hit: bool = false
	var elem_tag: String = ""
	for i in GameState.combatant_count():
		if not $CombatController.is_member_alive(i):
			continue
		var result: Dictionary = _calc_damage(i)
		if elem_tag.is_empty() and not result.get("element_tag", "").is_empty():
			elem_tag = result["element_tag"]
		$CombatController.apply_damage_to_enemy(result["damage"])
		total_dmg += result["damage"]
		_try_apply_affix_statuses(i)
		if result["is_critical"]:
			crit_hit = true
		if $CombatController.is_enemy_defeated():
			break
	# 各生存メンバーが「自分の装備スキル」を発動する（P3-D077）
	var skill_log: String = ""
	for i in GameState.combatant_count():
		if $CombatController.is_enemy_defeated():
			break
		if not $CombatController.is_member_alive(i):
			continue
		skill_log += _cast_member_equipped_skills(i)
	_update_hp_bars()
	var crit_tag: String = "  CRITICAL!" if crit_hit else ""
	_append_log("攻撃: %dダメージ%s%s%s" % [total_dmg, crit_tag, elem_tag, skill_log])
	if total_dmg > 0:
		_play_hit_vfx()
		_play_chr_attack()
		if $CombatController.current_enemy_hp > 0:
			_play_active_enemy_animation("hurt")
		var enemy_spawn_pos: Vector2 = _enemy_sprite.global_position if _enemy_sprite.visible else _boss_sprite.global_position
		_spawn_damage_number(str(total_dmg), enemy_spawn_pos, Color(1.0, 0.9, 0.0), 1.25 if crit_hit else 1.0)

# P3-D077: メンバーの装備スキル（最大2）を順に発動。発動した分のログ文字列を返す。
func _cast_member_equipped_skills(member_idx: int) -> String:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return ""
	var skill_ids: Array[String] = GameState.get_equipped_skill_ids(member)
	var out: String = ""
	var cast_count: int = 0
	for sid in skill_ids:
		if $CombatController.is_enemy_defeated():
			break
		var skill_data: Resource = DataRegistry.get_skill_data(sid)
		if skill_data == null:
			continue
		# cast_count=この tick で実際に発動したスキル数。スキル名ラベルの段組み offset と
		# 「この tick の最初の発動で旧 tick のラベルを消す」判定に使う（重なり防止）。
		var res: String = _execute_member_skill(member_idx, skill_data, cast_count)
		if not res.is_empty():
			cast_count += 1
		out += res
	return out

# 単一スキルの発動（ダメージ＋状態異常付与）。CDはメンバー×スキルで独立管理。
# cast_index: この tick でそのメンバーが発動した順番（0始まり）。ラベル段組みに使用。
func _execute_member_skill(member_idx: int, skill_data: Resource, cast_index: int = 0) -> String:
	if $CombatController.is_enemy_defeated():
		return ""
	match skill_data.effect_type:
		"heal":
			return _execute_member_heal(member_idx, skill_data, cast_index)
		"buff":
			return _execute_member_buff(member_idx, skill_data, cast_index)
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
	var skill_dmg: int = maxi(
		1,
		int(float(result["damage"]) * $CombatController.get_member_outgoing_damage_multiplier(member_idx))
	)
	var elem_result: Dictionary = _apply_enemy_mitigation(skill_dmg, attack_element)
	var final_dmg: int = maxi(
		1,
		int(float(elem_result["damage"]) * $CombatController.get_enemy_incoming_damage_multiplier())
	)
	$CombatController.apply_damage_to_enemy(final_dmg)
	var skill_is_crit: bool = result.get("is_critical", false)
	var spawn_pos: Vector2 = _enemy_sprite.global_position if _enemy_sprite.visible else _boss_sprite.global_position
	_spawn_hit_vfx(spawn_pos)
	_spawn_damage_number(str(final_dmg), spawn_pos + Vector2(12.0, 0.0), Color(1.0, 0.9, 0.0), 1.25 if skill_is_crit else 1.0)
	# この tick の最初の発動で旧 tick のラベルを除去し、2つ目以降は段違いに表示して重なりを防ぐ
	if cast_index == 0:
		_clear_member_skill_labels(member_idx)
	_spawn_skill_name(result["display_name"], member_idx, float(cast_index) * SKILL_LABEL_STACK_GAP)
	_apply_skill_status(member_idx, skill_data)
	var crit_tag: String = "  CRITICAL!" if skill_is_crit else ""
	return "\n【スキル】%s: %dダメージ%s%s" % [
		result["display_name"],
		final_dmg,
		crit_tag,
		elem_result["element_tag"],
	]

# スキルの状態異常付与（apply_status_id / apply_status_chance）。
func _apply_skill_status(member_idx: int, skill_data: Resource) -> void:
	if $CombatController.is_enemy_defeated():
		return
	if skill_data == null or skill_data.apply_status_id.is_empty():
		return
	if skill_data.apply_status_chance <= 0.0 or randf() > skill_data.apply_status_chance:
		return
	var base_info: Dictionary = _calc_attack_base(member_idx)
	if not $CombatController.apply_status("enemy", skill_data.apply_status_id, 1, base_info["base_damage"]):
		return
	var effect: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
	var label: String = skill_data.apply_status_id
	if effect != null:
		label = effect.display_name
	_append_log("[%s] 付与" % label)

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
	var skill_dmg: int = maxi(
		1,
		int(float(result["damage"]) * $CombatController.get_member_outgoing_damage_multiplier(member_idx))
	)
	var elem_result: Dictionary = _apply_enemy_mitigation(skill_dmg, attack_element)
	var final_dmg: int = maxi(
		1,
		int(
			float(elem_result["damage"])
			* $CombatController.get_enemy_incoming_damage_multiplier()
		)
	)
	$CombatController.apply_damage_to_enemy(final_dmg)
	var skill_is_crit: bool = result.get("is_critical", false)
	var skill_spawn_pos: Vector2 = _enemy_sprite.global_position if _enemy_sprite.visible else _boss_sprite.global_position
	_spawn_hit_vfx(skill_spawn_pos)
	_spawn_damage_number(str(final_dmg), skill_spawn_pos + Vector2(12.0, 0.0), Color(1.0, 0.9, 0.0), 1.25 if skill_is_crit else 1.0)
	_spawn_skill_name(result["display_name"], member_idx)
	var skill_crit_tag: String = "  CRITICAL!" if skill_is_crit else ""
	var weapon_name: String = _get_equipped_weapon_display_name(member_idx)
	var skill_header: String = result["display_name"]
	if not weapon_name.is_empty():
		skill_header = "%s / %s" % [weapon_name, result["display_name"]]
	return "\n【スキル】%s: %dダメージ%s%s" % [
		skill_header,
		final_dmg,
		skill_crit_tag,
		elem_result["element_tag"],
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
	var skill_dmg: int = maxi(
		1,
		int(float(result["damage"]) * $CombatController.get_member_outgoing_damage_multiplier(member_idx))
	)
	var elem_result: Dictionary = _apply_enemy_mitigation(skill_dmg, attack_element)
	var final_dmg: int = maxi(
		1,
		int(
			float(elem_result["damage"])
			* $CombatController.get_enemy_incoming_damage_multiplier()
		)
	)
	$CombatController.apply_damage_to_enemy(final_dmg)
	var sec_is_crit: bool = result.get("is_critical", false)
	var sec_spawn_pos: Vector2 = _enemy_sprite.global_position if _enemy_sprite.visible else _boss_sprite.global_position
	_spawn_hit_vfx(sec_spawn_pos)
	_spawn_damage_number(str(final_dmg), sec_spawn_pos + Vector2(-12.0, 8.0), Color(1.0, 0.9, 0.0), 1.25 if sec_is_crit else 1.0)
	_spawn_skill_name(result["display_name"], member_idx, 34.0)
	var skill_crit_tag: String = "  CRITICAL!" if sec_is_crit else ""
	return "\n【ジョブスキル】%s: %dダメージ%s%s" % [
		result["display_name"],
		final_dmg,
		skill_crit_tag,
		elem_result["element_tag"],
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
func _apply_enemy_mitigation(damage: int, attack_element: String) -> Dictionary:
	var element_tag: String = ""
	var enemy_data: Resource = $CombatController.current_enemy_data
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
	damage = _apply_enemy_defense(damage, enemy_data)
	return {"damage": damage, "element_tag": element_tag}

# 敵DEFによる逓減軽減: damage × K/(K+DEF)。最低1。
func _apply_enemy_defense(damage: int, enemy_data: Resource) -> int:
	if enemy_data == null or damage <= 0:
		return damage
	var def: int = int(enemy_data.defense)
	if def <= 0:
		return damage
	var mult: float = DEFENSE_MITIGATION_K / (DEFENSE_MITIGATION_K + float(def))
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

# 戦闘中の敵スプライト（通常 or ボス）を返す
func _active_enemy_sprite() -> AnimatedSprite2D:
	return _boss_sprite if _boss_sprite.visible else _enemy_sprite

# ボス/エリートのスキル発動を試行。発動したら true（通常攻撃をスキップ）。
func _try_enemy_skill() -> bool:
	var enemy_data: Resource = $CombatController.current_enemy_data
	if enemy_data == null or enemy_data.skill_ids.is_empty():
		return false
	if enemy_data.skill_use_chance <= 0.0 or randf() > enemy_data.skill_use_chance:
		return false
	var castable: Array = []
	for sid in enemy_data.skill_ids:
		var sd: Resource = DataRegistry.get_skill_data(str(sid))
		if sd == null:
			continue
		if _skill_executor.can_cast(sd, "enemy:%s" % sd.id):
			castable.append(sd)
	if castable.is_empty():
		return false
	var skill: Resource = castable[randi() % castable.size()]
	return _execute_enemy_skill(skill)

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
		$CombatController.apply_status("enemy", skill.apply_status_id, 1, 0)
		var eff: Resource = DataRegistry.get_status_effect(skill.apply_status_id)
		if eff != null:
			label = eff.display_name
	_append_log("敵スキル【%s】: 自身に[%s]" % [skill.display_name, label])

# 敵の攻撃スキル（全体/単体）。power_multiplier 分のダメージを対象へ。
func _execute_enemy_damage(skill: Resource) -> void:
	_play_active_enemy_animation("attack")
	_spawn_enemy_skill_name(skill.display_name)
	var targets: Array[int] = []
	if skill.target_type == "all_party":
		for i in $CombatController.party_combat_hp.size():
			if $CombatController.is_member_alive(i):
				targets.append(i)
	else:
		var t: int = $CombatController.pick_enemy_target_member_index()
		if t >= 0:
			targets.append(t)
	if targets.is_empty():
		return
	var lines: PackedStringArray = []
	for ti in targets:
		var dmg: int = _calc_enemy_damage_to_member(ti, skill.power_multiplier)["final"]
		$CombatController.apply_damage_to_member(ti, dmg)
		_play_chr_hurt(ti)
		if dmg > 0 and ti < _chr_sprites.size():
			_spawn_hit_vfx(_chr_sprites[ti].global_position)
			_spawn_damage_number(str(dmg), _chr_sprites[ti].global_position, Color(1.0, 0.35, 0.35))
		var member: Resource = GameState.get_combatant(ti)
		var mname: String = member.display_name if member != null else "?"
		if not $CombatController.is_member_alive(ti):
			if ti < _chr_sprites.size():
				_chr_sprites[ti].visible = false
			lines.append("%s に %d（撃破）" % [mname, dmg])
		else:
			lines.append("%s に %d" % [mname, dmg])
	_append_log("敵スキル【%s】\n  %s" % [skill.display_name, " / ".join(lines)])

# 敵スキル発動時、敵ドット絵の頭上にスキル名を赤系でポップ表示
func _spawn_enemy_skill_name(skill_name: String) -> void:
	if skill_name.is_empty():
		return
	var spr: AnimatedSprite2D = _active_enemy_sprite()
	if not spr.visible:
		return
	const ENEMY_SKILL_FONT_SIZE: int = 28
	var lbl := Label.new()
	lbl.text = skill_name
	lbl.add_theme_font_size_override("font_size", ENEMY_SKILL_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.4))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.position = Vector2(
		spr.global_position.x - float(skill_name.length()) * ENEMY_SKILL_FONT_SIZE * 0.5,
		spr.global_position.y - 150.0
	)
	_damage_numbers_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 26.0, 0.85)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.85).set_delay(0.45)
	tw.chain().tween_callback(lbl.queue_free)

func _do_enemy_attack() -> void:
	if $CombatController.current_enemy_data == null:
		return
	var target_idx: int = $CombatController.pick_enemy_target_member_index()
	if target_idx < 0:
		return
	_play_active_enemy_animation("attack")
	var enemy_result: Dictionary = _calc_enemy_damage_to_member(target_idx)
	$CombatController.apply_damage_to_member(target_idx, enemy_result["final"])
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
	var log_text: String
	if enemy_result["mitigated"] > 0:
		log_text = "敵の攻撃: %s%s に %dダメージ（軽減%d）" % [guard_prefix, member_name, enemy_result["final"], enemy_result["mitigated"]]
	else:
		log_text = "敵の攻撃: %s%s に %dダメージ" % [guard_prefix, member_name, enemy_result["final"]]
	if not $CombatController.is_member_alive(target_idx):
		log_text += "\n%s が倒れた！" % member_name
	_append_log(log_text)
	_try_apply_enemy_hit_status(target_idx)

func _try_apply_enemy_hit_status(target_idx: int) -> void:
	var enemy_data: Resource = $CombatController.current_enemy_data
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
	var source_atk: int = enemy_data.attack
	if not $CombatController.apply_status(unit_id, enemy_data.on_hit_status_id, 1, source_atk):
		return
	var effect: Resource = DataRegistry.get_status_effect(enemy_data.on_hit_status_id)
	var label: String = enemy_data.on_hit_status_id
	if effect != null:
		label = effect.display_name
	var hit_target: Resource = GameState.get_combatant(target_idx)
	var member_name: String = hit_target.display_name if hit_target != null else "?"
	_append_log("[%s] %s に付与" % [label, member_name])

func _calc_damage(member_index: int = -1) -> Dictionary:
	var base_info: Dictionary = _calc_attack_base(member_index)
	var is_critical: bool = randf() < base_info["crit_rate"]
	var damage: int = base_info["base_damage"]
	if is_critical:
		damage = int(damage * CRITICAL_MULTIPLIER)
	damage = int(damage * $DungeonController.run_damage_multiplier)
	damage = maxi(1, int(float(damage) * $CombatController.get_member_outgoing_damage_multiplier(member_index)))
	var elem_result: Dictionary = _apply_enemy_mitigation(damage, _get_weapon_element(member_index))
	damage = elem_result["damage"]
	damage = maxi(1, int(float(damage) * $CombatController.get_enemy_incoming_damage_multiplier()))
	return {
		"damage": damage,
		"is_critical": is_critical,
		"element_tag": elem_result["element_tag"],
	}

func _calc_enemy_damage_to_member(target_index: int, power_multiplier: float = 1.0) -> Dictionary:
	var base_dmg: int = int(float($CombatController.current_enemy_data.attack) * power_multiplier)
	base_dmg = maxi(1, int(float(base_dmg) * $CombatController.get_enemy_outgoing_damage_multiplier()))
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
	var mitigated: int = base_dmg - final_dmg
	return {"final": final_dmg, "base": base_dmg, "mitigated": mitigated}

# 敵の codex_materials を rarity 別確率で実ドロップ（P3-D067 / 図鑑↔経済の一本化）
const ECOLOGY_DROP_CHANCE: Dictionary = {0: 0.6, 1: 0.3, 2: 0.12, 3: 0.05}

func _roll_ecology_material_drops(enemy_data: Resource, log_lines: PackedStringArray) -> void:
	if enemy_data == null:
		return
	for raw_mat_id in enemy_data.codex_materials:
		var mat_id: String = str(raw_mat_id)
		if mat_id.is_empty():
			continue
		var mat_data: Resource = DataRegistry.get_material_data(mat_id)
		var rarity: int = 0 if mat_data == null else int(mat_data.rarity)
		var chance: float = float(ECOLOGY_DROP_CHANCE.get(rarity, 0.05))
		if randf() > chance:
			continue
		var amount: int = _apply_material_bonus(1)
		GameState.add_material(mat_id, amount)
		log_lines.append("採取: %s" % _format_material_reward_log(mat_id, amount, ""))
		_try_register_discovery("material", mat_id)

func _handle_enemy_defeated() -> void:
	$CombatTimer.stop()
	$CombatController.capture_rewards()
	var defeated_enemy: Resource = $CombatController.current_enemy_data
	if defeated_enemy != null:
		GameState.add_enemy_kill(defeated_enemy.id)
	var exp: int = $CombatController.last_exp_reward
	var gold: int = $CombatController.last_gold_reward
	var mult: float = $DungeonController.get_reward_multiplier()
	var final_exp: int = int(exp * mult)
	var final_gold: int = int(gold * mult)
	$DungeonController.accumulate_rewards(final_exp, final_gold)
	if $DungeonController.current_room_type == Enums.RoomType.BOSS:
		$DungeonController.update_discovery($DungeonController.DISCOVERY_BOSS_BONUS)
		_play_boss_animation("death")
	else:
		_play_enemy_animation("death")
	$CombatController.end_combat()
	_update_status_labels()
	var bonus_tag: String = " (x%.1f)" % mult if mult > 1.0 else ""
	var log_lines: PackedStringArray = [
		"撃破!  EXP +%d  Gold +%d%s" % [final_exp, final_gold, bonus_tag],
	]
	# P3-D074: 撃破時の武器直ドロップ（素材ドロップは一旦オミット）
	var dropped_weapon: String = $DungeonController.roll_kill_weapon_drop($DungeonController.current_room_type)
	if not dropped_weapon.is_empty():
		GameState.last_run_weapon_dropped = dropped_weapon
		log_lines.append("武器ドロップ: %s" % DataRegistry.get_weapon_name(dropped_weapon))
		var drop_pos: Vector2 = _enemy_sprite.global_position if _enemy_sprite.visible else _boss_sprite.global_position
		_spawn_weapon_drop(dropped_weapon, drop_pos)
	if $DungeonController.current_room_type == Enums.RoomType.ELITE:
		var elite_bonus: Dictionary = $DungeonController.apply_elite_bonus_loot()
		if not (elite_bonus["armor_id"] as String).is_empty():
			log_lines.append("エリート報酬: 防具 %s" % DataRegistry.get_armor_name(elite_bonus["armor_id"]))
		if not (elite_bonus["accessory_id"] as String).is_empty():
			log_lines.append("エリート報酬: 装飾品 %s" % DataRegistry.get_accessory_name(elite_bonus["accessory_id"]))
			GameState.last_run_accessory_dropped = elite_bonus["accessory_id"]
	log_lines.append("累計  EXP %d  Gold %d" % [
		$DungeonController.run_exp_reward,
		$DungeonController.run_gold_reward,
	])
	# 戦闘フロアでは narrative パネルを出さないため、撃破報酬はバトルログへ出す（撃破後も残す）。
	_append_log("\n".join(log_lines))
	_update_enemy_label()
	_update_hp_bars()
	_update_next_room_button()
	_start_auto_progress()

func _handle_party_wipe() -> void:
	$CombatTimer.stop()
	$CombatController.end_combat()
	_update_status_labels()
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
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	GameState.clear_event_helper()
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")

func _apply_healing_bonus(base_amount: int) -> int:
	return AffixStatCalculatorScript.apply_healing_bonus(base_amount)

func _apply_material_bonus(base_amount: int) -> int:
	return AffixStatCalculatorScript.apply_material_bonus(base_amount)

func _update_enemy_label() -> void:
	# 敵名は頭上ネームプレート(_update_enemy_nameplate)へ集約（モック準拠）。
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
	_is_paused = false
	_auto_delay = AUTO_DELAY_X1
	$CombatTimer.wait_time = SPEED_X1
	if $CombatController.is_in_combat:
		$CombatTimer.start()
	if $AutoProgressTimer.time_left > 0:
		$AutoProgressTimer.start(_auto_delay)
	$MainVBox/BottomZone/AutoCombatRow/ButtonPause.text = "一時停止"
	$MainVBox/HeaderBar/ButtonStop.text = "停止"

func _on_speed_x2_pressed() -> void:
	_is_paused = false
	_auto_delay = AUTO_DELAY_X2
	$CombatTimer.wait_time = SPEED_X2
	if $CombatController.is_in_combat:
		$CombatTimer.start()
	if $AutoProgressTimer.time_left > 0:
		$AutoProgressTimer.start(_auto_delay)
	$MainVBox/BottomZone/AutoCombatRow/ButtonPause.text = "一時停止"
	$MainVBox/HeaderBar/ButtonStop.text = "停止"

func _on_pause_button_pressed() -> void:
	_is_paused = not _is_paused
	$MainVBox/BottomZone/AutoCombatRow/ButtonPause.text = "再開" if _is_paused else "一時停止"
	$MainVBox/HeaderBar/ButtonStop.text = "再開" if _is_paused else "停止"
	if _is_paused:
		$CombatTimer.stop()
		_auto_progress_paused_remaining = $AutoProgressTimer.time_left
		$AutoProgressTimer.stop()
	else:
		if $CombatController.is_in_combat:
			$CombatTimer.start()
		if _auto_progress_paused_remaining > 0:
			$AutoProgressTimer.start(_auto_progress_paused_remaining)
			_auto_progress_paused_remaining = 0.0

func _on_stop_pressed() -> void:
	_is_paused = not _is_paused
	$MainVBox/HeaderBar/ButtonStop.text = "再開" if _is_paused else "停止"
	$MainVBox/BottomZone/AutoCombatRow/ButtonPause.text = "再開" if _is_paused else "一時停止"
	if _is_paused:
		$CombatTimer.stop()
		_auto_progress_paused_remaining = $AutoProgressTimer.time_left
		$AutoProgressTimer.stop()
	else:
		if $CombatController.is_in_combat:
			$CombatTimer.start()
		if _auto_progress_paused_remaining > 0:
			$AutoProgressTimer.start(_auto_progress_paused_remaining)
			_auto_progress_paused_remaining = 0.0

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
	const ENEMY_BODY_TARGET_PX: float = 160.0
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
	_enemy_sprite.visible = false

func _play_enemy_animation(anim: String) -> void:
	if not _enemy_sprite.visible:
		return
	if _enemy_sprite.sprite_frames != null and _enemy_sprite.sprite_frames.has_animation(anim):
		_enemy_sprite.play(anim)

# 戦闘中の敵（通常は EnemySprite、ボス部屋は BossSprite）にアニメを再生
func _play_active_enemy_animation(anim: String) -> void:
	if _boss_sprite.visible:
		_play_boss_animation(anim)
	else:
		_play_enemy_animation(anim)

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

# バトルログ下のパーティカード列（アイコン/HP/武器）を再構築（モック準拠・MP無し/CD維持）
func _rebuild_party_cards() -> void:
	for c in _party_cards_row.get_children():
		c.queue_free()
	_party_card_hp_bars.clear()
	_party_card_hp_labels.clear()
	for i in GameState.combatant_count():
		var member: Resource = GameState.get_combatant(i)
		if member == null:
			continue
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(110, 0)
		card.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var tex: Texture2D = _get_chr_icon_texture(member.job_id)
		if tex != null:
			icon.texture = tex
		card.add_child(icon)
		var name_label := Label.new()
		name_label.text = member.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)
		card.add_child(name_label)
		var hp_bar := ProgressBar.new()
		hp_bar.show_percentage = false
		hp_bar.custom_minimum_size = Vector2(0, 10)
		var hp_style := StyleBoxFlat.new()
		hp_style.bg_color = Color(0.2, 0.8, 0.2)
		hp_bar.add_theme_stylebox_override("fill", hp_style)
		card.add_child(hp_bar)
		var hp_label := Label.new()
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 11)
		card.add_child(hp_label)
		var weapon_label := Label.new()
		var wname: String = _get_equipped_weapon_display_name(i)
		weapon_label.text = wname if not wname.is_empty() else "素手"
		weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		weapon_label.add_theme_font_size_override("font_size", 10)
		weapon_label.add_theme_color_override("font_color", Color(0.83, 0.79, 0.72))
		card.add_child(weapon_label)
		_party_cards_row.add_child(card)
		_party_card_hp_bars.append(hp_bar)
		_party_card_hp_labels.append(hp_label)
	_update_party_cards_hp()

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

func _normalize_chr_scale(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	# 素材ごとに透明余白の割合が異なるため、フレーム高ではなく
	# 実体（α非透明領域）の高さを基準に float スケールで「見える体格」を統一する。
	# さらに実体の下端中央をノード位置へ合わせて足元を揃える（余白差による浮き/横ズレ解消）。
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var frame_w: float = tex.get_width()
	var frame_h: float = tex.get_height()
	if frame_h <= 0.0:
		return
	var body_h: float = frame_h
	var body_cx: float = frame_w / 2.0
	var body_bottom: float = frame_h
	var img: Image = tex.get_image()
	if img != null:
		var used: Rect2i = img.get_used_rect()
		if used.size.y > 0:
			body_h = float(used.size.y)
			body_cx = float(used.position.x) + float(used.size.x) / 2.0
			body_bottom = float(used.position.y + used.size.y)
	var s: float = clampf(CHR_BODY_TARGET_PX / body_h, 0.05, 20.0)
	sprite.scale = Vector2(s, s)
	sprite.centered = true
	sprite.offset = Vector2(frame_w / 2.0 - body_cx, frame_h / 2.0 - body_bottom)

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

func _play_hit_vfx() -> void:
	# 後方互換: 引数なし呼び出しは敵スプライト位置で発火
	if not _enemy_sprite.visible and not _boss_sprite.visible:
		return
	var enemy_pos: Vector2 = _enemy_sprite.global_position if _enemy_sprite.visible else _boss_sprite.global_position
	_spawn_hit_vfx(enemy_pos)

# 命中ごとに使い捨ての Hit VFX を生成（敵味方両対応・同一tick内の複数ヒットも個別表示）
func _spawn_hit_vfx(world_pos: Vector2) -> void:
	if not ResourceLoader.exists(VFX_HIT_PATH):
		return
	var frames: SpriteFrames = load(VFX_HIT_PATH) as SpriteFrames
	if frames == null:
		return
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.scale = _hit_vfx_sprite.scale
	spr.global_position = world_pos
	add_child(spr)
	spr.play("default")
	spr.animation_finished.connect(func() -> void: spr.queue_free())

func _spawn_damage_number(text: String, world_pos: Vector2, color: Color = Color.WHITE, scale: float = 1.0) -> void:
	const DMG_FONT_SIZE: int = 42
	const DMG_OUTLINE_SIZE: int = 8
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", DMG_FONT_SIZE)
	# 背景に紛れないよう黒縁取りで視認性を確保
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	lbl.add_theme_constant_override("outline_size", DMG_OUTLINE_SIZE)
	lbl.position = world_pos + Vector2(-DMG_FONT_SIZE * 0.5, -DMG_FONT_SIZE)
	if scale > 1.0:
		lbl.scale = Vector2(scale, scale)
		lbl.position -= Vector2(DMG_FONT_SIZE * 0.5 * (scale - 1.0), DMG_FONT_SIZE * 0.5 * (scale - 1.0))
	_damage_numbers_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 56.0, 0.75)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.75)
	tw.chain().tween_callback(lbl.queue_free)

# スキル発動時、発動者(ドット絵)の頭上にスキル名をポップ表示する
func _spawn_skill_name(skill_name: String, member_idx: int, stack_offset: float = 0.0) -> void:
	if skill_name.is_empty():
		return
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if not sprite.visible:
		return
	const SKILL_FONT_SIZE: int = 26
	var lbl := Label.new()
	lbl.text = skill_name
	lbl.add_theme_font_size_override("font_size", SKILL_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.92, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	lbl.add_theme_constant_override("outline_size", 6)
	# 頭上（足元基準スプライトの上方）に中央寄せで配置
	var head_top: float = sprite.global_position.y - CHR_BODY_TARGET_PX - 40.0 + stack_offset
	lbl.position = Vector2(
		sprite.global_position.x - float(skill_name.length()) * SKILL_FONT_SIZE * 0.5,
		head_top
	)
	_damage_numbers_layer.add_child(lbl)
	if member_idx < _chr_skill_labels.size():
		_chr_skill_labels[member_idx].append(lbl)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 26.0, 0.85)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.85).set_delay(0.45)
	tw.chain().tween_callback(func() -> void:
		if member_idx < _chr_skill_labels.size():
			_chr_skill_labels[member_idx].erase(lbl)
		lbl.queue_free()
	)

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
