# P2_Task015_Merchant_Room_Completed_v1.0

**Status:** Completed
**Task:** P2-Task015
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.4.1

---

## 概要

Phase2-M3 Special Room として Merchant Room を SSOT 確定した。
Branch Route 経由で出現し、永続 Gold を消費して支援報酬（防具・装飾品・回復）を購入する。

**武器は販売しない**（P2-D020）。

---

## 仕様

### 出現条件

- `RoomType.MERCHANT`
- Branch Route: SAFE_POOL / UNKNOWN_POOL からランダム選択
- `DungeonData.branch_enabled = true` が必要

### 商品カタログ

| type | label | price | 効果 |
|---|---|---|---|
| armor | 革鎧 | 40G | leather_armor Instance → armor_inventory |
| accessory | 銀の指輪 | 60G | silver_ring Instance → accessory_inventory |
| heal | 回復薬 | 35G | 生存メンバー +15 HP |

入室時にカタログを shuffle し **2 品**を提示。

### 購入ルール

- 支払い: `GameState.gold`（永続 Gold）
- 同一商品は 1 回のみ（`purchased` フラグ）
- Gold 不足時は購入不可
- 購入後も「立ち去る」まで部屋内

### UI

- `MerchantContainer`: 所持 Gold・2 商品行・立ち去るボタン
- Merchant 中は Branch / 次の部屋ボタン非表示

---

## 実装変更（P2-Task015）

- `MERCHANT_CATALOG` から **iron_sword（武器）を削除**
- **回復薬**（heal +15 HP）をカタログに追加
- `buy_merchant_item`: heal 型対応（Gold 減算のみ）
- `DungeonScene._apply_merchant_purchase_effect`: 回復薬購入時 `heal_party`

---

## 非実装 / 将来

- **Materials（素材）** — MaterialData 未定義
- Merchant 在庫のセーブ跨ぎ永続管理
- 拠点商人（BaseScene）

---

## 関連 Decision

- P2-D020: 武器非販売
- P2-D021: 永続 Gold 支払い
- P2-D022: SAFE/UNKNOWN Pool 出現
- P2-D023: 2 品ランダム・1 回限り購入

---

## 参照

- `docs/specs/game/05_ダンジョン.md` — MERCHANT Room 節
- `docs/specs/game/07_武器_装備.md` — Dungeon Merchant 節
- `scripts/dungeon/DungeonController.gd` — MERCHANT_CATALOG
- `scripts/dungeon/DungeonScene.gd` — Merchant UI
