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
> **採番（2026-06-28 改番 / P3-W 名前空間）:** world 帯（D040-D049）が満杯になり D050 以降が HQ 帯と衝突したため、world の溢れ分を **`P3-W-###`** へ改番した。対応: 旧 D050→W-001 / D051→W-002 / D052→W-003 / D053→W-004 / D054→W-005 / D055→W-006 / … / D066→W-017。HQ の D050〜D054 は据え置き。以後 world は `P3-W-###`、HQ は `P3-D###`。

| P3-W-021 | **伝説武器/王遺産の公開断片を執筆** — §3 九対それぞれに「公開断片（フラグメント）」（碑文・古記録・噂の一行）を追加。武器フレーバー・図鑑・イベントの将来素材として用いる。所在伝承と整合し、中核の謎の真相（王冠＝第十王遺産・世界樹・灯火・同一紋様の理由）には踏み込まない（§4 / `10_LoreDelivery §9`）。`WeaponData` に説明欄は無く九対は未実装のため、本件は世界観文書のみ（実装時の素材）。反映: `world/02 §3` | オーナー決定（D・固有名はHQ確定） |
| P3-W-020 | **素材ロア（`MaterialData`）を文章化** — 素材21件の `description` を「用途」から「由来（生物・遺構・歴史）」基準へ改稿（`10_LoreDelivery §7`）。超自然語（魔力/魔法/呪い/錬金術）をエルダ・自然現象へ書き換え（P3-W-004）、退役 DG 名（白骸墓地→モーンゲート崩落区画 / 王都跡→王都アステリア地下）を是正。歴史接続11件に `lore_id`（HE-001/002/006/007）を注釈付与（コード未参照・将来のロア接続用）。反映: `world/05 §3`,`resources/materials/*.tres` | オーナー決定（C・設定→実装直結） |
| P3-W-019 | **HE（History 機械可読エントリ）を拡充** — 基幹4本（王国時代/九王戦争/静寂/探索者）に加え、六時代を覆う追加5本を新設: HE-005 先王時代と世界遺産（先王時代）/ HE-006 九王と九英雄（九王時代）/ HE-007 王都アステリアの崩落（九王戦争・Crownfall の由来、真相非記載）/ HE-008 探索者ギルドの創設（静寂・理念「歴史を持ち帰れ」）/ HE-009 王の大街道と隊商（探索者）。基幹4本と相互リンク。文体＝復元概説（`10_LoreDelivery §8`）、中核の謎の真相は非記載（§9）。lore ドロップ未実装のため `CatalogHelper.STARTER_HISTORY_IDS` を HE-005〜009 まで開示に更新。反映: `world/01`（HEブロック・§1）,`scripts/codex/CatalogHelper.gd` | オーナー決定（B・固有名はHQ確定） |
| P3-W-018 | **モーンゲート敵6体の Codex 調査記録を執筆** — `codex_research_note` を深掘りロア（祖先種・鉱物化適応の仕組み・王都/遺物/歴史への接続を1点・能力は自然現象=エルダで記述・魔法不在）へ改稿。`10_LoreDelivery §7` の調査記録文体に準拠。弱点/耐性は既存 `element_*` 流用。`rune_roach`=文書庫跡 / `crown_eater_rat`=宝物庫跡 / `clock_moth`=旧時計機構の遺構 へ `codex_habitat` をロア整合。反映: `world/05 §3`,`resources/enemies/{sepia_hound,rune_roach,crystal_hedgehog,crown_eater_rat,clock_moth,serdion}.tres` | オーナー決定（A・設定→実装直結） |
| P3-W-017 | **ジョブの世界観を深化** — 基本5職を九王/九英雄の系譜・ギルド五部門・社会的位置づけに接続（ソードマン=騎士/回収・調査、ヴァンガード=守護王ヴァルケイン/回収、レンジャー=開拓王エルディオン・斥候/測量、アルケミスト=学識王セラディス・錬成/記録・補給、ビーストテイマー=カイル盟約・生態学/調査）。対応は気質・来歴を示すもので厳密所属ではない。**探索者ジョブ（野外圏の調査要員資格）と街の職能（鍛冶ガロ/商人セルマ等）を区別**。編成は隊長（プレイヤー）が複数専門を組み合わせる思想（評価=調査成果）。反映: `world/09 §5` | オーナー決定（F・固有名はHQ確定） |
| P3-W-016 | **言語・文字を確定** — **共通語**（王国時代の交流圏の名残・ギルドが正書法整備・地名接尾語もこの語彙）。**文字の三層**＝現代文字（記録/図鑑/契約）／王国文字（碑文・古文書、記録部はおおむね解読可）／**古代文字（Elder Script）**（世界遺産・最古遺構の未解読文字、文字か否かも不明）。固有名の古風な響き＝王国文字の共通語転写。**「ルーン」＝生物が古代文字を取り込み甲殻/鱗に析出した紋様**（ルーンローチ/ルーンスカー等、意味を持つとは限らず魔法でない / P3-W-004）。古代文字は未解読、学識王セラディスの封じた知・第十王遺産/王冠の謎との関連は噂どまり（永久未確定に踏み込まない）。配置＝`08 §15`。固有名はHQ確定。反映: `world/08 §15`,`world/11` | オーナー決定（D・固有名はHQ確定） |
| P3-W-015 | **Relics を深化** — §3.5 **王遺産の現状**: 九対の実物はほぼ未確認・所在は伝承のみ・野外圏奥地に眠る。ギルドは王遺産を日々の遺物回収とは**別格の最終調査目標**（歴史を書き換える象徴）と位置づけ、一般遺物（量産武器）と**探索段階として明確に隔絶**（装備の将来枠 D-004 と整合）。§4 **第十の王の公開断片を拡充**: 記述は学識王セラディス旧目録の写しのみ・原本喪失／九対の様式外／一部写本で**王冠記述の隣**に置かれ両者を結ぶ噂（裏付けなし）／実在・称号・比喩いずれか不明。**真相（王冠＝第十王遺産＝継承の核）は CANON_INTERNAL 留置・非開示**、公開は矛盾しない断片のみ。反映: `world/02 §3.5・§4` | オーナー決定（C・固有名はHQ確定） |
| P3-W-014 | **現在の情勢（探索者の時代の"今"）を確定** — ゲーム開始時の世界状況。安定の途上（ギルド/隊商で都市は安全に結ばれるが安全圏のみ・野外圏は危険・世界は調べ直され始めた段階）。**モーンゲート調査の契機**＝アイアンヘイブンの中核都市化＋王都遺物の豊富さ＋近年の地下活性化（鉱物化適応個体の増加・澱みの季で強化）→ギルドが新調査隊派遣を決定（=ゲーム開始状況）。動きつつある関心＝ヴェルディア/囁きの森への注目・古龍種の生体目撃の噂・遺物出所をめぐる支部/商人の駆け引き・王冠/第十王遺産に触れる断片（真相非開示）。**プレイヤー隊＝調査許可等級を得たばかりの新編調査隊**（英雄でなく社会に必要とされて送り出される）。大仰な世界存亡の危機は置かない（探索者フレーム維持）。反映: `world/01 §8` | オーナー決定（E・固有名はHQ確定） |
| P3-W-013 | **伝説モンスターの枠組みを確定** — **伝説個体（Legendary）**＝各地で語られる極稀な超大型・古代の生物（多くは Class VII、土地の象徴、頂点捕食者を兼ねる）。神/不死ではなく生物。**古龍種（Elder Reptiles）**＝竜ではなく王国時代から残る大型飛行爬虫類の総称（セルディオン骨格の由来、生体は稀）。九英雄カイルの盟約思想↔**ビーストテイマー**が伝説個体/古龍種の主題を担う。設計枠＝各 Biome/地方に伝説個体を最大1体（既定: モーンゲート=セルディオン／囁きの森=フローラベア・グランヴェル）、**他は祖先/Class/生態をHQ設計・名称はオーナー確定**。世界樹/灯火に結びつく伝説は永久未確定（答えを作らない / P3-D043）。反映: `world/04 §5`,`world/09`,`world/11` | オーナー決定（B・固有名はオーナー確定枠） |
| P3-W-012 | **アイアンヘイブンの主要 NPC を確定** — 拠点施設（§10）に対応する6名: **オーレン**（ギルド長/本部・任務）・**ニーナ**（記録官/図鑑）・**ガロ**（鍛冶師/赤鉄の工房）・**セルマ**（商人/中央市場・鑑定）・**トビアス**（宿主/辻灯亭・助っ人/編成・噂供給）・**マエル**（認定官/ジョブ認定）。在野ユニーク助っ人A(★4 ヴァンガード系)/B(★3 レンジャー系)/C(★3 アルケミスト系)は **背景のみ設計・名称はオーナー差替**（P3-D036b-7）。NPC固有名は調整可。台詞/演出は実装時別途。反映: `world/08 §14`,`world/11` | オーナー決定（A・固有名はHQ設計） |
| P3-W-011 | **Biome-02 囁きの森（ウィスパーウッド）を確定** — ダンジョン名＝**囁きの森ウィスパーウッド**（ヴェルディア大森林）。生態テーマ＝**共生適応**（菌糸・胞子・蔓との共生/寄生。鉱物化適応=無機と対をなす有機の適応）。生息モンスター設定をオーナー命名で確定（VI 菌植物6＝ブラッドブルーム他／IV 甲虫4／I 猪4／III 蛇4／Elite候補5＝ルーン・カルキノス[V]・エコー・マンダー[V]・深霧ワイバーン[III]・墓花マンモス[VII]・ブルームワイバーン[III]／Boss＝**フローラベア・グランヴェル**[VII 古代種]）。戦闘傾向＝**fire 弱点・poison 中心**（モーンゲート thunder/holy・bleed/stun と対）。能力の超自然語（呪文/魔竜等）は俗称とし自然現象（エルダ）として扱う（P3-W-004）。**ゲーム採用個体は別途選定**（設定先行）。設計はHQ・命名はオーナー。反映: `world/05 §3.2`,`world/04 §3`,`world/07`,`world/11` | オーナー決定（生態=HQ設計GO・名称=オーナー確定） |
| P3-W-010 | **ロア提示の具体運用を確定** — `10_LoreDelivery` を運用面で具体化。**Codex 文体**＝探索者の調査記録（敵=5段階開示 P3-D051 と対応、S5 `codex_research_note` に土地/歴史の断片を1点／素材=`MaterialData.lore_id` で由来を一行／武器=来歴フレーバー／History=HE 概説）。**HE 追加運用**＝`world/01` 末尾の機械可読ブロックに `# HE-00X`＋`## Overview/## Era/## Related History Entries`（見出し厳守・`CatalogHelper.gd` 解析・採番連番・真相非記載）。**中核の謎=公開vs内部**（内部確定4＝矛盾しない断片のみ／永久未確定2=世界樹・灯火は答えを作らない、CANON_INTERNAL を転記せず配布/図鑑対象外）。**新語=Glossary 登録義務＋造語ルール**を明文化。反映: `world/10 §2・§7-10` | オーナー決定（F・固有名詞は HQ 一任） |
| P3-W-009 | **信仰・死生観を確定** — 奇跡を起こす神は不在。信仰＝記憶・継承・自然への向き合い方の文化的営み。**灯火の信仰**（記憶/継承を絶やさない象徴・教義でなく作法・象徴=巫女イリア、巫女＝灯と記憶の守り手）、**継承の信仰**（白王の神殿・現在は迷信視、エレナス倫理へ接続）、**自然への畏れ**（野外圏/澱みの季・崇拝でなく知恵）。死生観＝死者は自然へ還る（戦後生態系と同感覚）／弔い＝記録・記憶（ギルド記録文化と接続）／**不死・蘇りは存在しない**（セルディオン=複合生命体と整合）。聖の光は信仰では「神の恵み」、ギルドでは**エルダ（自然力）**＝民間信仰と実証主義の併存。灯火/白王の真相は CANON_INTERNAL に留置（公開は象徴・断片）。配置＝`08 §13`。固有名詞は HQ 決定。反映: `world/08 §13`,`world/11` | オーナー決定（E・固有名詞は HQ 一任） |
| P3-W-008 | **経済・交易・素材の世界観を確定** — **Gold＝旧王国金貨**（統一王権喪失後も金属価値で流通する事実上の基軸通貨、ギルド/隊商が信用を担保）。素材は**二系統**＝生物素材（生態調査・`03`）／遺物素材（遺物回収・`02`）。エルダを帯びた素材の俗称＝「魔○○」（超自然でない）。鑑定＝遺物・素材の素性/価値判定（既存鑑定システム）。市場/商人/補給部＝中央市場での取引・隊商流通。鍛冶＝赤鉄の工房（鍛冶王〜ラグナ系譜）。ゲーム要素↔世界観の対応表を整備。配置＝`08`（経済は社会の一部）。固有名詞は HQ 決定。反映: `world/08 §12`,`world/11` | オーナー決定（C・固有名詞は HQ 一任） |
| P3-W-007 | **戦後の人類社会を確定** — 生存圏＝**安全圏**（城壁都市・集落）／外＝**野外圏**（戦後生態系・探索の舞台）、都市間は**隊商**＋王の大街道の名残で結ぶ。崩落で統一王権喪失（*Crownfall* の由来）→各都市自治、空白をギルド＋隊商網が補う。暮らし＝近郊の限られた農牧＋遺物・素材交易が経済の柱。**探索の動機＝三層（生存／知識／生計=Gold）**。戦後世代は王国時代を伝承でしか知らず、探索者は特別視される。配置＝`08`（現在の人類社会レイヤ）に集約。固有名詞は HQ 決定。反映: `world/08 §11`,`world/11` | オーナー決定（B・固有名詞は HQ 一任） |
| P3-W-006 | **探索者ギルドを深掘り** — 組織構造: **ギルド評議会**（加盟都市代表＋分野長の合議・中立機関）、**五部門**（回収/調査/測量/記録/補給）、本部=アイアンヘイブン＋支部（シーゲート/フロストウォール/グリーンホロウ）。階級: 個人の専門資格（准探索者→探索者→**上級探索者**→主席）で **上級探索者＝ジョブ到達形（P3-D048）に対応**。隊の評価＝**調査許可等級**（成果ベース・数値は game 側）。拠点アイアンヘイブンの施設をゲーム機能に対応づけ（本部=ダンジョン選択/図鑑、赤鉄の工房=鍛冶、中央市場=商人、辻灯亭=助っ人/編成、認定所=ジョブ認定）。固有名詞は HQ 決定。反映: `world/08 §8-10`,`world/11` | オーナー決定（A・固有名詞は HQ 一任） |
| P3-W-005 | **暦・時間・季節を確定** — 二層紀年法: 長期＝**崩落後（A.F.）**（崩落＝王都アステリア崩落/九王戦争終焉、現在 崩落後 約300年・諸説）、実用＝**ギルド暦（G.）**（ギルド創設起点、**現在 G.118**）。暦構成: 1年=12ヶ月=360日、1ヶ月=3旬、1旬=10日（週相当）。月名は失われ番号呼称。四季は各3ヶ月＋世界固有の**澱みの季**（晩秋〜初冬、瘴気活性化の危険期）。時計＝王国時代の歯車式時計の遺物（クロックモスの生態的背景）。固有名詞は HQ 決定。反映: `world/01 §7`,`world/11` | オーナー決定（D・固有名詞は HQ 一任） |
| P3-W-004 | **属性・魔法の世界観を確定（自然力エルダ）** — 超自然の魔法は不在。属性・魔法に見える現象はすべて自然力 **エルダ（Elda）** の働き（自然現象・物質反応）として説明する。5属性＝エルダの相（炎/氷/電気＝自然元素、**闇＝瘴気**、**聖＝浄化の光**＝先王時代の浄化技術の名残）。ゲーム上の属性名・ID は不変。錬成＝エルダを物質的に扱う技術、杖＝触媒器、呪い＝瘴気による汚染。弱点は生態から説明。造語は最小化方針（エルダのみ新語、瘴気/浄化/錬成は既存語）。あわせて `03_Ecology §2` の退役地名＋「古代魔術装置」記述をモーンゲート/現行地理＋エルダ整合へ修正。反映: `world/03 §6・§2`,`world/11`,`game/27`(ポインタ) | オーナー決定（大方針GO / 闇=瘴気・聖=浄化 採用 / 体系名=エルダ） |
| P3-W-003 | **地方誌を整備** — Region 10件（ヴェルディア/アイゼンプレイン/グレイハイランド/ノースリーチ/フロストリッジ/レッドリッジ/サンダーピーク/ブラックショア/ミストフェン/ブロークンマーシュ）に地勢・主要地点・旧王国・生態傾向・探索メモを付与。九王ゆかり（P3-D049）・マップ配置（P3-W-001）・諸王国（P3-W-002）と整合。生態は傾向まで（モンスター設計は④ Biome に残置）。反映: `world/07 §3.5` | オーナー決定 |
| P3-W-002 | **歴史を深化** — 九王戦争の経過を諸説の骨格（発端＝継承/領土/災厄の諸説 → 拡大 → 終息と崩壊）で記述。王国時代の主要諸王国9系統を九王・地方と対応づけ、現存/廃墟を確定。静寂の時代の変遷（自然再生・知識喪失・ギルド前史）と都市の興亡表を追加。公開は諸説・断片、真相（継承戦争）は内部留置。反映: `world/01 §2・§3.5・§6` | オーナー決定 |
| P3-W-001 | **エルド大陸マップの空間構成を確定** — ハブ＆スポーク型（中心＝廃墟王都アステリア＋拠点アイアンヘイブン、王の大街道が放射、クラウンリバーが東山脈→中央→西海岸）。地方を方角別に確定（北=辺境/雪山、西=森/海、中央=平原、東=山/鍛冶/火山、南=湿地/南海）。ビジュアル大陸図を生成し `docs/art/worldmap/Eld_Continent_Map.png` を正本化。反映: `world/07 §1.5` | オーナー決定。世界設定（Biome 実装とは独立） |
| P3-D049 | **九王ゆかりの地を確定（伝承）** — 九王を既存地名と1:1対応（開拓王↔ノースリーチ / 守護王↔ストームクラウン砦 / 学識王↔王立図書院 / 信義王↔アイゼンプレイン / 巡礼王↔王の大街道 / 鍛冶王↔アイアンフォージ・レッドフォージ / 海統王↔シーゲート・シャッタードアイルズ / 森護王↔ヴェルディア・グリーンホロウ / 継承王↔王都アステリア・王家霊廟）。伝説武器の所在（⑤）と整合。公開は伝承レベル、アステリア＝継承の中心地は内部留置。現存都市の多くは戦後成立で九王と非接続。反映: `world/07 §5.5` | オーナー決定 |
| P3-D048 | **ジョブ進化（到達形）の世界観を確定（P3-D037 詳細化）** — 単線（1職1到達形）。到達名（カタカナ・EO調）: ソードマン→**ソードセイバー** / レンジャー→**スナイパー** / ヴァンガード→**パラディン** / アルケミスト→**セージ** / ビーストテイマー→**ビーストロード**。上位下位ではなく「専門を究めた上級専門資格」。世界観トリガー＝ギルドの上級資格認定（実績ベース、Lv到達に対応）。数値は `game/06`（推進実装）。反映: `world/09 §4`,`world/11` | オーナー決定 |
| P3-D047 | **九英雄を正典化** — 各英雄に功績・世界/システム接点・残響を付与（アステル↔地図更新、エレナス↔ギルド倫理、リュシアン↔深部生態調査、ラグナ↔星炉鍛造、カイル↔古龍種/ビーストテイマー、マレク↔外縁海域）。内部接続: イリア↔灯火（継承の意思）、セレス文書↔第十の王/白王の断片源、無名の継承者↔継承の核。公開は断片のみ、真相は `CANON_INTERNAL`。反映: `world/01`,`CANON_INTERNAL` | オーナー決定 |
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
| P3-D050 | **「1DG（モーンゲート）まで＋システムを feature-complete → その後にUI/ドット絵を一括ポリッシュ」のフェーズ戦略を採用**。順序: Phase 3-B'（システム完成）→ Phase 3-A（ポリッシュ）。P3-D025/025a/039 と整合 | オーナー構想。手戻り最小化（旧採番 P3-D042 は world 側と衝突のため改番） |
| P3-D050a | **「システム完成」の定義 = 機能する仮UI（現行 UI-2+ 水準）＋仮アートまでを含む**。本番UI（UI_Reference 003系モック寄せ）と本番ドット絵量産（C案）は Phase 3-A に分離 | UI ゼロでは検証不能なシステムがあるため |
| P3-D050b | **バランス調整はシステム実装と同時に都度実施**（ポリッシュ Phase にまとめない） | プレイ感依存 |
| P3-D050c | **Phase 3-B' スコープ凍結（システム完成リスト）** — 下記。リスト外は正式版/後 Phase 送り | スコープ発散防止 |

