# CurrentState.md — Crownfall Project Dashboard

---

## Last Update

2026-06-27（**世界観 cutover** — lore SSOT を `docs/specs/world/`（12 文書）へ移行 / P3-D041b。旧 `game/29`〜`37` 削除、`33_EcologyCodex` のみ存置）

---

## Project Version

ProjectDocs **v3.6.0**

---

## Current Phase

**Phase3-B — Content Expansion**（**着手** — P3-D025。3-A 全画面 polish は後 Phase）

---

## Current Milestone

**Phase3-B-M2** — **完了**（P3-D023）— 属性5種 + 状態6種

---

## Active Tasks

| ID | 内容 | 状態 |
|---|---|---|
| — | P3-D024 spec 同期 | **完了** |
| P3-TH-001 | 簡易ヘイト | **完了** |
| P3-HW-001 | 聖属性武器 | **完了** |
| P3-D024b | 簡易ヘイト | **完了**（P3-TH-001） |
| P3-D024j | 聖属性武器 | **完了**（P3-HW-001） |
| P3-D024i | 属性 vs 状態チュートリアル | **完了**（P3-CX-001） |
| P3-HW-002 | slash_attack bleed 削除 | **完了** |
| P3-UI2-001 | 戦闘状態テキスト表示 | **完了** |
| P3-APPR-001 | 一括鑑定 | **完了** |
| P3-INIT-001 | イニシアチブ Phase 1 | **完了** |
| P3-EQ-CMP-001 | 装備比較 1 行 | **完了** |
| P3-UI2-002 | 状態ラベル折り返し | **完了** |
| P3-INIT-002 | イニシアチブ Phase 2 | **完了** |
| P3-JOB-001 | preferred_weapon +5% ATK | **完了** |
| P3-EQ-CMP-002 | 防具比較 1 行 | **完了** |
| P3-D024d-001 | 敵 curse エリート限定 | **完了** |
| P3-AFFIX-SPD-001 | Affix 速度 → イニシアチブ | **完了** |
| P3-D024c-001 | stagger_power リネーム | **完了** |
| P3-UI2-003 | viewport 縦長固定 720×1280 | **完了** |
| P3-UI2-004 | 浮動ダメージ数字 | **完了** |
| P3-EQ-CMP-003 | 装飾品比較 1 行 | **完了** |
| P3-UI2-005 | HP バー座標のスプライト追従 | **完了** |
| P3-SPEC-001 | 戦闘 AI spec イニシアチブ同期 | **完了** |
| P3-UI2-006 | バトルログ枠 art / スプライト位置 | **完了** |
| P3-SPEC-002 | UI spec / CODEMAP 同期 | **完了** |
| P3-THEME-001 | Panel 9-slice margin 調整 | **完了** |
| P3-ALPHA-001 | Alpha 5 分周回チェックリスト | **完了** |
| P3-UI2-007 | 浮動ダメージ座標（CanvasLayer） | **完了** |
| P3-UI2-009 | 宝箱中央配置 / 下部テキスト可読性 | **完了** |
| P3-UI2-008 | 戦闘スプライト scale / 遠近配置 | **完了** |
| P3-UI2-BG-001 | 王都跡戦闘 BG v3 差し替え | **完了** |
| P3-ALPHA-002 | 旧セーブ job_id マイグレーション | **完了** |
| P3-UI2-011 | ヘッダー B1 / 部屋表示 | **完了** |
| P3-UI2-012 | バトルログ戦闘限定 / ナレーション Panel | **完了** |
| P3-UI2-013 | 状態異常アイコン（頭上バッジ） | **完了** |
| P3-UI2-014 | エリート/ボス戦闘枠 | **完了** |
| P3-UI2-015 | Codex 初見トースト | **完了** |
| P3-UI2-016 | Build チップ（拠点・装備） | **完了** |
| P3-SPEC-004 | UI-2+ spec / CODEMAP 同期 | **完了** |
| P3-B-001 | 白骸墓地 完走検証・バランス初調整 | **完了**（オーナー GO） |
| P3-B-002 | 王都跡専用イベント 3 件 | **完了**（オーナー GO） |
| P3-B-003 | 地下工廠 Proposal | **完了**（オーナー GO） |
| P3-B-004 | 地下工廠プレイアブル追加 | **完了**（オーナー GO） |
| P3-B-005 | 地下工廠バランス初調整 | **完了**（オーナー GO） |
| P3-D026〜033 | 世界観刷新 Postwar Ecology（文書反映） | **完了**（Bible 29〜36 新設・既存 spec 同期） |
| OD-UI-003 | レベル制 | HQ 保留 |

### 世界観刷新（Postwar Ecology — 2026-06-26）

世界観を「戦後生態系」へ刷新。世界観 SSOT は **`docs/specs/world/`**（旧 `game/29`〜`37` から移行・統合済み / 2026-06-27 cutover, P3-D041b）。**コード未変更**（既存敵・DG・ジョブの実装移行は将来 Task）。

| world/ 文書 | 内容 |
|---|---|
| 00_Overview | 世界観マスター・三本柱・読み順 |
| 01_History | 歴史・HE エントリ（Codex 解析対象） |
| 02_Relics | 遺産・伝説武器・中核の謎 |
| 03_Ecology | 戦後生態系 総論 |
| 04_Classification | Class I〜VII |
| 05_Biomes | Biome |
| 06_MonsterNaming | 命名ガイド |
| 07_Geography | エルド大陸 |
| 08_SeekersGuild | 探索者ギルド |
| 09_Jobs | ジョブ（世界観面。数値は game/06） |
| 10_LoreDelivery | ロア提示ガイド |
| 11_Glossary | 用語レジストリ |

> 図鑑システム仕様は `game/33_EcologyCodex.md`（存置）。

**実装移行 整合課題:** 既存敵の生物化 / DG↔Biome 再マッピング / ジョブ 3→5 / Codex 拡張 → 移行 Proposal 待ち。

---

## Known Issues

| 課題 | 詳細 |
|---|---|
| viewport 比率 | **720×1280** ✅。スプライト 720 幅内 ✅（P3-UI2-006） |
| 状態 UI | 頭上アイコン ✅（013）。Codex トースト ✅（015）。Build チップ ✅（016）。PA art は Phase 3-A |
| 聖属性武器 | ~~未実装~~ → **sanctified_dagger**（P3-HW-001） |
| タンク fantasy | ~~ランダム被弾~~ → 簡易ヘイト（P3-TH-001） |
| ラン中介入 | Alpha=準備専用（P3-D024a）。方針切替は Phase 2 |
| 助っ人 targeting | 助っ人ソードマンがヘイト優先で狙われ実質無敵タンク化（全滅対象外）。後続で targeting から除外（P3-D036） |
| mourngate アセット依存 | 戦闘BG・宝箱・出口ゲートが退役済 `graveyard`/`royal_ruins` の PNG を流用。敵 `.tres` は `crystal_hedgehog` 以外プレースホルダ（旧シート参照）。オーナー作画＋推進チャットで差し替え予定（ビルドは現状 PASS） |

---

## Design References

| 文書 | 用途 |
|---|---|
| [28_ゲームデザイン点検.md](../specs/game/28_ゲームデザイン点検.md) | **GD 点検 SSOT** — P3-D024 |
| [27_状態異常と属性.md](../specs/game/27_状態異常と属性.md) | 属性/状態 SSOT v1.1 |
| [03_Decision_Log.md](../specs/core/03_Decision_Log.md) | P3-D016〜024 |
| [05_Backlog.md](../specs/core/05_Backlog.md) | P3-D024 / Initiative |
