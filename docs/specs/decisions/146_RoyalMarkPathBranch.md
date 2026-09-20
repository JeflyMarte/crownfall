# 分岐型王痕（P3-DG-ROYAL-MARK-002）

**Status:** **Approved**（2026-09-19）／**Implemented**（2026-09-19）  
**上書き:** Decision `144` の Rank III〜V「全員共通 Job Skill／維持」構造を本 Decision が正とする（ステ倍率・コスト・極限片経済・対象・解放ゲートは `144` 据置）  
**目的:** 王痕 I〜V を **攻勢／守勢／技巧** の方針分岐へ変え、極限任務の準備選択と V 完成感を両立する

---

## 0. 一言

王痕は **I〜V のまま MAX**。III で方針を選び、V でステ＋方針ピーク＋全方針共通の Ultimate 覚醒。既存セーブは `unselected` で旧 III 強化を維持し、選択後に新仕様へ移行する。

---

## 1. Rank（累積・コストは `144` 据置）

| Rank | 効果（累積ステ） | 方針 | 片 | Gold |
|---|---|---|---:|---:|
| I | HP ×1.03 | — | 100 | 5,000 |
| II | HP×1.03／ATK×1.03 | — | 150 | 10,000 |
| III | HP/ATK/DEF ×1.03 | **方針解放** | 200 | 15,000 |
| IV | HP/ATK/DEF ×1.05 | 方針段階 II | 250 | 25,000 |
| V | HP/ATK/DEF ×1.08 | 方針段階 III ＋ **Ultimate 覚醒** ＋ **MAX** | 300 | 45,000 |

累計: 片 1,000／Gold 100,000（片は表示×10・難易度比据置）。  
**Rank VI+ は追加しない。**  
対象・除外・解放・強化条件（人間19・Lv50・Main5 Normal CLEAR 等）は `144` §1 据置。  
ステ適用位置は `144` 据置。

---

## 2. 王痕方針

Rank III 以降、キャラクターごとに **同時 1 方針**。

### 2.1 攻勢

| Rank | outgoing |
|---|---:|
| III | +2% |
| IV | +4% |
| V | +6% |

既存 `get_member_outgoing_damage_multiplier` 共通経路のみ。

| 対象 | 非対象（新規配線禁止） |
|---|---|
| Normal Attack／Job Skill hit／Weapon Skill hit／Ultimate hit／counter hit | DoT／trap／pet／fixed damage／その他 outgoing 非経由 |

### 2.2 守勢

| Rank | incoming |
|---|---:|
| III | −3% |
| IV | −5% |
| V | −8% |

既存 `get_member_incoming_damage_multiplier` 共通経路のみ。  
direct DoT／thorns 等へ新規配線しない。

### 2.3 技巧（Job Skill 専門）

| Skill Type | III | IV | V |
|---|---:|---:|---:|
| Damage | power ×1.10 | ×1.15 | ×1.20 |
| Heal | ×1.15 | ×1.20 | ×1.25 |
| Trap | ×1.10 | ×1.15 | ×1.20 |
| Status | chance +10pp | +15pp | +20pp |
| Buff | duration +1 | +1 | +1 |
| Counter | count +1 | +1 | +1 |

規約:

- **Status 付き damage** は Status chance のみ（Damage power との二重禁止）
- 既存 status chance cap（≤100%）維持
- Weapon Skill／Ultimate は技巧対象外
- `trail_ward`／`none`／`equip_passive` 等 excluded は対象外。**新救済効果は作らない**
- excluded 装備中 UI: 「現在の装備スキルは技巧強化の対象外です」

---

## 3. 方針変更

Rank III 以降:

- 拠点／準備画面のみ変更可
- **無料**・何度でも可（片／Gold 非消費）
- ダンジョン攻略中は変更不可
- キャラクター単位で保存
- 同時有効は 1 方針

---

## 4. Rank V Ultimate 覚醒

全方針共通。現行 `144` Phase 2 Ultimate 強化を基本維持。

### 4.1 最低保証追加（本 Decision で確定）

| キャラ | skill_id | 追加 |
|---|---|---|
| レノール | `curse_burst` | `damage_mult ×1.08`（既存 status は変更しない） |
| 火鷹 | `critical_storm` | 現行 crit_surge duration 維持 ＋ `damage_mult ×1.08` |

**ミレイは変更しない**（現行 ignite 85→95% を維持）。  
その他 Ultimate も本 Decision では変更しない。

---

## 5. Save Migration

既存 Rank・消費済み片／Gold を完全維持。  
既存 Rank III〜V: **`royal_mark_path = unselected` を許可**（攻勢／守勢／技巧へ強制割当しない）。

### unselected 中

- 旧仕様 Rank III Job Skill enhancement を維持
- Rank ステ倍率を維持
- Rank V Ultimate 覚醒を維持
- 新・攻勢／守勢／技巧効果は **適用しない**

王痕画面初回で方針選択を促す。  
方針選択後は新仕様へ移行し、**以後 unselected へ戻せない**。

Save キー案（実装時）: キャラ ID → path（`unselected`／`offense`／`defense`／`technique`）。欠落は unselected。  
SAVE_VERSION 上げは実装 Task で行う（本 Decision 時点ではコード未変更）。

---

## 6. Modifier Exclusive Rule（実装必須）

```
unselected → 旧 Rank III Job Skill enhancement のみ
技巧       → 新技巧 modifier のみ
攻勢／守勢 → Job Skill enhancement なし

攻勢 → outgoing 段階のみ
守勢 → incoming 段階のみ
Ultimate 覚醒 → Rank ≥ V なら path 不問（unselected 含む）
```

「旧 III 強化 ＋ 新技巧／新方針」の二重適用は禁止。

---

## 7. 実装アンカー（予定）

- `RoyalMarkConfig`／`RoyalMarkSystem`／`RoyalMarkSkillModifier`
- `CombatController` outgoing／incoming
- `RoyalMarkScene`（方針 UI・excluded 警告・unselected 促し）
- `SaveManager`（paths＋migration）
- tests: path／排他／migration／Ult 最低保証

---

## 8. 非スコープ

- Economy／★片／25% 周回の再調整（`144` §3 据置）
- V 後の王痕片シンク／王痕共鳴／VI+
- Passive／限凸／新キャラ・装備・ダンジョン
- 極限 TUNING（`143`／`145`）変更
- 本 Decision 以外の Ultimate・Job Skill 新設

---

## 9. Impl 状態

| 項目 | 状態 |
|---|---|
| Decision／SSOT | **Approved（本ファイル）** |
| Gameplay／Combat | **Implemented**（攻勢 outgoing／守勢 incoming／技巧 Job／排他） |
| Save migration | **Implemented**（SAVE_VERSION 19・`royal_mark_paths`） |
| UI | **Implemented**（RoyalMarkScene 方針パネル） |
| Ult 最低保証 | **Implemented**（レノール／火鷹） |
| Tests | **Implemented**（`test_royal_mark*`） |
