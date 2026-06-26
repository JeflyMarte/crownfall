# Crownfall - Roadmap

## フェーズ概要

| フェーズ | 目標 | 状態 |
|---|---|---|
| Phase0 | 設計・仕様確定 | 完了 |
| Phase1 | MVP（ゲームループ成立） | 完了 |
| Phase2 | Alpha（装備・戦闘・鑑定の深化） | 進行中 |
| Phase3-A | Visual Production | 未着手 |
| Phase3-B | Content Expansion | 未着手 |
| Phase4 | Polish | 未着手 |
| Phase5 | Release Preparation | 未着手 |

---

## Phase2 マイルストーン

### Phase2-M1: Equipment Complete
**Status:** Completed（2026-06-19）

- Weapon / Armor / Accessory 3枠装備システム完成
- Loot・Appraisal・Equipment・Save/Load 統合
- Combat ATK / DEF / CRT 全効果接続

### Phase2-M2: Combat Spec Alignment
**Status:** Completed（2026-06-21）

- 自動戦闘（CombatTimer 1.5s）
- 冒険者3人個別HP・死亡判定・全滅判定
- ProjectDocs v3.3 更新

### Phase2-M3: Room System
**Status:** Completed（2026-06-21）

**完了（v3.4 SSOT 反映済）:**
- Branch Route System
- HEAL Room
- TREASURE Room
- EnemyData パラメータ拡張
- **Merchant Room**（P2-Task015）
- **Event Room**（P2-Task016）
- **Elite Room**（P2-Task017）
- **Discovery System**（P2-Task018）
- **SkillData Resource**（P2-Task019）
- **DataRegistry**（P2-Task020）

---

## Phase2-M4: World Expansion Foundation

**Status:** Completed（2026-06-21）

- Multi-Dungeon Foundation（P2-Task021）
- Base Dungeon Select（P2-Task022）
- Graveyard Dungeon + Enemy Set（P2-Task023）
- MaterialData Foundation（P2-Task024）
- 2 プレイアブルダンジョン（王都跡 / 白骸墓地）

---

## Phase2-M5: Combat Depth Foundation

**Status:** Completed（2026-06-21）

- SkillExecutor（P2-Task025）
- Weapon Skill Link — fixed_skill_id（P2-Task026）
- Job Foundation — JobData + DataRegistry（P2-Task027）
- 武器駆動スキル戦闘（slash_attack + フォールバック）

---

## Phase2-M6: Equipment Depth Foundation

**Status:** Completed（2026-06-21）

- AffixData Foundation（P2-Task028）
- Affix Roll System（P2-Task029）
- Affix Appraisal Integration（P2-Task030）
- Affix Stat Application（P2-Task031）
- Equipment Detail UI（P2-Task032）
- **Affix ループ完成:** Data → Roll → Appraisal → Instance → Stat → UI

---

## Phase2-M7: Job & Build Foundation

**Status:** Completed（2026-06-22）

**Purpose:** Connect JobData to gameplay, introduce build identity, and improve build readability. Job becomes a supporting layer for weapon-centric progression rather than replacing it.

**完了 Task（P2-D122）:**

| Task | 内容 | 状態 |
|---|---|---|
| P2-Task033 | Party Job Alignment + JobStatCalculator | **完了** |
| P2-Task034 | Job Modifier Combat Integration | **完了** |
| P2-Task035 | starting_skill_ids Combat Link | **完了** |
| P2-Task036 | Job UI | **完了** |
| P2-Task037 | Build Summary UI | **完了** |
| P2-Task038 | Phase2-M7 Closeout | **完了** |

**Exit Criteria（全達成）:**

- Job modifier connected ✓
- starting_skill_ids connected ✓
- Job UI ✓
- Build Summary UI ✓

**M7 対象外（Defer → M8+）:**

- Craft / Economy / Material usage（Future M8）
- Affix reroll / Legendary / Curse
- Codex / 新ダンジョン

