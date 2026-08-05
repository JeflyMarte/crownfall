# P3-BETA-QA-001 — 夜間バグチェック Closeout（2026-08-05）

**枠:** P3-BETA-QA-001  
**スコープ:** メイン①〜⑤ノーマル / P0＋P1  
**手法:** Agent C（GUT/smoke/pitfalls）先行 → A（戦闘）・B（拠点）並行 / リーダー合流  
**依頼文:** [`NightlyBugCheck_AgentPrompts_2026-08-05.md`](NightlyBugCheck_AgentPrompts_2026-08-05.md)

---

## 自動結果

| 項目 | 結果 |
|---|---|
| smoke_test.sh | PASS |
| GUT（修正前） | 1393 tests / **10 failing** |
| GUT（修正後） | **1394 Passing / 0 failing**（smoke PASS） |
| 主要シーン headless load | Boot/Dungeon/Equipment/Roster/Forge/Gacha/Codex/Result/Survey/Showcase/Settings **OK**（BaseScene は子 preload 警告のみ・単体 OK） |
| `SUB_DUNGEONS_PLAYABLE` | `false` 維持 |
| `JOB_EVOLUTION_PLAYABLE` | `false` 維持 |

---

## 発見票仕分け

### P0（出荷止め）— 本セッションで修正

なし（セーブ no-op 失敗はテスト汚染。本番 `load_game` はファイル無しで GameState 非破壊）

### P1（修正済）

| ID | 内容 | 処置 |
|---|---|---|
| QA-N1 | `ScrollTouchHelper._refresh_once` の型付き `call_deferred` → Object convert エラー（装備一覧シート等） | `instance_id` 経由に変更。`ui-layout` / `known-pitfalls` 追記 |
| QA-N2 | （調査のみ）イベント裂け目は closing=boss が正。`test_event_dungeon_stages` が誤って without_boss を要求 | テストを裂け目=boss／他=exit に更新 |

### 許容候補（テスト陳腐化・仕様追従）— 修正済

| 内容 | 処置 |
|---|---|
| `grant_self_evasion` が監査リスト未登録 | KNOWN_PASSIVE_EFFECTS に追加（実装は既にある） |
| ヴァルデン ATK 210→254 | ボス案A横展開に合わせテスト更新 |
| `boss_decree_wave` power 0.6→2.0 | ボス重技アライメントに合わせテスト更新 |
| ニーナ日課文言「お礼」系 | アサーション緩和 |
| 鍛冶 COMMON gold 40→80 | craft hint テストを HEAVY コストに追従 |
| 沈黙クリアテストが空パーティ | start 前にスターター解放 |
| SaveManager テストの `user://` remove 失敗 | `delete_normal_save` API 使用 |
| 防具 Gold 率テストが他装備・許可ブースト混入 | 武防飾＋commander をクリアして隔離 |

### オーナー実機に残すもの（エージェント外）

- ①〜⑤ノーマル通し（必殺・VFX・SE・セーブ復帰）
- 直近バランス感触（ボス圧・必殺100秒・治癒ナーフ・T6/T7）
- 拠点遷移ラグ体感（SceneRouter キャッシュ）
- iOS 実機ビルド／再インストール確認
- Hard/NM・無限（本スコープ外）

---

## 許容リスト（β出荷）

次は **βで許容**（P3-BETA-QA-001）:

1. wiki 配下の UID duplicate WARNING（site/docs 二重）— 起動非阻害
2. headless 終了時の ObjectDB/RID leak WARNING — 既往
3. GUT Pending: `test_boss_opening_aura_and_tempo_atk`（party unavailable in headless）
4. 寄り道／征討／ジョブ昇格のオミット継続（仕様）
5. バランス感触・文言 polish・見た目微調整（オーナー通し／別枠）

---

## エージェント分担実績

| Agent | 役割 | 状態 |
|---|---|---|
| C | smoke + GUT + omit + pitfalls | 完了（失敗10→修正） |
| A | 戦闘／DG 進行（コード監査＋シーン） | 並行実施・P0新規なし |
| B | 拠点／ScrollTouch／ナビ | ScrollTouch P1 を修正 |
| Leader | 仕分け・修正・Closeout | 本ドキュメント |

---

## 次アクション

1. GUT 全緑を確認したら統合＋main へ反映
2. オーナー実機通し（上記残）で β GO/NO-GO
3. 別チャット用プロンプトは再利用可（同ファイル）
