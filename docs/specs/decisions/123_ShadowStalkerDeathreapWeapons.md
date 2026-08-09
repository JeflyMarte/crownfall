# 影狩限定武器「死告」（P3-EQ-SHADOW-DEATHREAP-001）

**Status:** SSOT（Decision 承認済）  
**Approved:** 2026-08-10（オーナー GO）  
**Scope:** 影狩撃破で落ちる限定 L 武器4種。通常雑魚への確率即死。セット／エンシェント／灰冠席ビルドではない。

---

## 1. 概要

影狩（`shadow_stalker`）撃破のご褒美として、**死告**シリーズの武器を置く。  
効果は攻撃命中時の **雑魚限定即死**。武防飾セット加護は置かない。

---

## 2. 品目

| 部位 | id | 表示名 | `weapon_type` |
|---|---|---|---|
| 剣 | `deathreap_sword` | 死告の剣 | `sword` |
| 双刃 | `deathreap_dual` | 死告の双鎌 | `dual_blades` |
| 弓 | `deathreap_bow` | 死告の弓 | `bow` |
| 杖 | `deathreap_staff` | 死告の杖 | `staff` |

- レア: **LEGENDARY（L）**
- 属性: **闇**
- 共通パッシブ: `eq_wpn_deathreap`
- 通常ドロップ／灰冠／SET／神話／鍛冶生産／レイヴン伝説補完プールには載せない

---

## 3. 効果（`eq_wpn_deathreap`）

| # | 項目 | 決定 |
|---|---|---|
| 1 | 型 | 命中時確率即死（型1） |
| 2 | 確率 | **15%**（N／H／NM 同率） |
| 3 | 発動 | **通常攻撃＋攻撃系スキル**（`_deal_member_damage_to_enemy` 経由の与ダメ） |
| 4 | 対象 | `EnemyType.NORMAL` かつ **非放浪** |
| 5 | 除外 | ELITE／BOSS／放浪（影狩本体含む） |
| 6 | 連れ | ボス召喚でも NORMAL かつ非放浪なら可 |
| 7 | 保険 | 即死対象外の敵へ攻撃時 **25%で出血** |

---

## 4. 入手

| # | 項目 | 決定 |
|---|---|---|
| 1 | 経路 | 放浪遭遇の影狩撃破 ＋ 曜日イベント「影狩りの狩場」 |
| 2 | 未所持（死告0本） | 撃破で **1本確定**（編成職の装備可能種優先） |
| 3 | 以降 | 撃破ごと **25%**。未所持種優先。全所持ならいずれか |
| 4 | 汎用装備ドロップ | 現行の影狩レア抽選は **据置**（死告は別枠上乗せ） |

---

## 5. 実装正

- `ShadowStalkerLoot.gd` — 品目・付与・対象判定
- `CombatPassives.gd` — `eq_wpn_deathreap`
- `DungeonScene._try_fire_passive` — `effect: instant_kill_trash`
- `DungeonController` — 撃破時付与＋伝説プール除外
- `CraftHelper` — `deathreap_` 生産除外

---

## 6. スコープ外

- 防具／装飾の死告セット
- エンシェント（SET）加護
- 即死の難易度別確率
- 専用手描きアイコン（自動生成可）
