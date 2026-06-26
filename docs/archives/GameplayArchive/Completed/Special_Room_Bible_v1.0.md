# Special_Room_Bible_v1.0

**Status:** Completed
**Approved By:** DevelopmentHQ
**Version:** v1.0
**Source:** Special_Room_Bible_v1.1（Proposal）
**Implemented:** Phase2-M3（P2-Task013〜018）
**Date:** 2026-06-22

**関連文書:**
- `docs/specs/game/05_ダンジョン.md`（部屋タイプ・Branch Route・Discovery SSOT）
- `docs/specs/game/04_ゲームループ.md`（ゲームループ概要）
- `docs/specs/game/11_バランス.md`（報酬バランス）

---

## 1. 概要

Special Room は Crownfall の探索体験に変化と選択肢を提供するルームカテゴリ。

- Branch Route（分岐選択 UI）と組み合わせ、数秒で完結する意思決定を提供する。
- 固定シーケンスでも一部の Special Room が出現する（EVENT / TREASURE / ELITE）。
- Phase2-M3 で 5 種類（Heal / Treasure / Merchant / Event / Elite）を実装。

---

## 2. Design Principles

| 原則 | 内容 |
|---|---|
| 探索テンポ維持 | Special Room は戦闘なしで数秒完結（Elite のみ戦闘あり） |
| 意思決定の明確化 | Branch Route 選択で Safe / Dangerous / Unknown を明示 |
| リスクとリターット | Elite は高難度・高報酬、Merchant は Gold 消費によるリスク軽減 |
| Weapon 分離 | Weapon は Special Room から排出しない（探索終了時ドロップのみ） |
| Balance DataTable 管理 | 出現率・報酬量を DataTable で外部管理し、ProjectDocs に固定値を持たない |

---

## 3. Branch Route 連携

Special Room は Branch Route 経由で出現する。

**Pool 定義（v3.4+ 確定 SSOT）:**

| Pool | 内容 |
|---|---|
| SAFE_POOL | HEAL / TREASURE / MERCHANT |
| DANGEROUS_POOL | COMBAT / ELITE |
| UNKNOWN_POOL | COMBAT / HEAL / EVENT / TREASURE / MERCHANT |

**固定部屋:** MID_BOSS / BOSS / EXIT は ROOM_SEQUENCE 固定。Branch 選択なし。

**固定シーケンス出現（branch_enabled = false）:**

| index | RoomType |
|---|---|
| 2, 5 | EVENT |
| 3 | TREASURE |
| 4 | ELITE |

---

## 4. Spawn Rules

- Special Room は Branch Route への配置を基本とする。
- 出現率・出現回数は Balance Data / DataTable で管理。
- Boss 直前は Heal Room または Merchant Room を優先候補とする。
- Boss 撃破後は Special Room を生成しない。

---

## 5. Room 仕様

### 5-1. HEAL Room（回復の部屋）

| 項目 | 値 |
|---|---|
| RoomType | `Enums.RoomType.HEAL` |
| 出現 | SAFE_POOL / UNKNOWN_POOL（Branch Route） |
| 回復量 | 10 HP（`DungeonScene.HEAL_AMOUNT`） |
| 対象 | 生存メンバーのみ |
| 処理 | `CombatController.heal_party(10)` — 最大 HP を超えない |
| 戦闘 | なし |

入室ログ: 「回復の部屋: 生存メンバーを10回復」

### 5-2. TREASURE Room（宝箱の部屋）

| 項目 | 値 |
|---|---|
| RoomType | `Enums.RoomType.TREASURE` |
| 出現 | SAFE_POOL / UNKNOWN_POOL（Branch Route）/ 固定 index 3 |
| Gold | +30（`TREASURE_GOLD`） |
| Accessory | 20% で silver_ring 抽選（`TREASURE_ACCESSORY_CHANCE`） |
| 処理 | `DungeonController.generate_treasure_loot()` |
| 戦闘 | なし |

報酬は `run_gold_reward` に累積。Accessory は `GameState.accessory_inventory` に追加。

### 5-3. MERCHANT Room（商人の部屋）

Phase2-M3 Special Room。Gold シンク（`GameState.gold` 永続 Gold を消費）。

| 項目 | 値 |
|---|---|
| RoomType | `Enums.RoomType.MERCHANT` |
| 出現 | SAFE_POOL / UNKNOWN_POOL（Branch Route） |
| 商品数 | カタログからランダム 2 品提示 |
| 支払い | `GameState.gold`（鑑定と共通の永続 Gold） |
| Weapon 販売 | 不可（P2-D020。将来 Decision まで） |
| 戦闘 | なし |

**商品カタログ（MVP）:**

| 種別 | 内容 | 価格 |
|---|---|---|
| armor | leather_armor（未鑑定 Instance） | 40G |
| accessory | silver_ring（未鑑定 Instance） | 60G |
| heal | 回復薬（生存メンバー +15 HP） | 35G |

**操作フロー:**
1. 入室 → `generate_merchant_offers()` で 2 品提示
2. 購入 → Gold 減算・商品付与（回復は即時 `heal_party`）
3. 「立ち去る」→ Merchant UI 閉じ、次の部屋へ

UI: `MerchantContainer`（所持 Gold 表示・2 商品行・立ち去るボタン）

**設計意図:** ボス前準備として短時間の支援購入。Weapon はドロップ/鑑定ループを維持するため Merchant では販売しない。

