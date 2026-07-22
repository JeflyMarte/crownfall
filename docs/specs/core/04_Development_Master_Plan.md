# Development Master Plan — v1.0

**Status:** Completed Draft（Proposal → Completed Draft）  
**Version:** v1.6  
**Created:** 2026-06-21  
**Last synced:** 2026-06-22（Phase2-M9 Scope Adoption — P2-D148）  
**Audience:** DevelopmentHQ / 実装担当 AI / プロジェクトオーナー  
**Document type:** プロジェクト計画（**ゲームプレイ仕様ではない**）

---

## Maintenance Policy

**本書は全体開発戦略またはマイルストーン構造が変わったときのみ更新する。**

- 通常の Task 完了では **更新しない**
- 更新トリガー例: 新 Phase 開始、Milestone 再編、Exit Criteria 変更、長期方針の Decision
- 日次進捗は `CurrentState.md` / `CurrentSprint.md` / `11_TASK_INDEX.md` が担う

---

# 1. Purpose

本書は Crownfall の **Alpha から Release までの実装戦略** を一箇所に集約する。

定義するもの:

| 項目 | 内容 |
|---|---|
| 開発順序 | 何を先に、何を後に実装するか |
| マイルストーン目標 | 各 M の Purpose と Major Systems |
| 完了基準 | Phase / Milestone の Exit Criteria |
| 長期実装戦略 | Beta → Release への段階的拡張 |

**SSOT の位置づけ**

- **ゲームルール・数値・Resource スキーマ** → `docs/specs/game/` / `docs/specs/implementation/` / `03_Decision_Log.md`
- **プロジェクト進行・実装順序の戦略** → **本書**
- **現在の進捗スナップショット** → `docs/project/CurrentState.md`

本書は Product Vision の **実装計画側** の補完であり、Vision 本文を上書きしない。

---

# 2. Development Philosophy

Crownfall の実装は以下の原則に従う。

### Core Loop First

プレイ可能な最小ループ（探索 → 戦闘 → 報酬 → 拠点 → 装備/鑑定 → 再探索）を最優先で成立させる。装飾的システムより **ループ完走** を優先する。

### Foundation before Content

DataRegistry / Save / Instance / Scene 遷移など **基盤が先**。コンテンツ（敵・ダンジョン・Affix プール）は基盤の上に積む。

### Systems before Polish

戦闘・装備・Affix 等の **システム接続** を UI 全面リデザインより先に行う。MVP UI は機能優先（`mvp_theme.tres` レベル）。

### Mobile First

Landscape 1280×720 固定、60 FPS 目標、低操作負荷。DevelopmentHQ 判断も **スマホ向けセッション**（短時間・再開しやすさ）を前提とする。

### Small Vertical Slice

1 ダンジョン完走 → 2 ダンジョン → Affix ループ → … と **縦に薄く通す** ことを繰り返す。横に広い未接続機能を増やさない。

### Incremental Expansion

Affix 例: Data → Roll → Appraisal → Stat → UI の **段階統合**（P2-Task028〜032）。一度に全部つなげない。

### Preserve SSOT

- 実装前: Decision → SSOT 更新 → Task 実装
- コードの正: `CODEMAP.md` + `docs/specs/`
- 本書・Roadmap・CurrentState の役割を混同しない

---

# 3. Development Phases

| Phase | 名称 | 目標 | 状態（2026-06-21） |
|---|---|---|---|
| Phase 0 | 設計・仕様確定 | 憲章・MVP 方針・Godot アーキテクチャ確定 | **完了** |
| Phase 1 | Foundation / MVP | 1 ダンジョン・装備 3 枠・鑑定・Save・ループ成立 | **完了** |
| Phase 2 | Playable Alpha | 戦闘/部屋/世界/Affix/スキル/Job/Craft 基盤 + M9 候補 | **進行中**（M9） |
| Phase 3-A | Visual Production | スプライト / UI art / テーマ / 演出アセット | **未着手** |
| Phase 3-B | Content Expansion | 3 ダンジョン目以降・敵/イベント量産・Legendary コンテンツ | **未着手** |
| Phase 4 | Polish | 5 分周回・UX polish・バランス初版 | **未着手** |
| Phase 5 | Release Preparation | ストア申請・安定性・申請素材 | **未着手** |

Phase 2 完了 ≒ Alpha 完成。Phase 3-A → 3-B で Beta 向け **見た目 + コンテンツ** を段階投入。Phase 4〜5 で polish とリリース準備。

