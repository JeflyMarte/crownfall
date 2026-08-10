class_name BalanceConfig
extends RefCounted

## 戦闘バランス定数の中央 SSOT（P3-BAL-005）。
## 各所の GDScript に散在していたグローバル倍率をここへ集約する。
## 個別エンティティの基礎値（敵HP/スキル倍率等）は従来通り .tres が正。

# ── 見栄えスケール（P3-STAT-CHAR-001 / P3-BAL-STAT-SCALE-001） ───────────
## 旧スケール（素体HP30台・装備ATK一桁）からの一括倍率。キャラ・装備・敵で共有。
const STAT_SCALE: int = 8
## 炉研ぎ +N の平坦加算（旧 +1 ATK/DEF、防具HPは旧 +2）
const EQUIP_FORGE_FLAT_PER_LEVEL: int = STAT_SCALE
const EQUIP_FORGE_HP_PER_LEVEL: int = STAT_SCALE * 2
## 平坦ランダム（攻撃/防御/HPアップ）帯圧縮（P3-EQ-FLAT-ROLL-NARROW-001 案C）。
## 上限表は旧×CEILING を焼き込み。下限＝上限×FLOOR（最低1）。
const FLAT_ROLL_CEILING_MULT: float = 0.70
const FLAT_ROLL_FLOOR_RATIO: float = 0.55

# ── ダメージ計算（旧 DungeonScene 定数） ──────────────────────────────────
const FALLBACK_ATTACK: int = 10 * STAT_SCALE
const CRITICAL_MULTIPLIER: float = 1.5
## 武器デフォルト（P3-EQ-STAT-005）。個体未設定時に使用。
const DEFAULT_WEAPON_ATTACK_SPEED: float = 1.0
const DEFAULT_WEAPON_CRITICAL_RATE: float = 0.05
const DEFAULT_WEAPON_CRITICAL_DAMAGE: float = CRITICAL_MULTIPLIER
const DEFAULT_BANE_MULTIPLIER: float = 1.3
## 属性値の表示スケール（P3-EQ-ELEMENT-POWER-SCALE-001）。旧1=+1% → 新100=+1%。
const ELEMENT_POWER_SCALE: int = 100
## 旧セーブ判定上限（旧最大≈base10+roll18）。未満なら ×SCALE 移行。
const ELEMENT_POWER_LEGACY_CEILING: int = 50
## 属性値→与ダメ倍率: damage × (1 + element_power × K)。無属性時は適用しない。
## SCALE 後は K=0.0001（旧 0.01）。効果は不変。
const ELEMENT_POWER_K: float = 0.0001
## 敵DEF逓減軽減 K/(K+DEF)（P3-BAL-002）。敵DEF×STAT_SCALE に合わせ K も同倍率。
const DEFENSE_MITIGATION_K: float = 100.0 * float(STAT_SCALE)
## Biome 有利属性 与ダメ倍率（P3-D099）
const BIOME_FAVORED_BONUS: float = 1.15
## 防具属性耐性 被ダメ倍率（P3-D103）
const ARMOR_RESIST_MULTIPLIER: float = 0.75
## 装備合算回避率の上限（防具+装飾品）。
const EVASION_RATE_CAP: float = 0.50
## ダメージ±乱数（P3-D158）。最終ダメージ × [1−v, 1+v] の一様乱数。0で無効。
const DAMAGE_VARIANCE: float = 0.10

# ── 味方基礎（旧 CombatController 定数） ──────────────────────────────────
## P3-STAT-CHAR-001: 見栄え用スケール（旧 30 → 100 → 800）。ATK目安 ~300台
const BASE_MEMBER_HP: int = 800

# ── レベル成長（P3-D035 / P3-BAL-006 / P3-LV-099） ───────────────────────
const MAX_PLAYER_LEVEL: int = 99
const SOFT_CAP_LEVEL: int = 50
const HP_PER_LEVEL: int = 6 * STAT_SCALE
const ATTACK_PER_LEVEL: int = 2 * STAT_SCALE
## DEF 成長（P3-BAL-GROWTH-H1-001）。基礎は ATK の半分。キャラ倍率は CharacterGrowthRates。
const DEFENSE_PER_LEVEL: int = 1 * STAT_SCALE
## Lv51〜99 の逓減成長（新スキル習得なし）
const HP_PER_LEVEL_MASTER: int = 3 * STAT_SCALE
const ATTACK_PER_LEVEL_MASTER: int = 1 * STAT_SCALE
const DEFENSE_PER_LEVEL_MASTER: int = STAT_SCALE / 2