### システム完成リスト（Phase 3-B' 凍結 / P3-D050c）

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
| P3-D051 | **Codex を5段階調査制で実装**（現行の発見/未発見2値から移行）。段階制は **enemy（＋boss）のみ**、weapon/dungeon/material/history は2値維持 | 33_EcologyCodex v1.0（旧採番 P3-D043 は world 側と衝突のため改番） |
| P3-D051a | **段階トリガー**: S1=未遭遇 / S2=戦闘遭遇 / S3=1体撃破 / S4=累計3体撃破 / S5=累計6体撃破（数値は調整可） | 「討伐数」でなく調査の積み重ね |
| P3-D051b | **段階別開示**: S1=シルエット / S2=名前・イラスト / S3=分類・危険度・生息地 / S4=弱点・耐性・行動傾向 / S5=採取素材・調査記録 | 段階的理解 |
| P3-D051c | **データモデル**: `GameState.enemy_codex = { enemy_id: {seen:bool, kills:int} }`（セーブ永続）。段階は seen/kills から導出。既存 discovery_registry の "enemy" は seen 扱いへ統合 | 移行容易性 |
| P3-D051d | **EnemyData 拡張（MVP最小）**: `codex_class:String` / `codex_danger:int(1-5)` / `codex_habitat:String` / `codex_research_note:String(multiline)` / `codex_materials:Array[String]`（採取素材ID＝図鑑表示用、P3-CODEX5-002）。弱点/耐性=既存 element_weakness/resist 流用 | 既存6敵に追記 |
| P3-D051e | **boss は MVP では一般種と同じ5段階**で通す。boss 専用ページ（生態系の役割等）は Future | スコープ最小化 |

