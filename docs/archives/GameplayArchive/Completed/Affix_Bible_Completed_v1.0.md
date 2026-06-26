# Affix Bible — Completed v1.0

**Status:** Completed (Design Reference — pre-AffixData SSOT)  
**Version:** v1.0  
**Approved By:** DevelopmentHQ  
**Date:** 2026-06-21  
**Supersedes:** `docs/archives/GameplayArchive/Proposal/Affix_Bible_v1.0.md`  
**Next Step:** P2-Task028 AffixData Foundation

---

## Document Status — Read First

| Item | Statement |
|---|---|
| Document type | **Affix 設計参照** — AffixData / AffixRoller 実装前の確定 Bible |
| SSOT | **`docs/specs/` は本 Bible 採用後に Task028 で更新する** |
| Override rule | 本 Bible は Product Vision と整合。MVP Decision / specs と矛盾する場合は Decision Log が優先 |
| Implementation | Affix  gameplay 接続は **P2-Task028 以降** の Task で行う |
| Code impact | 本 Completed 文書のみでは gameplay 変更を許可しない |

---

## Reconstruction Note

`Affix_Bible_v1.0` Proposal 全文はリポジトリ未配置のため、DevelopmentHQ レビュー（Approve with Minor Revision）と既存 `docs/specs/game/09_ドロップ_Affix.md`・Product Vision を基に Completed を構成した。レビュー反映の **3 点修正**（容量固定 / Affix Type 粒度 / Legendary 哲学）は本 v1.0 に含む。

---

# 1. Purpose

Affix システムの **設計原則・装備ルール・データ粒度** を定義する。

- Crownfall の **武器主役** progression を Affix でどう強化するか
- AffixData.tres を書く際の **登録単位**（stat_type）を固定する
- Legendary が **数値膨張** にならないための指針を与える

---

# 2. Position in Crownfall

| レイヤ | 役割 |
|---|---|
| Weapon | ビルドの主役。固有スキル + Affix |
| Armor | 生存。Prefix Affix で補完 |
| Accessory | 補助・運。Prefix Affix で微調整（武器を凌駕しない） |

Affix は **鑑定後の装備 identity** の核心。未鑑定 → 鑑定 → Affix 判明の体験は Product Vision §3.4 と一致する。

---

# 3. Design Philosophy

## 3.1 Weapon-Centric Affix

- 最も多くの Affix 枠を **Weapon** に持たせる（Prefix + Suffix）
- Affix は武器ビルドの **方向性** を示す。Accessory Affix は補助に留める

## 3.2 Discovery Over Checklist

- Affix 付き装備は **探索ドロップ / 宝箱 / エリート** から得ることが主経路
- **Merchant should not replace exploration.** 商人は補完であり、Affix  hunt の主舞台ではない

## 3.3 Legendary Identity

Legendary Affix は **identity rather than raw power**（単純なステータス膨張ではない）。

> **Legendary Affixes should create new play styles, not simply increase existing numbers.**

例: 新しいトリガー、スキル連動、探索リズムの変化 — `+500 Attack` のような設計は避ける。

---

# 4. Core Player Loop（Product Vision 整合）

```text
Weapon Discovery
      ↓
   Appraisal
      ↓
 Affix Generation（ロール確定）
      ↓
 Equipment Reveal（装備判断）
```

- **Discovery:** 未鑑定装備がインベントリに入る
- **Appraisal:** Gold 消費で鑑定（MVP 既存フロー）
- **Affix Generation:** レアリティ・装備種に応じて Affix 抽選・数値ロール
- **Reveal:** 判明した Affix を見て装備 / 売却 / 保管を決める

---

# 5. Equipment Affix Rules（MVP 固定仕様）

MVP では **Recommended ではなく固定**。実装は以下のみサポートする。

| 装備種 | Prefix | Suffix |
|---|---|---|
| **Weapon** | ×1 | ×1 |
| **Armor** | ×1 | — |
| **Accessory** | ×1 | — |

