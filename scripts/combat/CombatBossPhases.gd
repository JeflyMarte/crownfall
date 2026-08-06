class_name CombatBossPhases
extends RefCounted

## ボス戦フェーズ移行（P3-D116）。HP 閾値で形態が変わり、スキル率・攻撃力が変化する。
## カタログはコード内静的定義。図鑑は目撃したフェーズのみ開示。
## P3-BAL-BOSS-PRESSURE-001 横展開: 全フェーズでスキル率寄せ＋全体／圧力スキルを激昂より優先。

const _DEFS: Dictionary = {
	"serdion": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			## F2: 通常攻撃偏重を抑え、即時全体（咆哮）寄りに。
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_serdion_hex": 1.6,
				"enemy_serdion_roar": 2.2,
				"boss_decree_wave": 1.4,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・激昂",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】セルディオンが激昂した！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_serdion_hex": 1.7,
				"enemy_serdion_roar": 2.0,
				"boss_decree_wave": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・断罪",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】断罪の波動が倍加する！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_serdion_hex": 1.8,
				"enemy_serdion_roar": 2.0,
				"boss_decree_wave": 2.5,
			},
		},
	],
	"granvel": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_granvel_hex": 1.6,
				"enemy_granvel_verdant_wave": 2.2,
				"enemy_granvel_bramble_crush": 1.4,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・森の怒り",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】グランヴェルの体表で根と蔓が荒れ狂う！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_granvel_hex": 1.7,
				"enemy_granvel_verdant_wave": 2.0,
				"enemy_granvel_bramble_crush": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・大森の化身",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】森そのものがグランヴェルに力を注ぐ！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_granvel_hex": 1.8,
				"enemy_granvel_verdant_wave": 2.0,
				"enemy_granvel_bramble_crush": 2.5,
			},
		},
	],
	"moldgar": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_moldgar_hex": 1.6,
				"enemy_moldgar_abyss_surge": 2.2,
				"enemy_moldgar_mire_maw": 1.4,
				"enemy_moldgar_call_marsh": 1.5,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・泥塘の主",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】モルドガルが泥塘の底へ半身を沈め、うねりが激しくなる！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_moldgar_hex": 1.7,
				"enemy_moldgar_abyss_surge": 2.0,
				"enemy_moldgar_mire_maw": 1.8,
				"enemy_moldgar_call_marsh": 2.2,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・底なしの王",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】底なし沼そのものがモルドガルとともに牙を剥く！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_moldgar_hex": 1.8,
				"enemy_moldgar_abyss_surge": 2.0,
				"enemy_moldgar_mire_maw": 2.5,
				"enemy_moldgar_call_marsh": 0.8,
			},
		},
	],
	"nereion": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_nereion_hex": 1.6,
				"enemy_nereion_tidal_wail": 2.2,
				"enemy_nereion_breach": 1.4,
				"enemy_nereion_call_dread": 1.5,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・満ち潮",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】ネレイオンの鳴音が高まり、潮が満ちはじめる！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_nereion_hex": 1.7,
				"enemy_nereion_tidal_wail": 2.0,
				"enemy_nereion_breach": 1.8,
				"enemy_nereion_call_dread": 2.2,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・潮鳴りの主",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】座礁船団が軋み、大潮がネレイオンとともに牙を剥く！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_nereion_hex": 1.8,
				"enemy_nereion_tidal_wail": 2.0,
				"enemy_nereion_breach": 2.5,
				"enemy_nereion_call_dread": 0.8,
			},
		},
	],
	"eldion": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_eldion_hex": 1.6,
				"enemy_eldion_glacial_breath": 2.2,
				"enemy_eldion_crevasse": 1.4,
				"enemy_eldion_glacial_regen": 1.2,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・白闇",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】エルディオンの翼が吹雪を呼び、視界が白闇に沈む！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_eldion_hex": 1.7,
				"enemy_eldion_glacial_breath": 2.0,
				"enemy_eldion_crevasse": 1.8,
				"enemy_eldion_glacial_regen": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・始祖の竜",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】体内の氷河晶が輝き、始祖の竜が真の力を解き放つ！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_eldion_hex": 1.8,
				"enemy_eldion_glacial_breath": 2.0,
				"enemy_eldion_crevasse": 2.5,
				"enemy_eldion_glacial_regen": 2.2,
			},
		},
	],
	"chronos_wave": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_chronos_wave_hex": 1.6,
				"enemy_chronos_wave_resonance": 2.2,
				"enemy_chronos_wave_gear_crush": 1.4,
				"enemy_chronos_wave_call_moth": 1.5,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・時歪",
			"skill_use_chance": 0.65,
			"attack_mult": 1.15,
			"log": "【フェーズ移行】歯車の共鳴が加速し、時間感覚が狂い始める！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_chronos_wave_hex": 1.7,
				"enemy_chronos_wave_resonance": 2.0,
				"enemy_chronos_wave_gear_crush": 1.8,
				"enemy_chronos_wave_call_moth": 2.2,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・時環暴走",
			"skill_use_chance": 0.75,
			"attack_mult": 1.35,
			"log": "【フェーズ移行】時環の共鳴龍が全層を震わせる！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_chronos_wave_hex": 1.8,
				"enemy_chronos_wave_resonance": 2.0,
				"enemy_chronos_wave_gear_crush": 2.5,
				"enemy_chronos_wave_call_moth": 0.8,
			},
		},
	],
	"valgard": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_valgard_hex": 1.6,
				"enemy_valgard_rampart": 2.2,
				"enemy_valgard_boundary_spear": 1.4,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・城壁展開",
			"skill_use_chance": 0.65,
			"attack_mult": 1.12,
			"log": "【フェーズ移行】境界の番が城壁機関を展開し、守りが強まる！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_valgard_hex": 1.7,
				"enemy_valgard_rampart": 2.0,
				"enemy_valgard_boundary_spear": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・機関暴走",
			"skill_use_chance": 0.75,
			"attack_mult": 1.28,
			"log": "【フェーズ移行】擬機械の機関が暴走し、境界廊全体が軋む！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_valgard_hex": 1.8,
				"enemy_valgard_rampart": 2.0,
				"enemy_valgard_boundary_spear": 2.5,
			},
		},
	],
	"skarpedion": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_skarpedion_hex": 1.6,
				"enemy_skarpedion_iron_molt": 2.2,
				"enemy_skarpedion_carapace_ram": 1.4,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・鉄殻",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】鉄殻の長が甲殻を震わせ、坑道が軋む！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_skarpedion_hex": 1.7,
				"enemy_skarpedion_iron_molt": 2.0,
				"enemy_skarpedion_carapace_ram": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・炉印",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】王冠の紋様が鉄殻に浮かび、長が全長を解く！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_skarpedion_hex": 1.8,
				"enemy_skarpedion_iron_molt": 2.0,
				"enemy_skarpedion_carapace_ram": 2.5,
			},
		},
	],
	"mycolga_ancient": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_mycolga_hex": 1.6,
				"enemy_mycolga_spore_field": 2.2,
				"enemy_mycolga_root_bind": 1.4,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・菌糸網",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】古茸の菌糸が通路を覆い、胞子が濃くなる！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_mycolga_hex": 1.7,
				"enemy_mycolga_spore_field": 2.0,
				"enemy_mycolga_root_bind": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・封緘の根",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】書庫全体が一本の根として脈打つ！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_mycolga_hex": 1.8,
				"enemy_mycolga_spore_field": 2.0,
				"enemy_mycolga_root_bind": 2.5,
			},
		},
	],
	"karna_smoke": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_karna_hex": 1.6,
				"enemy_karna_ash_veil": 2.2,
				"enemy_karna_magma_lance": 1.4,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・灰雲",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】燼竜が灰雲を吐き、火口が赤く染まる！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_karna_hex": 1.7,
				"enemy_karna_ash_veil": 2.0,
				"enemy_karna_magma_lance": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・燼の主",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】溶岩の脈動とともに燼竜が空へ昇る！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_karna_hex": 1.8,
				"enemy_karna_ash_veil": 2.0,
				"enemy_karna_magma_lance": 2.5,
			},
		},
	],
	"nereion_depths": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_nereion_depths_hex": 1.6,
				"enemy_nereion_depths_tide_pull": 2.2,
				"enemy_nereion_depths_abyss_roar": 1.4,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・深潮",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】潮脈王が沈没旗艦を揺らし、深海の圧が増す！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_nereion_depths_hex": 1.7,
				"enemy_nereion_depths_tide_pull": 2.0,
				"enemy_nereion_depths_abyss_roar": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・潮脈の主",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】外洋の底から、潮鳴りが一つに束ねられる！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_nereion_depths_hex": 1.8,
				"enemy_nereion_depths_tide_pull": 2.0,
				"enemy_nereion_depths_abyss_roar": 2.5,
			},
		},
	],
	"forgedormient": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_forgedormient_hex": 1.6,
				"enemy_forgedormient_slag_breath": 2.2,
				"enemy_forgedormient_furnace_quake": 1.4,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・炉熱",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】星炉の残熱が甦り、坑道が赤く光る！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_forgedormient_hex": 1.7,
				"enemy_forgedormient_slag_breath": 2.0,
				"enemy_forgedormient_furnace_quake": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・寝主",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】炉壁そのものが起き上がり、フォージ・ドルミエントが目を覚ます！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_forgedormient_hex": 1.8,
				"enemy_forgedormient_slag_breath": 2.0,
				"enemy_forgedormient_furnace_quake": 2.5,
			},
		},
	],
	"albark": [
		{
			"threshold": 1.0,
			"label": "第1形態",
			"skill_use_chance": 0.55,
			"attack_mult": 1.0,
			"skill_weight": {
				"boss_enrage": 0.45,
				"boss_albark_hex": 1.6,
				"enemy_albark_white_silence": 2.2,
				"enemy_albark_mapless_charge": 1.4,
			},
		},
		{
			"threshold": 0.50,
			"label": "第2形態・白闇",
			"skill_use_chance": 0.65,
			"attack_mult": 1.10,
			"log": "【フェーズ移行】白甲の古龍が翼を広げ、雪原が静寂に沈む！",
			"skill_weight": {
				"boss_enrage": 0.55,
				"boss_albark_hex": 1.7,
				"enemy_albark_white_silence": 2.0,
				"enemy_albark_mapless_charge": 1.8,
			},
		},
		{
			"threshold": 0.25,
			"label": "第3形態・地図なし",
			"skill_use_chance": 0.75,
			"attack_mult": 1.25,
			"log": "【フェーズ移行】ここより先、地図なし——アルバークが名を拒む！",
			"skill_weight": {
				"boss_enrage": 0.4,
				"boss_albark_hex": 1.8,
				"enemy_albark_white_silence": 2.0,
				"enemy_albark_mapless_charge": 2.5,
			},
		},
	],
}

