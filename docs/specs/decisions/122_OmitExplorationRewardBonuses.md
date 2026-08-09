# 探索報酬ボーナス・オミット（P3-BAL-OMIT-EXPLORE-REWARD-001）

**日付:** 2026-08-09  
**状態:** 承認（オーナー＝探索ボーナスはオミット）

## 要旨

ロール連動の探索スキルのうち、報酬系4種をプレイから外す。罠解除と罠ダメージ計算は残す。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-BAL-OMIT-EXPLORE-REWARD-001-1 | **採取／採掘／鍵開け／解読をオミット** | 本体報酬と二重・額が陳腐（例: 解読＋20） |
| P3-BAL-OMIT-EXPLORE-REWARD-001-2 | **罠解除は残す** | 安全機能（ボーナスではない） |
| P3-BAL-OMIT-EXPLORE-REWARD-001-3 | **SSOT** — `ExplorationSkills.REWARD_BONUSES_ENABLED=false` | 再有効化はフラグのみ |
| P3-BAL-OMIT-EXPLORE-REWARD-001-4 | **探索方針（P3-D098）は非スコープ** | 別系統 |

## 上書き

- `P3-D117` の報酬4種のプレイ効果（定義・罠 API は残置）