- **Prefix:** 名称前半に付く Affix（例: 「鋭利の」）
- **Suffix:** 名称後半に付く Affix（例: 「…の吸血」）。**Weapon のみ**

### Future（MVP 対象外）

| 拡張 | 説明 |
|---|---|
| Dual Prefix | 同一装備に Prefix 2 枠 |
| Dual Suffix | 同一 Weapon に Suffix 2 枠 |

将来拡張時は Decision + specs 更新後に実装する。

---

# 6. Affix Types（AffixData 登録単位）

`AffixData.stat_type`（または同等フィールド）として **以下を正式 enum 候補** とする。  
Combat / Economy / Loot の大分類だけでは Data 化に迷うため、**Data 登録粒度まで固定**する。

| stat_type | 概要 | 大分類 |
|---|---|---|
| Attack | 攻撃力補正 | Combat |
| Defense | 防御力補正 | Combat |
| HP | 最大 HP 補正 | Combat |
| Critical | クリ率 / クリダメ | Combat |
| Attack Speed | 攻撃速度 | Combat |
| Healing | 回復効果 | Combat |
| Skill Power | スキル威力倍率 | Combat |
| Cooldown | スキル CT 短縮 | Combat |
| Gold Gain | ゴールド獲得 | Economy |
| Material Gain | 素材獲得 | Economy |
| Treasure Quality | 宝箱品質 | Loot |
| Rare Drop Rate | レアドロップ率 | Loot |
| Exploration | 発見 / 探索補正 | Exploration |

新 stat_type 追加は Decision Log 記録後に行う。

---

# 7. Rarity & Roll（概要）

詳細数値は `docs/specs/game/09_ドロップ_Affix.md` および Task028+ で SSOT 化。

| 要点 | 方針 |
|---|---|
| 抽選タイミング | ドロップ生成時（未鑑定のまま inventory へ） |
| 鑑定 | Affix **内容の表示**。MVP では再ロールしない |
| Legendary 率 | 09 ドロップ仕様の目安に従う |
| Affix 数 | §5 固定容量内でレアリティに応じて **付与可否** を決める（枠数自体は増やさない） |

---

# 8. Merchant & Exploration

| ルール | 内容 |
|---|---|
| 主経路 | ダンジョン探索ドロップ・宝箱・エリート |
| 商人 | 固定効果装備・回復等。**Affix 付き装備の主販売はしない** |
| 原則 | **Merchant should not replace exploration.** |

---

# 9. Implementation Roadmap（参照）

| 順序 | Task | 内容 |
|---|---|---|
| 1 | **P2-Task028** | AffixData Foundation |
| 2 | M6+ | Affix Roll / Appraisal Integration |
| 3 | M6+ | Equipment Detail UI |
| 4 | 将来 | Legendary 演出 UI |

本 Bible は Task028 の **入力 Design Reference**。Task028 完了時に `03_Resource設計.md` 等へ SSOT マージする。

---

# 10. Deferred

- Dual Prefix / Dual Suffix
- Affix 再ロール / 鍛冶
- Legendary 専用演出 UI
- Codex Affix 図鑑
- 敵 / ボス Affix
- 全 stat_type の戦闘接続（段階的に Task 分割）

---

## DevelopmentHQ Decisions（本 Bible 由来）

| ID | 決定 |
|---|---|
| P2-D077 | MVP Affix 容量固定: Weapon Prefix×1 Suffix×1 / Armor Prefix×1 / Accessory Prefix×1 |
| P2-D078 | AffixData stat_type 登録単位を §6 の 13 種で固定 |
| P2-D079 | Legendary Affix は新 play style を生む。単純数値増加禁止 |
| P2-D080 | Affix_Bible_Completed_v1.0 を M6 Affix 実装の Design Reference として採用 |

---

## 参照

- `docs/archives/GameplayArchive/Completed/Crownfall_Product_Vision_Completed_v1.0.md` §3.3–3.4
- `docs/specs/game/09_ドロップ_Affix.md`
- `docs/specs/core/02_Roadmap.md` — Phase2-M6
