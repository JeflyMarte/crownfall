# キャラ差替えスキル枠 — パイロット（P3-SKILL-CHAR-SLOT-001）

**Status:** Decision **承認済**（2026-09-02 — オーナー「推奨でGO」）  
**親:** `94_JobSkillThemeKits`／`93_JobBuildThemesPassives`／`126_EngineerJob`  
**Maintains:** 職7本キット／装備枠1／Lv1・8・15は職共通／必殺・パッシブ枠は別 Decision

---

## 0. 一言

**案B** — 職習得7本のうち **Lv40 拡張枠1本だけ** をキャラ固有スキルに差し替える。パイロット＝**機巧士ガチャ助っ人3**（必殺・パッシブ差別化済み）。

---

## 1. 確定方針

| # | 決定 |
|---|---|
| P3-SKILL-CHAR-SLOT-001-1 | **差替え数** — 1枠／キャラ（Lv40） |
| P3-SKILL-CHAR-SLOT-001-2 | **差替え対象** — 職キットの `eng_scrap_burst`（拡張・敵全体薄ダメ） |
| P3-SKILL-CHAR-SLOT-001-3 | **パイロット** — `helper_q`／`helper_r`／`helper_s` |
| P3-SKILL-CHAR-SLOT-001-4 | **解決** — `GachaHelperData.skill_slot_replacements` が `JobData.skill_unlocks` を上書き |
| P3-SKILL-CHAR-SLOT-001-5 | **強さ** — 総量は `eng_scrap_burst`（×0.55 敵全）帯。差は付帯効果で個性化 |
| P3-SKILL-CHAR-SLOT-001-6 | **横展開** — 他職は別 Decision。2枠目・全7本差替えは Phase 4 以降 |

---

## 2. パイロット確定キット（Lv40）

| キャラ | 表示名 | id | 役割（テーマ） |
|---|---|---|---|
| トリム | **棘の雨** | `eng_trim_spike_rain` | 敵全体薄ダメ＋スパイク仕掛け（罠） |
| ブラン | **余熱波** | `eng_bran_ember_wave` | 敵全体炎＋炎上付与（装炎） |
| オルソ | **継ぎ目爆** | `eng_ortho_seam_burst` | 敵全体物理＋甲砕付与（破砕） |

### 数値（仮・実装正）

| id | 対象 | 倍率 | 付帯 | CD |
|---|---|---|---|---|
| `eng_scrap_burst`（職共通） | 敵全 | ×0.55 | — | 5.5 |
| `eng_trim_spike_rain` | 敵全 | ×0.50 | `eng_cascade`（スパイク最大3） | 6.0 |
| `eng_bran_ember_wave` | 敵全 | ×0.52 | `ignite` 45% | 6.0 |
| `eng_ortho_seam_burst` | 敵全 | ×0.52 | `armor_break` 40% | 6.0 |

---

## 3. 実装ピン

| 対象 | 内容 |
|---|---|
| `GachaHelperData.gd` | `skill_slot_replacements: Array[Dictionary]` |
| `SkillProgression.gd` | `get_unlock_entries_for_member`／装備 remap |
| `resources/skills/eng_trim_*` 他2 | tres 新規 |
| `resources/gacha_helpers/helper_*.tres` | replacements 接続 |
| GUT | 解放表・remap |

---

## 4. やらないこと

- 他職・スターター5への即横展開
- Lv30 以下の差替え
- 装備枠2／必殺再設計

---

## 5. 関連

- `126_EngineerJob` §6（キャラ別必殺・パッシブ）
- `41_UltimateRoleSplit`（必殺は職帯＋機巧士例外）
