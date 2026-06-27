# Crownfall — ChatGPT 世界観パッケージ

**ProjectDocs:** v3.5.45  
**用途:** ChatGPT へ世界観・ロア・ゲーム文脈を一括で渡す  
**正:** リポジトリ内 `docs/specs/` のコピー。矛盾時はリポジトリを優先する

---

## この ZIP に含まれるもの

> 世界観は **戦後生態系（Postwar Ecology）** に刷新（2026-06-26）。旧 World/Lore Bible（16〜25）は削除し、コアは `37_RelicsHistoryCore.md` に統合。

| 区分 | ファイル | 内容 |
|---|---|---|
| 入口 | `01_ゲーム概要.md` | ジャンル・コア体験 |
| 入口 | `03_世界観.md` | 世界観要約（ゲームデザイン視点） |
| マスター | `29_PostwarEcology.md` | 三本柱・生物由来モンスター・デザインルール |
| 分類 | `30_EcologyClassification.md` | モンスター分類体系（Class I〜VII） |
| 組織 | `31_SeekersGuild.md` | 探索者ギルド（調査管理機構） |
| 生態 | `32_BiomeBible.md` | バイオーム（生態系単位）・MVP 2 種 |
| 図鑑 | `33_EcologyCodex.md` | 生態図鑑（5 段階調査） |
| 命名 | `34_MonsterNamingGuide.md` | モンスター命名ガイド |
| 地理 | `35_WorldGeography.md` | エルド大陸地理 |
| ジョブ | `36_JobBible.md` | 5 基本ジョブ |
| 歴史・遺産 | `37_RelicsHistoryCore.md` | 語源（王冠）・時代区分・九王・王遺産・中核の謎 |
| 体験 | `04_ゲームループ.md` | プレイヤーループ |
| 敵 | `12_モンスター.md` | 敵・Family の設計方針 |
| 戦闘 | `26_CombatVision.md` | 戦闘ビジョン（不変原則） |
| 属性 | `27_状態異常と属性.md` | 属性・状態異常 |
| 設計 | `core/01_Design_Principles.md` | 全体設計原則 |

**含まないもの:** 実装コード、アーカイブ Proposal、Task 報告

---

## 推奨読み順（ChatGPT 向け）

1. `01_ゲーム概要.md` → `03_世界観.md`
2. `29_PostwarEcology.md`（**世界観マスター。必読**）
3. `30`〜`36`（分類 / ギルド / Biome / 図鑑 / 命名 / 地理 / ジョブ）
4. `37_RelicsHistoryCore.md`（歴史・遺産・中核の謎）
5. 戦闘・敵の文脈: `26_CombatVision.md` + `12_モンスター.md`

---

## ChatGPT への最初のプロンプト例

```text
添付 ZIP は Crownfall（2D見下ろし・自動探索ハクスラRPG）の公式世界観 SSOT です。

ルール:
- プレイヤーは「選ばれし英雄」ではなく探索者（Seeker）。探索隊の指揮官で直接操作しない
- モンスターは魔物・不死者ではなく全て実在生物が祖先（戦後生態系 / 29_PostwarEcology）
- ロアは断片的に開示。直接説明しすぎない
- 九王時代 → 王国時代 → 九王戦争 → 静寂 → 探索者の時代
- 王遺産・第十の王・王冠の失墜は中核の謎。断定しない
- MVP は王都地下モーンゲート（嘆きの地下水路）。ジョブは 5 基本職

この文脈で [依頼内容] を作成してください。
```

---

## 更新

ZIP 再生成: リポジトリルートで

```bash
./scripts/package_chatgpt_worldlore.sh
```

または HQ が `docs/specs/game/` のロア Bible 更新時に手動再パッケージ。