**Scope SSOT:** `docs/specs/core/Proposal/Phase2-M7_Scope_Proposal_v1.0.md`（P2-D113）

---

## Phase2-M8: Craft & Economy Foundation

**Status:** **完了**（2026-06-22 — P2-Task044 Closeout）

**Purpose:** Material 消費ループの完成と Blacksmith による Gold/Material 双方のシンク確立。

**Scope（P2-D139〜145）:**

| Task | 内容 | 状態 |
|---|---|---|
| P2-Task039 | CraftData Foundation | **完了** |
| P2-Task040 | Material Consumption Logic | **完了** |
| P2-Task041 | BlacksmithScene Foundation | **完了** |
| P2-Task042 | Craft Output Integration | **完了** |
| P2-Task043 | Economy Integration（Merchant 拡張） | **完了** |
| P2-Task044 | Phase2-M8 Closeout | **完了** |

**Exit Criteria:** 全項目達成 ✓

**Scope SSOT:** `docs/archives/GameplayArchive/Proposal/Phase2-M8_Craft_Economy_Foundation_Design_v1.0.md`（P2-D139）

**Closeout:** `docs/archives/GameplayArchive/Completed/Phase2_M8_Closeout_Completed_v1.0.md`

---

## Phase2-M9: Codex & Discovery Foundation

**Status:** **完了**（2026-06-23 — P2-Task050 Closeout）

**Purpose:** `discovery_registry` をプレイヤーが閲覧できる Codex UI へ接続。

**正式 Task（P2-D153）:**

| Task | 内容 | 状態 |
|---|---|---|
| P2-Task045 | Codex Scope Adoption | **完了** |
| P2-Task046 | Codex Data Foundation | **完了** |
| P2-Task047 | Codex UI Foundation | **完了** |
| P2-Task048 | Discovery Detail View | **完了** |
| P2-Task049 | History / Dungeon Bible Link | **完了** |
| P2-Task050 | Phase2-M9 Closeout | **完了** |

**Closeout:** `docs/archives/GameplayArchive/Completed/Phase2_M9_Closeout_Completed_v1.0.md`

---

## Future Roadmap（P2-D129 — Phase3 Split Adoption）

```
M7 Job & Build Foundation（完了）
  ↓
M8 Craft & Economy Foundation（完了）
  ↓
M9 Codex & Discovery Foundation（完了）
  ↓
Phase3-A Visual Production（**着手** — P3-D001）
  ↓
Phase3-B Content Expansion
  ↓
Phase4 Polish
  ↓
Phase5 Release Preparation
```

---

## Phase3-A: Visual Production（P2-D130）

**Status:** **着手**（P3-D001 — 2026-06-24）

**Scope SSOT:** `docs/archives/ArtArchive/Completed/Phase3A_Scope_Adoption_Completed_v1.1.md`

**Purpose:** スプライト / UI art / テーマ / 演出アセット。gameplay 仕様変更なし。

**Owner:** Pixel Apprentice

**候補:**

- キャラ / 敵 / 環境スプライト
- UI theme（mvp_theme → production）
- 装備アイコン art
- 最小 VFX

---

## Phase3-B: Content Expansion（P2-D131）

**Status:** 未着手

**Purpose:** ダンジョン / 敵 / イベント / Legendary 等のコンテンツ量産。

**Owner:** Game Designer

**候補:**

- 地下工廠（3 ダンジョン目）
- 敵 / ボス / エリート拡張
- Legendary 演出・コンテンツ
- Merchant / Event / Special Room 拡張
- Affix / Skill / Job プール拡張

---

## Phase4: Polish（P2-D132）

**Status:** 未着手

- 5 分周回調整
- UX / HUD 読みやすさ
- バランス初版

---

## Phase5: Release Preparation（P2-D132）

**Status:** 未着手

- スマホ UI 最終 polish
- パフォーマンス / 安定性
- ストア申請・素材
