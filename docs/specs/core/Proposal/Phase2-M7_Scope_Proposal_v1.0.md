# Phase2-M7 Scope Proposal v1.0

**Status:** Completed Draft → **Adopted**（DevelopmentHQ 2026-06-21）  
**Version:** v1.0.1（Review 修正: Task037 依存）  
**Created:** 2026-06-21  
**SSOT Baseline:** ProjectDocs **v3.5.18**  
**Milestone:** Phase2-M7 — Job & Build Foundation  
**Type:** Scope Definition（実装・Decision Log 更新は本 Proposal 承認後）

---

## Document Status

| 項目 | 内容 |
|---|---|
| 本書の位置づけ | M7 正式 Scope の **提案**。承認前は SSOT ではない |
| 整合対象 | `04_Development_Master_Plan.md` v1.1 / `CurrentState.md` / `CurrentSprint.md` / P2-D110〜112 |
| M6 | **完了**（Task028〜032） |
| M7 | **未着手**（Ready） |
| 更新禁止（本 Task） | Decision Log / CurrentState / CurrentSprint / Completed / ZIP |

---

# 1. Purpose

Phase2-M7 **Job & Build Foundation** の正式 Scope を確定する。

### 達成したいこと

- **JobData**（M5 基盤）を gameplay に **最小接続** する
- **Build Identity** をプレイヤーが読み取れる状態にする
- **Weapon-Centric** 原則を維持したまま、Job を **支援層** として機能させる

### M7 で成立させる Core 体験

```
装備（武器主役） + Affix + Job modifier
        ↓
戦闘・生存・スキルが Job で差分化
        ↓
Job UI / Build Summary でビルドが読める
```

### M7 でやらないこと

Craft / Economy / Codex / 新ダンジョン / Job 全面リデザイン / パーティ編成 UI 拡張

---

# 2. Scope

## 2.1 In Scope

| # | 領域 | 内容 |
|---|---|---|
| 1 | **Party Job 整合** | `Adventurer.job_id` を既存 JobData（warrior / guardian / scout）と整合 |
| 2 | **JobStatCalculator** | Job modifier 集計ヘルパー（AffixStatCalculator と同型の独立 RefCounted） |
| 3 | **Job Modifier 戦闘接続** | `base_hp_modifier` / `base_attack_modifier` / `base_defense_modifier` を **メンバー単位** に反映 |
| 4 | **starting_skill_ids 接続** | Job の starting skill を SkillExecutor 経由で **補助スキル** として接続 |
| 5 | **Job UI** | パーティ 3 人の Job 名称・role を **読み取り専用** 表示（BaseScene 想定） |
| 6 | **Build Summary UI** | 武器・防具・装飾品・Affix・Job を **1 画面で要約**（EquipmentScene 拡張想定） |
| 7 | **ProjectDocs 同期** | Task 完了ごとに specs 更新。M7 Closeout で Milestone 完了宣言 |

## 2.2 Design Constraints（必須）

| 原則 | M7 での解釈 |
|---|---|
| **Weapon-Centric** | 与ダメ・ビルドの主役は **装備武器 + Affix**。Job modifier は **倍率補正** に留める |
| **Job = Build Identity** | role / display_name / modifier 差で「この編成の役割」が分かる |
| **武器スキル優先** | `WeaponData.fixed_skill_id` が **Primary Skill**。Job `starting_skill_ids` は **Secondary** |
| **MVP / 保守性** | 新 Singleton 禁止。Calculator 分離。CombatController 全面改修禁止 |
| **段階統合** | Modifier → Skill → Job UI → Build Summary の順（Affix M6 パターン踏襲） |

## 2.3 starting_skill_ids — MVP 接続ルール（提案）

| ルール | 内容 |
|---|---|
| 参照 | 攻撃中メンバーの `JobData.starting_skill_ids[0]` のみ（MVP） |
| Primary | 既存 `_get_player_skill_data()` — **武器 fixed_skill_id**（変更なし） |
| Secondary | starting skill が Primary と **異なる id** の場合のみ SkillExecutor で追加実行 |
| 重複 | 同一 SkillData id は 1 ティック 1 回まで |
| 空 | guardian / scout は starting_skill 空 — **武器スキルのみ**（正常） |