# ── 味方全体攻撃（P3-BAL-ALLY-AOE-07-001） ────────────────────────────────
## 自キャラの敵全体ダメージスキル（必殺除く）の威力を統一。
const ALLY_AOE_DAMAGE_POWER_MULT: float = 0.7


## スキル実効 power。味方 all_enemies ダメージ（非必殺）は ALLY_AOE に固定。
static func effective_skill_power_multiplier(skill_data: Resource) -> float:
	if skill_data == null:
		return 0.0
	var raw: float = float(skill_data.power_multiplier)
	if str(skill_data.effect_type) != "damage":
		return raw
	if str(skill_data.target_type) != "all_enemies":
		return raw
	if str(skill_data.slot_type) == "ultimate":
		return raw
	var st: String = str(skill_data.skill_type)
	if st == "enemy" or st == "boss":
		return raw
	return ALLY_AOE_DAMAGE_POWER_MULT


# ── 回復スキル（P3-BAL-HEAL-MAXHP-001） ───────────────────────────────────
## 味方 heal スキルの power_multiplier = 対象 maxHP 割合（敵healと同型）。
## 旧固定基準（互換・テスト参照用。戦闘スキル経路では未使用）。
const HEAL_SKILL_BASE: int = 14 * STAT_SCALE
## 推奨値（tres が正。ここは Decision の目安）。
const HEAL_FRAC_MEND: float = 0.20
## 大治癒は全体各員（P3-BAL-ALCHEMIST-HEAL-001）。
const HEAL_FRAC_SALVE_BURST: float = 0.12
const HEAL_FRAC_GRAND_ELIXIR: float = 0.20
## 単体回復の頂点は AL 治癒（20%）。支援回復は一段下（P3-BAL-HEAL-HIERARCHY-001）。
## BT 血還の矢（旧・獣医の手当て）はドレイン攻撃（P3-BAL-BT-RG-KIT-TUNE-001）。
## RG 野営の一滴＝全体各員。つつき介抱＝最傷（自己除外）。
const HEAL_FRAC_CAMP_DRAUGHT: float = 0.08
## ジャック介抱（ペット回復。回転は治癒より遅く量も薄い。自己非対象）。
const HEAL_FRAC_PET_POUNCE: float = 0.08
## スキル `drain` タグ: 与ダメに対する自己回復割合（レリック吸血と加算）。
const SKILL_DRAIN_HEAL_RATIO: float = 0.5
## ジャック守り吠え（味全バフ付帯の薄い回復。P3-BAL-PET-JACK-KIT-001）。
const HEAL_FRAC_PET_JACK_WARD: float = 0.05
## BT 相棒鼓舞（バフ＋ペット maxHP 割合回復。CD短めの付帯回復）。
const HEAL_FRAC_PET_BOND_RALLY: float = 0.10
## BT 群れ纏い（旧號令）のペット回復。相棒鼓舞より厚め。
const HEAL_FRAC_PET_HERD_CALL: float = 0.15
## 回復部屋の最低回復（P3-BAL-NONCOMBAT-001: 各員 maxHP×割合と比較）
const ROOM_HEAL_AMOUNT: int = 10 * STAT_SCALE
## 泉成功時の回復割合（各生存者）。
const ROOM_HEAL_MAX_HP_FRAC: float = 0.18

# ── ボス／エリート CC（行動SKIP）耐性 P3-BAL-BOSS-CC-RESIST-001 ──
## SKIP 抽選倍率（1行動1回・最大確率に乗算）。
const CC_SKIP_MULT_BOSS: float = 0.5
const CC_SKIP_MULT_ELITE: float = 0.75
## ボスへのスタン付与 tick（通常 stun.tres=2 → 短縮）。
const CC_STUN_DURATION_TICKS_BOSS: int = 1
## 鈍化など interval_multiplier>1 の代理スキップ確率（耐性倍率の前）。
const CC_INTERVAL_PROXY_SKIP_CHANCE: float = 0.5

