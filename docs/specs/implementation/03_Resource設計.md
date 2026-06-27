# 03_Resource設計

## WeaponData

```gdscript
class_name WeaponData
extends Resource

@export var id: String
@export var display_name: String
@export var weapon_type: String
@export var rarity: String
@export var base_attack_min: int
@export var base_attack_max: int
@export var attack_speed: float
@export var fixed_skill_id: String
@export var possible_affixes: Array[String]
@export var mark: String
@export_multiline var flavor_text: String
```

## WeaponInstance

```gdscript
class_name WeaponInstance
extends Resource

@export var instance_id: String
@export var data_id: String
@export var attack: int
@export var affixes: Array[AffixInstance]
@export var is_identified: bool
@export var level: int
```

## AffixData（P2-Task028 確定）

```gdscript
class_name AffixData
extends Resource

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var affix_category: String    # prefix | suffix
@export var rarity: int               # Enums.Rarity
@export var stat_type: String         # Affix Bible §6（Attack, Defense, …）
@export var value: float              # サンプル固定値。Roll min/max は将来
@export var tags: Array[String]
```

### サンプル

| id | display_name | affix_category | stat_type |
|---|---|---|---|
| sharp | 鋭利 | prefix | Attack |
| swift | 敏捷 | prefix | Attack Speed |
| heavy | 重厚 | prefix | Defense |
| blessed | 祝福 | prefix | Healing |
| fortune | 幸運 | prefix | Gold Gain |
| protection | 守護 | prefix | Defense |
| of_might | 偉力 | suffix | Attack |

### 参照

- `DataRegistry.get_affix_data(id)` → AffixData Resource

---

## AffixRoller（P2-Task029 確定）

```gdscript
class_name AffixRoller
extends RefCounted

static func roll_for_equipment(equipment_category: String, item_rarity: int) -> Dictionary
```

### MVP スロット規則

| equipment_category | Prefix | Suffix |
|---|---|---|
| weapon | ×1 | ×1 |
| armor | ×1 | — |
| accessory | ×1 | — |

### フィルタ

- `affix_category` が slot（prefix/suffix）と一致
- `tags` に equipment_category が含まれる（空 tags は全種可）
- `affix.rarity <=` 抽選 tier

### レアリティ重み（tier 抽選）

| Rarity | Weight |
|---|---|
| COMMON | 70 |
| RARE | 25 |
| EPIC | 4 |
| LEGENDARY | 1 |

`item_rarity` が tier 上限（LEGENDARY 装備でも COMMON Affix 多数）。

### 戻り値

```gdscript
{
  "equipment_category": "weapon",
  "item_rarity": 0,
  "prefix_ids": ["sharp"],
  "suffix_ids": ["of_might"],
  "prefixes": [AffixData, ...],
  "suffixes": [AffixData, ...],
}
```

不正 category → `"error": "invalid_category"`、空配列。

### 未接続

- Equipment Detail UI

---

## 装備 Instance — Affix フィールド（P2-Task030 確定）

`WeaponInstance` / `ArmorInstance` / `AccessoryInstance` に以下を追加:

```gdscript
@export var prefix_ids: Array[String] = []
@export var suffix_ids: Array[String] = []  # weapon のみ通常 1 件。armor/accessory は空
```

### 鑑定連携

`AppraisalController.appraise_next()` が `AffixRoller.roll_for_equipment()` を呼び、roll 結果を instance に保存。Reveal は `【Affix】display_name / …` 形式。

Roll 失敗（error / 空候補）時も鑑定は完了。`prefix_ids` / `suffix_ids` は空配列。

### Save

`SaveManager` が `prefix_ids` / `suffix_ids` を inventory 各配列に serialize（後方互換: キー欠落時は空配列）。

### 未接続

- Equipment Detail UI 全面改修
- Affix reroll

---

## AffixStatCalculator（P2-Task031 確定）

```gdscript
class_name AffixStatCalculator
extends RefCounted

static func get_bonuses() -> Dictionary
static func apply_gold_bonus(base_gold: int) -> int
static func apply_healing_bonus(base_amount: int) -> int
static func apply_material_bonus(base_amount: int) -> int
```

### 入力

鑑定済み装備の Affix ID のみ（`is_appraised == true`）:

| 装備 | prefix_ids | suffix_ids |
|---|---|---|
| weapon | ✓ | ✓ |
| armor | ✓ | — |
| accessory | ✓ | — |

### 対応 stat_type（Task031）

