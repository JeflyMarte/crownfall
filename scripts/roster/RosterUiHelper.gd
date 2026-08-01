class_name RosterUiHelper
extends RefCounted

const _JobStatCalculator = preload("res://scripts/equipment/JobStatCalculator.gd")
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")

const BASE_MEMBER_HP: int = BalanceConfig.BASE_MEMBER_HP

const ROLE_LABELS: Dictionary = {
	"dps": "アタッカー",
	"tank": "タンク",
	"scout": "斥候",
	"support": "サポート",
}

const ROLE_GLYPHS: Dictionary = {
	"dps": "⚔",
	"tank": "🛡",
	"scout": "🏹",
	"support": "✚",
}

const ROLE_FILTER_LABELS: Dictionary = {
	"all": "全職",
	"tank": "タンク",
	"dps": "アタッカー",
	"scout": "斥候",
	"support": "サポート",
}

## 編成カード枠の共通寸法。選択ハイライトで変えるとセルが「拡大」して見えるので固定。
const CARD_CONTENT_MARGIN: float = 2.0
const CARD_BORDER_W: int = 2
## CHR アイコン原寸（~1254）を絶対に超えない描画辺キャップ。
const PORTRAIT_PX_HARD_MAX: int = 180

## StyleBox は mutate しない前提で共有キャッシュ（カード毎 new は編成画面の重さの主因）。
static var _cached_card_idle: StyleBoxFlat
static var _cached_card_active: StyleBoxFlat
static var _cached_card_leader: StyleBoxFlat
static var _cached_pick: StyleBoxFlat
static var _cached_roster_bottom_bar: StyleBoxFlat

static func leader_skill_display(member: Resource) -> Dictionary:
	if member == null:
		return {"name": "—", "description": "リーダーを編成してください。"}
	var passives: Array = CombatPassives.for_member(member)
	if passives.is_empty():
		return {"name": "—", "description": "リーダー効果はありません。"}
	var def: Dictionary = passives[0]
	return {
		"name": str(def.get("display_name", "—")),
		"description": passive_description(def),
	}

static func passive_description(def: Dictionary) -> String:
	if str(def.get("category", "")) == "relic":
		return CombatPassives.relic_description(str(def.get("id", "")))
	if def.has("description"):
		return str(def.get("description", ""))
	if float(def.get("evasion_rate_add", 0.0)) > 0.0:
		return "回避率が%d%%上昇する。" % int(round(float(def["evasion_rate_add"]) * 100.0))
	if float(def.get("first_attack_mult", 1.0)) > 1.0:
		return "戦闘中最初の通常攻撃の威力が%.0f倍になる。" % float(def["first_attack_mult"])
	if float(def.get("ultimate_power_mult", 1.0)) > 1.0:
		return "必殺技の威力が%d%%上昇する。" % int(round((float(def["ultimate_power_mult"]) - 1.0) * 100.0))
	if float(def.get("exp_gain_mult", 1.0)) > 1.0:
		return "自身の獲得経験値が%d%%増加する。" % int(round((float(def["exp_gain_mult"]) - 1.0) * 100.0))
	if float(def.get("party_exp_gain_mult", 1.0)) > 1.0:
		return "編成中パーティの獲得経験値が%d%%増加する。" % int(round((float(def["party_exp_gain_mult"]) - 1.0) * 100.0))
	if float(def.get("outgoing_mult", 1.0)) > 1.0:
		return "与ダメージが%d%%上昇する。" % int(round((float(def["outgoing_mult"]) - 1.0) * 100.0))
	if float(def.get("pet_outgoing_mult", 1.0)) > 1.0:
		return "オトモの与ダメージが%d%%上昇する。" % int(round((float(def["pet_outgoing_mult"]) - 1.0) * 100.0))
	if float(def.get("incoming_mult", 1.0)) < 1.0:
		return "被ダメージが%d%%軽減される。" % int(round((1.0 - float(def["incoming_mult"])) * 100.0))
	var effect: String = str(def.get("effect", ""))
	var target: String = str(def.get("target", "self"))
	match effect:
		"heal":
			return "味方が倒れたとき、パーティを回復する。"
		"counter_attack":
			if str(def.get("trigger", "")) == "on_ally_death":
				return "味方が倒れたとき、反撃する。"
			return "攻撃を受けたとき、反撃する。"
		"bonus_damage":
			return "一定回数の攻撃ごとに追撃する。"
		"aoe_burst":
			return "撃破時に周囲へ追撃する。"
		"abyss_ice_shell_counter":
			return "被弾時に氷殻を張り、反撃する。"
		"grant_next_attack_mult":
			return "味方が倒れたとき、次の通常攻撃の威力が上昇する。"
		"apply_status":
			var status_id: String = str(def.get("status_id", ""))
			var status_name: String = _status_label(status_id)
			if target == "party":
				return "味方が倒れたとき、パーティに%sを付与する。" % status_name
			if str(def.get("trigger", "")) == "on_combat_start":
				return "戦闘開始時、自身に%sを付与する。" % status_name
			if str(def.get("trigger", "")) == "on_hit_taken":
				return "攻撃を受けたとき、自身に%sを付与する。" % status_name
			if str(def.get("condition", "")) == "self_hp_below":
				return "HPが低下したとき、自身に%sを付与する。" % status_name
			return "条件を満たすと%sを付与する。" % status_name
	return "編成時に発動するリーダー特性（表示のみ）。"

