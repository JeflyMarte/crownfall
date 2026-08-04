# 宝箱成功時の装備確定（P3-BAL-TREASURE-EQUIP-001）

**Status:** Decision 承認済（2026-08-04 — オーナー案A）  
**上書き:** `P3-BAL-NONCOMBAT-001-3`／`P3-BAL-DAILY-TREASURE-GOLD-001-2` の宝箱装備抽選（装飾35%・武器12%）

---

## 1. 方針

| # | 項目 | 確定 |
|---|---|---|
| 1 | 成功時 | Gold 120 ＋ **装備1点確定** |
| 2 | カテゴリ | 武器／防具／装飾を **均等**（章プール・既存レア重み） |
| 3 | 追加抽選 | **廃止**（旧装飾35%・武器12%は重ねない） |
| 4 | 失敗時 | 据置（半額 Gold・装備なし） |
| 5 | 探索スキル | 鍵開けの装飾ボーナスは据置（確定が装飾以外のときのみ余地あり） |

---

## 2. SSOT

- `DungeonController.generate_treasure_loot()` / `_pick_treasure_equip_category()`
- 表示: `TreasureRoomPresentation`（防具行含む）