---

# 4. Milestone Breakdown

## Phase 1（MVP 相当 — Phase2 以前）

**Purpose:** 1 周プレイ可能な MVP ループ。

**Major systems:** Boot → Base → Dungeon → Result、Weapon/Loot/Appraisal/Equipment、SaveManager。

**Exit Criteria:** 王都跡完走、鑑定・装備変更・セーブ、100G 鑑定経済。

**Status:** **完了**

---

## Phase2-M1: Equipment Complete

**Purpose:** 武器・防具・装飾品 3 枠の装備深度と戦闘接続。

**Major systems:** Weapon/Armor/Accessory Data & Instance、Loot 率、Appraisal 3 カテゴリ、EquipmentScene、ATK/DEF/HP/CRT 戦闘反映。

**Exit Criteria:** 3 枠装備・鑑定・Save/Load・戦闘 stat 全接続。

**Status:** **完了**（2026-06-19）

---

## Phase2-M2: Combat Spec Alignment

**Purpose:** 自動戦闘仕様への整合、パーティ HP 個別管理。

**Major systems:** CombatTimer、CombatController 個別 HP、全滅判定、ProjectDocs v3.3。

**Exit Criteria:** 自動戦闘のみ、3 人個別 HP、1 人死亡で探索継続・3 人全滅で失敗。

**Status:** **完了**（2026-06-21）

---

## Phase2-M3: Room System

**Purpose:** 探索リズムの多様化（Special Room + データ基盤）。

**Major systems:** Branch Route、HEAL/TREASURE/Merchant/Event/Elite、Discovery registry、SkillData、DataRegistry SSOT。

**Exit Criteria:** Special Room 一式プレイ可能、Discovery 登録・Save、SkillData lookup 可能。

**Status:** **完了**（2026-06-21）

---

## Phase2-M4: World Expansion Foundation

**Purpose:** マルチダンジョン基盤と 2 プレイアブルエリア。

**Major systems:** Multi-Dungeon（GameState.current_dungeon_id）、Base Dungeon Select、白骸墓地、MaterialData + material_inventory。

**Exit Criteria:** 王都跡 / 白骸墓地選択・完走、素材 data 層 + Save。

**Status:** **完了**（2026-06-21）

---

## Phase2-M5: Combat Depth Foundation

**Purpose:** 武器駆動スキルと Job データ基盤。

**Major systems:** SkillExecutor、Weapon fixed_skill_id、JobData + DataRegistry lookup。

**Exit Criteria:** slash_attack 等が戦闘で発動、Job lookup のみ（戦闘未接続は許容）。

**Status:** **完了**（2026-06-21）

---

## Phase2-M6: Equipment Depth Foundation

**Purpose:** Affix による装備 identity と Core Loop 完成。

**Major systems:** AffixData、AffixRoller、鑑定連携、AffixStatCalculator、AffixDisplayFormatter、Equipment Affix UI。

**Exit Criteria:**

- Weapon Discovery → Appraisal → Affix Generation → Reveal → Stat → UI 比較 が一連で成立 ✓

**Status:** **完了**（2026-06-21）

**完了 Task:** P2-Task028〜032

**M6 Summary:** AffixData → AffixRoller → 鑑定連携（Instance 保存）→ AffixStatCalculator → AffixDisplayFormatter。Core Loop 完成。

---

## Phase2-M7: Job & Build Foundation

**Purpose:** Connect JobData to gameplay, introduce build identity, and improve build readability. Job becomes a supporting layer for weapon-centric progression rather than replacing it.

**Major systems:** Job combat modifier、`starting_skill_ids` 接続、Job UI、Build Summary UI。

**Exit Criteria（全達成）:**

- Job modifier connected ✓（P2-Task034）
- starting_skill_ids connected ✓（P2-Task035）
- Job UI ✓（P2-Task036）
- Build Summary UI ✓（P2-Task037）

**Status:** **完了**（2026-06-22）

**完了 Tasks（P2-D122）:** P2-Task033〜038

---

## Phase2-M8: Craft & Economy Foundation

**Purpose:** Material 消費ループの完成と Blacksmith による Gold/Material 双方のシンク確立。Weapon は Blacksmith でも排出しない（Special Room Bible 原則継承）。

**Major systems:** CraftData Resource、GameState.consume_materials()、BlacksmithScene、Craft Output Integration、Merchant Materials 購入（P2-Task043）。

**Exit Criteria:**

