# Repository_Cleanup_Policy_Completed_v1.0

**Status:** Completed  
**Type:** Repository Policy  
**Approved By:** DevelopmentHQ  
**Version:** v1.0  
**ProjectDocs:** v3.5.11  
**Date:** 2026-06-21

---

## Purpose

DevelopmentHQ にて Repository Cleanup 方針を正式決定し、ProjectDocs v3.5.10 基準の運用ルールを SSOT へ反映した。

**Gameplay / Resource / Scene 変更なし。ファイル削除・git commit なし。**

---

## Decisions

| # | 決定 |
|---|---|
| P2-D081 | ProjectDocs ZIP はリポジトリ管理対象外。SSOT は `docs/`。ZIP は Release Artifact |
| P2-D082 | Proposal は Completed 後も削除しない（Proposal → Completed → Decision 履歴） |
| P2-D083 | Lore（16/17/18）は当面 `docs/specs/game/` が正式配置先 |
| P2-D084 | Git Commit は Milestone 単位で分割（Milestone / Gameplay / ProjectDocs / Cleanup） |

---

## Repository Cleanup Policy

### Approved for deletion

- 全ての `.DS_Store`
- 中身が存在するディレクトリ内の `.gitkeep`

### Keep（削除禁止）

- `docs/specs/**`, `docs/project/**`, `docs/archives/**`
- `CHANGELOG.md`, `AGENTS.md`, `CLAUDE.md`, `README.md`
- Product Vision / Bible / Completed / Proposal
- CurrentState / CurrentSprint

### ProjectDocs ZIP

- Repository から除外
- Release Asset または NAS / Drive に保管

### Proposal Recovery

- Proposal 欠落 Completed は可能な限り Proposal 復元（例: Affix_Bible_v1.0）

---

## SSOT 反映

| ファイル | 内容 |
|---|---|
| `docs/specs/core/Project_Repository_Policy.md` | 運用ルール SSOT |
| `docs/specs/core/03_Decision_Log.md` | P2-D081〜084 |
| `docs/project/CurrentState.md` | バージョン・参照 |
| `CHANGELOG.md` | v3.5.11 |

---

## Deferred（本 Task では未実施）

- `.DS_Store` / 冗長 `.gitkeep` の物理削除
- 旧 ZIP のリポジトリからの除去
- git commit（Milestone 単位分割）
- Affix_Bible Proposal 復元

---

## 参照

- `docs/specs/core/Project_Repository_Policy.md`
