# 征討2・星炉火口（P3-DG-APEX-FORGE-001）

**Status:** Decision **承認済**（2026-08-30 — オーナー「Goで」／火山テーマ推奨案）  
**親:** `128_ApexConquestRedefine`  
**Boss 肖像:** `ART_BOSS_Forgedormient` 接続済  
**セット装備:** `136_ApexForgeSlagSet`（星炉の滓・承認済）  
**Boss 戦力:** `135_ApexForgeBoss`（降臨帯・承認済）  
**戦闘BG:** Early／Late／Boss 専用3枚接続済（BrokenMarsh 流用解除・2026-08-31）  
**DG ICO／BAN:** 専用接続済（フロストリッジ流用解除・2026-08-31）

---

## 0. 一言

2本目征討＝**星炉の寝主／星炉火口**。サンダーピーク（野火山・燼竜）と分け、**鍛冶王の星炉を火口に沈めた火山**を舞台にする。枠は天望の塔と同型（20F・常設・N/H/NM・無制限）。

---

## 1. 確定

| # | 決定 |
|---|---|
| P3-DG-APEX-FORGE-001-1 | id＝`red_forge_depths`（据置） |
| P3-DG-APEX-FORGE-001-2 | 征討名＝**星炉の寝主**／ステージ＝**星炉火口**／バナー＝**星炉の寝主　征討** |
| P3-DG-APEX-FORGE-001-3 | 進入行＝**星炉火口　{ノーマル／ハード／ナイトメア}** |
| P3-DG-APEX-FORGE-001-4 | Boss＝`forgedormient`（戦力は `135`。肖像は専用ART） |
| P3-DG-APEX-FORGE-001-5 | **20F 固定**・20F＝Boss。放浪無効。日次無制限 |
| P3-DG-APEX-FORGE-001-6 | イベント常設・TabsRow N/H/NM 自由（`is_apex_conquest_playable`） |
| P3-DG-APEX-FORGE-001-7 | 解放＝**天望（`north_reach`）クリア後** |
| P3-DG-APEX-FORGE-001-8 | 有利属性＝**氷**。天候＝炎天寄せ・吹雪0・run固定 |
| P3-DG-APEX-FORGE-001-9 | 雑魚Lv帯＝天望同型 50／54／58（`ApexConquestConfig`） |
| P3-DG-APEX-FORGE-001-10 | 敵プール＝火山／熱／岩の既存種のみ（下表） |
| P3-DG-APEX-FORGE-001-11 | 戦闘BG＝Motif B（火山＋鍛冶廃墟）。**Early F1〜14／Late F15〜19／Boss 部屋専用** |
| P3-DG-APEX-FORGE-001-12 | DG ICO＝`ICO_DG_RedForge`（512）／BAN＝`BAN_DG_RedForge`（1408×232） |

### 階帯

| 帯 | F | 感覚 |
|---|---|---|
| 外輪〜灰原 | 1〜7 | 赤黒礫・灰風 |
| 火口壁 | 8〜14 | 灼熱段丘・噴気 |
| 炉喉 | 15〜19 | 熔岩脈・熱圧 |
| 炉心 | 20 | フォージ・ドルミエント |

### 敵プール（実装ピン）

| 枠 | id |
|---|---|
| `enemy_pool` | `rock_bison`, `iron_horn`, `moss_shell`, `storm_joe`, `crown_raven`, `greios`, `oldrex` |
| `elite_pool` | `greios`, `oldrex`, `rock_bison` |
| Boss | `forgedormient` |
| 出さない | 氷本編種・海沼専任・サンダーピーク専用扱いの別Boss |

### 天候重み（合計100）

晴れ30／霧15／雨5／夜10／**炎天40**／吹雪0

### flavor

> 東の星炉火口。外輪の灰を越え、炉喉を降りると熔けた寝床に、星炉の寝主がいる。

---

### 戦闘BG（実装ピン）

| 帯 | アセット |
|---|---|
| Early（F1〜14） | `assets/dungeon/red_forge_depths/env/BG_Battle_RedForge_Early.png` |
| Late（F15〜19） | `assets/dungeon/red_forge_depths/env/BG_Battle_RedForge.png` |
| Boss（Boss部屋） | `assets/dungeon/red_forge_depths/env/BG_Battle_RedForge_Boss.png` |

配線: `DungeonScene` の `BATTLE_BG_*`／征討は階数で Early・Late、Boss 部屋は `BATTLE_BG_BOSS_MAP`。

---

## 2. 明示的にやらないこと（本 Decision）

- 専用セット装備（→ `136` で実施済）
- Boss ステ再定義（→ `135` で実施済）
- 専用戦闘BG（→ 001-11 で実施済。BrokenMarsh 流用解除）
- 専用BGM／戦闘ドット必須（暫定流用可）
- `thunder_peak` の同時配信
- クロノス／ヴァルを征討へ戻すこと

---

## 3. サンダーピークとの差

| | 星炉火口 | サンダーピーク（残置） |
|---|---|---|
| 正体 | 星炉＝炉にした火山 | 東端の野火山 |
| Boss | 寝主 | 燼竜 |
| 配信 | 本 Decision で常設征討 | 未配信 |

---

## 4. 関連

- `128`／`131`（名拒み）／`132`（アルバーク帯）／`133`（天望環境）
- 地理: `07_Geography` レッドフォージ／サンダーピーク
