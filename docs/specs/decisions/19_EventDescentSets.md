# 降臨セット装備（P3-DG-EVENT-SET-001）

**Status:** SSOT（Decision 承認済）  
**Approved:** 2026-07-26（オーナー GO）  
**Supersedes:** `18_EventDescentRewards.md` の単品＋レリック案（単品・専用レリックは廃止／本セットへ置換）

## 概要

時間帯降臨2本に **セット装備（表示レアリティ「エンシェントレア」／`Enums.Rarity.SET`）** を置く。  
武器＋防具＋装飾の **3部位装備時のみ** セット加護が発動。既存パッシブ／レリック枠と **重複可**（別枠自動付与・パッシブタブを消費しない）。

## レアリティ

| Enum | 値 | 表示 |
|---|---|---|
| `Enums.Rarity.SET` | 5（MYTHIC の次） | **エンシェントレア** |

通常ドロップ抽選・鍛冶・放浪★プールには載せない。

## セット品目

### クロノス「時環の刻」（`chronos_toki`）— DG `chronos_mausoleum`

| 部位 | id | 表示名 |
|---|---|---|
| 剣 | `chronos_toki_sword` | 時環の刻剣 |
| 双剣 | `chronos_toki_dual` | 時環の刻双剣 |
| 杖 | `chronos_toki_staff` | 時環の刻杖 |
| 弓 | `chronos_toki_bow` | 時環の刻弓 |
| 防具 | `chronos_toki_armor` | 時環の刻鎧 |
| 装飾 | `chronos_toki_orb` | 時環の刻宝珠 |

### ヴァルガード「アンティーク」（`valgard_antique`）— DG `valgard_boundary`

| 部位 | id | 表示名 |
|---|---|---|
| 剣 | `valgard_antique_blade` | アンティークブレイド |
| 双剣 | `valgard_antique_dual` | アンティークデュアル |
| 杖 | `valgard_antique_rod` | アンティークロッド |
| 弓 | `valgard_antique_arrow` | アンティークアロー |
| 防具 | `valgard_antique_armor` | アンティークアーマー |
| 装飾 | `valgard_antique_amulet` | アンティークアミュレット |

## セット加護（3部位のみ）

| セット | 加護名 | 効果 |
|---|---|---|
| 時環の刻 | **クロノスの加護** | 行動速度 +15%／スキルCD ×0.85／詠唱時間 ×0.85 |
| アンティーク | **ヴァルガードの加護** | HP・与ダメ・被ダメ軽減として ATK/DEF 相当 **各 +12%**（HP×1.12／outgoing×1.12／incoming×0.89） |

### パッシブタブ表示

- **3部位そろったときだけ** 装備画面パッシブタブに加護名／説明を情報カードで出す（`EquipmentSetBonuses.passive_ui_def_for_member`）
- 1〜2部位では出さない。パッシブ装備枠は消費しない（既存方針どおり）
- 装備詳細の「セット加護（3部位）」カタログ文言はアイテム閲覧用として別扱い

## 入手

| | 内容 |
|---|---|
| **初回（ティア別）** | エンシェント装備 **1個確定**（未所持部位優先。武器候補のみのときは編成向き優先） |
| **再周回** | **40%** で1個（同上の抽選。出ても最大1個） |
| 廃止 | 旧・初回3部位一括／旧専用単品・`relic_chronos_fragment`／`relic_valgard_gear` |

> **上書き（2026-08-11 — P3-BAL-DESCENT-SET-DROP-ONE-001）** — 一度に複数出さない。初回も最大1個。再周回の40%は据置。

## スコープ外

- 2部位ボーナス
- 曜日イベントセット
- セット専用新アイコンアート（仮流用可）
