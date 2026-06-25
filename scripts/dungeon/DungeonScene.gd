extends Control

const FALLBACK_ATTACK: int = 10
const CRITICAL_MULTIPLIER: float = 1.5
const HEAL_AMOUNT: int = 10

const ENEMY_SPRITE_MAP: Dictionary = {
	"fallen_soldier": "res://resources/animation/ENM_FallenSoldier.tres",
	"ruined_guard": "res://resources/animation/ENM_RuinedGuard.tres",
	"ruins_looter": "res://resources/animation/ENM_RuinsLooter.tres",
	"rusted_knight": "res://resources/animation/ENM_RustedKnight.tres",
	"bone_walker": "res://resources/animation/ENM_BoneWalker.tres",
	"grave_bat": "res://resources/animation/ENM_GraveBat.tres",
	"hollow_gravedigger": "res://resources/animation/ENM_HollowGravedigger.tres",
	"pale_hound": "res://resources/animation/ENM_PaleHound.tres",
	"ossuary_knight": "res://resources/animation/ENM_OssuaryKnight.tres",
}
const BOSS_SPRITE_MAP: Dictionary = {
	"royal_ruins": "res://resources/animation/BossRoyalGuardCaptain.tres",
	"graveyard": "res://resources/animation/BOSS_Gravekeeper.tres",
}
const CHR_SPRITE_MAP: Dictionary = {
	"warrior": "res://resources/animation/CHR_Warrior.tres",
	"guardian": "res://resources/animation/CHR_Guardian.tres",
	"scout": "res://resources/animation/CHR_Scout.tres",
}
const VFX_HIT_PATH: String = "res://resources/animation/FX_Hit_Normal.tres"
const VFX_HEAL_PATH: String = "res://resources/animation/FX_Heal.tres"
const SkillExecutorScript: Script = preload("res://scripts/combat/SkillExecutor.gd")
const AffixStatCalculatorScript: Script = preload("res://scripts/equipment/AffixStatCalculator.gd")
const JobStatCalculatorScript: Script = preload("res://scripts/equipment/JobStatCalculator.gd")

var _merchant_active: bool = false
var _event_active: bool = false
var _skill_executor: RefCounted = SkillExecutorScript.new()

@onready var _boss_sprite: AnimatedSprite2D = $BossSprite
@onready var _enemy_sprite: AnimatedSprite2D = $EnemySprite
@onready var _hit_vfx_sprite: AnimatedSprite2D = $HitVfxSprite
@onready var _heal_vfx_sprite: AnimatedSprite2D = $HealVfxSprite
@onready var _chr_sprite_0: AnimatedSprite2D = $ChrSprite0
@onready var _chr_sprite_1: AnimatedSprite2D = $ChrSprite1
@onready var _chr_sprite_2: AnimatedSprite2D = $ChrSprite2

@onready var _label_log: Label = $MainVBox/BattleLogScroll/LabelLog
@onready var _label_dungeon_name: Label = $MainVBox/HeaderBar/LabelDungeonName
@onready var _label_room: Label = $MainVBox/HeaderBar/LabelRoom
@onready var _room_tile_bg: TextureRect = $MainVBox/BattlefieldArea/RoomTileBg
@onready var _room_object: TextureRect = $MainVBox/BattlefieldArea/RoomObject
@onready var _auto_combat_row: HBoxContainer = $MainVBox/BottomZone/AutoCombatRow
@onready var _non_combat_zone: VBoxContainer = $MainVBox/BottomZone/NonCombatZone
@onready var _branch_container: HBoxContainer = $MainVBox/BottomZone/NonCombatZone/BranchContainer
@onready var _merchant_container: VBoxContainer = $MainVBox/BottomZone/NonCombatZone/MerchantContainer
@onready var _event_container: VBoxContainer = $MainVBox/BottomZone/NonCombatZone/EventContainer
@onready var _btn_next_room: Button = $MainVBox/BottomZone/NonCombatZone/ButtonNextRoom
@onready var _btn_finish: Button = $MainVBox/BottomZone/NonCombatZone/ButtonFinish
@onready var _menu_overlay: PanelContainer = $MenuOverlay

