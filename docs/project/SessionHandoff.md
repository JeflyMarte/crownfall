# Session Handoff — Cursor HQ

**Updated:** 2026-07-01（Alpha 戦術/探索拡張レーン D120〜132）
**ProjectDocs:** v3.6.0
**Branch:** `cursor/alpha-combat-formation-ui`（`main` より ahead 多数・未 push 想定）

---

## 1. 一言サマリー

モーンゲート1本・Combat v1.0 完了。Alpha 拡張（マーキング/ガンビット/装備プリセット/図鑑方針/4人バランス）を D120〜132 まで消化。**実機確認（P3-ALPHA-003）は Defer** — 暫定ゲート＝`tools/smoke_test.sh` PASS。

---

## 2. 直近完了（Impl）

| ID | 内容 |
|---|---|
| P3-D120〜128 | マーキング・E1装備プリセット・G1バランス・A1ガンビット・Result差別化・A2/D2 |
| P3-D129〜132 | 方針ヒント・チェックリストv2.1・Result方針/素材・DG選択方針表示 |
| P3-ALPHA-003b | 実機 Defer・headless Closeout |

---

## 3. 次候補

| 優先 | 内容 |
|---|---|
| — | Phase 3-A ポリッシュ（オーナー作画: 残ジョブドット絵） |
| — | Backlog 小タスク（Decision 要・本格システムは Defer） |
| 任意 | ブランチ `main` へのマージ判断（オーナー） |

---

## 4. 検証

```bash
bash tools/smoke_test.sh
```

実機は `docs/project/AlphaPlaytest_Checklist.md` v2.1（未記入 GO/NO-GO）。

---

## 5. SSOT

`docs/project/CurrentState.md` / `docs/specs/core/03_Decision_Log.md`