# ── 探索罠（最大HP割合 / P3-BAL-TRAP-TIER-001） ───────────────────────
## 配列 index = DungeonTierConfig TIER_NORMAL / HARD / NIGHTMARE
## 単体被弾（探索／罠部屋）
const TRAP_MAX_HP_FRAC_COMBAT_SINGLE_BY_TIER: Array[float] = [0.10, 0.15, 0.22]
const TRAP_MAX_HP_FRAC_ROOM_SINGLE_BY_TIER: Array[float] = [0.15, 0.25, 0.35]
## 全体被弾（単体より低め）
const TRAP_MAX_HP_FRAC_COMBAT_AOE_BY_TIER: Array[float] = [0.05, 0.08, 0.12]
const TRAP_MAX_HP_FRAC_ROOM_AOE_BY_TIER: Array[float] = [0.08, 0.12, 0.18]
## 発動時に全体パターンになる確率
const TRAP_AOE_CHANCE_BY_TIER: Array[float] = [0.25, 0.35, 0.45]
## 戦闘／エリート入室時の探索罠ロール（Nは失敗感を抑える — P3-BAL-N-NONCOMBAT-FAIL-001）
const TRAP_EXPLORE_CHANCE_BY_TIER: Array[float] = [0.08, 0.20, 0.28]
## 罠部屋の発動率（N=35%／H・NM据置）
const TRAP_ROOM_TRIGGER_CHANCE_BY_TIER: Array[float] = [0.35, 0.65, 0.80]
## 被弾時に毒 or 出血を付与する確率（N=なし）
const TRAP_STATUS_CHANCE_BY_TIER: Array[float] = [0.0, 0.40, 0.60]
const TRAP_STATUS_POOL: Array[String] = ["poison", "bleed"]
## 後方互換エイリアス（ハード帯＝旧 NONCOMBAT 据置値）
const TRAP_MAX_HP_FRAC_COMBAT_SINGLE: float = 0.15
const TRAP_MAX_HP_FRAC_ROOM_SINGLE: float = 0.25
const TRAP_MAX_HP_FRAC_COMBAT_AOE: float = 0.08
const TRAP_MAX_HP_FRAC_ROOM_AOE: float = 0.12
const TRAP_AOE_CHANCE: float = 0.35


static func _trap_tier_index(tier: int) -> int:
	return clampi(tier, 0, TRAP_MAX_HP_FRAC_ROOM_SINGLE_BY_TIER.size() - 1)


static func trap_max_hp_frac_combat_single(tier: int) -> float:
	return TRAP_MAX_HP_FRAC_COMBAT_SINGLE_BY_TIER[_trap_tier_index(tier)]


static func trap_max_hp_frac_room_single(tier: int) -> float:
	return TRAP_MAX_HP_FRAC_ROOM_SINGLE_BY_TIER[_trap_tier_index(tier)]


static func trap_max_hp_frac_combat_aoe(tier: int) -> float:
	return TRAP_MAX_HP_FRAC_COMBAT_AOE_BY_TIER[_trap_tier_index(tier)]


static func trap_max_hp_frac_room_aoe(tier: int) -> float:
	return TRAP_MAX_HP_FRAC_ROOM_AOE_BY_TIER[_trap_tier_index(tier)]


static func trap_aoe_chance(tier: int) -> float:
	return TRAP_AOE_CHANCE_BY_TIER[_trap_tier_index(tier)]


static func trap_explore_chance(tier: int) -> float:
	return TRAP_EXPLORE_CHANCE_BY_TIER[_trap_tier_index(tier)]


static func trap_room_trigger_chance(tier: int) -> float:
	return TRAP_ROOM_TRIGGER_CHANCE_BY_TIER[_trap_tier_index(tier)]


static func trap_status_chance(tier: int) -> float:
	return TRAP_STATUS_CHANCE_BY_TIER[_trap_tier_index(tier)]

