# Wiki 公開デプロイ手順

公開URL: **https://crownfall-game.github.io/**  
公開先リポジトリ: **`crownfall-game/crownfall-game.github.io`**  
Wikiの原稿: ゲーム本体 `JeflyMarte/crownfall` の `wiki/` フォルダ

---

## いま必要なこと（トークン1つ）

Cloud Agent / GitHub Actions は、公開先リポジトリへ **書き込みできない**（403）。  
そのため **PAT（個人アクセストークン）** を1つ作り、2か所に同じ値を登録する。

完了したらチャットで **「デプロイ再実行」** と送る。

---

### Step A — GitHub でトークンを作る

1. ブラウザで開く: https://github.com/settings/tokens?type=beta  
   （classic でも可: https://github.com/settings/tokens ）
2. **Generate new token**
3. 名前例: `crownfall-wiki-pages`
4. 権限:
   - **おすすめ（fine-grained）**
     - Resource owner: **`crownfall-game`**
     - Repository access: **Only select** → `crownfall-game.github.io` だけ
     - Permissions → Repository → **Contents: Read and write**
   - **簡単（classic）**
     - スコープ **`repo`** にチェック（広くなるので本番用は fine-grained 推奨）
5. Generate したあと、表示された **`ghp_...` をすぐコピー**（再表示できない）

---

### Step B — Cursor 環境に入れる（エージェント即デプロイ用）

1. Cursor の Cloud Agent 環境設定を開く  
   （ダッシュボードのこの環境の Secrets）
2. シークレット名: **`WIKI_PAGES_TOKEN`**（この名前で固定）
3. 値: Step A でコピーした `ghp_...`
4. 保存

---

### Step C — GitHub Actions にも同じ値を入れる（main 更新で自動公開）

1. 開く: https://github.com/JeflyMarte/crownfall/settings/secrets/actions  
2. **New repository secret**
3. Name: **`WIKI_PAGES_TOKEN`**（同じ名前）
4. Secret: Step A と同じ `ghp_...`
5. Add secret

---

### Step D — こちらに返す

チャットに次のどちらか:

- **「デプロイ再実行」** → エージェントが今の Wiki を公開する  
- または main に `wiki/**` を push 済みなら、Actions の **Deploy Wiki** が自動で走る（C が済んでいれば成功する）

公開できたかの確認:

- https://crownfall-game.github.io/guide/beginner/  
- 「つつき介抱」「調査室を回す」など最新文言が見えればOK

---

## うまくいかないとき

| 症状 | 確認 |
|---|---|
| Actions が `WIKI_PAGES_TOKEN が未設定` | Step C の名前が完全一致か（大文字・アンダースコア） |
| 403 / Permission denied | Step A の Contents Write、対象リポが `crownfall-game.github.io` か |
| サイトが古い | デプロイ成功ログのあと数分待つ／ブラウザ強制更新 |
| Pages が真っ白 | `crownfall-game.github.io` → Settings → Pages → Branch **main** / **/(root)** |

---

## 手元 Mac だけで公開する場合（トークン不要・自分の Git ログイン）

```bash
cd /path/to/crownfall/wiki
source .venv/bin/activate   # 無ければ README のセットアップ
git remote add wiki-pages https://github.com/crownfall-game/crownfall-game.github.io.git 2>/dev/null \
  || git remote set-url wiki-pages https://github.com/crownfall-game/crownfall-game.github.io.git
mkdocs gh-deploy --force --no-history --remote-name wiki-pages --remote-branch main
# 注意: 本体 main の tip が動くことがある → 作業後
cd .. && git fetch origin main && git branch -f main origin/main
```

---

## 初回だけ（もう済んでいる想定）

Org `crownfall-game` とリポジトリ `crownfall-game.github.io`（Public）の作成。  
未作成なら GitHub で作ってから Step A へ。

| 項目 | 値 |
|---|---|
| Org | `crownfall-game` |
| Pages リポ | `crownfall-game/crownfall-game.github.io` |
| site_url | `https://crownfall-game.github.io/` |
| 原稿リポ | `JeflyMarte/crownfall` の `wiki/` |

---

## 旧URL

- ~~https://jeflymarte.github.io/crownfall/~~ — 停止済
