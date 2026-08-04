class_name EquipmentPower
extends RefCounted

## 装備の非表示総合力（P3-EQ-POWER-RECOMMEND-001）。
## おすすめ／鍛冶強化一覧の比較 SSOT。UI 表示はしない。
## 案A（2026-08-02）: 主ステ寄り。速度・会心の倍率支配を避ける。
## 案B（2026-08-04）: レア度をソフト加点（N Lv低が E Lv高を逆転しにくくする）。同点はレア→装備Lv→炉研ぎ。

const _EquipmentEnhancer := preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _JobStatCalculator := preload("res://scripts/equipment/JobStatCalculator.gd")
const _Mods := preload("res://scripts/equipment/EquipmentRandomMods.gd")

## 防具・装飾の HP を防御／攻撃と同列にしない（HPロール単体で高レア高Lvを逆転させない）。
const ARMOR_HP_WEIGHT: float = 0.25
## 装飾会心は攻撃点への軽い換算（倍率乗算はしない）。
const ACCESSORY_CRIT_AS_ATTACK: float = 40.0
## レア1段階あたりの比較加点（主ステに加算）。COMMON→EPIC で +96 程度。
## 同帯の攻撃ロール逆転を抑えつつ、終盤 COMMON が高ベースなら序盤 EPIC に勝ち得る。
const RARITY_TIER_BONUS: float = 48.0


## category: weapon / armor / accessory
## member: 武器の職適性倍率に使用（null なら ×1）。
static func score(item: Resource, category: String, member: Resource = null) -> float:
	if item == null:
		return 0.0
	var main: float = 0.0
	match category:
		"weapon":
			main = _weapon_score(item, member)
		"armor":
			main = _armor_score(item)
		"accessory":
			main = _accessory_score(item)
		_:
			return 0.0
	return main + _rarity_bonus(item)


## 参考用（キャラ総合戦力と同型）。おすすめ比較には使わない。
static func combat_contribution(
	hp: float, defense: float, attack: float, speed: float, crit_rate: float, crit_damage: float
) -> float:
	var spd: float = maxf(0.0, speed)
	var crt: float = clampf(crit_rate, 0.0, 1.0)
	var cdmg: float = maxf(1.0, crit_damage)
	var offense: float = attack * spd * (1.0 + crt * (cdmg - 1.0))
	return hp + defense + offense


static func _rarity_bonus(item: Resource) -> float:
	return float(_EquipmentEnhancer.item_rarity(item)) * RARITY_TIER_BONUS


static func _weapon_score(weapon: Resource, member: Resource) -> float:
	## 実効攻撃のみ（速度・会心は乗算しない）。
	var atk: float = float(_EquipmentEnhancer.get_effective_attack(weapon))
	if member != null and "weapon_id" in weapon:
		var wdata: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
		atk *= _JobStatCalculator.get_preferred_weapon_multiplier(member, wdata)
	return atk


static func _armor_score(armor: Resource) -> float:
	var defense: float = float(_EquipmentEnhancer.effective_armor_defense(armor))
	var hp: float = float(_EquipmentEnhancer.effective_armor_hp(armor))
	return defense + hp * ARMOR_HP_WEIGHT


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
	return hp * ARMOR_HP_WEIGHT + defense + atk + clampf(crt, 0.0, 1.0) * ACCESSORY_CRIT_AS_ATTACK