# ── 非戦闘失敗ペナルティ（P3-BAL-NONCOMBAT-001 → 罠以外を緩和） ─────────
## 宝箱／泉／碑文の失敗HP割合（罠部屋・探索罠は上表のまま）。
const NONCOMBAT_FAIL_TREASURE_HP_FRAC: float = 0.08
const NONCOMBAT_FAIL_HEAL_HP_FRAC: float = 0.07
const NONCOMBAT_FAIL_LORE_HP_FRAC: float = 0.05
## 宝箱／碑文の成功率（N緩和・H/NM据置 — P3-BAL-N-NONCOMBAT-FAIL-001）。泉は据置。
const TREASURE_SUCCESS_CHANCE_BY_TIER: Array[float] = [0.70, 0.50, 0.50]
const LORE_SUCCESS_CHANCE_BY_TIER: Array[float] = [0.90, 0.80, 0.80]
## 旧・宝箱武器ドロップ率。P3-BAL-TREASURE-EQUIP-001 で確定1点方式へ置換（未使用）。
const TREASURE_WEAPON_CHANCE: float = 0.0
## 宝箱成功 Gold（N/H/NM — P3-BAL-TREASURE-GOLD-TIER-001）。失敗は半額。
const TREASURE_GOLD_BY_TIER: Array[int] = [1000, 3000, 5000]
## 碑文成功 Gold（N/H/NM — P3-BAL-LORE-GOLD-TIER-001）。初回／既知とも同額。
const LORE_GOLD_BY_TIER: Array[int] = [500, 1000, 3000]
## 旧互換（ノーマル帯）。正は lore_gold(tier)。
const LORE_FIRST_GOLD: int = 500
const LORE_REPEAT_GOLD: int = 500
const LORE_FIRST_MATERIAL_CHANCE: float = 0.10
const LORE_FIRST_ACCESSORY_CHANCE: float = 0.08
## 碑文成功時: 次部屋〜次の戦闘フロアまでの EXP／Gold／装備ドロップ率のいずれか ×1.1。
const LORE_FLOOR_BLESSING_MULT: float = 1.1
const LORE_FLOOR_BLESSING_KINDS: Array[String] = ["exp", "gold", "equip"]

## ダンジョン分かれ道（P3-DG-FLOOR-CHOICE-001）
const FLOOR_CHOICE_DAMAGE_MULT: float = 1.5
## 戦力強化: 次フロアの味方被ダメ倍率（案A・攻守）。
const FLOOR_CHOICE_INCOMING_MULT: float = 0.85
const FLOOR_CHOICE_HEAL_FRAC: float = 0.25
const FLOOR_CHOICE_HARVEST_MULT: float = 1.35
const FLOOR_CHOICE_ASSAULT_MULT: float = 1.25
const FLOOR_CHOICE_DEPLETED_HP_RATIO: float = 0.60
## 本編: floor_count ≤ SHORT → 1回、それ超（通常10F）→ 2回。無限は 10F チャンクごと（AbyssDungeonConfig.CHUNK_FLOORS）。
const FLOOR_CHOICE_MAX_PER_RUN: int = 2
const FLOOR_CHOICE_MAX_SHORT_RUN: int = 1
const FLOOR_CHOICE_SHORT_FLOOR_COUNT: int = 9
const FLOOR_CHOICE_HARVEST_PICKS: int = 2
const FLOOR_CHOICE_REWARD_KINDS: Array[String] = ["exp", "gold", "material", "equip"]


static func treasure_success_chance(tier: int) -> float:
	return TREASURE_SUCCESS_CHANCE_BY_TIER[_trap_tier_index(tier)]


static func lore_success_chance(tier: int) -> float:
	return LORE_SUCCESS_CHANCE_BY_TIER[_trap_tier_index(tier)]


static func treasure_gold(tier: int = -1) -> int:
	var t: int = tier
	if t < 0:
		t = int(GameState.current_dungeon_tier)
	return TREASURE_GOLD_BY_TIER[_trap_tier_index(t)]


static func lore_gold(tier: int = -1) -> int:
	var t: int = tier
	if t < 0:
		t = int(GameState.current_dungeon_tier)
	return LORE_GOLD_BY_TIER[_trap_tier_index(t)]

