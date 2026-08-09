# 日課報酬バラエティ＋バナーアイコン（P3-BAL-DAILY-REWARD-VARIETY-001）

**ID:** P3-BAL-DAILY-REWARD-VARIETY-001  
**日付:** 2026-08-09  
**状態:** 承認（オーナー GO）  
**上書き:** `P3-BAL-DAILY-TREASURE-GOLD-001` の日課報酬数値（宝箱 Gold は対象外）

## 要旨

日課が Gold 偏りで単調。報酬を最大2種に抑え、レーン分散し、ランダム装備（N〜E）を入れる。拠点バナーはテキストではなく全報酬をアイコン表示する。

## 確定

### 1. 報酬ルール

- 1ミッションあたり報酬 **最大2種類**
- `daily_gacha_pull` はプール除外のまま（数値触らない）
- 袋満杯時の装備は **同価値 Gold フォールバック**（claim は成功）

### 2. 割当

| ミッション | 報酬 |
|---|---|
| クリア1 | Gold 120 ＋ 装備1 |
| 20体撃破 | 魔晶石 20 ＋ 基礎鉱×8 |
| エリート1 | 蒼古の骨鉱×3 ＋ Gold 80 |
| ボス1 | 魔晶石 25 ＋ 装備1（E寄り） |
| 生産1 | 魔晶石 40 ＋ 基礎鉱×5 |
| 炉研ぎ1 | 基礎鉱×10 ＋ Gold 60 |
| 錬成1 | 遺跡結晶×3 ＋ Gold 60 |
| 分解1 | 基礎鉱×12（1種） |

### 3. ランダム装備

- カテゴリ: 武／防／飾を均等抽選
- レア上限: **E（`Enums.Rarity.EPIC`）まで**（L／M／SET／封蔵・降臨限定は除外）
- 重み（通常）: N 45 / R 35 / E 20
- 重み（ボス日課）: N 35 / R 35 / E 30
- 鑑定済み。装備 Lv は `EquipmentEnhancer.assign_drop_equip_level`（進行ティア連動）
- フォールバック Gold: N 80 / R 120 / E 180

### 4. UI

拠点デイリー行は Gold／魔晶石／素材／装備（未鑑定枠アイコン）をアイコン＋数量で表示。受取 FX も同様。

## SSOT

- `resources/daily_missions/*.tres`
- `scripts/data/DailyMissionData.gd`
- `scripts/autoload/DailyMissionSystem.gd`
- `scripts/base/BaseScene.gd`（日課行／claim FX）
