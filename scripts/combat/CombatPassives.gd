class_name CombatPassives
extends RefCounted

## パッシブ / リアクション（P3-D088）。
## 共通フォーマット: Trigger → Condition → Effect → Cooldown。
## 基本5職ロスターはキャラ固有パッシブを優先、それ以外はジョブフォールバック。
##
## trigger: "on_combat_start" | "on_combat_end" | "on_action_start" | "on_hit_taken" | "on_ally_death" |
##   "on_attack" | "on_kill" | "on_noncombat_enter"
## condition: "always" | "self_hp_below"（value=HP割合）| "ally_hp_below"（味方誰かHP割合）
## effect: "apply_status" | "heal" | "bonus_damage" | "counter_attack" | "grant_next_attack_mult" |
##   "refund_ct" | "grant_party_incoming_mult" | "grant_self_evasion" | "aoe_burst" | "abyss_ice_shell_counter"
## heal target: "party"（既定・全体）| "self" | "most_injured"（最傷1体・治癒スキルと同型）
## stat_mod（常時）: evasion_rate_add / back_row_evasion_rate_add / outgoing_mult / incoming_mult / first_attack_mult /
##   ultimate_power_mult / exp_gain_mult / party_exp_gain_mult /
##   party_outgoing_mult / party_incoming_mult / death_save_once / death_save_chance /
##   death_save_heal_max_hp_fraction / death_save_outgoing_mult / death_save_outgoing_duration_sec /
##   exploration_damage_immune / exploration_damage_party_mult /
##   outgoing_mult_requires_hp_below / elemental_outgoing_mult / outgoing_vs_status_mult / outgoing_vs_buff_mult /
##   lifesteal_ratio / lifesteal_basic_only /
##   pet_outgoing_mult / pet_defense_mult / pet_max_hp_mult / pet_revive_on_combat_end_chance /
##   pet_heal_on_action_max_hp_fraction / threat_base_add /
##   redirect_rear_hit_chance / lifesteal_ratio / combat_regen_* / treasure_room_weight_add /
##   skill_cd_mult / heal_received_mult / heal_skill_spill_damage_fraction /
##   heal_skill_spill_damage_add / incoming_crit_rate_add / crit_damage_add
## weather_bonus（P3-EQ-WEATHER-LEG-001）: weather_id → element_outgoing_mult / outgoing_mult / crit_rate_add / refund_ct_fraction
## effect 追加: "chance_cast_equipped_skill"（攻撃後に装備スキルを確率発動）
## action_skip_chance（常時）: 行動出番でこの確率で行動スキップ（状態異常スキップと独立）
## weapon 拡張: basic_attack_hits_all / basic_aoe_splash_mult / basic_attack_mult /
##   disable_basic_attack / outgoing_vs_boss_mult / passive_condition=front_row_only（与・被）
## cooldown: CT 秒（0 = 都度発火可。on_combat_start は実質1回）

## 戦闘スコープの一時回避加算（grant_self_evasion）。戦闘開始時に reset_combat_scoped。
static var _combat_member_evasion_add: Dictionary = {}

