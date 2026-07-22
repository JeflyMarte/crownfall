# Session Handoff — Cursor HQ / Impl

**Updated:** 2026-07-22  
**Branch（続き）:** `cursor/hub-survey-room-e010`  
**PR:** https://github.com/JeflyMarte/crownfall/pull/69  

---

## 1. 一言サマリー

調査室 Phase1（**P3-HUB-SURVEY-001**）をクラウドで実装済み・push 済み。ローカルで実機通し・UI polish・数値調整を続ける。作業ツリーはクリーン。

---

## 2. ローカル開始手順

```bash
git fetch origin
git checkout cursor/hub-survey-room-e010
git pull origin cursor/hub-survey-room-e010
```

関連（未マージなら別途）:
- Decision 単独: `cursor/decision-hub-survey-e010` (#67) — 本ブランチに統合済
- Cursor 一本化: `cursor/cursor-impl-only-e010` (#68) — 本ブランチに統合済

---

## 3. 直近完了（本ブランチ）

| 領域 | 内容 |
|---|---|
| 調査室 | `SurveyScene`・左メニュー導線・通常 BottomNav・背景／アイコン |
| SURVEY | 潜行クリア／ボス初回で加算。①≥70%＋クリアで②解禁 |
| 派遣 | 短20分／標準3時間・調査員配置・完了で素材／石／武器 |
| 図鑑 | 「実績」タブ骨格（埋め％マイルストーン） |
| Save | v10（`hub_survey_*`） |
| テスト | `test_hub_survey` 5/5・`test_dungeon_unlock` 7/7 |

SSOT: `docs/specs/decisions/05_HubSurveyRoom.md`

---

## 4. 後続（ローカル推奨）

| 順 | 内容 |
|---|---|
| 1 | **実機通し** — 左メニュー→調査室→短調査（時間スキップ可）→受取／潜行で SURVEY／②解放／図鑑実績 |
| 2 | **UI polish** — モック寄せ（カード密度・キーアート帯・報酬プレビュー・通貨チップ） |
| 3 | **数値調整** — Decision §10 仮値（時間・加算・ドロップ）を体感で直す |
| 4 | **欠け補強** — 資料一覧ポップ／ヘルプ／ニーナ台詞／派遣中編成UIの明示ロック表示 |
| 5 | **問題なければ** HQ が #69 を統合＋`main` へ |

やらない（Phase1 外）: 魔晶石枠拡張課金・調査室Lv本格・②コンテンツ磨き

---

## 5. 検証

```bash
godot4 --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit -gselect=test_hub_survey.gd -gexit
bash tools/smoke_test.sh
```

---

## 6. 注意

- stash なし・未コミットなし（2026-07-22 時点）
- 短調査の実機待ちは長いので、デバッグで `hub_survey_cycle.start_unix` を過去にずらす／仮数値を分単位に一時変更してよい
