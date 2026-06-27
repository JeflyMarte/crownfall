extends Control

const FALLBACK_ATTACK: int = 10
const CRITICAL_MULTIPLIER: float = 1.5
const HEAL_AMOUNT: int = 10
const SPEED_X1: float = 1.5
const SPEED_X2: float = 0.75
const AUTO_DELAY_X1: float = 1.2
const AUTO_DELAY_X2: float = 0.6
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
}
const STATUS_ICON_SIZE: float = 26.0
const STATUS_ICON_GAP: float = 3.0
const STATUS_ICON_Y_OFFSET: float = -74.0
const VFX_HIT_PATH: String = "res://resources/animation/FX_Hit_Normal.tres"
const VFX_HEAL_PATH: String = "res://resources/animation/FX_Heal.tres"
const SkillExecutorScript: Script = preload("res://scripts/combat/SkillExecutor.gd")
const ElementResolverScript: Script = preload("res://scripts/combat/ElementResolver.gd")
const AffixStatCalculatorScript: Script = preload("res://scripts/equipment/AffixStatCalculator.gd")
const JobStatCalculatorScript: Script = preload("res://scripts/equipment/JobStatCalculator.gd")

var _merchant_active: bool = false
var _event_active: bool = false
var _waiting_departure: bool = false
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
@onready var _merchant_container: VBoxContainer = $MainVBox/BottomZone/NonCombatZone/MerchantContainer
@onready var _event_container: VBoxContainer = $MainVBox/BottomZone/NonCombatZone/EventContainer
@onready var _btn_next_room: Button = $MainVBox/BottomZone/NonCombatZone/ButtonNextRoom
@onready var _btn_finish: Button = $MainVBox/BottomZone/NonCombatZone/ButtonFinish
@onready var _menu_overlay: PanelContainer = $MenuOverlay
@onready var _hp_bar_chr0: ProgressBar = $HpBarChr0
@onready var _hp_bar_chr1: ProgressBar = $HpBarChr1
@onready var _hp_bar_chr2: ProgressBar = $HpBarChr2
@onready var _hp_bar_chr3: ProgressBar = $HpBarChr3
@onready var _hp_bar_enemy: ProgressBar = $HpBarEnemy

var _chr_sprites: Array[AnimatedSprite2D] = []
var _chr_hp_bars: Array[ProgressBar] = []
var _status_icon_enemy: HBoxContainer
var _status_icon_chr_rows: Array[HBoxContainer] = []

