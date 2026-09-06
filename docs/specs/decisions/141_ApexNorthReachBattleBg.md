# 天望の塔・専用戦闘BG（P3-DG-APEX-NORTHREACH-BG-001）

**Status:** Decision **承認済**（2026-09-06 — オーナー「案AでGo」＋開けたステージ）  
**親:** `128_ApexConquestRedefine`  
**参照:** 星炉専用BG同型（Early／Late／Boss）

---

## 1. 確定

| # | 決定 |
|---|---|
| P3-DG-APEX-NR-BG-001-1 | 案A — 塔内から空へ（バナー青空・石塔系） |
| P3-DG-APEX-NR-BG-001-2 | 3枚 — Early／Late／Boss。中央は開けた戦闘床（オブジェクト最小） |
| P3-DG-APEX-NR-BG-001-3 | 帯 — Early **F1–14**／Late **F15–19**／Boss **BOSS部屋** |
| P3-DG-APEX-NR-BG-001-4 | 境界廊・フロスト FinalBoss 流用解除 |
| P3-DG-APEX-NR-BG-001-5 | パス — `assets/dungeon/north_reach/env/BG_Battle_NorthReach{,_Early,_Boss}.png` |

---

## 2. 画の指針

| 枚 | 内容 |
|---|---|
| Early | 下層石回廊。窓から遠景の灯。床は空いた石タイル |
| Late | 雲上露台。空と雲海。手すりは奥のみ |
| Boss | 塔頂円壇。白闇の余白。中央クリア |

やらない: 吹雪メイン、床上の置物・柱の密集、星炉溶岩パレット。

---

## 3. 実装ピン

- `DungeonScene` — `BATTLE_BG_*` ＋ `BATTLE_BG_BOSS_MAP`＋征討フロア帯切替
- GUT — `test_north_reach_dedicated_battle_bgs`
