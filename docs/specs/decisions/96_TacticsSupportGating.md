# 戦術サポート発火ゲート（回復閾値・バフ再付与・カテゴリ偏り）

**ID:** P3-BAL-TACTICS-SUPPORT-001  
**日付:** 2026-08-08  
**状態:** 承認（オーナー指示・計画確定）

## 要旨

行動方針6択は維持したまま、スキル枠内の回復・バフ連発を抑える。

1. 回復は方針ごとの HP 閾値（＋緊急安全弁）  
2. バフは対象に同ステータスが残っている間は温存  
3. スキルスロット内で damage / heal / buff のカテゴリ偏り  
4. 攻撃特化のスロット重みをスキル↓／通常↑に微調整  

## 回復閾値（最傷味方 HP 割合）

| 方針 | 回復可 |
|---|---|
| `attack_focus` | &lt; 0.45 |
| `conserve_ultimate` | &lt; 0.55 |
| `balanced` | &lt; 0.65 |
| `defend_focus` | &lt; 0.70 |
| `support_focus` | &lt; 0.80 |
| `attack_only` | スキルなし |

共通安全弁: 最傷 &lt; **0.35** なら上記より厳しい方針でも回復可（`attack_only` 除く）。

`mend` / `salve_burst` / `camp_draught` の `reserve_condition=ally_injured` は廃止し、コード側ゲートに統一。

## バフ再付与

`effect_type=buff` かつ主 `apply_status_id` あり:

| 対象 | スキップ条件 |
|---|---|
| self | 自身が所持 |
| pet | ペットが所持 |
| ally | 付与予定の最傷（無ければ自己）が所持 |
| all_party 等 | 通常方針: 生存味方の**過半**が所持／`support_focus`: **全員**所持 |

敵デバフ付き攻撃は対象外。不発時は CD 非消費・次候補へ。

## カテゴリ重み（スキル枠内）

| 方針 | damage | heal | buff |
|---|---|---|---|
| `attack_focus` | 70 | 15 | 15 |
| `conserve_ultimate` | 55 | 25 | 20 |
| `balanced` | 45 | 30 | 25 |
| `defend_focus` | 35 | 35 | 30 |
| `support_focus` | 20 | 45 | 35 |

ゲート不合格カテゴリは重み0。`support_focus` の `skill_index` 直指定は廃止。

## スロット重み

`attack_focus`: skill **36** / attack **46**（必殺・防御据置）。

## SSOT

- `scripts/combat/CombatTactics.gd`
- `scripts/dungeon/DungeonScene.gd`（ctx・スキル選択）
- `scripts/combat/CombatController.gd`（最傷 HP 比）
- 上書き: 本 Decision（P3-D113 の ally_injured 温存より優先）
