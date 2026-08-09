class_name CombatController
extends Node

# バランス値は BalanceConfig（SSOT・P3-BAL-005）を参照。ここはエイリアス。
const BASE_MEMBER_HP: int = BalanceConfig.BASE_MEMBER_HP
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const _StatusResolver = preload("res://scripts/combat/StatusResolver.gd")
const _EvolutionTraits = preload("res://scripts/systems/EvolutionTraits.gd")
const _PetSystem = preload("res://scripts/pets/PetSystem.gd")
const _AbyssWeaponEffects = preload("res://scripts/combat/AbyssWeaponEffects.gd")
const _EquipmentSetBonuses = preload("res://scripts/equipment/EquipmentSetBonuses.gd")
const _CommanderPermitBoost = preload("res://scripts/commander/CommanderPermitBoost.gd")

var is_in_combat: bool = false
var current_enemy_data: Resource = null
var current_enemy_hp: int = 0
var last_exp_reward: int = 0
var last_gold_reward: int = 0

# 敵レベル（P3-D081）。start_combat で決定し、ダンジョン中は不変。
# Lv1＝tres 基準値。HP/ATK は乗算スケール（ATK のレベル係数は C′で 0.13）、DEF は据置、EXP は別係数。
const ENEMY_LEVEL_HP_K: float = BalanceConfig.ENEMY_LEVEL_HP_K
const ENEMY_LEVEL_ATK_K: float = BalanceConfig.ENEMY_LEVEL_ATK_K
const ENEMY_LEVEL_EXP_K: float = BalanceConfig.ENEMY_LEVEL_EXP_K
# 4人編成リバランス（P3-BAL-003 / G1）。敵データは3人編成前提で調整済みのため、
# 現行 party 人数に応じて HP/ATK を中央補正する（EXP/ゴールドは据置）。
const PARTY_BALANCE_BASE_SIZE: int = 3
const PARTY_BALANCE_HP_SHARE: float = BalanceConfig.PARTY_BALANCE_HP_SHARE
const PARTY_BALANCE_ATK_SHARE: float = BalanceConfig.PARTY_BALANCE_ATK_SHARE
var enemy_level: int = 1
var _scaled_max_hp: int = 0
var _scaled_attack: int = 0
var _scaled_defense: int = 0
var _scaled_exp: int = 0

# 群れ（複数敵）状態（P3-D082/D110）。current_enemy_* / _scaled_* は常に「アクティブ（フォーカス）敵」を映す。
# 敵状態異常はスロット別 enemy_<i>（P3-D110）。味方はフォーカス1体を集中攻撃。
var swarm_data: Array[Resource] = []
var swarm_hp: Array[int] = []
var swarm_max_hp: Array[int] = []
var swarm_atk: Array[int] = []
var swarm_def: Array[int] = []
var swarm_exp: Array[int] = []
var enemy_phase_index: Array[int] = []
## 放浪個体の行動回数（逃走判定用 / P3-WANDER-001）。
var wander_action_counts: Array[int] = []
var active_enemy_index: int = 0
## 群れ人数連動（開始時固定。P3-BAL-SWARM-DENSITY-001）。
var swarm_density_count: int = 0
var _swarm_density_hp_mult: float = 1.0
var _swarm_density_atk_mult: float = 1.0
var _swarm_density_spd_mult: float = 1.0
# メンバー個別の攻撃対象スロット（P3-D111）。member_target_slot[i]=敵 swarm インデックス。
var member_target_slot: Array[int] = []
# 装備スキル①②のローテーション開始位置（P3-D113）。戦闘中のみ保持。
var member_skill_rot_idx: Array[int] = []
# 必殺チャージ（P3-COMBAT-GAUGE-001 → 時間制 P3-BAL-ULTIMATE-TIME-001）。
# member index → 0..ULTIMATE_CHARGE_MAX。戦闘中・生存中のみ時間で増加。
var member_ultimate_charge: Array[float] = []
## ELITE／BOSS も通常と同速（圧力×1.0・P3-BAL-ULTIMATE-UNIFY-100-001）。
var ultimate_charge_gain_mult: float = 1.0
## 直近ボス戦の開幕オーラ状態 id（無ければ空）。ログ／演出用。
var last_boss_opening_status_id: String = ""

# CT/ATB スケジューラ（P3-D084）。各生存ユニット（味方/群れ各敵）は個別の CT を持ち、
# CT が 0 になったユニットから 1 体ずつ行動する。速度（initiative_score）が大きいほど
# 行動 CT が短く、行動回数が増える（ラウンド制 P3-D083 を置換）。
const BASE_ACTION_CT: float = 2.0
const _CT_EPSILON: float = 0.0001
# 生存ユニットごとの残り CT（key = "party_<i>" / "enemy_<slot>"）
var unit_ct: Dictionary = {}
# 直近 advance_to_next_actor で進めた CT 量（呼出側の状態異常/スキルCD進行に使う）
var _last_ct_step: float = 0.0
## 戦闘開始からの累積 CT（怒涛／P3-BAL-COMBAT-ATTRITION-001）。
var _combat_ct_elapsed: float = 0.0
# 詠唱中ペイロード（P3-D112）。key = "party_<i>" / "enemy_<slot>"。
var _pending_casts: Dictionary = {}
## 直前の should_member_skip がパッシブ固有スキップだったか（ラベル用・1回消費）。
var _member_passive_skip: Dictionary = {}

var party_combat_hp: Array[int] = []
var party_max_hp: Array[int] = []
var _status_resolver: RefCounted = _StatusResolver.new()

# ── Threat / Aggro 基盤（P3-D104・ロードマップ フェーズA-2）──
# 敵は最大 Threat のメンバーを狙う。Threat は被ダメ肩代わり・与ダメ・挑発で増え、毎tick減衰。
var party_threat: Array[float] = []
const THREAT_DAMAGE_K: float = BalanceConfig.THREAT_DAMAGE_K
const THREAT_TAKEN_K: float = BalanceConfig.THREAT_TAKEN_K
const THREAT_TAUNT: float = BalanceConfig.THREAT_TAUNT
const THREAT_DECAY: float = BalanceConfig.THREAT_DECAY
const THREAT_TARGET_BIAS_MAX: String = "max_threat"
const THREAT_TARGET_BIAS_LOWEST_HP: String = "lowest_hp"
const THREAT_TARGET_BIAS_BACK_ROW: String = "back_row"
const THREAT_TARGET_BIAS_LOWEST_THREAT: String = "lowest_threat"
const MELEE_ATTACK_RANGE_MAX: float = CombatRange.MID_RANGE_MAX  # これ以下＝前列優先ターゲット（P3-D106d/f）

# ジョブ別の基礎 Threat 重み（タンクが引きやすい）。
func _job_threat_base(member_index: int) -> float:
	var c: Resource = GameState.get_combatant(member_index)
	if c == null:
		return 1.0
	var base: float = 1.0
	if Constants.is_pet_id(str(c.id)):
		base = _PetSystem.PET_THREAT_BASE
	else:
		match str(c.job_id):
			"vanguard": base = 4.0
			"swordsman": base = 2.0
			_: base = 1.0
		base += CombatPassives.threat_base_add_for_member(c)
	# 陣形（後列は狙われにくい）（P3-D106）
	return base * GameState.formation_threat_multiplier(member_index)

func start_combat(enemy_data: Resource, level: int = 1, apply_swarm_density: bool = true) -> void:
	start_combat_group([enemy_data], level, apply_swarm_density)

# 群れ対応の戦闘開始（P3-D082）。単体は要素1の配列として扱う。
# apply_swarm_density: 通常 COMBAT のみ true（ELITE/BOSS は false）。
func start_combat_group(enemies: Array, level: int = 1, apply_swarm_density: bool = true) -> void:
	is_in_combat = true
	ultimate_charge_gain_mult = 1.0
	_combat_ct_elapsed = 0.0
	clear_death_save_state()
	clear_member_skill_silence()
	_member_passive_skip.clear()
	enemy_level = maxi(1, level)
	swarm_data.clear()
	swarm_hp.clear()
	swarm_max_hp.clear()
	swarm_atk.clear()
	swarm_def.clear()
	swarm_exp.clear()
	enemy_phase_index.clear()
	wander_action_counts.clear()
	var valid_n: int = 0
	for e0 in enemies:
		if e0 != null:
			valid_n += 1
	_set_swarm_density(valid_n if apply_swarm_density else 0)
	for e in enemies:
		if e == null:
			continue
		var scaled: Dictionary = _scale_enemy_combat_stats(e)
		swarm_data.append(e)
		swarm_hp.append(int(scaled["hp"]))
		swarm_max_hp.append(int(scaled["hp"]))
		swarm_atk.append(int(scaled["atk"]))
		swarm_def.append(int(scaled["def"]))
		swarm_exp.append(int(scaled["exp"]))
		enemy_phase_index.append(0)
		wander_action_counts.append(0)
		GameState.mark_enemy_seen(e.id)
	active_enemy_index = 0
	_sync_active_enemy()
	last_exp_reward = 0
	last_gold_reward = 0
	ensure_party_hp_for_combat()
	_init_member_targets()
	_init_member_skill_rotation()
	## 必殺ゲージはフロア／戦闘をまたいで引き継ぐ（ダンジョン入場時のみリセット）。
	_ensure_member_ultimate_charge()
	## ボス開幕オーラ（個別 hex 状態）— CT 初期化前に付与（P3-BAL-BOSS-AURA-A-001）。
	last_boss_opening_status_id = _apply_boss_opening_aura()
	init_ct()


func _find_lead_boss_slot() -> int:
	for i: int in swarm_data.size():
		var ed: Resource = swarm_data[i]
		if ed != null and int(ed.enemy_type) == Enums.EnemyType.BOSS:
			return i
	return -1


