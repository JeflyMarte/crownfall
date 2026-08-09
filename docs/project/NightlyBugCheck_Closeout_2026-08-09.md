# P3-BETA-QA-001 — バグ点検 Closeout（2026-08-09）

**枠:** P3-BETA-QA-001（自主スコープ）  
**スコープ:** メイン①〜⑤ノーマル想定 / P0＋P1 / 自動化＋静的＋主要シーン  
**ブランチ:** `cursor/sub-mac-ui-integration-cca2`

---

## 方針

1. smoke + GUT（回帰の正）
2. 主要シーン headless instantiate
3. pitfalls 再発スキャン＋直近高リスク（召喚再利用・セーブ・撃破ゲート）
4. P0/P1 は同ターン修正。陳腐化テストは現行仕様へ追従

---

## 自動結果

| 項目 | 結果 |
|---|---|
| smoke_test.sh | PASS |
| GUT（修正前） | 1542 tests / **10 failing** / 1 pending |
| GUT（修正後） | **1545 Passing / 0 failing**（+召喚回帰1） |
| 主要シーン headless load | Boot〜StarterPick 等 21 件 OK |
| `SUB_DUNGEONS_PLAYABLE` | `false` 維持 |
| `JOB_EVOLUTION_PLAYABLE` | `false` 維持 |

---

## 発見票仕分け

### P0 — なし

### P1（本セッションで修正）

| ID | 内容 | 処置 |
|---|---|---|
| QA-0809-1 | 死体スロット再利用後、同種クローン召喚が不発（`slot:` 招集済フラグ残存） | 再利用時に `slot:` を erase。`skill:` は残す |
| QA-0809-2 | デバッグ全所持後に生産レシピが空（袋上限200超過で `can_craft` 拒否） | `debug_full_unlock` 時は袋チェックを ignore |

### ノイズ低減（許容→修正）

| ID | 内容 | 処置 |
|---|---|---|
| QA-0809-3 | BaseScene 日課で `unidentified.tres` 欠落 ERROR | 未鑑定 ID は weapon data load をスキップ |

### テスト陳腐化（修正済）

| 内容 | 処置 |
|---|---|
| WW D2 比率（moss_shell を D2 扱い） | moss_shell は danger=3。D2/D3 リスト更新 |
| glacier_warden HP 624→1650 | 名付き帯上げに追従 |
| ニーナ雨tips「降水」行 | `雨` or `降水` |
| 鍛冶 COMMON gold 80→120 | craft hint テスト追従 |
| fortune gold 隔離不足 | 他メンバー装備を隔離して +10% 検証 |
| moss_boar DEF 32→38 | 現行マスタ追従 |
| 味方 poison DoT×1.40 | `ENEMY_DOT_ON_PARTY_MULT` 込み期待値 |

### 許容（β据置）

1. wiki UID duplicate WARNING
2. headless 終了時 ObjectDB/RID leak
3. GUT Pending: `test_boss_opening_aura_and_tempo_atk`（party unavailable in headless）
4. Survey 即退室時の await resume 警告（`is_inside_tree` で安全 reverse・進行不能なし）
5. 寄り道／征討／ジョブ昇格オミット継続

---

## オーナー実機に残すもの

- ①〜⑤ノーマル通し（必殺・VFX・SE・セーブ復帰）
- 冠食い／苔イノシシ等のクローン召喚→死体再利用→再召喚
- デバッグ開始後の鍛冶生産
- iOS 再ビルド／再インストール（本セッション未実施）

---

## 次アクション

1. 統合＋main 反映（本 Closeout と同ターン）
2. オーナー実機通しで β GO/NO-GO
