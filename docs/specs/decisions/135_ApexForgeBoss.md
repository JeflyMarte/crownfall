# 征討 Boss フォージ・ドルミエント — 降臨帯へ寄せ（P3-DG-APEX-FORGE-BOSS-001）

**Status:** Decision **承認済**（2026-08-30 — オーナー「Aで」／`132` 同型）  
**親:** `134_ApexForgeVolcano`／`128_ApexConquestRedefine`  
**帯参照:** `132_ApexAlbarkBoss`（アルバークと同帯）／`15_ValgardGolem`／`14_ChronosDescent`  
**戦闘ICO:** ターン＋スラグ吐息／炉床震動 専用接続済（エルディオン流用解除・2026-08-31）

---

## 0. 一言

征討2 Boss `forgedormient` の **ステ・即時全体倍率を降臨エンドボス帯に再定義**する。キット構成・Hex・フェーズ骨格・炉床震動（詠唱全体）は据置。旧ステ（HP3280／ATK251）をアルバーク同帯へ揃える。

---

## 1. 確定方針

| # | 決定 |
|---|---|
| P3-DG-APEX-FORGE-BOSS-001-1 | **役割** — 征討2エンドボス。ヴァルより上・**クロノス未満**。アルバークと同帯 |
| P3-DG-APEX-FORGE-BOSS-001-2 | **ステ** — HP3900 / ATK248 / DEF236 / ASPD1.45 / 会心0.11 / EXP225 / Gold330 |
| P3-DG-APEX-FORGE-BOSS-001-3 | **属性** — 攻撃 fire／弱点 ice+holy／耐性 fire+dark（現行維持。火口有利氷＝弱点） |
| P3-DG-APEX-FORGE-BOSS-001-4 | **スキルキット据置** — 激昂／炉滓の脆弱(vulnerable)／スラグの吐息／炉床震動／通常炉爪・薙ぎ |
| P3-DG-APEX-FORGE-BOSS-001-5 | **スラグの吐息** — 全体即時 **×0.60**（時環共鳴／白静寂同型。旧×0.75） |
| P3-DG-APEX-FORGE-BOSS-001-6 | **炉床震動** — 全体×2.0・詠唱1.0・CD **9** 据置（単体突進型ではないため CD 変更なし） |
| P3-DG-APEX-FORGE-BOSS-001-7 | **フェーズ** — 現行骨格据置（率・重み・ラベル） |
| P3-DG-APEX-FORGE-BOSS-001-8 | **Hard/NM** — 専用表なし。`DungeonTierConfig` 流用 |
| P3-DG-APEX-FORGE-BOSS-001-9 | **DG 帯** — `red_forge_depths` difficulty7／推奨Lv60／敵Lv58（天望と同・据置） |

### 帯比較（正）

| | ヴァル | **アルバーク／フォージ** | クロノス |
|---|---|---|---|
| HP | 3600 | **3900** | 4200 |
| ATK | 254 | **248** | 250 |
| DEF | 220 | **236** | 256 |
| ASPD | 1.5 | **1.45** | 1.5 |

> 征討 Boss 2体は同帯。差はキット（氷単体突進 vs 炎詠唱全体）と属性。

---

## 2. 明示的にやらないこと

- 新規技の追加・炉床震動の単体化
- クロノス超え
- 専用戦闘ドット必須化
- 星炉セット装備（別 Decision）
- 征討専用 Hard/NM 数値表

---

## 3. 実装ピン

| 対象 | 内容 |
|---|---|
| `resources/enemies/forgedormient.tres` | ステ更新 |
| `resources/skills/enemy_forgedormient_slag_breath.tres` | ×0.60 |
| `IconPaths` | `ICO_ENM_Turn_Forgedormient`／`ICO_SKILL_EnemyForgedormientSlagBreath`／`FurnaceQuake` |
| GUT | ATK／即時全体×0.60 期待値更新 |

---

## 4. 関連

- `134_ApexForgeVolcano`／`132_ApexAlbarkBoss`／`128`
- `13_ChronosWaveDragon`／`15_ValgardGolem`
