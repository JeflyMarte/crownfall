# P2_Task024_MaterialData_Foundation_Completed_v1.0

**Status:** Completed
**Task:** P2-Task024
**Approved By:** DevelopmentHQ
**Version:** v1.0
**ProjectDocs:** v3.5.3

---

## 概要

Phase2-M4 MaterialData 基盤。Event/Elite の material placeholder を data-driven インベントリに置換。

---

## MaterialData スキーマ

id, display_name, description, rarity, icon, category, value, lore_id

---

## 初期素材

| id | display_name |
|---|---|
| relic_shard | 遺跡の欠片 |
| elite_relic_shard | 高品質遺跡の欠片 |
| ancient_bone | 古き骨 |
| cursed_iron | 呪いの鉄 |

---

## インベントリ

- `GameState.material_inventory` — `{ material_id: quantity }`
- `add_material` / `get_material_quantity`
- SaveManager 永続化

---

## 取得経路

| 経路 | material_id |
|---|---|
| Event（朽ちた木箱） | relic_shard |
| Elite ボーナス 15% | elite_relic_shard |

---

## 非実装

- クラフト / 鍛冶 / 強化 / 商人販売 / 素材 UI

---

## Decision

P2-D054〜P2-D056