var _chr_sprites: Array[AnimatedSprite2D] = []

func _ready() -> void:
	_btn_next_room.pressed.connect(_on_next_room_pressed)
	_btn_finish.pressed.connect(_on_finish_button_pressed)
	$CombatTimer.timeout.connect(_on_combat_timer_timeout)
	_branch_container.get_node("ButtonBranchSafe").pressed.connect(_on_branch_safe_pressed)
	_branch_container.get_node("ButtonBranchDangerous").pressed.connect(_on_branch_dangerous_pressed)
	_branch_container.get_node("ButtonBranchUnknown").pressed.connect(_on_branch_unknown_pressed)
	_merchant_container.get_node("Offer0Row/ButtonBuyOffer0").pressed.connect(_on_buy_offer0_pressed)
	_merchant_container.get_node("Offer1Row/ButtonBuyOffer1").pressed.connect(_on_buy_offer1_pressed)
	_merchant_container.get_node("ButtonMerchantLeave").pressed.connect(_on_merchant_leave_pressed)
	_event_container.get_node("ButtonEventA").pressed.connect(_on_event_choice_a_pressed)
	_event_container.get_node("ButtonEventB").pressed.connect(_on_event_choice_b_pressed)
	$MainVBox/HeaderBar/ButtonMenu.pressed.connect(_on_menu_button_pressed)
	_menu_overlay.get_node("MenuVBox/ButtonFinishFromMenu").pressed.connect(_on_menu_finish_pressed)
	_menu_overlay.get_node("MenuVBox/ButtonCloseMenu").pressed.connect(_on_close_menu_pressed)
	$MainVBox/BottomZone/AutoCombatRow/ButtonPause.pressed.connect(_on_pause_button_pressed)
	EventBus.weapon_obtained.connect(_on_weapon_obtained)
	_hit_vfx_sprite.animation_finished.connect(func(): _hit_vfx_sprite.visible = false)
	_heal_vfx_sprite.animation_finished.connect(func(): _heal_vfx_sprite.visible = false)
	_chr_sprites = [_chr_sprite_0, _chr_sprite_1, _chr_sprite_2]
	for sprite: AnimatedSprite2D in _chr_sprites:
		sprite.animation_finished.connect(func():
			if sprite.visible and sprite.sprite_frames != null:
				if sprite.animation in ["attack", "hurt"]:
					sprite.play("idle")
		)
	var dungeon_id: String = GameState.get_active_dungeon_id()
	$DungeonController.start_dungeon(dungeon_id)
	GameState.last_run_accessory_dropped = ""
	_update_room_label()
	_update_room_art()
	_update_enemy_label()
	_update_enemy_hp_label()
	_update_party_hp_label()
	_update_next_room_button()
	var dungeon_name: String = "ダンジョン"
	if $DungeonController.current_dungeon_data != null:
		dungeon_name = $DungeonController.current_dungeon_data.display_name
		_label_dungeon_name.text = dungeon_name
	_label_log.text = "%s の探索を開始した" % dungeon_name
	if not dungeon_id.is_empty():
		_try_register_discovery("dungeon", dungeon_id)

func _get_room_type_name() -> String:
	match $DungeonController.current_room_type:
		Enums.RoomType.START:    return "開始"
		Enums.RoomType.COMBAT:   return "戦闘"
		Enums.RoomType.EVENT:    return "イベント"
		Enums.RoomType.TREASURE: return "宝箱"
		Enums.RoomType.ELITE:    return "エリート"
		Enums.RoomType.MID_BOSS: return "中ボス"
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
	_label_room.text = "部屋 %d / %d  [%s]" % [idx, total, _get_room_type_name()]

func _on_next_room_pressed() -> void:
	_advance_to_next_room()

func _on_branch_safe_pressed() -> void:
	$DungeonController.set_branch_choice(0)
	_advance_to_next_room()