## 助っ人ガチャ仕様確定（2026-06-27 — オーナー決定 / P3-D036b 詳細）

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-D036b-1 | **方針A（キャラのみ簡易ガチャ）**。プール＝ユニーク助っ人 **3体**（★4×1 + ★3×2） | オーナー決定 |
| P3-D036b-2 | **通貨 `gacha_token`（無償のみ）**。入手= **ラン成功で 1〜2 token** ＋ **Gold購入 100G→1 token**（両方） | オーナー決定 |
| P3-D036b-3 | **引き方=単発のみ（1 token）**。10連なし | プール小のため |
| P3-D036b-4 | **排出率 ★4=20% / ★3=80%**、未所持を優先抽選 | オーナー決定 |
| P3-D036b-5 | **ハード天井=30連までに未所持を1体確定** | オーナー決定 |
| P3-D036b-6 | **重複= token 還元のみ（★4=5 / ★3=2）**。MVP は凸なし。データは所持数を保持し将来の凸に拡張可能に | オーナー決定 |
| P3-D036b-7 | **ユニーク助っ人3体は HQ がプレースホルダ定義**（既存ジョブ流用・スプライトは既存CHR複製）。名前/設定/作画は後でオーナー差替。仮: ★4=vanguard系 / ★3=ranger系 / ★3=alchemist系 | システム先行（オーナー決定） |
| P3-D036b-8 | **ロスター編成**: 取得済ガチャ助っ人は「編成枠3」の選択肢に加わり、基本メンバーと**入替可能**（恒久・装備可・共有EXP対象）。助っ人固定枠1（イベント）とは別 | P3-D036-2 |
| P3-D036b-9 | **ロスター初期構成= 基本5職全員を初期所持**（swordsman/ranger/alchemist/vanguard/beast_tamer）。アクティブ3はロスターから選択（初期=前3職）。ガチャは追加ユニークを供給 | オーナー決定 2026-06-27 |
| P3-D036b-A | **実装サブ分割**: A=データ/GameState/Save/GachaSystem・B=GachaScene・C=RosterScene編成+導線・D=token入手フック | HQ |

