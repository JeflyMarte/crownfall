# Phase2-M7 Task036 — Job UI Completed v1.0

**Status:** Completed  
**Date:** 2026-06-22  
**ProjectDocs:** v3.5.25  
**Milestone:** Phase2-M7 — Job & Build Foundation  
**Task:** P2-Task036

---

## Purpose

BaseScene にパーティ 3 人分の Job 情報を読み取り専用で表示する。  
Job 変更・編成変更 UI は **禁止**（P2-D120）。

---

## Design Rules（P2-D120）

| ルール | 内容 |
|---|---|
| 読み取り専用 | Job 変更・編成変更・スキル変更 UI なし |
| 表示場所 | BaseScene — 既存 LabelMember0/1/2 を拡張 |
| fallback: job_id 空 | `Job: -` |
| fallback: JobData 欠落 | `Job: {job_id}` |
| modifier 表示 | 1.0 と異なるもののみ（HP / ATK / DEF） |

---

## Display Format

```
{member_name} / Job: {job_display_name} / Role: {role} / {modifier_parts}
```

modifier_parts には 1.0 と異なるものだけ表示。

| Member | 表示例 |
|---|---|
| 戦士（warrior） | `戦士 / Job: 戦士 / Role: dps / ATK x1.10` |
| 守護者（guardian） | `守護者 / Job: 守護者 / Role: tank / HP x1.20 DEF x1.20` |
| 斥候（scout） | `斥候 / Job: 斥候 / Role: scout` |

---

## Implementation

**変更ファイル:**
- `scripts/base/BaseScene.gd`
- `scripts/autoload/DataRegistry.gd`

### BaseScene.gd 追加

`_format_member_job_line(member: Resource) -> String`  
`JobStatCalculator.get_member_modifiers(member)` から job_display / role / multiplier を取得してフォーマット。

`_update_party_display()` を更新し、3 Labels に `_format_member_job_line` の結果をセット。

### DataRegistry.gd 修正

`get_job_data(job_id)` に `ResourceLoader.exists()` guard を追加。  
存在しない id（旧セーブの thief / mage 等）→ コンソールエラーなしで null 返却。

---

## Verification

| 確認項目 | 結果 |
|---|---|
| warrior / guardian / scout 正しく表示 | warrior: ATK x1.10、guardian: HP x1.20 DEF x1.20、scout: modifier なし |
| job_id 空でクラッシュなし | `Job: -` 表示 |
| JobData 欠落（旧 thief/mage）でクラッシュなし | `Job: thief` / `Job: mage` 表示（ResourceLoader.exists guard） |
| Job 変更 UI なし | なし（P2-D120） |
| Headless 検証 | エラーなし |
| Combat Regression | CombatController / DungeonScene 未変更 |
| Save Regression | SaveManager 未変更 |
| UI 遷移 Regression | シーン構造未変更 |

---

## Next Task

**P2-Task037** — Build Summary UI（EquipmentScene 内 1 ブロック、依存: Task033 / Task034 / Task032）