- DataRegistry から CraftData 3 件以上取得可
- consume_materials() が素材と Gold を正しく減算
- 作成後に未鑑定 Instance が inventory に追加される（既存 Loot 生成フロー互換）
- Craft 後 Save → Load で inventory が保持される
- 素材不足・Gold 不足時に「作成」ボタンが無効

**Status:** **完了**（2026-06-22 — P2-Task044 Closeout）

**完了 Tasks（P2-Task039〜044）:** Craft Resource Pack / consume_materials / BlacksmithScene / Craft Output / Merchant Materials / Closeout

---

## Phase2-M9: Codex & Discovery Foundation

**Purpose:** `discovery_registry` をプレイヤーが閲覧できる Codex UI へ接続。Read-Only。Save 形式不変。

**Major systems:** CodexCatalogHelper、CodexScene、DiscoveryRegistry category 拡張（dungeon / weapon）、History / Dungeon Bible リンク。

**Exit Criteria:**

- 5 カテゴリ Tab（Enemy / Dungeon / Material / Weapon / History）
- Discovered / Undiscovered 表示
- Save → Load 後 Codex 表示一致
- 王都跡 / 白骸墓地 完走可能（回帰なし）

**Status:** **進行中**（Scope Adopted 2026-06-22 — P2-D148）

**Scope SSOT:** `docs/archives/GameplayArchive/Proposal/Phase2_M9_Codex_Discovery_Scope_Proposal_v1.0.md`

**Task 計画（P2-D153）:**

| Task | 内容 | 状態 |
|---|---|---|
| P2-Task045 | Codex Scope Adoption | **完了** |
| P2-Task046 | Codex Data Foundation | 未着手 |
| P2-Task047 | Codex UI Foundation | 未着手 |
| P2-Task048 | Discovery Detail View | 未着手 |
| P2-Task049 | History / Dungeon Bible Link | 未着手 |
| P2-Task050 | Phase2-M9 Closeout | 未着手 |

---

## Phase3-A: Visual Production（P2-D130）

**Purpose:** プレースホルダーから **本番ビジュアル** へ移行。gameplay 仕様は変更しない。

**Major systems（想定）:** キャラ / 敵スプライト、UI art / テーマ、環境 art、装備アイコン、最小 VFX。

**Exit Criteria（案）:** MVP 画面が production art で一貫表示、Pixel Apprentice 成果物が SSOT 管理下に配置。

**Status:** **未着手（Future）**

**Owner:** Pixel Apprentice（P2-D129 Responsibility）

---

## Phase3-B: Content Expansion（P2-D131）

**Purpose:** 2 DG 以降の **コンテンツ量産** — ダンジョン / 敵 / イベント / Legendary 等。

**Major systems（想定）:** 3 ダンジョン目（地下工廠等）、敵 / ボス / エリート拡張、Affix / Skill / Job プール拡張、Merchant / Event 拡張。

**Exit Criteria（案）:** 3 ダンジョン目プレイ可能、コンテンツ pool が Beta 試遊に足る量。

**Status:** **未着手（Future）**

**Owner:** Game Designer（P2-D129 Responsibility）

---

## Phase4: Polish（P2-D132）

**Purpose:** 5 分 run rhythm、UX 読みやすさ、バランス初版。

**Major systems（想定）:** 周回調整、HUD / ログ可読性、パフォーマンス初版。

**Status:** **未着手（Future）**

---

## Phase5: Release Preparation（P2-D132）

**Purpose:** ストア品質・安定性・申請準備。

**Major systems（想定）:** Save 耐性、ストア素材、申請、地域対応準備。

**Status:** **未着手（Future）**

---

# 5. Dependency Strategy

実装順序は **下流が上流に依存する** ため、以下の順を基本とする。

```
Core Loop（MVP）
  ↓
Combat Spec（自動戦闘・HP）
  ↓
Room System（探索リズム・Branch）
  ↓
DataRegistry / SkillData / Discovery（参照基盤）
  ↓
Dungeon Expansion（2 DG・Material data）
  ↓
Skill System（SkillExecutor・武器リンク）
  ↓
Affix Stack（Data → Roll → Appraisal → Stat → UI）
  ↓
Job & Build Foundation
  ↓
Craft / Economy Foundation
  ↓
Codex / Collection UI
  ↓
Phase3-A Visual Production（art / UI theme）
  ↓
Phase3-B Content Expansion（3 DG 目・敵量産）
  ↓
Phase4 Polish（balance / UX）
  ↓
Phase5 Release Preparation
```

