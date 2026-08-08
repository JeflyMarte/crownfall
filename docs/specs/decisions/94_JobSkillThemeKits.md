# 職スキルキット・テーマ再編（P3-SKILL-THEME-KIT-001）

**Status:** Decision 承認済（2026-08-08 — プラン実装 GO）  
**Overrides:** `20_SkillKitCompress.md` §4 キット表／`48_SkillKitDiverge.md`（SW Lv15）／`62_VanguardSkillTriad.md`・`84_VanguardKitTune.md`（VG 攻撃軸1本）／`82_RgBtSkillOrder.md`・`83_BtRgKitTune.md`（RG 順序）の該当行  
**Maintains:** 習得7／装備枠1／必殺スコープ外／`93_JobBuildThemesPassives.md` 職テーマ／火鷹パッシブ据置

---

## 1. 方針

| # | 決定 |
|---|---|
| P3-SKILL-THEME-KIT-001-1 | 各職7本＝**テーマ本体5**＋**拡張枠2** |
| P3-SKILL-THEME-KIT-001-2 | 拡張枠は他職本家より常に弱い（RG回復≪AL、SW自己バフ≠VG味全） |
| P3-SKILL-THEME-KIT-001-3 | 職テーマ正は Decision 93 |
| P3-SKILL-THEME-KIT-001-4 | 同型威力階段を復活させない |

---

## 2. 確定キット

### 2.1 ソードマン（出血／一撃／会心 ＋ 拡張: 自己バフ・群れ）

| Lv | id | 表示名 | 枠 | 役割 |
|---|---|---|---|---|
| 1 | `slash_attack` | 一閃 | テーマ | 短CD回転（一撃） |
| 8 | `rend_slash` | 裂傷斬 | テーマ | 出血付与 |
| 15 | `keen_slash` | 鋭閃 | テーマ | **会心寄り**（`crit_rate_bonus`+0.40） |
| 22 | `blade_tempest` | 剣嵐 | 拡張 | 敵全物理 |
| 30 | `battle_spirit` | 闘気 | 拡張 | 自己 empower |
| 40 | `blood_mist_slash` | 血煙斬 | テーマ | 敵全出血 |
| 50 | `apex_slash` | 極意斬 | テーマ | 長CDバースト |

- 旧 `blade_dance` は習得外・データ残置。remap → `keen_slash`

### 2.2 レンジャー（標的／拘束／探索 ＋ 拡張: 薄回復・群れ）

| Lv | id | 表示名 | 枠 | 役割 |
|---|---|---|---|---|
| 1 | `aimed_shot` | スナイプショット | テーマ | 精密＋甲砕 |
| 8 | `snare_shot` | スネアアロー | テーマ | 拘束（鈍化） |
| 15 | `camp_draught` | 野営の一滴 | 拡張 | 味全薄回復（AL未満） |
| 22 | `hunter_mark` | 狩人の標 | テーマ | 標的 |
| 30 | `trail_ward` | 踏破の護符 | テーマ | **探索適性・装備効果のみ**（非戦闘入場 味全5%回復／罠×0.75。戦闘では撃たない） |
| 40 | `volley_shot` | 斉射 | 拡張 | 敵全ダメ |
| 50 | `apex_shot` | 極意射 | テーマ | 長CD決め矢 |

- 旧 `piercing_shot` は習得外・残置。remap → `volley_shot`

### 2.3 ヴァンガード（挑発／味バフ／カウンター ＋ 拡張: 自己粘り・攻撃）

| Lv | id | 表示名 | 枠 | 役割 |
|---|---|---|---|---|
| 1 | `guard_strike` | 衛士斬り | テーマ | ヘイト維持の軽攻撃（硬直） |
| 8 | `offensive_stance` | 攻勢の構え | テーマ | 味全 empower |
| 15 | `menace_strike` | 威嚇斬 | テーマ | 敵全＋挑発 |
| 22 | `bulwark_aura` | 壁守り | テーマ | 味全 guard |
| 30 | `riposte_stance` | 応撃の構 | テーマ | **カウンター**（guard＋被弾反撃チャージ2） |
| 40 | `drain_slash` | ドレインスラッシュ | 拡張 | 自己吸血 |
| 50 | `assault_shatter` | 突撃破砕 | 拡張 | 攻撃決め技 |

- 旧 `shield_crush` は習得外・残置。remap → `riposte_stance`（攻撃軸1本削減）

### 2.4 アルケミスト（デバフ／回復／属性 ＋ 拡張: 味バフ）

| Lv | id | 表示名 | 枠 | 役割 |
|---|---|---|---|---|
| 1 | `hex_bolt` | アンブラボルト | テーマ | 速攻デバフ |
| 8 | `mend` | 治癒 | テーマ | 単体回復 |
| 15 | `attuned_bolt` | 属性共鳴 | テーマ | **属性**（装備武器属性・×1.5・対応状態30%。旧 `frail_dust` から置換） |
| 22 | `rally_vapors` | 腐食の煙 | 拡張 | 敵全弱ダメ＋脆弱（瘴気より薄威力） |
| 30 | `curse_sigil` | 呪印 | テーマ | 重デバフ |
| 40 | `miasma_cloud` | 瘴気の霧 | テーマ | 群れデバフ |
| 50 | `salve_burst` | 大治癒 | テーマ | 全体回復 |

### 2.5 ビーストテイマー（ペット／異常／吸血 ＋ 拡張: 味バフ）

| Lv | id | 表示名 | 枠 | 役割 |
|---|---|---|---|---|
| 1 | `toxin_dart` | 毒矢 | テーマ | 状態異常 |
| 8 | `pet_bond_rally` | 相棒鼓舞 | テーマ | ペット強化 |
| 15 | `beast_vet_care` | 血還の矢 | テーマ | 吸血 |
| 22 | `beast_hobble` | 絡み矢 | テーマ | 誘導異常（冷却） |
| 30 | `herd_call` | 群れ纏い | 拡張 | 味全 guard_minor＋ペット maxHP15%回復 |
| 40 | `pet_command_fang` | 指揮の牙 | テーマ | ペット連携 |
| 50 | `apex_tame` | 極意調教 | テーマ | 長CD＋ペット |

---

## 3. 実装メモ

- `SkillData.crit_rate_bonus`（SW 鋭閃）
- `CombatPassives` 戦闘スコープのカウンターチャージ（VG 応撃の構）
- 装備中 `trail_ward` の罠軽減＋非戦闘入場 味全5%回復（RG）
- `frail_dust` → `attuned_bolt`（装備武器属性。remap あり）
- `SkillProgression.EQUIPPED_SKILL_REMAP` 追記
- SSOT ゲーム表: `docs/specs/game/06_キャラクター_ジョブ.md`

---

## 4. やらないこと

- 必殺再設計／装備枠2／パッシブ再変更／同型威力階段
