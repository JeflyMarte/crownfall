# 10_UI・UX

## 主要画面

- 拠点
- ダンジョン探索
- 装備
- 鑑定
- ダンジョン選択
- リザルト
- 図鑑
- 探索ログ

## ダンジョン画面

表示要素

- ミニマップ
- 発見度
- 所持品数
- パーティHP
- ~~方針ボタン~~ → **Backlog**（P3-D024a Phase 2 — Alpha は準備専用）
- 探索ログ
- 敵・宝箱・イベント

### 方針ボタン（Backlog — P3-D024a Phase 2）

旧案: 探索 / 戦闘 / 収集 / 帰還 → 最小 2〜3 種（集中 / 安定 / 撤退）に再設計予定。`04_ゲームループ.md` 参照。

## 拠点施設

- 酒場
- 鑑定所
- 鍛冶場
- 書庫
- 地図室

MVPでは地図室・装備・鑑定のみ優先。

## 図鑑（Codex）

- BaseScene「図鑑」→ CodexScene
- カテゴリタブ: Enemy / Dungeon / Material / Weapon / History / **Guide**
- 一覧 + 詳細（Entry ID / Name / Status / Category / Overview / Related）
- History: Era + Related（History Bible 由来）
- Dungeon: Location + Theme + Related History（Dungeon Bible 由来）
- データ取得: CatalogHelper のみ
- 未発見: ID・名前・Overview `???`、Related 非表示
- **P3-D024i:** Codex Guide タブ — `COMBAT-G001` 属性の基礎 / `COMBAT-G002` 状態異常の基礎（P3-CX-001）

## UI方針

- スマホ向けに情報量を抑える
- 重要な判断ボタンは常時表示
- 鑑定演出を強くする
- レジェンド獲得時は画面停止演出

**状態ラベル折り返し（P3-UI2-002）:** `LabelStatusEnemy` / `LabelStatusParty` に `autowrap_mode=WORD_ARBITRARY` を設定。パーティ状態は1人1行（`\n` 区切り）で 720×1280 でも見切れない。

## ダンジョン戦闘 UI（Phase UI-2 実装済み）

| 機能 | Task | 実装概要 |
|---|---|---|
| 縦長固定ビューポート | P3-UI2-003 | 720×1280 固定（`project.godot`: viewport_width=720 / viewport_height=1280 / stretch mode=canvas_items / aspect=expand） |
| 頭上 HP バー | P3-UI2-005 | `HpBarChr0〜2` / `HpBarEnemy` が対応スプライトの `position.x` に追従 |
| 浮動ダメージ数字 | P3-UI2-004 | `_spawn_damage_number(text, pos, color, scale)` — Label Tween でフェードアップ。クリティカル scale=1.25、DoT 橙・赤橙、スキル白 |
| バトルログ Panel | P3-UI2-006 | `BattleLogPanel`（PanelContainer）が `BattleLogScroll` をラップ。`production_theme` の `PanelContainer/styles/panel = SB_Panel`（UI_Frame_Panel_Base 9-slice）が明示定義。`BattleLogScroll` の `custom_minimum_size` 高さ 200。**戦闘中のみ表示**（P3-UI2-012） |
| ナレーション Panel | P3-UI2-012 | `NarrativePanel`（PanelContainer + `LabelNarrative`）。非戦闘時のみ表示。宝箱・回復・商人・イベント・撃破報酬等を `_set_narrative()` で表示。font 18 + 黒 outline。高さ 200 |
| ヘッダー部屋表示 | P3-UI2-011 | `LabelRoom` — `B1 — 部屋 n/m [部屋種別]`。エリート/ボスは色分け |
| 状態テキストバッジ | P3-UI2-001/002 | ~~`LabelStatusEnemy` / `LabelStatusParty`~~ → **P3-UI2-013** で頭上アイコンに置換（戦闘中） |
| 状態異常アイコン | P3-UI2-013 | スプライト頭上（HP バー上）に 26px 色分けバッジ。6 種: 毒/冷/感/炎/呪/麻。スタック数・残 tick は tooltip。`STATUS_ICON_DEF` + `get_active_status_list()` |
| エリート/ボス戦闘枠 | P3-UI2-014 | `BattlefieldArea/CombatTierFrame` — ELITE/MID_BOSS/BOSS 戦闘中のみ。色付きボーダー + 上部ラベル（金/赤） |
| Codex 初見トースト | P3-UI2-015 | `DiscoveryToastLayer` — 新規発見時に上部フェード表示。`DiscoveryRegistry.get_display_label()` |
| Build チップ | P3-UI2-016 | `BuildTagHelper` — 拠点 `BuildChipRow` / 装備画面 `BuildChipRow`。Attack / Critical / Survival / Exploration |

**スプライト配置（720×1280 基準 — P3-UI2-008 scale 4〜5 / 遠近 y 配置）:**

| ノード | position | scale | 用途 |
|---|---|---|---|
| ChrSprite0 | (110, 700) | 5 | 冒険者 0（手前） |
| ChrSprite1 | (250, 660) | 5 | 冒険者 1 |
| ChrSprite2 | (390, 620) | 5 | 冒険者 2（奥） |
| EnemySprite | (540, 480) | 4 | 通常敵 |
| BossSprite | (500, 420) | 4 | ボス |
| HitVfxSprite | (540, 480) | 4 | 被弾エフェクト（敵） |
| HealVfxSprite | (250, 660) | 5 | 回復エフェクト（パーティ中央） |

**戦闘 BG:** `BATTLE_BG_MAP` — royal_ruins は v3（P3-UI2-BG-001）。graveyard は v2。

## ループ UX（P3-D024f）

- 一括鑑定（P3-APPR-001 — 実装済み）
- 装備比較 1 行（P3-EQ-CMP-001/002/003 — 実装済み）: 武器 `[ATK ±N | SPD ±N | CRT ±N%]` / 防具 `[DEF ±N | HP ±N]` / 装飾品 `[HP / ATK / DEF / CRT / LCK ±N]`