func _on_branch_dangerous_pressed() -> void:
	$DungeonController.set_branch_choice(1)
	_advance_to_next_room()

func _on_branch_unknown_pressed() -> void:
	$DungeonController.set_branch_choice(2)
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
			$CombatTimer.start()
			_show_enemy_sprite(enemy_data.id)
			_show_chr_sprites()
			if $DungeonController.current_room_type == Enums.RoomType.ELITE:
				_label_log.text = "【エリート】%s があらわれた" % enemy_data.display_name
			elif $DungeonController.current_room_type == Enums.RoomType.BOSS:
				_label_log.text = "【ボス】%s があらわれた" % enemy_data.display_name
			elif $DungeonController.current_room_type == Enums.RoomType.MID_BOSS:
				_label_log.text = "【中ボス】%s があらわれた" % enemy_data.display_name
			else:
				_label_log.text = "%s があらわれた" % enemy_data.display_name
		else:
			_label_log.text = "敵が現れなかった"
			_hide_enemy_sprite()
			_hide_chr_sprites()
	else:
		_hide_enemy_sprite()
		_hide_chr_sprites()
		match $DungeonController.current_room_type:
			Enums.RoomType.HEAL:
				var heal_amount: int = _apply_healing_bonus(HEAL_AMOUNT)
				$CombatController.heal_party(heal_amount)
				_play_heal_vfx()
				_label_log.text = "回復の部屋: 生存メンバーを%d回復" % heal_amount
			Enums.RoomType.TREASURE:
				var treasure: Dictionary = $DungeonController.generate_treasure_loot()
				var log_text: String = "宝箱を発見: Gold +%d" % treasure["gold"]
				if not (treasure["accessory_id"] as String).is_empty():
					log_text += "\n宝箱から装飾品を入手: " + treasure["accessory_id"]
					GameState.last_run_accessory_dropped = treasure["accessory_id"]
				_label_log.text = log_text
			Enums.RoomType.MERCHANT:
				_handle_merchant_room()
			Enums.RoomType.EVENT:
				_handle_event_room()
			_:
				_label_log.text = _get_room_type_name() + "の部屋に入った"
	_update_enemy_label()
	_update_enemy_hp_label()
	_update_party_hp_label()
	_update_next_room_button()
	_register_discoveries_for_room()

func _on_weapon_obtained(weapon_id: String) -> void:
	_try_register_discovery("weapon", weapon_id)

func _try_register_discovery(category: String, entry_id: String) -> void:
	if DiscoveryRegistry.register(category, entry_id):
		_append_discovery_log(category, entry_id)

func _append_discovery_log(category: String, entry_id: String) -> void:
	_label_log.text += "\n" + DiscoveryRegistry.format_new_discovery(category, entry_id)

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
	_label_log.text = "商人の部屋に入った"

func _on_buy_offer0_pressed() -> void:
	if $DungeonController.buy_merchant_item(0):
		var offer: Dictionary = $DungeonController.current_merchant_offers[0]
		_apply_merchant_purchase_effect(offer)
		_label_log.text = "%s を購入した！  -%dG" % [offer["label"], offer["price"]]
		_merchant_container.get_node("Offer0Row/ButtonBuyOffer0").disabled = true
		_merchant_container.get_node("LabelMerchantTitle").text = "商人が現れた  所持Gold: %d" % GameState.gold
		_refresh_merchant_buttons()
	else:
		_label_log.text = "Gold不足"

func _on_buy_offer1_pressed() -> void:
	if $DungeonController.buy_merchant_item(1):
		var offer: Dictionary = $DungeonController.current_merchant_offers[1]
		_apply_merchant_purchase_effect(offer)
		_label_log.text = "%s を購入した！  -%dG" % [offer["label"], offer["price"]]
		_merchant_container.get_node("Offer1Row/ButtonBuyOffer1").disabled = true
		_merchant_container.get_node("LabelMerchantTitle").text = "商人が現れた  所持Gold: %d" % GameState.gold
		_refresh_merchant_buttons()
	else:
		_label_log.text = "Gold不足"

