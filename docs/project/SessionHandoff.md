# Session Handoff — Cursor HQ

**Updated:** 2026-07-01（P3-ALPHA-005 ブランチ `main` マージ）
**ProjectDocs:** v3.6.0
**Branch:** `main`（`cursor/alpha-combat-formation-ui` マージ済）

---

## 1. 一言サマリー

Alpha Combat Formation 拡張（P3-D120〜133）を `main` に統合。Combat v1.0 + 準備ループ（作戦プリセット/ガンビット/探索方針/Result強化）完了。**実機確認は Defer** — `smoke_test.sh` PASS。

---

## 2. 直近完了

| 領域 | 内容 |
|---|---|
| 戦術 | A1 ガンビット / A2 条件拡張 / A3 マーキング |
| 準備 | E1 装備プリセット / G1 4人バランス / 方針ヒント |
| 帰還 | D123 Result差別化 / D130〜133 方針・素材・天候 |
| 運用 | P3-ALPHA-003b headless / P3-ALPHA-005 main マージ |

---

## 3. 次候補（実装順序 HQ 確定）

`CurrentState.md` → **Next Implementation Queue** 参照。

| 順 | 内容 |
|---|---|
| 0 | 実機チェック（可能時） |
| 1–2 | vanguard / beast_tamer スプライト |
| 3–5 | D134 競合トースト → D135 Result素材UI → D136 鍛冶復活 |
| 6–8 | ranger/alchemist 作画 → ガンビット UI 1点 → 環境アート |

---

## 4. 検証

```bash
bash tools/smoke_test.sh
```

---

## 5. SSOT

`docs/project/CurrentState.md` / `docs/specs/core/03_Decision_Log.md`
