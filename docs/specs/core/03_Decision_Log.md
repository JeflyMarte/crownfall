# Crownfall — Decision Log

## 初期決定（プロジェクト開始時）

| # | 決定事項 | 詳細 |
|---|---|---|
| D-001 | 自動探索採用 | プレイヤーは隊を直接操作しない。方針選択のみ |
| D-002 | 5分周回採用 | 通常ダンジョン1周を4〜6分に設計 |
| D-003 | 武器主軸 | 戦力寄与60%を武器が担う |
| D-004 | 装備枠（MVP3枠・正式版4枠） | MVP：武器・防具・装飾品。正式版で王遺産を追加 |
| D-005 | MVPは仮アート | MVP期間中はSprite不使用。UIは最低限テキストベース |
| D-006 | AI共同開発 | Claude Codeによる実装支援。Task単位で依頼 |

---

## MVP実装フェーズ決定（Task035〜Task047）

| # | 決定事項 | 根拠 |
|---|---|---|
| D-007 | MVPゲームループ確定 | Base→Dungeon→Result→Appraisal→Equipment→Base の6シーン固定順 |
| D-008 | Appraisal/EquipmentをMVP対象に含める | 鑑定→装備のコアループなしではMVP成立しない |
| D-009 | 鑑定済み武器のみ装備可能 | is_appraised = true が装備の前提条件 |
| D-010 | 装備保存はinstance_idで行う | WeaponInstanceへの参照ではなくIDで保存し、復元時にinventory検索で解決 |
| D-011 | equipment復元はinventory復元後に行う | オブジェクト参照の整合性確保のため順序を強制 |
| D-012 | Gold報酬を1周最低100G以上に調整 | 鑑定1回（100G）を1周で賄えないとコアループが回らない |
| D-013 | MVPテーマはmvp_theme.tres単一ファイルで管理 | 全シーンに同じThemeを適用し、個別スタイル定義を排除 |
| D-014 | SaveManagerにequipment保存を追加 | Task035-Fix時点でGold保存のみだった実装を完全化 |
| D-015 | ボタン多重押し対策（ButtonFinish/ButtonNext） | ResultScene gold二重加算・DungeonScene武器二重ドロップを防止 |
| D-016 | EXITルーム到達後はButtonNextRoomを無効化 | 「部屋11/10」表示を防止し、EXITが探索の終端であることを明示 |
| D-017 | party_members参照はインデックス直参照禁止 | セーブ破損時の部分復元でクラッシュしないようループ処理に変更 |

---

## Phase2-M1 Equipment Complete 決定（P2-Task005〜012）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D001 | Weapon / Armor / Accessory を同一設計思想（Data/Instance分離）で拡張する | 設計の一貫性確保。DataはResource定義、Instanceは個体情報を保持。拡張時のパターンを固定 |
| P2-D002 | 防御計算式: `max(1, enemy_attack - total_defense)` を採用 | 最低1ダメージ保証で戦闘が完全に無力化されることを防止 |
| P2-D003 | total_defense = armor.rolled_defense + accessory.defense_bonus の合算式を採用 | Armor と Accessory の防御効果を単純加算。将来の Resistance（属性）は別計算系に分離 |
| P2-D004 | ~~プレイヤーHP管理は DungeonScene が担当（CombatController は敵HPのみ）~~ **→ P2-D009に置き換え** | 冒険者個別HP対応に伴い変更 |
| P2-D005 | Accessory の効果値はダンジョン入室時に1回 load() してキャッシュする | 毎攻撃ごとの load() 呼び出しを避けパフォーマンスを保護。Armor は rolled 値をInstanceに保持するため load 不要 |
| P2-D006 | AccessoryInstance はロール値を持たない（fixed 値のみ） | Accessory はランダム性なし。効果値は AccessoryData をIDで参照。WeaponInstance / ArmorInstance との設計差分として明示 |
| P2-D007 | Appraisal の duck typing は `"weapon_id" in item` → `"armor_id" in item` → else（accessory）の elif 構造に統一 | アイテム種別の安全な識別。isinstance() 不使用。将来カテゴリ追加時は elif を追加する |
| P2-D008 | _get_effective_stats() を DungeonScene 内に設置し全装備効果を集約計算する | **P2-D009の戦闘仕様整合により廃止。** 装備効果計算は _calc_damage() / _calc_enemy_damage_to_member() に分散 |

---

## Phase2-M2 Combat Spec Alignment 決定（P2-Task009〜）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D009 | パーティHP管理を CombatController へ移管（P2-D004置き換え） | 冒険者3人個別HP・死亡判定・全滅判定を実装するため。CombatController.party_combat_hp[]: Array[int] で管理。DungeonSceneはUIのみ担当 |
| P2-D010 | 自動戦闘は CombatTimer 固定1.5秒（attack_speed は未接続） | MVPでは全員同タイミングで攻撃するシンプルな実装を優先。attack_speedをTimer.wait_timeに接続するのは将来フェーズ |
| P2-D011 | 全生存メンバーが同一の装備パラメータで攻撃する（MVP割り切り） | 個別装備は後フェーズのスコープ。MVP時点では GameState.equipped_weapon を全員共有 |
| P2-D012 | 全滅時は蓄積済み報酬のみ持ち帰る（ドロップ発生なし） | 敗北ペナルティの明確化。generate_run_loot() を呼ばずにResultSceneへ遷移 |
| P2-D013 | Armor HP Bonus は ArmorInstance に保存済みだが party_max_hp には未接続（将来実装） | CombatController移管時のスコープ制限。hp_bonusの戦闘接続は別Taskで対応 |
| P2-D014 | Accessory の load() はCombatTimer毎ティックで呼ぶ（キャッシュなし） | P2-D005のキャッシュ方針を廃止。1.5秒間隔のため実用上問題なし。GodotのResource cacheで対応 |

---

## Phase2-M3 Room System 決定（v3.4 反映分）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D015 | Branch Route は `DungeonData.branch_enabled` で ON/OFF | 王都跡は固定シーケンス維持。将来ダンジョンで分岐有効化 |
| P2-D016 | 分岐プール: Safe=HEAL/TREASURE, Dangerous=COMBAT, Unknown=COMBAT/HEAL/TREASURE | Phase2-M3 v3.4 確定スコープ。MID_BOSS/BOSS/EXIT は固定 |
| P2-D017 | HEAL Room は生存メンバー全員 +10 HP（最大 HP 上限） | `CombatController.heal_party(10)` |
| P2-D018 | TREASURE Room は Gold+30、20% で装飾品（silver_ring） | 探索中報酬累積。Result 前に inventory へ追加 |
| P2-D019 | EnemyData に 7+ パラメータ拡張・EnemyType enum 追加 | max_hp/attack/exp/gold は戦闘接続。move/detection/attack_range/critical_rate はデータ定義のみ |

---

## Phase2-M3 Merchant Room 決定（P2-Task015）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D020 | Merchant Room は武器を販売しない | 武器はドロップ→鑑定コアループの中心。商人は防具・装飾品・回復の支援役 |
| P2-D021 | Merchant 支払いは永続 Gold（`GameState.gold`） | 鑑定費用と同一通貨。探索中の Gold シンクとして機能 |
| P2-D022 | Merchant は SAFE / UNKNOWN Branch Pool から出現 | 安全・不明ルートの支援報酬。ボス前準備部屋として位置づけ |
| P2-D023 | 商品はカタログから 2 品ランダム提示・1 回限り購入 | 短時間・読みやすい UI。在庫永続管理は MVP 対象外 |

---

## Phase2-M3 Event Room 決定（P2-Task016）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D024 | Event Room は 2 択・即時解決。戦闘を発生させない | 数秒で完了する非戦闘 Special Room |
| P2-D025 | Event は UNKNOWN Branch Pool および固定シーケンスから出現 | Branch 多様化 + branch_enabled=false でも体験可能 |
| P2-D026 | 報酬 type: heal / gold / buff / material / lore（後2つは placeholder） | M3 初期カテゴリ。Shrine / Discovery 連動は対象外 |
| P2-D027 | Temporary buff は `run_damage_multiplier`（周回内のみ・セーブ非永続） | 1.15x 攻撃。探索終了でリセット |
| P2-D028 | Branch UNKNOWN Pool に EVENT を含める（v3.4.2 更新） | P2-D016 の Unknown 定義を Merchant/Event 反映で更新 |

