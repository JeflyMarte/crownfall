# 征討天候・雑魚Lv帯（P3-DG-APEX-ENV-001）

**Status:** Decision **承認済**（2026-08-30 — オーナー「推奨でGo」）  
**親:** `128_ApexConquestRedefine`  
**対象:** パイロット `north_reach`（天望の塔）

---

## 0. 一言

案C雰囲気（風・薄雲・吹雪なし）を天候抽選に接続し、20F 雑魚の敵Lvを **階帯で段階上昇**させる。Boss は `132` 据置。日次制限は無制限（`128` 001-7）。

---

## 1. 天候（案 W-A）

| # | 決定 |
|---|---|
| P3-DG-APEX-ENV-001-1 | **run 開始時1回抽選・周回中固定**（本編同型。深層の10F再抽選はしない） |
| P3-DG-APEX-ENV-001-2 | **征討専用重み** — 晴れ55／霧25／雨10／夜10／炎天0／**吹雪0**（合計100） |
| P3-DG-APEX-ENV-001-3 | フロストリッジ alias を **外す**（吹雪偏りを解消） |

> 天候IDに「風」は無い。薄雲感は **晴れ＋霧** で表現。

---

## 2. 雑魚敵Lv（N）

| 帯 | F | 敵Lv（N） |
|---|---|---|
| 塔門〜下層 | 1〜7 | **50** |
| 吹き抜け | 8〜14 | **54** |
| 雲上 | 15〜19 | **58** |
| 塔頂 | 20 | Boss（`albark`／`132`）。雑魚帯Lvは使わない |

| # | 決定 |
|---|---|
| P3-DG-APEX-ENV-001-4 | 上表を正。Hard/NM は `DungeonTierConfig.enemy_level_bonus` のみ加算 |
| P3-DG-APEX-ENV-001-5 | プール構成・帯分けフレーバーは `128` §3.1 据置（本 Decision は Lv のみ） |
| P3-DG-APEX-ENV-001-6 | `north_reach.enemy_level` リソース値は参照しない（階帯表が正） |

---

## 3. 明示的にやらないこと

- 専用「風」天候IDの新設
- 周回中の天候再抽選
- 帯ごとのプール差し替え必須化（任意の後続 polish）
- Boss 数値の再変更（`132`）

---

## 4. 実装ピン

| 対象 | 内容 |
|---|---|
| `CombatWeather.gd` | `_DUNGEON_WEIGHTS["north_reach"]`／alias 解除 |
| `ApexConquestConfig.gd`（新規） | `enemy_level_for_floor` |
| `DungeonController.get_enemy_level` | 征討時は階帯表＋ティア |
| GUT | 重み・階Lv |

---

## 5. 関連

- `128` 案C雰囲気／日次無制限
- `132_ApexAlbarkBoss`
- `25_AbyssFloorLevelCurve`（深層絶対表とは別。征討は固定長帯のみ）
