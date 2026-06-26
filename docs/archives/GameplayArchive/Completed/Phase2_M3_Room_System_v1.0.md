# Phase2_M3_Room_System_v1.0

**ステータス:** Completed
**作成日:** 2026-06-21
**対象マイルストーン:** Phase2-M3 Room System

---

## 概要

Phase2-M3ではBranch Route System（M2+）の基盤の上に、ゲームプレイの多様性を生むルームタイプを6つ実装した。すべてMVP一本道モードとの互換性を維持している。

---

## 実装済みシステム

### 1. Merchant Room（商人の部屋）

**RoomType:** `MERCHANT`（Enums.RoomType.MERCHANT）

**Branch Pool配置:**
- SAFE_POOL に追加（安全ルートで選択可能）
- UNKNOWN_POOL に追加（不明ルートで選択可能）

**動作仕様:**
- 入室時、MERCHANT_CATALOGから2品をランダム選択して提示
- 商品候補: 鉄の剣（50G）/ 革鎧（40G）/ 銀の指輪（60G）
- 購入にはGameState.gold（永続ゴールド）を消費する
- 購入後、対応するItemInstanceをInventoryに追加
- 「立ち去る」ボタンで商人UIを閉じ、次の部屋へ進める
- 同一商品の2重購入防止（purchased フラグ管理）

**UI:** DungeonScene内にMerchantContainer（VBoxContainer）として実装。
- LabelMerchantTitle（現在Gold表示）
- Offer0Row / Offer1Row（各HBoxContainer）
- ButtonMerchantLeave

---

### 2. Event Room（イベントの部屋）

**RoomType:** `EVENT`（既存、一本道モードでもindex 2/5に出現）

**イベント一覧（3種）:**

| ID | 説明 | 選択A | 選択B |
|---|---|---|---|
| fallen_altar | 崩れた祭壇を発見した。碑文に触れるか？ | 触れる → 全員+8HP回復 | 無視する → 変化なし |
| ancient_tome | 古文書を発見した。解読するか？ | 解読する → Gold+25 | 無視する → 変化なし |
| sealed_door | 封印された扉を発見した。扉を開けるか？ | 開ける → EXP+30 | 立ち去る → 変化なし |

**動作仕様:**
- 入室時にランダム1件を選択
- 2択ボタンで選択 → 結果をログ表示
- heal型: CombatController.heal_party() で生存者回復
- gold/exp型: DungeonController.accumulate_rewards() で累積報酬に加算
- 選択後、EventContainerを非表示にして次の部屋へ進める

**UI:** EventContainer（VBoxContainer）内に LabelEventDesc + ButtonEventA/B

---

### 3. Elite Room（エリートの部屋）

**RoomType:** `ELITE`（既存、一本道モードindex 4 / DANGEROUS_POOLから選択可）

**動作仕様:**
- `pick_elite_enemy_data()` が DungeonData.elite_pool からランダム選択
- elite_pool が空の場合、通常enemy_poolにフォールバック
- 報酬倍率: `ELITE_REWARD_MULTIPLIER = 1.5`（1.5倍のEXP/Gold）
- 撃破ログに "(x1.5)" を追記

**royal_ruins.tres elite_pool:** rusted_knight, ruins_looter

**MID_BOSS も同倍率適用**（1.5x）

---

### 4. Discovery System（発見度システム）

**データ格納先:** `GameState.dungeon_progress[dungeon_id]`
- `discovery: float` — 0.0〜1.0
- `hidden_room: bool`
- `hidden_boss: bool`

**増加タイミング:**
- 部屋入室ごと: +DISCOVERY_PER_ROOM（0.05）
- ボス撃破時: +DISCOVERY_BOSS_BONUS（0.20）追加

**解放閾値:** DungeonData.discovery_unlocks から参照
- `hidden_room`: 30%（0.3）達成で `hidden_room = true`
- `special_event`: 60%（0.6）達成（参照のみ、現時点でUI未実装）
- `hidden_boss`: 100%（1.0）達成で `hidden_boss = true`

**Save/Load:** SaveManager が GameState.dungeon_progress を既存処理で保存。

---

### 5. SkillData（スキルデータ基盤）

**クラス:** `SkillData extends Resource`

**フィールド:**
- `id: String`
- `display_name: String`
- `description: String`
- `cooldown: float` — クールタイム（秒）
- `damage_multiplier: float` — ダメージ倍率
- `effect_type: String` — "damage" / "heal" / "buff" / "none"
- `target_type: String` — "enemy" / "ally" / "all"

**実装済みリソース:** `resources/skills/slash_attack.tres`

**戦闘接続:** MVP M3では未接続。M4以降でSkillExecutor実装予定。

---

### 6. DataRegistry（データアクセス集約）

**Autoload:** DataRegistry（既存登録済み）

**実装メソッド:**
- `get_weapon_data(id)` → WeaponData Resource
- `get_armor_data(id)` → ArmorData Resource
- `get_accessory_data(id)` → AccessoryData Resource
- `get_enemy_data(id)` → EnemyData Resource
- `get_skill_data(id)` → SkillData Resource
- `get_dungeon_data(id)` → DungeonData Resource

**現状:** 既存コードのインライン load() 呼び出しはそのまま維持（M4以降で段階的移行）。DataRegistry は新規実装・将来利用向け基盤として提供。

---

## Branch Poolへの統合

| Pool | 内容 |
|---|---|
| SAFE_POOL | HEAL / TREASURE / MERCHANT |
| DANGEROUS_POOL | COMBAT / ELITE |
| UNKNOWN_POOL | COMBAT / HEAL / EVENT / TREASURE / MERCHANT |

---

## 非実装事項（M3対象外）

- イベント確率分岐（現在は確定的な outcome_a/b のみ）
- Discovery Codex UI
- SkillExecutor / スキル戦闘接続
- Merchant在庫の永続管理（訪問ごとにリセット）
- Elite専用EnemyType = ELITE のリソース（現在はNORMALがelite_poolに入っている）

---

## 関連ファイル

- `scripts/core/Enums.gd` — RoomType.MERCHANT 追加
- `scripts/data/DungeonData.gd` — elite_pool 追加
- `scripts/data/SkillData.gd` — 新規
- `scripts/autoload/DataRegistry.gd` — メソッド追加
- `scripts/dungeon/DungeonController.gd` — Merchant/Event/Elite/Discovery/Spawn分離
- `scripts/dungeon/DungeonScene.gd` — UI処理追加
- `scenes/dungeon/DungeonScene.tscn` — MerchantContainer/EventContainer追加
- `resources/dungeons/royal_ruins.tres` — elite_pool追加
- `resources/skills/slash_attack.tres` — 新規
