# Crownfall 攻略Wiki — ローカル表示／公開

ゲームの攻略・データ・世界観を MkDocs Material で表示する。

## セットアップ（初回）

```bash
cd wiki
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## プレビュー

```bash
cd /Users/marte/Projects/crownfall/wiki
source .venv/bin/activate
mkdocs serve --dev-addr 127.0.0.1:8001
```

ブラウザで http://127.0.0.1:8001 を開く。

（`8000` は Godot AI サーバー等が使うことがあるので、Wiki は `8001` を推奨）

## 静的ビルド

```bash
mkdocs build
```

出力は `wiki/site/`（gitignore 対象）。

## GitHub Pages 公開

公開URL: **https://crownfall-game.github.io/**

### いまやること（Cloud Agent 公開）

手順の正（画面クリック単位）: [`GITHUB_PAGES_ORG.md`](GITHUB_PAGES_ORG.md)

要約:

1. GitHub で PAT を1つ作る（`crownfall-game.github.io` に Contents Write）
2. 同じ値を次の2か所に **`WIKI_PAGES_TOKEN`** として入れる  
   - Cursor 環境 Secrets  
   - https://github.com/JeflyMarte/crownfall/settings/secrets/actions
3. チャットで「デプロイ再実行」

### 手元から公開する場合

```bash
cd wiki
source .venv/bin/activate
mkdocs gh-deploy --force --no-history --remote-name wiki-pages --remote-branch main
```

（初回は `GITHUB_PAGES_ORG.md` の remote 追加を行う。デプロイ後は本体 `main` tip を `origin/main` に戻す）

### 検索に載せるには

公開後、Google Search Console 等へ URL を登録し、公式サイト／SNS／ストア説明からリンクすると見つけてもらいやすい。

## データページの再生成

ゲームの `.tres` から数値ページを更新する:

```bash
python3 generate.py
```

手書きの `docs/guide/`・`docs/world/` は上書きされない。
