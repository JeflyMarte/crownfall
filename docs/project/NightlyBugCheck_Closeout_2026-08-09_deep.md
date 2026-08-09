# P3-BETA-QA-001 — 深掘り点検 Closeout（2026-08-09 night）

**枠:** P3-BETA-QA-001 続き（戦闘／拠点／セーブ）  
**スコープ:** P0＋P1  
**前回:** `NightlyBugCheck_Closeout_2026-08-09.md`（自動化・起動）

---

## 自動結果

| 項目 | 結果 |
|---|---|
| smoke（前回） | PASS |
| GUT | **1552 Passing / 0 failing** |
| 拠点14画面 headless | OK（警告のみ） |
| セーブ／調査／レリック／撃破ゲート unit | PASS |

---

## 発見→修正（本セッション）

### P0 — なし

### P1

| ID | 内容 | 処置 |
|---|---|---|
| QA-DEEP-1 | 死体再利用後、クローン召喚が **CD9999** で再発火不能 | `SkillExecutor.clear_cooldown_keys_with_prefix("enemy:N:")` を再利用時に実行 |
| QA-DEEP-2 | デバッグ生産：一覧は通るが確定／spawn が袋上限で失敗 | `BlacksmithScene` 確定・`try_add_*` に `debug_full_unlock` ignore |
| QA-DEEP-3 | 「はじめから」後に `saved_parties`／展示 id が残る | `reset_for_new_game` でクリア |
| QA-DEEP-4 | Continue／Debug「つづける」が reset なし load → 欠損キー汚染 | load 前に `reset_for_new_game` |
| QA-DEEP-5 | 調査室／図鑑の Scroll 内ボタンが `pressed` のみ | `_cf_keep_mouse_stop`＋STOP |
| QA-DEEP-6 | ギルド情報誌で下ナビ「ホーム」が誤活性 | `Tab.NONE` |
| QA-DEEP-7 | `test_boss_basic_dual_align` がエルディオン補強に未追随 | 期待値を例外化 |

---

## 許容／要実機

| 項目 | 備考 |
|---|---|
| Survey 即退室 await 警告 | 進行不能なし |
| T6/T7 テロップ docs 陳腐化 | Decision 準拠。docs は別枠 |
| 採取 `gather` room_types=[] | 報酬再有効化時の潜伏。今はオミット |

---

## オーナー実機に残すもの

1. クローン召喚→撃破→再利用スロットで再召喚
2. デバッグ開始→鍛冶で生産確定まで
3. はじめから後に編成プリセットが空
4. 調査室／図鑑のタッチ操作
5. ①〜⑤ノーマル通し

---

## 次

実機通しで β GO/NO-GO。
