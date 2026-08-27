# 戦鎚武器種（P3-EQ-WARHAMMER-001）

**Status:** Decision **承認済**（2026-08-27 — オーナー GO）  
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
| 一発 | 高い（同レア帯で剣より ATK 寄り） |
| 制御 | ノックバック／よろけ寄り（COMMON 目安 KB **0.85**／stagger **0.55**） |
| ビルド | 甲砕・ブレイク印・破砕テーマと相性 |
| VFX/SFX | 鈍器の打ち込み（斬撃系と差をつける） |

---

## 3. 最小実装（本 Decision 接続）

| 項目 | 内容 |
|---|---|
| COMMON | `iron_warhammer`（王国制式戦鎚）— プール／初期装備用 |
| JobData | `engineer.preferred_weapon_types` = `dual_blades`, `hammer` |
| 初期武器 | 機巧士スターター = `iron_warhammer`（旧 `hunting_bow`） |
| 図鑑表示 | `CodexContentHelper` に `hammer` → 戦鎚 |
| 後続 | 戦鎚のドロップ帯拡充・専用L（`95`）・Wiki・専用ICO |

---

## 4. やらないこと（本 Decision 範囲外）

- 戦鎚の大量新規L／全Biome横展開
- `consecrated_maul` の `hammer` 移行
- ソードマン等への戦鎚解放
- 槍など他の将来武器種の同時追加