---

## Phase2-M3 Elite Room 決定（P2-Task017）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D029 | Elite Room は常に戦闘。elite_pool から敵選択 | 高リスク Special Room。ボス mechanics は対象外 |
| P2-D030 | Elite 報酬: EXP/Gold x1.5 + ボーナスドロップ（防具/装飾品/素材placeholder） | 通常戦闘より高報酬。deterministic 倍率 + 確率ボーナス |
| P2-D031 | Elite は DANGEROUS Branch Pool および固定シーケンス index 4 | 危険ルートの核心 |
| P2-D032 | elite_pool 敵は enemy_type=ELITE | rusted_knight / ruins_looter を ELITE 化 |
| P2-D033 | Branch DANGEROUS Pool に ELITE を含める（v3.4.3 更新） | P2-D016 Dangerous 定義を ELITE 反映で更新 |

---

## Phase2-M3 Discovery System 決定（P2-Task018）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D034 | 発見登録は `GameState.discovery_registry`（category:entry_id） | Codex 基盤。UI なし M3 |
| P2-D035 | カテゴリ: room / enemy / event / lore / material | M3 最小スコープ |
| P2-D036 | 新規発見は LabelLog に `【新規発見】` 追記 | デバッグ・検証用可視化 |
| P2-D037 | dungeon_progress.discovery float は既存維持（登録型と別） | 戦闘バランス変更なし。将来 hidden 解放用 |
| P2-D038 | lore/material は placeholder ID 登録のみ（Codex/MaterialData 未実装） | 将来拡張のフック |

---

## Phase2-M3 SkillData 決定（P2-Task019）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D039 | SkillData は Resource。skill_type で player/enemy/boss/job を区別 | 将来スキル種別を同一スキーマで定義 |
| P2-D040 | trigger_type は M3 placeholder（"cooldown"）。power_multiplier で倍率表現 | SkillExecutor 未実装。最小フィールドで拡張可能 |
| P2-D041 | M3 では DataRegistry 参照のみ。SkillExecutor / 戦闘接続なし | 戦闘再設計・バランス変更を避ける |

---

## Phase2-M3 DataRegistry 決定（P2-Task020）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D042 | DataRegistry は id → `resources/{category}/{id}.tres` の lookup 層 | 6 カテゴリを単一 Autoload で参照 |
| P2-D043 | 既存 inline load() は M3 で一括置換しない。新規コードは DataRegistry 推奨 | リスク回避。段階移行 |
| P2-D044 | AffixData / JobData / drop_table は M3 未サポート | 将来拡張。エディタ UI 不要 |

---

## Phase2-M4 Multi-Dungeon 決定（P2-Task021）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D045 | 探索対象 DG は `GameState.current_dungeon_id`。空なら `Constants.DEFAULT_DUNGEON_ID` | 単一 hardcode 排除。Task022 で UI 選択 |
| P2-D046 | `DungeonController.start_dungeon` は id 引数 + `DataRegistry.get_dungeon_data` | M3 DataRegistry SSOT 継続 |
| P2-D047 | EVENTS / MERCHANT_CATALOG は M4 Task021 では DG 分離しない | 王都跡挙動維持。2 DG 目追加時に分離 |

---

## Phase2-M4 Base Dungeon Select 決定（P2-Task022）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D048 | BaseScene に最小 DG 選択 UI。探索ボタンは「探索開始」 | プレイヤーが DG を明示選択 |
| P2-D049 | 白骸墓地 id は `graveyard`。未登録時は「準備中」disabled | Task023 までコンテンツ追加しない |
| P2-D050 | 探索開始は DataRegistry に存在する id のみ許可 | 不正 id 遷移防止 |

---

## Phase2-M4 Graveyard Dungeon 決定（P2-Task023）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D051 | 白骸墓地 id = graveyard。difficulty 2、branch_enabled = true | 2 DG 目。Branch 体験を Graveyard で提供 |
| P2-D052 | 敵 6 体（通常 4 / Elite 1 / Boss 1）。AI は default 維持 | コンテンツ追加のみ。戦闘再設計なし |
| P2-D053 | BOSS 部屋は `DungeonData.boss_id` を使用（pick_combat_enemy_data） | 王都跡含め boss 出現を正しく接続 |

---

## Phase2-M4 MaterialData 決定（P2-Task024）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D054 | 素材は `MaterialData` Resource + `material_inventory`（id→quantity） | Event/Elite placeholder 解消 |
| P2-D055 | M4 取得経路: Event relic_shard / Elite elite_relic_shard のみ | 最小接続。クラフト未実装 |
| P2-D056 | ancient_bone / cursed_iron はサンプル定義のみ（ドロップ未接続） | 将来 DG/イベント拡張用 |

---

## Phase2-M4 Milestone Closeout（2026-06-21）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D057 | **Phase2-M4 を完了**とする。Task021〜024 が SSOT 確定 | World Expansion Foundation 達成 |
| P2-D058 | Multi-Dungeon 基盤確立（2 DG playable・Base 選択・DataRegistry 起動） | M4 核心成果 |
| P2-D059 | MaterialData 基盤確立（inventory + Event/Elite 接続） | placeholder 解消 |
| P2-D060 | **Combat Depth（SkillExecutor）は Phase2-M5 で開始** | M4 は世界拡張のみ。戦闘深みは M5 |

---

## Phase2-M5 SkillExecutor 決定（P2-Task025）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D061 | SkillExecutor は RefCounted。`effect_type = damage` のみ実行 | 最小 M5 基盤。heal/buff は無視 |
| P2-D062 | M5 プレイヤースキルは `slash_attack` 固定（`Constants.DEFAULT_PLAYER_SKILL_ID`） | 武器 fixed_skill_id は将来 Task |
| P2-D063 | cooldown は CombatTimer tick 単位で `tick(COMBAT_TICK_INTERVAL)` | slash_attack cooldown 3.0s / tick 1.5s |
| P2-D064 | スキルは通常攻撃に**追加**ダメージ。敵戦闘・Skill UI 変更なし | 既存ループを壊さない |

---

## Phase2-M5 Weapon Skill Link 決定（P2-Task026）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D065 | 戦闘スキルは `WeaponData.fixed_skill_id` → `DataRegistry.get_skill_data` で解決 | 武器主役の progression 方針 |
| P2-D066 | `fixed_skill_id` 空または SkillData 未取得時は `DEFAULT_PLAYER_SKILL_ID` にフォールバック | 未装備・旧武器互換 |
| P2-D067 | iron_sword のみ `fixed_skill_id = slash_attack`。rusted_blade は空（フォールバック検証用） | 既存 2 武器で差分確認 |
| P2-D068 | 戦闘ログに武器 display_name / スキル display_name を表示 | 武器差の可視化。UI 追加なし |

---

## Phase2-M5 Job Foundation 決定（P2-Task027）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D069 | JobData Resource を最小スキーマで追加 | 将来 job build の data 層 |
| P2-D070 | DataRegistry `get_job_data(id)` → `resources/jobs/{id}.tres` | 既存 lookup 規約継続 |
| P2-D071 | M5 サンプル: warrior / guardian / scout | 3 ロール代表。戦闘未接続 |
| P2-D072 | Adventurer.job_id との自動解決・ステ補正・UI は M5+ | データ準備のみ |

---

## Phase2-M5 Milestone Closeout（2026-06-21）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D073 | **Phase2-M5 を完了**とする。Task025〜027 が SSOT 確定 | Combat Depth Foundation 達成 |
| P2-D074 | SkillExecutor + 武器 fixed_skill_id スキル接続を M5 核心成果とする | 戦闘深度の第一歩 |
| P2-D075 | JobData 基盤確立（lookup のみ） | Job 本実装は M6+ |
| P2-D076 | **次マイルストーン候補: Phase2-M6 Equipment Depth Foundation** | Affix / 装備深度を M6 で計画 |