func _apply_merchant_purchase_effect(offer: Dictionary) -> void:
	if offer.get("type") == "heal":
		$CombatController.heal_party(_apply_healing_bonus(offer.get("amount", 10)))
		_play_heal_vfx()
		_update_party_hp_label()

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
	_label_log.text = "商人の部屋を後にした"
	_update_next_room_button()

# ---- Event ----

func _handle_event_room() -> void:
	var event: Dictionary = $DungeonController.pick_event()
	if event.is_empty():
		_label_log.text = "イベントの部屋に入った"
		return
	_event_active = true
	var event_id: String = event.get("id", "")
	if not event_id.is_empty():
		_try_register_discovery("event", event_id)
	_event_container.get_node("LabelEventDesc").text = event["description"]
	_event_container.get_node("ButtonEventA").text = event.get("choice_a", "A")
	_event_container.get_node("ButtonEventB").text = event.get("choice_b", "B")
	_event_container.visible = true
	_label_log.text = "イベントの部屋に入った"

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
			_update_party_hp_label()
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
		_:
			log_text = "何も起こらなかった"
	_label_log.text = log_text
	_event_active = false
	_event_container.visible = false
	_update_next_room_button()

# ---- Combat timer ----

func _on_combat_timer_timeout() -> void:
	if not $CombatController.is_in_combat:
		$CombatTimer.stop()
		return
	_skill_executor.tick(Constants.COMBAT_TICK_INTERVAL)
	_do_party_attack()
	if $CombatController.is_enemy_defeated():
		_handle_enemy_defeated()
		return
	_do_enemy_attack()
	_update_party_hp_label()
	if $CombatController.is_party_wiped():
		_handle_party_wipe()

func _do_party_attack() -> void:
	var total_dmg: int = 0
	var crit_hit: bool = false
	for i in GameState.party_members.size():
		if not $CombatController.is_member_alive(i):
			continue
		var result: Dictionary = _calc_damage(i)
		$CombatController.apply_damage_to_enemy(result["damage"])
		total_dmg += result["damage"]
		if result["is_critical"]:
			crit_hit = true
		if $CombatController.is_enemy_defeated():
			break
	var skill_log: String = _try_cast_player_skill()
	var primary_skill: Resource = _get_player_skill_data()
	var primary_id: String = primary_skill.id if primary_skill != null else ""
	var secondary_log: String = _try_cast_secondary_skill(primary_id)
	_update_enemy_hp_label()
	var crit_tag: String = "  CRITICAL!" if crit_hit else ""
	_label_log.text = "攻撃: %dダメージ%s%s%s" % [total_dmg, crit_tag, skill_log, secondary_log]
	if total_dmg > 0:
		_play_hit_vfx()
		_play_chr_attack()

func _get_player_skill_data() -> Resource:
	var skill_id: String = Constants.DEFAULT_PLAYER_SKILL_ID
	var weapon: Resource = GameState.equipped_weapon
	if weapon != null and not weapon.weapon_id.is_empty():
		var weapon_data: Resource = DataRegistry.get_weapon_data(weapon.weapon_id)
		if weapon_data != null and not weapon_data.fixed_skill_id.is_empty():
			skill_id = weapon_data.fixed_skill_id
	var skill_data: Resource = DataRegistry.get_skill_data(skill_id)
	if skill_data != null:
		return skill_data
	return DataRegistry.get_skill_data(Constants.DEFAULT_PLAYER_SKILL_ID)

func _get_equipped_weapon_display_name() -> String:
	var weapon: Resource = GameState.equipped_weapon
	if weapon == null or weapon.weapon_id.is_empty():
		return ""
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon.weapon_id)
	if weapon_data == null or weapon_data.display_name.is_empty():
		return weapon.weapon_id
	return weapon_data.display_name