---

# 3. Out of Scope

| 項目 | 理由 / 移管先 |
|---|---|
| Craft / Material usage / Blacksmith | Future M8 Craft & Economy（P2-D112） |
| Codex UI | Future M9 |
| 新ダンジョン | Phase3 候補 |
| Job 選択・転職 UI | M7 外。表示のみ |
| Job レベル / パッシブ実装 | JobData フィールドは将来用 |
| `passive_tag_ids` gameplay 接続 | M7 外 |
| `preferred_weapon_types` ペナルティ/ボーナス | M7 外（表示のみ可） |
| 敵スキル / ボス mechanics | Defer |
| Affix reroll / Legendary / Curse | Defer |
| Sort / Filter / Compare popup | Defer |
| Mobile UI 全面 polish | M7 外（Build Summary 最小追加のみ） |
| パーティメンバー別装備 | MVP は共有装備（GameState.equipped_*）維持 |

---

# 4. Success Criteria

M7 成功時、プレイヤー（および DevelopmentHQ）が以下を **説明なしで確認** できる。

| # | 成功基準 |
|---|---|
| SC-1 | 3 人パーティが warrior / guardian / scout JobData と整合している |
| SC-2 | 戦士（高 atk modifier）と守護者（高 def/hp modifier）で **戦闘結果に差** が出る |
| SC-3 | warrior の starting_skill（slash_attack）が武器スキルと整合し、**二重実行にならない** |
| SC-4 | Base（または指定 UI）で **各メンバーの Job 名** が見える |
| SC-5 | Equipment（Build Summary）で **武器 + Affix + Job modifier 概要** が 1 ブロックで読める |
| SC-6 | 王都跡 / 白骸墓地が **従来通り完走** 可能（回帰なし） |
| SC-7 | Job 未設定 / 不正 job_id でも **クラッシュしない** |

---

# 5. Exit Criteria

`04_Development_Master_Plan.md` v1.1 の M7 Exit Criteria と **完全一致** させる。

| # | Exit Criteria | 対応 Task |
|---|---|---|
| EC-1 | Job modifier connected | P2-Task034 |
| EC-2 | starting_skill_ids connected | P2-Task035 |
| EC-3 | Job UI | P2-Task036 |
| EC-4 | Build Summary UI | P2-Task037 |

**Milestone Closeout（EC-5）:** P2-Task038 完了 + DevelopmentHQ 承認 → Phase2-M7 Completed

---

# 6. Task 一覧

| Task | 名称 | 依存 |
|---|---|---|
| **P2-Task033** | Party Job Alignment + JobStatCalculator Foundation | M6 完了 |
| **P2-Task034** | Job Modifier Combat Integration | Task033 |
| **P2-Task035** | starting_skill_ids Combat Link | Task033, Task034 |
| **P2-Task036** | Job UI | Task033 |
| **P2-Task037** | Build Summary UI | Task033, **Task034**, Task032 |
| **P2-Task038** | Phase2-M7 Closeout | Task033〜037 |

---

# 7. Task 詳細

---

## P2-Task033 — Party Job Alignment + JobStatCalculator Foundation

### Purpose

パーティ `job_id` を JobData SSOT に整合し、Job modifier 集計の **共通ヘルパー** を確立する。

### Input

- `scripts/data/JobData.gd`
- `resources/jobs/*.tres`
- `scripts/autoload/GameState.gd`（`_init_party`）
- `scripts/domain/Adventurer.gd`
- `scripts/equipment/AffixStatCalculator.gd`（パターン参照）

### Output

- `scripts/equipment/JobStatCalculator.gd`（新規）
- `GameState._init_party()` — job_id を warrior / guardian / scout に整合
- （任意）サンプル SkillData 1 件を scout 用に追加 — **Scope 膨張防止のため Task033 では空のまま可**

### Completion Criteria

- [ ] `JobStatCalculator.get_member_modifiers(adventurer) -> Dictionary` が hp/atk/def multiplier を返す
- [ ] 不正 / 空 `job_id` → multiplier 1.0（安全 fallback）
- [ ] パーティ 3 人が `warrior` / `guardian` / `scout` に対応
- [ ] gameplay 戦闘数値 **未変更**（Calculator のみ）
- [ ] ProjectDocs 更新（03_Resource / CODEMAP）

