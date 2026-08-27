# 戦鎚武器種（P3-EQ-WARHAMMER-001）

**Status:** Decision **承認済**（2026-08-27 — オーナー GO）／**梯子A GO＋接続**（同日）  
**関連:** `07_JobWeaponRestrict.md`／`126_EngineerJob.md`／`95_JobThemeLegendaryCoverage.md`／`game/07_武器_装備.md`

---

## 1. 確定

| # | 項目 | 内容 |
|---|---|---|
| 1 | 表示名 | **戦鎚** |
| 2 | `weapon_type` | `hammer` |
| 3 | 立ち回り | **破砕**（推奨案①） |
| 4 | 機巧士許可 | **戦鎚・双剣**（`hammer`, `dual_blades`）。**弓は外す** |
| 5 | 他職 | 当面 **機巧士のみ** |
| 6 | 既存L | `consecrated_maul` 等は **据置**（現行 `sword` のまま。種別移行は別 Decision） |

旧方針「オルソの槌は見た目のみ／新種同時追加しない」（`126` §8）は **本決定で置換**。

---

## 2. 特性（仮数値・実装時調整可）

| 項目 | 内容 |
|---|---|
| 理想距離 | 近接やや長め（`base_attack_range` 目安 **1.15**・カテゴリは melee） |
| 攻速 | 遅め（COMMON 目安 **0.80**。剣 1.0／双剣 1.1 より遅い） |
| 一発 | 高い（同レア帯で剣 ATK×約1.15） |
| 制御 | ノックバック／よろけ寄り（KB **0.85**／stagger **0.55**） |
| ビルド | 甲砕・ブレイク印・破砕テーマと相性 |
| VFX/SFX | 鈍器の打ち込み（斬撃系と差をつける） |

---

## 3. 梯子A（**確定** — 2026-08-27 オーナー GO）

章ドロップ梯子を他種並みに埋める。カタログ完全同等（灰冠／深層／SET／神話）は後続。

| 帯 | 本数 | ID |
|---|---|---|
| R0 | 5 | `iron_warhammer`（モーン）／`mire_warhammer`／`verdant_maul`／`ridge_maul`／`black_sand_maul` |
| R1 | 4 | `storm_maul`／`pyre_maul`／`glacier_maul`／`lighthouse_maul` |
| R2 | 4 | `thunderfen_maul`／`symbiont_maul`／`permafrost_maul`／`sanctum_tide_maul` |
| R3 | 1 | **`seam_breaker_maul`（継ぎ目穿ちの戦鎚）** — 機巧士破砕テーマL |

**L効果:** 甲砕中与ダメ +25%。攻撃時25%で甲砕付与（`eq_wpn_seam_breaker_maul`）。

**プール:** 各章 dungeon `weapon_pool` に当該梯子3本＋L。モーンに制式＋L。グローバル `WEAPON_POOL` に制式＋L。

**ICO:** 当面 `ICO_WPN_ConsecratedMaul` 流用。専用アートは後続。

---

## 4. やらないこと（本 Decision 範囲外）

- カタログ本数の完全同等（灰冠席・深層・SET・神話の戦鎚枠）
- `consecrated_maul` の `hammer` 移行
- ソードマン等への戦鎚解放
- 槍など他の将来武器種の同時追加
- 罠／装炎向け戦鎚Lの追加（破砕L1本で梯子A完了。追加は任意後続）