---

## Affix Bible 決定（Affix_Bible_Completed v1.0 — 2026-06-21）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D077 | MVP Affix 容量 **固定**: Weapon Prefix×1 + Suffix×1 / Armor Prefix×1 / Accessory Prefix×1 | Recommended だと実装が迷う |
| P2-D078 | AffixData `stat_type` 登録単位を 13 種で固定（Attack〜Exploration） | AffixData.tres 作成容易化 |
| P2-D079 | Legendary Affix は **新 play style** を生む。単純数値増（例 +500 ATK）禁止 | identity over raw power |
| P2-D080 | Affix_Bible_Completed_v1.0 を M6 Affix 系 Task の Design Reference として採用 | P2-Task028 入力 SSOT 前参照 |

---

## Repository Cleanup Policy 決定（2026-06-21）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D081 | **ProjectDocs ZIP はリポジトリ管理対象外**。正式 SSOT は `docs/`。ZIP は Release Artifact | 重複 SSOT 回避 |
| P2-D082 | **Proposal は Completed 後も削除しない** | Proposal → Completed → Decision 履歴 |
| P2-D083 | Lore（16/17/18）は当面 **`docs/specs/game/`** が正式配置先 | WorldArchive 移動は Lore 完成後 |
| P2-D084 | **Git Commit は Milestone 単位で分割**（Gameplay / ProjectDocs / Cleanup 等） | 大量一括 commit 回避 |

---

## Phase2-M6 AffixData Foundation 決定（P2-Task028）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D085 | AffixData 最小スキーマ（id, affix_category, stat_type, value, tags 等） | Affix Bible → 実装可能 data 層 |
| P2-D086 | `stat_type` は Affix Bible §6 の 13 種に整合 | AffixData.tres 作成容易化 |
| P2-D087 | `get_affix_data(id)` → `resources/affixes/{id}.tres`（`RESOURCE_AFFIXES_PATH`） | DataRegistry 規約継続 |
| P2-D088 | Task028 は lookup のみ。Roll / Appraisal / 戦闘 / Save 未接続 | Foundation のみ |

---

## Phase2-M6 Affix Roll 決定（P2-Task029）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D089 | AffixRoller は `scripts/equipment/AffixRoller.gd`（RefCounted） | equipment ドメイン配置 |
| P2-D090 | MVP スロット: weapon P+S / armor P / accessory P（Bible 固定） | P2-D077 継続 |
| P2-D091 | 候補フィルタ: affix_category + tags + rarity tier | 不正 Affix 排除 |
| P2-D092 | Task029 は roll 結果 Dictionary のみ。Appraisal / Instance / Save 未接続 | 段階統合 |

---

## Phase2-M6 Affix Appraisal 決定（P2-Task030）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D093 | 鑑定完了時に `AffixRoller.roll_for_equipment()` を呼ぶ | Weapon Discovery → Appraisal → Affix ループ |
| P2-D094 | Instance に `prefix_ids` / `suffix_ids`（Array[String]）を保存 | Roll 結果の最小永続化 |
| P2-D095 | SaveManager が affix ID 配列を serialize（後方互換: 欠落時空配列） | 鑑定後の再読込 |
| P2-D096 | Task030 は Reveal 表示のみ。戦闘 stat 反映は後続 Task | 段階統合 |

---

## Phase2-M6 Affix Stat 決定（P2-Task031）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D097 | `AffixStatCalculator` は `scripts/equipment/AffixStatCalculator.gd` | equipment ドメイン配置 |
| P2-D098 | 鑑定済み装備の Affix ID のみ stat 反映（`is_appraised`） | Task030 ループ整合 |
| P2-D099 | Task031 対応 stat: Attack / Defense / HP / Critical / Gold Gain / Material Gain / Healing | MVP 最小 |
| P2-D100 | run Gold は `DungeonController.accumulate_rewards()` で倍率適用 | 単一接続点 |

---

## Phase2-M6 Equipment Detail UI 決定（P2-Task032）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D101 | `AffixDisplayFormatter` は UI 専用（`scripts/equipment/`） | stat 計算と分離 |
| P2-D102 | Affix 表示は `is_appraised == true` のみ | 未鑑定 conceal |
| P2-D103 | 表示形式: 名称行 + stat_type/value 行（Gold Gain は %） | 比較可読性 |
| P2-D104 | Task032 は表示のみ。gameplay / stat 計算は変更しない | UI Task 境界 |

---

## Phase2-M6 Milestone Closeout（2026-06-21）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D105 | **Phase2-M6 を完了**とする。Task028〜032 が SSOT 確定 | Equipment Depth Foundation 達成 |
| P2-D106 | **Affix ループ確立:** AffixData → Roll → Appraisal → Instance → Stat → Equipment UI | Core Loop 完成 |
| P2-D107 | Affix gameplay 効果（Attack/Defense/HP/Critical/Gold/Material/Healing）確立 | Task031 正式採用 |
| P2-D108 | 高度 Affix（reroll / Legendary / Curse / Material usage）は **Defer** | M6 スコープ外 |
| P2-D109 | **次マイルストーン候補: Phase2-M7 UI / UX Foundation** | 可読性・モバイル polish を M7 で計画 |

> **注:** P2-D111 により M7 正式名称は **Job & Build Foundation** に変更。P2-D109 の UI/UX 名称は置換済み。

---

## Phase2-M6 Closeout — Master Plan Sync（2026-06-21）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D110 | M6 Closeout 後に **Development Master Plan v1.1** を ProjectDocs と同期 | SSOT 整合 |
| P2-D111 | **Phase2-M7 正式名称: Job & Build Foundation** | Job を weapon-centric の支援層として接続 |
| P2-D112 | Material Usage Planning を **Future Craft & Economy Foundation** Milestone へ移管 | M6/M7 スコープから除外 |

---

## Phase2-M7 Scope Adoption（2026-06-21）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D113 | **Phase2-M7 正式 Scope** を `Phase2-M7_Scope_Proposal_v1.0.md` 通り採用 | DevelopmentHQ 承認 |
| P2-D114 | Job modifier は **パーティメンバー単位** に適用（共有装備でも per-member） | Build Identity |
| P2-D115 | stat 合成順序: base → Affix → **Job multiply** → crit / run mult | 合成バグ防止 |
| P2-D116 | `starting_skill_ids[0]` のみ MVP。Job skill = **Secondary**、武器 fixed_skill = **Primary** | Weapon-Centric |
| P2-D117 | Primary と同一 SkillData id の Secondary は **実行しない** | 二重 skill 防止 |
| P2-D118 | MVP パーティ job_id = **warrior / guardian / scout** | JobData SSOT 整合 |
| P2-D119 | `JobStatCalculator` は `scripts/equipment/JobStatCalculator.gd` | AffixStatCalculator 同型 |
| P2-D120 | Job UI は **BaseScene 読み取り専用** | MVP |
| P2-D121 | Build Summary は **EquipmentScene 内 1 ブロック**（Task037 は Task033+034+032 依存） | 保守性 |
| P2-D122 | M7 Task 計画: **P2-Task033〜038**（038 = Closeout） | Milestone 分解 |

---

## Phase2-M7 Party Job Alignment 決定（P2-Task033）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D123 | MVP パーティ初期 job_id = **warrior / guardian / scout** | JobData SSOT 整合（P2-D118 実装） |
| P2-D124 | `JobStatCalculator` は Job modifier 読み取りの標準ヘルパー | AffixStatCalculator 同型 |
| P2-D125 | Task033 は Calculator + party 整合のみ。**戦闘反映は Task034** | 段階統合 |

---

