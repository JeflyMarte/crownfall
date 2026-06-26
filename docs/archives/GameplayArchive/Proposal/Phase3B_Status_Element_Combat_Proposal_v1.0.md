# Phase3-B — 状態異常・属性戦闘 Proposal v1.0

**Status:** Adopted（P2-D171 — SSOT: `docs/specs/game/27_状態異常と属性.md`）  
**Version:** v1.0  
**Approved:** 2026-06-23  
**Related:** `26_CombatVision.md`, `08_戦闘_AI.md`, `09_ドロップ_Affix.md`

---

## 1. Purpose

Crownfall には現状、**状態異常**（毒・麻痺・睡眠等）と**属性**（炎・氷等）の戦闘体系が存在しない。

一方、仕様上は以下が既に言及されている。

| 既存言及 | 所在 | 実装 |
|---|---|---|
| 出血（Bleed） | `08_戦闘_AI.md`, `09_ドロップ_Affix.md`, `01_ゲーム概要.md` | **未実装** |
| 毒・凍結ビルド | `01_ゲーム概要.md` 勝ち筋例 | **未実装** |
| 属性耐性（Resistance） | P2-D003（防御とは別系） | **未実装** |
| 状態異常（汎用） | `26_CombatVision.md` Future Extensions | 未設計 |

本 Proposal は、Combat Vision を侵害せず、**段階的に**状態異常・属性を導入する設計案である。

---

## 2. Design Constraints（必須）

`26_CombatVision.md` より:

| 制約 | 設計への含意 |
|---|---|
| プレイヤーは戦闘操作しない | 状態異常は**ビルドの結果**として観察する。解除ボタン・QTE は不要 |
| 「見るだけで分かる」 | 各状態に**固定アイコン・色・ログ1行**を必須とする |
| AI 自律戦闘 | 睡眠・麻痺は「行動スキップ」として AI に処理させる |
| 段階統合 | Data → Resolver → Combat → UI → Content の順 |

---

## 3. 属性（Element）— 推奨案

### 3.1 方針: 少ない属性 + 明確なテーマ

スマホ・「見て理解」向けに **5 属性** を推奨する。10 属性以上は Phase4 以降も見送り。

| ID | 日本語 | 英語 | 世界観テーマ | 主なダンジョン |
|---|---|---|---|---|
| `physical` | 物理 | Physical | 標準・武器そのもの | 全般 |
| `ember` | 焼損 | Ember | 炉・錆・戦火 | 王都跡、地下工廠（将来） |
| `frost` | 霜 | Frost | 白骸・冷気 | 白骸墓地 |
| `venom` | 毒 | Venom | 腐敗・墓毒 | 白骸墓地 |
| `curse` | 呪 | Curse | 深淵・王冠の影 | エリート・ボス |

**採用しない（初期）:** 雷・聖・風・土の独立属性 — 焼損/霜/呪に統合可能なため。

### 3.2 属性の役割

属性は以下にのみ影響する（初期スコープ）。

| 用途 | 説明 |
|---|---|
| 与ダメ補正 | 弱点 1.25x / 耐性 0.75x（数値は Task で確定） |
| 状態異常の紐付け | 例: 毒状態は `venom` 属性攻撃で付与しやすい |
| 敵・装備の identity | 墓地敵は frost/venom 弱点など |

**属性は独立した「魔法システム」にしない。** 武器・スキル・敵攻撃のタグとして付与する。

### 3.3 データ設計（案）

```text
EnemyData.element_weakness: Array[String]   # 弱点属性 id
EnemyData.element_resist: Array[String]    # 耐性属性 id（任意）

WeaponData.element: String                 # デフォルト physical
SkillData.element: String
Affix: ElementalDamage / Resistance 系 stat_type（将来）
```

P2-D003 に従い、`total_defense` とは別に `element_resist_rate` を計算する。

---

## 4. 状態異常（Status Effect）— 推奨案

### 4.1 方針: Tier 段階導入

一度に FF 全状態を入れない。**プレイヤーが 5 分で覚える量**に抑える。

#### Tier 1 — Phase3-B 第一候補（MVP 戦闘深度）

| ID | 名称 | 効果 | 視覚 | ビルド役割 |
|---|---|---|---|---|
| `bleed` | 出血 | DoT（攻撃力% / tick）| 赤滴アイコン | Affix 既言及分の実装 |
| `poison` | 毒 | DoT（固定 or スタック）| 緑霧 | 墓地ビルド |
| `slow` | 鈍化 | 攻撃間隔延長 | 青足跡 | テンポ変化・観察向き |

#### Tier 2 — Phase3-B 後半 or Phase4

| ID | 名称 | 効果 | 視覚 | 注意 |
|---|---|---|---|---|
| `burn` | 焼損 | DoT + 防御微減 | 炎アイコン | ember 属性と連動 |
| `stun` | スタン | 1〜2 tick 行動不能 | 星アイコン | 短時間のみ。連鎖無限禁止 |
| `weak` | 虚弱 | 与ダメ減 | 下向き矢印 | シンプル debuff |

#### Tier 3 — Icebox（要別 Decision）

| ID | 名称 | 懸念 |
|---|---|---|
| `paralysis` | 麻痺 | 麻痺＝行動不能がスタンと重複。統合候補 |
| `sleep` | 睡眠 | 解除条件が複雑だと「見て分かる」に反する |
| `freeze` | 凍結 | 移動系実装後でないと意味が薄い |
| `silence` | 沈黙 | スキル体系拡張後 |

