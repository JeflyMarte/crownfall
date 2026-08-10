# 全ボス状態異常耐性＋速度（P3-BAL-BOSS-STATUS-SPEED-001）

**日付:** 2026-08-10  
**状態:** 承認（オーナー指示）

## 要旨

本編ボス全体に状態異常耐性を揃え、行動速度を **1.35** に統一する。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-BAL-BOSS-STATUS-SPEED-001-1 | **全 BOSS**（`enemy_type=BOSS`）に `incoming_status_chance_mult=0.55` | 付与成功率減衰を共通化（エルディオンと同値） |
| P3-BAL-BOSS-STATUS-SPEED-001-2 | **攻撃速度 1.35** — 全ボス `attack_speed=1.35`（旧下限1.0から引き上げ） | オーナー指示「ボス全体の速さを1.35」 |
| P3-BAL-BOSS-STATUS-SPEED-001-3 | **SSOT** — 本 Decision | — |

## 非スコープ

- エリート／雑魚への横展開
- エルディオン個別の ATK／技倍率再調整
- CC 刻み耐性（`97_BossCcResist`）の変更
- 人数連動速度係数（`BOSS_PARTY_*`）の変更