const _DEFS: Dictionary = {
	# ---- 神話装備（P3-EQ-MYTHIC-001 / P3-EQ-MYTHIC-WPN-TYPES-001） ----
	"eq_mythic_burial_crown": {
		"display_name": "レガートの継承",
		"category": "weapon",
		"description": "与ダメージ+25%。敵撃破時、自身の行動待ちをやや短縮する。",
		"outgoing_mult": 1.25,
		"trigger": "on_kill",
		"condition": "always",
		"effect": "refund_ct",
		"refund_ct_fraction": 0.45,
		"cooldown": 0.0,
	},
	"eq_mythic_lumen": {
		"display_name": "ルーメンの道標",
		"category": "weapon",
		"description": "与ダメージ+20%。標的状態の敵への与ダメージがさらに上昇する。",
		"outgoing_mult": 1.20,
		"outgoing_vs_status_mult": 1.30,
		"outgoing_vs_status_ids": ["mark"],
	},
	"eq_mythic_noesis": {
		"display_name": "ノエシスの理解",
		"category": "weapon",
		"description": "与ダメージ+15%。スキル威力が上昇する。",
		"outgoing_mult": 1.15,
		"skill_power_mult": 1.25,
	},
	"eq_mythic_lucian": {
		"display_name": "リュシアンの深淵",
		"category": "weapon",
		"description": "与ダメージ+15%。攻撃時、敵に出血を付与することがある。",
		"outgoing_mult": 1.15,
		"trigger": "on_attack",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "bleed",
		"target": "enemy",
		"status_chance": 0.30,
		"cooldown": 0.0,
	},
	"eq_mythic_cenotaph": {
		"display_name": "不滅の碑銘",
		"category": "armor",
		"description": "戦闘中1回、致死ダメージをHP1で耐え、直後に被ダメを大きく軽減する。",
		"death_save_once": true,
		"death_save_incoming_mult": 0.35,
		"death_save_duration_sec": 4.0,
	},
	"eq_mythic_hegemony": {
		"display_name": "評議会の覇",
		"category": "accessory",
		"description": "パーティ全体の与ダメ+20%／被ダメ-15%／獲得EXP+25%。",
		"party_outgoing_mult": 1.20,
		"party_incoming_mult": 0.85,
		"party_exp_gain_mult": 1.25,
	},

	# ---- 基本5職キャラ固有（P3-PASSIVE-SKILL-CORE-001: スキル核寄せ） ----
	"ald_royal_flame": {
		"display_name": "王炎の覇気",
		"description": "攻撃時25%の確率で敵に出血を付与する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "bleed",
		"target": "enemy",
		"status_chance": 0.25,
		"cooldown": 0.0,
	},
	"riva_lone_focus": {
		"display_name": "狙印の刻",
		"description": "攻撃時25%の確率で敵に標的を付与する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "mark",
		"target": "enemy",
		"status_chance": 0.25,
		"cooldown": 0.0,
	},
	"elias_field_elixir": {
		"display_name": "万象の触媒",
		"description": "属性つきの攻撃・スキルの与ダメージが20%上昇する。",
		"elemental_outgoing_mult": 1.20,
	},
	"galen_sacred_bastion": {
		"display_name": "聖盾の砦",
		"description": "被ダメージが10%軽減され、敵の注目を集めやすい。",
		"incoming_mult": 0.90,
		"threat_base_add": 80.0,
	},
	"mirei_swarm_resonance": {
		"display_name": "毒牙",
		"description": "攻撃時28%の確率で、毒・出血・炎上のいずれかを付与する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "random_enemy_status",
		"status_pool": ["poison", "bleed", "ignite"],
		"status_chance": 0.28,
		"cooldown": 0.0,
	},
	# ---- ジョブフォールバック（非基本ロスター・助っ人等） ----
	"bulwark": {
		"display_name": "鉄壁",
		"description": "攻撃を受けたとき、反撃する（再使用4秒）。",
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "counter_attack",
		"cooldown": 4.0,
	},
	"battle_fervor": {
		"display_name": "高揚",
		"description": "戦闘中最初の通常攻撃の威力が2倍になる。",
		"first_attack_mult": 2.0,
	},
	"field_medic": {
		"display_name": "野戦救護",
		"description": "自身の獲得経験値が15%増加する。",
		"exp_gain_mult": 1.15,
	},
	"pack_instinct": {
		"display_name": "群れの指揮",
		"description": "ペットが生存中、ペットの与ダメージが10%上昇する。",
		"pet_outgoing_mult": 1.10,
	},
	# ---- ガチャ助っ人固有（P3-GACHA-005 / P3-PASSIVE-CHAR-001） ----
	"leon_sword_focus": {
		"display_name": "病隙の刃",
		"description": "状態異常の敵への与ダメージが25%上昇する。",
		"outgoing_vs_status_mult": 1.25,
	},
	"durante_vial_echo": {
		"display_name": "薬瓶の反響",
		"description": "攻撃後、10%の確率で自身の装備スキルを発動する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "chance_cast_equipped_skill",
		"status_chance": 0.10,
		"cooldown": 0.0,
	},
	"ivar_trail_sight": {
		"display_name": "辺境の踏破",
		"description": "自分は非戦闘（罠・探索）ダメージを受けない。パーティが罠ダメージを受けたとき、ダメージ半減。",
		"exploration_damage_immune": true,
		"exploration_damage_party_mult": 0.5,
	},
	"serin_quick_mend": {
		"display_name": "予備瓶",
		"description": "味方の誰かのHPが半分を下回ったとき、いちばん傷ついた味方を中回復する（戦闘中1回）。",
		"trigger": "on_action_start",
		"condition": "ally_hp_below",
		"value": 0.5,
		"effect": "heal",
		"target": "most_injured",
		"heal_max_hp_fraction": 0.25,
		"once_per_combat": true,
		"cooldown": 0.0,
	},
	"mira_beast_call": {
		"display_name": "血契の矢",
		"description": "通常攻撃の与ダメージの15%を自身のHPとして吸収する。",
		"lifesteal_ratio": 0.15,
		"lifesteal_basic_only": true,
	},
	"valden_iron_oath": {
		"display_name": "鉄誓の壁",
		"description": "味方全体の被ダメージを軽減する。",
		"party_incoming_mult": 0.90,
	},
	"kaida_arena_edge": {
		"display_name": "一閃の賭け",
		"description": "戦闘中、最初の通常攻撃の威力が大きく上昇する。",
		"first_attack_mult": 1.75,
	},
	"garm_caravan_guard": {
		"display_name": "不屈の鼓動",
		"description": "戦闘中、3秒ごとに最大HPの2%を回復する。敵の注目を集めやすい。",
		"combat_regen_interval_sec": 3.0,
		"combat_regen_max_hp_fraction": 0.02,
		"threat_base_add": 70.0,
	},
	## P3-GACHA 追加4体（レノール／シアン／ネリ／ボルグ）
	"lenore_seal_echo": {
		"display_name": "呪印の増幅",
		"description": "状態異常の敵への与ダメージが45%上昇する。",
		"outgoing_vs_status_mult": 1.45,
	},
	"torva_frost_breath": {
		"display_name": "霜刃の一息",
		"description": "戦闘中最初の通常攻撃の威力が1.5倍になる。",
		"first_attack_mult": 1.5,
	},
	"sian_silent_line": {
		"display_name": "沈黙の罠糸",
		"description": "攻撃時28%の確率で、冷却・鈍化・恐怖のいずれかを付与する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "random_enemy_status",
		"status_pool": ["chill", "slow", "fear"],
		"status_chance": 0.28,
		"cooldown": 0.0,
	},
	"borg_gate_voice": {
		"display_name": "門前の応撃",
		"description": "攻撃を受けたとき、通常攻撃相当で反撃する（再使用3.5秒）。",
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "counter_attack",
		"cooldown": 3.5,
	},
	"neri_waterfowl_call": {
		"display_name": "水鳥の指揮",
		"description": "ペットのステータスが1.25倍になる。戦闘終了時、戦闘不能のペットを25%の確率で蘇生する。",
		"pet_outgoing_mult": 1.25,
		"pet_defense_mult": 1.25,
		"pet_max_hp_mult": 1.25,
		"pet_revive_on_combat_end_chance": 0.25,
		"pet_revive_max_hp_fraction": 0.30,
	},
	## プール助っ人 — 火鷹★4（撃破鼓舞＋行動スキップ）
	"hodaka_blood_price": {
		"display_name": "血潮の代償",
		"description": "敵撃破時、自身の攻撃力が上昇する（鼓舞）。行動出番でたまに行動できなくなる。",
		"trigger": "on_kill",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "empower",
		"target": "self",
		"cooldown": 0.0,
		"action_skip_chance": 0.20,
	},
	# ---- ジョブフォールバック補完（P3-D155） ----
	"foresight": {
		"display_name": "先読み",
		"description": "回避率が20%上昇する。",
		"evasion_rate_add": 0.20,
	},
	# ---- ★3 職固有（P3-D155 / P3-GACHA-006 / P3-PASSIVE-V2） ----
	"sword_charge": {
		"display_name": "剣気充填",
		"description": "与ダメージが常時10%上昇する。",
		"outgoing_mult": 1.10,
	},
	"wind_reading": {
		"display_name": "風読み",
		"description": "回避率が12%上昇する。",
		"evasion_rate_add": 0.12,
	},
	"spare_vial": {
		"display_name": "予備薬瓶",
		"description": "HPが50%を下回ったとき、自身を96回復する（再使用10秒）。",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "heal", "target": "self", "heal_value": BalanceConfig.SPARE_VIAL_HEAL,
		"cooldown": 10.0,
	},
	"unyielding_stance": {
		"display_name": "不屈の構え",
		"description": "被ダメージが12%軽減される。",
		"incoming_mult": 0.88,
	},
	"tamer_whistle": {
		"display_name": "手懐けの笛",
		"description": "攻撃時20%の確率で敵に冷却を付与し、動きを鈍らせる。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "chill",
		"target": "enemy",
		"status_chance": 0.20,
		"cooldown": 0.0,
	},
	# ---- ★4 職固有（P3-D155 / P3-GACHA-006 / P3-PASSIVE-V2） ----
	"royal_sword_doctrine": {
		"display_name": "王軍剣範",
		"description": "必殺技の威力が50%上昇する。",
		"ultimate_power_mult": 1.50,
	},
	"formation_eye": {
		"display_name": "隊列の眼",
		"description": "味方が倒れたとき、生存者の次の通常攻撃の威力が2倍になる。",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "grant_next_attack_mult",
		"mult": 2.0,
		"target": "party_alive",
		"cooldown": 0.0,
	},
	"panacea_gift": {
		"display_name": "万能薬進呈",
		"description": "編成中パーティの獲得経験値が10%増加する。",
		"party_exp_gain_mult": 1.10,
	},
	"greatshield_order": {
		"display_name": "大盾の号令",
		"description": "被ダメージが10%軽減される。",
		"incoming_mult": 0.90,
	},
	"herd_king_roar": {
		"display_name": "群王の咆哮",
		"description": "戦闘開始時、敵全体に恐怖を付与する。",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "fear",
		"target": "enemy_all",
		"cooldown": 0.0,
	},
	# ---- レジェンド装備（P3-EQ-LEG-001 / P3-EQ-LEG-002） ----
	"eq_serdion_ward": {
		"display_name": "霊廟の守護",
		"category": "armor",
		"description": "被弾時、HPが半分未満なら自身に防御を付与する（再使用6秒）。",
		"trigger": "on_hit_taken",
		"condition": "self_hp_below", "value": 0.5,
		"effect": "apply_status", "status_id": "guard", "target": "self",
		"cooldown": 6.0,
	},
	"eq_mourngate_royal": {
		"display_name": "王家の覇気",
		"category": "accessory",
		"description": "戦闘中最初の通常攻撃の威力が1.75倍になる。",
		"first_attack_mult": 1.75,
	},
	"eq_granvel_bark": {
		"display_name": "共生の樹皮",
		"category": "armor",
		"description": "被弾時、最大HPの4%を回復する（再使用5秒）。",
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "heal",
		"target": "self",
		"heal_max_hp_fraction": 0.04,
		"cooldown": 5.0,
	},
	"eq_silvaria_covenant": {
		"display_name": "盟約の加護",
		"category": "accessory",
		"description": "戦闘開始時、味方全体の必殺ゲージを少し回復する。",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "party_rally",
		"status_id": "",
		"ultimate_charge_flat": 25.0,
		"cooldown": 0.0,
	},
	"eq_moldgar_abyss": {
		"display_name": "深淵鱗の反毒",
		"category": "armor",
		"description": "被弾時30%で攻撃してきた敵に毒を付与する。",
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "apply_status", "status_id": "poison", "target": "enemy",
		"status_chance": 0.30,
		"cooldown": 0.0,
	},
	"eq_seradis_archive": {
		"display_name": "封緘の加護",
		"category": "accessory",
		"description": "戦闘開始時、味方全体に防御を付与する。",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "guard", "target": "party",
		"cooldown": 0.0,
	},
	"eq_nereion_tide": {
		"display_name": "潮鎧の冷却",
		"category": "armor",
		"description": "被弾時25%で攻撃してきた敵に冷却を付与する（再使用4秒）。",
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "apply_status", "status_id": "chill", "target": "enemy",
		"status_chance": 0.25,
		"cooldown": 4.0,
	},
	"eq_pharos_beacon": {
		"display_name": "潮灯の標照",
		"category": "accessory",
		"description": "戦闘開始時、敵全体に標的を付与する。",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status", "status_id": "mark", "target": "enemy_all",
		"cooldown": 0.0,
	},
	"eq_eldion_glacier": {
		"display_name": "氷鱗の凍結",
		"category": "armor",
		"description": "被ダメが8%軽減される。被弾時20%で攻撃してきた敵に冷却を付与する（再使用5秒）。",
		"incoming_mult": 0.92,
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "apply_status", "status_id": "chill", "target": "enemy",
		"status_chance": 0.20,
		"cooldown": 5.0,
	},
	"eq_frostridge_boundary": {
		"display_name": "境界の鉄壁",
		"category": "accessory",
		"description": "味方が倒れたとき、残った味方全体に防御を付与する（戦闘中1回）。",
		"trigger": "on_ally_death",
		"condition": "always",
		"effect": "apply_status", "status_id": "guard", "target": "party",
		"once_per_combat": true,
		"cooldown": 0.0,
	},
	## クラシックL装飾補充（P3-EQ-CLASSIC-L-ACC-001 / 56）
	"eq_bloodvein_signet": {
		"display_name": "血脈の衝動",
		"category": "accessory",
		"description": "与ダメ +12%。被ダメ +5%。",
		"outgoing_mult": 1.12,
		"incoming_mult": 1.05,
	},
	"eq_ironvow_amulet": {
		"display_name": "鉄誓の守り",
		"category": "accessory",
		"description": "被ダメ −12%。",
		"incoming_mult": 0.88,
	},
	"eq_quicksigil_charm": {
		"display_name": "速印",
		"category": "accessory",
		"description": "スキル再使用が 15% 速くなる。",
		"skill_cd_mult": 0.85,
	},
	"eq_dawnrally_brooch": {
		"display_name": "暁の鼓舞",
		"category": "accessory",
		"description": "戦闘開始時、味方全体を鼓舞する。",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "party_rally",
		"status_id": "empower",
		"cooldown": 0.0,
	},
	# ---- ビルド拡張レジェンド（P3-EQ-LEG-BUILD-001） ----
	"eq_bloodpact_plate": {
		"display_name": "血契",
		"category": "armor",
		"description": "出血中の敵からの被ダメ -15%。出血中の敵への与ダメ +10%。",
		"outgoing_vs_status_mult": 1.10,
		"outgoing_vs_status_ids": ["bleed"],
		"incoming_vs_status_mult": 0.85,
		"incoming_vs_status_ids": ["bleed"],
	},
	"eq_flurry_mail": {
		"display_name": "連撃の余熱",
		"category": "armor",
		"description": "被ダメ -8%。3回攻撃するたび最大HPの2%を回復する。",
		"incoming_mult": 0.92,
		"trigger": "on_attack",
		"condition": "always",
		"effect": "heal",
		"target": "self",
		"heal_max_hp_fraction": 0.02,
		"every_n": 3,
		"cooldown": 0.0,
	},
	"eq_bulwark_role": {
		"display_name": "盾役の構え",
		"category": "armor",
		"description": "敵の注目を大きく集める。前列で被弾すると防御をまとい再度注目を集める（再使用5秒）。",
		"threat_base_add": 100.0,
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "taunt_and_guard",
		"passive_condition": "front_row_only",
		"cooldown": 5.0,
	},
	"eq_cover_aegis": {
		"display_name": "庇護の外套",
		"category": "armor",
		"description": "いちばん傷ついた味方の被ダメ -12%。自身の被ダメ +5%。",
		"cover_ally_incoming_mult": 0.88,
		"incoming_mult": 1.05,
	},
	"eq_hexweave_robe": {
		"display_name": "呪縛の織",
		"category": "armor",
		"description": "場の敵が持つデバフ種類1つにつき被ダメ -3%（最大 -15%）。",
		"incoming_per_enemy_debuff": 0.03,
		"incoming_per_enemy_debuff_cap": 0.15,
	},
	"eq_blade_dance_ring": {
		"display_name": "剣舞の鼓動",
		"category": "accessory",
		"description": "必殺チャージ速度 +15%。スキル再使用が 10% 速くなる。",
		"ultimate_charge_dealt_mult": 1.15,
		"skill_cd_mult": 0.90,
	},
	"eq_pierce_charm": {
		"display_name": "急所の余勢",
		"category": "accessory",
		"description": "会心ダメージ +15%。どの職でも有効。",
		"crit_damage_add": 0.15,
	},
	"eq_pulse_amulet": {
		"display_name": "鼓動の充填",
		"category": "accessory",
		"description": "必殺チャージ速度 +35%。スキル再使用が 15% 遅くなる。",
		"ultimate_charge_dealt_mult": 1.35,
		"skill_cd_mult": 1.15,
	},
	"eq_beastlord_fang": {
		"display_name": "獣使いの牙",
		"category": "accessory",
		"description": "ペット与ダメ +25%／防御 +10%。自身の与ダメ -8%。",
		"pet_outgoing_mult": 1.25,
		"pet_defense_mult": 1.10,
		"outgoing_mult": 0.92,
	},
	"eq_apothecary_vial": {
		"display_name": "調剤師の薬",
		"category": "accessory",
		"description": "回復スキル効果 +20%。回復した味方に防御を付与する。",
		"heal_power_mult": 1.20,
		"heal_applies_guard": true,
	},
	## ペット／ヒーラービルド（P3-EQ-PET-HEAL-BUILD-001 / 54）
	"eq_beastcall_mantle": {
		"display_name": "獣呼びの指揮",
		"category": "armor",
		"description": "ペット与ダメ +18%／防御 +10%。自身の与ダメ -6%。",
		"pet_outgoing_mult": 1.18,
		"pet_defense_mult": 1.10,
		"outgoing_mult": 0.94,
	},
	"eq_field_salve_robe": {
		"display_name": "野戦調剤の衣",
		"category": "armor",
		"description": "回復スキル効果 +15%。自身の与ダメ -10%。",
		"heal_power_mult": 1.15,
		"outgoing_mult": 0.90,
	},
	"eq_pack_whistle_charm": {
		"display_name": "群れ笛",
		"category": "accessory",
		"description": "ペット与ダメ +8%。",
		"pet_outgoing_mult": 1.08,
	},
	"eq_salve_band": {
		"display_name": "軟膏の腕輪",
		"category": "accessory",
		"description": "回復スキル効果 +8%。",
		"heal_power_mult": 1.08,
	},
	# ---- レリック（P3-BAL-RELIC-REMAKE-001 / 53_RelicRuleRemake・案Aメリット寄り） ----
	"relic_war_banner": {
		"display_name": "指揮の軍旗",
		"category": "relic",
		"description": "撃破時に味方を鼓舞。ペット与ダメ +20%／防御 +10%",
		"pet_outgoing_mult": 1.20,
		"pet_defense_mult": 1.10,
		"trigger": "on_kill",
		"condition": "always",
		"effect": "party_rally",
		"status_id": "empower",
		"cooldown": 0.0,
	},
	"relic_aegis_shard": {
		"display_name": "身代わりの鏡",
		"category": "relic",
		"description": "後衛が狙われたとき 40% で自分が代わりに受け、防御を得る",
		"redirect_rear_hit_chance": 0.40,
	},
	"relic_old_hourglass": {
		"display_name": "連撃の歯車",
		"category": "relic",
		"description": "スキル再使用が 15% 速くなる",
		"skill_cd_mult": 0.85,
	},
	"relic_berserker_charm": {
		"display_name": "生命の脈",
		"category": "relic",
		"description": "戦闘中 3 秒ごとに最大HPの 1.5% 回復",
		"combat_regen_interval_sec": 3.0,
		"combat_regen_max_hp_fraction": 0.015,
	},
	"relic_hunter_sigil": {
		"display_name": "一騎の契",
		"category": "relic",
		"description": "標的の敵へ与ダメ +25%。攻撃前に標的を付与",
		"pre_hit_status_id": "mark",
		"outgoing_vs_status_mult": 1.25,
		"outgoing_vs_status_ids": ["mark"],
	},
	"relic_reactive_aegis": {
		"display_name": "吸血契約",
		"category": "relic",
		"description": "与ダメの 8% を自身が回復",
		"lifesteal_ratio": 0.08,
	},
	"relic_lament_ring": {
		"display_name": "不死鳥の羽",
		"category": "relic",
		"description": "戦闘中1回、致死を耐えて最大HPの 20% で復帰",
		"death_save_once": true,
		"death_save_heal_max_hp_fraction": 0.20,
	},
	"relic_scout_lens": {
		"display_name": "宝箱の羅針",
		"category": "relic",
		"description": "宝箱部屋の出現率が上がる（戦闘火力には影響しない）",
		"treasure_room_weight_add": 20,
	},
	"eq_wpn_consecrated_maul": {
		"display_name": "祝槌の癒し",
		"category": "weapon",
		"description": "攻撃のたびに自身のHPを5%回復する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "heal",
		"target": "self",
		"heal_max_hp_fraction": 0.05,
		"cooldown": 0.0,
	},
	"eq_wpn_silvaria_oathblade": {
		"display_name": "森護の誓盾",
		"category": "weapon",
		"description": "被弾時20%で受けるダメージを75%軽減する。",
		"incoming_block_chance": 0.20,
		"incoming_block_mult": 0.25,
	},
	"eq_wpn_veld_branch_staff": {
		"display_name": "翠枝の秘術",
		"category": "weapon",
		"description": "装備スキルの与ダメージ +35%。",
		"skill_power_mult": 1.35,
	},
	"eq_wpn_nereidas_tideblade": {
		"display_name": "潮汐の慧眼",
		"category": "weapon",
		"description": "会心率 +15% / 会心ダメ +50%。",
		"crit_rate_add": 0.15,
		"crit_damage_add": 0.50,
	},
	"eq_wpn_pharoslight_staff": {
		"display_name": "灯守の極意",
		"category": "weapon",
		"description": "必殺技の与ダメージ +50%。",
		"ultimate_power_mult": 1.50,
	},
	"eq_wpn_volgrave_thunderblade": {
		"display_name": "沼断ちの雷勢",
		"category": "weapon",
		"description": "雷属性確定。ショックの敵へ与ダメ+40%。攻撃時25%でショックを付与。",
		"forced_element": "thunder",
		"guaranteed_element_power_roll": true,
		"element_outgoing_mult": {"thunder": 1.10},
		"outgoing_vs_status_mult": 1.40,
		"outgoing_vs_status_ids": ["shock"],
		"trigger": "on_attack",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "shock",
		"target": "enemy",
		"status_chance": 0.25,
		"cooldown": 0.0,
	},
	"eq_wpn_seradion_storm_staff": {
		"display_name": "雷典の学識",
		"category": "weapon",
		"description": "装備キャラの獲得経験値が2倍になる。",
		"exp_gain_mult": 2.0,
	},
	"eq_wpn_eldion_frostbrand": {
		"display_name": "始祖の二律",
		"category": "weapon",
		"description": "氷属性確定。冷却の敵へ与ダメ+40%。攻撃時25%で冷却を付与。",
		"forced_element": "ice",
		"guaranteed_element_power_roll": true,
		"element_outgoing_mult": {"ice": 1.10},
		"outgoing_vs_status_mult": 1.40,
		"outgoing_vs_status_ids": ["chill"],
		"trigger": "on_attack",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "chill",
		"target": "enemy",
		"status_chance": 0.25,
		"cooldown": 0.0,
	},
	"eq_wpn_umbra_terminus_staff": {
		"display_name": "終末の帳",
		"category": "weapon",
		"description": "攻撃のたびに敵へランダムな状態異常を付与する。",
		"trigger": "on_attack",
		"condition": "always",
		"effect": "random_enemy_status",
		"status_pool": ["poison", "chill", "shock", "ignite", "curse", "fear", "bleed"],
		"cooldown": 0.0,
	},
	"eq_wpn_sanctified_dagger": {
		"display_name": "霊廟の呪詛",
		"category": "weapon",
		"description": "戦闘開始時、敵全体に呪いを付与する。",
		"trigger": "on_combat_start",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "curse",
		"target": "enemy_all",
		"cooldown": 0.0,
	},
	# ---- 弓／双刃レジェンド拡充（P3-EQ-LEG-WPN-BOW-DUAL-001） ----
	"eq_wpn_eldion_spine": {
		"display_name": "始祖の霜矢",
		"category": "weapon",
		"description": "氷属性確定。後列の通常攻撃 +25%。冷却の敵へ与ダメ +20%。",
		"forced_element": "ice",
		"guaranteed_element_power_roll": true,
		"element_outgoing_mult": {"ice": 1.10},
		"back_row_basic_attack_mult": 1.25,
		"outgoing_vs_status_mult": 1.20,
		"outgoing_vs_status_ids": ["chill"],
	},
	"eq_wpn_pharos_flare": {
		"display_name": "烽火の鼓動",
		"category": "weapon",
		"description": "必殺チャージ速度 +75%。装備スキル与ダメ +15%。",
		"ultimate_charge_dealt_mult": 1.75,
		"skill_power_mult": 1.15,
	},
	"eq_wpn_shadowcord": {
		"display_name": "影弦の急所",
		"category": "weapon",
		"description": "会心率 +10% / 会心ダメ +40%。撃破時に自身へ鼓舞。",
		"crit_rate_add": 0.10,
		"crit_damage_add": 0.40,
		"trigger": "on_kill",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "empower",
		"target": "self",
		"cooldown": 0.0,
	},
	"eq_wpn_silvaria_fang": {
		"display_name": "黒陽の双牙",
		"category": "weapon",
		"description": "炎属性確定。炎上の敵へ与ダメ+40%。攻撃時25%で炎上を付与。",
		"forced_element": "fire",
		"guaranteed_element_power_roll": true,
		"element_outgoing_mult": {"fire": 1.10},
		"outgoing_vs_status_mult": 1.40,
		"outgoing_vs_status_ids": ["ignite"],
		"trigger": "on_attack",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "ignite",
		"target": "enemy",
		"status_chance": 0.25,
		"cooldown": 0.0,
	},
	"eq_wpn_eldion_claw": {
		"display_name": "始祖の霜爪",
		"category": "weapon",
		"description": "氷属性確定。冷却の敵へ与ダメ+30%。3撃ごとに冷却を付与。",
		"forced_element": "ice",
		"guaranteed_element_power_roll": true,
		"element_outgoing_mult": {"ice": 1.05},
		"outgoing_vs_status_mult": 1.30,
		"outgoing_vs_status_ids": ["chill"],
		"trigger": "on_attack",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "chill",
		"target": "enemy",
		"status_chance": 1.0,
		"every_n": 3,
		"cooldown": 0.0,
	},
	# ---- 天候シンクロ・レジェンド（P3-EQ-WEATHER-LEG-001） ----
	"eq_wpn_stormveil_needle": {
		"display_name": "雷雨の穿針",
		"category": "weapon",
		"description": "雷属性与ダメ+15%。雨のとき雷与ダメ+40%。",
		"forced_element": "thunder",
		"guaranteed_element_power_roll": true,
		"element_outgoing_mult": {"thunder": 1.15},
		"weather_bonus": {
			"rain": {
				"element_outgoing_mult": {"thunder": 1.40},
			},
		},
	},
	"eq_wpn_noctumbra_fang": {
		"display_name": "宵闇の牙",
		"category": "weapon",
		"description": "闇属性与ダメ+15%。夜のとき闇与ダメ+40%、撃破時に自身の行動待ちを短縮。",
		"forced_element": "dark",
		"guaranteed_element_power_roll": true,
		"element_outgoing_mult": {"dark": 1.15},
		"trigger": "on_kill",
		"effect": "refund_ct",
		"refund_ct_fraction": 0.0,
		"weather_bonus": {
			"night": {
				"element_outgoing_mult": {"dark": 1.40},
				"refund_ct_fraction": 0.50,
			},
		},
	},
	"eq_wpn_mistpierce_halberd": {
		"display_name": "霧穿ちの戦鉾",
		"category": "weapon",
		"description": "会心率+3%。霧のとき与ダメ+26%、会心率+10%。",
		"crit_rate_add": 0.03,
		"weather_bonus": {
			"fog": {
				"outgoing_mult": 1.263,
				"crit_rate_add": 0.10,
			},
		},
	},
	# ---- 深層限定レジェンド（P3-DG-ABYSS-001-C / P3-DG-ABYSS-LEG-001） ----
	"eq_abyss_veinblade": {
		"display_name": "虚脈裂傷",
		"category": "weapon",
		"description": "HPが低いほど与ダメ上昇（最大+40%）。撃破時、他の敵へ鉱物裂傷（与ダメの40%）。",
		"missing_hp_outgoing_bonus": 0.40,
		"trigger": "on_kill",
		"condition": "always",
		"effect": "aoe_burst",
		"aoe_burst_fraction": 0.40,
		"cooldown": 0.0,
	},
	"eq_abyss_rootfang": {
		"display_name": "根葬連撃",
		"category": "weapon",
		"description": "同一敵への連続ヒットで与ダメが段階上昇（+8%/最大5）。対象が変わるとリセット。",
		"same_target_stack_bonus": 0.08,
		"same_target_stack_max": 5,
	},
	"eq_abyss_mirestaff": {
		"display_name": "澱みの霧ガード",
		"category": "weapon",
		"description": "被弾時に霧ガード（被ダメ半減）を付与する（再使用8秒）。",
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "apply_status",
		"status_id": "guard",
		"target": "self",
		"cooldown": 8.0,
	},
	"eq_abyss_netherbow": {
		"display_name": "虚潮の印",
		"category": "weapon",
		"description": "命中で潮汐印。同一敵に4積で爆発（そのヒットの150%追撃）。",
		"tide_mark_threshold": 4,
		"tide_mark_burst_fraction": 1.50,
	},
	"eq_abyss_riftclaw": {
		"display_name": "裂氷の氷殻",
		"category": "weapon",
		"description": "被弾時またはHP40%未満で氷殻（被ダメ-35%、4秒）。氷殻中は反撃する（再使用6秒）。",
		"ice_shell_incoming_mult": 0.65,
		"ice_shell_duration_sec": 4.0,
		"ice_shell_hp_threshold": 0.40,
		"trigger": "on_hit_taken",
		"condition": "always",
		"effect": "abyss_ice_shell_counter",
		"cooldown": 6.0,
	},
	# ---- 弓／杖レジェンド数揃え（P3-EQ-LEG-WPN-FILL-001） ----
	"eq_wpn_volley_horizon_bow": {
		"display_name": "地平の斉射",
		"category": "weapon",
		"description": "通常攻撃が敵全体へ届く（主対象以外は55%）。",
		"basic_attack_hits_all": true,
		"basic_aoe_splash_mult": 0.55,
	},
	"eq_wpn_vanguard_war_bow": {
		"display_name": "戦列の猛矢",
		"category": "weapon",
		"description": "前列: 与ダメ×2.0／被ダメ×1.5。後列: 与ダメ×1.25／被ダメ×1.1。",
		"outgoing_mult": 2.0,
		"incoming_mult": 1.5,
		"back_row_outgoing_mult": 1.25,
		"back_row_incoming_mult": 1.1,
		"passive_condition": "front_row_only",
	},
	"eq_wpn_regicide_longbow": {
		"display_name": "王討ちの矢",
		"category": "weapon",
		"description": "ボスへの与ダメ×1.5。",
		"outgoing_vs_boss_mult": 1.5,
	},
	"eq_wpn_amplify_orb_staff": {
		"display_name": "増幅の珠",
		"category": "weapon",
		"description": "通常攻撃の与ダメ +35%。",
		"basic_attack_mult": 1.35,
	},
	"eq_wpn_silent_rite_staff": {
		"display_name": "黙撃の秘儀",
		"category": "weapon",
		"description": "通常攻撃不可。装備スキルの与ダメ×2.0。",
		"disable_basic_attack": true,
		"skill_power_mult": 2.0,
	},
	## P3-BAL-LEG-WPN-A001 — ビルド穴埋めレジェンド
	"eq_wpn_packbond_staff": {
		"display_name": "絆笛の号令",
		"category": "weapon",
		"description": "ペットの与ダメ +30%／防御 +10%。",
		"pet_outgoing_mult": 1.30,
		"pet_defense_mult": 1.10,
	},
	"eq_wpn_mendweaver_staff": {
		"display_name": "癒織",
		"category": "weapon",
		"description": "回復スキル効果 +22%。自身の与ダメ -8%。",
		"heal_power_mult": 1.22,
		"outgoing_mult": 0.92,
	},
	"eq_wpn_blightcord_bow": {
		"display_name": "腐血の影弦",
		"category": "weapon",
		"description": "毒・出血の敵へ与ダメ +35%。攻撃時25%で毒か出血を付与。",
		"outgoing_vs_status_mult": 1.35,
		"outgoing_vs_status_ids": ["poison", "bleed"],
		"trigger": "on_attack",
		"condition": "always",
		"effect": "random_enemy_status",
		"status_pool": ["poison", "bleed"],
		"status_chance": 0.25,
		"cooldown": 0.0,
	},
	"eq_wpn_pulsekeen_edge": {
		"display_name": "脈打つ閃刃",
		"category": "weapon",
		"description": "会心時、必殺ゲージ+8＆ヒットの35%を追加ダメージ。",
		"crit_rate_add": 0.05,
		"trigger": "on_attack",
		"condition": "is_critical",
		"effect": "crit_pulse",
		"ultimate_charge_flat": 8.0,
		"bonus_damage_fraction": 0.35,
		"cooldown": 0.0,
	},
	"eq_wpn_aegis_line_sword": {
		"display_name": "防壁の戦剣",
		"category": "weapon",
		"description": "敵の注目を集めやすくなり、被ダメージが12%軽減する。",
		"threat_base_add": 120.0,
		"incoming_mult": 0.88,
	},
	# ---- 灰冠の九（P3-GACHA-EQ-KAIWAN／S2・F2・W1） ----
	"eq_wpn_kaiwan_silent": {
		"display_name": "裂鍵の刺し",
		"category": "weapon",
		"description": "バフ中の敵への与ダメ +25%。スキル再使用時間 +10%。",
		"outgoing_vs_buff_mult": 1.25,
		"skill_cd_mult": 1.10,
	},
	"eq_wpn_kaiwan_false": {
		"display_name": "偽星の鋭閃",
		"category": "weapon",
		"description": "会心ダメ +30%。被クリティカル率 +10%。",
		"crit_damage_add": 0.30,
		"incoming_crit_rate_add": 0.10,
	},
	"eq_wpn_kaiwan_wiltes": {
		"display_name": "枯翠の棘癒",
		"category": "weapon",
		"description": "回復スキル時、最弱敵へ回復量の40%相当ダメ。被回復 -20%。",
		"heal_skill_spill_damage_fraction": 0.40,
		"heal_received_mult": 0.80,
	},
	"eq_kaiwan_thornmail": {
		"display_name": "枯翠の棘甲",
		"category": "armor",
		"description": "回復スキル追撃 +15pt。被回復 -20%。",
		"heal_skill_spill_damage_add": 0.15,
		"heal_received_mult": 0.80,
	},
}

