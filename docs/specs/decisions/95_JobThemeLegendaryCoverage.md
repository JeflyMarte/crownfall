# 職ビルドテーマのL網羅（差し替え主軸）

**Status:** Decision 承認済（2026-08-08 — オーナー「推奨案でいきましょう」）  
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

---

## 2. 転用一覧（2026-08-08）

| ID | 新テーマ | 新効果概要 |
|---|---|---|
| `bloodvein_signet` | BT吸血 | 与ダメの10%吸収 |
| `ironvow_amulet` | RG探索 | パーティ探索・罠ダメ×0.75 |
| `quicksigil_charm` | RG拘束 | 冷却／鈍化敵与+15%、攻撃25%冷却 |
| `dawnrally_brooch` | VG味方バフ | 据置（開幕味方鼓舞） |
| `volley_horizon_bow` | RG探索 | 斉射維持＋宝箱部屋 weight+25 |
| `vanguard_war_bow` | VGカウンター | 開幕反撃+1、反撃ダメ+30% |
| `regicide_longbow` | SW一撃 | 初撃×1.45 |
| `amplify_orb_staff` | AL属性 | 属性つき与+25% |
| `silent_rite_staff` | BT異常 | 毒／炎上／感電付与＋それら敵与+20% |
| `veld_branch_staff` | VG味方バフ | 開幕味方鼓舞 |
| `consecrated_maul` | BT吸血 | 与ダメの8%吸収 |

既存のビルドL（`pulse_amulet`／`flurry_light_mail`／`cover_aegis_cloak`／`blade_dance_ring`／`hexweave_robe`／`blightcord_bow` 等）と合わせて、不足だった9テーマを **各2点以上** にする。

---

## 3. 配線メモ

- `treasure_room_weight_add` は装備パッシブからも効くよう `party_treasure_room_weight_add` を `for_member` 走査へ拡張
- 吸血は既存 `member_lifesteal_ratio`、探索減は `exploration_damage_party_mult_for_member`

---

## 4. スコープ外

- テーマ3点化の追加転用／新規
- レリック差し替え
- 展示室作例の装備差し替え（任意・後続）
