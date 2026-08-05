# 夜間バグチェック — Agent 依頼プロンプト（2026-08-05）

**枠:** P3-BETA-QA-001  
**スコープ:** メイン①〜⑤ノーマル / P0＋P1 のみ  
**リーダー:** 本セッション（発見票はリーダーへ戻す。仕様変更・バランス調整はしない）  
**ブランチ:** `cursor/sub-mac-ui-integration-cca2`（main 先端相当）

発見票フォーマット（必須）:

```
- Severity: P0 / P1 / 許容候補
- 再現: 画面→操作→結果（1〜3行）
- 証跡: ログ1行 or スクショ有無
- 推測原因: （短く）
- 修正提案: 領域のみ（勝手に直さない／仕様変更しない）
```

---

## Agent C — 自動化・セーブ・回帰（先行起動）

```text
あなたは Crownfall の QA Impl です。修正はせず、発見票のみ返す。

Task: P3-BETA-QA-001 / Agent C（自動化・セーブ・回帰）

Read:
- docs/project/CurrentState.md（Known Issues・直近更新）
- docs/project/CurrentSprint.md（βスコープ）
- .cursor/rules/pitfalls-startup.mdc
- .cursor/rules/known-pitfalls.mdc（按需）
- .cursor/skills/run-gut-tests/SKILL.md

Do:
1. `bash tools/smoke_test.sh` を実行し PASS/FAIL を記録
2. `bash tools/run_tests.sh`（GUT）を実行し件数と失敗を記録（基準: 以前 1240 PASS）
3. 主要シーンの headless instantiate（Boot / BaseScene / DungeonScene / Equipment / Roster / Forge / Gacha / Codex / Result 等）。SCRIPT ERROR・パース失敗を票化
4. セーブ往復: 新規開始キー・続きから・`saved_parties` 等の SaveManager/GameState 整合をコード監査（破壊的操作はしない）
5. βオミット確認: 寄り道／征討（SUB_DUNGEONS_PLAYABLE）、ジョブ昇格オミット等が誤解放していないか
6. pitfalls 再発スキャン: 外側 const＋ラムダ、`apply_body` on RichTextLabel、`maxf` 3引数、autoload 不正 uid 等の新規ヒット

Do NOT:
- コード修正・コミット・仕様変更
- バランス感触・文言polish・Hard/NM通し
- archives / Lore 全文読込

Done when:
- smoke + GUT 結果を報告（FAIL は発見票）
- セーブ／オミット／pitfalls の P0/P1 票（無ければ「該当なし」）
- 報告は発見票フォーマットのみ（長文禁止）
```

---

## Agent A — 戦闘・ダンジョン進行

```text
あなたは Crownfall の QA Impl です。修正はせず、発見票のみ返す。

Task: P3-BETA-QA-001 / Agent A（戦闘・ダンジョン進行）

Read:
- docs/project/CurrentState.md
- docs/project/CurrentSprint.md
- docs/specs/implementation/CODEMAP.md（Dungeon/Combat 周辺のみ）
- docs/specs/implementation/14_Presentation_Pitfalls.md
- .cursor/rules/pitfalls-startup.mdc

Do:
1. Boot→拠点→ダンジョン選択→メイン①〜⑤ノーマル各入場を確認（デバッグ解放／既存セーブ可）
2. 各 Biome で最低「入場→1戦闘→退場 or 結果」まで。可能ならボス／分かれ道／罠／碑文／宝箱／ペット／必殺も短く触る
3. 直近高リスク回帰を重点:
   - 冠呼び／途中召集クラッシュ
   - 敵全体攻撃フル威力
   - ボス圧横展開
   - 必殺チャージ全部屋100秒
   - T6/T7 減衰後ダメ表示
   - フロアバフ凡例
4. Godot MCP / headless / ログで SCRIPT ERROR・クラッシュ・進行停止を拾う

Do NOT:
- コード修正・コミット・仕様変更・バランス数値判定
- Hard/NM／無限フル通し
- 拠点メタ画面の深掘り（Agent B 担当）

Done when:
- ①〜⑤ノーマルの入場〜戦闘経路について P0/P1 票 or 「該当なし」
- 発見票フォーマットのみ
```

---

## Agent B — 拠点・メタ画面

```text
あなたは Crownfall の QA Impl です。修正はせず、発見票のみ返す。

Task: P3-BETA-QA-001 / Agent B（拠点・メタ画面）

Read:
- docs/project/CurrentState.md
- docs/project/CurrentSprint.md
- docs/specs/implementation/CODEMAP.md（Hub/UI 周辺のみ）
- .cursor/rules/ui-layout.mdc
- .cursor/rules/pitfalls-startup.mdc

Do:
1. 拠点下ナビ全画面往復（冒険／装備／編成／鍛冶／召喚／図鑑／調査／マイページ／設定）。黒画面・即死・ナビ壊れを票化
2. SceneRouter キャッシュ／読み込み中表示の破綻がないか
3. ScrollTouch が BaseButton を殺していないか（パーティ詳細など直近修正の回帰）
4. SafeArea・はみ出しによる操作不能／表示全滅
5. 直近高リスク: ギルド情報誌「いまの野外」見出し、展示室タブ、図鑑タブ
6. 主要シーン instantiate + 可能なら ui_audit / スクショ

Do NOT:
- コード修正・コミット・仕様変更
- 戦闘ラン深掘り（Agent A 担当）
- 見た目の微調整・文言polishをバグ扱いしない（表示全滅級のみ P1）

Done when:
- 拠点主要導線一周の P0/P1 票 or 「該当なし」
- 発見票フォーマットのみ
```