## Phase2-M7 Job Combat Integration 決定（P2-Task034）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D126 | Task034 で P2-D115 合成順序を **CombatController / DungeonScene** に実装 | HP / ATK / DEF |
| P2-D127 | Job 戦闘接続は **CombatController + DungeonScene のみ**。SkillExecutor / UI / Save 非変更 | 最小 diff |
| P2-D128 | 被弾 Defense は **被弾メンバー index** の job def modifier を適用 | P2-D114 per-member |

---

## Phase2-M7 starting_skill_ids Combat Link 決定（P2-Task035）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D134 | `_get_job_skill_data(member_index)` で攻撃メンバーの `starting_skill_ids[0]` を SkillData として解決 | P2-D116 実装。job_id 空 / JobData なし / starting_skill_ids 空 → null |
| P2-D135 | `_try_cast_secondary_skill` で Primary と同一 SkillData id の場合は実行しない | P2-D117 実装。warrior + slash_attack 武器 → Primary のみ（二重なし） |
| P2-D136 | Secondary Skill 未設定・未取得は安全スキップ。guardian / scout 空は正常系 | クラッシュなし fallback |

---

## Phase3 Split Adoption 決定（Project Structure）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D129 | Phase3 を **Phase3-A（Visual Production）** + **Phase3-B（Content Expansion）** へ分割採用 | Phase3 Split Proposal v1.0 |
| P2-D130 | **Phase3-A Visual Production** = スプライト / UI art / テーマ / 演出アセット制作。**gameplay 仕様変更なし** | Pixel Apprentice 主担当 |
| P2-D131 | **Phase3-B Content Expansion** = ダンジョン / 敵 / イベント / Affix プール / Legendary 等の **コンテンツ量産** | Game Designer 主担当 |
| P2-D132 | Phase 再編: **Phase4 = Polish**、**Phase5 = Release Preparation**（旧 Phase4 Content / Phase5 Release を再配置） | Roadmap 整合 |
| P2-D133 | `04_Development_Master_Plan.md` の Phase 構造を P2-D129 分割に同期更新 | Master Plan SSOT |

### Responsibility（P2-D129 採用）

| 役割 | 担当 |
|---|---|
| Decision / Review / SSOT | DevelopmentHQ |
| Repository / Document 更新 | Claude Code |
| Visual Production | Pixel Apprentice |
| Content Expansion Design | Game Designer |

---

## Phase2-M7 Milestone Closeout（2026-06-22）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D137 | **Phase2-M7 を完了**とする。P2-Task033〜037 が SSOT 確定 | Job & Build Foundation 達成。EC-1〜4 全確認 |
| P2-D138 | **次マイルストーン候補: Phase2-M8 Craft & Economy Foundation** | Material data（M4）と Job/装備基盤の上に Craft ループを積む（P2-D112） |

---

## Phase2-M8 Scope Adoption（2026-06-22）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D139 | **Phase2-M8「Craft & Economy Foundation」正式 Scope 採用**（Design v1.0 + Task Proposal v1.0 通り） | DevelopmentHQ 承認 |
| P2-D140 | CraftData スキーマ（id / display_name / required_materials / gold_cost / output_type / output_id / unlock_condition）を **SSOT 確定** | Design §2-2 正式採用 |
| P2-D141 | **MVP レシピ 3 件採用**: craft_leather_armor / craft_silver_ring / craft_bone_armor。素材・Gold コストは Design §2-3 通り | Economy バランス確認済み |
| P2-D142 | **MVP では Weapon クラフト不可**。output_type="weapon" は将来拡張予約のみ | Special Room Bible 継承（P2-D112） |
| P2-D143 | **consume_materials() は GameState に配置**。専用 CraftController 新規作成なし | アーキテクチャ最小差分 |
| P2-D144 | **Merchant Materials 購入（P2-Task043）を M8 スコープとして正式計画**。価格: relic_shard 20G / ancient_bone 20G（MaterialData.value 基準） | Gold/Material 双方向循環 |
| P2-D145 | **P2-Task039（CraftData Foundation）は Craft Resource Pack で完了済み**（M7 並行 Task）。M8 実装開始は P2-Task040 から | SSOT 整合 |

---

## Lore Bible Adoption（2026-06-22）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D146 | **22_DungeonBible.md を ProjectDocs SSOT として正式採用**。Dungeon探索参照の一元管理確立 | DevelopmentHQ 承認済。既存 Lore のみ収録。Gameplay 仕様記載なし |
| P2-D147 | **23_FactionBible.md を ProjectDocs SSOT として正式採用**。勢力・組織の一元管理確立（F-001〜F-007 + 王国内行政機関） | DevelopmentHQ 承認済。既存 Lore のみ収録。Gameplay 仕様記載なし |

---

## Phase2-M9 Codex & Discovery Scope Adoption 決定（P2-Task045）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D148 | Phase2-M9「Codex & Discovery Foundation」Scope を **正式採用** | `Phase2_M9_Codex_Discovery_Scope_Proposal_v1.0.md` |
| P2-D149 | Codex MVP カテゴリ = **Enemy / Dungeon / Material / Weapon / History** | Proposal §2.1 |
| P2-D150 | `discovery_registry` **Save 形式不変**。category 拡張（`dungeon` / `weapon`）のみ許可 | Proposal §4 |
| P2-D151 | Codex UI = **BaseScene 遷移・閲覧専用**（報酬 / Unlock なし） | Proposal §1.3 |
| P2-D152 | History Bible MVP = **サブセット表示**（全 66 件一括非表示） | Proposal §9 R-1 |
| P2-D153 | M9 Task 計画: **P2-Task045〜050**（050 = Closeout） | Proposal §6 |

---

## DevelopmentHQ Cursor Migration（2026-06-23）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D154 | **DevelopmentHQ を ChatGPT ブラウザから Cursor HQ セッションへ移行** | リポジトリ直接アクセスによるレビュー・運用効率化。`06_DevelopmentHQ_Operations.md` を SSOT 化 |
| P2-D155 | **AI 実装は Cursor Impl セッションに統一**（Claude Code 併用時も同一ルール・HQ レビューは Cursor） | Task Bundle / スコープ制約を維持しつつツール分業を廃止 |
| P2-D156 | **Phase3 順序を Phase3-A（Visual）→ Phase3-B（Content）で正式採用** | Alpha 基盤完成後、見た目整備を先行しコンテンツ量産の評価基盤を確立 |
| P2-D157 | **ChatGPT 向け `■ Task:` コピペ報告フローを廃止** | 情報の正はリポジトリ更新のみ。`.cursor/rules/developmenthq-operations.mdc` に置換 |
| P2-D158 | **ProjectDocs ZIP を Git リポジトリに含めない**（`.gitignore` で `*.zip` 除外） | P2-D081 継続。既存ルート ZIP は削除 |

---

## World Assets Bible Adoption（2026-06-23）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D159 | **`World_Assets_Bible_v1.1` を ProjectDocs SSOT として正式採用**（`25_WorldAssetsBible.md`） | オーナー承認。12 World Pillars を世界観基幹とする |
| P2-D160 | **World Pillars A-01〜A-12** をロア設計の上位概念として確定 | Proposal レビュー Exit Criteria |
| P2-D161 | **九王時代と九王戦争の時系列を統一** — 秩序の時代ののち大戦で王国時代終焉。当事者は未解明 | `03_世界観` / HE-002 との整合 |
| P2-D162 | **伝説武器・竜の改名を採用** — 継承剣レガート、翠杖ヴェルド、深竜トレンチャ、シルヴァーン王国 | ネーミングレビュー承認 |
| P2-D163 | **A-10 灯火（The Last Flame）** を World Pillar として新規採用 | raw 欠落分の執筆・承認 |
| P2-D164 | **Phase9 メインストーリー（終わりなき回廊叙事詩）をゲーム本編スコープ外**とする | ハクスラ軽量ループ・原則2との整合 |
| P2-D165 | **王国設定の正は五王国（K-001〜005）**。GPT 草案の九王国現役設定は不採用（神話古地名としてのみ可） | `19_KingdomBible.md` SSOT 優先 |

---