| stat_type | 効果 |
|---|---|
| Attack | 与ダメ flat 加算 |
| Defense | 被ダメ軽減（defense 加算） |
| HP | max HP flat 加算 |
| Critical | crit_rate 加算 |
| Gold Gain | gold 倍率加算（1.0 + Σvalue） |
| Material Gain | 素材取得量 flat 加算 |
| Healing | 回復量 flat 加算 |

### 未対応（安全に無視）

Attack Speed, Skill Power, Cooldown, Treasure Quality, Rare Drop Rate, Exploration 等

### 接続点

| 接続 | ファイル |
|---|---|
| 与ダメ / crit | `DungeonScene._calc_attack_base()` |
| 被ダメ軽減 | `DungeonScene._calc_enemy_damage_to_member()` |
| max HP | `CombatController._init_party_hp()` |
| run Gold | `DungeonController.accumulate_rewards()` |
| 回復 / 素材 | `DungeonScene` heal・material 解決 |

---

## AffixData（旧正式版スキーマ — 参照用）

将来 Roll 拡張時に min/max / weight 等を追加する可能性あり。Task028 では未実装。

```gdscript
# 旧 03_Resource 記載（未実装フィールド）
# min_value, max_value, value_type, allowed_item_types, weight
```

## EnemyData（Phase2-M3 実装）

```gdscript
class_name EnemyData
extends Resource

@export var id: String
@export var display_name: String
@export var max_hp: int
@export var attack: int
@export var defense: int
@export var attack_speed: float
@export var critical_rate: float
@export var move_speed: float
@export var detection_range: float
@export var attack_range: float
@export var enemy_type: int          # Enums.EnemyType
@export var ai_type: String
@export var exp_reward: int
@export var gold_reward: int
@export var drop_table_id: String
```

## DungeonData

```gdscript
class_name DungeonData
extends Resource

@export var id: String
@export var display_name: String
@export var difficulty: int
@export var room_count: int
@export var enemy_pool: Array[String]
@export var boss_id: String
@export var drop_table_id: String
@export var discovery_unlocks: Dictionary   # 進行度閾値（registry とは別系統）
@export var branch_enabled: bool            # Phase2-M3: Branch Route
@export var elite_pool: Array[String]       # Elite Room 敵プール（P2-Task017）
```

## SkillData（P2-Task019 確定）

```gdscript
class_name SkillData
extends Resource

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var skill_type: String       # player / enemy / boss / job
@export var target_type: String      # enemy / ally / self / all
@export var power_multiplier: float  # ダメージ・回復等の倍率
@export var cooldown: float
@export var trigger_type: String     # M3: "cooldown" placeholder
@export var effect_type: String      # damage / heal / buff / none
@export var tags: Array[String]      # 例: physical, melee
```

### サンプル

| ファイル | id | skill_type |
|---|---|---|
| `resources/skills/slash_attack.tres` | slash_attack | player |

### 参照

- `DataRegistry.get_skill_data(id)` → SkillData Resource
- `SkillExecutor`（P2-Task025）— `effect_type = damage` のみ実行
- 戦闘接続: 装備武器 `fixed_skill_id` → SkillData（P2-Task026）。未設定時 `Constants.DEFAULT_PLAYER_SKILL_ID`

---

## SkillExecutor（P2-Task025 確定）

```gdscript
class_name SkillExecutor
extends RefCounted

func reset() -> void
func tick(delta_seconds: float) -> void
func can_cast(skill_data: Resource) -> bool
func calculate_damage(skill_data, base_damage, is_critical, critical_multiplier, run_multiplier) -> int
func execute_damage_skill(...) -> Dictionary   # executed / damage / display_name
```

- DungeonScene がインスタンスを保持。戦闘開始時 `reset()`、ティック毎 `tick()`
- heal / buff / none は安全に無視

---

## JobData（P2-Task027 確定）

```gdscript
class_name JobData
extends Resource

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var role: String
@export var base_hp_modifier: float
@export var base_attack_modifier: float
@export var base_defense_modifier: float
@export var preferred_weapon_types: Array[String]
@export var starting_skill_ids: Array[String]
@export var passive_tag_ids: Array[String]
```

### サンプル

| ファイル | id | role |
|---|---|---|
| `resources/jobs/warrior.tres` | warrior | dps |
| `resources/jobs/guardian.tres` | guardian | tank |
| `resources/jobs/scout.tres` | scout | scout |

### 参照

- `DataRegistry.get_job_data(id)` → JobData Resource

---

## JobStatCalculator（P2-Task033 確定）

```gdscript
class_name JobStatCalculator
extends RefCounted

static func get_member_modifiers(adventurer: Resource) -> Dictionary
static func empty_modifiers() -> Dictionary
```