static func _status_label(status_id: String) -> String:
	match status_id:
		"empower":
			return "鼓舞"
		"guard":
			return "防御"
		"bleed":
			return "出血"
		"poison":
			return "毒"
		"mark":
			return "標的"
		"chill":
			return "冷気"
		"shock":
			return "感電"
		"ignite":
			return "炎上"
		"stun":
			return "気絶"
		"curse":
			return "呪詛"
		_:
			return status_id


## パーセンテージとして本文中に埋め込まれる想定のスケール対象フィールド（生値0..1 → 表示%）。
const _PASSIVE_SCALE_RATE_FIELDS: Array[String] = [
	"status_chance", "evasion_rate_add", "incoming_block_chance",
	"death_save_chance", "heal_max_hp_fraction",
]
## ボーナス系倍率フィールド（(値-1)*100 が本文の%として埋め込まれる）。
const _PASSIVE_SCALE_BONUS_MULT_FIELDS: Array[String] = [
	"outgoing_mult", "pet_outgoing_mult", "ultimate_power_mult",
	"skill_power_mult", "exp_gain_mult", "party_exp_gain_mult", "speed_mult",
]


## 限界突破で強化された数値だけ色を変えつつ、パッシブ効果の全文を返す（結果ポップ用・BBCode）。
## raw_def: 生の（未スケール）定義。scaled_def: 現在の限界突破段階でスケール済みの定義。
static func passive_effect_highlighted_text(
	raw_def: Dictionary, scaled_def: Dictionary, highlight_hex: String = "8ce080"
) -> String:
	var text: String = passive_description(raw_def)
	if raw_def.is_empty() or scaled_def.is_empty():
		return text
	for key: String in _PASSIVE_SCALE_BONUS_MULT_FIELDS:
		if not raw_def.has(key):
			continue
		var old_pct: int = int(round((float(raw_def.get(key, 1.0)) - 1.0) * 100.0))
		var new_pct: int = int(round((float(scaled_def.get(key, 1.0)) - 1.0) * 100.0))
		text = _highlight_pct(text, old_pct, new_pct, highlight_hex)
	if raw_def.has("incoming_mult"):
		var old_pct: int = int(round((1.0 - float(raw_def.get("incoming_mult", 1.0))) * 100.0))
		var new_pct: int = int(round((1.0 - float(scaled_def.get("incoming_mult", 1.0))) * 100.0))
		text = _highlight_pct(text, old_pct, new_pct, highlight_hex)
	for key: String in _PASSIVE_SCALE_RATE_FIELDS:
		if not raw_def.has(key):
			continue
		var old_pct: int = int(round(float(raw_def.get(key, 0.0)) * 100.0))
		var new_pct: int = int(round(float(scaled_def.get(key, 0.0)) * 100.0))
		text = _highlight_pct(text, old_pct, new_pct, highlight_hex)
	return text


static func _highlight_pct(text: String, old_pct: int, new_pct: int, hex: String) -> String:
	if old_pct == new_pct:
		return text
	var old_frag: String = "%d%%" % old_pct
	if text.find(old_frag) < 0:
		return text
	return text.replace(old_frag, "[color=#%s]%d%%[/color]" % [hex, new_pct])

static func stat_line(label: String, value: int) -> String:
	return "%s %d" % [label, value]

static func short_display_name(full_name: String) -> String:
	var text: String = str(full_name)
	var idx: int = text.find("（")
	if idx > 0:
		return text.substr(0, idx)
	return text


static func member_name_with_limit_break(member: Resource, short: bool = true) -> String:
	## 限界突破分を名前横に「 +N」で付与（編成カード等）。
	if member == null:
		return "—"
	var base: String = short_display_name(str(member.display_name)) if short else str(member.display_name)
	const _GachaLimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")
	var suf: String = _GachaLimitBreak.plus_suffix(_GachaLimitBreak.breakthrough_for_member(member))
	if suf.is_empty():
		return base
	return "%s %s" % [base, suf]