func _try_cast_player_skill() -> String:
	if $CombatController.is_enemy_defeated():
		return ""
	var skill_data: Resource = _get_player_skill_data()
	if skill_data == null:
		return ""
	var member_idx: int = _first_alive_member_index()
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
	$CombatController.apply_damage_to_enemy(result["damage"])
	var skill_crit_tag: String = "  CRITICAL!" if result.get("is_critical", false) else ""
	var weapon_name: String = _get_equipped_weapon_display_name()
	var skill_header: String = result["display_name"]
	if not weapon_name.is_empty():
		skill_header = "%s / %s" % [weapon_name, result["display_name"]]
	return "\n【スキル】%s: %dダメージ%s" % [
		skill_header,
		result["damage"],
		skill_crit_tag,
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
	$CombatController.apply_damage_to_enemy(result["damage"])
	var skill_crit_tag: String = "  CRITICAL!" if result.get("is_critical", false) else ""
	return "\n【ジョブスキル】%s: %dダメージ%s" % [
		result["display_name"],
		result["damage"],
		skill_crit_tag,
	]

func _calc_attack_base(member_index: int = -1) -> Dictionary:
	var damage: int = FALLBACK_ATTACK
	var crit_rate: float = 0.0
	var weapon: Resource = GameState.equipped_weapon
	if weapon != null:
		damage = weapon.rolled_attack
		crit_rate = weapon.critical_rate
	var acc: Resource = GameState.equipped_accessory
	if acc != null:
		var acc_data: Resource = load("res://resources/accessories/" + acc.accessory_id + ".tres")
		if acc_data != null:
			damage += acc_data.attack_bonus
			crit_rate += acc_data.crit_rate_bonus
	var affix_bonuses: Dictionary = AffixStatCalculatorScript.get_bonuses()
	damage += int(affix_bonuses.get("attack_flat", 0))
	crit_rate += float(affix_bonuses.get("crit_rate_add", 0.0))
	damage = _apply_job_attack_multiplier(damage, member_index)
	return {"base_damage": damage, "crit_rate": crit_rate}

func _apply_job_attack_multiplier(base_damage: int, member_index: int) -> int:
	if base_damage <= 0 or member_index < 0 or member_index >= GameState.party_members.size():
		return base_damage
	var member: Resource = GameState.party_members[member_index]
	var job_mods: Dictionary = JobStatCalculatorScript.get_member_modifiers(member)
	var atk_mult: float = float(job_mods.get("attack_multiplier", JobStatCalculator.DEFAULT_MULTIPLIER))
	return maxi(0, int(round(float(base_damage) * atk_mult)))

func _first_alive_member_index() -> int:
	for i in GameState.party_members.size():
		if $CombatController.is_member_alive(i):
			return i
	return -1

func _do_enemy_attack() -> void:
	if $CombatController.current_enemy_data == null:
		return
	var alive: Array[int] = []
	for i in $CombatController.party_combat_hp.size():
		if $CombatController.is_member_alive(i):
			alive.append(i)
	if alive.is_empty():
		return
	var target_idx: int = alive[randi() % alive.size()]
	var enemy_result: Dictionary = _calc_enemy_damage_to_member(target_idx)
	$CombatController.apply_damage_to_member(target_idx, enemy_result["final"])
	_play_chr_hurt(target_idx)
	if not $CombatController.is_member_alive(target_idx) and target_idx < _chr_sprites.size():
		_chr_sprites[target_idx].visible = false
	var member_name: String = GameState.party_members[target_idx].display_name
	var log_text: String
	if enemy_result["mitigated"] > 0:
		log_text = "敵の攻撃: %s に %dダメージ（軽減%d）" % [member_name, enemy_result["final"], enemy_result["mitigated"]]
	else:
		log_text = "敵の攻撃: %s に %dダメージ" % [member_name, enemy_result["final"]]
	if not $CombatController.is_member_alive(target_idx):
		log_text += "\n%s が倒れた！" % member_name
	_label_log.text = log_text

func _calc_damage(member_index: int = -1) -> Dictionary:
	var base_info: Dictionary = _calc_attack_base(member_index)
	var is_critical: bool = randf() < base_info["crit_rate"]
	var damage: int = base_info["base_damage"]
	if is_critical:
		damage = int(damage * CRITICAL_MULTIPLIER)
	damage = int(damage * $DungeonController.run_damage_multiplier)
	return {"damage": damage, "is_critical": is_critical}

func _calc_enemy_damage_to_member(target_index: int) -> Dictionary:
	var base_dmg: int = $CombatController.current_enemy_data.attack
	var defense: int = 0
	var armor: Resource = GameState.equipped_armor
	if armor != null:
		defense = armor.rolled_defense
	var acc: Resource = GameState.equipped_accessory
	if acc != null:
		var acc_data: Resource = load("res://resources/accessories/" + acc.accessory_id + ".tres")
		if acc_data != null:
			defense += acc_data.defense_bonus
	defense += int(AffixStatCalculatorScript.get_bonuses().get("defense_flat", 0))
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
	_label_log.text = "\n".join(log_lines)
	_update_enemy_label()
	_update_enemy_hp_label()
	_update_next_room_button()

func _handle_party_wipe() -> void:
	$CombatTimer.stop()
	$CombatController.end_combat()
	_hide_enemy_sprite()
	_hide_chr_sprites()
	_merchant_active = false
	_event_active = false
	_non_combat_zone.visible = false
	_auto_combat_row.visible = false
	_label_log.text = "全員が倒れた... 探索失敗"
	GameState.last_run_exp_reward = $DungeonController.run_exp_reward
	GameState.last_run_gold_reward = $DungeonController.run_gold_reward
	GameState.last_run_weapon_dropped = ""
	GameState.last_run_armor_dropped = ""
	GameState.last_run_accessory_dropped = ""
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")

func _apply_healing_bonus(base_amount: int) -> int:
	return AffixStatCalculatorScript.apply_healing_bonus(base_amount)

func _apply_material_bonus(base_amount: int) -> int:
	return AffixStatCalculatorScript.apply_material_bonus(base_amount)

# HP labels removed in v2 — overhead HP bars are P3-UI-002
func _update_enemy_label() -> void:
	pass

func _update_enemy_hp_label() -> void:
	pass

func _update_party_hp_label() -> void:
	pass

func _update_branch_ui() -> void:
	if _merchant_active or _event_active:
		_branch_container.visible = false
		_btn_next_room.visible = false
		return
	var show_branch: bool = $DungeonController.is_branch_choice_phase()
	_branch_container.visible = show_branch
	_btn_next_room.visible = not show_branch
	if show_branch:
		var blocked: bool = $DungeonController.is_completed or $CombatController.is_in_combat
		_branch_container.get_node("ButtonBranchSafe").disabled = blocked
		_branch_container.get_node("ButtonBranchDangerous").disabled = blocked
		_branch_container.get_node("ButtonBranchUnknown").disabled = blocked

func _update_next_room_button() -> void:
	var at_exit: bool = $DungeonController.current_room_type == Enums.RoomType.EXIT
	var blocked: bool = $DungeonController.is_completed or $CombatController.is_in_combat or at_exit
	_btn_next_room.disabled = blocked
	_update_branch_ui()
	_update_combat_visibility()

func _update_combat_visibility() -> void:
	var in_combat: bool = $CombatController.is_in_combat
	_non_combat_zone.visible = not in_combat
	_auto_combat_row.visible = in_combat

func _on_finish_button_pressed() -> void:
	_btn_finish.disabled = true
	$CombatTimer.stop()
	$CombatController.end_combat()
	$DungeonController.generate_run_loot()
	GameState.last_run_exp_reward = $DungeonController.run_exp_reward
	GameState.last_run_gold_reward = $DungeonController.run_gold_reward
	GameState.last_run_weapon_dropped = $DungeonController.last_weapon_dropped
	GameState.last_run_armor_dropped = $DungeonController.last_armor_dropped
	if not $DungeonController.last_accessory_dropped.is_empty():
		GameState.last_run_accessory_dropped = $DungeonController.last_accessory_dropped
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")

# ---- Menu Overlay ----

func _on_menu_button_pressed() -> void:
	_menu_overlay.visible = true

func _on_close_menu_pressed() -> void:
	_menu_overlay.visible = false

func _on_menu_finish_pressed() -> void:
	_menu_overlay.visible = false
	_on_finish_button_pressed()

func _on_pause_button_pressed() -> void:
	pass

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
	_enemy_sprite.play("idle")
	_enemy_sprite.visible = true

func _hide_enemy_sprite() -> void:
	_enemy_sprite.visible = false

func _play_enemy_animation(anim: String) -> void:
	if not _enemy_sprite.visible:
		return
	if _enemy_sprite.sprite_frames != null and _enemy_sprite.sprite_frames.has_animation(anim):
		_enemy_sprite.play(anim)

# ---- CHR Sprites ----

func _show_chr_sprites() -> void:
	for i in GameState.party_members.size():
		if i >= _chr_sprites.size():
			break
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		if not $CombatController.is_member_alive(i):
			sprite.visible = false
			continue
		var member: Resource = GameState.party_members[i]
		var path: String = CHR_SPRITE_MAP.get(member.job_id, "")
		if path.is_empty() or not ResourceLoader.exists(path):
			sprite.visible = false
			continue
		var frames: SpriteFrames = load(path) as SpriteFrames
		if frames == null:
			sprite.visible = false
			continue
		sprite.sprite_frames = frames
		sprite.play("idle")
		sprite.visible = true

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

const _BATCH3: String = "res://assets/dungeon/royal_ruins/batch3/"
const _BATCH7: String = "res://assets/dungeon/graveyard/batch7/"

func _update_room_art() -> void:
	var room_type: int = $DungeonController.current_room_type
	var dungeon_id: String = ""
	if $DungeonController.current_dungeon_data != null:
		dungeon_id = $DungeonController.current_dungeon_data.id
	var tile_path: String
	var obj_path: String = ""
	if dungeon_id == "graveyard":
		match room_type:
			Enums.RoomType.COMBAT, Enums.RoomType.ELITE, Enums.RoomType.MID_BOSS, Enums.RoomType.BOSS:
				tile_path = _BATCH7 + "TILE_Graveyard_Wall_Tombstone.png"
			Enums.RoomType.TREASURE:
				tile_path = _BATCH7 + "TILE_Graveyard_Floor_02.png"
				obj_path = _BATCH7 + "OBJ_TreasureChest_Open.png"
			Enums.RoomType.EXIT:
				tile_path = _BATCH7 + "TILE_Graveyard_Floor_02.png"
				obj_path = _BATCH7 + "OBJ_ExitGate_Graveyard.png"
			_:
				tile_path = _BATCH7 + "TILE_Graveyard_Floor_02.png"
	else:
		match room_type:
			Enums.RoomType.COMBAT, Enums.RoomType.ELITE, Enums.RoomType.MID_BOSS, Enums.RoomType.BOSS:
				tile_path = _BATCH3 + "TILE_RoyalRuins_Wall_01.png"
			Enums.RoomType.TREASURE:
				tile_path = _BATCH3 + "TILE_RoyalRuins_Floor_01.png"
				obj_path = _BATCH3 + "OBJ_TreasureChest_Closed.png"
			Enums.RoomType.EXIT:
				tile_path = _BATCH3 + "TILE_RoyalRuins_Floor_01.png"
				obj_path = _BATCH3 + "OBJ_ExitGate_RoyalRuins.png"
			_:
				tile_path = _BATCH3 + "TILE_RoyalRuins_Floor_01.png"
	_set_room_texture(_room_tile_bg, tile_path)
	_set_room_texture(_room_object, obj_path)

func _set_room_texture(node: TextureRect, path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		node.texture = null
		node.visible = false
		return
	node.texture = load(path) as Texture2D
	node.visible = true