# 基本5職ロスター adventurer_id → キャラ固有パッシブ id
const RELIC_PASSIVE_ORDER: Array[String] = [
	"relic_war_banner", "relic_aegis_shard", "relic_old_hourglass", "relic_berserker_charm",
	"relic_hunter_sigil", "relic_reactive_aegis", "relic_lament_ring", "relic_scout_lens",
]

const RELIC_LEGACY_TO_PASSIVE: Dictionary = {
	"war_banner": "relic_war_banner",
	"aegis_shard": "relic_aegis_shard",
	"old_hourglass": "relic_old_hourglass",
	"berserker_charm": "relic_berserker_charm",
	"hunter_sigil": "relic_hunter_sigil",
	"reactive_aegis": "relic_reactive_aegis",
	"lament_ring": "relic_lament_ring",
	"scout_lens": "relic_scout_lens",
}

const _BASE_ROSTER_PASSIVES: Dictionary = {
	"adventurer_0": "ald_royal_flame",
	"adventurer_1": "riva_lone_focus",
	"adventurer_2": "elias_field_elixir",
	"adventurer_3": "galen_sacred_bastion",
	"adventurer_4": "mirei_swarm_resonance",
}


## 基本ロスターの固有パッシブ id（図鑑／UI 用）。未登録は空文字。
static func base_roster_passive_id(adventurer_id: String) -> String:
	return str(_BASE_ROSTER_PASSIVES.get(adventurer_id, ""))


