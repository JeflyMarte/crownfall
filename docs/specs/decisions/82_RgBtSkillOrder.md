# BT／RG スキル順・到達技（回復前倒し＋極意復帰）

**ID:** P3-SKILL-RG-BT-ORDER-001  
**日付:** 2026-08-06  
**状態:** 承認（オーナー「オッケー」＝案A）  
**Overrides:** `43_BtRgSupportHeal.md` の「Lv50＝回復」差し替え  
**Maintains:** 7本キット／解放Lv帯 1/8/15/22/30/40/50／必殺は別枠

---

## 要旨

1. 回復は **3つ目（Lv15）** へ前倒し  
2. **Lv50＝職象徴の重い到達技**（極意射／極意調教）。CD はグランドエリクサー級の「決め技」感（**CD24**）  
3. 7本維持のため RG は `hunting_ground_mark`、BT は `venom_spray` を習得外（tres 残置）

---

## 確定順

| Lv | レンジャー | ビーストテイマー |
|---|---|---|
| 1 | `aimed_shot` スナイプ | `toxin_dart` 毒矢 |
| 8 | `volley_shot` 斉射 | `pet_bond_rally` 相棒鼓舞 |
| **15** | **`camp_draught` 野営の一滴**（全体8%） | **`beast_vet_care` 血還の矢**（ドレイン） |
| 22 | `hunter_mark` 狩人の標 | `beast_hobble` 絡み矢 |
| 30 | `snare_shot` スネア | `herd_call` 群れの號令 |
| 40 | `piercing_shot` 貫通射 | `pet_command_fang` 指揮の牙 |
| **50** | **`apex_shot` 極意射** | **`apex_tame` 極意調教** |

> 2026-08-07: RG Lv8/30 入替・獣医／野営の効果変更は `83_BtRgKitTune.md`。

## 到達技（Lv50）

| id | 威力 | CD | 備考 |
|---|---:|---:|---|
| `apex_shot` | **2.7** | **24** | 旧 2.35／CD7。RG 決め矢 |
| `apex_tame` | **2.55** | **24** | 旧 2.2／CD7。命中時ペット強化タグ維持 |

必殺（`dead_eye`／`beast_dominion`／`grand_elixir`）は変更なし。

## 習得外（残置）

| id | 備考 |
|---|---|
| `hunting_ground_mark` | 敵全標的。データ残置 |
| `venom_spray` | 敵全毒。データ残置 |

## SSOT

- `resources/jobs/{ranger,beast_tamer}.tres`
- `resources/skills/{apex_shot,apex_tame,camp_draught,beast_vet_care}.tres`
- 上書き: `20_SkillKitCompress` §4.2／4.5、`43_BtRgSupportHeal`、`06_キャラクター_ジョブ`