**推奨:** Tier 3 の `paralysis` / `sleep` は **スタン / 鈍化の亜種**として再定義するか、ボス専用に限定する。

### 4.2 状態異常ルール（共通）

| ルール | 内容 |
|---|---|
| 同時付与上限 | 1 ユニットあたり **異種 3 種まで**（同種はスタックルール） |
| DoT tick | CombatTimer（現行）または将来リアルタイム tick に同期 |
| クリーンズ | 現行: 戦闘終了で全解除。将来: スキル・装備で解除 |
| プレイヤー操作 | **なし**（自動で掛かり・切れる） |
| 表示 | LabelLog + アイコン列（Phase3-A VFX と連携） |

### 4.3 出血（既存仕様との統合）

`08_戦闘_AI.md` 将来仕様:

- 5 秒 / 攻撃力 20%/秒 / 最大 5 スタック

→ Tier 1 の `bleed` として正式採用候補。Affix の Bleed カテゴリと接続。

### 4.4 データ設計（案）

```text
# マスタ
StatusEffectData: id, display_name, tier, max_stacks, tick_interval,
                  effect_type (dot / action_skip / stat_mod), element_tag

# 戦闘中インスタンス
StatusInstance: effect_id, stacks, remaining_ticks, source_element

# CombatController
active_statuses: Dictionary  # unit_id -> Array[StatusInstance]
```

---

## 5. 既存システムとの接続

| システム | 接続方針 |
|---|---|
| **Affix** | `Bleed` カテゴリ stat を StatusResolver へ。新 stat: `poison_chance`, `slow_chance` 等 |
| **SkillData** | `apply_status_id`, `element`, `chance` フィールド追加 |
| **WeaponData** | `element`, `on_hit_status`（将来） |
| **EnemyData** | 攻撃時 status 付与、弱点属性 |
| **Job** | Mage → burn 付与、Scout → poison 特効（AI 思想と一致） |
| **Combat Vision** | ログに「誰が誰に毒」を必ず出す |

---

## 6. IN / OUT Scope

### IN（Phase3-B 候補 Milestone: Combat Depth）

| 優先 | 内容 |
|---|---|
| P0 | StatusEffectData + StatusResolver 基盤 |
| P0 | Tier1: bleed / poison / slow |
| P1 | 5 属性定義 + 弱点・耐性ダメ補正 |
| P1 | 戦闘 UI: 状態アイコン + ログ |
| P2 | Affix ↔ 状態異常接続 |
| P2 | 敵 2〜3 種に付与攻撃 |
| P2 | Tier2: burn / stun |

### OUT（本 Proposal スコープ外）

- プレイヤーによる状態解除操作
- 属性マスター・複合属性（炎+雷等）
- 地形属性（水面で感電等）— Combat Vision Future
- パーティメンバー別耐性（共有装備のまま）
- sleep / paralysis 無制限ループ
- 16 種類以上の状態異常

---

## 7. Milestone / Task 順（案）

**仮称: Phase3-B-M1 — Status & Element Foundation**

| Task | 内容 | 依存 |
|---|---|---|
| P3-Task0xx | StatusEffectData + enum + DataRegistry | — |
| P3-Task0xx | StatusResolver（付与・tick・解除） | 上 |
| P3-Task0xx | CombatController 接続（DoT / slow） | 上 |
| P3-Task0xx | Element 弱点・耐性ダメ補正 | — |
| P3-Task0xx | 戦闘 UI（アイコン・ログ） | Phase3-A 推奨 |
| P3-Task0xx | bleed Affix 接続 + サンプル敵 | Affix |
| P3-Task0xx | Closeout | — |

**Phase3-A（Visual）との関係:** gameplay ロジックは 3-B で実装、アイコン・VFX は 3-A と並行可。プレースホルダ `[毒]` テキストで先行実装も可。

---

## 8. Risks

| リスク | 対策 |
|---|---|
| CombatTimer 抽象戦闘では視覚的に薄い | ログ + アイコンを先に実装。リアルタイム戦闘は別 Milestone |
| 状態過多で理解不能 | Tier 制。同時 3 種上限 |
| Affix / Skill スキーマ膨張 | StatusEffectData に効果を集約。Affix は chance のみ |
| バランス爆発 | Tier1 は 3 種のみ。5 分周回テスト後に Tier2 |

---

## 9. HQ 推奨判断（検討結論）

| 項目 | 推奨 |
|---|---|
| 属性数 | **5 種**（physical / ember / frost / venom / curse） |
| 初期状態異常 | **出血・毒・鈍化** の 3 種（Tier1） |
| 麻痺・睡眠 | **Phase3-B では採用しない**。スタン短時間化で代替検討 |
| 導入タイミング | **Phase3-B**（3-A と並行可。ロジック先行） |
| 設計フロー | 本 Proposal 承認 → `27_状態異常と属性.md` SSOT 化 → Task 分割 |

---

## 10. 承認待ち事項（オーナー）

- [ ] 属性 5 種案の承認
- [ ] Tier1 状態異常 3 種（bleed / poison / slow）の承認
- [ ] 麻痺・睡眠の Tier3 保留の承認
- [ ] Phase3-B-M1 として Milestone 化するか

---

## 関連

- 設計フロー: `06_DevelopmentHQ_Operations.md` §4〜5
- 戦闘ビジョン: `26_CombatVision.md`
- 草案 spec: `docs/specs/game/27_状態異常と属性.md`（Proposal ミラー）