> **採番ルール（チャット間調整 / 2026-06-28 更新）**: world 系決定＝**`P3-W-###` 名前空間**（旧 D040〜D049 帯は満杯のため凍結・既存はそのまま、溢れ分 D050〜D066 は P3-W-001〜017 へ改番済）。HQ システム系決定＝**`P3-D###`（D050 以降）** を継続。両者は別名前空間のため以後衝突しない。旧 P3-D042/043（HQ）は P3-D050/051 へ改番済。

## ジョブ進化 数値・実装仕様確定（2026-06-27 — オーナー決定 / P3-D037 詳細・P3-D052）

進化先名は P3-D048（world）で確定。本セクションは数値・実装方式（game/06）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D052-1 | **効果モデル A 専門深化**: 進化後補正 = `1.0 + (基礎補正 - 1.0) × 1.3`（強みは強化・弱みは弱化）。HP/ATK/DEF 各補正に適用。世界観「専門を究める／上位下位なし」と整合 | オーナー決定 |
| P3-D052-2 | **トリガー= 手動ギルド認定**。キャラ Lv10 到達後、拠点「ギルド認定」画面で各員を認定して進化（自動進化はしない） | オーナー決定 |
| P3-D052-3 | **必要 Lv= 10**（上限Lv20の中盤） | オーナー決定 |
| P3-D052-4 | **実装方式**: `Adventurer.is_evolved`（bool・セーブ永続）＋`JobData.evolved_display_name`/`evolution_level`。`JobStatCalculator` が `is_evolved` 時に補正深化＋到達形名を返す（`job_id` は不変・既存戦闘/装備/UIは無改修で反映） | HQ |

## ダンジョン進行を全自動化 — 分岐撤廃＋自動進行（2026-06-28 — オーナー決定 / P3-D053）