**理由（要約）**

- Room System なしでは Multi-Dungeon の意味が薄い
- Affix は Appraisal / Instance / Save が前提（Task028〜030）
- Job & Build は Affix stat 集計パターン確立後が安全（M6 完了）
- Craft / Economy は Material data（M4）と Job/装備基盤の上
- Codex は Discovery 登録（M3）後
- Phase3-A（Visual）は gameplay 基盤確立後 — **仕様変更なし** で art 差し替え
- Phase3-B（Content）は Multi-Dungeon + DataRegistry パターン確立後
- Polish / Release は Phase3-A/B 後

---

# 6. Current Position

**Snapshot:** ProjectDocs v3.5.34 / Phase 2 Alpha / **Phase2-M9 進行中**（Scope Adopted P2-D148）

### Already Complete

- Phase 0 / Phase 1（MVP ループ）
- Phase2-M1〜M8

### Current Milestone

**Phase2-M9 — Codex & Discovery Foundation**（Scope Adoption 済 P2-D148）

- 正式 Task: P2-Task045〜050
- Scope SSOT: `Phase2_M9_Codex_Discovery_Scope_Proposal_v1.0.md`

### Immediate Next

1. **P2-Task046** — Codex Data Foundation
2. P2-Task047 — Codex UI Foundation

### Previous Milestone

**Phase2-M8 — Craft & Economy Foundation** — **完了**（2026-06-22）

### Future Roadmap（P2-D129）

```
M7 Job & Build（完了）
  ↓
M8 Craft & Economy（完了）
  ↓
M9 Codex & Discovery（進行中）
  ↓
Phase3-A Visual Production
  ↓
Phase3-B Content Expansion
  ↓
Phase4 Polish
  ↓
Phase5 Release Preparation
```

### Deferred（意図的に後回し）

- Affix reroll / Legendary 特殊 / Curse
- 敵スキル / ボス固有 mechanics
- 3 ダンジョン目以降 → **Phase3-B**
- UI 全面リデザイン / production art → **Phase3-A**
- Weapon クラフト / 武器 Merchant 販売（MVP 禁止維持）

---

# 7. Long-term Vision

日付は固定しない。順序のみ示す。

### Toward Beta（Phase3-A → Phase3-B）

- **Phase3-A:** production art / UI theme — gameplay 仕様不変
- **Phase3-B:** 3 ダンジョン目（例: 地下工廠）設計 + 実装、敵 / イベント量産
- Job・Affix 拡張 stat・Material 消費ループ（M8）・Codex（M9）の **接続完了**

### Toward Beta Playtest（Phase4 Polish）

- 5 分前後の run  rhythm 調整
- 装備比較・ビルド選択の読みやすさ
- バランス初版・探索リズム（Product Vision §3.8）の検証

### Toward Release（Phase5 Release Preparation）

- モバイル UI ポリッシュ（Landscape HUD、ログ可読性）
- パフォーマンス・Save 耐性・クラッシュフリー
- ストア素材・申請・地域対応

### Toward Store Launch

- Product Vision の Commander Fantasy / Weapon-Centric / Appraisal Identity が **初回体験で伝わる** 状態
- コンテンツ量は「深さ > 横幅」の原則を維持した拡張

---

# 8. Deferred Systems

以下は **Master Plan 上、Phase 2 後半〜Phase 4 以降** に配置する major deferrals。

| システム | 備考 |
|---|---|
| Job Combat | JobData lookup のみ完了（M5） |
| Job UI / 編成 UI | パーティ 3 人固定のまま |
| Affix Reroll | Appraisal 一度きり（MVP） |
| Legendary Presentation | identity 演出・特殊ロジック |
| Curse Affix | MVP 対象外 |
| Codex UI | discovery_registry のみ |
| Craft / Economy | **M8 完了**（Blacksmith + Merchant Materials） |
| Enemy Skills | 平砍 + プレイヤースキルのみ |
| Boss Mechanics | エリート相当（HP/ドロップ） |
| Third Dungeon | **Phase3-B** Content Expansion |
| Fourth Dungeon+ | **Phase3-B** Content Expansion |
| Production Art / UI Theme | **Phase3-A** Visual Production |
| Sort / Filter / Compare UI | Equipment 最小表示のみ |
| Achievement / Collection rewards | Discovery 拡張 |

---

# 9. Development Rules

DevelopmentHQ / 実装 AI 共通ルール（要約）。