---

## P2-Task034 — Job Modifier Combat Integration

### Purpose

Job modifier を **メンバー単位** の戦闘計算に接続する。武器・Affix との合成順序を固定する。

### Input

- `JobStatCalculator.gd`（Task033）
- `scripts/dungeon/DungeonScene.gd`（`_calc_attack_base`, `_calc_enemy_damage_to_member`, 攻撃ループ）
- `scripts/combat/CombatController.gd`（`_init_party_hp`）
- `AffixStatCalculator.gd`（合成順序参照）

### Output

- `DungeonScene` — メンバー index 付きダメージ計算（job atk modifier）
- `CombatController._init_party_hp` — メンバー別 max HP に job hp modifier
- `DungeonScene._calc_enemy_damage_to_member` — 被弾対象の job def modifier

### 合成順序（提案固定）

```
base（武器 / ステ）
  → Affix flat/mult
  → Job modifier（multiply）
  → crit / run multiplier
```

### Completion Criteria

- [ ] 同一装備でも warrior と guardian で **与ダメ / 被ダメ / max HP** に差
- [ ] Affix 効果は Task031 通り維持
- [ ] 武器未装備 fallback 維持
- [ ] CombatController **全面改修なし**（`_init_party_hp` 最小追加のみ）
- [ ] 王都跡 / 白骸墓地 完走可能

---

## P2-Task035 — starting_skill_ids Combat Link

### Purpose

Job `starting_skill_ids[0]` を **Secondary Skill** として SkillExecutor に接続。武器スキルを主役のまま補助層を追加。

### Input

- `JobStatCalculator` / party job 解決（Task033）
- `scripts/combat/SkillExecutor.gd`
- `DungeonScene._try_cast_player_skill()` / 攻撃ループ
- `WeaponData.fixed_skill_id` フロー（Task026）

### Output

- `DungeonScene` — メンバー攻撃時に Secondary Skill 判定・実行
- 戦闘ログに `【ジョブスキル】` 等の **最小識別**（文字列 1 行追加可）

### Completion Criteria

- [ ] warrior + iron_sword（slash_attack）→ **Primary のみ**（重複なし）
- [ ] starting_skill を持つ Job で、Primary と **異なる** skill id 時のみ Secondary 発動
- [ ] guardian / scout（starting_skill 空）→ 挙動変化なし
- [ ] SkillExecutor cooldown 既存挙動維持
- [ ] 武器 fixed_skill_id が **常に Primary**

---

## P2-Task036 — Job UI

### Purpose

プレイヤーがパーティ各員の **Job Identity** を確認できる最小 UI を追加する。

### Input

- `JobData` / `DataRegistry.get_job_data`
- `scenes/base/BaseScene.tscn` + `BaseScene.gd`（第一候補）
- `mvp_theme.tres`

### Output

- BaseScene に **Party Job 表示**（3 行: 名前 / Job 名 / role）
- 読み取り専用。**Job 変更 UI なし**

### 表示例

```
戦士 — 戦士（dps）
守護者 — 守護者（tank）
斥候 — 斥候（scout）
```

### Completion Criteria

- [ ] Base 画面で 3 人の Job 名が見える
- [ ] 不正 job_id → 「不明」または id fallback（クラッシュなし）
- [ ] 新シーン **作成しない**（Base 拡張優先）
- [ ] gameplay 変更なし

---

## P2-Task037 — Build Summary UI

### Purpose

武器主役のビルドを **1 ブロックで読める** Build Summary を Equipment に追加。Affix 表示（Task032）を拡張統合。

### Input

- `AffixDisplayFormatter.gd`
- `JobStatCalculator.gd`
- `EquipmentScene.gd` / `.tscn`
- 装備中 weapon / armor / accessory
- **Task034 完了後**（Job Modifier 表示に必要）

### Output

- EquipmentScene に **Build Summary** セクション（Label または折りたたみ 1 ブロック）
- 含む情報: 武器 ATK / 装備 Affix 要約 / Job modifier 概要 / 装備中 role

### 表示例

```
=== Build Summary ===
武器: rusted_blade  ATK 17
Affix: 鋭利 / 偉力
防具: leather_armor  DEF 5
ジョブ: 戦士（dps） ATK x1.1
```