| # | 決定 | 根拠 |
|---|---|---|
| P3-D053-1 | **per-room 分岐選択（安全/危険/不明）を完全撤廃**。`branch_*`（UI/コード/プール/`DungeonData.branch_enabled` 運用）を除去 | 道中の浅いギャンブル選択が「全自動探索」体験と矛盾（オーナー実プレイ判断） |
| P3-D053-2 | **進行を A2＝自動進行制**: 部屋解決後にタイマーで自動的に次の部屋へ。x1/x2/一時停止で観戦（既存の速度/一時停止系を流用・タイマーも pause 連動） | 指揮官＝事前方針→実行は自動。mock 003_07（x1/x2/停止・自動戦闘中）と整合 |
| P3-D053-3 | **停止して入力待ちする部屋＝選択必須の MERCHANT / EVENT のみ**。COMBAT/ELITE/MID_BOSS/BOSS は勝利後に自動進行、TREASURE/HEAL/START は自動通過 | 意味ある選択のみ手動 |
| P3-D053-4 | **EXIT 到達で自動的に探索終了→リザルト**（手動「探索終了」も残す） | 最後まで止まらない |
| P3-D053-5 | リスク/リワードの事前選択（出撃前 方針）は **今回スコープ外**（将来 B 案として再検討可） | A 採用 |

## 中ボス(MID_BOSS)廃止 — エリート/ボスへ集約（2026-06-28 — オーナー決定 / P3-D054）

| # | 決定 | 根拠 |
|---|---|---|
| P3-D054-1 | **MID_BOSS 部屋を廃止**。`ROOM_SEQUENCE` の MID_BOSS(index7) を COMBAT へ置換。道中は 雑魚＋ELITE1回＋BOSS のみ | ELITE と MID_BOSS が同一プール・同一1.5倍で冗長（P3-D053 で elite_pool=clock_moth 単一化により完全重複） |
| P3-D054-2 | MID_BOSS 固有処理（ラベル/バッジ/報酬/抽選分岐）を除去。`Enums.RoomType.MID_BOSS` の**列挙値自体は残す**（並び変更による既存値ズレ回避、未使用化） | 低リスク優先 |
| P3-D054-3 | MID_BOSS の追加ドロップは元々無し→廃止で報酬影響なし。ELITE の追加ドロップ抽選は維持 | 現仕様維持 |

## スキル装備システム・キャラ管理画面（2026-06-29 — オーナー決定 / P3-D077）

> 動機: スキルは武器`fixed_skill_id`＋ジョブ`starting_skill_ids[0]`から戦闘時に導出する設計でキャラ非保持だった。プレイヤーが明示的にスキルを装備し、戦闘では装備スキルのみ使用する形へ変更。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D077-1 | メニュー「装備へ」→**「キャラ管理」**に改称（`BaseScene`） | 装備＋スキル管理を担う画面へ |
| P3-D077-2 | **装備スキルは1キャラ2スロット**（`Constants.MAX_EQUIPPED_SKILLS=2`）。`Adventurer.equipped_skill_ids` に保持＋セーブ対応 | 旧「武器＋ジョブ」2発と整合 |
| P3-D077-3 | **装備可能プールはジョブ別**（`JobData.learnable_skill_ids`）。先頭MAX個を既定装備にフォールバック。剣士=斬撃/着火斬/放電斬/霜触, ヴァンガード=守護斬り/斬撃/着火斬/霜触, レンジャー=狙撃/拘束矢/呪詛弾, アルケミスト=呪詛弾/放電斬/着火斬/霜触, ビーストテイマー=拘束矢/狙撃/呪詛弾/霜触 | ジョブ個性・8スキル流用 |
| P3-D077-4 | **戦闘では全メンバーが自分の装備スキルのみ発動**（従来＝先頭1人・武器/ジョブ導出を廃止）。CDはメンバー×スキルで独立 | キャラ管理の意図に沿う |
| P3-D077-5 | 武器`fixed_skill_id`の自動付与は廃止（明示装備に一本化）。武器スキルはプール/初期装備候補として温存 | スキル管理の一本化 |
| P3-D077-6 | キャラ管理画面に**スキルタブ**追加（装備中スロット表示＋ジョブ習得可能スキル一覧で装備/解除）。EquipmentScene TabContainer 第3タブ | UI |
| P3-D077-7 | 実装は HQ。headless で全スクリプトコンパイル＋全リソースロード検証 | 品質担保 |

## 部屋抽選のランダム化・ダンジョン別フロア数（2026-06-29 — オーナー決定 / P3-D076）

> 動機: `ROOM_SEQUENCE` 固定列で毎ラン同一進行だったため、中間部屋を重み付きランダム化。事故（宝箱だらけ/ELITE連続等）はガードで抑制。ダンジョン別に長さを設定可能化。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D076-1 | **中間部屋を重み付きランダム抽選**化（プリセット=戦闘多め: COMBAT60 / EVENT15 / TREASURE13 / ELITE12） | 周回の単調さ解消・戦闘テンポ優先 |
| P3-D076-2 | **両端固定**: F1=START / 2部屋目=COMBAT(肩慣らし固定) / 最終フロア=BOSS / その後にEXIT付与(フロア番号外) | 開幕事故防止・クライマックス保証 |
| P3-D076-3 | **安全ガード全適用**: ELITE最大2 / ELITE連続禁止(直前ELITEならCOMBATへ) / COMBAT最低3保証(不足時は非COMBATをEVENT/TREASURE→ELITEの順に変換) | 報酬・難度の極端化を防止 |
| P3-D076-4 | **ダンジョン別フロア数** `DungeonData.floor_count`(START〜BOSS含む。0なら従来固定列にフォールバック)。**mourngate=7**(案A: STARTをF1に数える→中間抽選4部屋) | ダンジョン毎に長さ設定したい要望 |
| P3-D076-5 | 抽選はラン開始時(`start_dungeon`)に一括生成し `room_sequence` に保持。進行・部屋数表示は同配列基準(`get_total_rooms`) | 決定性・UI整合 |
| P3-D076-6 | 実装は HQ。headless で2万試行検証(全不変条件0件: サイズ/両端/ELITE上限・連続/COMBAT最低 すべて違反なし) | 品質担保 |

## 鍛冶屋（クラフト）のオミット・退避（2026-06-28 — オーナー決定 / P3-D075）

> 経緯: P3-D068 で探索ドロップを直ドロップ化、P3-D074 で素材ドロップをオミット済。素材消費前提のクラフト導線（鍛冶屋）は当面不要のためオミット。鑑定(P3-D072)同様、コードは将来用途のため退避（削除しない）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D075-1 | **鍛冶屋をオミット**。`BaseScene` 左メニューの「鍛冶屋」ボタン・ハンドラ・ルーティングを撤去 | 素材オミットでクラフトループが機能しないため |
| P3-D075-2 | `BlacksmithScene.tscn/.gd(.uid)` を `archive/blacksmith/` へ退避（`archive/.gdignore` で Godot スキャン対象外） | 将来復帰可・削除しない |
| P3-D075-3 | `CraftData`/`RecipeData`/`DataRegistry.get_all_craft_data` 等のデータは残置（参照元が無くなるだけ） | 復帰容易・リスク無し |
| P3-D075-4 | 実装は HQ・Godot headless でロード検証 | 軽微・導線撤去 |

## 撃破演出強化：武器直ドロップ／全滅時残置／攻撃時間差（2026-06-28 — オーナー決定 / P3-D074）

