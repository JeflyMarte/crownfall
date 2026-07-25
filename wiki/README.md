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

想定URL: **https://jeflymarte.github.io/crownfall/**

### いまの公開方式（稼働）

静的サイトは **`gh-pages` ブランチ** に載せる方式。

```bash
cd wiki
source .venv/bin/activate
mkdocs gh-deploy --force
```

### 初回だけ（リポジトリ設定）

1. GitHub → リポジトリ **Settings** → **Pages**
2. **Build and deployment → Source** を **Deploy from a branch**
3. Branch: **`gh-pages`** / folder: **`/ (root)`** → Save

（Actions 用 Workflow ファイルはローカルに用意済みだが、PAT に `workflow` 権限が無いと push できない。Actions 運用に切り替えるときは権限付きトークンで `.github/workflows/wiki-pages.yml` を push し、Source を GitHub Actions に変更）

### 検索に載せるには

公開後、Google Search Console 等へ URL を登録し、公式サイト／SNS／ストア説明からリンクすると見つけてもらいやすい。

## データページの再生成

ゲームの `.tres` から数値ページを更新する:

```bash
python3 generate.py
```

手書きの `docs/guide/`・`docs/world/` は上書きされない。