## ボスの `boss_*_hex` から付与状態 id を取る。無ければ空。
func boss_hex_status_id(boss: Resource) -> String:
	if boss == null:
		return ""
	for raw in boss.skill_ids:
		var sid: String = str(raw)
		if not sid.begins_with("boss_") or not sid.ends_with("_hex"):
			continue
		var skill: Resource = DataRegistry.get_skill_data(sid)
		if skill == null:
			continue
		var st: String = str(skill.apply_status_id)
		if not st.is_empty():
			return st
	return ""


## 入場時に味方全員へボス個別 hex 状態を付与。付与した状態 id を返す。
func _apply_boss_opening_aura() -> String:
	var slot: int = _find_lead_boss_slot()
	if slot < 0:
		return ""
	var boss: Resource = swarm_data[slot]
	var status_id: String = boss_hex_status_id(boss)
	if status_id.is_empty():
		return ""
	var src_atk: int = swarm_atk[slot] if slot < swarm_atk.size() else 0
	for i: int in party_combat_hp.size():
		if not is_member_alive(i):
			continue
		apply_status("party_%d" % i, status_id, 1, src_atk)
	return status_id


func _set_swarm_density(start_count: int) -> void:
	if start_count <= 0:
		swarm_density_count = 0
		_swarm_density_hp_mult = 1.0
		_swarm_density_atk_mult = 1.0
		_swarm_density_spd_mult = 1.0
		return
	swarm_density_count = start_count
	_swarm_density_hp_mult = BalanceConfig.swarm_density_hp_mult(start_count)
	_swarm_density_atk_mult = BalanceConfig.swarm_density_atk_mult(start_count)
	_swarm_density_spd_mult = BalanceConfig.swarm_density_spd_mult(start_count)


func is_swarm_density_solo() -> bool:
	return is_in_combat and swarm_density_count == 1


func _scale_enemy_combat_stats(enemy_data: Resource) -> Dictionary:
	var lf: float = float(maxi(0, enemy_level - 1))
	var enemy_type: int = int(enemy_data.enemy_type)
	var is_boss: bool = enemy_type == Enums.EnemyType.BOSS
	var is_trash: bool = enemy_type == Enums.EnemyType.NORMAL
	var party_hp_mult: float = _party_size_balance_multiplier(PARTY_BALANCE_HP_SHARE)
	var atk_share: float = (
		BalanceConfig.BOSS_PARTY_BALANCE_ATK_SHARE if is_boss else PARTY_BALANCE_ATK_SHARE
	)
	var party_atk_mult: float = _party_size_balance_multiplier(atk_share)
	var boss_atk_mult: float = BalanceConfig.BOSS_ATK_MULT if is_boss else 1.0
	var trash_atk_mult: float = (
		BalanceConfig.TRASH_ENEMY_ATK_MULT if is_trash else 1.0
	)
	var hp: int = maxi(1, int(round(
		float(enemy_data.max_hp)
		* (1.0 + ENEMY_LEVEL_HP_K * lf)
		* party_hp_mult
		* BalanceConfig.ENEMY_GLOBAL_HP_MULT
		* _swarm_density_hp_mult
	)))
	var atk: int = maxi(1, int(round(
		float(enemy_data.attack)
		* (1.0 + ENEMY_LEVEL_ATK_K * lf)
		* party_atk_mult
		* BalanceConfig.ENEMY_GLOBAL_ATK_MULT
		* _swarm_density_atk_mult
		* boss_atk_mult
		* trash_atk_mult
	)))
	var df: int = maxi(0, int(enemy_data.defense))
	var xp: int = maxi(0, int(round(float(enemy_data.exp_reward) * (1.0 + ENEMY_LEVEL_EXP_K * lf))))
	return {"hp": hp, "atk": atk, "def": df, "exp": xp}

# 現行編成人数に対する敵ステ補正倍率（base=3人前提）。
# ペット込みの実戦闘人数を使う（P3-BAL-OPENING-001 / 旧は ACTIVE_PARTY_SIZE=人間4固定）。
static func _party_size_balance_multiplier(share: float) -> float:
	var n: int = maxi(1, GameState.combatant_count())
	if n <= PARTY_BALANCE_BASE_SIZE:
		return 1.0
	var ratio: float = float(n) / float(PARTY_BALANCE_BASE_SIZE) - 1.0
	return 1.0 + ratio * share

# current_enemy_* / _scaled_* をアクティブ敵スロットに同期する。
func _sync_active_enemy() -> void:
	if active_enemy_index < 0 or active_enemy_index >= swarm_data.size():
		current_enemy_data = null
		current_enemy_hp = 0
		_scaled_max_hp = 0
		_scaled_attack = 0
		_scaled_defense = 0
		_scaled_exp = 0
		return
	current_enemy_data = swarm_data[active_enemy_index]
	current_enemy_hp = swarm_hp[active_enemy_index]
	_scaled_max_hp = swarm_max_hp[active_enemy_index]
	_scaled_attack = swarm_atk[active_enemy_index]
	_scaled_defense = swarm_def[active_enemy_index]
	_scaled_exp = swarm_exp[active_enemy_index]

func swarm_count() -> int:
	return swarm_data.size()

func is_enemy_slot_alive(i: int) -> bool:
	return i >= 0 and i < swarm_hp.size() and swarm_hp[i] > 0

func get_living_enemy_indices() -> Array[int]:
	var out: Array[int] = []
	for i in swarm_hp.size():
		if swarm_hp[i] > 0:
			out.append(i)
	return out

func living_enemy_count() -> int:
	return get_living_enemy_indices().size()

# 群れ全滅（戦闘クリア）判定。
func is_combat_cleared() -> bool:
	return is_in_combat and living_enemy_count() == 0

func get_enemy_attack_at(i: int) -> int:
	if i >= 0 and i < swarm_atk.size():
		return swarm_atk[i]
	return _scaled_attack

func get_enemy_defense_at(i: int) -> int:
	if i >= 0 and i < swarm_def.size():
		return swarm_def[i]
	return _scaled_defense

func get_enemy_max_hp_at(i: int) -> int:
	if i >= 0 and i < swarm_max_hp.size():
		return swarm_max_hp[i]
	return _scaled_max_hp

func get_enemy_hp_at(i: int) -> int:
	if i >= 0 and i < swarm_hp.size():
		return swarm_hp[i]
	return current_enemy_hp

func get_enemy_data_at(i: int) -> Resource:
	if i >= 0 and i < swarm_data.size():
		return swarm_data[i]
	return current_enemy_data

# 敵スロット別 StatusResolver ユニット id（P3-D110）。CT の enemy_<slot> と整合。
func enemy_status_unit_id(slot: int) -> String:
	return "enemy_%d" % slot

func get_active_enemy_status_unit_id() -> String:
	return enemy_status_unit_id(active_enemy_index)

# アクティブ敵を次の生存スロットへ繰り上げる（撃破スロットの状態は呼び出し側でクリア）。
func advance_active_enemy() -> int:
	for i in swarm_hp.size():
		if swarm_hp[i] > 0:
			active_enemy_index = i
			_sync_active_enemy()
			return i
	active_enemy_index = -1
	_sync_active_enemy()
	return -1

func clear_enemy_slot_status(slot: int) -> void:
	if slot < 0:
		return
	_status_resolver.clear_unit(enemy_status_unit_id(slot))

func _init_member_targets() -> void:
	member_target_slot.clear()
	for i in party_combat_hp.size():
		member_target_slot.append(0)

func _init_member_skill_rotation() -> void:
	member_skill_rot_idx.clear()
	for i in party_combat_hp.size():
		member_skill_rot_idx.append(0)

func get_skill_rotation_index(member_index: int) -> int:
	if member_index < 0 or member_index >= member_skill_rot_idx.size():
		return 0
	return member_skill_rot_idx[member_index]

func set_skill_rotation_after_cast(member_index: int, used_index: int, slot_count: int) -> void:
	if member_index < 0 or member_index >= member_skill_rot_idx.size() or slot_count <= 0:
		return
	member_skill_rot_idx[member_index] = (used_index + 1) % slot_count

func _init_member_ultimate_charge() -> void:
	member_ultimate_charge.clear()
	for i in party_combat_hp.size():
		member_ultimate_charge.append(0.0)


## パーティ人数に合わせて必殺ゲージ配列を整え、既存値は維持する。
func _ensure_member_ultimate_charge() -> void:
	var n: int = party_combat_hp.size()
	if member_ultimate_charge.size() == n:
		return
	var old: Array[float] = member_ultimate_charge.duplicate()
	member_ultimate_charge.clear()
	for i: int in n:
		if i < old.size():
			member_ultimate_charge.append(float(old[i]))
		else:
			member_ultimate_charge.append(0.0)


## ダンジョン入場時に必殺ゲージを0へ。
func reset_member_ultimate_charge() -> void:
	ensure_party_hp_for_combat()
	_init_member_ultimate_charge()
	ultimate_charge_gain_mult = 1.0


func set_ultimate_charge_gain_mult(mult: float) -> void:
	ultimate_charge_gain_mult = maxf(0.0, mult)


## ELITE／BOSS 入場時: 持ち越しゲージを半減（ゼロにはしない）。
func scale_member_ultimate_charge(mult: float) -> void:
	_ensure_member_ultimate_charge()
	var m: float = maxf(0.0, mult)
	for i: int in member_ultimate_charge.size():
		member_ultimate_charge[i] = minf(
			Constants.ULTIMATE_CHARGE_MAX,
			float(member_ultimate_charge[i]) * m
		)


func get_ultimate_charge(member_index: int) -> float:
	if member_index < 0 or member_index >= member_ultimate_charge.size():
		return 0.0
	return float(member_ultimate_charge[member_index])

func get_ultimate_charge_ratio(member_index: int) -> float:
	return clampf(get_ultimate_charge(member_index) / Constants.ULTIMATE_CHARGE_MAX, 0.0, 1.0)

func is_ultimate_charge_ready(member_index: int) -> bool:
	return get_ultimate_charge(member_index) >= Constants.ULTIMATE_CHARGE_MAX - 0.001

