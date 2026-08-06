# YouTube解説動画 — ゆっくり／VOICEVOX（動画知識ゼロ向け）

**方針:** 実況ではなく「ゆっくり風ナレでCrownfallを解説」。結月ゆかりは使わない。  
**目標:** 作業の大半を Cursor がやる。あなたは「アプリを入れる／起動する／YouTubeにログインして公開ボタン」だけ。

Wiki: https://crownfall-game.github.io/

関連: 台本 `youtube_ep01_script.md` ／ **文体メモ `YOUTUBE_VOICE.md`** ／ 音声スクリプト `../../tools/voicevox_synth.py`

---

## Cursor ができること／あなたがやること

| 工程 | Cursor | あなた |
|---|---|---|
| 台本 | ✅ 書く・直す | 読んで「OK／直して」だけ |
| 音声（VOICEVOX） | ✅ APIでWAV生成（アプリ起動中なら） | VOICEVOXを **インストール＆起動**（初回だけ） |
| ゲーム映像 | ✅ Godot自動撮影→mp4（`tools/yt_ep01_footage_runner.gd`） | 手動録画も可（QuickTime） |
| 字幕・タイトル・説明文 | ✅ 用意 | コピペでも可 |
| YouTube投稿 | 下書き文面まで ✅／ブラウザ操作は補助可 | **チャンネル作成・公開ボタン**は本人必須 |

「全部自動でYouTubeに勝手に公開」までは、アカウント権限の都合でできません。それ以外はかなり任せられます。

---

## 全体の流れ

```
① VOICEVOX インストール＆起動（あなた・一度だけ）
 → ② 台本（Cursor）
 → ③ 音声WAV一括生成（Cursor）
 → ④ 画面クリップ用意（あなた・短時間）
 → ⑤ 動画組み立て（Cursor + ffmpeg）
 → ⑥ YouTube（あなたが公開／Cursorが文面）
```

---

## ① VOICEVOX を入れる（あなた・15分）

1. 公式: https://voicevox.hiroshiba.jp/  
2. Mac用をダウンロードしてインストール  
3. アプリを起動したままにする（裏で `localhost:50021` が動く）  
4. キャラはとりあえず **ずんだもん** か **四国めたん** でOK（後から変更可）

確認（Cursor側でも可）:

- ブラウザで http://localhost:50021/docs が開けば成功  

利用規約・クレジット表記は公式の案内に従う（説明欄に「VOICEVOX」と話者名を書くのが無難）。

---

## ② 台本（Cursor）

第1本: **「Crownfallってどんなゲーム？」**（6分前後）

- ファイル: `docs/devlog/youtube_ep01_script.md`  
- 口調: ゆっくり解説っぽい丁寧＋少しゆるい（Noteの熱量口調とは分ける）  
- 各ブロックに「画面指示」と「読み上げ文」を分ける  

「台本直して」と言えば直します。

---

## ③ 音声を一括生成（Cursor）

VOICEVOX 起動中に、リポジトリのスクリプトでWAVを出します。

```bash
# 例（話者IDは環境で異なる。ずんだもんノーマルはよく 3）
python3 tools/voicevox_synth.py \
  --script docs/devlog/youtube_ep01_script.md \
  --out docs/devlog/yt_ep01/voice \
  --speaker 3
```

出力: `docs/devlog/yt_ep01/voice/01_*.wav` …

声が気に入らなければ `--speaker` を変えるだけ（Cursorに「めたんにして」で可）。

---

## ④ 画面クリップ — **音声先行・1文=1ショット（標準）**

### 同期の正（第2回以降の標準）

| ❌ やってはいけない | ✅ やること |
|---|---|
| セクション（数十秒）に1クリップを割り当ててループ／切断 | **音声 manifest のキュー秒数どおり**に画面を撮る |
| 「尺だけ合わせればOK」と思って総尺だけ検算する | **中身の一致**をサンプル時刻で検算する（テロップ文言＝画面） |
| セクションアセンブラ（`yt_ep02_assemble.py` 旧方式）で本番を出す | ショット駆動ランナーで通し撮影し、テロップ焼き込みだけする |

第2回で「動画と音声が全く合っていない」と感じた原因は、音声の尺ズレではなく **画面の粒度不足**だった（音声は114文／映像は8セクションのループ）。

### Cursor 自動（推奨・ep02）