# ジョブ → パッシブ id（基本ロスター以外のフォールバック）
const _JOB_PASSIVES: Dictionary = {
	"vanguard": ["bulwark"],
	"swordsman": ["battle_fervor"],
	"ranger": ["foresight"],
	"alchemist": ["field_medic"],
	"beast_tamer": ["pack_instinct"],
}

# ★3 / ★4 職帯パッシブ定義（データ残置）。P3-PASSIVE-CHAR-001 案αにより
# 自動付与・選択プールからは外し、差別化はキャラ固有のみ。
const _STAR3_JOB_PASSIVES: Dictionary = {
	"swordsman": "sword_charge",
	"ranger": "wind_reading",
	"alchemist": "spare_vial",
	"vanguard": "unyielding_stance",
	"beast_tamer": "tamer_whistle",
}
const _STAR4_JOB_PASSIVES: Dictionary = {
	"swordsman": "royal_sword_doctrine",
	"ranger": "formation_eye",
	"alchemist": "panacea_gift",
	"vanguard": "greatshield_order",
	"beast_tamer": "herd_king_roar",
}

# レア度に応じた職固有ティアパッシブ定義（該当なしは空 Dictionary）。
# 案α: 装備プールには載せない（定義照会・テスト用に残置）。
static func tier_def_for(job_id: String, rarity: int) -> Dictionary:
	if rarity >= 4:
		return _def_with_id(str(_STAR4_JOB_PASSIVES.get(job_id, "")))
	if rarity == 3:
		return _def_with_id(str(_STAR3_JOB_PASSIVES.get(job_id, "")))
	return {}

## 戦闘中のみ有効な被弾反撃チャージ（VG 応撃の構など）。
static var _combat_counter_charges: Dictionary = {}


static func reset_combat_scoped() -> void:
	_combat_member_evasion_add.clear()
	_combat_counter_charges.clear()


static func grant_combat_evasion(member_index: int, amount: float) -> void:
	if member_index < 0 or amount <= 0.0:
		return
	var cur: float = float(_combat_member_evasion_add.get(member_index, 0.0))
	_combat_member_evasion_add[member_index] = cur + amount


static func grant_combat_counter_charges(member_index: int, charges: int) -> void:
	if member_index < 0 or charges <= 0:
		return
	var cur: int = int(_combat_counter_charges.get(member_index, 0))
	_combat_counter_charges[member_index] = cur + charges


static func consume_combat_counter_charge(member_index: int) -> bool:
	if member_index < 0:
		return false
	var cur: int = int(_combat_counter_charges.get(member_index, 0))
	if cur <= 0:
		return false
	_combat_counter_charges[member_index] = cur - 1
	return true


const TRAIL_WARD_SKILL_ID: String = "trail_ward"
const TRAIL_WARD_TRAP_MULT: float = 0.75
const TRAIL_WARD_NONCOMBAT_HEAL_FRAC: float = 0.05


## 装備中の探索適性スキル（踏破の護符）による罠ダメ倍率。
static func equipped_exploration_trap_mult_for_member(member: Resource) -> float:
	if member == null:
		return 1.0
	if _member_has_equipped_skill(member, TRAIL_WARD_SKILL_ID):
		return TRAIL_WARD_TRAP_MULT
	return 1.0


static func party_has_trail_ward_equipped() -> bool:
	for i: int in GameState.combatant_count():
		var m: Resource = GameState.get_combatant(i)
		if m != null and _member_has_equipped_skill(m, TRAIL_WARD_SKILL_ID):
			return true
	return false