## Combat Vision Adoption（2026-06-23）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D166 | **`26_CombatVision.md` を戦闘設計の長期 SSOT として正式採用** | DevelopmentHQ / GPT 協議内容の反映。Invariant: プレイヤー＝指揮官、AI 自律戦闘 |
| P2-D167 | **Combat Vision の Core Concept / Player Role / Development Rule は長期不変** | 新システム追加時も「指揮官＋AI 自律」を維持 |
| P2-D168 | **現行 Alpha 実装（CombatTimer・部屋ステップ）と Vision の関係を明示** | `01_MVP方針決定` §3 はマクロ進行。Vision は戦闘表現・リアルタイム自律の将来正。`08_戦闘_AI.md` にギャップ表 |

---

## Design Pipeline v1.1（2026-06-23）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D169 | **設計パイプラインを `06_DevelopmentHQ_Operations.md` v1.1 に明文化** — Spark → Proposal → Decision → Spec → Task → Impl。GPT 協議は Proposal 必須 | 戦闘 Vision 等の未反映協議を防ぐ |
| P2-D170 | **状態異常・属性は Proposal 検討完了**（`Phase3B_Status_Element_Combat_Proposal_v1.0.md`） | Tier1=出血/毒/鈍化、属性5種、麻痺/睡眠は Tier3 保留 |

---

## Status & Element Combat Adoption（2026-06-23）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D171 | **`27_状態異常と属性.md` を ProjectDocs SSOT として正式採用** | オーナー承認。Combat Vision 準拠 |
| P2-D172 | **属性 5 種を確定** — physical / ember / frost / venom / curse | 弱点 ×1.25 / 耐性 ×0.75。6 種以上は拡張禁止（当面） |
| P2-D173 | **Tier1 状態異常 3 種を第一実装対象** — bleed / poison / slow。出血数値（5s / 20%/tick / 5 stack）を SSOT 化 | `08_戦闘_AI.md` 将来仕様を統合 |
| P2-D174 | **Tier3（麻痺 / 睡眠 / 凍結 / 沈黙）を実装保留**。スタン・鈍化で代替 | 「見て分かる」戦闘との整合 |
| P2-D175 | **Phase3-B-M1「Status & Element Foundation」** を Combat Depth の第一 Milestone 候補として計画 | Task 順は `27_状態異常と属性.md` |

---

## Phase2-M9 Milestone Closeout（2026-06-23）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D176 | **Phase2-M9 を完了**とする。P2-Task045〜050 Exit Criteria 達成（EC-6 は Deferred 明示） | Codex & Discovery Foundation 達成 |
| P2-D177 | **Impl は Claude Code 最大 2 セッション並行**（16GB MacBook Air）。HQ は Cursor。git worktree 推奨 | 運用効率・RAM 制約 |

---

## Phase3 開始（2026-06-23）

| # | 決定事項 | 根拠 |
|---|---|---|
| P2-D178 | **次マイルストーンを Phase3-A Visual Production とする**（P2-D156 継続） | M9 完了後の公式順序 |

---

## Phase3-A Scope Adoption 決定（2026-06-24）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D001 | **Phase3-A Visual Production Scope を正式採用**（`Phase3A_Scope_Adoption_Completed_v1.1.md`） | オーナー承認。IN/OUT・Exit Criteria・P0/P1/P2 リスト確定 |
| P3-D002 | **全アイコン（素材含む）キャンバス 64×64 統一**。UI 表示は Godot 側でスケール | D-PA-001 承認。Request Pack v1.0 の素材 32×32 指定は不採用 |
| P3-D003 | **ファイル名にサイズサフィックスなし**（例: `ICO_WPN_IronSword.png`） | D-PA-002 承認。Visual Production v1.0 命名規則に統一 |
| P3-D004 | **敵スプライト `ENM_BoneWalker_Sheet`** を採用（`ENM_Skeleton` 不採用） | D-PA-003 承認。`bone_walker` ゲーム id と一致 |
| P3-D005 | **Phase3-A 開始時はシステムフォント維持**。Bitmap Font は P0 UI Frame 承認後の Batch 2 | D-PA-004 承認 |
| P3-D006 | **TileSet は手動マッピング**（AutoTile / Terrain は Phase3-B 工廠 DG で検討） | D-PA-005 承認 |
| P3-D007 | **P0 制作を 3 段階 Batch** — (1) UI Frame → (2) Icons → (3) Tileset+Sprites | D-PA-006 承認 |

---

## Phase3-A Closeout 決定（2026-06-25）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D008 | **P3-A-009 B-2/B-3 を P2 格下げ** — `FX_Hit_Critical.png`、RoyalRuins 補完タイル 3 件（Floor_02 / Floor_Cracked / Wall_02）は Phase3-A Closeout ブロッカーとしない | Impl 未接続・EC-7/EC-6 は既存アセットで充足。オーナー承認（P3-A-009） |
| P3-D009 | **Phase3-A Closeout 必須条件は EC-1〜7 全 PASS**。EC-8 は P1 納品照合で別途記録 | Scope v1.1 §2 維持。B-1（Godot `.import`）解消後に EC-3/7 実機確認 |
| P3-D010 | **`.import` は `.gitignore` 維持・リポジトリ非コミット**。各環境で `smoke_test.sh --import-only` 実行が正規フロー | Godot 標準運用。CommitPlan の import commit は方針撤回 |
| P3-D011 | **OD-UI-001 戦闘画面 — `UI_Reference_003_07_Battle_Auto_v2` を採用**（Phase UI-1）。段階的寄せ（B）第 1 段 | オーナー承認。手動戦闘なし・タイマー/下部ナビ/カード列/獲得予定除外 |
| P3-D012 | **Phase UI-1 実装前提** — (1) 縦長スマホ固定 (2) バトルフィールド主体・RoomArt は背景化 or 非表示 (3) ≡ メニューは探索終了のみ (4) x1=1.5s / x2=0.75s・停止=Timer 停止のみ | オーナー承認（2026-06-25） |
| P3-D013 | **アセット生成分担** — **PA = どうしても必要なもの**（キャラ/敵スプライトシート・ICO 等）。**ChatGPT 生成 = 代替可能なもの**（背景・雰囲気用 art 等） | オーナー承認。コスト・速度最適化 |

## Phase UI-1 Closeout 決定（2026-06-25）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D014 | **Phase UI-1 Closeout — EC-UI-1〜7 全 PASS**。次マイルストーン **Phase3-B-M1**（状態異常・属性）へ | P3-UI-001〜003 + 002b 完了。`smoke_test` PASS |
| P3-D015 | **Phase UI-2 へ格下げ** — (1) 浮動ダメージ数字 (2) 縦長 viewport 固定（P3-D012 未着手分） (3) HP バー座標のスプライト追従 (4) バトルログ UI 枠 art (5) CHR/敵 vs v2 背景の位置微調整 | v2 第 1 段の IN だが Closeout ブロッカーとしない。モック寄せは段階的（P3-D011 B） |

## Phase3-B-M1 着手（2026-06-25）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D016 | **Tier1 poison / slow 暫定数値** — poison: 5 tick / stack 3 / flat 4 per tick。slow: 3 tick / stack 1 / interval_multiplier 1.5（P3-B-002 MVP: 敵攻撃 50% スキップ） | SSOT 未記載。M1 暫定 |
| — | **P3-B-001 完了** — StatusEffectData + Tier1 tres + DataRegistry + element フィールド | bleed SSOT 一致 |
| P3-D017 | **Phase3-B-M1 Closeout — EC-B-1〜7 全 PASS** | P3-B-001〜007 完了 |
| P3-D018 | **OD-UI-002 キャラ別装備 GO** — `Adventurer.equipped_*` を正とし `GameState` グローバル装備を廃止。1 instance = 1 メンバーのみ。旧セーブは member0 へ移行 | オーナー承認（A） |