### Completion Criteria

- [ ] 鑑定済み Affix が Summary に含まれる
- [ ] Job modifier が **数値または倍率** で読める
- [ ] 未鑑定 Affix は Summary に **非表示**
- [ ] Compare popup / sort / filter **なし**
- [ ] 戦闘 stat 計算ロジック **変更なし**（表示のみ）

---

## P2-Task038 — Phase2-M7 Closeout

### Purpose

Phase2-M7 を DevelopmentHQ 承認可能な状態で Closeout し、ProjectDocs を同期する。

### Input

- Task033〜037 完了報告
- `CurrentState.md` / `CurrentSprint.md` / `02_Roadmap.md` / Master Plan
- M6 Closeout 文書（テンプレ）

### Output

- `Phase2_M7_Closeout_Completed_v1.0.md`
- ProjectDocs v3.5.x 更新（CHANGELOG / Decision Log に P2-D113+ 反映）
- ZIP 再生成

### Completion Criteria

- [ ] M7 Exit Criteria EC-1〜4 全確認
- [ ] Deferred 一覧更新
- [ ] 次 Milestone 候補（M8 Craft & Economy）明記
- [ ] **gameplay 変更なし**（同期のみ）

---

# 8. Implementation Order

```
P2-Task033  Party Job Alignment + JobStatCalculator
    ↓
P2-Task034  Job Modifier Combat Integration
    ↓
P2-Task035  starting_skill_ids Combat Link
    ↓
P2-Task036  Job UI          ─┐
    ↓                        ├─ Task036 は Task033 後なら Task034 と並行可
P2-Task037  Build Summary UI ── Task034 完了後（依存: 033, 034, 032）
    ↓
P2-Task038  Phase2-M7 Closeout
```

**推奨:** 1 Task / 1 依頼（CLAUDE.md 運用）。Task036 は Task034 と **並行可能**（UI のみ）。

---

# 9. Dependencies

## 9.1 上流（完了済み）

| 依存 | 提供 |
|---|---|
| M5 Task027 | JobData + get_job_data + 3 job.tres |
| M5 Task025-026 | SkillExecutor + weapon fixed_skill_id |
| M6 Task028-032 | Affix loop + AffixStatCalculator + AffixDisplayFormatter |
| M2 | 個別 HP / 自動戦闘 |
| M1 | 装備 3 枠 |

## 9.2 下流（M7 完了後）

| 後続 | 関係 |
|---|---|
| M8 Craft & Economy | Material usage — Job/装備基盤の上 |
| M9 Codex | 独立 |
| Phase3 3rd Dungeon | 独立 |

## 9.3 既知ギャップ（Task033 で解消）

| ギャップ | 現状 | M7 対応 |
|---|---|---|
| party job_id | GameState: warrior / **thief** / **mage** | warrior / guardian / scout に整合 |
| Job lookup | thief / mage に JobData **なし** | Task033 で修正 |
| 戦闘 | 全員同一 `_calc_damage()` | Task034 で **index 別** modifier |

---

# 10. Risk

| # | リスク | 影響 | 緩和 |
|---|---|---|---|
| R-1 | Job modifier × Affix × 武器の **合成順序** バグ | バランス崩壊 | Task034 で順序 SSOT 化。Decision 候補 P2-D115 |
| R-2 | starting_skill と weapon skill **二重実行** | DPS 膨張 | Primary/Secondary 分離。同一 id スキップ P2-D116 |
| R-3 | 共有装備 + 個別 Job modifier の **説明負荷** | プレイヤー混乱 | Build Summary（Task037）で明示 |
| R-4 | `_calc_damage()` ループ改修範囲 | 回帰 | メンバー index 引数の **最小 diff** |
| R-5 | scout 用 starting_skill 未定义 | Secondary 検証不足 | warrior 重複排除テストを必須 Verification に。scout 空は正常系 |
| R-6 | UI 追加による Base / Equipment **縦長化** | 可読性低下 | 1 ブロック Summary。全面リデザイン禁止 |

---

# 11. Decision 候補（P2-D113 以降 — 未採用）

**本 Proposal 承認時に Decision Log へ追加する候補。** 現時点では **更新しない**。

