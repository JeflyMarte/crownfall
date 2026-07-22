# Session Handoff — Cursor HQ / Impl

**Updated:** 2026-07-22  
**Branch（続き）:** `main`（今日の修正一括反映済）  
**統合:** `cursor/sub-mac-ui-integration-cca2`

---

## 1. 一言サマリー

本日分の未マージ PR（#58〜#69）を **統合＋`main` へ反映済み**。ローカルは `main` を pull して実機確認。

---

## 2. ローカル開始

```bash
git fetch origin
git checkout main
git pull origin main
```

---

## 3. 今日 main に入ったもの（抜粋）

| 領域 | 内容 |
|---|---|
| UX QA | 速度×1=1.0／×1.5、イントロ続行、未開「？」、状態異常ICO 等 |
| 加入 | スターター拠点セリフ→リビール（既存） |
| 調査室 | Phase1（派遣／SURVEY／②条件／実績タブ） |
| 他 | レジェンド落ち演出、装備長押し、MVPスコア隠、イベント章ICO、DEF/群れ、鍛冶オーバーレイ、クリアSE、Cursor一本化 |

---

## 4. 後続（ローカル推奨）

| 順 | 内容 |
|---|---|
| 1 | 実機通し（速度・加入・調査室・レジェンド落ち） |
| 2 | 調査室 UI polish／数値 |
| 3 | 問題があれば hotfix ブランチ |

---

## 5. 注意

- stash なし想定。ローカル未コミットがあれば先に退避／コミット
- 調査室の時間待ちは `hub_survey_cycle.start_unix` を過去にずらしてよい