> 要望: ①味方全滅時に勝った敵をその場に残す ②ドロップを「敵消滅後にアイコンが落ちて入手」アニメ化（対象は武器のみ・素材はオミット）③敵と味方の攻撃アニメが同時で重なるので分離。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D074-1 | **味方全滅時に敵スプライトを残す**。`_handle_party_wipe` で `_hide_enemy_sprite()` を廃止し idle 表示で勝者を残置（リザルト遷移まで） | 敗北演出の説得力 |
| P3-D074-2 | **武器は撃破時に直ドロップ**化。確率＝通常25%/エリート60%/ボス100%。ラン終了一括の武器生成(`generate_run_loot`)は廃止（防具/装飾は据置） | 直ドロップ体感・撃破毎の報酬感 |
| P3-D074-3 | ドロップ武器は撃破直後にアイコンをポップ→入手アニメ（`_spawn_weapon_drop`）。死亡アニメ後(0.35s)に出現 | 「敵が消えた後に落ちる」要望 |
| P3-D074-4 | **素材ドロップは一旦オミット**（ecology素材・エリート素材ボーナスを停止）。関数は将来用に残置 | スコープ縮小・後日復帰可 |
| P3-D074-5 | **攻撃アニメを時間差化**: tick内の味方/敵フェーズ間に `max(0.15, 0.4*速度係数)` のディレイを挿入 | 同時再生の重なり解消 |
| P3-D074-6 | 既知の副作用: 武器が即インベントリ加算のため全滅でも収集済み武器は保持（farm懸念）。今回は許容、要観察 | 直ドロップ仕様の自然な帰結 |

## 部屋移動トランジション演出（2026-06-28 — オーナー決定 / P3-D073）

> 要望: 次の部屋へ進む際にアニメーションが欲しい。HQ意見＝フルオート/x2のテンポを損なわない軽量演出から、で合意。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D073-1 | **部屋移動時に軽量トランジション**（暗転フェード＋部屋名キャプション）。`TransitionLayer`(CanvasLayer) のオーバーレイで実装 | 体感向上・新規アセット不要 |
| P3-D073-2 | **速度連動**: フェード片道 = `clamp(AUTO_DELAY*0.3, 0.12, 0.3)`（x2で自動短縮）。`mouse_filter=ignore` で操作を阻害しない | フルオート/x2テンポ維持 |
| P3-D073-3 | 自動進行のタイムアウト経路(`_on_auto_progress_timeout`)で発火。暗転中に部屋切替→フェードインで新部屋（戦闘なら敵）を出現 | 切替の唐突さ解消 |
| P3-D073-4 | 歩行マーチ（CHR walk）はアセット未整備のため見送り。潜入時(拠点→DG)の専用演出も今回スコープ外 | 低コスト優先・Beta候補 |
| P3-D073-5 | 実装は HQ・Godot headless でロード検証 | 軽微・UI |

## 鑑定機能のオミット・退避（2026-06-28 — オーナー決定 / P3-D072）

> 経緯: P3-D068 で探索ドロップは全て直ドロップ（鑑定済み＋Affix自動付与）化済。鑑定が必須なのはクラフト品のみだった。オーナー判断で鑑定機能を一旦すべてオミットし、画面導線からも外す。コードは将来用途のため退避（削除しない）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D072-1 | **鑑定画面への唯一の導線（ResultScene「次へ＝鑑定へ」）を撤去**。リザルト「次へ」は拠点(BaseScene)へ直行。ボタン表記「鑑定へ」→「拠点へ」 | 画面選択肢から鑑定を完全除去 |
| P3-D072-2 | **クラフト出力を生成時に自動鑑定化**（`is_appraised=true`＋`AffixRoller` でAffix付与）。鑑定を外しても未鑑定で詰まない | 直ドロップ(P3-D068)と整合・唯一の未鑑定生成経路を解消 |
| P3-D072-3 | **鑑定の scene/script を `archive/appraisal/` へ退避**（`scenes/appraisal`・`scripts/appraisal`）。`archive/.gdignore` でGodotのリソース走査から除外。削除はしない | 「退避」（将来再利用可）・res:// から実質除外 |
| P3-D072-4 | `is_appraised` フィールド・`AppraisalController`/`AffixRoller` 等のロジックは温存。セーブ形式は不変（全品 is_appraised=true になるだけ） | 低リスク・後方互換 |
| P3-D072-5 | 実装は HQ 側で対応・Godot headless でパース/ロード検証 | 軽微・UI/フロー |

## 戦闘 下部パーティパネル追加 — MP不採用・CD維持（2026-06-28 — オーナー決定 / P3-D071）

> 経緯: 「バトルログ下に自キャラのアイコン/HP/MP/武器を出したい」要望。検討の結果 **MP概念は未実装**（スキルはCD制 `SkillExecutor`）と確認。オーナー判断で **MP導入は撤回し CD のまま** とし、パネルは アイコン/HP/武器 のみ表示。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D071-1 | **バトルログ下に下部パーティパネルを追加**（各メンバー: ジョブCHRアイコン / HPバー＋数値 / 装備武器名）。戦闘中のみ表示 | 視認性向上 |
| P3-D071-2 | **MPは導入しない**。スキルは現行 CD 制（`SkillExecutor`）を維持。MP表示は出さない | MP未実装・gameplay 不変方針(P3-D069)維持 |
| P3-D071-3 | **頭上HPバー（パーティ）も維持**（パネルと重複表示OK） | オーナー選択 |
| P3-D071-4 | 確定モック003_07_v2 の「下部カード列なし」は本決定で一部上書き（カード列を採用） | オーナー決定（モック決定権者） |
| P3-D071-5 | gameplay 不変のため Phase 3-A ポリッシュ内。実装は HQ 側で対応 | 軽微・UIのみ |

## ダンジョン完全フルオート化 — 商人削除・イベント無選択化（2026-06-28 — オーナー決定 / P3-D070）

> 動機: 実プレイで「古文書発見などでプレイヤー選択が入り手が止まる」。ダンジョン内は完全フルオートにしたい（指揮官は出撃前方針のみ）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D070-1 | **イベント部屋(EVENT)を無選択化**。A/B 選択を廃止し、「古文書を見つけた」のように**決定事項のみ提示**して自動で結果適用→自動進行 | プレイヤー選択を排除（フルオート） |
| P3-D070-2 | イベント結果は従来の **outcome_a（肯定側の報酬）を単一 outcome として採用**。description は疑問文→宣言文へ書き換え。outcome_b（何もしない）は廃止 | 報酬を失わずテンポ維持 |
| P3-D070-3 | **商人部屋(MERCHANT)を削除**。`ROOM_SEQUENCE` には元々 MERCHANT 不在＝現状未出現のため、関連デッドコード(MERCHANT_CATALOG/generate_merchant_offers/buy_merchant_item/商人UI/ハンドラ)を除去 | 不要機能の整理・フルオート阻害要因の排除 |
| P3-D070-4 | イベント解決後は「出発」待ち(`_waiting_departure`)を廃し `_start_auto_progress()` で自動進行。全部屋種が自動進行で統一 | 完全フルオート |
| P3-D070-5 | 戦闘自動進行・速度切替/一時停止/停止は現状維持。出撃前の方針選択は温存 | 既存の指揮官体験を維持 |
| P3-D070-6 | 実装は **Claude Code（Impl セッション）** が担当 | オーナー指示 |

