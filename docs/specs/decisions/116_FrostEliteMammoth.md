# フロストリッジ：トリケラオミット／マンモス・エリート化（P3-BAL-FR-ELITE-MAMMOTH-001）

**日付:** 2026-08-09  
**状態:** 承認（オーナー＝極冠トリケラオミット・マンモスをエリート・氷晶の蹂躙弱体）

## 要旨

`polar_tricera` をフロスト系プールから外し、硬殻タンク役として `glacier_warden`（氷晶マンモス）をエリート枠へ昇格する。防御無視全体は残しつつ倍率を抑える。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-BAL-FR-ELITE-MAMMOTH-001-1 | **`polar_tricera` を `frostridge`／`abyss_frostridge`／`north_reach` の elite_pool から除外**（図鑑もプール外で非掲載） | オーナー・オミット |
| P3-BAL-FR-ELITE-MAMMOTH-001-2 | **`glacier_warden` を elite**（`enemy_type=1`・雑魚プールから除外・elite_pool へ）。ステをエリート帯へ | 硬殻タンクをエリート役に |
| P3-BAL-FR-ELITE-MAMMOTH-001-3 | **氷晶の蹂躙** — ×1.65→**×1.40**／CD12→**14**／冷却35%→**25%**。`ignore_defense` 据置 | 少し弱体 |
| P3-BAL-FR-ELITE-MAMMOTH-001-4 | 核スキル重み3.5・使用率0.5（他エリートと同型） | 出番確保 |

## 上書き

- `99_EliteSkillIdentity` のトリケラ復帰
- `113_MammothIgnoreDefAoE` の威力／CD／冷却