# ── 敵レベルスケール（P3-D081） ──────────────────────────────────────────
const ENEMY_LEVEL_HP_K: float = 0.10
## 味方 DEF 成長（P3-BAL-GROWTH-H1）による被ダメ減を相殺（P3-BAL-GROWTH-H1-C）。
## 0.10→0.13: 序盤ほぼ据置、中後半で変更前相当の被圧に近づける。
const ENEMY_LEVEL_ATK_K: float = 0.13
const ENEMY_LEVEL_EXP_K: float = 0.15

# ── 編成人数補正（P3-BAL-003・base=3人） ─────────────────────────────────
const PARTY_BALANCE_HP_SHARE: float = 0.85
const PARTY_BALANCE_ATK_SHARE: float = 0.40

# ── 序盤〜全体の難易度再調整（P3-BAL-OPENING-001 / 002） ──
## 戦闘開始時に敵 HP/ATK へ乗算（全ダンジョン共通）。
## OPENING-002: HP をさらに上げて数撃交換に（ATK グローバルは据置＝逓減式で脅威を出す）。
const ENEMY_GLOBAL_HP_MULT: float = 2.00
## P3-BAL-ENEMY-PRESSURE-001: 1.30×1.25（標準+25%）。HP は据置。
const ENEMY_GLOBAL_ATK_MULT: float = 1.625
## 雑魚（NORMAL）のみ ATK 追加倍率（P3-BAL-TRASH-ATK-150-001）。ELITE/BOSS は据置。
const TRASH_ENEMY_ATK_MULT: float = 1.5
## 味方ユニット上の DoT tick 倍率（敵付与想定）。味方→敵 DoT は対象外。
const ENEMY_DOT_ON_PARTY_MULT: float = 1.40
## ★帯ボーナス＋個人ステ補正の圧縮（素体 BASE_MEMBER_HP は据置）。
## HP/DEF は 0.70 据置。ATK のみさらに圧縮して一撃感を抑える（OPENING-002）。
const ALLY_STAT_BONUS_SCALE: float = 0.70
const ALLY_ATK_BONUS_SCALE: float = 0.40

# ── Threat（P3-D104） ────────────────────────────────────────────────────
const THREAT_DAMAGE_K: float = 0.10   # 与ダメ1あたりの加算
const THREAT_TAKEN_K: float = 0.15    # 被ダメ1あたりの加算
const THREAT_TAUNT: float = 40.0 * float(STAT_SCALE)  # 挑発（防御スロット）スパイク
const THREAT_DECAY: float = 0.90

# ── 状態／コンボの平坦値（旧スケール×STAT_SCALE） ───────────────────────
## DoT 役割（P3-BAL-DOT-IDENTITY-001）: 毒＝長く薄く／炎上＝短く厚く／出血＝ATK比例。
## 実数値の正は resources/status/*.tres。ここは参照・テスト用の鏡。
const DOT_FLAT_POISON: int = 2 * STAT_SCALE
const DOT_FLAT_IGNITE: int = 3 * STAT_SCALE / 2
const DOT_PCT_POISON: float = 0.10
const DOT_PCT_IGNITE: float = 0.18
const DOT_PCT_BLEED: float = 0.20
const DOT_TICKS_POISON: int = 6
const DOT_TICKS_IGNITE: int = 3
const DOT_TICKS_BLEED: int = 5
const COMBO_POISON_PER_STACK: int = 8 * STAT_SCALE
const COMBO_BLEED_PER_STACK: int = 6 * STAT_SCALE
const SPARE_VIAL_HEAL: int = 12 * STAT_SCALE

# ── 陣形（P3-D106） ──────────────────────────────────────────────────────
const FORMATION_BACK_INCOMING: float = 0.85  # 後列の被ダメ倍率
const FORMATION_BACK_THREAT: float = 0.6     # 後列の Threat 基礎倍率
const DENSE_ROW_INCOMING: float = 1.08       # 密集列 被ダメ倍率
const SPREAD_ROW_INCOMING: float = 0.94      # 散開列 被ダメ倍率

