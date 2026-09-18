# 王痕育成（P3-DG-ROYAL-MARK-001）

**Status:** **Implemented**（2026-09-18）— Phase 1／feature `cursor/royal-mark-144`（**main 未マージ**）  
**上書きなし**（極限任務 Decision 143 は Completed のまま）

---

## 0. 一言

極限任務の恒久目的として、人間キャラクターに **王痕 I〜V**（ステ倍率）を付与する。固有 Passive／限凸とは独立。

---

## 1. 対象

| 項目 | 内容 |
|---|---|
| 対象 | 人間プレイアブル 19 人（`Adventurer.id`） |
| 除外 | Jack／他ペット |
| 解放 | メイン Biome 1〜5 Normal CLEAR |
| 強化条件 | roster 所持・Lv50 以上・片／Gold |

---

## 2. Rank（累積）

| Rank | 効果（累積倍率） | 片 | Gold |
|---|---|---:|---:|
| I | HP ×1.03 | 10 | 5,000 |
| II | HP×1.03／ATK×1.03 | 15 | 10,000 |
| III | HP/ATK×1.03／DEF×1.03 | 20 | 15,000 |
| IV | HP/ATK/DEF ×1.05 | 25 | 25,000 |
| V | HP/ATK/DEF ×1.08 | 30 | 45,000 |

累計コスト: 片 100／Gold 100,000。

ステ適用位置: `(base+equip+affix+level)×job` の直後。戦闘専用 modifier はその後。UI と Combat は同一ヘルパ。

---

## 3. 極限報酬

EX-01〜10 共通。

| ★帯 | 初回到達片 |
|---:|---:|
| 1 | 3 |
| 2 | +3 |
| 3 | +4 |
| 4 | +5 |

差分のみ（`prev_best` → `stars`）。1任務最大 15。

CLEAR ごと 25% で片×1（初回 CLEAR 含む）。`force_repeat_roll`／`rng` 注入可。

同一ラン二重 commit は `GameState.extreme_run_reward_committed` で遮断（★・周回とも）。

---

## 4. Save（v18）

| キー | 型 |
|---|---|
| `royal_mark_shards` | int |
| `royal_mark_ranks` | `{ Adventurer.id: 0..5 }` |

v17→v18: 既存 `extreme_mission_progress[*].best_stars` から一度だけ遡及（★1=3 … ★4=15、EX合算）。再 migrate しない。

---

## 5. 実装アンカー

- `scripts/systems/RoyalMarkConfig.gd`／`RoyalMarkSystem.gd`
- `GameState`／`SaveManager`（SAVE_VERSION 18）
- `ExtremeMissionConfig.commit_clear_result`
- `RosterUiHelper`／`CombatController`／`DamageCalculator`
- `EquipmentScene`（限凸近傍）／`ResultScene`
- `tests/unit/test_royal_mark.gd`

---

## 6. 非スコープ

王痕 VI+／Passive 変更／限凸変更／新キャラ・装備・ダンジョン／極限 TUNING 変更／Decision 143 変更。
