# 図鑑歴史・断片の bake 同梱（P3-CODEX-HIST-BAKE-001）

**Status:** Decision 承認済（2026-07-29 バグ修正・オーナー報告対応）  
**関連:** `P3-CODEX-HIST-GUIDE-050`／`CatalogHelper`／`tools/bake_codex_bible.py`

---

## 1. 背景

図鑑「歴史」が実機で「（項目なし）」になっていた。  
原因は HE／LF 本文を `res://docs/specs/world/*.md` から `FileAccess` 直読みしており、**エクスポートに `docs/` が含まれない**ため。

手引き／世界観解説（`GuideCatalog.gd`）は GDScript 埋め込みのため実機でも生きていた。

---

## 2. 確定

| # | 項目 | 決定 |
|---|---|---|
| 1 | 実行時の正 | `resources/codex/history_entries.json`／`fragment_entries.json` |
| 2 | 編集の正（SSOT） | `docs/specs/world/01_History.md`／`12_Fragments.md` |
| 3 | 再生成 | `python3 tools/bake_codex_bible.py`（MD 更新後に必須） |
| 4 | フォールバック | bake 欠落時のみ Markdown（開発用）。実機は bake 必須 |
| 5 | starter 開示 | HE-001〜050 は従来どおり常時開示 |

---

## 3. 実装メモ

- `CatalogHelper._load_history_bible_entries`／`_load_fragment_entries` は bake 優先
- 歴史タブ自体はオミットしない（空はバグ）
- MD を直したら bake を再実行して JSON をコミットする
