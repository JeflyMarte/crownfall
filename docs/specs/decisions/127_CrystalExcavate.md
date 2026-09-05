# 魔晶石発掘（案A・日次）（P3-UX-CRYSTAL-EXCAVATE-001）

**Status:** Decision **承認済**（2026-08-25）／**Impl 済**（2026-09-01 — 選択→対石→結果・日課上入口・GUT・headless）
**実装:** 済（要実機）  
**上書き:** なし（新機能）  
**維持:** 既存ダンジョン戦闘・調査室・日課・ガチャ経済の本体は据置。発掘は別フロー

---

## 0. 一言

拠点から日に1回、隊員のスキルで岩を掘り、与ダメに応じて魔晶石を得る（上限 **300**）。必殺は使えない。

---

## 1. 確定方針

| # | 決定 |
|---|---|
| P3-UX-CRYSTAL-EXCAVATE-001-1 | **案A＝簡易発掘**。本編ダンジョン／調査派遣／実戦闘コントローラには乗せない |
| P3-UX-CRYSTAL-EXCAVATE-001-2 | **日次1回**。リセット境界は日課と同じ（`DailyMissionSystem` の day_key／5:00 JST） |
| P3-UX-CRYSTAL-EXCAVATE-001-3 | **報酬＝魔晶石のみ**（`GameState.gacha_token`）。Gold・素材・装備・EXP・図鑑進捗は出さない |
| P3-UX-CRYSTAL-EXCAVATE-001-4 | **1回あたりの硬上限＝300**。換算結果は必ず `clamp(..., 0, 300)` |
| P3-UX-CRYSTAL-EXCAVATE-001-5 | **必殺不可**。候補は `slot_type != "ultimate"` のみ |
| P3-UX-CRYSTAL-EXCAVATE-001-6 | **入口**＝拠点ホームで **ニーナ吹き出し下〜調査室上**の円形入口（`UI_Hub_CrystalExcavate`）。BottomNav 新タブは作らない。選択画面は `UI_CrystalExcavate_Select_Frame` 背景に操作のみ重ねる |
| P3-UX-CRYSTAL-EXCAVATE-001-9 | **初回ニーナガイド**（選択画面）。`tutorial_flags.crystal_excavate_nina_guide_done`。フレーム「？」で再表示可 |
| P3-UX-CRYSTAL-EXCAVATE-001-10 | **ダメージランキング**。発掘確定時に履歴へ追加（与ダメ降順・最大50件・セーブ v17）。結果画面／選択画面から遷移可。戻り先は呼び出し元 |
| P3-UX-CRYSTAL-EXCAVATE-001-12 | **拠点復帰チャリン**。発掘で付与した魔晶石は `pending_hub_fx_tokens` を経由し、拠点入場時に右上 TokenChip へ `CurrencyGainFx`＋数値カウントアップ |
| P3-UX-CRYSTAL-EXCAVATE-001-7 | **フロー**＝選択画面（キャラ＋スキル）→「発掘」→戦闘風画面（キャラ対石・ダメージ表示）→結果画面→拠点 |
| P3-UX-CRYSTAL-EXCAVATE-001-8 | 消費は「発掘」確定時（または戦闘開始直前）にその日の枠を埋める。途中離脱で枠を戻さない（再入は結果／済表示） |

### 破棄した案

| 破棄 | 理由 |
|---|---|
| 案B（複数掘り・ミニゲーム複雑化） | オーナー案A |
| 必殺チャージ／必殺ダメージ換算 | オーナー：必殺なし |
| 無制限／高キャップ | オーナー：上限300 |

---

## 2. 画面フロー（体験正）

```
拠点（発掘入口）
  → [選択] キャラ1人 ＋ スキル1本 ＋「発掘」ボタン
  → [戦闘風] キャラ vs 石。攻撃演出＋ダメージ数字
  → [結果] 獲得魔晶石（当日済なら再入場は済表示のみ）
  → 拠点
```

| 画面 | 要件 |
|---|---|
| 選択 | ロスターの冒険者（**ペット除外**）。スキルは装備中の非必殺を優先表示。未装備の習得スキルを出すかは Impl 判断可（必殺除外は必須） |
| 戦闘風 | 石はダミー敵。CT／ヘイト／部屋進行／実ドロップなし。必殺ゲージUIなし。軽量なヒット／ダメージ数字で十分 |
| 結果 | 付与量・残回数（0/1）・拠点へ戻る |

---

## 3. ダメージ→魔晶石（推奨換算）

硬制約は **上限300** のみ。以下は初回実装の推奨。桁が崩れる調律は Decision なしで可（上限維持）。

| 段階 | 式／帯 |
|---|---|
| 見込みダメ（選択） | 既存スキル威力プレビュー（装備・パッシブ込み）の中央値。石に対する1撃想定 |
| 確定ダメ | 中央値 × **一様乱数 [0.85, 1.15]**（±15%）。`CrystalExcavateDamageHelper.roll_damage` |
| 換算 | `tokens = clamp(int(round(dealt_damage * 0.08)), 1, 300)`（dealt>0）。0ダメは0 |
| 目安 | 弱〜中スキルで数十〜百台、強ビルドで天井付近。調査・クリア石と並ぶ日次枠として過大にしない |

実装は定数化（倍率・下限・上限）し、GUT で cap／日次1回を固定する。

---

## 4. セーブ

| キー | 内容 |
|---|---|
| `GameState.crystal_excavate_state`（仮名） | `{ "day_key": String, "used": bool, last_* }`。SaveManager 読書きを **同コミット** |
| `GameState.crystal_excavate_history` | ランキング用配列（セーブ v17+）。日次リセットでは消さない |

`day_key` 不一致なら未使用に戻す（日課と同様）。

---

## 5. 非対象・禁止

- 本編 `DungeonScene`／`DungeonController` への相乗り
- 必殺スロット・必殺チャージ演出
- 日次枠のデバッグ以外での無制限掘り（本番）
- 入口を BottomNav 5タブへ追加すること

---

## 6. SSOT／実装メモ

- Decision 本体＝本ファイル
- 入口配線＝`BaseScene`（`DailyMissionPanel` 近傍）
- シーン案＝`scenes/excavate/`（Select／Combat／Result）＋専用 System／Helper
- CODEMAP・必要なら手引き1行は Impl 時

---

## 7. Exit Criteria（Impl）

1. 日課隣から入れる。済の日は再掘り不可
2. 必殺が選べない／使えない
3. 選択→戦闘風（ダメ表示）→結果→拠点
4. 付与魔晶石 ≤300、セーブ復帰後も day_key が正しければ used 維持
5. GUT：換算 cap・日次1回・必殺除外
6. headless で選択／戦闘風シーン instantiate