func add_ultimate_charge(member_index: int, amount: float) -> void:
	if member_index < 0 or member_index >= member_ultimate_charge.size():
		return
	if amount <= 0.0:
		return
	if not is_member_alive(member_index):
		return
	## ペットは必殺対象外（P3-PET-ULT-OMIT-001）。
	if GameState.is_pet_combatant(member_index):
		return
	var gained: float = amount * ultimate_charge_gain_mult
	if gained <= 0.0:
		return
	member_ultimate_charge[member_index] = minf(
		Constants.ULTIMATE_CHARGE_MAX,
		float(member_ultimate_charge[member_index]) + gained
	)

## 戦闘時間で必殺ゲージを進める（×1 で FILL_SECONDS 秒満タン）。
## `delta_sec` は一時停止を除いた戦闘クロック（速度倍率込み可）。
func tick_ultimate_charge_over_time(delta_sec: float) -> void:
	if delta_sec <= 0.0 or not is_in_combat:
		return
	var fill_sec: float = Constants.ULTIMATE_CHARGE_FILL_SECONDS
	if fill_sec <= 0.0:
		return
	_ensure_member_ultimate_charge()
	var base_per_sec: float = Constants.ULTIMATE_CHARGE_MAX / fill_sec
	for i: int in member_ultimate_charge.size():
		if not is_member_alive(i):
			continue
		var rate_mult: float = CombatPassives.ultimate_charge_rate_mult(i)
		if rate_mult <= 0.0:
			continue
		add_ultimate_charge(i, base_per_sec * delta_sec * rate_mult)

func consume_ultimate_charge(member_index: int) -> void:
	if member_index < 0 or member_index >= member_ultimate_charge.size():
		return
	member_ultimate_charge[member_index] = 0.0

func get_member_target_slot(member_index: int) -> int:
	if member_index < 0 or member_index >= member_target_slot.size():
		return active_enemy_index
	var slot: int = member_target_slot[member_index]
	if is_enemy_slot_alive(slot):
		return slot
	## 死亡スロットはメンバー戦術ルールで付け替え（DEFAULT front 固定は戦術無視）。
	var member: Resource = GameState.get_combatant(member_index)
	var rule: String = CombatTactics.DEFAULT_TARGET
	if member != null:
		rule = CombatGambit.target_from_member(member)
	var picked: int = pick_enemy_slot_by_rule(rule)
	if picked < 0:
		return active_enemy_index
	member_target_slot[member_index] = picked
	return picked

# 生存敵から target ルールで1体選ぶ（P3-D100/D111）。
## 敵デバフ集合（ターゲット優先・vs状態与ダメ・has_debuff）。shock/ignite 漏れは配線バグ（H-001）。
const DEBUFF_STATUS_IDS: Array[String] = [
	"stun", "fear", "poison", "bleed", "vulnerable", "armor_break", "armor_break_light", "curse", "major_curse",
	"chill", "slow", "mark", "shock", "ignite",
]

