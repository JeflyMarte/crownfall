# Phase2-M7 Task035 — starting_skill_ids Combat Link Completed v1.0

**Status:** Completed  
**Date:** 2026-06-22  
**ProjectDocs:** v3.5.24  
**Milestone:** Phase2-M7 — Job & Build Foundation  
**Task:** P2-Task035

---

## Purpose

JobData の `starting_skill_ids[0]` を Secondary Skill として SkillExecutor に接続し、武器 Primary Skill を主役としながら Job 固有スキルを補助層として追加する。

---

## Design Rules（P2-D116 / P2-D117）

| ルール | 内容 |
|---|---|
| Primary Skill | `WeaponData.fixed_skill_id` → `_get_player_skill_data()` — 変更なし |
| Secondary Skill | 攻撃メンバーの `JobData.starting_skill_ids[0]` のみ（MVP） |
| 重複防止 | Primary と同一 SkillData id → Secondary スキップ |
| 空安全 | job_id 空 / JobData null / starting_skill_ids 空 → Secondary なし（クラッシュなし） |
| ログ | Secondary 発動時 `【ジョブスキル】display_name: N ダメージ` を追記 |

---

## Implementation

**変更ファイル:** `scripts/dungeon/DungeonScene.gd`

### 追加関数

#### `_get_job_skill_data(member_index: int) -> Resource`

攻撃メンバーの job から `starting_skill_ids[0]` を解決。  
job_id 空 / JobData 未取得 / starting_skill_ids 空 → `null` を返す。

#### `_try_cast_secondary_skill(primary_skill_id: String) -> String`

Secondary Skill を試みる。  
- `_get_job_skill_data()` が null → `""` 返却  
- `skill_data.id == primary_skill_id` → スキップ（P2-D117）  
- 実行時は `_skill_executor.execute_damage_skill()` 経由（cooldown 管理込み）  
- ログ: `"\n【ジョブスキル】{name}: {damage}ダメージ"`

#### `_do_party_attack()` 修正

```gdscript
var skill_log: String = _try_cast_player_skill()
var primary_skill: Resource = _get_player_skill_data()
var primary_id: String = primary_skill.id if primary_skill != null else ""
var secondary_log: String = _try_cast_secondary_skill(primary_id)
$VBoxContainer/LabelLog.text = "攻撃: %dダメージ%s%s%s" % [total_dmg, crit_tag, skill_log, secondary_log]
```

---

## Verification

| 確認項目 | 結果 |
|---|---|
| warrior + iron_sword（slash_attack）→ Primary のみ | warrior.starting_skill_ids[0]="slash_attack" = Primary id → Secondary スキップ |
| guardian / scout → Secondary なし | starting_skill_ids 空 → `_get_job_skill_data()` が null |
| SkillExecutor cooldown 既存挙動維持 | skill_id 単位独立管理。Secondary も同ロジックで cooldown 管理 |
| Job 未設定クラッシュなし | `job_id.is_empty()` 早期 return |
| SkillData 未取得クラッシュなし | `DataRegistry.get_skill_data()` null チェック |
| Headless 検証 | `Godot --headless --quit-after 3` — エラーなし |
| Save Regression | SaveManager 未変更 |
| UI Regression | シーン構造未変更 |

---

## Decisions

| # | 内容 |
|---|---|
| P2-D134 | `_get_job_skill_data` で `starting_skill_ids[0]` を SkillData として解決 |
| P2-D135 | Primary と同一 id の Secondary は実行しない（P2-D117 実装） |
| P2-D136 | Secondary 未設定・未取得は安全スキップ |

---

## Current Job Data（2026-06-22 時点）

| Job | starting_skill_ids | Secondary 発動 |
|---|---|---|
| warrior | ["slash_attack"] | slash_attack = Primary と同一 → スキップ |
| guardian | [] | なし（正常） |
| scout | [] | なし（正常） |

> warrior に Primary と異なる skill が追加された場合、または新 Job が別 starting_skill を持つ場合に Secondary が実際に発動する。

---

## Next Task

**P2-Task036** — Job UI（BaseScene 読み取り専用表示）
