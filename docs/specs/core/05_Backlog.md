# Development Backlog — SSOT

**Status:** Active  
**Version:** v1.2  
**Created:** 2026-06-21  
**SSOT Baseline:** ProjectDocs v3.5.22  
**Document type:** 将来機能一覧（**ゲームプレイ仕様ではない**）

---

## Maintenance Policy

| 項目 | ルール |
|---|---|
| 更新タイミング | DevelopmentHQ Decision 後 / Milestone Closeout 後 / 新 Deferred 確定時 |
| 追加 | DevelopmentHQ Decision **後のみ** |
| 削除 | 機能が **正式実装** され Task Index に移った後 |
| Task 化 | Backlog から **削除または [→ Task] 注記** → Task Index へ |
| 本書に書かない | 数値・Resource スキーマ・詳細設計・実装手順 |

**Routine Task 完了だけでは本書を更新しない。** CurrentState / CurrentSprint が日次進捗を担う。

---

# 1. Purpose

## 1.1 Backlog の役割

本書は Crownfall の **未着手・将来実装・Deferred** 機能を一元管理する SSOT である。

| 管理する | 管理しない |
|---|---|
| まだ存在しない機能の **名称と優先度** | 実装済み / 実装中 Task（→ Task Index） |
| Milestone 横断の **候補一覧** | スケジュール確定（→ Roadmap） |
| 実装順序の **理由**（→ Master Plan 参照） | ゲームルール・バランス数値 |

## 1.2 対象範囲

- Phase2 残 Milestone（M7〜M9 候補）
- Phase3-A / Phase3-B 候補機能
- Phase4 / Phase5 候補機能
- Deferred Systems（意図的延期）
- Icebox（将来検討）

## 1.3 対象外

- 完了済み M1〜M6 成果物
- P2-Task033〜038 の **Task 定義本文**（Task Index / Scope Proposal が SSOT）
- Product Vision 本文

---

# 2. Priority Rules

| Priority | 意味 | 例 |
|---|---|---|
| **P0** | 現 Milestone 必須。Exit Criteria 未達なら Milestone 未完了 | M7 Job modifier 接続 |
| **P1** | 現 Milestone 内。P0 完了後すぐ | M7 Build Summary UI |
| **P2** | 次 Milestone 第一候補 | M8 Material Usage |
| **P3** | 計画済みだが Milestone 未割当 | Phase3-B 3rd Dungeon |
| **Future** | Phase 確定後に詳細化 | Phase4 Quest |
| **Icebox** | アイデア段階。Decision なし | Guild |

**運用:** 各項目に `[P0]` 等を付与。同一 Phase 内では P0 → P1 → P2 の順で Task 化を検討する。

---

# 3. Current Active Backlog

## Phase2-M7 — Job & Build Foundation（進行中）

**Scope SSOT:** `Proposal/Phase2-M7_Scope_Proposal_v1.0.md`（P2-D113）  
**Task 対応:** P2-Task033〜038（Task Index — 未実装）

| Priority | 機能 | 備考 |
|---|---|---|
| P0 | Party Job Alignment | Task033 |
| P0 | JobStatCalculator Foundation | Task033 |
| P0 | Job Modifier Combat Integration | Task034 |
| P0 | starting_skill_ids Combat Link（Secondary） | Task035 |
| P1 | Job UI（Base 読み取り専用） | Task036 |
| P1 | Build Summary UI | Task037（依存: 034） |
| P0 | Phase2-M7 Closeout | Task038 |

---

## Phase2-M8 — Craft & Economy Foundation（候補）

**Master Plan:** Future M8（P2-D112 Material Usage 移管）
**Design Proposal:** `docs/archives/GameplayArchive/Proposal/Phase2-M8_Craft_Economy_Foundation_Design_v1.0.md`
**Task Proposal:** `docs/archives/GameplayArchive/Proposal/Phase2-M8_Task_Proposal_v1.0.md`

| Priority | 機能 | Task 候補 |
|---|---|---|
| P2 | CraftData Resource 定義 | Task039 |
| P2 | Material Consumption Logic | Task040 |
| P2 | BlacksmithScene Foundation | Task041 |
| P2 | Craft Output Integration | Task042 |
| P2 | Economy Integration（Merchant 拡張） | Task043 |
| P2 | Phase2-M8 Closeout | Task044 |

**Suggested Decisions（未採番）:**
- CraftData スキーマ採用
- MVP レシピ 3 件承認（craft_leather_armor / craft_silver_ring / craft_bone_armor）
- Weapon クラフト可否確認
- Merchant Materials 価格帯承認
- `consume_materials()` 配置方針

---

## Phase2-M9 — Codex Foundation（候補）

**Master Plan:** Future M9

| Priority | 機能 |
|---|---|
| P2 | Discovery UI / Codex |
| P3 | History Bible UI |
| P3 | World Bible UI |
| P2 | Collection 閲覧 |
| P3 | Codex Search |

---

## Phase3-A — Visual Production（P2-D130）

**Owner:** Pixel Apprentice

