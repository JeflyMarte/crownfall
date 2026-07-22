# Crownfall — ChatGPT 世界観パッケージ

**ProjectDocs:** v3.5.45  
**用途:** ChatGPT へ世界観・ロア・ゲーム文脈を一括で渡す  
**正:** リポジトリ内 `docs/specs/` のコピー。矛盾時はリポジトリを優先する

---

## この ZIP に含まれるもの

> 世界観は **戦後生態系（Postwar Ecology）** に刷新（2026-06-26）。世界観 SSOT は **`docs/specs/world/`**（15 文書＋内部 CANON）に再構成（2026-06-27 cutover／Fragments・Characters・Society 追加済）。旧 Bible（`game/16`〜`25` / `29`〜`37`）は削除し `world/` へ統合。

### 世界観 SSOT（`world/`）

| 区分 | ファイル | 内容 |
|---|---|---|
| マスター | `world/00_Overview.md` | 三本柱・全体像・読み順 |
| 歴史 | `world/01_History.md` | 王国時代〜探索者の時代・HE エントリ |
| 遺産 | `world/02_Relics.md` | 遺産・伝説武器・中核の謎 |
| 生態 | `world/03_Ecology.md` | 戦後生態系 総論・エルダ・裂け目 |
| 分類 | `world/04_Classification.md` | モンスター分類体系（Class I〜VII）・遍在希少種 |
| Biome | `world/05_Biomes.md` | バイオーム（生態系単位） |
| 命名 | `world/06_MonsterNaming.md` | モンスター命名ガイド |
| 地理 | `world/07_Geography.md` | エルド大陸地理 |
| 組織 | `world/08_SeekersGuild.md` | 探索者ギルド・招待状／魔晶石 |
| ジョブ | `world/09_Jobs.md` | ジョブ（世界観面） |
| 提示 | `world/10_LoreDelivery.md` | ロア提示ガイド |
| 用語 | `world/11_Glossary.md` | 用語・固有名詞レジストリ |
| 断片 | `world/12_Fragments.md` | 公開断片ロア集 |
| 人物 | `world/13_Characters.md` | 九王・九英雄・ニーナ・初期隊・ジャック |
| 社会 | `world/14_Society.md` | ギルド外の社会・文化・派閥 |

### ゲーム仕様側（数値・システム）

| 区分 | ファイル | 内容 |
|---|---|---|
| 入口 | `01_ゲーム概要.md` | ジャンル・コア体験 |
| 入口 | `03_世界観.md` | 世界観要約（ゲームデザイン視点・world/ への入口） |
| ジョブ数値 | `06_キャラクター_ジョブ.md` | ジョブの数値・実装仕様 |
| 図鑑 | `33_EcologyCodex.md` | 生態図鑑（5 段階調査・システム仕様） |
| 体験 | `04_ゲームループ.md` | プレイヤーループ |
| 敵 | `12_モンスター.md` | 敵・Family の設計方針 |
| 戦闘 | `26_CombatVision.md` | 戦闘ビジョン（不変原則） |
| 属性 | `27_状態異常と属性.md` | 属性・状態異常 |
| 設計 | `core/01_Design_Principles.md` | 全体設計原則 |

**含まないもの:** 実装コード、アーカイブ Proposal、Task 報告、`CANON_INTERNAL.md`（プレイヤー非開示）

---

## 推奨読み順（ChatGPT 向け）

1. `01_ゲーム概要.md` → `03_世界観.md`
2. `world/00_Overview.md`（**世界観マスター。必読**）
3. `world/01_History.md` → `world/02_Relics.md`（歴史・遺産・中核の謎）
4. `world/03`〜`07`（生態 / 分類 / Biome / 命名 / 地理）
5. `world/08`〜`11`（ギルド / ジョブ / 提示 / 用語）
6. `world/12`〜`14`（断片 / 人物 / 社会）— β文案・拠点声に直結
7. 戦闘・敵の文脈: `26_CombatVision.md` + `12_モンスター.md`

---

## ChatGPT への最初のプロンプト例

```text
添付 ZIP は Crownfall（2D見下ろし・自動探索ハクスラRPG）の公式世界観 SSOT です。

ルール:
- プレイヤーは「選ばれし英雄」ではなく探索者（Seeker）。探索隊の指揮官で直接操作しない
- モンスターは魔物・不死者ではなく全て実在生物が祖先（戦後生態系 / world/03_Ecology）
- ロアは断片的に開示。直接説明しすぎない
- 九王時代 → 王国時代 → 九王戦争 → 静寂 → 探索者の時代
- 王遺産・第十の王・王冠の失墜は中核の謎。断定しない
- 招待状＝召喚ではない。魔晶石＝エルダ晶石の招致手数料
- コズミックダック／宝冠レイヴンは遍在希少種（異界来訪ではない）
- MVP／β は王都地下モーンゲート。ジョブは 5 基本職。随伴オトモ「ジャック」あり

この文脈で [依頼内容] を作成してください。
```

---

## 更新

ZIP 再生成: リポジトリルートで

```bash
./scripts/package_chatgpt_worldlore.sh
```

または HQ が `docs/specs/world/` のロア文書更新時に手動再パッケージ。
