# Phase2-M8 Merchant Material Shop Foundation v1.0

Status: Completed
Approved By: DevelopmentHQ
Version: v1.0
Date: 2026-06-22
Task Type: Parallel Task（M8 準備）
Decision Basis: P2-D144（Merchant Materials 価格帯承認）

---

## Purpose

Phase2-M8 Task043（Economy Integration / Merchant 拡張）の先行基盤として、
MaterialShopData Resource と DataRegistry API を実装した。
Merchant UI / Gold 減算 / Material 付与との接続はなし。

---

## Created Script

- scripts/data/MaterialShopData.gd（material_id / price / stock / unlock_condition）

---

## Created Resources

resources/material_shop/（新規ディレクトリ）
- relic_shard.tres: price=20G, stock=-1（無限）
- ancient_bone.tres: price=20G, stock=-1（無限）

---

## Updated Code

- scripts/core/Constants.gd: RESOURCE_MATERIAL_SHOP_PATH 追加
- scripts/autoload/DataRegistry.gd: get_material_shop_items() / get_material_price(material_id) 追加

---

## API Spec

get_material_shop_items() -> Array
  - resources/material_shop/ を DirAccess で走査
  - 全 MaterialShopData を Array で返す

get_material_price(material_id: String) -> int
  - {material_id}.tres を load して price を返す
  - 未定義 id → -1 返却（クラッシュなし）

---

## Updated Docs

- docs/specs/implementation/CODEMAP.md: MaterialShopData.gd / material_shop/ 追記
- docs/specs/implementation/03_Resource設計.md: MaterialShopData スキーマ・API 仕様追記
- docs/specs/implementation/11_TASK_INDEX.md: 本 Task 登録

---

## Validation

- relic_shard → get_material_price("relic_shard") = 20 ✓
- ancient_bone → get_material_price("ancient_bone") = 20 ✓
- 不明 id → get_material_price("unknown") = -1（ResourceLoader.exists 判定）✓
- クラッシュなし（null guard / exists check 実装済み）
- MERCHANT_CATALOG / DungeonController / DungeonScene 変更なし
- Gold 減算 / Material 付与 / Save 変更なし

---

## Next

Task043（Economy Integration）で以下を実装する。
- Merchant UI に Material 商品行を追加
- buy_merchant_item が "material" type を処理
- DataRegistry.get_material_shop_items() から商品生成
- DataRegistry.get_material_price() で価格参照