func _pick_debuff_priority_slots(living: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for i: int in living:
		for status_id: String in DEBUFF_STATUS_IDS:
			if get_enemy_status_stacks_at(i, status_id) > 0:
				out.append(i)
				break
	return out

func _pick_status_priority_slots(living: Array[int], priority_status: String) -> Array[int]:
	var out: Array[int] = []
	for i: int in living:
		if priority_status.is_empty():
			if not get_enemy_status_list_at(i).is_empty():
				out.append(i)
		elif get_enemy_status_stacks_at(i, priority_status) > 0:
			out.append(i)
	return out

func pick_enemy_slot_by_rule(rule: String) -> int:
	var living: Array[int] = get_living_enemy_indices()
	if living.is_empty():
		return -1
	if living.size() == 1:
		return living[0]
	var best: int = living[0]
	match rule:
		"lowest_hp":
			for i: int in living:
				if swarm_hp[i] < swarm_hp[best]:
					best = i
		"highest_hp":
			for i: int in living:
				if swarm_hp[i] > swarm_hp[best]:
					best = i
		"highest_atk":
			for i: int in living:
				if swarm_atk[i] > swarm_atk[best]:
					best = i
		"enemy_with_status":
			var with_status: Array[int] = _pick_status_priority_slots(living, "")
			if with_status.is_empty():
				return living[0]
			best = with_status[0]
			for i: int in with_status:
				if swarm_hp[i] < swarm_hp[best]:
					best = i
		"enemy_marked":
			var marked: Array[int] = _pick_status_priority_slots(living, "mark")
			if marked.is_empty():
				return living[0]
			best = marked[0]
			for i: int in marked:
				if swarm_hp[i] < swarm_hp[best]:
					best = i
		"enemy_with_debuff":
			var debuffed: Array[int] = _pick_debuff_priority_slots(living)
			if debuffed.is_empty():
				return living[0]
			best = debuffed[0]
			for i: int in debuffed:
				if swarm_hp[i] < swarm_hp[best]:
					best = i
		"back":
			return living[living.size() - 1]
		_:
			best = living[0]
	return best

# メンバー戦術の target ルールで狙いを決定し member_target_slot に保存する。
func resolve_member_target(member_index: int, rule: String) -> int:
	var slot: int = pick_enemy_slot_by_rule(rule)
	if member_index >= 0 and member_index < member_target_slot.size():
		member_target_slot[member_index] = slot
	return slot

# パーティ・フォーカス対象を target ルールで選び、アクティブ敵に設定する（P3-D100）。
# 単一アクティブ＝味方はフォーカス1体を集中攻撃。敵別状態スロット（P3-D110）で個体ごとに状態保持。
# rule: "front" | "lowest_hp" | "highest_hp" | "highest_atk"
func set_focus_by_rule(rule: String) -> int:
	var best: int = pick_enemy_slot_by_rule(rule)
	if best < 0:
		return active_enemy_index
	if best != active_enemy_index:
		active_enemy_index = best
		_sync_active_enemy()
	return active_enemy_index

func get_enemy_max_hp() -> int:
	return _scaled_max_hp

func get_enemy_attack() -> int:
	return _scaled_attack

func get_enemy_defense() -> int:
	return _scaled_defense

func get_wander_flee_after_turns(slot: int) -> int:
	var data: Resource = get_enemy_data_at(slot)
	if data == null or not bool(data.is_wandering):
		return 0
	return maxi(0, int(data.wander_flee_after_turns))

func get_wander_action_count(slot: int) -> int:
	if slot < 0 or slot >= wander_action_counts.size():
		return 0
	return wander_action_counts[slot]

func increment_wander_action_count(slot: int) -> void:
	if slot < 0 or slot >= wander_action_counts.size():
		return
	wander_action_counts[slot] += 1

func flee_enemy_slot(slot: int) -> void:
	if slot < 0 or slot >= swarm_hp.size():
		return
	swarm_hp[slot] = 0
	if slot == active_enemy_index:
		current_enemy_hp = 0


## 通常攻撃／スキル被ダメ倍率（トリッキー）。DoT 等は呼び出し側で使わない。
func get_enemy_incoming_attack_mult(slot: int, is_basic_attack: bool) -> float:
	var data: Resource = get_enemy_data_at(slot)
	if data == null:
		return 1.0
	var mult: float = 1.0
	if is_basic_attack:
		if "incoming_basic_mult" in data:
			mult = float(data.incoming_basic_mult)
	else:
		if "incoming_skill_mult" in data:
			mult = float(data.incoming_skill_mult)
	if mult <= 0.0:
		## 完全無効は禁止（Decision）。下限で通し残す。
		return 0.05
	return mult

func end_combat() -> void:
	is_in_combat = false
	ultimate_charge_gain_mult = 1.0
	clear_death_save_state()
	clear_member_skill_silence()
	current_enemy_data = null
	current_enemy_hp = 0
	enemy_level = 1
	_scaled_max_hp = 0
	_scaled_attack = 0
	_scaled_defense = 0
	_scaled_exp = 0
	swarm_data.clear()
	swarm_hp.clear()
	swarm_max_hp.clear()
	swarm_atk.clear()
	swarm_def.clear()
	swarm_exp.clear()
	enemy_phase_index.clear()
	wander_action_counts.clear()
	active_enemy_index = 0
	_set_swarm_density(0)
	member_target_slot.clear()
	member_skill_rot_idx.clear()
	unit_ct.clear()
	_last_ct_step = 0.0
	_pending_casts.clear()
	_status_resolver.clear_all()

## ラン開始時に1回だけ呼ぶ。全員を最大HPで初期化する。
func reset_party_hp_for_run() -> void:
	_init_party_hp()

## 戦闘開始時。HPはラン中持ち越し・Threatのみ戦闘ごとにリセット。
func ensure_party_hp_for_combat() -> void:
	var expected_size: int = GameState.get_combatants().size()
	if party_combat_hp.is_empty() or party_combat_hp.size() != expected_size:
		_init_party_hp()
	else:
		_reset_party_threat_for_combat()

func _reset_party_threat_for_combat() -> void:
	party_threat.clear()
	var combatants: Array = GameState.get_combatants()
	for i in combatants.size():
		party_threat.append(_job_threat_base(i))

func _init_party_hp() -> void:
	party_combat_hp.clear()
	party_max_hp.clear()
	party_threat.clear()
	var combatants: Array = GameState.get_combatants()
	for i in combatants.size():
		var member: Resource = combatants[i]
		var max_hp: int = BASE_MEMBER_HP
		if member.base_stats != null and member.base_stats.hp > 0:
			max_hp = member.base_stats.hp
		var armor: Resource = member.equipped_armor
		if armor != null:
			max_hp += EquipmentEnhancer.effective_armor_hp(armor)
		var acc: Resource = member.equipped_accessory
		if acc != null:
			var acc_data: Resource = DataRegistry.get_accessory_data(str(acc.accessory_id))
			if acc_data != null:
				max_hp += EquipmentEnhancer.effective_accessory_int_bonus(acc, "hp_bonus", acc_data)
		# Affix ボーナスとレベル HP
		var affix_bonuses: Dictionary = _AffixStatCalculator.get_bonuses(i)
		max_hp += int(affix_bonuses.get("hp_flat", 0))
		max_hp += LevelSystem.level_hp_bonus(member.level, member)
		var job_mods: Dictionary = _JobStatCalculator.get_member_modifiers(member)
		var hp_mult: float = float(job_mods.get("hp_multiplier", _JobStatCalculator.DEFAULT_MULTIPLIER))
		hp_mult *= _EquipmentSetBonuses.hp_mult(i)
		hp_mult *= _CommanderPermitBoost.hp_mult()
		max_hp = maxi(1, int(round(float(max_hp) * hp_mult)))
		## ペットは編成パッシブのステ倍率を最大HPにも適用。
		if GameState.is_pet_combatant(i):
			var pet_hp_mult: float = CombatPassives.pet_max_hp_mult_from_party()
			if pet_hp_mult > 0.0 and not is_equal_approx(pet_hp_mult, 1.0):
				max_hp = maxi(1, int(round(float(max_hp) * pet_hp_mult)))
		party_combat_hp.append(max_hp)
		party_max_hp.append(max_hp)
		party_threat.append(_job_threat_base(i))

func is_member_alive(index: int) -> bool:
	if index < 0 or index >= party_combat_hp.size():
		return false
	return party_combat_hp[index] > 0

func get_alive_count() -> int:
	var count: int = 0
	for hp in party_combat_hp:
		if hp > 0:
			count += 1
	return count

func is_party_wiped() -> bool:
	# 助っ人のみ生存ではラン継続しない。メイン編成3人が全滅で判定。
	var main_count: int = GameState.party_members.size()
	for i in mini(main_count, party_combat_hp.size()):
		if party_combat_hp[i] > 0:
			return false
	return true

func apply_damage_to_enemy(amount: int) -> void:
	if not is_in_combat:
		return
	if active_enemy_index >= 0 and active_enemy_index < swarm_hp.size():
		swarm_hp[active_enemy_index] = max(0, swarm_hp[active_enemy_index] - amount)
		current_enemy_hp = swarm_hp[active_enemy_index]
	else:
		current_enemy_hp = max(0, current_enemy_hp - amount)

## 致死回避を使ったメンバー index → シールド終了時刻（Time.get_ticks_msec）。
var _death_save_used: Dictionary = {}
var _death_save_shield_until_msec: Dictionary = {}
var _death_save_outgoing_until_msec: Dictionary = {}
var _death_save_outgoing_mult: Dictionary = {}
## 戦闘中の一時パーティ被ダメ倍率（ヴァルデン等）。1.0=等倍。
var party_temp_incoming_mult: float = 1.0
## 分かれ道・戦力強化などラン／フロア単位の被ダメ倍率（DungeonScene が同期）。
var floor_choice_incoming_mult: float = 1.0

func clear_death_save_state() -> void:
	_death_save_used.clear()
	_death_save_shield_until_msec.clear()
	_death_save_outgoing_until_msec.clear()
	_death_save_outgoing_mult.clear()
	party_temp_incoming_mult = 1.0
	## floor_choice_incoming_mult はフロア単位。死亡セーブリセットでは触らない。


## T10 沈黙: member_idx → 残り秒（戦闘クロック。一時停止中は進まない）。
var _member_skill_silence_remaining_sec: Dictionary = {}


func clear_member_skill_silence() -> void:
	_member_skill_silence_remaining_sec.clear()


func apply_member_skill_silence(member_index: int, duration_sec: float) -> void:
	if member_index < 0 or duration_sec <= 0.0:
		return
	if not is_member_alive(member_index):
		return
	_member_skill_silence_remaining_sec[member_index] = duration_sec


func is_member_skill_silenced(member_index: int) -> bool:
	if member_index < 0:
		return false
	return float(_member_skill_silence_remaining_sec.get(member_index, 0.0)) > 0.0


## 必殺／スキルCDと同型の戦闘クロック。戻り値=解除されたメンバーがいたか。
func tick_member_skill_silence(delta_sec: float) -> bool:
	if delta_sec <= 0.0 or _member_skill_silence_remaining_sec.is_empty():
		return false
	var expired: bool = false
	var keys: Array = _member_skill_silence_remaining_sec.keys()
	for k in keys:
		var rem: float = float(_member_skill_silence_remaining_sec[k]) - delta_sec
		if rem <= 0.0:
			_member_skill_silence_remaining_sec.erase(k)
			expired = true
		else:
			_member_skill_silence_remaining_sec[k] = rem
	return expired


func apply_damage_to_member(index: int, amount: int) -> void:
	if index < 0 or index >= party_combat_hp.size():
		return
	var before: int = int(party_combat_hp[index])
	if before <= 0:
		return
	var after: int = max(0, before - amount)
	if after <= 0:
		var save_def: Dictionary = CombatPassives.death_save_def_for_member(index)
		if not save_def.is_empty():
			var once: bool = bool(save_def.get("death_save_once", false))
			if once and bool(_death_save_used.get(index, false)):
				party_combat_hp[index] = after
				return
			var chance: float = float(save_def.get("death_save_chance", 1.0 if once else 0.0))
			if chance <= 0.0:
				chance = 1.0 if once else 0.0
			if chance > 0.0 and randf() <= chance:
				if once:
					_death_save_used[index] = true
				party_combat_hp[index] = 1
				var heal_frac: float = float(save_def.get("death_save_heal_max_hp_fraction", 0.0))
				if heal_frac > 0.0 and index < party_max_hp.size():
					var heal_amt: int = maxi(1, int(round(float(party_max_hp[index]) * heal_frac)))
					## 致死復帰は受取回復ペナルティを通さない（等倍）。
					heal_member(index, heal_amt, false)
				var out_mult: float = float(save_def.get("death_save_outgoing_mult", 1.0))
				var out_dur: float = float(save_def.get("death_save_outgoing_duration_sec", 0.0))
				if out_dur > 0.0 and not is_equal_approx(out_mult, 1.0):
					_death_save_outgoing_until_msec[index] = Time.get_ticks_msec() + int(out_dur * 1000.0)
					_death_save_outgoing_mult[index] = out_mult
				var dur_sec: float = float(save_def.get("death_save_duration_sec", 0.0))
				if dur_sec > 0.0:
					_death_save_shield_until_msec[index] = Time.get_ticks_msec() + int(dur_sec * 1000.0)
				return
	party_combat_hp[index] = after


## 後衛被弾をレリック装備者へ振替。振替時 true。
func try_redirect_rear_hit(target_idx: int) -> Dictionary:
	var out: Dictionary = {"target": target_idx, "redirected": false}
	if target_idx < 0 or not is_member_alive(target_idx):
		return out
	if not GameState.is_member_back_row(target_idx):
		return out
	var holder: int = CombatPassives.redirect_rear_hit_holder_index()
	if holder < 0 or holder == target_idx or not is_member_alive(holder):
		return out
	var chance: float = CombatPassives.redirect_rear_hit_chance_for(holder)
	if chance <= 0.0 or randf() > chance:
		return out
	out["target"] = holder
	out["redirected"] = true
	out["holder"] = holder
	return out


func death_save_outgoing_mult_for(member_index: int) -> float:
	if not bool(_death_save_outgoing_until_msec.has(member_index)):
		return 1.0
	if Time.get_ticks_msec() > int(_death_save_outgoing_until_msec[member_index]):
		_death_save_outgoing_until_msec.erase(member_index)
		_death_save_outgoing_mult.erase(member_index)
		return 1.0
	return float(_death_save_outgoing_mult.get(member_index, 1.0))

func refund_member_ct(member_index: int, fraction: float) -> void:
	var frac: float = clampf(fraction, 0.0, 1.0)
	if frac <= 0.0:
		return
	var key: String = _ct_unit_key("party", member_index)
	if not unit_ct.has(key):
		return
	var full: float = get_unit_action_ct("party", member_index)
	unit_ct[key] = full * (1.0 - frac)


## 敵スロットの行動待ちを短縮（T14 時間稼ぎ）。
func refund_enemy_ct(slot: int, fraction: float) -> void:
	var frac: float = clampf(fraction, 0.0, 1.0)
	if frac <= 0.0 or not is_enemy_slot_alive(slot):
		return
	var key: String = _ct_unit_key("enemy", slot)
	if not unit_ct.has(key):
		return
	var full: float = get_unit_action_ct("enemy", slot)
	unit_ct[key] = full * (1.0 - frac)


## 行動待ちを延ばす（反撃ペナルティ等）。fraction=1 で満タン待ちに近い。
func penalize_member_ct(member_index: int, fraction: float) -> void:
	var frac: float = clampf(fraction, 0.0, 1.0)
	if frac <= 0.0:
		return
	var key: String = _ct_unit_key("party", member_index)
	if not unit_ct.has(key):
		return
	var full: float = get_unit_action_ct("party", member_index)
	var cur: float = float(unit_ct[key])
	unit_ct[key] = minf(full, cur + full * frac)

func is_enemy_slot_defeated(slot: int) -> bool:
	return is_in_combat and not is_enemy_slot_alive(slot)

func is_enemy_defeated() -> bool:
	return is_enemy_slot_defeated(active_enemy_index)

func heal_party(amount: int) -> void:
	if party_combat_hp.is_empty():
		_init_party_hp()
	for i in party_combat_hp.size():
		if party_combat_hp[i] > 0:
			party_combat_hp[i] = min(party_combat_hp[i] + amount, party_max_hp[i])

## 指定メンバーを回復し、実際に回復した量を返す（死亡者は蘇生しない／上限クランプ）。
func get_member_max_hp(index: int) -> int:
	if index < 0 or index >= party_max_hp.size():
		return 0
	return maxi(0, int(party_max_hp[index]))


## apply_received_mult=false は吸血・致死復帰など「受取回復」扱いしない経路用。
func heal_member(index: int, amount: int, apply_received_mult: bool = true) -> int:
	if index < 0 or index >= party_combat_hp.size():
		return 0
	if party_combat_hp[index] <= 0:
		return 0
	var adjusted: int = amount
	if apply_received_mult:
		var heal_mult: float = CombatPassives.relic_heal_received_mult(index)
		heal_mult *= CombatWeather.heal_received_multiplier(GameState.get_weather())
		heal_mult *= _status_resolver.get_healing_received_multiplier("party_%d" % index)
		if not is_equal_approx(heal_mult, 1.0):
			adjusted = int(round(float(amount) * heal_mult))
	if adjusted <= 0:
		return 0
	var before: int = party_combat_hp[index]
	party_combat_hp[index] = min(before + adjusted, party_max_hp[index])
	return party_combat_hp[index] - before


## 戦闘不能メンバーを蘇生（HP0→指定割合）。成功時の回復後HPを返す。失敗時0。
func revive_member(index: int, max_hp_fraction: float = 0.30) -> int:
	if index < 0 or index >= party_combat_hp.size() or index >= party_max_hp.size():
		return 0
	if party_combat_hp[index] > 0:
		return 0
	var max_hp: int = maxi(1, int(party_max_hp[index]))
	var hp: int = maxi(1, int(round(float(max_hp) * clampf(max_hp_fraction, 0.01, 1.0))))
	party_combat_hp[index] = mini(hp, max_hp)
	return int(party_combat_hp[index])

func get_enemy_hp_ratio(slot: int) -> float:
	if not is_enemy_slot_alive(slot):
		return 0.0
	var maxhp: int = get_enemy_max_hp_at(slot)
	if maxhp <= 0:
		return 0.0
	return float(get_enemy_hp_at(slot)) / float(maxhp)


## 戦闘中に敵を追加（T8 途中召集）。失敗時 -1。新規は満タン CT。
## ステ倍率は開始時の群れ人数連動を維持（召集で再計算しない）。
## 死体スロット（hp<=0）があれば再利用し、生存数のみで size_cap を見る。
func append_enemy_to_swarm(enemy_data: Resource, size_cap: int = 5) -> int:
	if not is_in_combat or enemy_data == null:
		return -1
	if living_enemy_count() >= size_cap:
		return -1
	var scaled: Dictionary = _scale_enemy_combat_stats(enemy_data)
	var hp: int = int(scaled["hp"])
	var atk: int = int(scaled["atk"])
	var defv: int = int(scaled["def"])
	var expv: int = int(scaled["exp"])
	var reuse: int = -1
	for i: int in swarm_hp.size():
		if swarm_hp[i] <= 0:
			reuse = i
			break
	if reuse >= 0:
		clear_enemy_slot_status(reuse)
		clear_pending_cast("enemy", reuse)
		swarm_data[reuse] = enemy_data
		swarm_hp[reuse] = hp
		swarm_max_hp[reuse] = hp
		swarm_atk[reuse] = atk
		swarm_def[reuse] = defv
		swarm_exp[reuse] = expv
		if reuse < enemy_phase_index.size():
			enemy_phase_index[reuse] = 0
		if reuse < wander_action_counts.size():
			wander_action_counts[reuse] = 0
		GameState.mark_enemy_seen(enemy_data.id)
		_sync_ct_units()
		return reuse
	if swarm_data.size() >= size_cap:
		return -1
	swarm_data.append(enemy_data)
	swarm_hp.append(hp)
	swarm_max_hp.append(hp)
	swarm_atk.append(atk)
	swarm_def.append(defv)
	swarm_exp.append(expv)
	enemy_phase_index.append(0)
	wander_action_counts.append(0)
	GameState.mark_enemy_seen(enemy_data.id)
	var slot: int = swarm_data.size() - 1
	_sync_ct_units()
	return slot


## 敵スロット回復（P3-BAL-ENEMY-TRICKY-001）。実回復量を返す。
func heal_enemy_slot(slot: int, amount: int) -> int:
	if not is_in_combat:
		return 0
	if slot < 0 or slot >= swarm_hp.size() or amount <= 0:
		return 0
	if swarm_hp[slot] <= 0:
		return 0
	var maxhp: int = get_enemy_max_hp_at(slot)
	if maxhp <= 0:
		return 0
	var before: int = swarm_hp[slot]
	swarm_hp[slot] = mini(before + amount, maxhp)
	if slot == active_enemy_index:
		current_enemy_hp = swarm_hp[slot]
	return swarm_hp[slot] - before

## 最も負傷している生存敵スロット（exclude 以外）。いなければ -1。
func get_most_injured_enemy_slot(exclude_slot: int = -1) -> int:
	var best: int = -1
	var best_deficit: int = 0
	for i in swarm_hp.size():
		if i == exclude_slot:
			continue
		if not is_enemy_slot_alive(i):
			continue
		var deficit: int = get_enemy_max_hp_at(i) - swarm_hp[i]
		if deficit > best_deficit:
			best_deficit = deficit
			best = i
	return best

## 最も負傷している生存敵（自分含む）。満タンのみなら -1。
func get_most_injured_enemy_slot_including(slot_hint: int = -1) -> int:
	var best: int = get_most_injured_enemy_slot(-1)
	if best >= 0:
		return best
	if slot_hint >= 0 and is_enemy_slot_alive(slot_hint):
		return slot_hint
	return -1

## 最も負傷している生存メンバーのindexを返す（負傷者なしは -1）。
## `exclude_idx` 指定時はそのメンバーを候補から外す（つつき介抱など自己非対象）。
func get_most_injured_member_index(exclude_idx: int = -1) -> int:
	var best: int = -1
	var best_deficit: int = 0
	for i in party_combat_hp.size():
		if i == exclude_idx:
			continue
		if party_combat_hp[i] <= 0:
			continue
		var deficit: int = party_max_hp[i] - party_combat_hp[i]
		if deficit > best_deficit:
			best_deficit = deficit
			best = i
	return best


## 最傷生存メンバーの HP 割合（0〜1）。負傷者なし／全滅は 1.0。
func get_lowest_member_hp_ratio(exclude_idx: int = -1) -> float:
	var idx: int = get_most_injured_member_index(exclude_idx)
	if idx < 0:
		return 1.0
	var maxhp: int = party_max_hp[idx]
	if maxhp <= 0:
		return 1.0
	return float(party_combat_hp[idx]) / float(maxhp)

func pick_enemy_target_member_index(attacker_slot: int = -1) -> int:
	return pick_enemy_target_from_indices(_eligible_enemy_targets(false, false), attacker_slot)

func pick_enemy_target_for_melee_attack(attacker_slot: int = -1) -> int:
	if _is_enemy_ranged_at(attacker_slot):
		return pick_enemy_target_member_index(attacker_slot)
	var front: Array[int] = _eligible_enemy_targets(true, false)
	if not front.is_empty():
		return pick_enemy_target_from_indices(front, attacker_slot)
	return pick_enemy_target_from_indices(_eligible_enemy_targets(false, true), attacker_slot)

func get_member_threat(member_index: int) -> float:
	return _threat_of(member_index)

func _is_enemy_ranged_at(slot: int) -> bool:
	var data: Resource = get_enemy_data_at(slot) if slot >= 0 else current_enemy_data
	if data == null:
		return false
	return float(data.attack_range) > MELEE_ATTACK_RANGE_MAX

func _eligible_enemy_targets(front_only: bool, back_only: bool) -> Array[int]:
	var alive: Array[int] = []
	for i in party_combat_hp.size():
		if not is_member_alive(i):
			continue
		var back: bool = GameState.is_member_back_row(i)
		if front_only and back:
			continue
		if back_only and not back:
			continue
		alive.append(i)
	return alive

func pick_enemy_target_from_indices(indices: Array[int], attacker_slot: int = -1) -> int:
	if indices.is_empty():
		return -1
	var best: int = indices[0]
	for i in indices:
		var score: float = _enemy_target_score(i, attacker_slot)
		var best_score: float = _enemy_target_score(best, attacker_slot)
		if score > best_score:
			best = i
		elif is_equal_approx(score, best_score) and i < best:
			best = i
	return best

func _enemy_target_bias(attacker_slot: int) -> String:
	var data: Resource = get_enemy_data_at(attacker_slot) if attacker_slot >= 0 else current_enemy_data
	if data == null or not ("threat_target_bias" in data):
		return THREAT_TARGET_BIAS_MAX
	var bias: String = str(data.threat_target_bias)
	if bias.is_empty():
		return THREAT_TARGET_BIAS_MAX
	return bias

func _enemy_target_score(member_index: int, attacker_slot: int) -> float:
	var bias: String = _enemy_target_bias(attacker_slot)
	match bias:
		THREAT_TARGET_BIAS_LOWEST_HP:
			if member_index < 0 or member_index >= party_max_hp.size():
				return 0.0
			var max_hp: int = maxi(1, party_max_hp[member_index])
			var hp: int = party_combat_hp[member_index] if member_index < party_combat_hp.size() else 0
			return 1.0 - float(hp) / float(max_hp)
		THREAT_TARGET_BIAS_BACK_ROW:
			var score: float = _threat_of(member_index)
			return score * (2.0 if GameState.is_member_back_row(member_index) else 0.55)
		THREAT_TARGET_BIAS_LOWEST_THREAT:
			return 1000.0 - _threat_of(member_index)
		_:
			return _threat_of(member_index)

func _threat_of(member_index: int) -> float:
	if member_index < 0 or member_index >= party_threat.size():
		return 0.0
	return party_threat[member_index]

# Threat を加算（P3-D104）。member が範囲外なら無視。
func add_threat(member_index: int, amount: float) -> void:
	if member_index < 0 or member_index >= party_threat.size():
		return
	party_threat[member_index] = maxf(0.0, party_threat[member_index] + amount)

# 挑発（防御スロット等）。当該メンバーへ大きな Threat スパイクを与え矢面に立たせる。
func apply_taunt(member_index: int) -> void:
	add_threat(member_index, THREAT_TAUNT)

# status tick ごとに Threat を基礎値へ向けて減衰させる（挑発が時間で薄れる）。
func decay_threat() -> void:
	for i in party_threat.size():
		var base: float = _job_threat_base(i)
		party_threat[i] = base + (party_threat[i] - base) * THREAT_DECAY

func capture_rewards() -> void:
	capture_rewards_at(active_enemy_index)

func capture_rewards_at(slot: int) -> void:
	var data: Resource = get_enemy_data_at(slot)
	if data == null:
		return
	last_exp_reward = swarm_exp[slot] if slot >= 0 and slot < swarm_exp.size() else _scaled_exp
	last_gold_reward = data.gold_reward

func apply_status(
	unit_id: String,
	effect_id: String,
	stacks: int = 1,
	source_attack: int = 0
) -> bool:
	if unit_id.begins_with("party_"):
		var member_idx: int = int(unit_id.substr(6))
		## 死者への付与禁止（撃破後 on_hit・DoT 残骸の誤発火防止）。
		if not is_member_alive(member_idx):
			return false
		if _ArmorStatResolver.member_immune_to_status(member_idx, effect_id):
			return false
		## 有益バフ以外はパーティ異常耐性（ヴァルデン鉄誓など）で減衰。
		if not StatusResolver.is_beneficial_status(effect_id):
			if not _party_passes_incoming_status_roll():
				return false
		return _status_resolver.apply_status(unit_id, effect_id, stacks, source_attack)
	var duration_override: int = -1
	if unit_id.begins_with("enemy_"):
		var slot: int = int(unit_id.substr(6))
		## 章テーマ: 敵の incoming_status_chance_mult で付与を減衰（ミスト等）。
		if not _enemy_passes_incoming_status_roll(slot):
			return false
		if effect_id == "stun" and enemy_cc_tier_at(slot) == "boss":
			duration_override = BalanceConfig.CC_STUN_DURATION_TICKS_BOSS
	return _status_resolver.apply_status(unit_id, effect_id, stacks, source_attack, duration_override)


func _enemy_passes_incoming_status_roll(slot: int) -> bool:
	var data: Resource = get_enemy_data_at(slot)
	if data == null:
		return true
	var mult: float = 1.0
	if "incoming_status_chance_mult" in data:
		mult = float(data.incoming_status_chance_mult)
	if mult >= 0.999:
		return true
	if mult <= 0.0:
		return false
	return randf() <= mult


func _party_passes_incoming_status_roll() -> bool:
	var mult: float = CombatPassives.party_incoming_status_chance_mult()
	if mult >= 0.999:
		return true
	if mult <= 0.0:
		return false
	return randf() <= mult

func apply_status_to_active_enemy(
	effect_id: String,
	stacks: int = 1,
	source_attack: int = 0
) -> bool:
	return apply_status(get_active_enemy_status_unit_id(), effect_id, stacks, source_attack)

func apply_status_to_enemy_slot(
	slot: int,
	effect_id: String,
	stacks: int = 1,
	source_attack: int = 0
) -> bool:
	return apply_status(enemy_status_unit_id(slot), effect_id, stacks, source_attack)


## "boss" | "elite" | "normal"（P3-BAL-BOSS-CC-RESIST-001）。
func enemy_cc_tier_at(slot: int) -> String:
	var data: Resource = get_enemy_data_at(slot)
	if data == null:
		return "normal"
	var et: int = int(data.enemy_type)
	if et == Enums.EnemyType.BOSS:
		return "boss"
	if et == Enums.EnemyType.ELITE:
		return "elite"
	return "normal"


func enemy_cc_skip_mult_at(slot: int) -> float:
	match enemy_cc_tier_at(slot):
		"boss":
			return BalanceConfig.CC_SKIP_MULT_BOSS
		"elite":
			return BalanceConfig.CC_SKIP_MULT_ELITE
		_:
			return 1.0


func should_enemy_skip_action_at(slot: int) -> bool:
	return _status_resolver.should_skip_action(
		enemy_status_unit_id(slot), enemy_cc_skip_mult_at(slot)
	)

func should_enemy_skip_action() -> bool:
	return should_enemy_skip_action_at(active_enemy_index)

## Status-forced skip only (no RNG). Safe for Now Playing / turn-order badges.
func peek_enemy_status_skip_at(slot: int) -> bool:
	return _status_resolver.has_guaranteed_action_skip(
		enemy_status_unit_id(slot), enemy_cc_skip_mult_at(slot)
	)

func get_enemy_skip_action_label_at(slot: int) -> String:
	return _status_resolver.get_skip_action_label(enemy_status_unit_id(slot))

func get_enemy_skip_action_label() -> String:
	return get_enemy_skip_action_label_at(active_enemy_index)

func apply_damage_to_enemy_slot(slot: int, amount: int) -> void:
	if not is_in_combat:
		return
	if slot < 0 or slot >= swarm_hp.size():
		return
	swarm_hp[slot] = max(0, swarm_hp[slot] - amount)
	if slot == active_enemy_index:
		current_enemy_hp = swarm_hp[slot]

func get_enemy_id_at(slot: int) -> String:
	if slot < 0 or slot >= swarm_data.size():
		return ""
	var data: Resource = swarm_data[slot]
	if data == null:
		return ""
	return str(data.id)

func get_enemy_hp_ratio_at(slot: int) -> float:
	if slot < 0 or slot >= swarm_max_hp.size():
		return 1.0
	var maxhp: int = swarm_max_hp[slot]
	if maxhp <= 0:
		return 0.0
	return float(swarm_hp[slot]) / float(maxhp)

func get_enemy_phase_index(slot: int) -> int:
	if slot < 0 or slot >= enemy_phase_index.size():
		return 0
	return enemy_phase_index[slot]

func set_enemy_phase_index(slot: int, phase_index: int) -> void:
	if slot >= 0 and slot < enemy_phase_index.size():
		enemy_phase_index[slot] = maxi(0, phase_index)

func tick_all_statuses() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for slot in swarm_hp.size():
		if is_enemy_slot_alive(slot):
			results.append_array(_status_resolver.tick_unit(enemy_status_unit_id(slot)))
	for i in party_combat_hp.size():
		## 敵と同様、生存者のみ tick（死者の DoT ログ／VFXのみを防ぐ）。
		if is_member_alive(i):
			results.append_array(_status_resolver.tick_unit("party_%d" % i))
	return results

func should_member_skip_action_at(member_index: int) -> bool:
	if member_index < 0 or member_index >= party_combat_hp.size():
		return false
	_member_passive_skip.erase(member_index)
	if _status_resolver.should_skip_action("party_%d" % member_index):
		return true
	var member: Resource = GameState.get_combatant(member_index)
	var chance: float = CombatPassives.action_skip_chance_for_member(member)
	if chance > 0.0 and randf() < chance:
		_member_passive_skip[member_index] = true
		return true
	return false


## Status-forced skip only (no RNG / no passive skip). Safe for UI preview.
func peek_member_status_skip_at(member_index: int) -> bool:
	if member_index < 0 or member_index >= party_combat_hp.size():
		return false
	return _status_resolver.has_guaranteed_action_skip("party_%d" % member_index)

func get_member_skip_action_label_at(member_index: int) -> String:
	if member_index < 0 or member_index >= party_combat_hp.size():
		return ""
	if bool(_member_passive_skip.get(member_index, false)):
		_member_passive_skip.erase(member_index)
		var member: Resource = GameState.get_combatant(member_index)
		var label: String = CombatPassives.action_skip_label_for_member(member)
		if not label.is_empty():
			return label
		return "パッシブ"
	return _status_resolver.get_skip_action_label("party_%d" % member_index)

# メンバーの遺物効果倍率（P3-D090）。メイン編成のみ（助っ人は遺物なし）。
func _member_relic_effects(member_index: int) -> Dictionary:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return {"outgoing_mult": 1.0, "incoming_mult": 1.0, "speed_mult": 1.0}
	var member: Resource = GameState.party_members[member_index]
	return CombatPassives.stat_multipliers_for_member(member, member_index)

func enemy_slot_has_debuff(slot: int) -> bool:
	if slot < 0 or not is_enemy_slot_alive(slot):
		return false
	for status_id: String in DEBUFF_STATUS_IDS:
		if get_enemy_status_stacks_at(slot, status_id) > 0:
			return true
	return false


## 敵スロットにバフ（empower／guard 等）があるか。
func enemy_slot_has_buff(slot: int) -> bool:
	if slot < 0 or not is_enemy_slot_alive(slot):
		return false
	for raw: Dictionary in get_enemy_status_list_at(slot):
		var sid: String = str(raw.get("effect_id", ""))
		if sid.is_empty():
			continue
		if CombatVfxManager.is_buff_status(sid):
			return true
	return false


func get_member_outgoing_damage_multiplier(
	member_index: int,
	action_range: String = "",
	is_skill: bool = false,
	attack_element: String = "",
	target_slot: int = -1
) -> float:
	var mult: float = _status_resolver.get_outgoing_damage_multiplier("party_%d" % member_index)
	mult *= float(_member_relic_effects(member_index).get("outgoing_mult", 1.0))
	var hp_ratio: float = 1.0
	if member_index < party_max_hp.size() and party_max_hp[member_index] > 0:
		hp_ratio = float(party_combat_hp[member_index]) / float(party_max_hp[member_index])
	mult *= float(CombatPassives.character_stat_modifiers_for_member(member_index, hp_ratio).get("outgoing_mult", 1.0))
	mult *= CombatPassives.relic_outgoing_hp_tier_mult(member_index, hp_ratio)
	mult *= death_save_outgoing_mult_for(member_index)
	mult *= CombatPassives.party_outgoing_mult()
	if GameState.is_pet_combatant(member_index) and is_member_alive(member_index):
		mult *= CombatPassives.pet_outgoing_mult_from_party()
	mult *= 1.0 + CombatSynergy.compute_physical_bonus(GameState.party_members)
	mult *= float(CombatSynergy.compute_role_bonuses(GameState.party_members).get("outgoing_mult", 1.0))
	if not action_range.is_empty():
		mult *= GameState.formation_range_outgoing_multiplier(member_index, action_range)
	mult *= _EvolutionTraits.member_outgoing_mult(member_index, is_skill, attack_element)
	if not attack_element.is_empty():
		var elem_any: float = float(
			CombatPassives.character_stat_modifiers_for_member(member_index, hp_ratio).get(
				"elemental_outgoing_mult", 1.0
			)
		)
		if elem_any > 0.0 and not is_equal_approx(elem_any, 1.0):
			mult *= elem_any
		var elem_mults: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(member_index).get("element_outgoing_mult", {})
		if elem_mults is Dictionary and elem_mults.has(attack_element):
			mult *= float(elem_mults[attack_element])
	if target_slot >= 0:
		var present_statuses: Array = []
		for status_id: String in DEBUFF_STATUS_IDS:
			if get_enemy_status_stacks_at(target_slot, status_id) > 0:
				present_statuses.append(status_id)
		var mark_focus: float = CombatPassives.relic_mark_focus_outgoing_mult(member_index, present_statuses)
		if not is_equal_approx(mark_focus, 1.0):
			mult *= mark_focus
		if not present_statuses.is_empty():
			mult *= CombatPassives.outgoing_vs_status_mult_for_member(member_index, present_statuses)
		if enemy_slot_has_buff(target_slot):
			mult *= CombatPassives.outgoing_vs_buff_mult_for_member(member_index)
	var boss_mult: float = CombatPassives.weapon_outgoing_vs_boss_mult(member_index)
	if target_slot >= 0 and not is_equal_approx(boss_mult, 1.0):
		var ed: Resource = get_enemy_data_at(target_slot)
		if ed != null and int(ed.enemy_type) == Enums.EnemyType.BOSS:
			mult *= boss_mult
	mult *= _AbyssWeaponEffects.outgoing_multiplier(member_index, target_slot, hp_ratio)
	mult *= _EquipmentSetBonuses.outgoing_mult(member_index)
	return mult

# 被ダメ補正（防御=guard 等）。1.0=等倍。P3-D085 で配線。遺物 incoming_mult も乗算（P3-D090）。
## attacker_slot: 敵スロット（血契など攻撃側状態参照。不明時は -1）。
func get_member_incoming_damage_multiplier(member_index: int, attacker_slot: int = -1) -> float:
	var mult: float = _status_resolver.get_incoming_damage_multiplier("party_%d" % member_index)
	mult *= float(_member_relic_effects(member_index).get("incoming_mult", 1.0))
	mult *= float(CombatPassives.character_stat_modifiers_for_member(member_index).get("incoming_mult", 1.0))
	mult *= CombatPassives.party_incoming_mult()
	mult *= clampf(party_temp_incoming_mult, 0.05, 1.0)
	## 分かれ道・戦力強化（次フロア限定・DungeonScene が同期）。
	if floor_choice_incoming_mult > 0.0 and floor_choice_incoming_mult < 1.0:
		mult *= floor_choice_incoming_mult
	if bool(_death_save_shield_until_msec.has(member_index)):
		if Time.get_ticks_msec() <= int(_death_save_shield_until_msec[member_index]):
			var save_def: Dictionary = CombatPassives.death_save_def_for_member(member_index)
			mult *= float(save_def.get("death_save_incoming_mult", 0.35))
		else:
			_death_save_shield_until_msec.erase(member_index)
	# ロール（堅守）ボーナス（P3-D097・party 全体）
	mult *= float(CombatSynergy.compute_role_bonuses(GameState.party_members).get("incoming_mult", 1.0))
	# 探索方針（安全優先）被ダメ軽減（P3-D098）
	mult *= GameState.exploration_incoming_multiplier()
	# 天候の被ダメ倍率（P3-D101）。霧は回復／毒側へ移したため通常は 1.0。
	mult *= CombatWeather.incoming_multiplier(GameState.get_weather())
	# 陣形（後列＝被ダメ軽減）（P3-D106）
	mult *= GameState.formation_incoming_multiplier(member_index)
	# 散開/密集（同列人数・P3-D106e）
	mult *= CombatFormation.density_incoming_multiplier(
		member_index, party_combat_hp.size(), Callable(self, "is_member_alive")
	)
	mult *= _EvolutionTraits.member_incoming_mult(member_index)
	mult *= _AbyssWeaponEffects.incoming_shell_multiplier(member_index)
	mult *= _EquipmentSetBonuses.incoming_mult(member_index)
	## ビルドL: 庇護外套・呪縛法衣・血契（攻撃側状態）（P3-EQ-LEG-BUILD-001）
	var most_injured: int = get_most_injured_member_index()
	mult *= CombatPassives.cover_ally_incoming_mult_for(member_index, most_injured)
	mult *= CombatPassives.hexweave_incoming_mult_for_member(
		member_index, count_unique_enemy_debuff_types()
	)
	if attacker_slot >= 0:
		var attacker_statuses: Array = []
		for status_id: String in DEBUFF_STATUS_IDS:
			if get_enemy_status_stacks_at(attacker_slot, status_id) > 0:
				attacker_statuses.append(status_id)
		mult *= CombatPassives.incoming_vs_attacker_status_mult(member_index, attacker_statuses)
	return mult


## 場の生存敵が持つデバフ種類のユニーク数（呪縛法衣）。
func count_unique_enemy_debuff_types() -> int:
	var seen: Dictionary = {}
	for slot: int in get_living_enemy_indices():
		for status_id: String in DEBUFF_STATUS_IDS:
			if get_enemy_status_stacks_at(slot, status_id) > 0:
				seen[status_id] = true
	return seen.size()

func get_density_log_tag(member_index: int) -> String:
	return CombatFormation.density_log_tag(
		member_index, party_combat_hp.size(), Callable(self, "is_member_alive")
	)

# ロール編成ボーナス（P3-D097）。回復量倍率 / 会心率加算。
func get_party_role_heal_multiplier() -> float:
	return float(CombatSynergy.compute_role_bonuses(GameState.party_members).get("heal_mult", 1.0))

func get_party_role_crit_add() -> float:
	return float(CombatSynergy.compute_role_bonuses(GameState.party_members).get("crit_add", 0.0))

func get_enemy_incoming_damage_multiplier() -> float:
	return get_enemy_incoming_damage_multiplier_at(active_enemy_index)

func get_enemy_incoming_damage_multiplier_at(slot: int) -> float:
	return _status_resolver.get_incoming_damage_multiplier(enemy_status_unit_id(slot))

# アクティブ敵の DEF 減少率（armor_break・P3-D107）。0.0=なし。
func get_enemy_defense_reduction() -> float:
	return get_enemy_defense_reduction_at(active_enemy_index)

func get_enemy_defense_reduction_at(slot: int) -> float:
	return _status_resolver.get_defense_reduction(enemy_status_unit_id(slot))


## 味方の DEF 減少率（armor_break 等）。0.0=なし。敵側と同型。
func get_member_defense_reduction(member_index: int) -> float:
	if member_index < 0 or member_index >= party_combat_hp.size():
		return 0.0
	return _status_resolver.get_defense_reduction("party_%d" % member_index)

# 同系統タグ・シナジー（P3-D095）。指定属性をパーティで複数人が共有する時の与ダメボーナス（0.0=なし）。
func get_element_synergy_bonus(element: String) -> float:
	if element.is_empty():
		return 0.0
	return float(CombatSynergy.compute_element_bonuses(GameState.party_members).get(element, 0.0))

func get_enemy_status_stacks(effect_id: String) -> int:
	return get_enemy_status_stacks_at(active_enemy_index, effect_id)

func get_enemy_status_stacks_at(slot: int, effect_id: String) -> int:
	return _status_resolver.get_status_stacks(enemy_status_unit_id(slot), effect_id)

# 状態異常コンボ起爆: アクティブ敵の指定状態を消費しスタック数を返す（P3-D089）。
func consume_enemy_status(effect_id: String) -> int:
	return consume_enemy_status_at(active_enemy_index, effect_id)

func consume_enemy_status_at(slot: int, effect_id: String) -> int:
	return _status_resolver.consume_status(enemy_status_unit_id(slot), effect_id)

func get_combat_ct_elapsed() -> float:
	return _combat_ct_elapsed

func get_attrition_step() -> int:
	return BalanceConfig.attrition_step(_combat_ct_elapsed)

func get_attrition_outgoing_mult() -> float:
	return BalanceConfig.attrition_outgoing_mult(_combat_ct_elapsed)

func get_enemy_outgoing_damage_multiplier() -> float:
	return get_enemy_outgoing_damage_multiplier_at(active_enemy_index)

func get_enemy_outgoing_damage_multiplier_at(slot: int) -> float:
	return (
		_status_resolver.get_outgoing_damage_multiplier(enemy_status_unit_id(slot))
		* get_attrition_outgoing_mult()
	)

func get_enemy_status_summary() -> String:
	return get_enemy_status_summary_at(active_enemy_index)

func get_enemy_status_summary_at(slot: int) -> String:
	return _status_resolver.get_active_status_summary(enemy_status_unit_id(slot))

func get_enemy_status_list() -> Array[Dictionary]:
	return get_enemy_status_list_at(active_enemy_index)

func get_enemy_status_list_at(slot: int) -> Array[Dictionary]:
	return _status_resolver.get_active_status_list(enemy_status_unit_id(slot))

func get_member_status_stacks(member_index: int, effect_id: String) -> int:
	return _status_resolver.get_status_stacks("party_%d" % member_index, effect_id)


func member_has_beneficial_buff(member_index: int) -> bool:
	return _status_resolver.has_beneficial_status("party_%d" % member_index)


func party_has_any_beneficial_buff() -> bool:
	for i: int in party_combat_hp.size():
		if not is_member_alive(i):
			continue
		if member_has_beneficial_buff(i):
			return true
	return false


## 味方の有益バフを除去。除去した effect_id 一覧。
func dispel_member_buffs(member_index: int) -> PackedStringArray:
	return _status_resolver.remove_beneficial_statuses("party_%d" % member_index)

# 味方コンボ起爆: メンバー自身の指定状態を消費（P3-D109）。
func consume_member_status(member_index: int, effect_id: String) -> int:
	return _status_resolver.consume_status("party_%d" % member_index, effect_id)

func get_member_status_summary(member_index: int) -> String:
	return _status_resolver.get_active_status_summary("party_%d" % member_index)

func get_member_status_list(member_index: int) -> Array[Dictionary]:
	return _status_resolver.get_active_status_list("party_%d" % member_index)

# ---- Initiative (P3-D019 Phase 1 + Phase 2) ----

# 単体メンバーのイニシアチブ（武器attack_speed×ジョブ補正×Affix）。死亡は 0。
func get_member_initiative_score(i: int) -> float:
	if not is_member_alive(i):
		return 0.0
	var spd: float = 1.0
	var weapon_inst: Resource = GameState.get_member_equipped_weapon(i)
	if weapon_inst != null and not weapon_inst.weapon_id.is_empty() and weapon_inst.attack_speed > 0.0:
		spd = weapon_inst.attack_speed
	var job_mod: float = 1.0
	if i < GameState.party_members.size():
		var member: Resource = GameState.party_members[i]
		if member != null and not member.job_id.is_empty():
			var job_data: Resource = DataRegistry.get_job_data(member.job_id)
			if job_data != null and job_data.base_initiative_modifier > 0.0:
				job_mod = job_data.base_initiative_modifier
	var affix_mult: float = float(_AffixStatCalculator.get_bonuses(i).get("attack_speed_mult_add", 0.0))
	var relic_speed: float = float(_member_relic_effects(i).get("speed_mult", 1.0))
	var set_speed: float = _EquipmentSetBonuses.speed_mult(i)
	return spd * job_mod * (1.0 + affix_mult) * relic_speed * set_speed

func get_party_initiative_score() -> float:
	var best: float = 0.0
	for i in party_combat_hp.size():
		best = maxf(best, get_member_initiative_score(i))
	return best if best > 0.0 else 1.0

func get_enemy_initiative_score() -> float:
	if current_enemy_data == null:
		return 1.0
	return current_enemy_data.attack_speed if current_enemy_data.attack_speed > 0.0 else 1.0

# 敵スロット別イニシアチブ（attack_speed × ソロ密度速度 × ボス人数速度）。
func get_enemy_initiative_score_at(slot: int) -> float:
	var d: Resource = get_enemy_data_at(slot)
	if d == null:
		return 1.0
	var base: float = d.attack_speed if d.attack_speed > 0.0 else 1.0
	var mult: float = _swarm_density_spd_mult
	if int(d.enemy_type) == Enums.EnemyType.BOSS:
		mult *= BalanceConfig.boss_party_speed_mult(GameState.combatant_count())
	return base * mult

# ---- CT/ATB スケジューラ（P3-D084） ----

func _ct_unit_key(kind: String, index: int) -> String:
	return "%s_%d" % [kind, index]

func _ct_parse_key(key: String) -> Dictionary:
	var sep: int = key.rfind("_")
	return {"kind": key.substr(0, sep), "index": int(key.substr(sep + 1))}

# ユニットの行動 CT。速度（initiative_score）が速いほど短い＝多く動ける。
func get_unit_action_ct(kind: String, index: int) -> float:
	var spd: float = 1.0
	if kind == "party":
		spd = get_member_initiative_score(index)
	else:
		spd = get_enemy_initiative_score_at(index)
	if spd <= 0.0:
		spd = 1.0
	return BASE_ACTION_CT / spd

# 現在の生存ユニット一覧（味方→群れ敵の順）。各要素: {"kind","index"}。
func get_living_units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in party_combat_hp.size():
		if is_member_alive(i):
			out.append({"kind": "party", "index": i})
	for slot in swarm_hp.size():
		if is_enemy_slot_alive(slot):
			out.append({"kind": "enemy", "index": slot})
	return out

# 戦闘開始時に全生存ユニットの CT を初期化（満タン＝1回分）。
func init_ct() -> void:
	unit_ct.clear()
	for u in get_living_units():
		unit_ct[_ct_unit_key(u["kind"], u["index"])] = get_unit_action_ct(u["kind"], u["index"])
	_last_ct_step = 0.0

# unit_ct のキー集合を現在の生存ユニットへ同期（新規=満タン追加 / 死亡=除去）。
func _sync_ct_units() -> void:
	var living: Dictionary = {}
	for u in get_living_units():
		var key: String = _ct_unit_key(u["kind"], u["index"])
		living[key] = true
		if not unit_ct.has(key):
			unit_ct[key] = get_unit_action_ct(u["kind"], u["index"])
	for key in unit_ct.keys():
		if not living.has(key):
			unit_ct.erase(key)

# 次に行動するユニットへクロックを進める。{"kind","index"} を返す（生存ユニット無し={}）。
# 全ユニットの CT を最小残量ぶん減算し、0 に達したユニットを選ぶ（同時0は味方優先→index昇順）。
func advance_to_next_actor() -> Dictionary:
	_sync_ct_units()
	if unit_ct.is_empty():
		_last_ct_step = 0.0
		return {}
	var min_rem: float = INF
	for key in unit_ct:
		min_rem = minf(min_rem, unit_ct[key])
	if min_rem < 0.0:
		min_rem = 0.0
	for key in unit_ct:
		unit_ct[key] -= min_rem
	_last_ct_step = min_rem
	_combat_ct_elapsed += min_rem
	var ready: Array[Dictionary] = []
	for key in unit_ct:
		if unit_ct[key] <= _CT_EPSILON:
			var info: Dictionary = _ct_parse_key(key)
			ready.append({"key": key, "kind": info["kind"], "index": info["index"]})
	ready.sort_custom(func(a, b):
		if a["kind"] != b["kind"]:
			return a["kind"] == "party"
		return a["index"] < b["index"])
	var chosen: Dictionary = ready[0]
	unit_ct[chosen["key"]] = get_unit_action_ct(chosen["kind"], chosen["index"])
	return {"kind": chosen["kind"], "index": chosen["index"]}

# 直近 advance_to_next_actor で進めた CT 量。
func consume_last_ct_step() -> float:
	return _last_ct_step

# CT 残量の昇順（次に動く順）でユニットを返す。CT 表示UI用。
# 各要素: {"kind","index","ct"}。同値は味方優先→index 昇順。
func get_ct_order() -> Array[Dictionary]:
	_sync_ct_units()
	var entries: Array[Dictionary] = []
	for key in unit_ct:
		var info: Dictionary = _ct_parse_key(key)
		entries.append({"kind": info["kind"], "index": info["index"], "ct": float(unit_ct[key])})
	entries.sort_custom(func(a, b):
		if not is_equal_approx(a["ct"], b["ct"]):
			return a["ct"] < b["ct"]
		if a["kind"] != b["kind"]:
			return a["kind"] == "party"
		return a["index"] < b["index"])
	return entries

# 行動準備度（1=次に動きやすい / 0=行動直後）。パーティカード CT バー用。
func get_unit_ct_readiness(kind: String, index: int) -> float:
	_sync_ct_units()
	var key: String = _ct_unit_key(kind, index)
	if not unit_ct.has(key):
		return 0.0
	var full: float = get_unit_action_ct(kind, index)
	if full <= _CT_EPSILON:
		return 1.0
	return clampf(1.0 - float(unit_ct[key]) / full, 0.0, 1.0)

# ── 詠唱 / Action Lock（P3-D112）──

func _cast_unit_key(kind: String, index: int) -> String:
	return "%s_%d" % [kind, index]

func has_pending_cast(kind: String, index: int) -> bool:
	return _pending_casts.has(_cast_unit_key(kind, index))

func get_pending_cast(kind: String, index: int) -> Dictionary:
	var key: String = _cast_unit_key(kind, index)
	if not _pending_casts.has(key):
		return {}
	return _pending_casts[key].duplicate()

func begin_party_cast(member_index: int, skill_id: String, target_slot: int, turns_left: int) -> void:
	_pending_casts[_cast_unit_key("party", member_index)] = {
		"skill_id": skill_id,
		"target_slot": target_slot,
		"turns_left": maxi(1, turns_left),
	}

func begin_enemy_cast(slot: int, skill_id: String, turns_left: int) -> void:
	_pending_casts[_cast_unit_key("enemy", slot)] = {
		"skill_id": skill_id,
		"turns_left": maxi(1, turns_left),
	}

# 詠唱を1段進める。戻り値: "chant"（継続）/ "ready"（発動可）/ "none"
# P3-D112-1: ceil(cast_time) 回の自分番を詠唱消費 → 先に減算し 0 で ready（off-by-one 防止）。
func advance_pending_cast(kind: String, index: int) -> String:
	var key: String = _cast_unit_key(kind, index)
	if not _pending_casts.has(key):
		return "none"
	var pending: Dictionary = _pending_casts[key]
	var left: int = int(pending.get("turns_left", 0))
	if left <= 0:
		return "ready"
	left -= 1
	pending["turns_left"] = left
	_pending_casts[key] = pending
	if left <= 0:
		return "ready"
	return "chant"

func clear_pending_cast(kind: String, index: int) -> void:
	_pending_casts.erase(_cast_unit_key(kind, index))

func clear_pending_casts_for_kind(kind: String) -> void:
	var prefix: String = "%s_" % kind
	for key in _pending_casts.keys():
		if str(key).begins_with(prefix):
			_pending_casts.erase(key)
