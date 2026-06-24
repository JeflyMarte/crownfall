# OD-UI-001 Gap Analysis — 現行 UI vs モック v1.0

**ID:** OD-UI-001
**Type:** Gap Analysis（設計判断なし — 観察のみ）
**Status:** Draft（HQ Decision 待ち）
**作成:** 2026-06-24
**対象:** Phase3-A 完了後のモック寄せ方針検討材料
**モック正:** `docs/art/reference/UI_Reference_001.png` + `UI_Reference_002.png`

> **注記:** 本文書は現状の観察と分類のみ。Phase3-A Closeout 後に HQ が本文書を参照して OD-UI-001 Decision を発行する。Impl は Decision が出るまでここに記載のギャップを埋める実装を行わない。

---

## 背景

Phase3-A では gameplay 変更なしで production アセットを接続することを優先した（P3-D001）。
その結果、以下の現状になっている:

- `production_theme.tres` 適用済み（Bronze ボーダー・Bone White フォント・暗背景）
- `UI_BG_Dark.png` 全画面背景適用済み
- 装備・鑑定アイコン接続済み
- 敵/ボス AnimatedSprite2D 接続済み
- **レイアウト構造はすべて MVP の VBoxContainer テキストスタック**

モックと現行実装の間には視覚的なギャップが存在する。

---

## ギャップ分類

### カテゴリ A — テーマ・カラー（Phase3-A 対応済み）

| 項目 | モック | 現行 | 状態 |
|---|---|---|---|
| ボタンスタイル | Bronze ボーダー・暗背景 | production_theme.tres で再現 | ✅ 解消 |
| 背景色 | 暗い石造り系 | UI_BG_Dark.png（全画面） | ✅ 解消 |
| フォントカラー | Bone White `#d4cbb8` | production_theme.tres 設定済み | ✅ 解消 |
| パネルスタイル | 9-slice Bronze ボーダー | StyleBoxTexture 適用済み | ✅ 解消 |

### カテゴリ B — アイコン表示（Phase3-A 対応済み）

| 項目 | モック | 現行 | 状態 |
|---|---|---|---|
| 装備アイコン | 32×32 テクスチャ横並び | IconPaths 経由で表示 | ✅ 解消 |
| 未鑑定アイコン | `ICO_*_Unidentified` | AppraisalScene 対応済み | ✅ 解消 |
| 素材アイコン一部 | ICO_MAT_* 全点 | batch2 は RelicShard のみ | ⏳ Batch 7 待ち |

### カテゴリ C — タイポグラフィ（未対応）

| 項目 | モック | 現行 | ギャップ規模 |
|---|---|---|---|
| フォント種 | Bitmap / ピクセルフォント（推定） | Godot デフォルトフォント | 中 |
| フォントサイズ | 画面サイズ相応（推定 14-16px） | システムデフォルト | 中 |
| 日本語対応 | 対応必要 | システムフォントで動作中 | 低（動作に支障なし） |

> **P3-D005 決定:** Phase3-A 開始時はシステムフォント。Bitmap Font 導入は Batch 2 承認後に検討。

### カテゴリ D — レイアウト・構造（Phase3-A 未着手）

| 項目 | 推定モック仕様 | 現行実装 | ギャップ規模 |
|---|---|---|---|
| DungeonScene 全体配置 | 敵スプライトが画面中央・大きく表示、ステータス欄が下部 | 縦一列 VBoxContainer（上から情報・ログ・ボタン） | 大 |
| 部屋アート表示 | タイル背景が画面全体または大型エリア | HBoxContainer 内に 64×64 + 32×32 の小型テクスチャ | 中 |
| 戦闘ログ | スクロール可能な専用ウィンドウ（推定） | Label 1 行更新 | 中 |
| 敵スプライト位置 | 中央・大きい（scale 3× でも 96px 相当） | AnimatedSprite2D position=(640,80) — 画面上部 | 中 |
| HPバー | グラフィカルなゲージ表示（推定） | テキスト `HP: 42/100` | 大 |
| ボタン配置 | 画面下部に固定（推定） | VBoxContainer 末尾に自然配置 | 小〜中 |

### カテゴリ E — 演出・フィードバック（Phase3-A 一部）

| 項目 | モック | 現行 | 状態 |
|---|---|---|---|
| 敵 Idle アニメーション | あり | 接続済み | ✅ 解消 |
| 敵 Death アニメーション | あり | 接続済み | ✅ 解消 |
| Hit VFX | あり | 未接続（Batch 6 待ち） | ⏳ P3-A-006 |
| Heal VFX | あり | 未接続（Batch 6 待ち） | ⏳ P3-A-006 |
| 冒険者スプライト | あり | 未接続（Batch 7 待ち） | ⏳ P3-A-008 |

---

## ギャップ優先度（HQ 判断向け）

| 優先 | カテゴリ | 必要作業 | フェーズ案 |
|---|---|---|---|
| **高** | E（VFX） | P3-A-006 — Batch 6 次第 | Phase3-A |
| **高** | E（CHR） | P3-A-008 — Batch 7 次第 | Phase3-A |
| **中** | D（HPバー） | グラフィカルゲージ実装 | Phase3-A Closeout 後 or Phase4 |
| **中** | D（DungeonScene レイアウト） | VBox → アンカー配置リファクタ | Phase3-A Closeout 後 |
| **中** | D（部屋アート） | RoomArt エリア拡大 | Phase3-A Closeout 後 |
| **低** | C（フォント） | Bitmap Font 導入（P3-D005 継続） | Phase4 Polish |
| **低** | D（戦闘ログ） | ScrollContainer + 複数行ログ | Phase3-B or Phase4 |

---

## HQ への Decision 依頼

Phase3-A Closeout（EC-1〜7 PASS）後、以下のいずれかを選択:

| 選択肢 | 内容 | リスク |
|---|---|---|
| A — MVP レイアウト維持 | Phase3-A 完了後もレイアウトは変更しない。Phase4 Polish で全面リデザイン | 長期間モックと乖離 |
| B — 段階的寄せ | EC-7 後に D 項目を 1〜2 個ずつ修正 Task 化して対応 | Phase3-B 日程に影響 |
| C — Phase3-A 内で大改修 | DungeonScene レイアウトを大幅再設計（HP ゲージ / ログ / 配置） | 工期大・gameplay 変更なしでは難しい |

**推奨:** 選択肢 B — Closeout 後に優先度高から順に Task 化

---

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-06-24 | 初版作成（P3-Prep-006） |