static func _member_has_equipped_skill(member: Resource, skill_id: String) -> bool:
	if member == null or skill_id.is_empty():
		return false
	var ids: Array[String] = GameState.get_equipped_skill_ids(member)
	return ids.has(skill_id)


static func get_def(passive_id: String) -> Dictionary:
	return _def_with_id(passive_id)


static func all_def_ids() -> Array:
	return _DEFS.keys()

static func migrate_relic_passive_id(raw_id: String) -> String:
	var pid: String = str(raw_id)
	if pid.is_empty():
		return ""
	if _DEFS.has(pid):
		return pid
	return str(RELIC_LEGACY_TO_PASSIVE.get(pid, ""))

static func is_relic_passive(passive_id: String) -> bool:
	if passive_id.is_empty():
		return false
	var def: Dictionary = _DEFS.get(passive_id, {})
	return str(def.get("category", "")) == "relic"

static func is_weapon_passive(passive_id: String) -> bool:
	if passive_id.is_empty():
		return false
	var def: Dictionary = _DEFS.get(passive_id, {})
	return str(def.get("category", "")) == "weapon"

static func weapon_passive_def_for_member(member: Resource) -> Dictionary:
	if member == null:
		return {}
	var weapon: Resource = member.equipped_weapon if "equipped_weapon" in member else null
	if weapon == null or str(weapon.weapon_id).is_empty():
		return {}
	var weapon_data: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	if weapon_data == null:
		return {}
	var pid: String = str(weapon_data.fixed_passive_id) if "fixed_passive_id" in weapon_data else ""
	if pid.is_empty():
		return {}
	return get_def(pid)

static func weapon_stat_modifiers_for_member(member_index: int) -> Dictionary:
	var out: Dictionary = {
		"skill_power_mult": 1.0,
		"ultimate_power_mult": 1.0,
		"crit_rate_add": 0.0,
		"crit_damage_add": 0.0,
		"exp_gain_mult": 1.0,
		"incoming_block_chance": 0.0,
		"incoming_block_mult": 1.0,
		"element_outgoing_mult": {},
		"basic_attack_mult": 1.0,
		"outgoing_vs_boss_mult": 1.0,
		"basic_attack_hits_all": false,
		"basic_aoe_splash_mult": 1.0,
		"disable_basic_attack": false,
	}
	if member_index < 0 or member_index >= GameState.party_members.size():
		return out
	var def: Dictionary = weapon_passive_def_for_member(GameState.party_members[member_index])
	if not def.is_empty():
		if def.has("skill_power_mult"):
			out["skill_power_mult"] = float(def["skill_power_mult"])
		if def.has("ultimate_power_mult"):
			out["ultimate_power_mult"] = float(def["ultimate_power_mult"])
		if def.has("crit_rate_add"):
			out["crit_rate_add"] = float(def["crit_rate_add"])
		if def.has("crit_damage_add"):
			out["crit_damage_add"] = float(def["crit_damage_add"])
		if def.has("exp_gain_mult"):
			out["exp_gain_mult"] = float(def["exp_gain_mult"])
		if def.has("outgoing_mult"):
			out["outgoing_mult"] = float(def["outgoing_mult"])
		if def.has("incoming_block_chance"):
			out["incoming_block_chance"] = float(def["incoming_block_chance"])
		if def.has("incoming_block_mult"):
			out["incoming_block_mult"] = float(def["incoming_block_mult"])
		if def.has("basic_attack_mult"):
			out["basic_attack_mult"] = float(def["basic_attack_mult"])
		if def.has("outgoing_vs_boss_mult"):
			out["outgoing_vs_boss_mult"] = float(def["outgoing_vs_boss_mult"])
		if def.has("basic_attack_hits_all"):
			out["basic_attack_hits_all"] = bool(def["basic_attack_hits_all"])
		if def.has("basic_aoe_splash_mult"):
			out["basic_aoe_splash_mult"] = float(def["basic_aoe_splash_mult"])
		if def.has("disable_basic_attack"):
			out["disable_basic_attack"] = bool(def["disable_basic_attack"])
		if def.has("element_outgoing_mult") and def["element_outgoing_mult"] is Dictionary:
			out["element_outgoing_mult"] = (def["element_outgoing_mult"] as Dictionary).duplicate()
		_merge_weapon_weather_bonus(def, out)
	## 防具／装飾の crit_* も会心計算に載せる（武器専用キーだった穴を埋める）。
	var member: Resource = GameState.party_members[member_index]
	var weapon_pid: String = str(def.get("id", ""))
	for raw_eq: Variant in _equipment_passives_for_member(member):
		if raw_eq is not Dictionary:
			continue
		var eq_def: Dictionary = raw_eq
		var eq_id: String = str(eq_def.get("id", ""))
		if not weapon_pid.is_empty() and eq_id == weapon_pid:
			continue
		if eq_def.has("crit_rate_add"):
			out["crit_rate_add"] = float(out["crit_rate_add"]) + float(eq_def["crit_rate_add"])
		if eq_def.has("crit_damage_add"):
			out["crit_damage_add"] = float(out["crit_damage_add"]) + float(eq_def["crit_damage_add"])
	return out


static func _active_weather_bonus(def: Dictionary) -> Dictionary:
	if def.is_empty() or not def.has("weather_bonus"):
		return {}
	var bonuses: Variant = def.get("weather_bonus", {})
	if bonuses is not Dictionary:
		return {}
	var weather: String = GameState.get_weather()
	if weather.is_empty() or not (bonuses as Dictionary).has(weather):
		return {}
	var block: Variant = (bonuses as Dictionary)[weather]
	if block is not Dictionary:
		return {}
	return (block as Dictionary).duplicate()


static func _merge_weapon_weather_bonus(def: Dictionary, out: Dictionary) -> void:
	var bonus: Dictionary = _active_weather_bonus(def)
	if bonus.is_empty():
		return
	if bonus.has("crit_rate_add"):
		out["crit_rate_add"] = float(out.get("crit_rate_add", 0.0)) + float(bonus["crit_rate_add"])
	if bonus.has("crit_damage_add"):
		out["crit_damage_add"] = float(out.get("crit_damage_add", 0.0)) + float(bonus["crit_damage_add"])
	if bonus.has("outgoing_mult"):
		out["outgoing_mult"] = float(out.get("outgoing_mult", 1.0)) * float(bonus["outgoing_mult"])
	if bonus.has("element_outgoing_mult") and bonus["element_outgoing_mult"] is Dictionary:
		var merged: Dictionary = out.get("element_outgoing_mult", {}).duplicate()
		for key: Variant in (bonus["element_outgoing_mult"] as Dictionary).keys():
			merged[str(key)] = float((bonus["element_outgoing_mult"] as Dictionary)[key])
		out["element_outgoing_mult"] = merged

## hp_ratio: 0..1。負なら HP 条件付き outgoing は適用しない（非戦闘参照用）。
static func character_stat_modifiers_for_member(member_index: int, hp_ratio: float = -1.0) -> Dictionary:
	var out: Dictionary = {
		"evasion_rate_add": 0.0,
		"ultimate_power_mult": 1.0,
		"exp_gain_mult": 1.0,
		"outgoing_mult": 1.0,
		"incoming_mult": 1.0,
		"first_attack_mult": 1.0,
		"elemental_outgoing_mult": 1.0,
	}
	if member_index < 0 or member_index >= GameState.party_members.size():
		return out
	var member: Resource = GameState.party_members[member_index]
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if str(def.get("category", "")) in ["relic", "weapon"]:
			continue
		if def.has("evasion_rate_add"):
			out["evasion_rate_add"] += float(def["evasion_rate_add"])
		if def.has("back_row_evasion_rate_add") and GameState.is_member_back_row(member_index):
			out["evasion_rate_add"] += float(def["back_row_evasion_rate_add"])
		for key: String in [
			"ultimate_power_mult", "exp_gain_mult", "incoming_mult", "first_attack_mult", "elemental_outgoing_mult"
		]:
			if def.has(key):
				out[key] *= float(def[key])
		if def.has("outgoing_mult"):
			var need_below: float = float(def.get("outgoing_mult_requires_hp_below", -1.0))
			if need_below >= 0.0:
				if hp_ratio >= 0.0 and hp_ratio <= need_below:
					out["outgoing_mult"] *= float(def["outgoing_mult"])
			else:
				out["outgoing_mult"] *= float(def["outgoing_mult"])
	out["evasion_rate_add"] += float(_combat_member_evasion_add.get(member_index, 0.0))
	# 武器常時 outgoing／incoming（神話・前列限定など）＋天候シンクロ outgoing
	var wdef: Dictionary = weapon_passive_def_for_member(member)
	var front_only: bool = str(wdef.get("passive_condition", "")) == "front_row_only"
	var is_back: bool = GameState.is_member_back_row(member_index)
	if front_only:
		if is_back:
			if wdef.has("back_row_outgoing_mult"):
				out["outgoing_mult"] *= float(wdef["back_row_outgoing_mult"])
			if wdef.has("back_row_incoming_mult"):
				out["incoming_mult"] *= float(wdef["back_row_incoming_mult"])
		else:
			## 常時与ダメ乗算は trigger と独立（on_attack は付与効果のみのゲート）。
			if wdef.has("outgoing_mult"):
				out["outgoing_mult"] *= float(wdef["outgoing_mult"])
			if wdef.has("incoming_mult"):
				out["incoming_mult"] *= float(wdef["incoming_mult"])
	else:
		if wdef.has("outgoing_mult"):
			out["outgoing_mult"] *= float(wdef["outgoing_mult"])
		if wdef.has("incoming_mult"):
			out["incoming_mult"] *= float(wdef["incoming_mult"])
	var wbonus: Dictionary = _active_weather_bonus(wdef)
	if wbonus.has("outgoing_mult"):
		out["outgoing_mult"] *= float(wbonus["outgoing_mult"])
	return out


static func weapon_disables_basic_attack(member_index: int) -> bool:
	return bool(weapon_stat_modifiers_for_member(member_index).get("disable_basic_attack", false))


static func weapon_basic_attack_mult(member_index: int) -> float:
	var mult: float = maxf(0.0, float(weapon_stat_modifiers_for_member(member_index).get("basic_attack_mult", 1.0)))
	if member_index < 0 or member_index >= GameState.party_members.size():
		return mult
	var def: Dictionary = weapon_passive_def_for_member(GameState.party_members[member_index])
	if def.has("back_row_basic_attack_mult") and GameState.is_member_back_row(member_index):
		mult *= float(def["back_row_basic_attack_mult"])
	return mult


static func weapon_basic_hits_all(member_index: int) -> bool:
	return bool(weapon_stat_modifiers_for_member(member_index).get("basic_attack_hits_all", false))


static func weapon_basic_aoe_splash_mult(member_index: int) -> float:
	return clampf(float(weapon_stat_modifiers_for_member(member_index).get("basic_aoe_splash_mult", 1.0)), 0.0, 1.0)


static func weapon_outgoing_vs_boss_mult(member_index: int) -> float:
	return maxf(0.0, float(weapon_stat_modifiers_for_member(member_index).get("outgoing_vs_boss_mult", 1.0)))

