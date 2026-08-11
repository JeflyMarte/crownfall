# 00_Operations — ソロ Godot 運用 SSOT

**対象:** PROJECT_NAME（ソロ・Cursor 一本化・Godot）  
**由来:** Crownfall 運用の蒸留（起動即死二層・修正即本線・文言同期・STOP）

---

## 1. 役割

| 役割 | 責務 |
|---|---|
| HQ | Scope / Decision / レビュー / Closeout / CurrentState 更新 |
| Impl | 指定 Task のみ実装。仕様独断変更禁止 |

ソロでも分ける。曖昧な指示は Impl せず HQ として確認する。

---

## 2. 修正完了の既定（セット）

オーナーが止めない限り、実装・修正完了は同じターンで:

1. コミット（必要なら feature push）
2. **本線（`main`）へマージ → push**
3. `CurrentState`（必要なら Decision／CODEMAP）更新
4. 該当する再発防止ルール／テスト更新

「GO 待ち」にしない。

| 例外（セットにしない） | 例 |
|---|---|
| オーナー明示 | 「マージしない」「レビューだけ」「WIP」 |
| STOP | 体験・面白さ・システム懸念／曖昧 |
| 壊れている WIP | 本線禁止。仮置きブランチ可 |
| Decision のみ | 仕様更新のみ。マージなし |

---

## 3. Closeout チェック

1. 変更が Task スコープ内か
2. 該当 spec / Decision と矛盾しないか
3. Exit Criteria（テスト・スモーク）を満たすか
4. Known Issues を悪化させていないか
5. プレイヤー文言／オミット案内が同期されているか（該当時）
6. 起動経路を触ったら headless で該当シーン確認

---

## 4. Decision

- バランス・進行・報酬・セーブ・オミット方針は Decision を残す
- 未承認の archives／雑談は実装根拠にしない
- Decision は短く（要旨・決定表・上書き対象）

---

## 5. WIP / stash

- 動いた大きい塊は **WIP コミット**（stash だけに依存しない）
- cloud／大きな退避の前後で `git status` と `stash list` を確認
- オーナー確認なしに `stash drop` しない

詳細: `.cursor/rules/git-wip-safety.mdc`

---

## 6. 再発防止

修正だけで終わらない。カタログ → ルール →（可能なら）テスト。  
詳細: `.cursor/rules/recurrence-prevention.mdc`
