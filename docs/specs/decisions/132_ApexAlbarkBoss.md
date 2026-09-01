# 征討 Boss アルバーク — 降臨帯へ寄せ（P3-DG-APEX-BOSS-001）

**Status:** Decision **承認済**（2026-08-30 — オーナー「Goで」／案B・推奨A＋白静寂0.60）  
**親:** `128_ApexConquestRedefine`  
**維持:** `13_ChronosWaveDragon`「クロノス＝アルバーク超え」  
**参照帯:** `15_ValgardGolem`／`14_ChronosDescent`（現行 `valgard`／`chronos_wave` データ）  
**戦闘ICO／図鑑:** ART＋ターン＋白静寂／地図なき突進 専用接続済（エルディオン流用解除・2026-08-31）

---

## 0. 一言

征討パイロット Boss `albark` の **ステ・圧力技倍率を降臨エンドボス帯に再定義**する。キット構成・Hex・フェーズ骨格は据置。ATK がクロノス／ヴァル超えだった旧値を是正する。

---

## 1. 確定方針

| # | 決定 |
|---|---|
| P3-DG-APEX-BOSS-001-1 | **役割** — 征討エンドボス。ヴァルより上・**クロノス未満** |
| P3-DG-APEX-BOSS-001-2 | **ステ** — HP3900 / ATK248 / DEF236 / ASPD1.45 / 会心0.11 / EXP225 / Gold330 |
| P3-DG-APEX-BOSS-001-3 | **属性** — 攻撃 ice／弱点 fire／耐性 dark+thunder（現行維持。塔 Boss 階の有利炎＝弱点） |
| P3-DG-APEX-BOSS-001-4 | **スキルキット据置** — 激昂／白闇の威圧(fear)／白静寂／地図なき突進／通常爪・薙ぎ |
| P3-DG-APEX-BOSS-001-5 | **白静寂** — 全体即時 **×0.60**（時環共鳴同型。旧×0.75） |
| P3-DG-APEX-BOSS-001-6 | **地図なき突進** — 単体×2.0・CD **6.5**（界壁衝角同型。旧 CD7） |
| P3-DG-APEX-BOSS-001-7 | **フェーズ** — 現行ヴァル同型骨格据置（率・重み・ラベル） |
| P3-DG-APEX-BOSS-001-8 | **Hard/NM** — 専用表なし。`DungeonTierConfig` 流用 |
| P3-DG-APEX-BOSS-001-9 | **DG 帯** — `north_reach` difficulty7／推奨Lv60／敵Lv58（時王霊廟と同・据置） |

### 帯比較（正）

| | ヴァル | **アルバーク** | クロノス |
|---|---|---|---|
| HP | 3600 | **3900** | 4200 |
| ATK | 254 | **248** | 250 |
| DEF | 220 | **236** | 256 |
| ASPD | 1.5 | **1.45** | 1.5 |

> ATK はクロノス未満を優先（`13`）。DEF／HP でヴァル超えの厚みを出す。

---

## 2. 明示的にやらないこと

- 新規技の追加
- クロノス超え
- 専用戦闘ドット必須化
- 征討専用 Hard/NM 数値表

---

## 3. 実装ピン

| 対象 | 内容 |
|---|---|
| `resources/enemies/albark.tres` | ステ更新 |
| `resources/skills/enemy_albark_white_silence.tres` | ×0.60 |
| `resources/skills/enemy_albark_mapless_charge.tres` | CD 6.5 |
| `IconPaths` | `ART_BOSS_Albark`／`ICO_ENM_Turn_Albark`／WhiteSilence／MaplessCharge |
| GUT | ATK／即時全体×0.60 期待値更新 |

---

## 4. 関連

- `128_ApexConquestRedefine`／`131_ApexNamerefuseSet`
- `13_ChronosWaveDragon`／`15_ValgardGolem`
- `38_EliteBossPressure`（Hex fear 据置）