| Priority | 機能 |
|---|---|
| P2 | Character Sprites |
| P2 | Enemy Sprites |
| P2 | Environment / Room Art |
| P2 | Equipment Icon Art |
| P2 | UI Theme / Visual Polish（mvp_theme → production） |
| P3 | Minimal VFX |

---

## Phase3-B — Content Expansion（P2-D131）

**Owner:** Game Designer

### Dungeon Expansion

| Priority | 機能 |
|---|---|
| P2 | Underground Factory（3 ダンジョン目候補） |
| P3 | Ancient Library |
| P3 | Dungeon 4 |
| P3 | Dungeon 5 |

### Combat & Content Depth

| Priority | 機能 |
|---|---|
| P2 | Enemy Expansion |
| P2 | Boss Expansion |
| P2 | Elite Expansion |
| P2 | **Status & Element Foundation（Phase3-B-M1）** — ✅ 完了（P3-D023）。旧 bleed/poison/slow 表記は廃止 |
| P2 | **Status Effect Foundation** — → Phase3-B-M1 に統合（P2-D175） |
| P2 | **Element System** — → Phase3-B-M1 に統合（P2-D175） |
| P2 | Legendary Equipment |
| P2 | More Skills |
| P2 | More Jobs |
| P3 | Status Tier2（burn / stun / weak） |
| P3 | Merchant Expansion |
| P3 | Special Room Expansion |

---

## Combat Vision — Initiative & Position（P3-D019）

**Decision:** P3-D019 / P3-D019a  
**SSOT 参照:** `26_CombatVision.md` / `08_戦闘_AI.md`  
**Alpha:** Phase 1 イニシアチブ実装済（P3-INIT-001）。`base_attack_speed` 比較で先攻/後攻。

| Priority | 機能 | 段階 | 備考 |
|---|---|---|---|
| P2 | **Initiative Phase 1** — 速度 stat で先攻/後攻 | 1 | P2-D010 後継。CombatTimer 内の行動順をイニシア順に |
| P2 | **Initiative Phase 2** — ジョブ `base_initiative_modifier` | 2 | ✅ P3-INIT-002 |
| P2 | **Initiative Affix** — Attack Speed affix → 先制 | 2b | ✅ P3-AFFIX-SPD-001 |
| P3 | **Position System** — Front / Mid / Back | 3a | Vision §Position。隊列 AI 基盤 |
| P3 | **Initiative Phase 3** — 位置 + 射程 + イニシア統合 | 3b | Vision 本格。引き付け・被弾分布 |
| P3 | 奇襲 / ボス先制（コンテンツ側） | 3b | 特定敵・部屋の例外ルール |

**Task 化タイミング:** EQ-1 完了 + Phase UI-2 着手後を第一候補。Position（3a）と Initiative Phase 1 は並行検討可。

---

## Game Design Review（P3-D024 — 2026-06-25 承認）

**SSOT:** `28_ゲームデザイン点検.md`

| Priority | 機能 | Decision |
|---|---|---|
| P0 | Spec SSOT 同期（bleed / 方針 / 召喚 MVP） | P3-D024 — **完了**（implementation spec 含む） |
| P0 | Alpha = 準備専用（spec honest 化） | P3-D024a — **完了** |
| P1 | **簡易ヘイト** — Guardian / Front 優先被弾 | P3-D024b |
| P1 | **属性 vs 状態** Codex / チュートリアル 1 画面 | P3-D024i |
| P1 | **聖属性武器** 1 本 | P3-D024j |
| P1 | 呪い — 敵→味方 curse 抑制（エリート以降） | P3-D024d — **完了**（P3-D024d-001） |
| P2 | **一括鑑定** | P3-D024f — **完了**（P3-APPR-001） |
| P2 | 装備比較 1 行 | P3-D024f — **完了**（P3-EQ-CMP-001 武器 / P3-EQ-CMP-002 防具） |
| P2 | `preferred_weapon_types` 小ボーナス | P3-D024e — **完了**（P3-JOB-001） |
| P2 | ラン中最小方針 2〜3 種 | P3-D024a Phase 2 |
| P2 | `stun_power` → `stagger_power` リネーム | P3-D024c — **完了**（P3-D024c-001） |

**Task 化第一候補（Combat）:** P3-D024b 簡易ヘイト → P3-D019 Initiative Phase 1

---

## Phase4 — Polish（P2-D132）

| Priority | 機能 |
|---|---|
| Future | UX / HUD Readability |
| Future | Balancing（5 分周回） |
| Future | Performance |
| Future | Audio |
| Future | Tutorial |
| Future | Accessibility |

---

## Phase5 — Release Preparation（P2-D132）

| Priority | 機能 |
|---|---|
| Future | Localization |
| Future | Store Assets |
| Future | Save Migration |
| Future | Store Submission |

---

## Postwar Ecology — 将来システム（2026-06-26 — P3-D035〜037）

