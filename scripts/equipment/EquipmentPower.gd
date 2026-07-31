class_name EquipmentPower
extends RefCounted

## 装備の非表示総合力（P3-EQ-POWER-RECOMMEND-001）。
## 式はキャラ総合戦力（P3-UI-COMBAT-POWER-001）の寄与近似。
## UI 表示はしない。おすすめ装備の比較 SSOT。

const _EquipmentEnhancer := preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _JobStatCalculator := preload("res://scripts/equipment/JobStatCalculator.gd")
const _Mods := preload("res://scripts/equipment/EquipmentRandomMods.gd")


## category: weapon / armor / accessory
## member: 武器の職適性倍率に使用（null なら ×1）。
static func score(item: Resource, category: String, member: Resource = null) -> float:
	if item == null:
		return 0.0
	match category:
		"weapon":
			return _weapon_score(item, member)
		"armor":
			return _armor_score(item)
		"accessory":
			return _accessory_score(item)
		_:
			return 0.0


## HP + 防御 + 攻撃×速度×(1+会心率×(会心ダメ−1))
static func combat_contribution(hp: float, defense: float, attack: float, speed: float, crit_rate: float, crit_damage: float) -> float:
	var spd: float = maxf(0.0, speed)
	var crt: float = clampf(crit_rate, 0.0, 1.0)
	var cdmg: float = maxf(1.0, crit_damage)
	var offense: float = attack * spd * (1.0 + crt * (cdmg - 1.0))
	return hp + defense + offense


static func _weapon_score(weapon: Resource, member: Resource) -> float:
	var atk: float = float(_EquipmentEnhancer.get_effective_attack(weapon))
	var wdata: Resource = null
	if "weapon_id" in weapon:
		wdata = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	if member != null:
		atk *= _JobStatCalculator.get_preferred_weapon_multiplier(member, wdata)
	var spd: float = _WeaponStatResolver.resolve_attack_speed(weapon, wdata)
	var crt: float = _WeaponStatResolver.resolve_critical_rate(weapon, wdata)
	var cdmg: float = _WeaponStatResolver.resolve_critical_damage(weapon)
	## 武器は攻撃寄与のみ（HP/DEF なし）。
	return combat_contribution(0.0, 0.0, atk, spd, crt, cdmg)


static func _armor_score(armor: Resource) -> float:
	var defense: float = float(_EquipmentEnhancer.effective_armor_defense(armor))
	var hp: float = float(_EquipmentEnhancer.effective_armor_hp(armor))
	## 防具は耐久寄与のみ。
	return combat_contribution(hp, defense, 0.0, 1.0, 0.0, 1.5)


static func _accessory_score(accessory: Resource) -> float:
	var data: Resource = null
	if "accessory_id" in accessory and not str(accessory.accessory_id).is_empty():
		data = DataRegistry.get_accessory_data(str(accessory.accessory_id))
	var hp: float = 0.0
	var atk: float = 0.0
	var defense: float = 0.0
	var crt: float = 0.0
	if data != null:
		## effective_* はフィールド反映済みの random_mods（HP/ATK/DEF/会心）を含む。
		## sum_kind の再加算は二重評価になる（P3-FIX-EQ-META-AUDIT-A-001）。
		_Mods.ensure_migrated(accessory)
		hp = float(_EquipmentEnhancer.effective_accessory_int_bonus(accessory, "hp_bonus", data))
		atk = float(_EquipmentEnhancer.effective_accessory_int_bonus(accessory, "attack_bonus", data))
		defense = float(
			_EquipmentEnhancer.effective_accessory_int_bonus(accessory, "defense_bonus", data)
		)
		crt = float(
			_EquipmentEnhancer.effective_accessory_float_bonus(accessory, "crit_rate_bonus", data)
		)
	## 装飾は速度1.0・会心ダメ既定で攻撃寄与を近似。レアは同点時のみ別途 tiebreak。
	var cdmg: float = BalanceConfig.DEFAULT_WEAPON_CRITICAL_DAMAGE
	return combat_contribution(hp, defense, atk, 1.0, crt, cdmg)
