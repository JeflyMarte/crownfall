class_name CombatEnemyTraits
extends RefCounted
## 雑魚パッシブ特性（P3-BAL-ENEMY-TRAIT-001 / Decision 118）。
## スキル・ステ数値・T6/T7軽減とは別枠。


const TRAIT_THORNS := "thorns"
const TRAIT_DEATH_NOVA := "death_nova"
const TRAIT_PACK_RAGE := "pack_rage"
const TRAIT_FRONT_FOCUS := "front_focus"
const TRAIT_BACK_FOCUS := "back_focus"
const TRAIT_LIFESTEAL := "lifesteal"
const TRAIT_TOUCH_AILMENT := "touch_ailment"
const TRAIT_LOW_HP_HASTE := "low_hp_haste"
const TRAIT_DOUBLE_TAP := "double_tap"
const TRAIT_SKILL_TAX := "skill_tax"

const THORNS_ATK_FRAC := 0.25
const DEATH_NOVA_ATK_FRAC := 0.35
const LIFESTEAL_RATIO_DEFAULT := 0.30
const TOUCH_AILMENT_CHANCE := 0.25
const LOW_HP_HASTE_RATIO := 0.30
const LOW_HP_HASTE_SPD_MULT := 1.0 / 0.70
const DOUBLE_TAP_POWER := 0.40
const SKILL_TAX_SEC := 2.0
const PACK_RAGE_STATUS := "enrage"

## enemy_id → trait_id（Decision 118 割り付け）。
const ASSIGNMENTS: Dictionary = {
	# ① モーンゲート
	"sepia_hound": TRAIT_LIFESTEAL,
	"rune_roach": TRAIT_PACK_RAGE,
	"crystal_hedgehog": TRAIT_THORNS,
	"crown_eater_rat": TRAIT_SKILL_TAX,
	"grave_bell_bat": TRAIT_BACK_FOCUS,
	"crystal_scorpion": TRAIT_TOUCH_AILMENT,
	"skullface_mantis": TRAIT_DOUBLE_TAP,
	# ② ウィスパーウッド
	"moss_boar": TRAIT_FRONT_FOCUS,
	"moss_shell": TRAIT_LOW_HP_HASTE,
	"spore_widow": TRAIT_TOUCH_AILMENT,
	"iron_horn": TRAIT_DOUBLE_TAP,
	"blood_bloom": TRAIT_LIFESTEAL,
	"rune_carcinos": TRAIT_THORNS,
	# ③ ミストフェン
	"blood_leech": TRAIT_LIFESTEAL,
	"dead_poison_frog": TRAIT_DEATH_NOVA,
	"mist_mantis": TRAIT_BACK_FOCUS,
	"marsh_king": TRAIT_PACK_RAGE,
	"bone_picker": TRAIT_SKILL_TAX,
	"mire_strider_spider": TRAIT_TOUCH_AILMENT,
	"spore_needle_wasp": TRAIT_DOUBLE_TAP,
	# ④ ブラックショア
	"ship_eater_crab": TRAIT_FRONT_FOCUS,
	"skull_turtle": TRAIT_THORNS,
	"undertaker_shark": TRAIT_LIFESTEAL,
	"samurai_fish": TRAIT_DOUBLE_TAP,
	"black_tide_shark": TRAIT_PACK_RAGE,
	"abyssal_squid": TRAIT_SKILL_TAX,
	"tide_lamp": TRAIT_BACK_FOCUS,
	# ⑤ フロストリッジ
	"frost_claw_raptor": TRAIT_DOUBLE_TAP,
	"vergaron": TRAIT_FRONT_FOCUS,
	"storm_joe": TRAIT_SKILL_TAX,
	"oldrex": TRAIT_LOW_HP_HASTE,
	"wind_ripper": TRAIT_BACK_FOCUS,
	# 放浪・横断
	"rock_bison": TRAIT_FRONT_FOCUS,
	"golden_scarab": TRAIT_DEATH_NOVA,
	"cosmic_duck": TRAIT_SKILL_TAX,
	"crown_raven": TRAIT_BACK_FOCUS,
	"shadow_stalker": TRAIT_DOUBLE_TAP,
}

const DEFS: Dictionary = {
	TRAIT_THORNS: {
		"name": "棘反撃",
		"hint": "通常攻撃で殴ると反撃を受ける",
	},
	TRAIT_DEATH_NOVA: {
		"name": "死に際",
		"hint": "撃破時にパーティへ小ダメージ",
	},
	TRAIT_PACK_RAGE: {
		"name": "群れの怒り",
		"hint": "味方敵が倒れると激昂する",
	},
	TRAIT_FRONT_FOCUS: {
		"name": "前衛狙い",
		"hint": "前列を優先して攻撃する",
	},
	TRAIT_BACK_FOCUS: {
		"name": "後列狙い",
		"hint": "後列を優先して攻撃する",
	},
	TRAIT_LIFESTEAL: {
		"name": "吸血",
		"hint": "与えたダメージの一部を吸収する",
	},
	TRAIT_TOUCH_AILMENT: {
		"name": "接触異常",
		"hint": "通常攻撃で殴ると状態異常を受けることがある",
	},
	TRAIT_LOW_HP_HASTE: {
		"name": "瀕死加速",
		"hint": "HPが低いと行動が早くなる",
	},
	TRAIT_DOUBLE_TAP: {
		"name": "追撃",
		"hint": "通常攻撃が二度当たる",
	},
	TRAIT_SKILL_TAX: {
		"name": "重圧",
		"hint": "命中するとスキルの待ち時間が伸びる",
	},
}


static func trait_id_of(data: Resource) -> String:
	if data == null:
		return ""
	if "trait_id" in data:
		var tid: String = str(data.trait_id).strip_edges()
		if not tid.is_empty():
			return tid
	var eid: String = str(data.id) if "id" in data else ""
	return str(ASSIGNMENTS.get(eid, ""))


static func has_trait(data: Resource, trait_id: String) -> bool:
	return trait_id_of(data) == trait_id


static func display_name(trait_id: String) -> String:
	var def: Variant = DEFS.get(trait_id, {})
	if def is Dictionary:
		return str(def.get("name", trait_id))
	return trait_id


static func hint(trait_id: String) -> String:
	var def: Variant = DEFS.get(trait_id, {})
	if def is Dictionary:
		return str(def.get("hint", ""))
	return ""


static func codex_line(trait_id: String) -> String:
	if trait_id.is_empty() or not DEFS.has(trait_id):
		return ""
	return "%s — %s" % [display_name(trait_id), hint(trait_id)]


static func thorns_damage(enemy_atk: int) -> int:
	return maxi(1, int(round(float(maxi(0, enemy_atk)) * THORNS_ATK_FRAC)))


static func death_nova_damage(enemy_atk: int) -> int:
	return maxi(1, int(round(float(maxi(0, enemy_atk)) * DEATH_NOVA_ATK_FRAC)))


static func lifesteal_ratio_of(data: Resource) -> float:
	if data == null:
		return 0.0
	if "lifesteal_ratio" in data:
		var r: float = float(data.lifesteal_ratio)
		if r > 0.0:
			return r
	if has_trait(data, TRAIT_LIFESTEAL):
		return LIFESTEAL_RATIO_DEFAULT
	return 0.0
