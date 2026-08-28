# 機巧士ビルドL Phase A（P3-EQ-ENGINEER-LEG-001）

**Status:** Decision **承認済**（2026-08-28 — オーナー「推奨値で GO」）  
**関連:** `126_EngineerJob.md`／`95_JobThemeLegendaryCoverage.md`／`129_WarHammerWeapon.md`／`93_JobBuildThemesPassives.md`

---

## 1. 目的

機巧士3テーマ（罠／装炎／破砕）を **Decision 95** の「テーマあたり最低2点」に到達させる Phase A。  
灰冠／深層／SET／神話のカタログ同等は **後続**（`129` §4 同型）。

| テーマ | Phase A 前 | Phase A 後 |
|---|---|---|
| 罠 | 0 | **2** |
| 装炎 | 0 | **2** |
| 破砕 | 1（`seam_breaker_maul`） | **2** |

---

## 2. 設計原則

| # | 原則 |
|---|---|
| 1 | 効果は **テーマループ**（設置・発火・長CD・炎上・甲砕）。平与ダメ%だけを主軸にしない |
| 2 | 助っ人パッシブ（開幕印／長CD炎上／3 hit 甲砕）と **複製しない** |
| 3 | 武器割当：**戦鎚＝破砕＋装炎**、**双剣＝罠**（`129` 整合） |
| 4 | 新規 **5点**（武器2＋装飾3）。既存 `seam_breaker_maul` は据置 |
| 5 | 甲砕中与の装備合算は **最大 +35%**（`1.35` 倍）でキャップ |

---

## 3. 品目一覧（確定）

| テーマ | 種別 | id | 表示名 | パッシブ | 効果概要 |
|---|---|---|---|---|---|
| 罠 | 双剣 | `coil_spring_dual` | 巻取棘の双剣 | `eq_wpn_coil_spring_dual` | 設置する仕掛けの **残発+1** |
| 罠 | 装飾 | `trapgear_charm` | 罠綱の護符 | `eq_trapgear_charm` | **罠スキル**（`trap_place`）の CD **×0.88** |
| 装炎 | 戦鎚 | `pyrebrand_maul` | 焦熱刻印の戦鎚 | `eq_wpn_pyrebrand_maul` | **炎上中**の敵へ与 **+20%** |
| 装炎 | 装飾 | `overheat_amulet` | 過熱管の首飾り | `eq_overheat_amulet` | **CD≥12秒**のスキル威力 **×1.15** |
| 破砕 | 装飾 | `seam_focus_sigil` | 継ぎ目狙いの印環 | `eq_seam_focus_sigil` | **甲砕中**の敵へ与 **+15%**（装備合算 **最大1.35**） |

### 3.1 既存（据置）

| id | テーマ | 効果 |
|---|---|---|
| `seam_breaker_maul` | 破砕 | 甲砕中与+25%。攻撃25%甲砕 |

---

## 4. 入手

- **武器3本**（`coil_spring_dual`／`pyrebrand_maul`／`seam_breaker_maul`）：章 `weapon_pool`（戦鎚梯子接続済5章）＋グローバル `WEAPON_POOL`
- **装飾3本**：通常レジェンド抽選（`rarity=LEGENDARY`、ビルドL枠・灰冠除外外）

---

## 5. 実装フック（新規）

| キー | 用途 |
|---|---|
| `engineer_trap_fires_add` | 仕掛け設置時の残発加算 |
| `trap_skill_cd_mult` | `trap_place` タグ技能の CD のみ |
| `long_cd_skill_power_mult` + `long_cd_skill_min_cooldown` | 長CD決め技の威力 |
| `outgoing_vs_status_max_mult` | 特定状態（甲砕）への装備合算キャップ |

---

## 6. 後続（Phase B 以降）

- 双剣梯子＋Lの章完全埋め
- 灰冠／深層／SET／神話の機巧士枠
- ~~専用ICO（暫定は種別テンプレ／既存近縁）~~ → **Phase A 5点 専用ICO接続済**（2026-08-28）

---

## 7. SSOT

| 層 | ファイル |
|---|---|
| 本決定 | `docs/specs/decisions/130_EngineerLegendaryPhaseA.md` |
| テーマ網羅 | `95_JobThemeLegendaryCoverage.md` §追記 |
| 戦鎚 | `129_WarHammerWeapon.md` |
