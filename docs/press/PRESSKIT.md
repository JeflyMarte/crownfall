# プレスキット 構成手順

> Google Drive にフォルダを作り、**「リンクを知っている全員が閲覧可」**にして共有 URL をプレス文書に貼る。
> ZIP 版も同梱すると親切（記者が一括 DL できる）。

---

## フォルダ構成

```
Crownfall_PressKit/
├─ README.txt                  ← ファクトシートのテキスト版（下記）
├─ Crownfall_PressRelease.pdf  ← RELEASE_B の PDF
├─ logo/
│   ├─ AppIcon_1024.png
│   └─ Crownfall_Logo.png      ← 【要作成】背景透過ロゴ
├─ screenshots/
│   └─ 01〜10（下表）
├─ gif/
│   ├─ combat_auto.gif         ← 【要作成】自動戦闘 5秒
│   └─ legend_drop.gif         ← 【要作成】レジェンド演出 3秒
└─ video/
    └─ Crownfall_Trailer.mp4   ← 【要作成】TRAILER_60s.md 参照
```

---

## スクリーンショット 10 枚（既存流用）

記者が記事に貼るのは 3〜5 枚。**多すぎると選べないので 10 枚に絞る。**
番号順に「何のゲームか分かる」流れになるよう並べる。

| # | ファイル名（配布時） | 元ファイル | 意図 |
|---|---|---|---|
| 01 | `01_title.png` | 【要撮影】タイトル画面 | 一枚目に必ず必要 |
| 02 | `02_hub.png` | 【要撮影】拠点ホーム | 「準備する場所」が伝わる |
| 03 | `03_dungeon_select.png` | `note06_shots/abyss_select.png` または【要撮影】メインダンジョン選択 | 潜る先を選ぶ画面 |
| 04 | `04_combat.png` | `note04_shots/combat_mid.png` | **最重要。自動戦闘の画** |
| 05 | `05_boss.png` | `note09_shots/boss_combat_serdion.png` | ボス戦の派手さ |
| 06 | `06_boss_intro.png` | `note09_shots/boss_intro_valgard.png` | 登場演出のカットイン |
| 07 | `07_result.png` | `note04_shots/result_mvp.png` | 結果画面・MVP |
| 08 | `08_equipment.png` | `note05_shots/equip_silent_rite.png` | 装備の作り込み |
| 09 | `09_blacksmith.png` | `note05_shots/blacksmith.png` | 鍛冶＝成長システム |
| 10 | `10_codex.png` | `note09_shots/codex_serdion.png` | 生態図鑑＝世界観の売り |

### 撮り直しが必要なもの

- **01 タイトル画面**・**02 拠点ホーム**・**03 メインダンジョン選択** は既存 shots に無い
- いずれも実機（またはエディタ）で 720×1280 のまま撮る。デバッグ表示・仮テキストが写り込んでいないか確認

### 加工ルール

- リサイズしない（720×1280 のまま）
- 枠・影・端末モックを付けない（記者側で加工するため素の方が使われやすい）
- 日本語 UI のまま。ぼかし・モザイクは入れない

---

## README.txt の内容

`FACTSHEET.md` から下記だけを抜き出してプレーンテキストで置く。

- タイトル / ジャンル / 対応機種 / 価格 / 対応言語 / 配信日 / 開発者
- 3 行ピッチ
- 特徴 5 点
- App Store URL、Wiki、note、問い合わせ先
- 「スクリーンショット・動画は記事内で自由に使用可」の一文（**これを書いておくと使ってもらえる確率が上がる**）

### 使用許諾の文例

```
本プレスキットに含まれる画像・動画は、Crownfallの紹介記事・動画において
自由にご使用いただけます。使用にあたっての事前連絡は不要です。
出典表記は任意ですが、記載いただける場合は「(C) KOKI HONDA」でお願いします。
```

---

## GIF の作り方（記者が最も欲しがる素材）

X への引用と記事内埋め込みで最も効くのが 3〜6 秒の GIF。以下を用意する。

1. **自動戦闘 GIF（5 秒）** — パーティ 4 人＋ペットが自動で敵の群れを削る。ダメージ数字と状態異常アイコンが動いているところ
2. **レジェンドドロップ GIF（3 秒）** — 金の演出が出る瞬間

実機録画 → `ffmpeg` で切り出し：

```bash
ffmpeg -i input.mov -ss 00:00:12 -t 5 -vf "fps=15,scale=480:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" -loop 0 combat_auto.gif
```

ファイルサイズは 5MB 以下を目安に（超えると X で動かない）。
