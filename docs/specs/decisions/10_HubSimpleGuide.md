# 拠点初回簡易ガイド（P3-UI-HUB-GUIDE-001）

**Status:** Decision 承認済（2026-07-26 オーナー指定／同日 6P・ジャック支給・魔晶石演出追記）  
**上書き:** `02_NewGameIntro` の「操作講習なし」は維持。本ガイドは **何からやるか** のみ。

---

## 1. 方針

- 「はじめから」後、**初回の拠点ホーム**でのみ表示
- 画面遷移せず、**メニュー（拠点）の上に大きめポップ**
- 案内役は記録官ニーナ。右下にドット絵（`SPR_NPC_Nina`）
- 各トピック **1ページ**（全6ページ）。スキップ可

---

## 2. ページ（確定）

| # | 内容 |
|---|---|
| 1 | まずガチャ（招待状）を引いて仲間を集める |
| 2 | ダンジョンへ潜ってレア装備を手に入れ、レベルアップ |
| 3 | 調査室でダンジョンを研究。報酬もある |
| 4 | 鍛冶屋で武器をさらに強くする |
| 5 | 展示室でキャラを自慢する |
| 6 | ギルドから新人調査隊サポートとしてペット「ジャック」支給 |

---

## 3. ガイド完了後の儀式（同セッション）

1. **ジャック加入演出**（`StarterJoinOverlay`・ガチャ同型。セリフは犬の鳴き声）
2. **魔晶石 500** を TopBar へ飛込（`CurrencyGainFx`）。`GachaSystem.STARTING_TOKENS`

| 項目 | 値 |
|---|---|
| ガイド終了まで魔晶石 | **0**（`reset_for_new_game`） |
| ジャック所持 | ガイド完了＋加入演出まで無し（`starter_pet_granted`） |
| トークン二重防止 | `tutorial_flags.hub_starting_tokens_granted` |

---

## 4. 表示条件

| 項目 | 値 |
|---|---|
| フラグ | `GameState.tutorial_flags.hub_simple_guide_done` |
| セーブ | `tutorial_flags` を永続化（Save v13） |
| 既存セーブ | マイグレーションで **済み扱い**（Continue では出さない）＋支給済み扱いへ heal |
| 新規 | `reset_for_new_game` で flags クリア → 初回拠点で表示 |
| 優先 | 解放通知／等級アップ／スターター加入の後 |
| デバッグ再演 | **preview のみ**。済みフラグは消さない／セーブしない／支給しない |
| 修復 | 進行済み（`stage_progress` あり）なのにフラグ欠落なら load 時に済みへ |

---

## 5. スコープ外

- 施設への強制遷移・ハイライトツアー
- 戦闘／属性／CT の操作講習
- 設定からの「もう一度見る」（必要なら後続）

---

## 6. 実装

- `scripts/ui/HubSimpleGuideOverlay.gd`
- `scripts/base/BaseScene.gd`（ガイド → ジャック → 魔晶石）
- `scripts/pets/PetSystem.gd`（`grant_starter_pet` / `starter_pet_granted`）
- 接続: `BaseScene`（他オーバーレイ消化後）