**未実装:** Materials 商人販売（MaterialData 定義済、販売は将来 Task）。

### 5-4. EVENT Room（イベントの部屋）

Phase2-M3 Special Room。2 択の短時間イベント。戦闘なし。

| 項目 | 値 |
|---|---|
| RoomType | `Enums.RoomType.EVENT` |
| 出現 | UNKNOWN_POOL（Branch Route）/ 固定 index 2, 5 |
| 選択 | 2 ボタン（A / B）→ 即時結果表示 |
| 所要時間 | 数秒（1 選択で完了） |

**報酬カテゴリ（MVP）:**

| type | イベント例 | 効果 |
|---|---|---|
| heal | 崩れた祭壇 | 生存メンバー +8 HP |
| gold | 古文書 | run 報酬 Gold +25 |
| buff | 封印された扉 | 周回内攻撃 x1.15（`run_damage_multiplier`） |
| material | 朽ちた木箱 | `relic_shard` x1 → `material_inventory` |
| lore | 色あせた碑文 | ログのみ（Codex 未実装） |

**操作フロー:**
1. 入室 → `pick_event()` で 5 種からランダム 1 件
2. 選択 → `resolve_event()` → 結果ログ
3. Event UI 非表示 → 次の部屋へ

UI: `EventContainer`（説明文・ButtonEventA/B）

**設計意図:** 探索の多様性を数秒で追加。Shrine / Discovery 連動は Future Phase 対象外。

### 5-5. ELITE Room（エリートの部屋）

Phase2-M3 Special Room。常に戦闘。高リスク・高報酬。

| 項目 | 値 |
|---|---|
| RoomType | `Enums.RoomType.ELITE` |
| 出現 | DANGEROUS_POOL（Branch Route）/ 固定 index 4 |
| 敵選択 | `pick_elite_enemy_data()` → `DungeonData.elite_pool` |
| フォールバック | elite_pool 空時は enemy_pool |
| 戦闘 | あり（既存自動戦闘 CombatTimer） |

**王都跡 elite_pool:** rusted_knight, ruins_looter（`enemy_type = ELITE`）
**白骸墓地 elite_pool:** ossuary_knight（`enemy_type = ELITE`）

**報酬（通常戦闘より高い）:**

| 優先 | 報酬 | 値 |
|---|---|---|
| 1 | Gold | EXP/Gold × 1.5（`ELITE_REWARD_MULTIPLIER`） |
| 2 | Armor | 35% で leather_armor 即時ドロップ |
| 3 | Accessory | 25% で silver_ring 即時ドロップ |
| 4 | 高品質素材 | 15% `elite_relic_shard` × 1 → `material_inventory` |
| 5 | EXP | Gold と同倍率 × 1.5 |

UI: 入室ログ `【エリート】{敵名}`、撃破ログに `(x1.5)` とボーナス行

---

## 6. Reward Rules

| ルール | 内容 |
|---|---|
| Weapon | Special Room からは排出しない。探索終了時に未鑑定武器として生成 |
| Armor | Treasure・Elite・Merchant から取得 |
| Accessory | Treasure・Elite・Merchant・Boss Reward から取得 |

---

## 7. Economy 設計

| 役割 | Room |
|---|---|
| Gold 供給源 | Treasure Room・Elite Room |
| Gold 消費先 | Merchant Room・AppraisalScene（鑑定） |

Treasure と Elite が Gold を稼ぎ、Merchant と Appraisal が Gold を消費する循環を形成する。

---

## 8. Lore 提供

- Phase2 では Event Room の `lore` type から提供（ログ表示のみ）。
- Codex UI は未実装（M9 Codex & Discovery Foundation 候補）。
- Shrine による Lore 拡張は Future Phase。

---

## 9. Discovery System 連携（P2-Task018）

Special Room 入室が Discovery Registry への登録トリガーとなる。

| category | 登録タイミング | entry_id 例 |
|---|---|---|
| room | Special Room 入室 | heal / treasure / merchant / event / elite |
| event | Event Room 入室 | fallen_altar / ancient_tome |
| lore | Event 選択（lore outcome） | royal_ruins_inscription |
| material | Event/Elite 選択（material outcome） | relic_shard / elite_relic_shard |

初回登録時ログ: `【新規発見】{category} / {entry_id}`

---

## 10. Future Phase

| コンテンツ | 内容 | 対象 Phase |
|---|---|---|
| Shrine Room | Lore 拡張・祈り効果 | Phase3-B 以降 |
| Unknown Route | Discovery System 連携（hidden_room / hidden_boss 解放） | M9 以降 |
| Materials 販売 | Merchant に Materials 追加 | 将来 Task |
| Balance DataTable | 出現率・報酬量の外部管理 | 将来 Task |
| Boss Reward Accessory | Boss 撃破後 Accessory 排出 | 将来 Task |

---

## 11. 互換性メモ

本文書は以下の実装済みシステムとの互換性を保つ。

| システム | 互換状態 |
|---|---|
| Branch Route System（P2-Task012） | SAFE/DANGEROUS/UNKNOWN Pool 定義に準拠 |
| HEAL Room（P2-Task013） | 本文書 §5-1 に記録 |
| TREASURE Room（P2-Task014） | 本文書 §5-2 に記録 |
| Discovery System（P2-Task018） | §9 に記録 |