## Phase 3-A スコープ確定 — 純ポリッシュ / gameplay 不変（2026-06-28 — オーナー決定 / P3-D069）

| # | 決定 | 根拠 |
|---|---|---|
| P3-D069-1 | **Phase 3-A = 見た目のポリッシュのみ。gameplay は変更しない**（UIテーマ昇格・アセット差替・最小VFX） | P3-D050/050a の原則 |
| P3-D069-2 | **D-a パーティ人数=現状維持**（編成3＋助っ人固定枠1＝戦闘4体）。4人編成化は Beta 送り | gameplay 不変・助っ人システム(P3-D036)と整合 |
| P3-D069-3 | **D-b 装備枠=現状3枠維持**（武器/防具/装飾）。6枠化（新装備種）は Beta 送り | gameplay 不変 |
| P3-D069-4 | **D-c 拠点メタ（複数通貨/スタミナ/デイリー/下部ナビタブ/プレイヤーLv等）は Phase 3-A では導入しない**。Gold 単一のまま見た目だけ 003 へ寄せる。メタ進行は Beta | ポリッシュ範囲・メタは別フェーズ |
| P3-D069-5 | **A1 起点= BaseScene を 003_01 の見た目へ寄せる**（タイトルロゴ/城背景/左縦メニュー/装飾枠/配色）。**メタ要素は足さない**（既存要素の見た目だけ） | テーマ基準づくり |

## 装備ドロップを直ドロップ化 — 鑑定品撤廃・鑑定システムは温存（2026-06-28 — オーナー決定 / P3-D068）

> 動機: 実プレイで「全ドロップが鑑定品＝毎回100G鑑定が必須でテンポが悪い」とオーナー判断。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D068-1 | **探索ドロップの装備（武器/防具/装飾 全て）を「直ドロップ」化**＝生成時に `is_appraised=true` ＋ Affix を鑑定相当で自動付与（無料・即戦力） | 鑑定の作業感を解消 |
| P3-D068-2 | **比率＝100% 直ドロップ**（鑑定品ドロップは廃止） | オーナー決定 |
| P3-D068-3 | **鑑定システム（AppraisalController/AppraisalScene/一括鑑定）はコード温存**（将来用途のため削除しない）。クラフト生成品は現状の `is_appraised=false` を維持し、鑑定フローの利用先として残す | 「どこかで使う可能性」 |
| P3-D068-4 | 対象＝`DungeonController` の `_spawn_weapon`/`_spawn_armor`/`_spawn_accessory`（run/treasure/elite ドロップ）。Affix は既存 `AffixRoller.roll_for_equipment(category, rarity)` を流用 | 既存ロジック流用・最小改修 |
| P3-D068-5 | 実装は **Claude Code（Impl セッション）** が担当 | オーナー指示 |

## 武器クラフト 実機能化 — 図鑑↔経済の一本化（2026-06-28 — オーナー決定 / P3-D067）

> 前提: 武器クラフトの機構自体は `P3-CRAFT-001` で実装済（鍛冶で weapon 生成可能）。ただし旧素材 cursed_iron/leather がドロップ・商人とも入手不可で**レシピが成立せず**、かつ敵の `codex_materials`（新生態素材）は図鑑表示専用で実ドロップしていなかった。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D067-1 | **通常撃破で敵の `codex_materials` を実ドロップ化**（rarity 別確率: 0=60% / 1=30% / 2=12% / 3=5%）。エリート/ボスは自前の豊富なプール＋既存 elite 報酬を維持 | 図鑑 S5「採取素材」と実入手を一致（一本化） |
| P3-D067-2 | **クラフトレシピを新生態素材ベースへ改訂**: iron_sword={王金門歯2,刻印甲殻1} / hunting_bow={褪色魔毛2,魔導触角1} / leather_armor={追憶牙2,褪色魔毛1}。bone_armor(古き骨・商人) / silver_ring(遺跡欠片+高品質) は据置 | 入手可能素材へ整合・旧 cursed_iron/leather 依存を解消 |
| P3-D067-3 | **apprentice_staff（杖＝アルケミスト基本武器）のレシピを新規追加**={魔導触角2,晶核1} | 基本3武器種(sword/bow/staff)を被覆 |
| P3-D067-4 | 旧素材 cursed_iron / leather はレシピ未使用化（リソースは温存・将来再利用可） | 低リスク |
| P3-D067-5 | ドロップ数量は既存 `_apply_material_bonus` を適用。バランス値は P3-D050b に従い都度調整 | 既存機構流用 |

## 残り2ジョブ スキル確定 — ヴァンガード / ビーストテイマー（2026-06-28 — オーナー決定 / P3-D066）

> 番号は HQ system 系。world 帯（〜D065）との衝突回避で D066 を採用。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D066-1 | **2ジョブはシステム実装済**（roster 5職初期所持・既定編成・装備・セーブ移行・進化・vanguard はヘイト対象）。残ギャップ＝開始スキルのみ | 実態確認（既存コード） |
| P3-D066-2 | **vanguard 開始スキル= 守護斬り `guard_strike`**（melee・power1.1・CD3.5・`stun`25%）。タンク識別＋怯ませで被害軽減（簡易ヘイトと相乗） | swordsman と slash 共用を解消・役割明確化 |
| P3-D066-3 | **beast_tamer 開始スキル= 拘束矢 `snare_shot`**（ranged・power1.2・CD3.5・`chill`50%）。鈍足化で「誘導/弱体化」を表現 | support 役・回復/バフは SkillExecutor 未対応のためデバフで表現 |
| P3-D066-4 | **回復/バフは見送り**（alchemist MVP と同方針）。SkillExecutor は damage のみ実行 | スコープ最小化 |
| P3-D066-5 | **ジョブ副スキルの状態異常付与を有効化**（`_try_apply_secondary_skill_status`）。従来は weapon 主スキルのみ付与 | 副スキルの `apply_status` を機能させる最小コード追加 |
| P3-D066-6 | バランス値は P3-D050b に従い都度調整 | プレイ感依存 |

## 旧セーブ残存データ修正 / パーティアイコン統一（2026-06-29 — P3-FIX-002）

