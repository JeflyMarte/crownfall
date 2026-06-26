# Archives — レビュー前成果物保管庫

## 位置づけ

このディレクトリはDevelopmentHQレビュー待ちの成果物を保管する場所です。

**正式仕様のSSOT（唯一の真実の情報源）は `docs/specs/` のみです。**

archives 内の文書はすべて **Proposal（提案）扱い** であり、正式仕様ではありません。

---

## DevelopmentHQ レビューフロー（Cursor）

```
Lead / Art Director / 世界観担当
  ↓ 成果物を archives/ に配置
DevelopmentHQ（Cursor HQ セッション）レビュー
  ↓ 承認された内容のみ
ProjectDocs（docs/specs/）へ反映
  ↓
Implementation Agent（Cursor Impl セッション）が Task 実装
```

運用詳細: `docs/specs/core/06_DevelopmentHQ_Operations.md`

承認前の内容を実装に使用しないでください。

---

## ディレクトリ構成

```
archives/
  GameplayArchive/   — Lead Game Designer の成果物
  ArtArchive/        — Art Director の成果物
  WorldArchive/      — 世界観・ゲームデザイン室の成果物
  ReviewHistory/     — DevelopmentHQ レビュー記録
  README.md          — 本ファイル
```

---

## 各フォルダの役割

### GameplayArchive

Lead Game Designer が作成した設計提案を配置します。

配置例:
- Phase2_Gameplay_Design_Proposal_v1.0.md
- Weapon_Bible_v1.md
- Dungeon_Design_v1.md
- Job_Design_v1.md

### ArtArchive

Art Director が作成したアートディレクション提案を配置します。

配置例:
- Phase2_Art_Direction_Proposal_v1.1.md
- UI_Guideline_v1.md
- Pixel_Guide_v1.md

### WorldArchive

世界観・ゲームデザイン室が作成した世界設定資料を配置します。

配置例:
- `Completed/World_Assets_Bible_Completed_v1.1.md` — World Pillars 採用記録（SSOT: `docs/specs/game/25_WorldAssetsBible.md`）
- `Proposal/World_Assets_Bible_v1.1.md` — 採用時 Proposal 原文
- `Proposal/Phase0_World_Assets_Review_v1.1.md` — DevelopmentHQ レビュー
- `Proposal/Phase0_World_Assets_v1.0_raw.md` — GPT 原文（参照用）
- World_Bible.md / History_Bible.md / Region_Bible.md

### ReviewHistory

DevelopmentHQ によるレビュー記録を配置します。

配置例:
- Review_2026-06-19.md
- Decision_Candidates.md

---

## 注意事項

- archives 内の文書は DevelopmentHQ 承認前は **Proposal** です
- 承認なしに実装へ反映しないでください
- 承認済み内容は ProjectDocs（docs/specs/）へ反映し、archives 内の文書はそのまま履歴として残します
- ProjectDocs（docs/specs/）の内容を archives に移動しないでください
