# CommitPlan — Phase3-A Visual Production

**目的:** Phase3-A 期間中のコミット単位・順序・メッセージ規則を定義する。
**作成:** 2026-06-24
**対象範囲:** 最終コミット（fc2dcbc P3-A-005）以降の全変更

---

## コミット規則

### メッセージ形式

```
{Task}: {変更内容の一行サマリー}（{EC / 目的}）
```

例:
```
P3-A-007: 白骸墓地通常敵 5 種スプライト接続（EC-8）
P3-Prep-docs: CODEMAP/TaskIndex/AssetPipeline 同期
```

### ルール

- Task 単位で 1 コミット（複数 .tres を同一 Task で生成した場合はまとめて 1 コミット）
- gameplay ロジック変更のコミットは HQ が行う
- Doc 系（docs/specs/ 更新）は HQ コミット責務（Impl は code コミットのみ）
- `.import` ファイルは生成されたら即コミット（PNG と同タイミング）
- `--no-verify` / `--amend` 禁止。hook が通らない場合は原因を調べる

---

## Impl コミット一覧（P3-A-005 以降）

### 済み（fc2dcbc まで）

| コミット | Task | 内容 |
|---|---|---|
| fc2dcbc | P3-A-005 | 王都跡通常敵 4 種スプライト接続（EC-3 完走） |
| 54c2467 | P3-A-004 | ボス AnimatedSprite2D フレームワーク実装 |
| 0690e85 | P3-A-003 | 王都跡タイルアート表示（EC-6） |
| d35bc8b | P3-A-002 | 装備 UI にアイコン表示（EC-4 / EC-5） |
| 7c82d75 | P3-A-Prep-Icons | ICON_MAP 経由パス解決に修正 |
| a6164d7 | P3-A-Prep-Icons | IconPaths static クラス追加 |
| d804139 | P3-A-001b | 残り 5 シーンに UI_BG_Dark 全画面背景追加 |
| 7cfe5d1 | P3-A-001 | production_theme.tres 導入・全画面背景追加 |
| e1b12a6 | P3-Prep-002 | dungeon/weapon discovery フック |

### 未コミット — Impl 責務

以下を下記の順でコミットする。

#### コミット 1: P3-A-007 コードおよび SpriteFrames

```
P3-A-007: 白骸墓地通常敵 5 種スプライト接続（EC-8 向け）
```

対象ファイル:
- `scripts/dungeon/DungeonScene.gd`（ENEMY_SPRITE_MAP に 5 エントリ追加）
- `resources/animation/ENM_BoneWalker.tres`
- `resources/animation/ENM_GraveBat.tres`
- `resources/animation/ENM_HollowGravedigger.tres`
- `resources/animation/ENM_PaleHound.tres`
- `resources/animation/ENM_OssuaryKnight.tres`

> **注:** batch5 PNG の `.import` は Godot Editor 初回起動後に生成される。生成後に追加コミットを作る。

#### コミット 2: P3-Prep ドキュメント同期

```
P3-Prep-003/005/008: CODEMAP・Task Index・AssetPipeline 同期
```

対象ファイル:
- `docs/specs/implementation/CODEMAP.md`
- `docs/specs/implementation/11_TASK_INDEX.md`
- `docs/specs/implementation/12_AssetPipeline.md`

#### コミット 3: P3-Prep 設計文書

```
P3-Prep-004/006/007: CommitPlan / OD-UI-001 / Batch 6+7 発注書
```

対象ファイル:
- `docs/project/CommitPlan_Phase3A.md`
- `docs/project/Proposal/OD-UI-001_Gap_Analysis_v1.0.md`
- `docs/archives/ArtArchive/Proposal/Pixel_Apprentice_Batch6_Request_v1.0.md`
- `docs/archives/ArtArchive/Proposal/Pixel_Apprentice_Batch7_Request_v1.0.md`

### 未コミット — HQ 責務

以下は HQ セッション（Cursor）が管理する。Impl は手を出さない:

| ファイルグループ | タイミング |
|---|---|
| `docs/specs/` 各ファイル（多数更新中） | ProjectDocs マイルストーン完了時 |
| `resources/enemies/*.tres`（パラメータ更新） | HQ 確認後 |
| `CLAUDE.md`, `README.md`, `.gitignore` | HQ 裁量 |
| `resources/dungeons/royal_ruins.tres` | HQ 確認後 |

---

## 今後のコミット予測

| 予定タイミング | Task | 内容 |
|---|---|---|
| Batch 6 納品後 | P3-A-006 | VFX AnimatedSprite2D 接続（EC-7） |
| Batch 5 import 後 | — | batch5 `.import` ファイル追加 |
| Batch 7 納品後 | P3-A-007 Tile | 白骸墓地 Tileset 接続 |
| Batch 7 納品後 | P3-A-008 | 冒険者 CHR スプライト接続 |
| EC-1〜7 PASS 後 | P3-A-009 | Closeout（HQ と協同） |

---

## 禁止事項

- `git push --force` は HQ 承認なしに禁止
- HQ 管理ファイルを Impl がコミットしない
- `assets/` 内の PNG を Impl が単独追加しない（PA 納品物は HQ 管理）
