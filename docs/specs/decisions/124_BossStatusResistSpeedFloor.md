# 全ボス状態異常耐性＋速度下限（P3-BAL-BOSS-STATUS-SPEED-001）

**日付:** 2026-08-10  
**状態:** 承認（オーナー指示）

## 要旨

本編ボス全体に状態異常耐性を揃え、鈍足ボスの速度下限を 1.0 にする。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-BAL-BOSS-STATUS-SPEED-001-1 | **全 BOSS**（`enemy_type=BOSS`）に `incoming_status_chance_mult=0.55` | 付与成功率減衰を共通化（エルディオンと同値） |
| P3-BAL-BOSS-STATUS-SPEED-001-2 | **攻撃速度下限 1.0** — 未満は 1.0 へ引き上げ。既に 1.0 超は据置 | 遅すぎるボスの是正 |
| P3-BAL-BOSS-STATUS-SPEED-001-3 | **SSOT** — 本 Decision | — |

## 非スコープ

- エリート／雑魚への横展開
- エルディオン個別の ATK／技倍率再調整
- CC 刻み耐性（`97_BossCcResist`）の変更
