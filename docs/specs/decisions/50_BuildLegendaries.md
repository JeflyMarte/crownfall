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
| 防具 | `flurry_light_mail` | `eq_flurry_mail` | 被-8%、3攻撃ごとHP2%回復 |
| 防具 | `bulwark_role_plate` | `eq_bulwark_role` | Threat+100、前列被弾で taunt+guard |
| 防具 | `cover_aegis_cloak` | `eq_cover_aegis` | 最傷味方被-12%、自身被+5% |
| 防具 | `hexweave_robe` | `eq_hexweave_robe` | 敵デバフ種類×-3%被ダメ（上限15%） |
| 装飾 | `blade_dance_ring` | `eq_blade_dance_ring` | 必殺速度+15%、スキルCD×0.9 |
| 装飾 | `pierce_charm` | `eq_pierce_charm` | 貫通二次ダメ+35% |
| 装飾 | `pulse_amulet` | `eq_pulse_amulet` | 必殺速度+35%、スキルCD×1.15 |
| 装飾 | `beastlord_fang` | `eq_beastlord_fang` | オトモ与+25%/防+10%、自身与-8% |
| 装飾 | `apothecary_vial` | `eq_apothecary_vial` | 回復+20%、回復対象に guard |

---

## 3. 入手

- 経路: `DungeonController.apply_boss_legendary_loot`（x-5 初回・ティア別）
- Biome 固定★に **加えて** `BuildLegendaryLoot.roll_one()` で未所持1点
- 通常プール／灰冠ガチャには入れない

---

## 4. スコープ外

- 専用アイコン新規制作（既存L／形カテゴリ汎用を暫定流用）
- AL／BT 専用ビルド装備（後続）
- 神話枠への混入