static func job_display_name(member: Resource) -> String:
	if member == null:
		return "—"
	if PetSystem.is_pet_member(member):
		return "オトモ"
	var mods: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	return str(mods.get("display_name", member.job_id))

static func role_label(role: String) -> String:
	return str(ROLE_LABELS.get(role, role))

static func role_glyph(role: String) -> String:
	return str(ROLE_GLYPHS.get(role, "◆"))

static func stars_text(rarity: int) -> String:
	var count: int = clampi(rarity, 1, 5)
	var out: String = ""
	for _i in count:
		out += "★"
	return out

static func get_member_portrait_texture(member: Resource) -> Texture2D:
	if member == null:
		return null
	var member_id: String = str(member.id)
	if PetSystem.is_pet_id(member_id):
		return IconPaths.get_icon_texture(member_id, "chr")
	if member_id.begins_with("gacha_"):
		var helper: Resource = DataRegistry.get_gacha_helper_data(member_id.trim_prefix("gacha_"))
		if helper != null:
			var helper_tex: Texture2D = helper.get_portrait_texture()
			if helper_tex != null:
				return helper_tex
	# 初期5・固有登録は member id、無ければ職フォールバック
	var by_id: Texture2D = IconPaths.get_icon_texture(member_id, "chr")
	if by_id != null:
		return by_id
	return IconPaths.get_icon_texture(str(member.job_id), "chr")

static func compute_combat_power(members: Array) -> int:
	var total: int = 0
	for member in members:
		if member == null:
			continue
		total += compute_member_combat_power(member)
	return total


## 1人分の総合戦力（P3-UI-COMBAT-POWER-001）。
## HP + 防御 + 攻撃×速度×(1 + 会心率×(会心ダメ−1))。
static func compute_member_combat_power(member: Resource) -> int:
	return combat_power_from_stats(compute_member_stats(member, -1))


static func combat_power_from_stats(stats: Dictionary) -> int:
	if stats.is_empty():
		return 0
	var hp: float = float(stats.get("hp", 0))
	var defense: float = float(stats.get("defense", 0))
	var attack: float = float(stats.get("attack", 0))
	var speed: float = maxf(0.0, float(stats.get("speed", 1.0)))
	var crit_rate: float = clampf(float(stats.get("crit_rate", 0.0)), 0.0, 1.0)
	var crit_damage: float = maxf(1.0, float(stats.get("crit_damage", 1.5)))
	var offense: float = attack * speed * (1.0 + crit_rate * (crit_damage - 1.0))
	return int(round(hp + defense + offense))


static func format_combat_power(value: int) -> String:
	var text: String = str(maxi(0, value))
	if text.length() <= 3:
		return text
	var out: String = ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3, 3) + out
		text = text.substr(0, text.length() - 3)
	return text + out


## party_index は互換のため残す（未使用）。装備由来は常にメンバー本体から集計。
static func compute_member_stats(member: Resource, _party_index: int = -1) -> Dictionary:
	if member == null:
		return {"hp": 0, "attack": 0, "defense": 0, "speed": 1.0, "crit_rate": 0.0, "crit_damage": 1.5}
	var weapon: Resource = member.equipped_weapon if "equipped_weapon" in member else null
	var armor: Resource = member.equipped_armor if "equipped_armor" in member else null
	var accessory: Resource = member.equipped_accessory if "equipped_accessory" in member else null
	var acc_data: Resource = null
	if accessory != null and not str(accessory.accessory_id).is_empty():
		acc_data = DataRegistry.get_accessory_data(str(accessory.accessory_id))
	var affix: Dictionary = _AffixStatCalculator.get_bonuses_for_member(member)
	var job: Dictionary = _JobStatCalculator.get_member_modifiers(member)
	var level: int = int(member.level)
	var hp: int = BASE_MEMBER_HP
	if member.base_stats != null and int(member.base_stats.hp) > 0:
		hp = int(member.base_stats.hp)
	if armor != null:
		hp += EquipmentEnhancer.effective_armor_hp(armor)
	if acc_data != null and accessory != null:
		hp += EquipmentEnhancer.effective_accessory_int_bonus(accessory, "hp_bonus", acc_data)
	hp += int(affix.get("hp_flat", 0))
	hp += LevelSystem.level_hp_bonus(level)
	hp = int(round(float(hp) * float(job.get("hp_multiplier", 1.0))))
	var attack: int = 0
	if weapon != null:
		attack = _EquipmentEnhancer.get_effective_attack(weapon)
	if acc_data != null and accessory != null:
		attack += EquipmentEnhancer.effective_accessory_int_bonus(accessory, "attack_bonus", acc_data)
	attack += int(affix.get("attack_flat", 0))
	attack += LevelSystem.level_attack_bonus(level)
	if member.base_stats != null:
		attack += int(member.base_stats.attack)
	var atk_mult: float = float(job.get("attack_multiplier", 1.0))
	if weapon != null:
		atk_mult *= _JobStatCalculator.get_preferred_weapon_multiplier(
			member, DataRegistry.get_weapon_data(str(weapon.weapon_id))
		)
	attack = int(round(float(attack) * atk_mult))
	var defense: int = 0
	if armor != null:
		defense = EquipmentEnhancer.effective_armor_defense(armor)
	if acc_data != null and accessory != null:
		defense += EquipmentEnhancer.effective_accessory_int_bonus(
			accessory, "defense_bonus", acc_data
		)
	defense += int(affix.get("defense_flat", 0))
	if member.base_stats != null:
		defense += int(member.base_stats.defense)
	defense = int(round(float(defense) * float(job.get("defense_multiplier", 1.0))))
	var speed: float = weapon.attack_speed if weapon != null else 1.0
	var crit: float = (weapon.critical_rate if weapon != null else 0.0)
	if acc_data != null and accessory != null:
		crit += EquipmentEnhancer.effective_accessory_float_bonus(accessory, "crit_rate_bonus", acc_data)
	crit += float(affix.get("crit_rate_add", 0.0))
	var crit_damage: float = BalanceConfig.CRITICAL_MULTIPLIER
	if weapon != null:
		crit_damage = _WeaponStatResolver.resolve_critical_damage(weapon)
	return {
		"hp": hp,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"crit_rate": crit,
		"crit_damage": crit_damage,
	}

