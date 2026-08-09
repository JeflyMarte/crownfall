# 分解で Gold 入手（P3-BAL-DISMANTLE-GOLD-001）

**ID:** P3-BAL-DISMANTLE-GOLD-001  
**日付:** 2026-08-09  
**状態:** 承認（オーナー依頼＝GO）  
**上書き:** `P3-FORGE-003-9` の「Gold 返却据置」

## 要旨

分解の出口にスクラップ Gold を足す。素材返却表・80%キャップ・一括対象は据置。

## 確定

| レア | ベース Gold |
|---|---:|
| ◇（N／SET） | 25 |
| ◆ | 40 |
| ✦ | 80 |
| ★／ミシック | 200 |

- 炉研ぎボーナス: `enhance_level × 5` Gold（素材の共通+1 とは独立）
- `equip_level` による差は付けない（据置）
- プレビュー／確認文／結果ポップに Gold を含める（一括も合算）

## SSOT

- `EquipmentEnhancer.DISMANTLE_GOLD_BY_RARITY`／`DISMANTLE_GOLD_PER_ENHANCE`
- `dismantle_preview`／`dismantle_item`／`dismantle_bulk_*` の `gold` キー