static func party_outgoing_mult() -> float:
	var mult: float = 1.0
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		for raw_def: Variant in _equipment_passives_for_member(member):
			if raw_def is not Dictionary:
				continue
			var def: Dictionary = raw_def
			if def.has("party_outgoing_mult"):
				mult *= float(def["party_outgoing_mult"])
	return mult


## 編成メンバーのキャラ／ジョブパッシブからペット与ダメ倍率（ペット未所持なら 1.0）。
static func pet_outgoing_mult_from_party() -> float:
	if GameState.active_pet == null:
		return 1.0
	var mult: float = 1.0
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		for def: Dictionary in for_member(member):
			if def.has("pet_outgoing_mult"):
				mult *= float(def["pet_outgoing_mult"])
	return mult


## 編成メンバーのパッシブからペット防御倍率（ペット未所持なら 1.0）。
static func pet_defense_mult_from_party() -> float:
	if GameState.active_pet == null:
		return 1.0
	var mult: float = 1.0
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		for def: Dictionary in for_member(member):
			if def.has("pet_defense_mult"):
				mult *= float(def["pet_defense_mult"])
	return mult


## 編成メンバーのパッシブからペット最大HP倍率（ペット未所持なら 1.0）。
static func pet_max_hp_mult_from_party() -> float:
	if GameState.active_pet == null:
		return 1.0
	var mult: float = 1.0
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		for def: Dictionary in for_member(member):
			if def.has("pet_max_hp_mult"):
				mult *= float(def["pet_max_hp_mult"])
	return mult


## 戦闘終了時ペット蘇生の最良チャンス／回復割合（誰も持たなければ空）。
static func pet_revive_on_combat_end_def() -> Dictionary:
	var best_chance: float = 0.0
	var best_frac: float = 0.30
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		for def: Dictionary in for_member(member):
			var chance: float = float(def.get("pet_revive_on_combat_end_chance", 0.0))
			if chance <= best_chance:
				continue
			best_chance = chance
			best_frac = float(def.get("pet_revive_max_hp_fraction", 0.30))
	if best_chance <= 0.0:
		return {}
	return {
		"chance": best_chance,
		"max_hp_fraction": best_frac,
	}


## 行動開始時のペット回復割合（該当パッシブの合算ではなく最大）。
static func pet_heal_on_action_fraction_for_member(member: Resource) -> float:
	if member == null:
		return 0.0
	var best: float = 0.0
	for def: Dictionary in for_member(member):
		best = maxf(best, float(def.get("pet_heal_on_action_max_hp_fraction", 0.0)))
	return best


static func threat_base_add_for_member(member: Resource) -> float:
	if member == null:
		return 0.0
	var add: float = 0.0
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if def.has("threat_base_add"):
			add += float(def["threat_base_add"])
	return add


## パッシブ固有の行動スキップ確率（合計。状態異常スキップとは別判定）。
static func action_skip_chance_for_member(member: Resource) -> float:
	if member == null:
		return 0.0
	var chance: float = 0.0
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if str(def.get("category", "")) in ["relic", "weapon"]:
			continue
		chance += float(def.get("action_skip_chance", 0.0))
	return clampf(chance, 0.0, 1.0)


## 行動スキップ時のログ用ラベル（最初に action_skip_chance を持つパッシブ名）。
static func action_skip_label_for_member(member: Resource) -> String:
	if member == null:
		return ""
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if str(def.get("category", "")) in ["relic", "weapon"]:
			continue
		if float(def.get("action_skip_chance", 0.0)) > 0.0:
			return str(def.get("display_name", ""))
	return ""


static func party_incoming_mult() -> float:
	var mult: float = 1.0
	var member_index: int = 0
	for member: Resource in GameState.party_members:
		if member == null:
			member_index += 1
			continue
		for raw_def: Variant in _equipment_passives_for_member(member):
			if raw_def is not Dictionary:
				continue
			var def: Dictionary = raw_def
			if def.has("party_incoming_mult"):
				mult *= float(def["party_incoming_mult"])
		## キャラ固有のパーティ被ダメ軽減（鉄誓の壁など）。前列限定を尊重。
		for pid: String in GameState.get_equipped_character_passive_ids(member):
			var cdef: Dictionary = get_def(pid)
			if cdef.is_empty() or not cdef.has("party_incoming_mult"):
				continue
			if str(cdef.get("passive_condition", "")) == "front_row_only":
				if GameState.is_member_back_row(member_index):
					continue
			mult *= float(cdef["party_incoming_mult"])
		member_index += 1
	return mult

## 致死回避パッシブ定義（装備→キャラ固有）。消費／確率判定は CombatController。
static func death_save_def_for_member(member_index: int) -> Dictionary:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return {}
	var member: Resource = GameState.party_members[member_index]
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if bool(def.get("death_save_once", false)) or float(def.get("death_save_chance", 0.0)) > 0.0:
			return def
	return {}


static func member_ignores_exploration_damage(member: Resource) -> bool:
	if member == null:
		return false
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		if bool(raw_def.get("exploration_damage_immune", false)):
			return true
	return false


## 単一メンバの罠パーティ軽減倍率（未所持は 1.0）。
static func exploration_damage_party_mult_for_member(member: Resource) -> float:
	if member == null:
		return 1.0
	var mult: float = 1.0
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		if raw_def.has("exploration_damage_party_mult"):
			mult *= float(raw_def["exploration_damage_party_mult"])
	return mult


## 編成全体の罠ダメージ倍率（辺境の踏破など）。複数所持は積算。
static func party_exploration_damage_mult() -> float:
	var mult: float = 1.0
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		mult *= exploration_damage_party_mult_for_member(member)
	return mult


## 状態異常持ち敵への与ダメ倍率。
## `present_status_ids` に現在の敵デバフ id を渡す。空なら従来どおり「何らかのデバフあり」前提で呼び出し側が制御。
## パッシブに `outgoing_vs_status_ids` がある場合は、そのいずれかが present に含まれるときだけ乗算。
static func outgoing_vs_status_mult_for_member(member_index: int, present_status_ids: Array = []) -> float:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return 1.0
	var mult: float = 1.0
	var member: Resource = GameState.party_members[member_index]
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		if not raw_def.has("outgoing_vs_status_mult"):
			continue
		## 狩人など without 分岐付きは relic_mark_focus_outgoing_mult 側で処理。
		if raw_def.has("outgoing_without_status_mult"):
			continue
		var filter_ids: Array = raw_def.get("outgoing_vs_status_ids", [])
		if not filter_ids.is_empty():
			var matched: bool = false
			for sid: Variant in filter_ids:
				if present_status_ids.has(str(sid)):
					matched = true
					break
			if not matched:
				continue
		mult *= float(raw_def["outgoing_vs_status_mult"])
	return mult


## バフ中の敵への与ダメ倍率（灰冠サイレント等）。
static func outgoing_vs_buff_mult_for_member(member_index: int) -> float:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return 1.0
	var mult: float = 1.0
	var member: Resource = GameState.party_members[member_index]
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		if raw_def.has("outgoing_vs_buff_mult"):
			mult *= float(raw_def["outgoing_vs_buff_mult"])
	return mult


## 被クリティカル率加算（装備パッシブ合算）。
static func incoming_crit_rate_add_for_member(member_index: int) -> float:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return 0.0
	var add: float = 0.0
	for raw_def: Variant in for_member(GameState.party_members[member_index]):
		if raw_def is not Dictionary:
			continue
		if raw_def.has("incoming_crit_rate_add"):
			add += float(raw_def["incoming_crit_rate_add"])
	return add


## 回復スキル追撃ダメ比率（武器 fraction＋防具 add）。武器なしは無効。
static func heal_skill_spill_damage_fraction(member_index: int) -> float:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return 0.0
	var frac: float = 0.0
	var add: float = 0.0
	for raw_def: Variant in for_member(GameState.party_members[member_index]):
		if raw_def is not Dictionary:
			continue
		if raw_def.has("heal_skill_spill_damage_fraction"):
			frac = maxf(frac, float(raw_def["heal_skill_spill_damage_fraction"]))
		if raw_def.has("heal_skill_spill_damage_add"):
			add += float(raw_def["heal_skill_spill_damage_add"])
	if frac <= 0.0:
		return 0.0
	return maxf(0.0, frac + add)


## 必殺チャージ速度倍率（鍵名 `ultimate_charge_dealt_mult` は互換維持・時間制でも速度に適用）。
static func ultimate_charge_rate_mult(member_index: int) -> float:
	return weapon_ultimate_charge_dealt_mult(member_index)


static func weapon_ultimate_charge_dealt_mult(member_index: int) -> float:
	var def: Dictionary = weapon_passive_def_for_member(
		GameState.party_members[member_index] if member_index >= 0 and member_index < GameState.party_members.size() else null
	)
	var mult: float = 1.0
	if not def.is_empty() and def.has("ultimate_charge_dealt_mult"):
		mult *= maxf(0.0, float(def["ultimate_charge_dealt_mult"]))
	mult *= equipped_relic_float(member_index, "ultimate_charge_dealt_mult", 1.0)
	## 装飾など装備固定パッシブ（剣舞の指輪／鼓動の首飾り）。
	if member_index >= 0 and member_index < GameState.party_members.size():
		for raw_def: Variant in _equipment_passives_for_member(GameState.party_members[member_index]):
			if raw_def is not Dictionary:
				continue
			var edef: Dictionary = raw_def
			if str(edef.get("category", "")) == "weapon":
				continue
			if edef.has("ultimate_charge_dealt_mult"):
				mult *= maxf(0.0, float(edef["ultimate_charge_dealt_mult"]))
	return mult


## 装備中レリック定義（無ければ空）。
static func equipped_relic_def(member_index: int) -> Dictionary:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return {}
	var member: Resource = GameState.party_members[member_index]
	var relic_id: String = GameState.get_equipped_relic_passive_id(member)
	if relic_id.is_empty():
		return {}
	return get_def(relic_id)


static func equipped_relic_float(member_index: int, key: String, default_value: float = 1.0) -> float:
	var def: Dictionary = equipped_relic_def(member_index)
	if def.is_empty() or not def.has(key):
		return default_value
	return float(def[key])


## レリック／武器／装飾などのスキルCD倍率（>1で遅延）。セットは呼び出し側で乗算。
static func relic_skill_cd_mult(member_index: int) -> float:
	var mult: float = equipped_relic_float(member_index, "skill_cd_mult", 1.0)
	if member_index >= 0 and member_index < GameState.party_members.size():
		var member: Resource = GameState.party_members[member_index]
		var wdef: Dictionary = weapon_passive_def_for_member(member)
		if wdef.has("skill_cd_mult"):
			mult *= float(wdef["skill_cd_mult"])
		for raw_def: Variant in _equipment_passives_for_member(member):
			if raw_def is not Dictionary:
				continue
			var edef: Dictionary = raw_def
			if str(edef.get("category", "")) in ["weapon", "relic"]:
				continue
			if edef.has("skill_cd_mult"):
				mult *= float(edef["skill_cd_mult"])
	return maxf(0.05, mult)


## 貫通の二次ヒット倍率（既定1.0）。
static func pierce_secondary_damage_mult(member_index: int) -> float:
	var mult: float = 1.0
	if member_index < 0 or member_index >= GameState.party_members.size():
		return mult
	for raw_def: Variant in for_member(GameState.party_members[member_index]):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if def.has("pierce_secondary_damage_mult"):
			mult *= maxf(0.0, float(def["pierce_secondary_damage_mult"]))
	return mult


