# Crownfall — ChatGPT 世界観パッケージ

**ProjectDocs:** v3.5.45  
**用途:** ChatGPT へ世界観・ロア・ゲーム文脈を一括で渡す  
**正:** リポジトリ内 `docs/specs/` のコピー。矛盾時はリポジトリを優先する

---

## この ZIP に含まれるもの

| 区分 | ファイル | 内容 |
|---|---|---|
| 入口 | `01_ゲーム概要.md` | ジャンル・コア体験 |
| 入口 | `03_世界観.md` | 世界観要約（ゲームデザイン視点） |
| 原則 | `17_WorldBible.md` | 世界設計 10 原則・命名・時代 |
| 原則 | `20_WorldBible.md` | 世界全体の俯瞰（専門 Bible への入口） |
| 柱 | `25_WorldAssetsBible.md` | World Pillars A-01〜A-12・Canon 索引 |
| 開示 | `18_LoreDeliveryGuide.md` | ロアの届け方（説明しすぎない） |
| 歴史 | `16_HistoryBible.md` | History Entry HE-001〜 |
| 王国 | `19_KingdomBible.md` | 五王国 K-001〜005 |
| 地理 | `21_GeographyBible.md` | 地域・地名 |
| 探索 | `22_DungeonBible.md` | ダンジョンのロア設計 |
| 勢力 | `23_FactionBible.md` | 派閥・組織 |
| NPC | `24_NPCBible.md` | 主要 NPC |
| 体験 | `04_ゲームループ.md` | プレイヤーループ |
| 敵 | `12_モンスター.md` | 敵・Family の設計方針 |
| 戦闘 | `26_CombatVision.md` | 戦闘ビジョン（不変原則） |
| 属性 | `27_状態異常と属性.md` | 属性・状態異常（未実装・設計のみ） |
| 設計 | `core/01_Design_Principles.md` | 全体設計原則 |

**含まないもの:** 実装コード、アーカイブ Proposal、Task 報告、Phase3-A アート制作指示

---

## 推奨読み順（ChatGPT 向け）

1. `01_ゲーム概要.md` → `03_世界観.md`
2. `17_WorldBible.md` → `20_WorldBible.md` → `25_WorldAssetsBible.md`
3. `18_LoreDeliveryGuide.md`（**フレーバーテキスト作成前に必読**）
4. 必要に応じて `16_` / `19_` / `21_` / `22_` / `23_` / `24_`
5. 戦闘・敵の文脈: `26_CombatVision.md` + `12_モンスター.md`

---

## ChatGPT への最初のプロンプト例

```text
添付 ZIP は Crownfall（2D見下ろし・自動探索ハクスラRPG）の公式世界観 SSOT です。

ルール:
- プレイヤーは「選ばれし英雄」ではなくレリックハンター（探索者）
- ロアは断片的に開示。直接説明しすぎない（18_LoreDeliveryGuide 準拠）
- 九王時代 → 王国時代 → 九王戦争 → 静寂 → 探索者の時代
- 王遺産・第十の王・王冠の失墜は中核の謎。断定しない
- MVP は王都跡・白骸墓地の 2 ダンジョン。装備 3 枠（王遺産枠は正式版）

この文脈で [依頼内容] を作成してください。
```

---

## 更新

ZIP 再生成: リポジトリルートで

```bash
./scripts/package_chatgpt_worldlore.sh
```

または HQ が `docs/specs/game/` のロア Bible 更新時に手動再パッケージ。