static func card_panel_style(active: bool, leader: bool) -> StyleBox:
	## 枠は StyleBoxFlat で明示（薄い 9-slice が背景に沈んで「消えた」ように見える対策）。
	## 返却後に mutate しないこと（共有キャッシュ）。
	if leader:
		if _cached_card_leader == null:
			_cached_card_leader = _make_card_panel_style(Color(0.95, 0.82, 0.38, 1.0))
		return _cached_card_leader
	if active:
		if _cached_card_active == null:
			_cached_card_active = _make_card_panel_style(Color(0.86, 0.74, 0.45, 0.98))
		return _cached_card_active
	if _cached_card_idle == null:
		_cached_card_idle = _make_card_panel_style(Color(0.55, 0.48, 0.36, 0.92))
	return _cached_card_idle


static func _make_card_panel_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.94)
	style.border_color = border
	## 選択／リーダーで border・margin を変えるとセル最小サイズが膨らみ「拡大」に見える。幅は常に同一。
	style.set_border_width_all(CARD_BORDER_W)
	style.set_corner_radius_all(10)
	style.content_margin_left = CARD_CONTENT_MARGIN
	style.content_margin_top = CARD_CONTENT_MARGIN
	style.content_margin_right = CARD_CONTENT_MARGIN
	style.content_margin_bottom = CARD_CONTENT_MARGIN
	return style


## 入れ替え選択ハイライト。card_panel_style と margin／border 幅を一致させ、選択でセルが膨らまないようにする。
static func pick_panel_style() -> StyleBoxFlat:
	if _cached_pick == null:
		_cached_pick = _make_card_panel_style(Color(0.95, 0.78, 0.35))
	return _cached_pick


## 一覧カード下段の暗い帯（セル毎 new しない）。
static func roster_bottom_bar_style() -> StyleBoxFlat:
	if _cached_roster_bottom_bar == null:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.03, 0.02, 0.82)
		style.content_margin_left = 4
		style.content_margin_top = 1
		style.content_margin_right = 4
		style.content_margin_bottom = 1
		_cached_roster_bottom_bar = style
	return _cached_roster_bottom_bar


## CHR 肖像（1254px 級）を固定枠に拘束する。選択・再レイアウトでも原寸へ逃げない。
## px は枠内描画辺。PORTRAIT_PX_HARD_MAX で絶対キャップ。
## resized で set_size しない（親レイアウトと闘って拡大連鎖の原因になる）。
static func make_clamped_portrait(tex: Texture2D, px: int, fill_cover: bool = false) -> Control:
	var side: int = clampi(px, 24, PORTRAIT_PX_HARD_MAX)
	var host := Control.new()
	host.custom_minimum_size = Vector2(side, side)
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.clip_contents = true
	var art := TextureRect.new()
	art.name = "PortraitArt"
	art.texture = tex
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_COVERED if fill_cover
		else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2.ZERO
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(art)
	return host


static func portrait_hard_max_px() -> int:
	return PORTRAIT_PX_HARD_MAX