## 回復スキル威力倍率（既定1.0）。
static func heal_power_mult_for_member(member_index: int) -> float:
	var mult: float = 1.0
	if member_index < 0 or member_index >= GameState.party_members.size():
		return mult
	for raw_def: Variant in for_member(GameState.party_members[member_index]):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if def.has("heal_power_mult"):
			mult *= maxf(0.0, float(def["heal_power_mult"]))
	return mult


## 回復時に対象へ guard を付与するか。
static func heal_applies_guard_for_member(member_index: int) -> bool:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return false
	for raw_def: Variant in for_member(GameState.party_members[member_index]):
		if raw_def is not Dictionary:
			continue
		if bool(raw_def.get("heal_applies_guard", false)):
			return true
	return false


## 攻撃側敵の状態に応じた被ダメ倍率（血契など）。
static func incoming_vs_attacker_status_mult(member_index: int, attacker_status_ids: Array) -> float:
	var mult: float = 1.0
	if member_index < 0 or member_index >= GameState.party_members.size():
		return mult
	for raw_def: Variant in for_member(GameState.party_members[member_index]):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if not def.has("incoming_vs_status_mult"):
			continue
		var filter_ids: Array = def.get("incoming_vs_status_ids", [])
		if filter_ids.is_empty():
			continue
		var matched: bool = false
		for sid: Variant in filter_ids:
			if attacker_status_ids.has(str(sid)):
				matched = true
				break
		if matched:
			mult *= float(def["incoming_vs_status_mult"])
	return mult


## 庇護: 最傷味方なら cover_ally_incoming_mult を返す（自分は character incoming 側）。
static func cover_ally_incoming_mult_for(member_index: int, most_injured_index: int) -> float:
	if member_index < 0 or member_index != most_injured_index:
		return 1.0
	if member_index >= GameState.party_members.size():
		return 1.0
	var mult: float = 1.0
	## 庇護は「装備者以外の最傷味方」を守る。装備者自身が最傷なら適用しない。
	for i: int in GameState.party_members.size():
		if i == member_index:
			continue
		var m: Resource = GameState.party_members[i]
		if m == null:
			continue
		for raw_def: Variant in for_member(m):
			if raw_def is not Dictionary:
				continue
			var def: Dictionary = raw_def
			if def.has("cover_ally_incoming_mult"):
				mult *= float(def["cover_ally_incoming_mult"])
	return mult


## 場の敵デバフ種類数に応じた被ダメ軽減（呪縛法衣）。
static func hexweave_incoming_mult_for_member(member_index: int, unique_debuff_count: int) -> float:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return 1.0
	var reduction: float = 0.0
	var cap: float = 0.0
	for raw_def: Variant in for_member(GameState.party_members[member_index]):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if not def.has("incoming_per_enemy_debuff"):
			continue
		reduction += float(def["incoming_per_enemy_debuff"]) * float(maxi(0, unique_debuff_count))
		cap = maxf(cap, float(def.get("incoming_per_enemy_debuff_cap", 0.15)))
	if reduction <= 0.0:
		return 1.0
	return 1.0 - clampf(reduction, 0.0, cap if cap > 0.0 else 0.15)


## HP帯による与ダメ倍率（狂戦士）。hp_below を満たす帯のうち最大倍率。
static func relic_outgoing_hp_tier_mult(member_index: int, hp_ratio: float) -> float:
	var def: Dictionary = equipped_relic_def(member_index)
	if def.is_empty():
		return 1.0
	var tiers: Array = def.get("outgoing_hp_tiers", [])
	if tiers.is_empty():
		return 1.0
	var best: float = 1.0
	for raw: Variant in tiers:
		if raw is not Dictionary:
			continue
		var threshold: float = float(raw.get("hp_below", 0.0))
		if hp_ratio < threshold:
			best = maxf(best, float(raw.get("outgoing_mult", 1.0)))
	return best


## 標的フォーカス（狩人）。mark あり=vs／なし=without。
static func relic_mark_focus_outgoing_mult(member_index: int, present_status_ids: Array) -> float:
	var def: Dictionary = equipped_relic_def(member_index)
	if def.is_empty():
		return 1.0
	if not def.has("outgoing_without_status_mult") and not def.has("outgoing_vs_status_mult"):
		return 1.0
	var filter_ids: Array = def.get("outgoing_vs_status_ids", [])
	var has_focus: bool = false
	if filter_ids.is_empty():
		has_focus = not present_status_ids.is_empty()
	else:
		for sid: Variant in filter_ids:
			if present_status_ids.has(str(sid)):
				has_focus = true
				break
	if has_focus and def.has("outgoing_vs_status_mult"):
		return float(def["outgoing_vs_status_mult"])
	if def.has("outgoing_without_status_mult"):
		return float(def["outgoing_without_status_mult"])
	return 1.0


static func relic_heal_received_mult(member_index: int) -> float:
	var mult: float = equipped_relic_float(member_index, "heal_received_mult", 1.0)
	if member_index >= 0 and member_index < GameState.party_members.size():
		for raw_def: Variant in for_member(GameState.party_members[member_index]):
			if raw_def is not Dictionary:
				continue
			var def: Dictionary = raw_def
			if str(def.get("category", "")) == "relic":
				continue
			if def.has("heal_received_mult"):
				mult *= float(def["heal_received_mult"])
	return maxf(0.0, mult)


static func relic_pre_hit_status_id(member_index: int) -> String:
	var def: Dictionary = equipped_relic_def(member_index)
	return str(def.get("pre_hit_status_id", ""))


## 後衛被弾リダイレクト装備者（生存・chance>0 の先頭）。無ければ -1。
static func redirect_rear_hit_holder_index() -> int:
	for i: int in GameState.party_members.size():
		if GameState.party_members[i] == null:
			continue
		var chance: float = equipped_relic_float(i, "redirect_rear_hit_chance", 0.0)
		if chance > 0.0:
			return i
	return -1


static func redirect_rear_hit_chance_for(member_index: int) -> float:
	return clampf(equipped_relic_float(member_index, "redirect_rear_hit_chance", 0.0), 0.0, 1.0)


static func relic_lifesteal_ratio(member_index: int) -> float:
	return maxf(0.0, equipped_relic_float(member_index, "lifesteal_ratio", 0.0))


## レリック＋キャラ固有の吸血率。`lifesteal_basic_only` は通常攻撃のみ加算。
static func member_lifesteal_ratio(member_index: int, skill_id: String = "") -> float:
	var ratio: float = relic_lifesteal_ratio(member_index)
	if member_index < 0 or member_index >= GameState.party_members.size():
		return ratio
	var member: Resource = GameState.party_members[member_index]
	var sid: String = str(skill_id)
	var is_basic: bool = sid.is_empty() or sid == "basic_attack"
	for raw_def: Variant in for_member(member):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if str(def.get("category", "")) == "relic":
			continue
		if not def.has("lifesteal_ratio"):
			continue
		if bool(def.get("lifesteal_basic_only", false)) and not is_basic:
			continue
		ratio += maxf(0.0, float(def["lifesteal_ratio"]))
	return ratio


## 戦闘リジェネ定義（interval/fraction 両方あるレリック・キャラパッシブ）。
static func combat_regen_defs_for_party() -> Array:
	var out: Array = []
	for i: int in GameState.combatant_count():
		var member: Resource = GameState.get_combatant(i)
		if member == null:
			continue
		for raw_def: Variant in for_member(member):
			if raw_def is not Dictionary:
				continue
			var def: Dictionary = raw_def
			var interval: float = float(def.get("combat_regen_interval_sec", 0.0))
			var frac: float = float(def.get("combat_regen_max_hp_fraction", 0.0))
			if interval <= 0.0 or frac <= 0.0:
				continue
			out.append({
				"member_index": i,
				"interval_sec": interval,
				"max_hp_fraction": frac,
				"display_name": str(def.get("display_name", "")),
			})
	return out


## 編成中レリックの宝箱部屋 weight 加算（最大値。複数は合算しない）。
static func party_treasure_room_weight_add() -> int:
	var best: int = 0
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		var relic_id: String = GameState.get_equipped_relic_passive_id(member)
		if relic_id.is_empty():
			continue
		var def: Dictionary = get_def(relic_id)
		if def.is_empty():
			continue
		best = maxi(best, int(def.get("treasure_room_weight_add", 0)))
	return best


static func on_kill_refund_fraction(member_index: int) -> float:
	var def: Dictionary = weapon_passive_def_for_member(
		GameState.party_members[member_index] if member_index >= 0 and member_index < GameState.party_members.size() else null
	)
	if def.is_empty():
		return 0.0
	var weather_bonus: Dictionary = _active_weather_bonus(def)
	if weather_bonus.has("refund_ct_fraction"):
		return clampf(float(weather_bonus["refund_ct_fraction"]), 0.0, 1.0)
	if str(def.get("trigger", "")) != "on_kill":
		return 0.0
	if str(def.get("effect", "")) != "refund_ct":
		return 0.0
	return clampf(float(def.get("refund_ct_fraction", 0.0)), 0.0, 1.0)

static func skill_stat_modifiers_for_member(member_index: int) -> Dictionary:
	var out: Dictionary = weapon_stat_modifiers_for_member(member_index)
	var char_mods: Dictionary = character_stat_modifiers_for_member(member_index)
	out["ultimate_power_mult"] = float(out["ultimate_power_mult"]) * float(char_mods.get("ultimate_power_mult", 1.0))
	out["exp_gain_mult"] = float(out["exp_gain_mult"]) * float(char_mods.get("exp_gain_mult", 1.0))
	return out

static func party_exp_mult() -> float:
	var mult: float = 1.0
	for member: Resource in GameState.party_members:
		if member == null:
			continue
		for raw_def: Variant in for_member(member):
			if raw_def is not Dictionary:
				continue
			var def: Dictionary = raw_def
			if def.has("party_exp_gain_mult"):
				mult *= float(def["party_exp_gain_mult"])
	return mult

static func weapon_passive_description(passive_id: String) -> String:
	var def: Dictionary = get_def(passive_id)
	if def.is_empty():
		return ""
	if def.has("description"):
		return str(def.get("description", ""))
	return relic_description(passive_id)

static func relic_passive_ids() -> Array[String]:
	return RELIC_PASSIVE_ORDER.duplicate()

static func relic_icon_key(passive_id: String) -> String:
	var pid: String = migrate_relic_passive_id(passive_id)
	if pid.begins_with("relic_"):
		return pid.trim_prefix("relic_")
	return pid

static func relic_display_name(passive_id: String) -> String:
	var def: Dictionary = get_def(migrate_relic_passive_id(passive_id))
	if def.is_empty():
		return "なし"
	return str(def.get("display_name", passive_id))

static func relic_description(passive_id: String) -> String:
	var def: Dictionary = get_def(migrate_relic_passive_id(passive_id))
	if def.is_empty():
		return ""
	if def.has("description"):
		return str(def.get("description", ""))
	return _passive_effect_summary(def)

