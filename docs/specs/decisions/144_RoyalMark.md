# 王痕育成（P3-DG-ROYAL-MARK-001）

**Status:** **Implemented**（2026-09-18）— Phase 1＋Phase 2（専用UI＋**Rank III Job Skill／Rank V Ultimate 強化**）／feature `cursor/royal-mark-144`（**main 未マージ**）  
**上書きなし**（極限任務 Decision 143 は Completed のまま）

---

## 0. 一言

極限任務の恒久目的として、人間キャラクターに **王痕 I〜V**（ステ倍率）を付与する。固有 Passive／限凸とは独立。

---

## 1. 対象

| 項目 | 内容 |
|---|---|
| 対象 | 人間プレイアブル 19 人（`Adventurer.id`） |
| 除外 | Jack／他ペット |
| 解放 | メイン Biome 1〜5 Normal CLEAR |
| 強化条件 | roster 所持・Lv50 以上・片／Gold |

---

## 2. Rank（累積）

| Rank | 効果（累積倍率） | 片 | Gold |
|---|---|---:|---:|
| I | HP ×1.03 | 10 | 5,000 |
| II | HP×1.03／ATK×1.03 | 15 | 10,000 |
| III | HP/ATK×1.03／DEF×1.03 ＋ **装備 Job Skill 強化** | 20 | 15,000 |
| IV | HP/ATK/DEF ×1.05（Skill 強化は維持） | 25 | 25,000 |
| V | HP/ATK/DEF ×1.08 ＋ **固有 Ultimate 強化**（Skill も維持） | 30 | 45,000 |

累計コスト: 片 100／Gold 100,000。

ステ適用位置: `(base+equip+affix+level)×job` の直後。戦闘専用 modifier はその後。UI と Combat は同一ヘルパ。

---

## 3. 極限報酬

EX-01〜10 共通。

| ★帯 | 初回到達片 |
|---:|---:|
| 1 | 3 |
| 2 | +3 |
| 3 | +4 |
| 4 | +5 |

差分のみ（`prev_best` → `stars`）。1任務最大 15。

CLEAR ごと 25% で片×1（初回 CLEAR 含む）。`force_repeat_roll`／`rng` 注入可。

同一ラン二重 commit は `GameState.extreme_run_reward_committed` で遮断（★・周回とも）。

---

## 4. Save（v18）

| キー | 型 |
|---|---|
| `royal_mark_shards` | int |
| `royal_mark_ranks` | `{ Adventurer.id: 0..5 }` |

v17→v18: 既存 `extreme_mission_progress[*].best_stars` から一度だけ遡及（★1=3 … ★4=15、EX合算）。再 migrate しない。

---

## 5. 実装アンカー

- `scripts/systems/RoyalMarkConfig.gd`／`RoyalMarkSystem.gd`／**`RoyalMarkSkillModifier.gd`**
- `GameState`／`SaveManager`（SAVE_VERSION 18）
- `ExtremeMissionConfig.commit_clear_result`
- `RosterUiHelper`／`CombatController`／`DamageCalculator`
- **`RoyalMarkScene`**（Phase 2 専用育成UI）／**キャラ管理「王痕育成」導線**（拠点メニューはオミット）
- `EquipmentScene`（Rank 参照表示のみ・強化 transaction なし）／`ResultScene`
- `DungeonScene._execute_member_skill`（実行直前に `enhance_for_combat`）
- `tests/unit/test_royal_mark.gd`／`test_royal_mark_ui.gd`／**`test_royal_mark_skill_enhance.gd`**

---

## 5.1 Phase 2 UI（専用画面）

| 項目 | 内容 |
|---|---|
| Scene | `scenes/royal_mark/RoyalMarkScene.tscn` |
| 導線 | **キャラ管理（Equipment）NameRow「王痕育成」**。拠点左メニューからはオミット。Main5 Normal 未 CLEAR はボタン LOCKED |
| 切替 | roster 人間のみ左右切替（Jack／pet 除外）。入場時は `equipment_focus_member_id` を優先 |
| 戻る | キャラ管理へ（フォーカス維持） |
| 表示 | Rank I〜V（III=◆／V=★）。**情報階層**＝現在効果1行 → **次の王痕（主情報）** → コスト →「王痕を刻む」→ 特殊王痕 III/V 2行コンパクト。**MAX時は次Rank・素材・刻む非表示**→同スロットに「王痕 V」＋「MAX」（既存用語）。ゲーム効果・コスト不変 |
| 強化 | 「王痕を刻む」→ `RoyalMarkSystem.can_upgrade`／`apply_upgrade`／save。短演出のみ |
| 王痕片 Help | 右上 `?`／素材行タップで説明（極限任務への直接遷移はなし） |
| 背景 | 専用 `UI_BG_RoyalMark`（拠点BGと分離・装飾専用）。動的 UI は Godot Control |
| 色階層 | 金＝見出し／王痕重要情報。本文・数値＝アイボリー〜白。強化値＝淡青白。不足＝赤。未解放＝グレー |
| Equipment | NameRow「王痕育成」導線。Rank 参照ラベルは置かない |

ロジック・経済・Save・Extreme 報酬は Phase 1 据置（数値変更なし）。Presentation はモック寄せ／Polish 可（Decision 効果値は不変）。

---

## 5.2 Phase 2 — Skill／Ultimate 強化

| ゲート | 内容 |
|---|---|
| Rank 0〜II | Skill／Ultimate 補正なし |
| Rank III〜IV | **装備中 Job Skill 1枠のみ**（付け替えで対象も追従）。`trail_ward`／`equip_passive`／`effect_type=none` は対象外 |
| Rank V | 上記 Job Skill ＋ **固有 Ultimate** |

標準 Job Skill: damage×1.10／heal×1.15／status +10pp（damageは据置）／buff duration+1／trap は威力×1.10のみ。  
標準 Ultimate: damage×1.08上限／heal +2〜3pp／薄い control は付与穴埋め。  
個別8（skill_id 辞書）: ボルグ counter／ブリキ cascade／アンヴィ AB倍率／火鷹 crit_surge 時間／ルーシェ blood_drain 時間／ウォール tag heal／エリアス attune 時間／セリン heal。  
計算順: 既存 modifier／passive／装備の後に王痕。CD・資源・AI・Passive・限凸は変更しない。status chance ≤100%。

---

## 6. 非スコープ

王痕 VI+／Passive 変更／限凸変更／新キャラ・装備・ダンジョン／極限 TUNING 変更／Decision 143 変更／新大型アート／Phase 1 経済・★・25%周回の再調整。