### 戻り値

```gdscript
{
  "hp_multiplier": 1.0,
  "attack_multiplier": 1.0,
  "defense_multiplier": 1.0,
  "job_id": "warrior",
  "display_name": "戦士",
  "role": "dps",
}
```

### 安全 fallback

- `adventurer == null` / 空 `job_id` / JobData 欠落 → multiplier 1.0
- 不正 modifier（≤ 0）→ 1.0

### 未接続（Task033 時点 → Task034 で接続）

- ~~戦闘 HP / ATK / DEF 反映~~ → **P2-Task034 接続済**
- starting_skill_ids / Job UI / Build Summary

### 戦闘接続（P2-Task034 確定）

| パラメータ | 接続箇所 | 合成 |
|---|---|---|
| HP | `CombatController._init_party_hp` | (base + Affix flat) × job hp_mult |
| Attack | `DungeonScene._calc_attack_base(index)` | (base + Equip + Affix) × job atk_mult → crit / run |
| Defense | `DungeonScene._calc_enemy_damage_to_member(index)` | (Equip + Affix flat) × job def_mult |

合成順序（P2-D115）: Base → Equipment → Affix → **Job multiply** → crit / run mult

### Party 初期 job_id（P2-D123）

| メンバー | job_id |
|---|---|
| adventurer_0 | warrior |
| adventurer_1 | guardian |
| adventurer_2 | scout |

---

## DataRegistry（P2-Task020 確定）

Autoload。コア Data Resource の lookup 層。

### 規約

| メソッド | パス | 返却型 |
|---|---|---|
| `get_weapon_data(id)` | `resources/weapons/{id}.tres` | WeaponData |
| `get_armor_data(id)` | `resources/armors/{id}.tres` | ArmorData |
| `get_accessory_data(id)` | `resources/accessories/{id}.tres` | AccessoryData |
| `get_enemy_data(id)` | `resources/enemies/{id}.tres` | EnemyData |
| `get_skill_data(id)` | `resources/skills/{id}.tres` | SkillData |
| `get_dungeon_data(id)` | `resources/dungeons/{id}.tres` | DungeonData |
| `get_material_data(id)` | `resources/materials/{id}.tres` | MaterialData |
| `get_job_data(id)` | `resources/jobs/{id}.tres` | JobData |
| `get_affix_data(id)` | `resources/affixes/{id}.tres` | AffixData |

パス定数: `Constants.RESOURCE_*_PATH`

### M3 登録済みリソース

| カテゴリ | id 例 |
|---|---|
| weapons | iron_sword, rusted_blade |
| armors | leather_armor |
| accessories | silver_ring |
| enemies | fallen_soldier, ruined_guard, ruins_looter, rusted_knight, royal_guard_captain |
| skills | slash_attack |
| dungeons | royal_ruins, graveyard |
| materials | relic_shard, elite_relic_shard, ancient_bone, cursed_iron |
| jobs | warrior, guardian, scout |
| affixes | sharp, swift, heavy, blessed, fortune, protection, of_might |

### 未サポート（将来）

- drop_table Resource
- エディタ UI / hot reload / 一括マイグレーション

### 既存コードとの関係

`DungeonController` / `EquipmentScene` 等に inline `load()` が残存。**M3 では一括置換しない。**
新規実装は `DataRegistry` 経由を推奨。

---

## MaterialData（P2-Task024 確定）

```gdscript
class_name MaterialData
extends Resource

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var rarity: int              # Enums.Rarity
@export var icon: String
@export var category: String         # relic / bone / metal 等
@export var value: int               # 将来: 売却・換算用
@export var lore_id: String          # 将来: Codex 連動
```

### インベントリ

- `GameState.material_inventory: Dictionary` — `{ material_id: quantity }`
- `GameState.add_material(id, amount)` / `get_material_quantity(id)`
- `SaveManager` で永続化

### サンプル

| id | display_name | category |
|---|---|---|
| relic_shard | 遺跡の欠片 | relic |
| elite_relic_shard | 高品質遺跡の欠片 | relic |
| ancient_bone | 古き骨 | bone |
| cursed_iron | 呪いの鉄 | metal |
| leather | なめし革 | hide |

### 取得経路（M4）

| 経路 | material_id |
|---|---|
| Event Room（朽ちた木箱） | relic_shard |
| Elite Room ボーナス（15%） | elite_relic_shard |

**未実装:** 商人素材販売 / 素材 UI

---

## Craft Output Integration（P2-Task042 確定）

**接続:** `BlacksmithScene._on_craft_pressed(craft)`

### フロー