1. **One milestone at a time** — 現行 M の Exit Criteria を満たしてから次 M へ
2. **Task スコープ厳守** — 指定 Task 範囲外に手を付けない（`AGENTS.md`）
3. **Decision before SSOT** — 仕様変更は Decision Log → specs 更新 → 実装
4. **ProjectDocs before implementation** — Task バンドル Read リストを守る
5. **Completed documents archived** — 承認後 `GameplayArchive/Completed/` に成果物
6. **No feature creep** — Task にない機能を推測実装しない
7. **Incremental integration** — Roll / Appraisal / Stat / UI を一括接続しない
8. **CODEMAP is code truth** — 未実装 path を勝手に作成しない
9. **本書は戦略変更時のみ更新** — 通常 Task 完了では CurrentState / Task Index を更新

---

# 10. Exit Criteria

## Phase 1（MVP）— 完了済み

- 1 ダンジョン完走、鑑定・装備・Save、Result → Base ループ

## Phase 2（Alpha）— 進行中

- M1〜M8 完了 ✓
- **Next:** Phase2-M9 Codex & Discovery Foundation
- Alpha 基盤: 2 DG・Special Room・Affix・Job・Craft/Economy ループ ✓

## Phase2-M8 — Craft & Economy Foundation — **完了**（2026-06-22）

- CraftData + consume_materials + BlacksmithScene + Craft Output ✓
- Merchant Materials 購入（P2-D144）✓
- Task039〜044 完了 ✓

## Phase3-A — Visual Production（P2-D130）

- キャラ / 敵 / 環境 / 装備アイコンの production art
- UI theme / visual identity（gameplay 仕様変更なし）

## Phase3-B — Content Expansion（P2-D131）

- 3 ダンジョン目プレイ可能
- 敵 / ボス / イベント / Legendary コンテンツ pool 拡張

## Phase 4 — Polish（P2-D132）

- 5 分 run 目安の初版 balance
- UX / HUD 読みやすさ

## Phase 5 — Release Preparation（P2-D132）

- ストア品質 UI / 安定性 / 申請準備完了

---

# 11. Relationship to Other Documents

```
Product Vision（Design Reference — 非 SSOT 実装仕様）
        ↓ 方針整合
02_Roadmap.md（Phase / Milestone タイムライン）
        ↓ 詳細化
04_Development_Master_Plan.md（本書 — 実装戦略 SSOT）
        ↓ スプリント分解
docs/project/CurrentSprint.md（現 M の Goal / 残 Task）
        ↓ 日次スナップショット
docs/project/CurrentState.md（今どこまで終わったか）
        ↓ 実装単位
11_TASK_INDEX.md + DevelopmentHQ Task プロンプト
        ↓ コード正
CODEMAP.md + docs/specs/implementation/ + docs/specs/game/
        ↓ 確定事項
03_Decision_Log.md
        ↓ 承認成果
docs/archives/GameplayArchive/Completed/
```

| 文書 | 役割 | 更新頻度 |
|---|---|---|
| Roadmap | Phase / M の一覧と状態 | Milestone 完了・Phase 移行時 |
| **Master Plan（本書）** | なぜその順序か、長期戦略 | **戦略・M 構造変更時のみ** |
| CurrentSprint | 現 M の Goal | M 開始 / Task 完了時 |
| CurrentState | ダッシュボード | Task 完了時 |
| Task Index | 実装履歴・ファイル対応 | Task 完了時 |
| Decision Log | 確定 Decision | Decision 採用時 |
| specs/game | ゲームルール SSOT | Decision + Task 反映時 |

---

## Document History

| Version | Date | Note |
|---|---|---|
| v1.0 | 2026-06-21 | 初版 Completed Draft。Phase2-M6 進行中時点のスナップショット |
| v1.1 | 2026-06-21 | M6 Closeout 同期。M7 = Job & Build Foundation |
| v1.2 | 2026-06-21 | M7 Scope Adoption。Task033〜038 登録。M7 進行中 |
| v1.3 | 2026-06-21 | Phase3 Split Adoption（P2-D129）。Phase3-A/B + Phase4/5 再編 |
| v1.4 | 2026-06-22 | Phase2-M7 Closeout（P2-D137）。M7 完了、M8 候補明記 |
| v1.5 | 2026-06-22 | Phase2-M8 Closeout（P2-Task044）。M8 完了、M9 = Next Milestone |
| v1.6 | 2026-06-22 | Phase2-M9 Scope Adoption（P2-D148）。Task045〜050 登録。M9 進行中 |