```bash
# 1) 音声（文単位 manifest）
python3 tools/voicevox_synth.py \
  --script docs/devlog/youtube_ep02_script.md \
  --out docs/devlog/yt_ep02/voice --speed 1.0

# 2) 音声秒数どおりに画面を通し撮り（Movie Maker・約4分）
Godot.app --path . \
  --write-movie docs/devlog/yt_ep02/footage/ep02_shots.avi \
  --fixed-fps 30 --disable-vsync \
  -s res://tools/yt_ep02_shot_runner.gd

# 3) silent mp4 → テロップ＋音声焼き込み
#    （AVI→silent は ffmpeg。焼き込みは yt_ep02_burn_yukkuri.py）
python3 tools/yt_ep02_burn_yukkuri.py
# → docs/devlog/yt_ep02/export/crownfall_ep02_yukkuri.mp4
```

ショット表は `tools/yt_ep02_shot_runner.gd` の `SHOTS`。台本の文と画面を1対1で対応させる。  
ランナーは累積フレームで音声総尺に追い込む（各ショットの超過は次で吸収、総尺は音声と一致）。

### 検算（必須）

撮影後に、以前ズレていた時刻などでフレームを抜いて確認する。

| 確認 | 合格条件 |
|---|---|
| 総尺 | silent / yukkuri / narration が ±0.05s 以内 |
| 累積ドリフト | ランナーログの `cum_drift` が終端で 0 |
| 中身 | サンプル時刻でテロップ文言と画面が対応（例: 「結果の入手装備…」→結果画面） |

### 通し撮影（映像先行）を使う場合

ダンジョン通し解説のように、映像が主でナレを後付けするときは映像先行でもよい。  
（第3回本編は案Cのため **音声先行**。通し撮影は素材用途に限る）  
その場合は **台本の秒数を映像に合わせる**（音声の秒数に映像をループで合わせない）。

### 手動（QuickTime・例外）

編集ソフトを覚えなくてよいよう、**素材だけ**用意する経路も残す。ただし本番同期は上記ショット駆動を優先。

---

## ⑤ 動画組み立て（Cursor）

```bash
# ep01 例（初回）
python3 tools/voicevox_synth.py --script docs/devlog/youtube_ep01_script.md --out docs/devlog/yt_ep01/voice --speed 1.0
Godot.app --path . -s res://tools/yt_ep01_footage_runner.gd
python3 tools/yt_ep01_assemble.py
python3 tools/yt_ep01_burn_yukkuri.py
# → docs/devlog/yt_ep01/export/crownfall_ep01_yukkuri.mp4

# ep02 以降（標準）: ショット通し撮り → burn のみ（セクションループ組み立て禁止）
```

立ち絵は公式配布（`docs/devlog/yt_ep01/assets/zundamon/`・ATTRIBUTION参照）。収益化時は商用可否を再確認。

字幕は焼き込み（`yt_ep*_burn_yukkuri.py`）を標準とする。

---

## ⑥ YouTube（あなたが最後だけ）

1. https://studio.youtube.com/ にログイン  
2. チャンネルが無ければ作成（初回ウィザード）  
3. アップロード → `crownfall_ep01.mp4`  
4. タイトル／説明は Cursor が書いた文を貼る  
5. まず **限定公開** で自分だけ確認 → OKなら **公開**

### タイトル例

```text
【ゆっくり解説】自分では殴らないハクスラ『Crownfall』ってどんなゲーム？
```

### 説明欄例

```text
自動探索ハクスラRPG『Crownfall』の紹介です。
プレイヤーは指揮官で、自分では戦いません。

攻略Wiki: https://crownfall-game.github.io/

VOICEVOX: （使用した話者名）

#Crownfall #ゆっくり解説 #インディーゲーム
```

---

## よくある質問

**Q. 本当にゆっくり霊夢・魔理沙じゃなくていい？**  
A. 初回は VOICEVOX で十分。「ゆっくり解説」の型（ゆっくりした解説ナレ）を踏襲します。東方立ち絵にこだわる場合は別途素材と規約確認が必要です。

**Q. CapCutは必須？**  
A. 不要ルートを用意しています。見た目を凝らしたくなったら後からCapCutでも可。

**Q. ゆかり手順書は？**  
A. `YOUTUBE_YUKARI_GUIDE.md` は保留。今は本ファイルが正。

---

## いまやること（あなた）

1. VOICEVOX を入れて起動する  
2. 「VOICEVOX起動した」と Cursor に送る  

→ こちらで台本確定・音声生成・次の指示（録画4本）まで進める。
