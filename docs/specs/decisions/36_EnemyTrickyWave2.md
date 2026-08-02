# 敵トリッキー第2波（T8／T10／T11／T14）

**Status:** Decision 承認済（2026-08-02 — オーナー「推奨でGo」）  
**Impl:** Phase A〜C ✅（`P3-BAL-ENEMY-TRICKY-005`〜`007`）  
**関連:** `35_EnemyTrickySkills.md`／P3-UX-ENEMY-RESIST-TELOP-001

---

## 1. 方針

T1〜T7 に加え、読みの違う特性をスポット配置で追加する。  
全敵一律禁止。1戦闘トリッキー原則 0〜1。ボス位相の全面置換なし。  
発動時は **戦闘内・スロット×種類で初回テロップ**（案A同型）。

---

## 2. タイプ定義

| ID | タイプ | 挙動 | 難度 |
|---|---|---|---|
| **T8** | 途中召集 | HP≤50% かつスキルで雑魚 **1体** 追加。戦闘中追加は **召喚者スロットあたり1回**。生存合計 ≤ `SWARM_SIZE_CAP`(5)。報酬は通常撃破 | 高 |
| **T10** | 沈黙 | 生存ランダム1人へ **スキル／必殺封印 5秒**（通常攻撃可）。封印中は頭上に **❌** | 高 |
| **T11** | 吸血 | パーティへ与えた実ダメの **30%** を自己回復 | 中 |
| **T14** | 時間稼ぎ | 他の生存敵1体の CT を加速（行動を早める）。T3 enrage と別 | 中 |

### 確定クローズ

| 項目 | 確定 |
|---|---|
| T10 対象 | **ランダム1人**（生存） |
| T8 タイミング | **HP≤50% + スキル**（1回） |
| T11 経済 | Gold奪いなし（吸血のみ） |
| パイロット | 既存敵キット差替。新敵・新アートなし |

---

## 3. パイロット

| タイプ | 敵 | 実装 |
|---|---|---|
| T11 | **`undertaker_shark`** | `lifesteal_ratio=0.3` |
| T14 | **`clock_moth`** | `enemy_chrono_haste`（haste） |
| T10 | **`tide_lamp`** | `enemy_tide_silence`（silence） |
| T8 | **`crown_eater_rat`** | `enemy_crown_call`（summon・同種1体） |

---

## 4. 段階

| Phase | Task | 内容 |
|---|---|---|
| A | **P3-BAL-ENEMY-TRICKY-005** | T11／T14 |
| B | **P3-BAL-ENEMY-TRICKY-006** | T10 |
| C | **P3-BAL-ENEMY-TRICKY-007** | T8 |

---

## 5. 横展開案A（`P3-BAL-ENEMY-TRICKY-008`・2026-08-02 GO）

章あたり +2〜3。エンジン追加なし。スポット据置。

| 章 | 敵 | タイプ |
|---|---|---|
| ① | `sepia_hound` | T11 吸血 |
| ② | `moss_boar` / `iron_horn` / `rune_carcinos` | T8 召集／T14 加速／T6 通常軽減 |
| ③ | `dead_poison_frog` / `spore_needle_wasp` / `bone_picker` | T1 状態／T4 自爆／T5 逃走 |
| ④ | `ship_eater_crab` / `ninja_octopus` | T3 味方バフ／T7 スキル軽減 |
| ⑤ | `storm_joe` / `oldrex` / `frost_claw_raptor` | T10 沈黙／T2 回復／T14 加速 |

---

## 6. スコープ外

- 全雑魚一律付与（案C）
- 分身ダミー（報酬なし）
- Gold／アイテム奪取
- 沈黙のパーティ全体付与
- ボス位相の書き換え
