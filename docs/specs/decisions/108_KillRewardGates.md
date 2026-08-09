# 撃破報酬ゲート（護衛・召喚・二重付与）（P3-FIX-KILL-REWARD-GATES-001）

**日付:** 2026-08-09  
**状態:** 承認（オーナー＝撃破報酬全般／エリート護衛／DoT 監査の是正）

## 要旨

ボス章★と同型の漏れを塞ぐ。部屋種別だけでプレミアムを付けず、**撃破した entity** でゲートする。追撃／DoT による二重撃破報酬も冪等化する。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-FIX-KILL-REWARD-GATES-001-1 | **エリートボーナス／`kill_elite`／エリート武器率・レリック**は `is_run_elite_kill`（`enemy_type == ELITE`）時のみ | 護衛撃破でエリート報酬が乗っていた |
| P3-FIX-KILL-REWARD-GATES-001-2 | **ボス Discovery +0.20／ボス death アニメ／ボス武器率・レリック**は `is_run_boss_kill` 時のみ | 召喚撃破で本体扱いしていた（章★は既修正） |
| P3-FIX-KILL-REWARD-GATES-001-3 | **撃破報酬はスロット冪等**（`_kill_award_slots`）。DoT は既死スロット skip。追撃キル後の外側 hooks も first_kill のみ | マルチ DoT／`on_attack` 追撃で二重 EXP・ドロップ |
| P3-FIX-KILL-REWARD-GATES-001-4 | **`on_kill`／`record_run_kill` は `_on_enemy_slot_killed(killer)` に集約**。追撃・余波・枯翠も含む。DoT／自爆は killer=-1 | パッシブ直接ダメ撃破で hooks 欠落 |
| P3-FIX-KILL-REWARD-GATES-001-5 | **ボス武器率は `is_run_boss_kill` のみ**（`enemy_type==BOSS` フォールバック削除）。レリックは `enemy_data==null` で空 | Decision 整合／fail-closed |
| P3-FIX-KILL-REWARD-GATES-001-6 | **召喚は死体スロット再利用**。上限は生存数のみ | 護衛撃破後に追加召喚不可 |

## 非スコープ

- 護衛雑魚の通常 EXP／Gold／図鑑（従来どおり付与）
- 部屋クリア時の別系統報酬
- 無限併走エリートへのエリートプレミアム（別判断）
- 同 tick clear+wipe 優先（現状 DoT は撃破で early return）