| Priority | 機能 | Decision | 備考 |
|---|---|---|---|
| Future | **レベル制** — EXP→Lv→ステ成長 | P3-D035 | `Adventurer.level` 基盤あり。OD-UI-003 を採用方針化 |
| Future | **助っ人キャラ制** — 3 人 + 助っ人で戦闘 | P3-D036 | `MAX_PARTY_SIZE` / 戦闘配列・UI 拡張 |
| Future | **ジョブ強化（ジョブ進化）** — ジョブ Lv → 進化 → 名称変更 | P3-D037 | 基本 5 職の上位プログレッション層。`36_JobBible.md` |

---

# 4. Deferred Systems

意図的に **現 Milestone 外** とした機能。Decision または Closeout で Defer 宣言済み。

| 機能 | 備考 / 想定移管 |
|---|---|
| Affix Reroll | Appraisal 一度きり（MVP） |
| Legendary Affix 特殊ロジック | identity 演出 — Beta 以降 |
| Curse Affix | MVP 対象外 |
| Compare Popup | M7 外 — UI polish 候補 |
| Sort（装備） | M7 外 |
| Filter（装備） | M7 外 |
| Rarity Color System | UI polish |
| passive_tag_ids gameplay | JobData フィールドのみ |
| Job Level | JobData 拡張 — 未計画 |
| Job Change / 転職 UI | M7 外 |
| Third Skill / 追加 skill 枠 | 未計画 |
| preferred_weapon_types ボーナス | ✅ P3-JOB-001 — 適合時 ATK ×1.05 |
| Enemy Skills | 平砍 + プレイヤースキルのみ |
| Boss Mechanics（固有） | エリート相当のまま |
| **Status Tier3（麻痺 / 睡眠 / 凍結 / 沈黙）** | Proposal: スタン・鈍化で代替検討（P2-D170） |
| **属性 6 種以上** | 5 属性案で足りるまで拡張しない |
| パーティメンバー別装備 | **Phase EQ-1 完了**（P3-D018） |
| Attack Speed Affix stat | Task031 未対応 stat — **Initiative Phase 2 で解消**（P3-D019a） |
| Skill Power / Cooldown Affix | 未対応 stat |
| Achievement / Collection rewards | Discovery 拡張 |

**Deferred Count:** 19

---

# 5. Icebox

Decision 未実施の **将来検討** 候補。Backlog 昇格には DevelopmentHQ Decision が必要。

| 候補 | メモ |
|---|---|
| Guild | ソーシャル — 未検討 |
| Endless Dungeon | ループ外コンテンツ |
| New Game+ | メタ進行 |
| Seasonal Content | ライブオプス |
| Challenge Mode | 制限付き run |
| PvP / 非同期対戦 | スコープ外候補 |
| 王遺産装備枠 | MVP 除外（正式版） |
| 自動売却 / オート装備 | QoL — 未検討 |

**Icebox Count:** 8

---

# 6. Maintenance Rules

1. **追加** — DevelopmentHQ Decision または Milestone Closeout で Defer/Candidate 確定後のみ  
2. **削除** — 機能が実装され Task Index に Registered / Completed となった後  
3. **Task 化** — Backlog 項目に Task ID を付与 → Task Index へ移動 → Backlog から削除または `[Done → Task0XX]`  
4. **優先度変更** — Decision Log または Master Plan 更新とセット  
5. **仕様化禁止** — 本書に stat 数値・API・シーン構成を書かない（`docs/specs/game/` へ）  
6. **Roadmap との境界** — Roadmap = いつ。Backlog = 何が残っているか。重複名称は可、スケジュールは Roadmap のみ  

---

# 7. Relationship to Other Documents

```
Product Vision（Design Reference — 体験の北極星）
        ↓ 方針整合
04_Development_Master_Plan.md（なぜその順番か）
        ↓ 時系列
02_Roadmap.md（いつ・どの Milestone か）
        ↓ 未実装機能プール
05_Backlog.md（本書 — まだ存在しない機能一覧）
        ↓ スプリント選択
docs/project/CurrentSprint.md（現 M の Goal）
        ↓ 日次
docs/project/CurrentState.md（今どこまで）
        ↓ 実装単位
11_TASK_INDEX.md（実装済み・実装中・Task 定義）
        ↓ 確定事項
03_Decision_Log.md
```

| 文書 | 役割 | 本書との関係 |
|---|---|---|
| Master Plan | 戦略・依存順序 | Backlog 項目の **配置理由** |
| Roadmap | Phase / M タイムライン | Backlog の **時期ラベル** |
| **Backlog** | 未実装機能一覧 | — |
| Task Index | Task 履歴・ファイル | 実装開始後は **Backlog から移出** |
| CurrentSprint | 現 M Goal | Backlog P0/P1 から **選ばれた subset** |
| specs/game | gameplay SSOT | Backlog 項目の **詳細仕様先** |

---

## Document History

| Version | Date | Note |
|---|---|---|
| v1.0 | 2026-06-21 | 初版。SSOT v3.5.19 整合。M7 進行中時点 |
| v1.1 | 2026-06-21 | Phase3 Split Adoption（P2-D129）。Phase3-A/B + Phase4/5 再分類 |
| v1.2 | 2026-06-25 | Combat Initiative（P3-D019）Backlog 登録。Initiative & Position 段階表 |