| # | 決定事項（案） | 根拠 |
|---|---|---|
| **P2-D113** | **Phase2-M7 正式 Scope** を本 Proposal 通り採用 | M7 Scope Definition 承認 |
| **P2-D114** | Job modifier は **パーティメンバー単位** に適用（共有装備でも per-member） | Build Identity / 3 人差別化 |
| **P2-D115** | stat 合成順序: base → Affix → **Job multiply** → crit / run mult | 合成バグ防止 |
| **P2-D116** | `starting_skill_ids[0]` **のみ** MVP 接続。Job skill は **Secondary**、武器 fixed_skill が **Primary** | Weapon-Centric |
| **P2-D117** | Primary と同一 SkillData id の Secondary は **実行しない** | 二重 slash_attack 防止 |
| **P2-D118** | MVP パーティ job_id = **warrior / guardian / scout**（GameState 初期化整合） | JobData SSOT 一致 |
| **P2-D119** | `JobStatCalculator` は `scripts/equipment/JobStatCalculator.gd` に配置 | AffixStatCalculator 同型 |
| **P2-D120** | Job UI は **BaseScene 読み取り専用**。Job 変更 UI は M7 外 | MVP |
| **P2-D121** | Build Summary は **EquipmentScene 内 1 ブロック** 追加。依存 **Task033+034+032** | 保守性 |
| **P2-D122** | **Phase2-M7 完了** — Exit Criteria EC-1〜4 + Closeout 承認 | Milestone 完了 |

---

# 12. CurrentState 更新案（Proposal — 未適用）

**M7 開始 Task（033）完了後に適用推奨。Closeout（038）で最終確定。**

```markdown
## Current Milestone
Phase2-M7 — Job & Build Foundation（**進行中**）

## Previous Milestone
Phase2-M6 — Equipment Depth Foundation（**完了** 2026-06-21）

## Current Task
P2-Task033 Party Job Alignment + JobStatCalculator Foundation

## Next Recommended Task
1. P2-Task034 Job Modifier Combat Integration

## Current Playable Features（追記）
| ジョブ | JobData lookup → **（M7 後）modifier / skill / UI** |
```

---

# 13. CurrentSprint 更新案（Proposal — 未適用）

**DevelopmentHQ が本 Proposal を承認した時点で Sprint 切替。**

```markdown
## Sprint Name
Phase2-M7 — Job & Build Foundation

## Goal
JobData を gameplay に接続し、Build Identity と Build Summary 可読性を確立。
Weapon-Centric 原則を維持。

## Remaining Tasks（M7）
| 優先 | Task | 内容 |
|---|---|---|
| 1 | P2-Task033 | Party Job Alignment + JobStatCalculator |
| 2 | P2-Task034 | Job Modifier Combat Integration |
| 3 | P2-Task035 | starting_skill_ids Combat Link |
| 4 | P2-Task036 | Job UI |
| 5 | P2-Task037 | Build Summary UI |
| 6 | P2-Task038 | Phase2-M7 Closeout |

## Next Priority
P2-Task033

## Notes
- Scope SSOT: Phase2-M7_Scope_Proposal_v1.0.md（承認後）
- Craft / Codex / 新 DG は M7 外
```

---

# 14. Approval Checklist（DevelopmentHQ）

| # | 確認項目 |
|---|---|
| 1 | Weapon-Centric / Job = 支援層の原則に同意 |
| 2 | Task033〜038 の粒度に同意 |
| 3 | starting_skill Secondary ルール（P2-D116/117）に同意 |
| 4 | Party job_id 整合（warrior/guardian/scout）に同意 |
| 5 | M8 以降（Craft）を M7 外とすることに同意 |

**承認後アクション（本 Proposal 外）:**

1. Decision Log に P2-D113〜122 追加  
2. `11_TASK_INDEX.md` に Task033〜038 追加  
3. CurrentState / CurrentSprint 更新（§12/§13）  
4. Master Plan M7 Status → 進行中  
5. P2-Task033 実装開始

---

## Document History

| Version | Date | Note |
|---|---|---|
| v1.0.1 | 2026-06-21 | DevelopmentHQ 採用。Task037 依存を Task034 に修正 |
