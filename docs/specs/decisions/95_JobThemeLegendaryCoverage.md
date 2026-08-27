# 職ビルドテーマのL網羅（差し替え主軸）

**Status:** Decision 承認済（2026-08-08 — オーナー「推奨案でいきましょう」）  
**追記（2026-08-08）:** 職×武器種の装備制限を転用制約に追加（オーナー指摘）  
**関連:** `93_JobBuildThemesPassives.md`／`94_JobSkillThemeKits.md`／`50_BuildLegendaries.md`／`56_ClassicLegendaryAccessories.md`

---

## 1. 方針

| # | 項目 | 確定 |
|---|---|---|
| 1 | 目標 | 各職テーマを支える L を **最低2点**（理想2〜3） |
| 2 | 主軸 | **既存Lの効果差し替え**（ID・入手・アート維持） |
| 3 | 副 | ビルドプール編入は当面しない |
| 4 | 新規 | 量産しない。部位が足りないときだけ最小追加（本 Decision では0） |
| 5 | 触らない | Biome 固定ボスLの物語ペア（x-5）は原則据置 |
| 6 | **武器制約** | テーマ職が装備できない武器種へテーマ効果を載せない（防具・装飾は職共通） |

### 職 × 装備可能武器

| 職 | 装備可 |
|---|---|
| ソードマン | 剣・双刃 |
| レンジャー | 弓・剣 |
| ヴァンガード | 剣・杖 |
| アルケミスト | 杖・双刃 |
| ビーストテイマー | 杖・弓 |
| 機巧士 | 戦鎚・双剣 |

---

## 2. 転用一覧（2026-08-08／同日・武器種修正）

| ID | 種別 | テーマ職が装備可 | 新テーマ | 新効果概要 |
|---|---|---|---|---|
| `bloodvein_signet` | 飾 | ○ | BT吸血 | 与ダメの10%吸収 |
| `ironvow_amulet` | 飾 | ○ | RG探索 | パーティ探索・罠ダメ×0.75 |
| `quicksigil_charm` | 飾 | ○ | RG拘束 | 冷却／鈍化敵与+15%、攻撃25%冷却 |
| `dawnrally_brooch` | 飾 | ○ | VG味方バフ | 据置（開幕味方鼓舞） |
| `volley_horizon_bow` | 弓 | RG○ | RG探索 | 斉射維持＋宝箱部屋 weight+25 |
| `vanguard_war_bow` | 弓 | RG○ | RG標的 | 標的与+20%、攻撃25%標的 |
| `regicide_longbow` | 弓 | BT○ | BT吸血 | 与ダメの8%吸収 |
| `amplify_orb_staff` | 杖 | AL○ | AL属性 | 属性つき与+25% |
| `silent_rite_staff` | 杖 | BT○ | BT異常 | 毒／炎上／感電付与＋それら敵与+20% |
| `veld_branch_staff` | 杖 | VG○ | VG味方バフ | 開幕味方鼓舞 |
| `consecrated_maul` | 剣 | SW○ | SW一撃 | 初撃×1.45 |
| `aegis_line_sword` | 剣 | VG○ | VGカウンター | 開幕反撃+1、反撃ダメ+30%（脅威も軽く残す） |

### 機巧士・戦鎚L（2026-08-27 — `129` 梯子A／新規最小）

新武器種のため転用ではなく **最小新規1本**（方針§1-4の例外。追加テーマLは後続）。

| ID | 種別 | テーマ | 効果概要 |
|---|---|---|---|
| `seam_breaker_maul` | 戦鎚 | EN破砕 | 甲砕中与+25%。攻撃25%で甲砕 |

既存のビルドL（`pulse_amulet`／`flurry_light_mail`／`cover_aegis_cloak`／`blade_dance_ring`／`hexweave_robe`／`blightcord_bow` 等）と合わせて、不足だったテーマを **各2点以上** にする。

### 修正前の誤り（参考）

弓を SW一撃／VGカウンターへ、剣を BT吸血へ載せていた → 職が装備不可のため上記へ組み直し。

---

## 3. 配線メモ

- `treasure_room_weight_add` は装備パッシブからも効くよう `party_treasure_room_weight_add` を `for_member` 走査へ拡張
- 吸血は既存 `member_lifesteal_ratio`、探索減は `exploration_damage_party_mult_for_member`

---

## 4. スコープ外

- テーマ3点化の追加転用／新規
- レリック差し替え
- 展示室作例の装備差し替え（任意・後続）
