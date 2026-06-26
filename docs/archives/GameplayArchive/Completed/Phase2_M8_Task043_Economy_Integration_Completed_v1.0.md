# Phase2_M8_Task043_Economy_Integration_Completed_v1.0

**Status:** Completed
**Task:** P2-Task043
**Milestone:** Phase2-M8 — Craft & Economy Foundation
**Version:** v1.0
**ProjectDocs:** v3.5.32
**Completed Date:** 2026-06-22

---

## 概要

Dungeon Merchant に MaterialShopData ベースの素材購入を接続。P2-D144 実装。

---

## Scope

| In Scope | Out of Scope |
|---|---|
| Merchant material offers | Weapon 販売 |
| gold → add_material | Blacksmith / Craft 変更 |
| MaterialShopData 価格参照 | Save Format 変更 |
| armor/accessory/heal 維持 | Combat / Dungeon Flow 変更 |

---

## Merchant Material Flow

```
generate_merchant_offers()
  → _build_merchant_catalog()（MERCHANT_CATALOG + MaterialShopData）
  → shuffle → 2 件選択

buy_merchant_item(index)
  → gold >= price ?
  → material: material_id 有効 + get_material_price >= 0 ?
  → gold 減算
  → add_material(material_id, 1)
  → purchased = true
```

---

## UI Display

```
Material: relic_shard 20G
Material: ancient_bone 20G
```

既存商品: `革鎧 — 40G` / `銀の指輪 — 60G` / `回復薬 — 35G`（従来通り）

---

## MVP Prices（P2-D144）

| material_id | price |
|---|---|
| relic_shard | 20G |
| ancient_bone | 20G |

---

## Failure Behavior

| 条件 | 結果 |
|---|---|
| Gold 不足 | buy_merchant_item → false、「Gold不足」 |
| material_id 不正 | 購入不可（catalog 生成時 skip / buy 時 reject） |
| price 取得失敗 | catalog 除外 / 購入 reject |

---

## Files

- `scripts/dungeon/DungeonController.gd`
- `scripts/dungeon/DungeonScene.gd`

---

## Next

**P2-Task044** — Phase2-M8 Closeout