```
検証（output_type / output_id / gold / materials）
  → GameState.gold 減算
  → GameState.consume_materials(required_materials)
  → Instance 生成（未鑑定、affix なし）
  → armor_inventory / accessory_inventory 追加
  → SaveManager.save_game()
```

### MVP 対象 output_type

| output_type | 生成 | inventory |
|---|---|---|
| armor | ArmorInstance（DungeonController 同型） | `GameState.armor_inventory` |
| accessory | AccessoryInstance（DungeonController 同型） | `GameState.accessory_inventory` |
| weapon | **禁止**（ボタン非表示 + 検証 reject） |

### 失敗時

Gold / 素材 **一切消費しない**。`LabelStatus` に最小ログ表示。

---

## CraftData（M8 Craft Resource Pack — Parallel Task）

```gdscript
class_name CraftData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var required_materials: Dictionary = {}  # { material_id: quantity }
@export var gold_cost: int = 0
@export var output_type: String = ""  # "armor" | "accessory" | "weapon"
@export var output_id: String = ""
@export var unlock_condition: String = ""
```

- DataRegistry: `get_craft_data(id)` / `get_all_craft_data()`
- パス: `resources/crafting/`

### サンプル（MVP 3件）

| id | required_materials | gold_cost | output_type | output_id |
|---|---|---|---|---|
| craft_leather_armor | leather×2, relic_shard×1 | 50G | armor | leather_armor |
| craft_bone_armor | ancient_bone×3 | 40G | armor | bone_armor |
| craft_silver_ring | relic_shard×3, elite_relic_shard×1 | 80G | accessory | silver_ring |

---

## RecipeData（M8 Craft Resource Pack — Parallel Task）

```gdscript
class_name RecipeData
extends Resource

@export var id: String = ""
@export var craft_id: String = ""    # 対応する CraftData.id
@export var display_name: String = ""
@export var output_summary: String = ""
@export var category: String = ""   # "armor" | "accessory"
@export var description: String = ""
```

- DataRegistry: `get_recipe_data(id)`
- パス: `resources/recipes/`
- Blacksmith UI のカテゴリ表示・説明文に使用する表示層 Resource

---

| `get_all_weapon_data()` | なし | 全 WeaponData の Array |

---

## CatalogHelper（P2-Task046 確定）

```gdscript
class_name CatalogHelper
extends RefCounted

static func get_enemy_entries() -> Array
static func get_dungeon_entries() -> Array
static func get_material_entries() -> Array
static func get_weapon_entries() -> Array
static func get_history_entries() -> Array
static func is_discovered(category: String, entry_id: String) -> bool
```

### Entry 形式

```gdscript
{
  "id": "fallen_soldier",
  "display_name": "亡国兵",  # 未発見時 "???"
  "icon": "",
  "description": "",
  "discovered": true,
}
```

### Discovery 判定

- `enemy` / `material` — 既存 `discovery_registry` key
- `dungeon` / `weapon` — `"dungeon:{id}"` / `"weapon:{id}"`（登録フックは Task047+）
- `history` — HE-001〜004 常時発見 / `history:{id}` / `lore:{id}` → HE マップ

### History Bible

- Read-only parse: `docs/specs/world/01_History.md`（HE-001〜004 機械可読ブロック。旧 16/37 は削除）
- 欠落時 → 空配列

---

## MaterialShopData（M8 Merchant Material Shop Foundation — Parallel Task）

```gdscript
class_name MaterialShopData
extends Resource

@export var material_id: String = ""
@export var price: int = 0
@export var stock: int = -1        # -1 = 無限
@export var unlock_condition: String = ""
```

- DataRegistry: `get_material_shop_items()` / `get_material_price(material_id)`
- パス: `resources/material_shop/`
- **Merchant 接続済**（P2-Task043）— `DungeonController._build_merchant_catalog()` 経由

### Merchant Material Purchase（P2-Task043 確定）

```
Gold 確認 → gold 減算 → GameState.add_material(id, 1) → purchased フラグ
```

- 価格: MaterialShopData.price（DataRegistry 経由）
- 既存 armor / accessory / heal 商品は MERCHANT_CATALOG 維持
- weapon 販売なし

### MVP 定義（P2-D144）

| material_id | price | stock |
|---|---|---|
| relic_shard | 20G | -1（無限） |
| ancient_bone | 20G | -1（無限） |

### API 動作仕様

| 関数 | 入力 | 戻り値 |
|---|---|---|
| `get_material_shop_items()` | なし | 全 MaterialShopData の Array |
| `get_material_price(material_id)` | material_id | price（int） / 未定義 id → -1 |