| # | 決定 | 根拠 |
|---|---|---|
| P3-FIX-002-1 | **基本ロスター正規化を追加**（`GameState.normalize_base_roster()` を `SaveManager._apply_roster_save` のロード時に実行）。基本職 `adventurer_0..4` の `display_name`/`job_id` を `BASE_ROSTER_DEFS` で上書き | 旧セーブの「戦士/盗賊/魔術師」等が `_migrate_job_id`（job_id のみ移行）で残存していた。基本職にカスタム改名機能は無く上書き安全 |
| P3-FIX-002-2 | **vanguard / beast_tamer に仮バストアイコンを追加**（dot シートから 128px 生成 / `IconPaths` に `chr:vanguard` `chr:beast_tamer` 追加）。パーティパネルの 32px ドット絵フォールバック（小さく不揃い）を解消 | helper_a(vanguard) 等で枠サイズ不揃いが発生していた |
| P3-FIX-002-3 | **既知の残課題**: vanguard/beast_tamer は仮アイコン＝ピクセル絵柄。剣士/レンジャー/錬金（ハイレゾイラスト）と絵柄が不一致。完全統一には専用イラスト提供が必要 → **解消済**: 2026-06-29 にヴァンガード/ビーストテイマーの本イラストを実装（全5職ハイレゾ統一） | 専用素材提供済 |

## ボス戦フリーズ修正（2026-06-29 — P3-FIX-003）

| # | 決定 | 根拠 |
|---|---|---|
| P3-FIX-003-1 | **`_append_log` のログ間引きを `queue_free()` 単独→`remove_child()`＋`queue_free()` に修正**（`DungeonScene.gd`） | `queue_free()` はフレーム終端まで遅延削除のため `while get_child_count() > _LOG_MAX` 内で件数が減らず**無限ループ→フリーズ**。`remove_child()` で即時 detach し解消 |
| P3-FIX-003-2 | 発症条件＝バトルログが `_LOG_MAX(60)` 超過。長期戦のボス戦で初発症。P3-D074(ログ常駐化)/P3-D077(全員スキルログ)で行数増加し顕在化 | 既存バグの顕在化 |

## 断片ロア実機配信 クローズ（2026-06-29 — P3-D072-LORE）

| # | 決定 | 根拠 |
|---|---|---|
| P3-D072-LORE | **断片ロア実機配信を完了クローズ**。`world/12_Fragments.md` の `# LF` ブロック6件が `DungeonController` の碑文イベントID（ancient_record / mourngate_rune_shell / pilgrim_marker / record_margin / forge_brand / lamp_relief）と一致し、本文パーサ（`CatalogHelper._load_fragment_entries`）・碑文表示（`DungeonScene` `type:"lore"`）・Codex「記録」カテゴリの配線を確認済 | コード・コンテンツ・ID対応が既に揃っており、残は実機確認のみ。オーナー判断でクローズ |

## 回復/バフスキル MVP（2026-06-29 — P3-D078）

> P3-D066-4 / alchemist MVP で見送っていた回復/バフを SkillExecutor に解禁。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D078-1 | **SkillExecutor を damage 専用から heal/buff 対応へ拡張**。`can_cast` を `effect_type != "none"` に緩和し、CD判定/CDセットのみ行う `execute_support_skill()` を追加（効果適用は呼び出し側） | 既存 damage 経路（`execute_damage_skill`/`calculate_damage`）は不変のまま最小拡張 |
| P3-D078-2 | **回復スキル `mend`（治癒・CD5.0・heal）**。発動時 `CombatController.get_most_injured_member_index()` の最も負傷した生存メンバーを `HEAL_SKILL_BASE(14)×power` 回復（`_apply_healing_bonus` 適用）。**負傷者ゼロなら CD を消費せず不発** | オート戦闘での無駄撃ち防止・単体集中回復で MVP 単純化 |
| P3-D078-3 | **バフスキル `empower`（鼓舞・CD6.0・buff）**。`empower` 状態（`stat_mod`/`outgoing_damage_multiplier=1.3`/3tick）を生存メイン編成全員に付与。与ダメ倍率は通常攻撃・スキル双方に既存配線で適用 | 既存 `get_member_outgoing_damage_multiplier` を流用し追加配線なしで成立 |
| P3-D078-4 | **alchemist に `mend`/`empower` を learnable 追加**（並び= hex_bolt, mend, empower, ...）。既定装備2枠＝hex_bolt+mend（火力+回復）で支援役の identity を確立。装備変更で empower に差替可 | キャラ管理(P3-D077)のスキル装備と整合 |
| P3-D078-5 | **演出**: 回復は対象頭上に緑「+N」ポップ＋発動者にスキル名。バフは `STATUS_ICON_DEF` に `empower`(「攻」橙)アイコン追加で付与可視化。EquipmentScene スキルタブは heal/buff 用の説明文に分岐 | 既存 `_spawn_damage_number`/`_spawn_skill_name`/状態アイコン機構を流用 |
| P3-D078-6 | **防御バフ（被ダメ減）は今回見送り**。敵→メンバーのダメージ計算に member `incoming_damage_multiplier` 未配線のため。将来 vanguard 用に別途配線 | スコープ最小化 |

## ボススキル MVP（2026-06-29 — P3-D079）

> Master Plan / Backlog で Defer されていた「敵スキル / ボス mechanics」を MVP 実装。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D079-1 | **EnemyData に `skill_ids: Array[String]` / `skill_use_chance: float` を追加**。敵ターンで `skill_use_chance` 判定→使用可能スキル（CD明け）からランダム発動、無ければ通常攻撃 | データ駆動でボス/エリートにスキル付与可能。既存通常攻撃はフォールバックで不変 |
| P3-D079-2 | **敵スキルは共有 `SkillExecutor` で CD 管理**（key=`"enemy:<id>"`）。`execute_support_skill` で CD ゲートのみ行い、効果適用は DungeonScene 側 | 味方スキルと同一機構を流用・追加状態管理なし |
| P3-D079-3 | **Serdion に2スキル付与（`skill_use_chance=0.4`）**: `boss_enrage`（激昂・buff・CD12: 自身に `enrage` 与ダメ+40%/3tick）／`boss_decree_wave`（断罪の波動・damage・CD6・`target_type="all_party"`: 全味方に attack×0.7 のAoE） | 「激昂→全体攻撃」で危険な連携を演出。AoEは全滅判定（既存）に直結 |
| P3-D079-4 | **演出**: 敵ドット絵頭上に赤系スキル名ポップ（`_spawn_enemy_skill_name`）。AoEは各対象に被弾VFX＋赤ダメージ数字、ログに対象別内訳。撃破時は該当スプライト非表示 | 既存 `_spawn_damage_number`/`_play_chr_hurt`/被弾処理を流用 |
| P3-D079-5 | **敵スキルの属性耐性/被ダメ補正は今回最小**（メンバー側 element 耐性・incoming 補正は未配線）。`_calc_enemy_damage_to_member` に `power_multiplier` 引数を追加しスキル威力のみ反映 | スコープ最小化・既存敵ダメージ式を踏襲 |