## Phase EQ-1 Closeout（2026-06-25）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D020 | **Phase EQ-1 Closeout — EC-EQ-1〜5 全 PASS** | P3-EQ-001〜004 完了。`smoke_test` PASS |
| — | **EC-EQ-1** per-member `equipped_*` + Save 移行 | GameState / SaveManager |
| — | **EC-EQ-2** 戦闘 stat per-member | DungeonScene / CombatController / AffixStatCalculator |
| — | **EC-EQ-3** EquipmentScene メンバー選択 | EquipmentScene |
| — | **EC-EQ-4** BaseScene パーティ装備表示 | BaseScene |
| — | **EC-EQ-5** 1 instance = 1 member 排他 | EquipmentController |

## Phase3-B-M2 着手（2026-06-25）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D021 | **Tier2 暫定数値** — burn: flat 3/tick / stack 3 / incoming×1.15。stun: 2 tick / skip 100%。weak: outgoing×0.75 / 3 tick | M1 暫定と同様。SSOT 追記は Closeout 時 |
| — | **P3-B-008〜010 着手** — burn/stun/weak + StatusResolver 拡張 + 戦闘接続 | Tier2 Backlog |

## Element & Status Redesign（2026-06-25）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D022 | **属性を 5 種に刷新** — `fire` / `ice` / `thunder` / `dark` / `holy`。無属性 `""` は弱点ボーナスなし。弱点時 ×1.25 のみ（耐性ペナルティ廃止） | オーナー承認。モンハン型 |
| P3-D022a | **状態異常 6 種** — poison / chill / shock / ignite / curse / stun。旧 bleed/slow/weak/burn 廃止 | オーナー承認 |

## Element & Status Closeout（2026-06-25）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D023 | **Phase3-B-M2 Closeout — 属性5種+状態6種 実装完了** | P3-D022 体系。Affix 4種 / スキル3種 / 武器5種。`smoke_test` PASS |

## Phase EQ-1 着手（2026-06-25）

| # | 決定事項 | 根拠 |
|---|---|---|
| — | **Phase EQ-1 Scope** — P3-EQ-001 データ/Save → P3-EQ-002 戦闘 → P3-EQ-003 UI | P3-D018 |

## Combat Initiative（2026-06-25）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D019 | **戦闘ターン順の長期方針 — イニシアチブ（C）を Combat Vision 整合の正式目標とする**。Alpha 検証中は現行どおり **味方先制固定**（`08_戦闘_AI.md` 1ティック順序）を維持。Alpha 後も Decision + Task で差し替え可 | オーナー承認。先制固定は过渡期。防御・速度ビルドの可視化にはイニシアチブが必要 |
| P3-D019a | **段階導入** — (1) 単純速度 stat で先攻/後攻 (2) ジョブ・Affix 補正 (3) Front/Mid/Back 位置 AI と統合。数値・API は Task 化時に `08_戦闘_AI.md` / `26_CombatVision.md` へ | P2-D168 Alpha↔Vision ギャップ。P2-D010 attack_speed 未接続の後継 |

## Game Design Review（2026-06-25 — オーナー全件承認）

**SSOT:** `28_ゲームデザイン点検.md`

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D024 | **GD 点検 Closeout** — bleed/方針/召喚 MVP 等の spec 陳腐化を一括同期 | オーナー承認 |
| P3-D024a | **Alpha プレイヤー役割 = 準備専用** — 意思決定は拠点・帰還後。旧「探索優先/戦闘優先…」4 方針は **Backlog**（Phase 2 で最小 2〜3 種から段階導入） | Vision↔Alpha ギャップ解消 |
| P3-D024b | **簡易ヘイトを P1 Combat** — 敵単体攻撃時 Guardian / Front 優先被弾を Initiative 前に実装 | タンク fantasy 可視化 |
| P3-D024c | **武器 `stun_power` は接続時 `stagger_power` へリネーム** — 状態 `stun` と混同防止。未接続 stat は UI 非表示 | 命名衝突 |
| P3-D024d | **呪い — 当面プレイヤー→敵 debuff のみ**。敵→味方 curse はエリート以降 or 状態 UI 整備後 | 観察ゲームでの敗因可読性 |
| P3-D024e | **Alpha: ジョブ＝stat ロール、武器種制限なし**。`preferred_weapon_types` 小ボーナスは P2 | 06 vs 実装データの整合 |
| P3-D024f | **ループ UX P2** — 一括鑑定・装備比較 1 行・Gold 用途 SSOT 再整理 | 5 分周回摩擦 |
| P3-D024g | **ダンジョン別ビルドフック** — 王都=弱点属性 / 墓地=状態異常 / 工廠=感電+機械 | コンテンツ役割明確化 |
| P3-D024h | **MVP 3 ビルド検証** — 状態異常・属性弱点・クリティカル（出血・召喚は Backlog） | 02_MVP設計 更新 |
| P3-D024i | **属性 vs 状態 — Codex/チュートリアル 1 画面を P1 UX 必須** | P3-D022 学習コスト |
| P3-D024j | **聖属性武器 1 本を P1 Content** | 5 属性 asymmetric 解消 |
| P3-D024k | **弱点敵比率 — 上げすぎない**（全員属性武器必須化を避ける） | ビルド自由度 |

## Phase 3 優先順（2026-06-25 — オーナー承認）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D025 | **Phase 3-B（コンテンツ）を Phase 3-A（ビジュアル本格化）より先行**。中身（敵・DG・イベント等）を先に埋める | オーナー判断。画面未確定のうちの全面 polish は差し戻しリスク |
| P3-D025a | **Phase 3-A フル Closeout / 全画面 mock 寄せは後 Phase で一括**（UI_Reference 003 系）。現行は UI-2+ 仮 UI + 既存 PA 差し替え可能分のみ維持 | C-lite で戦闘ホットスポットのみ随時可。メイン画面・敵グラフィックの本番化はコンテンツ固着後 |
| P3-D025b | **P3-D024a Phase 2（ラン中方針）は 3-B 一段落後** — Alpha 準備専用を維持しつつコンテンツ検証を優先 | 方針 UI はレイアウト再変更を招くため |

## 世界観刷新 — Postwar Ecology（2026-06-26 — オーナー決定）

**SSOT:** `29_PostwarEcology.md` 〜 `36_JobBible.md`（新規 Bible 8 件）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D026 | **世界観を「戦後生態系（Postwar Ecology）」へ刷新** — 三本柱 History / Relics / Ecology。モンスターは全て実在生物由来。アンデッド・悪魔・スライム等の異世界起源種は排除 | オーナー決定。`29_PostwarEcology.md` |
| P3-D027 | **モンスター分類体系 Class I〜VII** 採用（獣/鳥/爬虫/昆虫/水棲/菌植物/古代種）+ 地域派生 | `30_EcologyClassification.md` |
| P3-D028 | **探索者ギルド（調査管理機構）** を組織設定の正とする。評価軸は討伐数でなく発見・調査成果 | `31_SeekersGuild.md` |
| P3-D029 | **Biome 体系** — DG を生態系単位として設計。MVP は モーンゲート（王都地下）/ ウィスパーウッド（ヴェルディア） | `32_BiomeBible.md` |
| P3-D030 | **Ecology Codex（5 段階調査）** を図鑑方針とする。コンプより「世界理解」を重視 | `33_EcologyCodex.md` |
| P3-D031 | **モンスター命名** — 漢字/カタカナ両用可。実在生物ベース必須 | `34_MonsterNamingGuide.md` |
| P3-D032 | **エルド大陸（World Geography v1.0）** を現在の探索地理の正とする。旧王国地理は History 柱として保持 | `35_WorldGeography.md` |
| P3-D033 | **基本ジョブ 5 種**（ソードマン/レンジャー/ヴァンガード/アルケミスト/ビーストテイマー）。上位下位職なし。旧 5 ジョブ・上位ジョブ候補は Superseded | `36_JobBible.md` |
| — | **整合課題（実装移行は将来 Task）** — 既存敵の生物化再設計 / DG↔Biome 再マッピング / ジョブ .tres 移行 / Codex データ拡張。本決定は**文書（世界観 SSOT）刷新のみ**。コード未変更 | DevelopmentHQ が移行 Proposal を別途起票 |