static func selectable_relic_passive_ids() -> Array[String]:
	var out: Array[String] = []
	for pid: String in RELIC_PASSIVE_ORDER:
		if GameState.has_relic(pid):
			out.append(pid)
	return out

static func stat_multipliers_for_member(member: Resource, member_index: int) -> Dictionary:
	var eff: Dictionary = {"outgoing_mult": 1.0, "incoming_mult": 1.0, "speed_mult": 1.0}
	if member == null:
		return eff
	var relic_id: String = GameState.get_equipped_relic_passive_id(member)
	if relic_id.is_empty():
		return eff
	var def: Dictionary = get_def(relic_id)
	if def.is_empty():
		return eff
	for key: String in eff.keys():
		if def.has(key):
			var mult: float = float(def[key])
			if key == "outgoing_mult" and str(def.get("passive_condition", "")) == "front_row_only":
				if member_index >= 0 and GameState.is_member_back_row(member_index):
					mult = 1.0
			eff[key] = mult
	return eff

static func _passive_effect_summary(def: Dictionary) -> String:
	if def.has("description"):
		return str(def.get("description", ""))
	var parts: PackedStringArray = []
	if float(def.get("outgoing_mult", 1.0)) > 1.0:
		parts.append("与ダメ +%d%%" % int(round((float(def["outgoing_mult"]) - 1.0) * 100.0)))
	if float(def.get("pet_outgoing_mult", 1.0)) > 1.0:
		parts.append("ペット与ダメ +%d%%" % int(round((float(def["pet_outgoing_mult"]) - 1.0) * 100.0)))
	if float(def.get("pet_defense_mult", 1.0)) > 1.0:
		parts.append("ペット防御 +%d%%" % int(round((float(def["pet_defense_mult"]) - 1.0) * 100.0)))
	if float(def.get("pet_max_hp_mult", 1.0)) > 1.0:
		parts.append("ペットHP +%d%%" % int(round((float(def["pet_max_hp_mult"]) - 1.0) * 100.0)))
	if float(def.get("pet_revive_on_combat_end_chance", 0.0)) > 0.0:
		parts.append("戦闘終了時ペット蘇生 %d%%" % int(round(float(def["pet_revive_on_combat_end_chance"]) * 100.0)))
	if float(def.get("pet_heal_on_action_max_hp_fraction", 0.0)) > 0.0:
		parts.append("行動時ペット回復 %d%%" % int(round(float(def["pet_heal_on_action_max_hp_fraction"]) * 100.0)))
	if float(def.get("heal_power_mult", 1.0)) > 1.0:
		parts.append("回復 +%d%%" % int(round((float(def["heal_power_mult"]) - 1.0) * 100.0)))
	if float(def.get("heal_received_mult", 1.0)) < 1.0:
		parts.append("被回復 -%d%%" % int(round((1.0 - float(def["heal_received_mult"])) * 100.0)))
	if float(def.get("heal_received_mult", 1.0)) > 1.0:
		parts.append("被回復 +%d%%" % int(round((float(def["heal_received_mult"]) - 1.0) * 100.0)))
	if float(def.get("incoming_mult", 1.0)) < 1.0:
		parts.append("被ダメ -%d%%" % int(round((1.0 - float(def["incoming_mult"])) * 100.0)))
	if float(def.get("incoming_mult", 1.0)) > 1.0:
		parts.append("被ダメ +%d%%" % int(round((float(def["incoming_mult"]) - 1.0) * 100.0)))
	if float(def.get("speed_mult", 1.0)) > 1.0:
		parts.append("速度 +%d%%" % int(round((float(def["speed_mult"]) - 1.0) * 100.0)))
	if float(def.get("evasion_rate_add", 0.0)) > 0.0:
		parts.append("回避 +%d%%" % int(round(float(def["evasion_rate_add"]) * 100.0)))
	if float(def.get("back_row_evasion_rate_add", 0.0)) > 0.0:
		parts.append("後列回避 +%d%%" % int(round(float(def["back_row_evasion_rate_add"]) * 100.0)))
	if float(def.get("first_attack_mult", 1.0)) > 1.0:
		parts.append("初撃 ×%.1f" % float(def["first_attack_mult"]))
	if def.has("party_incoming_mult"):
		if str(def.get("passive_condition", "")) == "front_row_only":
			parts.append("前列時 パーティ被ダメ ×%.2f" % float(def["party_incoming_mult"]))
		else:
			parts.append("パーティ被ダメ ×%.2f" % float(def["party_incoming_mult"]))
	if str(def.get("effect", "")) == "grant_self_evasion":
		parts.append("開幕回避 +%d%%" % int(round(float(def.get("evasion_add", 0.0)) * 100.0)))
	if float(def.get("threat_base_add", 0.0)) > 0.0:
		parts.append("敵の注目 +%.0f" % float(def["threat_base_add"]))
	if float(def.get("ultimate_power_mult", 1.0)) > 1.0:
		parts.append("必殺 +%d%%" % int(round((float(def["ultimate_power_mult"]) - 1.0) * 100.0)))
	if float(def.get("exp_gain_mult", 1.0)) > 1.0:
		parts.append("経験値 +%d%%" % int(round((float(def["exp_gain_mult"]) - 1.0) * 100.0)))
	if float(def.get("party_exp_gain_mult", 1.0)) > 1.0:
		parts.append("パーティ経験値 +%d%%" % int(round((float(def["party_exp_gain_mult"]) - 1.0) * 100.0)))
	return " / ".join(parts)

static func equipment_passives_for_member(member: Resource) -> Array:
	return _equipment_passives_for_member(member)

static func _def_with_id(passive_id: String) -> Dictionary:
	var def: Dictionary = _DEFS.get(passive_id, {}).duplicate()
	if def.is_empty():
		return {}
	def["id"] = passive_id
	return def

# 指定メンバーのパッシブ定義一覧（装備固定＋装備中 optional）。
static func for_member(member: Resource) -> Array:
	if member == null:
		return []
	var out: Array = []
	var seen: Dictionary = {}
	for eq_def: Dictionary in _equipment_passives_for_member(member):
		var eq_id: String = str(eq_def.get("id", ""))
		if eq_id.is_empty() or seen.has(eq_id):
			continue
		seen[eq_id] = true
		out.append(eq_def)
	for pid: String in GameState.get_equipped_character_passive_ids(member):
		if seen.has(pid):
			continue
		var def: Dictionary = _def_with_id(pid)
		if def.is_empty():
			continue
		seen[pid] = true
		out.append(_with_gacha_limit_break(member, def))
	var relic_id: String = GameState.get_equipped_relic_passive_id(member)
	if not relic_id.is_empty() and not seen.has(relic_id):
		var relic_def: Dictionary = _def_with_id(relic_id)
		if not relic_def.is_empty():
			out.append(relic_def)
	return out

## 戦闘突入ログ用（装備固定＋選択パッシブ＋レリック、`for_member` と同集合）。
static func combat_loadout_log_entries(member: Resource) -> Array:
	var out: Array = []
	if member == null:
		return out
	for def: Dictionary in for_member(member):
		var pid: String = str(def.get("id", ""))
		if pid.is_empty():
			continue
		out.append({
			"tag": "レリック" if is_relic_passive(pid) else ("武器" if is_weapon_passive(pid) else "パッシブ"),
			"name": str(def.get("display_name", pid)),
		})
	return out

static func selectable_passive_ids(member: Resource) -> Array[String]:
	var out: Array[String] = []
	for def: Dictionary in _core_passives_for_member(member):
		var pid: String = str(def.get("id", ""))
		if pid.is_empty() or out.has(pid):
			continue
		out.append(pid)
	return out

static func _core_passives_for_member(member: Resource) -> Array:
	## P3-PASSIVE-CHAR-001 案α: 職帯は自動付与しない（固有／ジョブFBのみ）。
	return _base_passives_for_member(member)

static func _base_passives_for_member(member: Resource) -> Array:
	if member == null:
		return []
	var adv_id: String = str(member.id)
	if _BASE_ROSTER_PASSIVES.has(adv_id):
		var char_def: Dictionary = _def_with_id(str(_BASE_ROSTER_PASSIVES[adv_id]))
		if not char_def.is_empty():
			return [_with_gacha_limit_break(member, char_def)]
	var out: Array = []
	if adv_id.begins_with("gacha_"):
		var helper: Resource = DataRegistry.get_gacha_helper_data(adv_id.trim_prefix("gacha_"))
		if helper != null and not str(helper.passive_id).is_empty():
			var helper_def: Dictionary = _def_with_id(str(helper.passive_id))
			if not helper_def.is_empty():
				out.append(_with_gacha_limit_break(member, helper_def))
	if out.is_empty():
		out = for_job(str(member.job_id))
	return out

static func _with_gacha_limit_break(member: Resource, def: Dictionary) -> Dictionary:
	if def.is_empty():
		return {}
	const _LimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")
	var bt: int = _LimitBreak.breakthrough_for_member(member)
	if bt <= 0:
		return def
	return _LimitBreak.scale_passive_def(def, bt)
static func _equipment_passives_for_member(member: Resource) -> Array:
	var out: Array = []
	if member == null:
		return out
	var armor_inst: Resource = member.equipped_armor if "equipped_armor" in member else null
	if armor_inst != null and not str(armor_inst.armor_id).is_empty():
		var armor_data: Resource = DataRegistry.get_armor_data(str(armor_inst.armor_id))
		if armor_data != null and not str(armor_data.fixed_passive_id).is_empty():
			var armor_def: Dictionary = _def_with_id(str(armor_data.fixed_passive_id))
			if not armor_def.is_empty():
				armor_def["source_name"] = DataRegistry.get_armor_name(str(armor_inst.armor_id))
				out.append(armor_def)
	var acc_inst: Resource = member.equipped_accessory if "equipped_accessory" in member else null
	if acc_inst != null and not str(acc_inst.accessory_id).is_empty():
		var acc_data: Resource = DataRegistry.get_accessory_data(str(acc_inst.accessory_id))
		if acc_data != null and not str(acc_data.fixed_passive_id).is_empty():
			var acc_def: Dictionary = _def_with_id(str(acc_data.fixed_passive_id))
			if not acc_def.is_empty():
				acc_def["source_name"] = DataRegistry.get_accessory_name(str(acc_inst.accessory_id))
				out.append(acc_def)
	var weapon_inst: Resource = member.equipped_weapon if "equipped_weapon" in member else null
	if weapon_inst != null and not str(weapon_inst.weapon_id).is_empty():
		var weapon_data: Resource = DataRegistry.get_weapon_data(str(weapon_inst.weapon_id))
		if weapon_data != null and not str(weapon_data.fixed_passive_id).is_empty():
			var weapon_def: Dictionary = _def_with_id(str(weapon_data.fixed_passive_id))
			if not weapon_def.is_empty():
				weapon_def["source_name"] = DataRegistry.get_weapon_name(str(weapon_inst.weapon_id))
				out.append(weapon_def)
	return out

# 指定ジョブのパッシブ定義一覧（id 込み）を返す。
static func for_job(job_id: String) -> Array:
	var out: Array = []
	for pid in _JOB_PASSIVES.get(job_id, []):
		var def: Dictionary = _def_with_id(str(pid))
		if def.is_empty():
			continue
		out.append(def)
	return out
