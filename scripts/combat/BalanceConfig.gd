class_name BalanceConfig
extends RefCounted

## 戦闘バランス定数の中央 SSOT（P3-BAL-005）。
## 各所の GDScript に散在していたグローバル倍率をここへ集約する。
## 個別エンティティの基礎値（敵HP/スキル倍率等）は従来通り .tres が正。

# ── ダメージ計算（旧 DungeonScene 定数） ──────────────────────────────────
const FALLBACK_ATTACK: int = 10
const CRITICAL_MULTIPLIER: float = 1.5
## 敵DEF逓減軽減 K/(K+DEF)（P3-BAL-002）
const DEFENSE_MITIGATION_K: float = 100.0
## Biome 有利属性 与ダメ倍率（P3-D099）
const BIOME_FAVORED_BONUS: float = 1.15
## 防具属性耐性 被ダメ倍率（P3-D103）
const ARMOR_RESIST_MULTIPLIER: float = 0.75