## 実装移行 Scope — Postwar Ecology MVP（2026-06-26 — オーナー決定）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D034 | **第一弾実装スコープ = 1 DG（モーンゲート/王都地下）+ 3 ジョブ（ソードマン/レンジャー/アルケミスト）+ モックグラフィック**。残り 2 ジョブ・他 Biome は後続 | オーナー判断。前衛(ソードマン)を含めロール三角を確保 |
| P3-D034a | **ジョブ構成は前衛+遠隔+支援** — ソードマン(剣/前衛) / レンジャー(弓/遠隔) / アルケミスト(杖)。「ハンター」は採用せずレンジャーに統合 | 前衛不在=簡易ヘイト破綻の回避 |
| P3-D034b | **アルケミストは MVP で 魔法ダメージ + デバフ(状態異常付与)のみ**。回復/バフは戦闘ロジック未実装のため後続 | `SkillExecutor` は damage のみ実行 |
| P3-D034c | **武器種を sword / bow / staff へ整理**。弓・杖の武器データ + スキルを新規作成 | 現行武器は全て剣系 |
| P3-D034d | **モーンゲートの敵（生物由来）はオーナー指示待ち** — 敵 .tres / スプライトは指示後に着手 | オーナーが種を指定 |
| P3-D034e | **ドット絵（スプライト/アイコン）はオーナーが作画**。Cursor/Claude はコードのみ。AI 画像生成は行わない | オーナー方針 |
| P3-D034f | **モーンゲートを新規ゲーム既定ダンジョンに採用**（`Constants.DEFAULT_DUNGEON_ID = mourngate`）。royal_ruins は `ROYAL_RUINS_DUNGEON_ID` として選択可で残置 | オーナー決定 |
| P3-D034g | **スプライト命名規約**: `ENM_<PascalName>.tres` / `BOSS_<Name>.tres` / `CHR_<Job>.tres`。新ジョブ・モーンゲート敵の名前付き .tres を作成しスプライトマップを最終名へ差し替え済。中身は現状プレースホルダ複製で、**オーナーが新ドット絵で各 .tres のシートを差し替える**（コード変更不要） | オーナー決定 |

## ピクセル基準 — モック忠実（C案）（2026-06-26 — オーナー決定）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D039 | **ピクセル基準を高解像度（C案）に統一**。通常キャラ/敵=96×96、エリート=128×128、ボス=192×192、タイル=48×48、UIアイコン=64×64（現状維持）。細部サイズは HQ 一任 | オーナー決定（モック再現優先） |
| P3-D039a | **スプライトシート規格**: 横1列ストリップ・透過PNG・コマ間余白なし。コマ順 idle×4 / attack×4 / hurt×2 / death×4（計14コマ）。詳細は `docs/art/Sprite_Production_Spec.md` | 制作標準化 |
| P3-D039b | 既存プレースホルダ .tres の region は現状（32/64）のまま据え置き、**オーナーの新シート納品時に HQ が C 基準へ一括更新**（オーナーはコード不要） | ビルドを壊さず移行 |

## 世界観一本化 — 旧資産退役（2026-06-26 — オーナー決定）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D038 | **旧3ダンジョン（royal_ruins / graveyard / underground_factory）と旧16敵（不死・機械系）を退役**し、Postwar Ecology の新Biomeに一本化する。モーンゲートを起点に再構築。旧データは削除せず `resources/_archive/` 等へ退避し git 履歴を残す | オーナー決定（選択肢C） |
| P3-D038a | **段階実行**: R1=旧DGをUIから退役＋セーブ移行、R2=旧 .tres 退避＋コード参照除去、R3=旧ロア/spec を新世界へ刷新、B=新Biome追加 | 安全にビルドを壊さず移行するため |
| P3-D038b | **旧ジョブ .tres（warrior/guardian/scout）は退避**（セーブ移行は `SaveManager._JOB_MIGRATION` で新3職へ吸収済） | 一本化方針 |

## 将来システム登録（2026-06-26 — オーナー決定 / Backlog 化）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D035 | **レベル制を将来実装** — `Adventurer.level` 基盤あり。経験値→レベル→ステ成長。OD-UI-003（保留）を本決定で採用方針化 | オーナー決定。詳細設計は別 Proposal |
| P3-D035a | **レベル制 実装（2026-06-26）** — パーティ共有 EXP（ラン成功時、全員へ同量付与）。`exp_to_next(L)=100×L`、上限 **Lv20**。成長 **+6 HP / +2 ATK** per Lv（flat、affix と同じ加算点で適用＝HP は CombatController、ATK は DungeonScene）。`Adventurer.exp` 追加・セーブ永続化。`LevelSystem.gd` 新設。失敗（全滅）時は EXP 付与なし。DEF 成長は MVP 対象外 | 実装決定（数値は調整可） |
| P3-D036 | **助っ人キャラ制を将来実装** — 戦闘を「3 人 + 助っ人」で行える設計。パーティ枠拡張・一時参加。**詳細確定は下記「助っ人キャラ制 詳細確定」セクション参照** | オーナー決定。`MAX_PARTY_SIZE` 拡張要 |
| P3-D037 | **ジョブ強化システムを将来実装** — ジョブレベルを設け、一定到達でジョブが進化し名称が変わる。P3-D033「基本 5 職は対等・上位下位なし」は**launch 時点の基本層**を指し、進化は**その上の将来プログレッション層**として両立 | オーナー決定。`36_JobBible.md` に注記 |