static func has_phases(enemy_id: String) -> bool:
	return _DEFS.has(enemy_id)

static func boss_ids() -> Array:
	return _DEFS.keys()

static func phase_count(enemy_id: String) -> int:
	return (_DEFS.get(enemy_id, []) as Array).size()

static func phase_def(enemy_id: String, phase_index: int) -> Dictionary:
	var phases: Array = _DEFS.get(enemy_id, [])
	if phase_index < 0 or phase_index >= phases.size():
		return {}
	return phases[phase_index]

# 現在 HP 割合からフェーズ index を決定（閾値以下の最大段階）。
static func resolve_phase_index(enemy_id: String, hp_ratio: float) -> int:
	var phases: Array = _DEFS.get(enemy_id, [])
	if phases.is_empty():
		return 0
	var idx: int = 0
	for i: int in phases.size():
		if hp_ratio <= float(phases[i].get("threshold", 1.0)):
			idx = i
	return idx

static func attack_mult(enemy_id: String, phase_index: int) -> float:
	return float(phase_def(enemy_id, phase_index).get("attack_mult", 1.0))

static func skill_use_chance(enemy_id: String, phase_index: int, fallback: float) -> float:
	var def: Dictionary = phase_def(enemy_id, phase_index)
	if def.is_empty():
		return fallback
	return float(def.get("skill_use_chance", fallback))

# 図鑑 stage5 用。目撃済みフェーズのみラベル開示（第1形態は常時）。
static func codex_phase_text(enemy_id: String, phases_seen: Array) -> String:
	if not has_phases(enemy_id):
		return ""
	var phases: Array = _DEFS[enemy_id]
	var parts: PackedStringArray = []
	for i: int in phases.size():
		var p: Dictionary = phases[i]
		if i == 0 or i in phases_seen:
			var th: float = float(p.get("threshold", 1.0))
			var suffix: String = "開始" if i == 0 else "HP≤%d%%" % int(round(th * 100.0))
			parts.append("%s（%s）" % [str(p.get("label", "")), suffix])
		else:
			parts.append("？？？")
	return "フェーズ: %s" % " → ".join(parts)
