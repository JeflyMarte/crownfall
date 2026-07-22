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

# ── ダメージ計算（旧 DungeonScene 定数） ──────────────────────────────────
const FALLBACK_ATTACK: int = 10 * STAT_SCALE
const CRITICAL_MULTIPLIER: float = 1.5
## 武器デフォルト（P3-EQ-STAT-005）。個体未設定時に使用。
const DEFAULT_WEAPON_ATTACK_SPEED: float = 1.0
const DEFAULT_WEAPON_CRITICAL_RATE: float = 0.05
const DEFAULT_WEAPON_CRITICAL_DAMAGE: float = CRITICAL_MULTIPLIER
const DEFAULT_BANE_MULTIPLIER: float = 1.3
## 属性値→与ダメ倍率: damage × (1 + element_power × K)。無属性時は適用しない。
const ELEMENT_POWER_K: float = 0.01
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
## Lv51〜99 の逓減成長（新スキル習得なし）
const HP_PER_LEVEL_MASTER: int = 3 * STAT_SCALE
const ATTACK_PER_LEVEL_MASTER: int = 1 * STAT_SCALE

# ── 回復スキル基準値（旧 DungeonScene 定数） ─────────────────────────────
const HEAL_SKILL_BASE: int = 14 * STAT_SCALE
## 回復部屋の固定回復（旧 10）
const ROOM_HEAL_AMOUNT: int = 10 * STAT_SCALE

# ── 探索罠（最大HP割合 / P3-TRAP-PCT-001） ───────────────────────────────
## 単体被弾
const TRAP_MAX_HP_FRAC_COMBAT_SINGLE: float = 0.10
const TRAP_MAX_HP_FRAC_ROOM_SINGLE: float = 0.15
## 全体被弾（単体より低め）
const TRAP_MAX_HP_FRAC_COMBAT_AOE: float = 0.05
const TRAP_MAX_HP_FRAC_ROOM_AOE: float = 0.08
## 発動時に全体パターンになる確率
const TRAP_AOE_CHANCE: float = 0.35

# ── 敵レベルスケール（P3-D081） ──────────────────────────────────────────
const ENEMY_LEVEL_HP_K: float = 0.10
const ENEMY_LEVEL_ATK_K: float = 0.10
const ENEMY_LEVEL_EXP_K: float = 0.15

# ── 編成人数補正（P3-BAL-003・base=3人） ─────────────────────────────────
const PARTY_BALANCE_HP_SHARE: float = 0.85
const PARTY_BALANCE_ATK_SHARE: float = 0.40

# ── 序盤〜全体の難易度再調整（P3-BAL-OPENING-001 / 002） ──
## 戦闘開始時に敵 HP/ATK へ乗算（全ダンジョン共通）。
## OPENING-002: HP をさらに上げて数撃交換に（ATK グローバルは据置＝逓減式で脅威を出す）。
const ENEMY_GLOBAL_HP_MULT: float = 2.00
const ENEMY_GLOBAL_ATK_MULT: float = 1.30
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
const DOT_FLAT_POISON: int = 4 * STAT_SCALE
const DOT_FLAT_IGNITE: int = 3 * STAT_SCALE
const COMBO_POISON_PER_STACK: int = 8 * STAT_SCALE
const COMBO_BLEED_PER_STACK: int = 6 * STAT_SCALE
const SPARE_VIAL_HEAL: int = 12 * STAT_SCALE

# ── 陣形（P3-D106） ──────────────────────────────────────────────────────
const FORMATION_BACK_INCOMING: float = 0.85  # 後列の被ダメ倍率
const FORMATION_BACK_THREAT: float = 0.6     # 後列の Threat 基礎倍率
const DENSE_ROW_INCOMING: float = 1.08       # 密集列 被ダメ倍率
const SPREAD_ROW_INCOMING: float = 0.94      # 散開列 被ダメ倍率

# ── エンカウント（P3-D082/D110） ─────────────────────────────────────────
const SWARM_CHANCE: float = 0.24        # COMBAT 部屋の群れ出現率
const MIXED_SWARM_CHANCE: float = 0.50  # 群れ時に別種を混ぜる確率
