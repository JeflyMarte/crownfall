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

想定URL: **https://crownfall-game.github.io/**

Org `crownfall-game` のユーザーサイト（リポジトリ `crownfall-game.github.io`）へ載せる。  
手順の正: [`GITHUB_PAGES_ORG.md`](GITHUB_PAGES_ORG.md)

### 公開（移行後）

```bash
cd wiki
source .venv/bin/activate
mkdocs gh-deploy --force --no-history --remote-name wiki-pages --remote-branch main
```

（初回は Org／空リポジトリ作成のあと、上記ドキュメントの remote 追加を行う）

### 旧方式（JeflyMarte/crownfall の gh-pages）

移行完了まで残っていてもよい。新URL運用開始後は旧 Pages を止めるか案内を出す。

### 検索に載せるには

公開後、Google Search Console 等へ URL を登録し、公式サイト／SNS／ストア説明からリンクすると見つけてもらいやすい。

## データページの再生成

ゲームの `.tres` から数値ページを更新する:

```bash
python3 generate.py
```

手書きの `docs/guide/`・`docs/world/` は上書きされない。
