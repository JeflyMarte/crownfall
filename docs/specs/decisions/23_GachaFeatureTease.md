# 招待状 Featured 煽り文左配置（P3-GACHA-FEATURE-TEASE-001）

**Status:** Decision 承認済（2026-07-28 オーナー GO）  
**上書き:** `P3-GACHA-FEATURE-BLURB-001` の「右ステ内・パッシブ上」配置

---

## 1. 方針

Featured の特徴文（`origin_note`）だけをキャラの**左**へ移し、文面を煽り調にする。  
名前／★／職／HP・ATK・DEF／固有パッシブ説明は**右のまま**。

---

## 2. 確定

| # | 項目 | 決定 |
|---|---|---|
| 1 | 左へ移すもの | `origin_note`（煽り文）のみ |
| 2 | 右に残すもの | 名前・★・職・HP/ATK/DEF・パッシブ説明 |
| 3 | 文面形式 | **本文のみ**・末尾 `！`（名前は右にあるため付けない） |
| 4 | データ | 既存 `origin_note` を煽り調へ改稿（新フィールドなし） |

---

## 3. 実装メモ

- `GachaUiHelper.build_featured_shell` — `FeatureBlurbWrap`（左）＋`StatsWrap`（右）
- ラインナップ副題も `origin_note` を表示（煽り文で統一可）
- `summon_quote` は各ヘルパーに既にあるため、加入セリフへのフォールバック影響は実質なし
