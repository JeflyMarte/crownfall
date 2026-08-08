# ビルド拡張レジェンド防具・装飾（10本）

**Status:** Decision 承認済（2026-08-02 — オーナー「推奨10本でgo」）  
**Impl:** `P3-EQ-LEG-BUILD-001`  
**関連:** P3-EQ-LEG-001／P3-SKILL-KIT-DIVERGE-001／`48_SkillKitDiverge.md`／`49_SwordsmanSelfBuff.md`

---

## 1. 方針

Biome 固定★（x-5 ペア）とは別に、**スキル分化ビルドを補強する防具5＋装飾5**を追加する。  
クラシック差し替えではなく、初回ボス時に未所持から **追加1点** を付与する。

---

## 2. 装備一覧

| 種別 | ID | パッシブ | 効果概要 |
|---|---|---|---|
| 防具 | `bloodpact_plate` | `eq_bloodpact_plate` | 出血敵へ与+10%／被-15% |
| 防具 | `flurry_light_mail` | `eq_flurry_mail` | **罠糸の軽甲** — 冷却／鈍化敵へ与+20%、攻撃20%で鈍化（RG拘束） |
| 防具 | `bulwark_role_plate` | `eq_bulwark_role` | Threat+100、前列被弾で taunt+guard |
| 防具 | `cover_aegis_cloak` | `eq_cover_aegis` | **応撃の外套** — 開幕反撃チャージ+2、反撃ダメ+25%（VGカウンター） |
| 防具 | `hexweave_robe` | `eq_hexweave_robe` | 敵デバフ種類×-3%被ダメ（上限15%） |
| 装飾 | `blade_dance_ring` | `eq_blade_dance_ring` | **共鳴の指輪** — 属性つき攻撃／スキル与+18%（AL属性） |
| 装飾 | `pierce_charm` | `eq_pierce_charm` | 会心ダメ+15%（職非依存） |
| 装飾 | `pulse_amulet` | `eq_pulse_amulet` | **初撃の首飾り** — 戦闘初撃×1.40（SW一撃） |
| 装飾 | `beastlord_fang` | `eq_beastlord_fang` | ペット与+25%/防+10%、自身与-8% |
| 装飾 | `apothecary_vial` | `eq_apothecary_vial` | 回復+20%、回復対象に guard |

### 2026-08-08 テーマ網羅差し替え

職スキルテーマ再編（Decision 93/94）後の不足軸を埋めるため、発動が狭い／凡庸だった4本の効果を差し替え（ID・入手は維持）。

| 旧 | 新テーマ |
|---|---|
| 連撃軽甲（3撃微回復） | RG拘束 |
| 庇護外套（最傷庇護） | VGカウンター |
| 剣舞指輪（必殺／CD） | AL属性 |
| 鼓動首飾り（必殺／CD遅延） | SW一撃 |

追加の最低2点化（クラシック飾・フィル武など）は **`95_JobThemeLegendaryCoverage.md`**。

---

## 3. 入手

- 経路: `DungeonController.apply_boss_legendary_loot`（x-5 初回・ティア別）
- Biome 固定★に **加えて** `BuildLegendaryLoot.roll_one()` で未所持1点
- 通常プール／灰冠ガチャには入れない

---

## 4. アイコン

| ID | ファイル |
|---|---|
| bloodpact_plate | `ICO_ARM_BloodpactPlate.png` |
| flurry_light_mail | `ICO_ARM_FlurryLightMail.png` |
| bulwark_role_plate | `ICO_ARM_BulwarkRolePlate.png` |
| cover_aegis_cloak | `ICO_ARM_CoverAegisCloak.png` |
| hexweave_robe | `ICO_ARM_HexweaveRobe.png` |
| blade_dance_ring | `ICO_ACC_BladeDanceRing.png` |
| pierce_charm | `ICO_ACC_PierceCharm.png` |
| pulse_amulet | `ICO_ACC_PulseAmulet.png` |
| beastlord_fang | `ICO_ACC_BeastlordFang.png` |
| apothecary_vial | `ICO_ACC_ApothecaryVial.png` |

- 64×64 RGBA・`IconPaths` 登録・`LEGENDARY_HAND_DRAWN_*` で再生成スキップ
- 取込: `tools/import_build_legendary_icons.py`

## 5. スコープ外

- ~~AL／BT 専用ビルド装備（後続）~~ → **`54_PetHealerBuildGear.md` で実施**
- 神話枠への混入