## 世界観資料の再構成（2026-06-27 — オーナー決定）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D040 | **旧 World/Lore Bible（`game/16`〜`25`）を削除**し、コアを `game/37_RelicsHistoryCore.md` に抽出統合（語源/時代区分/九王/九英雄/王遺産・伝説武器/中核の謎 + HE-001〜004 機械可読）。`CatalogHelper.gd` の History 解析を 16→37 へ切替。削除方式は git rm（履歴に保持） | オーナー決定。旧資料が Postwar Ecology と矛盾 |
| P3-D041 | **世界観資料の全体構成を刷新** — `docs/specs/world/` を新設し、4層（過去/現在の自然/現在の人類/運用）+ マスターの **12 文書**へ再編。世界観↔仕様を分離（Jobs/Codex は世界観面=`world/`、数値・仕様=`game/`。図鑑は `game/` のシステム仕様）。各文書は ChatGPT が執筆。構成・移行手順は `docs/specs/world/README.md` | オーナー決定（配置=world分離 / 粒度=12 / Jobs・Codex=分離） |
| P3-D041a | **移行は段階 cutover** — 現行 `game/29`〜`37` は world 文書完成まで live SSOT として残し、Draft 明記で二重 SSOT を回避。完成後に参照切替→旧削除→smoke | ビルドを壊さない |
| P3-D041b | **cutover 完了（2026-06-27）** — world 12 文書を正式 SSOT 化。`game/29`〜`32`・`34`〜`37` を削除（`33_EcologyCodex` は図鑑システム仕様として game/ 存置）。`37` の HE-001〜004 機械可読ブロックを `world/01_History.md` 末尾へ移管し `CatalogHelper.gd` の `HISTORY_BIBLE_PATH` を `world/01` へ切替。全 spec/運用/スクリプトの参照を `world/` へ更新 | P3-D041a の完了 |
| P3-D046 | **先王時代（超古代 / Pre-Nine）と白王を正典化** — 九王時代より前の起源不明の超古代「先王時代」を採用。世界遺産＝その構造物。**内部正史**: 灯火・王冠・世界樹・古代種は先王時代由来（＝「王冠は人工物でない／これは九王の遺産ではない」の真意）。**白王**＝先王時代に王冠（継承の核）を最初に担った存在、第十の王はその継承者。公開は「起源不明の超古代」「継承を司った伝説的存在」の断片のみ、真相は `CANON_INTERNAL`。あわせて `11_Glossary` を P3-D044 同期＋新語登録。反映: `CANON_INTERNAL`,`world/01`,`world/07`,`world/11` | オーナー決定 |
| P3-D045 | **伝説武器9対を正典化** — 九王と1:1対応。武器種＝大剣/槍/杖/剣/弓/槌/槍/杖/剣、各対に理念・概要・所在の伝承（フック）を確定。#8 翠杖ヴェルド＝ヴェルディア（④Biome-02と接続）、#9 継承剣レガート＝王都アステリア（内部正史と接続）。#6 星炉＝同一紋様の表向き説明（真相は CANON_INTERNAL に留置）。**槌**は将来武器種候補（ロアのみ・未実装）。反映: `world/02`,`game/07` | オーナー決定 |
| P3-D044 | **エルド大陸 地理を確定** — プレイヤー拠点＝**アイアンヘイブン（Ironhaven / 探索者都市）**（ゲームの「拠点」の正体）。モーンゲート＝**王都アステリア地下の旧排水網**。王都アステリア＝旧文明の首都（公開は廃墟、内部正史では継承の中心地）。次 Biome 第一候補地＝**ヴェルディア（大森林）**（地理確保のみ。生態は④で設計）。反映: `world/07`,`world/05`,`CANON_INTERNAL`（地理フック） | オーナー決定 |
| P3-D043 | **中核の謎の方針を P-C ハイブリッドで確定** — 土台となる4謎（九王戦争の真実/第十の王・第十王遺産/王冠の失墜/伝説武器の同一紋様）は内部正史を確定、主題的2謎（世界樹/灯火）は恒久未確定で余白化。統合真相＝「王冠＝第十王遺産＝継承の核」を採用（王冠は倒れたが滅びず＝継承の意思=灯火が残り、探索者=プレイヤーが無自覚の継承者＝作品名 Crownfall に直結）。真相は**非公開 `world/CANON_INTERNAL.md`** に集約し、プレイヤー向け `02_Relics` は断片のまま。ChatGPT 配布・図鑑から除外 | オーナー決定。反映: `world/CANON_INTERNAL`,`world/README` |
| P3-D042 | **mourngate 6体の生物分類を正典化** — 祖先/Class を確定: セピアハウンド=イヌ科/I・ルーンローチ=ゴキブリ/IV・水晶ハリネズミ=ハリネズミ/I・冠喰いネズミ=ネズミ/I・クロックモス=蛾/IV・セルディオン=古龍種死骸＋鉱物性共生生物/VII。mourngate の共通テーマを **鉱物化適応**（遺物・鉱物の体内取り込み）と定義。セルディオンは「不死の骨竜」ではなく**死骸骨格＋寄生性結晶生命の複合生命体**（不死排除原則を維持）。`04_Classification` §3 派生表を mourngate 基準へ書換 | オーナー決定。反映: `world/04`,`world/05`,`game/12` |

## 助っ人キャラ制 詳細確定（2026-06-27 — オーナー決定 / P3-D036 詳細化）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D036-1 | **戦闘枠 = 最大4 =「編成枠 ×3 + 助っ人固定枠 ×1」**。`Constants.MAX_PARTY_SIZE` 系を編成3＋助っ人1へ拡張 | 共存問題回避（オーナー決定） |
| P3-D036-2 | **編成枠 ×3** — 基本5職 + ガチャ入手メンバーの**ロスターから3名選択**。恒久・装備可・共有EXP対象・全滅判定対象 | ガチャ助っ人は「既存3名と入替」方式 |
| P3-D036-3 | **助っ人固定枠 ×1（イベント助っ人）** — DG内イベントで一時加入。**1ラン限定・装備不可・EXPなし・全滅判定対象外・自動AI**。正体は既存5職の NPC 版（汎用） | オーナー決定 |
| P3-D036-4 | **ガチャ助っ人** — 拠点ガチャで入手するユニーク要員（**2〜3名**）。専用通貨（通常Goldと別管理、仮ID `gacha_token`）で排出。装備可・共有EXP対象 | オーナー決定 |
| P3-D036a | **Phase a（中）** — 戦闘「編成3 + 助っ人固定枠1」基盤 + イベント助っ人（装備/EXPなし・全滅対象外・自動AI）。ガチャ/ロスターは含まない | 手触り検証を先行 |
| P3-D036b | **Phase b（大）** — ガチャ + ロスター編成（3名選択UI・専用通貨 `gacha_token`・排出2〜3体・恒久/装備/共有EXP・セーブ） | a 検証後に着手 |

## フェーズ戦略 — システム feature-complete 優先（2026-06-27 — オーナー決定）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D042 | **「1DG（モーンゲート）まで＋システムを feature-complete → その後にUI/ドット絵を一括ポリッシュ」のフェーズ戦略を採用**。順序: Phase 3-B'（システム完成）→ Phase 3-A（ポリッシュ）。P3-D025/025a/039 と整合 | オーナー構想。手戻り最小化 |
| P3-D042a | **「システム完成」の定義 = 機能する仮UI（現行 UI-2+ 水準）＋仮アートまでを含む**。本番UI（UI_Reference 003系モック寄せ）と本番ドット絵量産（C案）は Phase 3-A に分離 | UI ゼロでは検証不能なシステムがあるため |
| P3-D042b | **バランス調整はシステム実装と同時に都度実施**（ポリッシュ Phase にまとめない） | プレイ感依存 |
| P3-D042c | **Phase 3-B' スコープ凍結（システム完成リスト）** — 下記。リスト外は正式版/後 Phase 送り | スコープ発散防止 |

### システム完成リスト（Phase 3-B' 凍結 / P3-D042c）

| 区分 | 項目 | 状態 |
|---|---|---|
| 戦闘 | コア / 属性5・状態6 / イニシアチブ / ヘイト | ✅ |
| 育成 | レベル制（P3-D035a） | ✅ |
| 装備 | 武器/防具/装飾・Affix・鑑定・比較 | ✅ |
| 助っ人 | P3-D036a（イベント）/ P3-D036b（ガチャ・ロスター） | ⬜ |
| ジョブ | 残り2職（ヴァンガード/ビーストテイマー）/ ジョブ進化（P3-D037） | ⬜ |
| 収集 | Ecology Codex（5段階調査） | 一部 → 完成必須 |
| 経済 | Gold用途 / 専用通貨 `gacha_token` / 素材ショップ / クラフト（防具・装飾=実装済、**武器=有効化要**） | 一部 → 完成必須 |
| 永続 | セーブ移行 | ✅ |

## Ecology Codex 5段階調査 — 段階定義（2026-06-27 — オーナー決定）

**SSOT:** `game/33_EcologyCodex.md`（システム仕様）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D043 | **Codex を5段階調査制で実装**（現行の発見/未発見2値から移行）。段階制は **enemy（＋boss）のみ**、weapon/dungeon/material/history は2値維持 | 33_EcologyCodex v1.0 |
| P3-D043a | **段階トリガー**: S1=未遭遇 / S2=戦闘遭遇 / S3=1体撃破 / S4=累計3体撃破 / S5=累計6体撃破（数値は調整可） | 「討伐数」でなく調査の積み重ね |
| P3-D043b | **段階別開示**: S1=シルエット / S2=名前・イラスト / S3=分類・危険度・生息地 / S4=弱点・耐性・行動傾向 / S5=採取素材・調査記録 | 段階的理解 |
| P3-D043c | **データモデル**: `GameState.enemy_codex = { enemy_id: {seen:bool, kills:int} }`（セーブ永続）。段階は seen/kills から導出。既存 discovery_registry の "enemy" は seen 扱いへ統合 | 移行容易性 |
| P3-D043d | **EnemyData 拡張（MVP最小）**: `codex_class:String` / `codex_danger:int(1-5)` / `codex_habitat:String` / `codex_research_note:String(multiline)`。弱点/耐性=既存 element_weakness/resist 流用、素材=既存 drop_table_id 流用。本文テキストは仮置き可（後日 world/文章レビュー側で調整） | 既存6敵に追記 |
| P3-D043e | **boss は MVP では一般種と同じ5段階**で通す。boss 専用ページ（生態系の役割等）は Future | スコープ最小化 |

