# Wiki 公開先の移行（Org: crownfall-game）

目標URL: **https://crownfall-game.github.io/**

ゲーム本体リポジトリ（現状 `JeflyMarte/crownfall`）とは別に、  
**Org のユーザーサイト用リポジトリ**へ静的サイトだけ載せる。

---

## あなたがやること（ブラウザ・一度だけ）

### 1. Organization 作成

1. https://github.com/organizations/plan を開く（Free で可）
2. Organization account name: **`crownfall-game`**
3. Contact email を入れて作成

### 2. Pages 用リポジトリ作成

1. Org `crownfall-game` で **New repository**
2. Repository name: **`crownfall-game.github.io`**（この名前が必須）
3. Public
4. README なし（空でOK）で Create

### 3. 権限

自分の個人アカウントが Org の Owner（またはリポジトリ Write）であることを確認。

完了したら Cursor に「Org 作った」と返す。こちらで初回デプロイする。

---

## Cursor / ローカル側（初回デプロイ）

前提: `wiki/` の venv と mkdocs 済み。`site_url` は既に新URLへ更新済み。

```bash
cd /Users/marte/Projects/crownfall/wiki
source .venv/bin/activate

# Pages 専用リモート（初回のみ）
git remote add wiki-pages https://github.com/crownfall-game/crownfall-game.github.io.git
# 既にある場合は URL だけ合わせる:
# git remote set-url wiki-pages https://github.com/crownfall-game/crownfall-game.github.io.git

mkdocs gh-deploy --force --no-history --remote-name wiki-pages --remote-branch main
```

※ Org サイトはブランチ **`main`** のルート配信が無難。  
※ 失敗したら GitHub → `crownfall-game.github.io` → Settings → Pages → Source: **Deploy from a branch** → Branch **main** / **/ (root)**

---

## 以降の更新

```bash
cd /Users/marte/Projects/crownfall/wiki
source .venv/bin/activate
# データ再生成が必要なら: python3 generate.py
mkdocs gh-deploy --force --no-history --remote-name wiki-pages --remote-branch main
```

---

## 旧URL

- ~~旧: https://jeflymarte.github.io/crownfall/~~ — **停止済**（`gh-pages` ブランチ削除・2026-07-26）
- 新: https://crownfall-game.github.io/

---

## 設定ファイルの正

| 項目 | 値 |
|---|---|
| Org | `crownfall-game` |
| Repo | `crownfall-game/crownfall-game.github.io` |
| site_url | `https://crownfall-game.github.io/` |
| ゲーム本体 | 当面 `JeflyMarte/crownfall` のまま可（Wikiソースは monorepo の `wiki/`） |