# ── エンカウント（P3-D082/D110） ─────────────────────────────────────────
const SWARM_CHANCE: float = 0.45        # COMBAT 部屋の群れ出現率（P3-BAL-SWARM-001）
const MIXED_SWARM_CHANCE: float = 0.50  # 群れ時に別種を混ぜる確率
## 1-1〜1-3（biome_index=1 かつ chapter 1〜3）の群れ率倍率。序盤の圧を抑える。
const EARLY_STAGE_SWARM_CHANCE_MULT: float = 0.50
## モーンゲート 1-1〜1-3・ノーマルのみの群れ頭数上限（単体1／群れ最大2）。
const EARLY_STAGE_SWARM_SIZE_CAP: int = 2
## 時間帯降臨（時環／境界等）— ノーマルでも群れ多め（P3-BAL-DESCENT-SWARM-001）。
## 本編 N=0.45 より高く、曜日イベント forced_swarm 帯（0.30〜0.40）より厚くする。
const DESCENT_EVENT_SWARM_CHANCE: float = 0.72
const DESCENT_EVENT_SWARM_MIN: int = 2
const DESCENT_EVENT_SWARM_MAX: int = 4

# ── 群れ人数連動（P3-BAL-SWARM-DENSITY-001） ─────────────────────────────
## 戦闘開始時の頭数で一体あたり倍率を固定。倒しても再計算しない。
## 通常 COMBAT のみ（ELITE/BOSS は適用外）。
const SWARM_DENSITY_SOLO_HP: float = 1.50
const SWARM_DENSITY_SOLO_ATK: float = 1.50
const SWARM_DENSITY_SOLO_SPD: float = 1.50
## ソロ開始時、味方回避率に乗算（実質命中↑）。
const SOLO_EVASION_MULT: float = 0.5
const SWARM_DENSITY_PAIR_HP: float = 1.00
const SWARM_DENSITY_PAIR_ATK: float = 1.00
const SWARM_DENSITY_TRIPLE_HP: float = 0.90
const SWARM_DENSITY_TRIPLE_ATK: float = 0.85
const SWARM_DENSITY_MOB_HP: float = 0.80
const SWARM_DENSITY_MOB_ATK: float = 0.75
## ソロ戦で全体／列／AoE スキルの抽選ウェイト倍率。
const SOLO_AOE_SKILL_WEIGHT_MULT: float = 2.25

# ── エリート護衛（P3-BAL-ELITE-BOSS-PRESSURE-001 / P3-BAL-TIER-ENC-A-001） ─
## ELITE 部屋入場時に従える章雑魚数（N/H）。プール空なら単体。
## 例外: モーンゲート・ノーマルは護衛0（`DungeonController._mourngate_normal_elite_escorts_disabled`）。
const ELITE_ESCORT_MIN: int = 1
const ELITE_ESCORT_MAX: int = 2
## NM・双エリート時の護衛（薄い・合計）。
const ELITE_ESCORT_NM_DUAL_MIN: int = 0
const ELITE_ESCORT_NM_DUAL_MAX: int = 1
## NM・単エリート時の護衛（厚い）。
const ELITE_ESCORT_NM_SINGLE_MIN: int = 2
const ELITE_ESCORT_NM_SINGLE_MAX: int = 3

# ── 必殺チャージ圧力（P3-BAL-ULTIMATE-UNIFY-100-001 で無効化＝×1.0） ──
## ELITE／BOSS も通常と同じ速度（旧×0.5は廃止）。
const ULTIMATE_CHARGE_PRESSURE_MULT: float = 1.0
## ELITE／BOSS 入場時の持ち越し減衰なし（旧×0.5は廃止）。
const ULTIMATE_CHARGE_PRESSURE_ENTER_MULT: float = 1.0

