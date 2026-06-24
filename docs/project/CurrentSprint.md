# CurrentSprint.md — Sprint Dashboard

---

## Sprint Name

Phase3-A — Visual Production（**Closeout 完了**）

---

## Goal

gameplay 変更なしで、見た目・UI・スプライトの production 基盤を整える（P3-D001）。  
**Closeout = EC-1〜7 全 PASS — 達成（2026-06-25）**

---

## 運用（P2-D177）

| 役割 | ツール | 並行 |
|---|---|---|
| DevelopmentHQ | **Cursor**（**白鳥 紗季**） | 1 |
| Implementation | **Claude Code** | **最大 2** |
| Visual Production | **Pixel Apprentice** | オーナー + Pixellab |

**16GB MacBook Air:** Godot 起動時は Claude Code **1〜2**。

### Claude Code キャラクター（HQ プロンプト必須）

**同時並行: 最大 2 台**（16GB MacBook Air + Godot 時は 1〜2）。3 台目は休憩。

| 呼び名 | 氏名 | 役割 | 性格・口調 |
|---|---|---|---|
| **美咲** | **彩川 美咲**（あやかわ みさき） | PA 支援 — 発注書・納品整理・アセット検証 | 丁寧・チェックリスト型。「サイズ・命名、確認しました」 |
| **遥** | **氷見 遥**（ひみ はるか） | Impl — メイン 1 | 落ち着いた先輩。「スコープ確認 → 実装 → 差分報告」 |
| **楓** | **早瀬 楓**（はやせ かえで） | Impl — メイン 2 | 手が早い実装者。報告簡潔。「N files / PASS / 懸念 1 点」 |
| **涼花** | **水無 涼花**（みなせ すずか） | 休憩 — メモリ対策 | **並行に含めない**。復帰時のみ割当 |

**HQ プロンプト形式:**

```
## 【氷見 遥】P3-A-006 VFX 接続

あなたは Crownfall 実装チームの氷見 遥です。
（キャラ定義は各 CC 起動時プロンプト参照）

Task: ...
```

PA → **彩川 美咲** / Impl 並行 → **氷見 遥** + **早瀬 楓** / 休憩 → **水無 涼花**

**キャラ定義 SSOT:** `docs/project/ClaudeCode_Characters.md`（紗季 + 美咲 / 遥 / 楓 / 涼花）

---

## Sprint 状態

| 項目 | 状態 |
|---|---|
| P3-D001〜007 | **承認済** |
| P0 Batch 1〜3 | **完了** |
| P1 Batch 4 — 王都跡 ENM 4 | **完了** |
| **P1 Batch 5** — 白骸墓地 ENM 5 | **完了**（assets/dungeon/graveyard/batch5/） |
| P1 Batch 6 — VFX | **完了**（assets/vfx/batch6/） |
| P1 Batch 7 G1 — Tileset + OBJ 3 体 + Missing Tiles 4 件 | **完了**（graveyard/batch7/） |
| P1 Batch 7 G2 — BOSS_Gravekeeper | **完了**（graveyard/batch7/） |
| P1 Batch 7 G3 — CHR Warrior/Guardian/Scout | **完了**（characters/batch7/） |
| P1 Batch 7 G4 — Icons × 9 | **完了**（ui/batch7/ + graveyard/batch7/） |
| Impl P3-A-001〜005 | **完了** |
| Impl P3-A-006 VFX 接続 | **完了** |
| Impl P3-A-007 ENM + Tile | **完了** `806d7fd` |
| Impl P3-A-008 CHR + Gravekeeper | **完了** `5fbad7e` |
| Impl P3-A-009 Closeout | **完了** |

---

## Claude Code Task

| 担当 | Task | 内容 | 状態 |
|---|---|---|---|
| **遥**（氷見 遥） | P3-A-006 | VFX 接続（EC-7） | **完了** |
| **楓**（早瀬 楓） | — | — | Phase3-A **完了** |
| **美咲**（彩川 美咲） | — | PA 支援 | Batch 7 **完了** |
| **涼花**（水無 涼花） | — | 休憩 | — |

---

## Pixel Apprentice — 次発注

### Batch 5（完了）

全 5 体納品済。`assets/dungeon/graveyard/batch5/`

### Batch 6（完了）

全 2 点納品済。`assets/vfx/batch6/`

### Batch 7（完了）

| Group | 内容 | 状態 |
|---|---|---|
| G1 | TILE_Graveyard_Wang_Sheet + OBJ × 3 + Missing Tiles 4 件 | **完了**（graveyard/batch7/） |
| G2 | BOSS_Gravekeeper_Sheet（1600×64, 25f） | **完了**（graveyard/batch7/） |
| G3 | CHR Warrior/Guardian/Scout（608×32, 19f） | **完了**（characters/batch7/）※Scout idle 3 dup |
| G4 | Icons × 9（ATK/DEF/CRT/ARM × 3/MAT × 4 + Tombstone Tile） | **完了**（ui/batch7/ + graveyard/batch7/） |

---

## Impl ロードマップ（Phase3-A 残）

| Task | 内容 | 依存 | EC |
|---|---|---|---|
| ~~P3-A-005~~ | 王都跡通常敵 | Batch 4 | EC-3 ✅ |
| **P3-A-006** | VFX | Batch 6 | EC-7 |
| P3-A-007 | 白骸墓地 Tile + 敵 | Batch 5 + Tile | EC-8 ✅（CHR/Boss 残） |
| P3-A-008 | CHR + Gravekeeper | Batch 7 G2/G3 | EC-8 |
| P3-A-009 | Closeout | EC-1〜7 | Milestone |

---

## HQ 次アクション

1. **OD-UI-001** モック寄せ方針 Decision
2. Phase3-B Scope / スプリント策定
3. 新 clone: `bash tools/smoke_test.sh --import-only`

---

## Notes

- ProjectDocs v3.5.45
- モック正: `docs/art/reference/UI_Reference_001.png` + `002.png` + **`003_01〜07`**
- 新 HQ チャット: `@SessionHandoff.md` + `@CurrentState.md`
- 命名: サフィックスなし・`ENM_BoneWalker_Sheet`・ICO 64×64