func _ready() -> void:
	_btn_next_room.pressed.connect(_on_next_room_pressed)
	_btn_finish.pressed.connect(_on_finish_button_pressed)
	$CombatTimer.timeout.connect(_on_combat_timer_timeout)
	$AutoProgressTimer.timeout.connect(_on_auto_progress_timeout)
	_merchant_container.get_node("Offer0Row/ButtonBuyOffer0").pressed.connect(_on_buy_offer0_pressed)
	_merchant_container.get_node("Offer1Row/ButtonBuyOffer1").pressed.connect(_on_buy_offer1_pressed)
	_merchant_container.get_node("ButtonMerchantLeave").pressed.connect(_on_merchant_leave_pressed)
	_event_container.get_node("ButtonEventA").pressed.connect(_on_event_choice_a_pressed)
	_event_container.get_node("ButtonEventB").pressed.connect(_on_event_choice_b_pressed)
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
	while _battle_log_content.get_child_count() > _LOG_MAX:
		_battle_log_content.get_child(0).queue_free()
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
	var enemy_visible: bool = _enemy_sprite.visible or _boss_sprite.visible
	_hp_bar_enemy.visible = in_combat and enemy_visible
	if _hp_bar_enemy.visible:
		var enemy_data: Resource = $CombatController.current_enemy_data
		if enemy_data != null:
			_hp_bar_enemy.max_value = enemy_data.max_hp
			_hp_bar_enemy.value = $CombatController.current_enemy_hp
		var active_enemy: AnimatedSprite2D = _boss_sprite if _boss_sprite.visible else _enemy_sprite
		_set_hp_bar_above_sprite(_hp_bar_enemy, active_enemy)
	for i: int in _chr_hp_bars.size():
		var bar: ProgressBar = _chr_hp_bars[i]
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		bar.visible = sprite.visible and in_combat
		if bar.visible and i < $CombatController.party_combat_hp.size():
			bar.max_value = $CombatController.party_max_hp[i]
			bar.value = $CombatController.party_combat_hp[i]
			_set_hp_bar_above_sprite(bar, sprite)

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
	var active_enemy: AnimatedSprite2D = _boss_sprite if _boss_sprite.visible else _enemy_sprite
	_set_status_row_above_sprite(
		_status_icon_enemy,
		active_enemy,
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
		Enums.RoomType.MERCHANT: return "商人"
	return ""

func _update_room_label() -> void:
	if $DungeonController.current_dungeon_data == null:
		_label_room.text = "部屋 — / —"
		return
	var idx: int = $DungeonController.current_room_index + 1
	var total: int = $DungeonController.current_dungeon_data.room_count
	_label_room.text = "B1 — 部屋 %d/%d [%s]" % [idx, total, _get_room_type_name()]
	var badge_color: Color = Color.WHITE
	match $DungeonController.current_room_type:
		Enums.RoomType.ELITE: badge_color = Color(1.0, 0.7, 0.2)
		Enums.RoomType.BOSS: badge_color = Color(1.0, 0.35, 0.35)
	_label_room.add_theme_color_override("font_color", badge_color)

func _on_next_room_pressed() -> void:
	_waiting_departure = false
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
					log_text += "\n宝箱から装飾品を入手: " + treasure["accessory_id"]
					GameState.last_run_accessory_dropped = treasure["accessory_id"]
				_set_narrative(log_text)
				_start_auto_progress()
			Enums.RoomType.MERCHANT:
				_handle_merchant_room()
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

# ---- Merchant ----

func _handle_merchant_room() -> void:
	_merchant_active = true
	var offers: Array = $DungeonController.generate_merchant_offers()
	_merchant_container.get_node("LabelMerchantTitle").text = "商人が現れた  所持Gold: %d" % GameState.gold
	for i in offers.size():
		var offer: Dictionary = offers[i]
		var label_text: String = _format_merchant_offer_label(offer)
		if i == 0:
			_merchant_container.get_node("Offer0Row/LabelOffer0").text = label_text
			_merchant_container.get_node("Offer0Row/ButtonBuyOffer0").disabled = GameState.gold < offer["price"]
		elif i == 1:
			_merchant_container.get_node("Offer1Row/LabelOffer1").text = label_text
			_merchant_container.get_node("Offer1Row/ButtonBuyOffer1").disabled = GameState.gold < offer["price"]
	_merchant_container.visible = true
	_set_narrative("商人の部屋に入った")

func _on_buy_offer0_pressed() -> void:
	if $DungeonController.buy_merchant_item(0):
		var offer: Dictionary = $DungeonController.current_merchant_offers[0]
		_apply_merchant_purchase_effect(offer)
		_set_narrative("%s を購入した！  -%dG" % [offer["label"], offer["price"]])
		_merchant_container.get_node("Offer0Row/ButtonBuyOffer0").disabled = true
		_merchant_container.get_node("LabelMerchantTitle").text = "商人が現れた  所持Gold: %d" % GameState.gold
		_refresh_merchant_buttons()
	else:
		_set_narrative("Gold不足")

func _on_buy_offer1_pressed() -> void:
	if $DungeonController.buy_merchant_item(1):
		var offer: Dictionary = $DungeonController.current_merchant_offers[1]
		_apply_merchant_purchase_effect(offer)
		_set_narrative("%s を購入した！  -%dG" % [offer["label"], offer["price"]])
		_merchant_container.get_node("Offer1Row/ButtonBuyOffer1").disabled = true
		_merchant_container.get_node("LabelMerchantTitle").text = "商人が現れた  所持Gold: %d" % GameState.gold
		_refresh_merchant_buttons()
	else:
		_set_narrative("Gold不足")

func _apply_merchant_purchase_effect(offer: Dictionary) -> void:
	if offer.get("type") == "heal":
		$CombatController.heal_party(_apply_healing_bonus(offer.get("amount", 10)))
		_play_heal_vfx()
		_update_hp_bars()

func _format_merchant_offer_label(offer: Dictionary) -> String:
	if offer.get("type") == "material":
		return "%s %dG" % [offer["label"], offer["price"]]
	return "%s — %dG" % [offer["label"], offer["price"]]

func _refresh_merchant_buttons() -> void:
	var offers: Array = $DungeonController.current_merchant_offers
	for i in offers.size():
		var can_buy: bool = not offers[i].get("purchased", false) and GameState.gold >= offers[i]["price"]
		if i == 0:
			_merchant_container.get_node("Offer0Row/ButtonBuyOffer0").disabled = not can_buy
		elif i == 1:
			_merchant_container.get_node("Offer1Row/ButtonBuyOffer1").disabled = not can_buy

func _on_merchant_leave_pressed() -> void:
	_merchant_active = false
	_merchant_container.visible = false
	_waiting_departure = true
	_set_narrative("商人の部屋を後にした")
	_update_next_room_button()

# ---- Event ----

func _handle_event_room() -> void:
	var event: Dictionary = $DungeonController.pick_event()
	if event.is_empty():
		_set_narrative("イベントの部屋に入った")
		return
	_event_active = true
	var event_id: String = event.get("id", "")
	if not event_id.is_empty():
		_try_register_discovery("event", event_id)
	_set_narrative(event["description"])
	_event_container.get_node("ButtonEventA").text = event.get("choice_a", "A")
	_event_container.get_node("ButtonEventB").text = event.get("choice_b", "B")
	_event_container.visible = true

func _on_event_choice_a_pressed() -> void:
	_resolve_event_choice(0)

func _on_event_choice_b_pressed() -> void:
	_resolve_event_choice(1)

func _resolve_event_choice(choice_index: int) -> void:
	var outcome: Dictionary = $DungeonController.resolve_event(choice_index)
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
			log_text = "%s を記録した（Codexは将来実装）" % outcome.get("label", "碑文")
			_try_register_discovery("lore", lore_id)
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
	_set_narrative(log_text)
	_event_active = false
	_event_container.visible = false
	_waiting_departure = true
	_update_next_room_button()

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
		_run_party_combat_phase()
	else:
		_run_party_combat_phase()
		if $CombatController.is_enemy_defeated():
			_handle_enemy_defeated()
			return
		_run_enemy_combat_phase()
	_update_hp_bars()
	_update_status_labels()
	if $CombatController.is_party_wiped():
		_handle_party_wipe()

func _run_party_combat_phase() -> void:
	_do_party_attack()
	_try_apply_skill_status()

func _run_enemy_combat_phase() -> void:
	if $CombatController.should_enemy_skip_action():
		var skip_label: String = $CombatController.get_enemy_skip_action_label()
		if skip_label.is_empty():
			skip_label = "鈍化"
		_append_log("[%s] 敵の行動が遅れた" % skip_label)
	else:
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
	var skill_log: String = _try_cast_player_skill()
	var member_idx: int = _first_alive_member_index()
	var primary_skill: Resource = _get_player_skill_data(member_idx)
	var primary_id: String = primary_skill.id if primary_skill != null else ""
	var secondary_log: String = _try_cast_secondary_skill(primary_id)
	_update_hp_bars()
	var crit_tag: String = "  CRITICAL!" if crit_hit else ""
	_append_log("攻撃: %dダメージ%s%s%s%s" % [total_dmg, crit_tag, elem_tag, skill_log, secondary_log])
	if total_dmg > 0:
		_play_hit_vfx()
		_play_chr_attack()
		if $CombatController.current_enemy_hp > 0:
			_play_active_enemy_animation("hurt")
		var enemy_spawn_pos: Vector2 = _enemy_sprite.global_position if _enemy_sprite.visible else _boss_sprite.global_position
		_spawn_damage_number(str(total_dmg), enemy_spawn_pos, Color(1.0, 0.9, 0.0), 1.25 if crit_hit else 1.0)

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
	var elem_result: Dictionary = _apply_element_to_damage(skill_dmg, attack_element)
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
	_spawn_damage_number(str(final_dmg), skill_spawn_pos + Vector2(12.0, 0.0), Color(1.0, 0.9, 0.0), 1.25 if skill_is_crit else 1.0)
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
	var elem_result: Dictionary = _apply_element_to_damage(skill_dmg, attack_element)
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
	_spawn_damage_number(str(final_dmg), sec_spawn_pos + Vector2(-12.0, 8.0), Color(1.0, 0.9, 0.0), 1.25 if sec_is_crit else 1.0)
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

func _apply_element_to_damage(damage: int, attack_element: String) -> Dictionary:
	var element_tag: String = ""
	var enemy_data: Resource = $CombatController.current_enemy_data
	if enemy_data == null or damage <= 0:
		return {"damage": damage, "element_tag": element_tag}
	var elem_mult: float = ElementResolverScript.get_damage_multiplier(
		attack_element,
		enemy_data.element_weakness,
		enemy_data.element_resist
	)
	if elem_mult > 1.0:
		damage = maxi(1, int(float(damage) * elem_mult))
		var elem_name: String = ElementResolverScript.get_display_name(attack_element)
		if not elem_name.is_empty():
			element_tag = "  [弱点:%s]" % elem_name
	return {"damage": damage, "element_tag": element_tag}

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
	var elem_result: Dictionary = _apply_element_to_damage(damage, _get_weapon_element(member_index))
	damage = elem_result["damage"]
	damage = maxi(1, int(float(damage) * $CombatController.get_enemy_incoming_damage_multiplier()))
	return {
		"damage": damage,
		"is_critical": is_critical,
		"element_tag": elem_result["element_tag"],
	}

func _calc_enemy_damage_to_member(target_index: int) -> Dictionary:
	var base_dmg: int = $CombatController.current_enemy_data.attack
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

func _handle_enemy_defeated() -> void:
	$CombatTimer.stop()
	$CombatController.capture_rewards()
	if $CombatController.current_enemy_data != null:
		GameState.add_enemy_kill($CombatController.current_enemy_data.id)
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
	if $DungeonController.current_room_type == Enums.RoomType.ELITE:
		var elite_bonus: Dictionary = $DungeonController.apply_elite_bonus_loot()
		if not (elite_bonus["armor_id"] as String).is_empty():
			log_lines.append("エリート報酬: 防具 %s" % elite_bonus["armor_id"])
		if not (elite_bonus["accessory_id"] as String).is_empty():
			log_lines.append("エリート報酬: 装飾品 %s" % elite_bonus["accessory_id"])
			GameState.last_run_accessory_dropped = elite_bonus["accessory_id"]
		if not (elite_bonus["material_id"] as String).is_empty():
			var mat_id: String = elite_bonus["material_id"]
			var mat_amount: int = _apply_material_bonus(1)
			GameState.add_material(mat_id, mat_amount)
			log_lines.append("エリート報酬: %s" % _format_material_reward_log(mat_id, mat_amount, ""))
			_try_register_discovery("material", mat_id)
	log_lines.append("累計  EXP %d  Gold %d" % [
		$DungeonController.run_exp_reward,
		$DungeonController.run_gold_reward,
	])
	_set_narrative("\n".join(log_lines))
	_update_enemy_label()
	_update_hp_bars()
	_update_next_room_button()
	_start_auto_progress()

func _handle_party_wipe() -> void:
	$CombatTimer.stop()
	$CombatController.end_combat()
	_update_status_labels()
	_hide_enemy_sprite()
	_hide_chr_sprites()
	_merchant_active = false
	_event_active = false
	_update_combat_visibility()
	_non_combat_zone.visible = false
	_set_narrative("全員が倒れた... 探索失敗")
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
	if not $CombatController.is_in_combat or $CombatController.current_enemy_data == null:
		_label_enemy.text = ""
		_label_enemy.visible = false
		return
	_label_enemy.text = $CombatController.current_enemy_data.display_name
	_label_enemy.visible = true

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
	_btn_next_room.visible = _waiting_departure
	_btn_next_room.text = "出発"
	_update_combat_visibility()

func _update_combat_visibility() -> void:
	var in_combat: bool = $CombatController.is_in_combat
	_non_combat_zone.visible = not in_combat
	_auto_combat_row.visible = in_combat
	$MainVBox/BattleLogPanel.visible = in_combat
	_narrative_panel.visible = not in_combat
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
	_label_combat_tier.text = tier_text
	_label_combat_tier.add_theme_color_override("font_color", border_color)
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
		_advance_to_next_room()

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
	const ENEMY_DISPLAY_PX: float = 256.0
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	var h: float = tex.get_height() if tex != null else 96.0
	if h <= 0.0:
		return
	var s: float = max(1.0, ENEMY_DISPLAY_PX / h)
	sprite.scale = Vector2(s, s)

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

# 職ごとに素材セルサイズが異なる（新規 96px / 旧 32px placeholder）ため、
# 表示高さを揃える。整数倍にして拡大時のにじみを防ぐ。
func _normalize_chr_scale(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	const CHR_DISPLAY_PX: float = 192.0
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	var h: float = tex.get_height() if tex != null else 32.0
	if h <= 0.0:
		return
	var s: float = max(1.0, round(CHR_DISPLAY_PX / h))
	sprite.scale = Vector2(s, s)

func _hide_chr_sprites() -> void:
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
	if not _enemy_sprite.visible and not _boss_sprite.visible:
		return
	if not ResourceLoader.exists(VFX_HIT_PATH):
		return
	var frames: SpriteFrames = load(VFX_HIT_PATH) as SpriteFrames
	if frames == null:
		return
	_hit_vfx_sprite.sprite_frames = frames
	_hit_vfx_sprite.play("default")
	_hit_vfx_sprite.visible = true

func _spawn_damage_number(text: String, world_pos: Vector2, color: Color = Color.WHITE, scale: float = 1.0) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.position = world_pos + Vector2(-16.0, -32.0)
	if scale > 1.0:
		lbl.scale = Vector2(scale, scale)
		lbl.position -= Vector2(8.0 * (scale - 1.0), 8.0 * (scale - 1.0))
	_damage_numbers_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 56.0, 0.75)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.75)
	tw.chain().tween_callback(lbl.queue_free)

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