# ── ボス圧案A（P3-BAL-BOSS-AURA-A-001） ──────────────────────────────────
## BOSS 攻撃力の追加倍率（グローバルATK・人数補正の外側）。
const BOSS_ATK_MULT: float = 1.22
## BOSS のみ人数ATK補正の share（通常敵は PARTY_BALANCE_ATK_SHARE）。
const BOSS_PARTY_BALANCE_ATK_SHARE: float = 0.50
## BOSS 速度の人数係数上限（3人=1.0／4人=1.25／5+=cap）。
const BOSS_PARTY_SPEED_MULT_4: float = 1.25
const BOSS_PARTY_SPEED_MULT_CAP: float = 1.40
## 戦闘中 hex の CD（tres も同値。開幕オーラとは別）。
const BOSS_HEX_COOLDOWN: float = 6.0


## 編成人数に対するボス行動速度倍率（ペット込み combatant_count）。基準=3人。
static func boss_party_speed_mult(combatant_n: int) -> float:
	var n: int = maxi(1, combatant_n)
	if n <= 3:
		return 1.0
	if n == 4:
		return BOSS_PARTY_SPEED_MULT_4
	return BOSS_PARTY_SPEED_MULT_CAP


static func swarm_density_hp_mult(start_count: int) -> float:
	match start_count:
		1:
			return SWARM_DENSITY_SOLO_HP
		2:
			return SWARM_DENSITY_PAIR_HP
		3:
			return SWARM_DENSITY_TRIPLE_HP
		_:
			return SWARM_DENSITY_MOB_HP if start_count >= 4 else 1.0


static func swarm_density_atk_mult(start_count: int) -> float:
	match start_count:
		1:
			return SWARM_DENSITY_SOLO_ATK
		2:
			return SWARM_DENSITY_PAIR_ATK
		3:
			return SWARM_DENSITY_TRIPLE_ATK
		_:
			return SWARM_DENSITY_MOB_ATK if start_count >= 4 else 1.0


static func swarm_density_spd_mult(start_count: int) -> float:
	return SWARM_DENSITY_SOLO_SPD if start_count == 1 else 1.0

# ── ダンジョンクリア EXP（P3-BAL-CLEAR-EXP-001） ─────────────────────────
## CLEAR 時のみ、ラン中獲得 EXP に乗せる完走ボーナス（リタイア／全滅なし）。
const CLEAR_EXP_BONUS_RATIO: float = 0.25

# ── 撃破 EXP 全体倍率（P3-BAL-KILL-EXP-150-001） ─────────────────────────
## モンスター討伐（戦闘撃破）のキャラ EXP に乗せる。クリアボーナスは積立の +25% 経由で連動。
## エリート部屋倍率・ティア・曜日×2・イベント MOD・図鑑調査などは既存どおり上乗せ。
const COMBAT_KILL_EXP_MULT: float = 1.5

# ── 曜日イベント撃破報酬（P3-BAL-WEEKDAY-EVENT-REWARD-001） ─────────────
## 曜日枠イベントDG（PRIMARY_WEEKDAY）の撃破 EXP／Gold 倍率。時間帯降臨は対象外。
## 敵ステ・装備ドロップ・日次1回は据置。野外 EventSystem MOD_* とは別経路。
const WEEKDAY_EVENT_REWARD_MULT: float = 2.0

# ── 長期戦怒涛（P3-BAL-COMBAT-ATTRITION-001） ─────────────────────────────
## 戦闘 CT が長いほど敵与ダメが段階上昇（回復ドレイン持久戦の締め）。
## grace 経過後に第1段、以降 STEP_CT ごとに +MULT_PER_STEP（上限 CAP）。
const ATTRITION_GRACE_CT: float = 18.0
const ATTRITION_STEP_CT: float = 12.0
const ATTRITION_MULT_PER_STEP: float = 0.12
const ATTRITION_MULT_CAP: float = 0.60


static func attrition_step(elapsed_ct: float) -> int:
	if elapsed_ct <= ATTRITION_GRACE_CT:
		return 0
	return int(floor((elapsed_ct - ATTRITION_GRACE_CT) / ATTRITION_STEP_CT)) + 1


static func attrition_outgoing_mult(elapsed_ct: float) -> float:
	var steps: int = attrition_step(elapsed_ct)
	if steps <= 0:
		return 1.0
	var bonus: float = minf(ATTRITION_MULT_CAP, float(steps) * ATTRITION_MULT_PER_STEP)
	return 1.0 + bonus
