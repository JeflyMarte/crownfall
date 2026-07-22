# Crownfall — Decision Log

## 初期決定（プロジェクト開始時）

| # | 決定事項 | 詳細 |
|---|---|---|
| D-001 | 自動探索採用 | プレイヤーは隊を直接操作しない。方針選択のみ |
| D-002 | 5分周回採用 | 通常ダンジョン1周を4〜6分に設計。**→ P3-DG-STG-001 でメイン章（1-1 等）5〜10分に上書き** |
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
| P3-W-018 | **モーンゲート敵6体の Codex 調査記録を執筆** — `codex_research_note` を深掘りロア（祖先種・鉱物化適応の仕組み・王都/遺物/歴史への接続を1点・能力は自然現象=エルダで記述・魔法不在）へ改稿。`10_LoreDelivery §7` の調査記録文体に準拠。弱点/耐性は既存 `element_*` 流用。`rune_roach`=王墓の回廊 / `crown_eater_rat`=忘れられた納骨堂 / `clock_moth`=封鎖監獄 へ `codex_habitat` をロア整合。反映: `world/05 §3`,`resources/enemies/{sepia_hound,rune_roach,crystal_hedgehog,crown_eater_rat,clock_moth,serdion}.tres` | オーナー決定（A・設定→実装直結） |
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
| P3-D049 | **九王ゆかりの地を確定（伝承）** — 九王を既存地名と1:1対応（開拓王↔ノースリーチ / 守護王↔ストームクラウン砦 / 学識王↔王立図書院 / 信義王↔アイゼンプレイン / 巡礼王↔王の大街道 / 鍛冶王↔アイアンフォージ・レッドフォージ / 海統王↔シーゲート・シャッタードアイルズ / 森護王↔ヴェルディア・グリーンホロウ / 継承王↔王都アステリア・王座の深淵）。伝説武器の所在（⑤）と整合。公開は伝承レベル、アステリア＝継承の中心地は内部留置。現存都市の多くは戦後成立で九王と非接続。反映: `world/07 §5.5` | オーナー決定 |
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

## スキル習得＋武器スキル（2026-07-02 — オーナー承認 / P3-SKILL-001）

> P3-D077 の装備スキルに **レベル習得** と **レジェンド武器スキル** を追加。Lv 上限は **50**（P3-D035a から引き上げ）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-SKILL-001-1 | **Lv 上限 50**（`LevelSystem.MAX_LEVEL`）。成長式は据え置き（+6 HP / +2 ATK per Lv） | オーナー承認 |
| P3-SKILL-001-2 | **ジョブスキルは `skill_unlocks` で Lv 解放**。解放状態はセーブせず Lv から導出（`SkillProgression`） | セーブ互換・単一正 |
| P3-SKILL-001-3 | **装備枠 2 は維持**。未解放スキルは装備不可。ロード時に `normalize_equipped_skills` | P3-D077 整合 |
| P3-SKILL-001-4 | **属性斬撃（kindling/static/rime）はジョブプールから除外** → 名前付き武器を **LEGENDARY** 化し `fixed_skill_id` で供給 | 武器主役 progression |
| P3-SKILL-001-5 | **武器スキルは装備枠外**。戦術「スキル」枠で装備スキル不発時にレジェンド武器スキルを試行（CD 独立: `member:weapon:skill_id`） | 第3系統 |
| P3-SKILL-001-6 | **COMMON 初期武器**（iron_sword / hunting_bow / apprentice_staff）は `fixed_skill_id` なし | P3-D077-5 継続 |

## ソードマン習得スキル10（2026-07-02 — オーナー承認 / P3-SKILL-002）

| # | 決定 | 根拠 |
|---|---|---|
| P3-SKILL-002-1 | **ソードマンは Lv50 まで習得10**（装備枠2は維持）。解放 Lv=1/6/12/18/24/30/36/42/48/50 | オーナー承認。5本では少ない |
| P3-SKILL-002-2 | **新規9スキル**（`rend_slash`〜`apex_slash`）。属性斬撃は引き続きレジェンド武器専用 | 近接・slash タグで連携軸 |
| P3-SKILL-002-3 | **連刃**（`chain_slash`）は `reserve_condition=enemy_has_bleed` で温存 | 裂傷斬→出血追撃コンボ |

## レンジャー習得スキル10（2026-07-02 — オーナー承認 / P3-SKILL-003）

| # | 決定 | 根拠 |
|---|---|---|
| P3-SKILL-003-1 | **レンジャーは Lv50 まで習得10**。解放 Lv=1/6/12/18/24/30/36/42/48/50（ソードマンと同曲線） | オーナー承認 |
| P3-SKILL-003-2 | **新規7スキル** + 既存3（`aimed_shot`/`snare_shot`/`hex_bolt`）。遠隔・pierce タグ軸 | 斥候・標的連携 |
| P3-SKILL-003-3 | **追標射**（`mark_pursuit`）は `reserve_condition=enemy_has_mark` で温存 | 狩人の標→追撃 |

## アルケミスト習得スキル10（2026-07-02 — オーナー承認 / P3-SKILL-004）

| # | 決定 | 根拠 |
|---|---|---|
| P3-SKILL-004-1 | **アルケミストは Lv50 まで習得10**。解放 Lv=1/6/12/18/24/30/36/42/48/50 | Alpha 3職目・オーナー承認 |
| P3-SKILL-004-2 | **新規7スキル** + 既存3（`hex_bolt`/`mend`/`empower`）。攻撃/回復/鼓舞の支援軸 | 杖 mid 射程 |
| P3-SKILL-004-3 | **崩呪**（`vulnerable_surge`）は `reserve_condition=enemy_has_vulnerable` で温存 | 脆弱の粉→追撃 |

## ヴァンガード習得スキル10（2026-07-02 — P3-SKILL-005）

| # | 決定 | 根拠 |
|---|---|---|
| P3-SKILL-005-1 | **ヴァンガードは Lv50 まで習得10**。タンク軸（guard/shield・stun/fear） | 基本5職完遂 |
| P3-SKILL-005-2 | **恐怖追撃**（`fear_chain`）は `reserve_condition=enemy_has_fear` | 威嚇斬→追撃 |

## ビーストテイマー習得スキル10（2026-07-02 — P3-SKILL-006）

| # | 決定 | 根拠 |
|---|---|---|
| P3-SKILL-006-1 | **ビーストテイマーは Lv50 まで習得10**。生態軸（毒・冷却・鼓舞） | 基本5職完遂 |
| P3-SKILL-006-2 | **猛毒噴射**（`venom_burst`）は `reserve_condition=enemy_has_poison` | 毒矢→追撃 |

## P3-SKILL Closeout（2026-07-02 — P3-SKILL-007）

| # | 決定 | 根拠 |
|---|---|---|
| P3-SKILL-007-1 | **基本5職すべて Lv50 習得10 完了**（P3-SKILL-001〜006）。装備枠2・必殺・レジェンド武器スキルは据え置き | オーナー承認済み一括実装 |
| P3-SKILL-007-2 | **新規 SkillData 計39本**（職別7〜9 + システム既存流用）。`CODEMAP` / `game/06` 同期 | HQ Closeout |
| P3-SKILL-007-3 | **次レーン** = P3-BETA-001（2本目DG 設計・オーナー Decision）または P3-GACHA-006（ガチャ再設計・未GO） | CurrentState キュー |

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

> **⚠ 上書き済（2026-07-11）:** 素材体制は **P3-MAT-003**（炉研ぎ3種）へ移行。ドロップは `pick_combat_drop_material()`、レシピは **P3-MAT-CRAFT-001**。以下は履歴。

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

## 行動順制（イニシアチブ・ラウンド制）＋行動順表示（2026-06-29 — P3-D083）

> 動機: 従来は1 tick で味方全員＋敵全体が一括行動し「同時攻撃」に見えた。速度（イニシアチブ）に基づく行動順で1体ずつ行動させ、行動順を画面表示する。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D083-1 | **ラウンド制**（1 tick=1ラウンド）。ラウンド開始時に生存ユニット（味方＋群れ各敵）を**イニシアチブ降順**で並べ、1体ずつ逐次行動。速度は順番のみに影響（行動回数は全員1回） | 「行動順に行動」の最小素直実装。ATB（速度で回数差）は不採用 |
| P3-D083-2 | **速度指標＝既存 `initiative_score` 流用**（味方=武器`attack_speed`×ジョブ補正×Affix、敵=`attack_speed`）。同値は**味方優先→index昇順**。`CombatController.build_turn_order()` が生成 | 既存 P3-D019 実装の流用 |
| P3-D083-3 | **逐次表示**: 各ユニット行動間に速度連動の短ディレイ（`_attack_stagger_delay`）。味方は「通常攻撃＋装備スキル」を解決、敵はアクティブのみ鈍化/スキル判定後に攻撃。フォーカス撃破（味方は先頭生存敵を狙う）維持 | テンポ維持・既存処理流用 |
| P3-D083-4 | **多重実行防止**: 逐次awaitでラウンド処理が `wait_time`(x1=1.5s) を超え得るため `_round_active` ガードで再入を抑止（処理中の timeout は無視） | 1ラウンド=複数awaitに伴う再入バグ回避 |
| P3-D083-5 | **行動順表示UI**: 画面上部にアイコン列（味方=CHRアイコン/敵=敵ドット idle）。ラウンド開始時に構築、**現在行動中を拡大＋不透明で強調**、行動前/他は淡色、死亡で除外。このラウンドの順のみ表示 | オーナー要望（アイコン式・当該ラウンドのみ） |
| P3-D083-6 | **`does_enemy_act_first` の陣営先制ログを廃止**（行動順表示に統合）。撃破処理は `_award_enemy_kill`/`_on_active_enemy_killed`/`_finalize_combat_cleared` に分割（群れ繰り上げと整合） | 行動順制への一本化・関数責務分離 |

## 群れ出現（複数敵）MVP（2026-06-29 — P3-D082）

> 動機: 一定確率で複数の敵が同時に出現する戦闘を追加し、難易度に緩急をつける。群れ対象は敵ごとに事前定義。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D082-A1 | **群れ可否は `EnemyData.can_swarm`（+`swarm_min`/`swarm_max`）で敵側に定義** | 「群れる敵を最初に決めておく」要望に直結 |
| P3-D082-A2 | **対象＝sepia_hound / crown_eater_rat**（lore=群れ・低HPの遊撃型）。同種のみの群れ | テーマ適合・MVP単純化 |
| P3-D082-B | **COMBAT 部屋でのみ 20%（`SWARM_CHANCE`）で群れ化、サイズ2〜3。ELITE/BOSS は常に単体** | 雑魚戦のみ・節度ある頻度 |
| P3-D082-C1 | **CombatController を群れ配列化**（`swarm_data/hp/atk/def/exp`＋`active_enemy_index`）。`current_enemy_*`/`_scaled_*` は常に「アクティブ（先頭生存）敵」を映すプロキシ | 既存単体ロジックをアクティブ敵に対し再利用（最小破壊） |
| P3-D082-C2 | **プレイヤーは先頭フォーカス撃破**（全員がアクティブ敵を集中攻撃→撃破で次へ繰り上げ）。全滅で戦闘終了 | 既存攻撃/スキル経路を改変せず流用 |
| P3-D082-C3 | **敵ターンは生存敵が各自1回ずつ攻撃**（被ダメが敵数分に増加＝難易度上昇） | 群れの脅威を表現 |
| P3-D082-C4 | **状態異常はアクティブ敵のみ `"enemy"` 単一スロットを流用し、繰り上げ時にクリア**（StatusResolver の多重化は見送り） | フォーカス撃破モデルでは攻撃対象＝状態付与対象が常にアクティブのため破綻せず、改修量を最小化（承認時の"多重化"を実装簡潔性のため調整） |
| P3-D082-D | **UI＝横並び固定スロット**（slot0 は既存ノード流用、2体目以降は duplicate 生成）。敵ごとに HPバー＋`Lv{n} 名前`ネームプレート（群れ時は小フォント）。撃破は個別 death アニメ＋当該HPバー/名前を即時非表示（死体は残置） | 視認性・既存オーバーレイ機構の流用 |
| P3-D082-E | **報酬は撃破ごと加算**（EXP/Gold）、**武器ドロップは各敵個別判定** | 敵数分の報酬を自然に反映 |
| P3-D082-F | **敵レベル(P3-D081)は群れ各体に同一適用** | 一貫性 |

## 敵レベル制 MVP（2026-06-29 — P3-D081）

> 動機: 同一ダンジョンでも難易度を調整できるようにする（敵を強く・EXP も増やす）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D081-1 | **敵レベルは DG 単位で固定**（`DungeonData.enemy_level`、既定=1）。`DungeonController.get_enemy_level()` 経由で戦闘開始時に確定。**ダンジョン中はレベルアップしない** | 難易度調整に直結・最小実装。深度逓増（C案）は不採用 |
| P3-D081-2 | **ステータスは乗算スケール**: `HP/ATK = base × (1 + 0.10×(Lv−1))`、**DEF は据置**。Lv1 で tres 基準値＝完全互換 | 役割が薄い DEF を据置にしつつ攻防 HP を一様強化 |
| P3-D081-3 | **EXP は別係数**: `exp = base × (1 + 0.15×(Lv−1))`。プレイヤー必要EXP=100×Lv との釣り合いは P3-D050b に従い都度調整 | レベル相応の報酬。整数丸め |
| P3-D081-4 | **共有 Resource は不変**。`CombatController` がスケール後値（`_scaled_max_hp/_scaled_attack/_scaled_defense/_scaled_exp` と `enemy_level`）を派生変数で保持し、`get_enemy_max_hp/attack/defense` 経由で参照 | 共有 EnemyData のプール汚染を回避 |
| P3-D081-5 | **表示**: ネームプレートを `Lv{n} {敵名}` 形式に変更（常時表示） | オーナー要望 |

## ヴァンガード ドット絵実装 / 敵スプライト画質改善（2026-06-29 — P3-ART-002）

| # | 決定 | 根拠 |
|---|---|---|
| P3-ART-002-1 | **vanguard のダンジョンドット絵を実装**。プレースホルダ（`CHR_Warrior_Sheet.png` 流用）を廃し、提供素材(232px・north-east)から `assets/characters/vanguard/` に idle/attack/hurt/death 各9枚を配置、`CHR_Vanguard.tres` を再生成（idle=9フレーム実アニメ） | 5職中 vanguard のみダンジョン絵がプレースホルダだった |
| P3-ART-002-2 | **レンジャー提供素材は既存実装と同一**のため対応不要（バイナリ一致確認） | 重複差替の回避 |
| P3-ART-002-3 | **敵スプライトを Nearest フィルタ化＋表示サイズ 160→132px**（`DungeonScene.tscn` EnemySprite/BossSprite `texture_filter=1` / `ENEMY_BODY_TARGET_PX`）。96pxドット絵の拡大ぼやけを解消し精細化 | 既存 Linear 拡大でぼやけていた（オーナー指摘） |

## 戦闘 時間モデルを CT/ATB へ移行（2026-06-30 — P3-D084）

> 戦闘システム v1.0（深い事前準備で勝敗が決まるオート戦闘）への再設計の土台。オーナー承認: ①CT/ATB全面移行（P3-D083 ラウンド制を置換）／②薄い縦切りMVP（まず通常攻撃のみ）／③3人据置（陣形=前後列のみ・4人はBeta）。後続: P3-D085 スロット5＋防御＋必殺 / P3-D086 AI設定（Tactics→Condition→Priority→Target）。defer: 遺物/陣形2×2/生態特効/Biome/探索/プリセット/パッシブ/タグコンボ/詠唱。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D084-1 | **ラウンド制（P3-D083）を CT/ATB 制へ置換**。各生存ユニット（味方＋群れ各敵）が個別 CT を持ち、CT が 0 に達したユニットから 1 体ずつ行動。速度が攻撃回数に直結する | 「全行動にCT・速度で行動回数差」要望の土台。`build_turn_order`/`does_enemy_act_first` は撤去 |
| P3-D084-2 | **スケジューラ＝イベント駆動（決定的）**。`CombatController.advance_to_next_actor()` が全ユニットの CT を最小残量ぶん減算→0 のユニットを選択（同時0は味方優先→index昇順）→行動 CT を再セット。`get_ct_order()` で CT 残量昇順を取得 | delta 実時間積分を避け、pause/倍速とも整合する決定的実装 |
| P3-D084-3 | **行動 CT ＝ `BASE_ACTION_CT(2.0) / initiative_score`**（速度は既存 P3-D019 流用：味方=武器attack_speed×ジョブ×Affix／敵=attack_speed）。共有 Resource 不変 | 速い装備/ジョブ/Affix ほど多く動く。既存速度指標を再利用 |
| P3-D084-4 | **1 パルス＝1 行動**（`CombatTimer` 1 timeout で 1 ユニットのみ行動）。間隔 x1=0.55s / x2=0.28s。await 不使用＝同期実行で再入なし（`_round_active` は安全保持） | P3-D083 の逐次await＋`wait_time`超過問題を解消。倍速＝パルス間隔短縮 |
| P3-D084-5 | **スキルCDは進行 CT 量で、状態異常は一定 CT（`CT_PER_STATUS_TICK=2.0`）ごとに 1 tick**。群れ/フォーカス撃破/報酬/全滅判定は不変。スキルは現行 CD 経路を暫定流用（5スロット/必殺は P3-D085） | DoT 持続をラウンド時代と同等に保ちつつ最小改修 |
| P3-D084-6 | **表示＝上部アイコン列を「行動順」から「CT プレビュー（CT 残量昇順・次に動く順）」へ転用**。行動ごとに再構築し先頭（最短 CT）を強調 | P3-D083 の UI 機構を流用し追加コスト最小。CT バー化は後続で検討可 |

## スキルスロット5＋防御＋必殺技（2026-06-30 — P3-D085）

> 戦闘 v1.0 MVP縦切り②（P3-D084 の上に構築）。1 行動＝1 スロット（排他選択）。スロット選択の暫定優先度は P3-D086（AI設定 Tactics→Condition→Priority→Target）で player 設定化する。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D085-1 | **メンバーの 1 CT 行動を「5スロットから 1 つだけ実行」へ再構成**（従来=通常攻撃＋装備スキル全部を同 tick 一括）。スロット＝通常攻撃 / 防御 / スキル① / スキル② / 必殺技 | ATB（1行動=1手）と整合。スキルが通常攻撃に積み増しされない＝威力配分が選択になる |
| P3-D085-2 | **暫定選択優先度（D086 で設定化）**: 必殺技(発動可) → 防御(条件) → スキル①②(最初に撃てる1つ) → 通常攻撃 | AI レイヤ未実装のためのデフォルト。`_do_member_turn` に集約 |
| P3-D085-3 | **必殺技スロット＝長CD高威力スキル**。`JobData.ultimate_skill_id`（空なら `Constants.DEFAULT_ULTIMATE_SKILL_ID`）。MVPは全ジョブ共通の汎用 `ultimate_strike`（power×3.0 / CD30.0 / `slot_type="ultimate"`）。CD は CT 秒で管理（既存 SkillExecutor 流用） | 必殺 tier の実証を最小ファイルで。ジョブ別必殺は後続で差別化 |
| P3-D085-4 | **防御スロット＝自己被ダメ減バフ**。新ステータス `guard`（`stat_mod` / `incoming_damage_multiplier=0.5` / 2 tick）を自身付与。`CombatController.get_member_incoming_damage_multiplier()` を新設し `_calc_enemy_damage_to_member` に配線（D078-6 で保留していたメンバー被ダメ補正を実配線） | 防御に実効果。敵通常/敵スキル両方の被ダメに適用 |
| P3-D085-5 | **防御の暫定発動条件**＝自HP30%未満 かつ guard 未付与（連続防御で硬直しないようガード）。頭上に「防御」ポップ＋状態アイコン「防」 | オート戦闘での無駄/硬直防止。条件は D086 で player 設定化 |
| P3-D085-6 | **SkillData に `slot_type`（attack/defend/skill/ultimate）/`range_type`（melee/mid/long/global）を追加**。現状 slot_type=ultimate のみ必殺判定に使用、range_type はメタ情報（挙動未反映） | 共通フォーマット拡張。射程/AI は後続で利用 |
| P3-D085-7 | **スキル①②の装備は P3-D077（最大2・`MAX_EQUIPPED_SKILLS`）を流用**。必殺/防御は当面 player 装備対象外（ジョブ/既定で供給）。5スロット編集UIは P3-D086 で整備 | UI 大改修を回避しつつ機構を先行実装 |

## AI設定（Tactics→Condition→Priority）MVP（2026-06-30 — P3-D086）

> 戦闘 v1.0 MVP縦切り③。P3-D085 の固定スロット優先度を player 設定の戦術プリセットで置換。スロット選択を「戦術＝優先度＋発動条件」で決める。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D086-1 | **戦術（Tactics）をメンバー単位の最上位AI設定として導入**。`Adventurer.tactics_id`（空=`balanced`）・セーブ永続（`SaveManager` party 直列化に追加）。`GameState.get_member_tactics_id/set_member_tactics` | プリセット選択でAI挙動を一括切替。最小データで「作戦を組む」体験を成立 |
| P3-D086-2 | **`CombatTactics`（静的）で 6 プリセット定義**: バランス/積極攻撃/慎重/生存優先/ボス集中/雑魚掃討。各プリセット＝優先度順スロット計画（`{slot, condition, value}` の配列） | Tactics→Priority→（per-slot）Condition を 1 構造に集約。データ駆動で増設容易 |
| P3-D086-3 | **Condition MVP セット**: `always` / `self_hp_below`(HP割合) / `enemy_is_boss` / `enemy_is_elite` / `enemy_count_gte`(体数) / `ally_dead`。`CombatTactics.condition_met(rule, ctx)` で評価 | オート戦闘で意味を持つ最小条件。距離/状態条件は後続（射程・Target と併せて） |
| P3-D086-4 | **実行エンジン**＝`DungeonScene._do_member_turn` を戦術プラン駆動へ置換。優先度順に評価し「条件成立かつ実発動できた最初のスロット」で行動確定（不発時は次ルール→最終フォールバック通常攻撃）。`_build_tactics_context` が HP割合/Boss/Elite/敵数/味方死亡 を供給。防御は条件を戦術へ移譲し二重ガードのみ抑止（`_do_member_defend_slot`） | P3-D085 の各スロット executor をそのまま再利用。固定優先度を撤去 |
| P3-D086-5 | **編集UI**＝キャラ管理「スキル」タブ最上部に戦術 OptionButton（`EquipmentScene`）。選択で `set_member_tactics`→保存は戻る時。per-slot 条件のフル編集（ガンビット式）は後続 | UI 大改修（新タブ/行ビルダ）を避け、プリセット選択で価値を先行提供 |
| P3-D086-6 | **Target 層（敵個体の狙い分け：Lowest HP/Highest ATK 等）は本MVPでは見送り**。現行フォーカス撃破（全員がアクティブ先頭敵を集中攻撃・`apply_damage_to_enemy` 一本）では選択肢が無く効果が出ないため。Target 実装は「複数敵同時ターゲット可能化」の戦闘モデル変更を伴う別 Decision | スコープ最小化・無効機能の実装回避 |

## 生態特効＋図鑑連動 MVP（2026-06-30 — P3-D087）

> 「図鑑で調べるほど攻略精度が上がる」コア体験の足がかり。武器の生態特効と Codex 表示を連動。新アート/敵データ追加なし。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D087-1 | **生態特効の判定キー＝既存 `EnemyData.codex_class`** を流用（獣類/昆虫類/古代種…）。敵データの新規フィールド/編集は不要 | モーンゲート6体は codex_class 設定済（獣類×3/昆虫類×2/古代種×1）。world/04 分類と整合 |
| P3-D087-2 | **特効源＝武器のみ（MVP）**。`WeaponData` に `bane_class`（敵 codex_class と同文字列）/`bane_multiplier`（既定×1.3）を追加。スキル特効は後続 | オーナー確定（weapon_only）。武器選びに直結 |
| P3-D087-3 | **与ダメ計算**: `_apply_enemy_mitigation` に `member_index` を追加し、武器 `bane_class`＝敵 `codex_class` で `×bane_multiplier`。**属性弱点(×1.25)/耐性(×0.75)と乗算で併用**。ログ/数値に `[特効:獣類]` タグ | 既存の弱点タグ機構を流用。通常攻撃＋装備スキルに適用（武器の常時効果） |
| P3-D087-4 | **図鑑連動＝情報表示のみ**（特効ボーナスは常時適用）。Codex 敵詳細（stage≥4）の「弱点/耐性」行に `特効: {codex_class}` を併記＝「この生態には◯◯特効が有効」 | オーナー確定（info_only）。図鑑＝攻略本＝武器選択の導線。機構ゲートは将来 |
| P3-D087-5 | **初期特効付与（調整可）**: 燻鉄の大剣=獣類 / 霜結びの剣=昆虫類 / 霊廟の聖別刃=古代種（各×1.3）。他武器は特効なし | 火→獣・氷→昆虫・聖→古代種でテーマ整合。3分類を被覆 |
| P3-D087-6 | **スコープ外**: 防具の分類耐性 / 敵→味方の特効 / 調査段階による特効ゲート / Biome地形補正 | MVP最小化 |

## パッシブ / リアクション MVP（2026-06-30 — P3-D088）

> 戦闘 v1.0 のビルド構築深化。戦闘中に自動発火する常在能力（共通フォーマット Trigger→Condition→Effect→Cooldown）を導入。D086(戦術)・D085(状態/被ダメ補正)・D084(CT) を再利用し新アート/新メカ最小。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D088-1 | **パッシブ定義＝`CombatPassives`（静的・データ駆動）**。CombatTactics と同方式でコード内 `_DEFS`＋ジョブ紐付け `_JOB_PASSIVES`（tres 非増設）。共通フォーマット Trigger→Condition→Effect→Cooldown | 既存戦術と一貫。武器/遺物への移譲は後続で容易 |
| P3-D088-2 | **Trigger MVP**: `on_combat_start` / `on_hit_taken`（被弾・生存時） / `on_ally_death`（生存者で発火）。`on_attack`(N回毎)・距離/タグ系は後続 | オート戦闘で意味を持つ最小イベント。既存の敵通常/敵スキル被弾点・撃破点にフック |
| P3-D088-3 | **Condition MVP**: `always` / `self_hp_below`(HP割合)。**Effect MVP**: `apply_status`(status_id / target self\|party) / `heal`(party・`_apply_healing_bonus` 経由) | D085 の guard/empower・CombatController.apply_status/heal_party を再利用。新規効果ゼロ |
| P3-D088-4 | **CD＝CT秒で管理**（`_passive_cd[\"idx:pid\"]`、`_run_combat_step` で進行CTぶん減算）。発火成功時のみCDセット。戦闘開始でクリア。頭上に `◇名称` ポップ＋ログ `[パッシブ]` | スキルCD(D084)と同管理。`on_combat_start`(CD0)は実質1回 |
| P3-D088-5 | **ジョブ別初期パッシブ**: vanguard=鉄壁(被弾&HP<50%→guard・CD6) / swordsman・ranger=高揚(戦闘開始→empower自己) / alchemist=野戦救護(味方死亡→party回復12) / beast_tamer=群れの本能(味方死亡→empower全体) | 各ロールの性格付け。タンク=耐え/支援=蘇生フォロー/連携=被撃破時の奮起 |
| P3-D088-6 | **スコープ外**: パッシブの player 編集/装備化・`on_attack`回数トリガ・無敵/バリア専用効果・リアクションの能動UI | MVP最小化。まずジョブ固定で機構実証 |

## 状態異常コンボ MVP（2026-06-30 — P3-D089）

> 戦闘 v1.0 の手応え強化。味方の攻撃ヒット時、敵に乗った状態異常を「起爆」して追加ダメージ＋消費。既存の毒/冷却付与スキルがそのまま起点になり、新アート/新データ不要。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D089-1 | **コンボ＝攻撃ヒット時の状態起爆**。味方の与ダメ確定直前にアクティブ敵の前提状態を判定し、成立なら 1 つだけ起爆＝追加ダメージをヒット値へ上乗せ＋その状態を消費（1ヒット1コンボ） | 追加分を攻撃ダメージへ folding することで既存の撃破/報酬判定をそのまま通す（別経路 apply 回避＝低リスク） |
| P3-D089-2 | **ルール定義＝`CombatCombos`（静的・コード内）**。`bonus = per_stack×stacks + round(hit_fraction×hit_damage)`。tres 非増設（Tactics/Passives/Combos 一貫） | データ駆動で増設容易。シナジータグの正式タクソノミは後続 |
| P3-D089-3 | **MVP 2種**: 毒(poison)→**毒爆発**（per_stack=8・毒消費） / 冷却(chill)→**粉砕**（hit_fraction=0.5・冷却消費）。評価順 poison→chill | 既存付与経路（属性スキル/Affix）が起点。提案の「毒爆発」「凍結→粉砕」に対応。数値は調整可 |
| P3-D089-4 | **基盤追加**: `StatusResolver.get_status_stacks/consume_status`、`CombatController.get_enemy_status_stacks/consume_enemy_status`。`DungeonScene._consume_enemy_combo_bonus` を通常攻撃＋スキル3経路（primary/buff系/secondary）の apply 直前に配線 | 状態の取得/丸ごと消費を最小APIで追加。全味方与ダメ経路を被覆 |
| P3-D089-5 | **表示**: 頭上に `毒爆発 +N` ポップ（橙）＋ログ `[コンボ] 毒爆発 +N`。ダメージ数値は攻撃と合算表示 | 起爆の視認性。専用ポップ関数は増設せず既存 `_spawn_damage_number` 流用 |
| P3-D089-6 | **スコープ外**: シナジータグ(Slash/Pierce/Fire…)の正式分類・味方への状態コンボ・出血/感電等の追加コンボ・コンボ専用VFX | MVP最小化。タグ体系は遺物/スキル拡張と併せて後続 |

## 遺物（Relics）MVP（2026-06-30 — P3-D090）

> 「武器=何で戦うか / 防具=どれだけ耐えるか / 遺物=どう戦うか」の第3の柱。入手/インベントリは作らず、プリセット選択（戦術と同UI）で常時倍率効果を付与する薄いMVP。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D090-1 | **1メンバー1遺物枠**。`Adventurer.relic_id`（空=なし）・セーブ永続（`SaveManager` party 直列化に追加）。`GameState.get_member_relic_id/set_member_relic` | 戦術(P3-D086)と同データパターン。最小データで第3枠を成立 |
| P3-D090-2 | **カタログ＝`CombatRelics`（静的・tres非増設）**。効果＝常時倍率 `outgoing_mult`/`incoming_mult`/`speed_mult`（既定1.0）。`effects_for(id)` でマージ取得 | Tactics/Passives/Combos と一貫。発火型/条件型は後続で拡張可 |
| P3-D090-3 | **配線＝戦闘の中央3フックのみ**（低リスク・全攻撃/被弾経路を被覆）: 与ダメ=`get_member_outgoing_damage_multiplier`、被ダメ=`get_member_incoming_damage_multiplier`、行動速度=`get_member_initiative_score`（CT短縮）。いずれも状態異常倍率と乗算。助っ人は遺物なし | 既存倍率関数に1係数を乗じるだけ＝ダメ計算/CT計算の散在を回避 |
| P3-D090-4 | **MVP遺物4種**: 王国軍旗(与ダメ×1.10) / 王盾の欠片(被ダメ×0.90) / 古い砂時計(行動速度+10%) / 狂戦士の護符(与ダメ×1.20・被ダメ×1.15のリスク型) | 攻/守/速/トレードオフを各1で被覆し、ビルド選択の体験を成立 |
| P3-D090-5 | **UI＝装備画面スキルタブ、戦術行の直下に遺物 OptionButton**（`EquipmentScene`・`_ensure_relic_ui`/`_refresh_relic_ui`/`_on_relic_selected`）。選択即 `set_member_relic`・保存は戻る時 | 戦術セレクタの実績パターンを流用。新タブ/インベントリUIを回避 |
| P3-D090-6 | **スコープ外**: ドロップ/インベントリ化・前後列/HP等の条件付き効果・通常N回毎などの発火型遺物・スキルCD直接短縮・遺物アイコン | MVP最小化。入手導線とイベント型は後続 Decision |

## 作戦プリセット MVP（2026-06-30 — P3-D091）

> 「ボス用」「周回用」等の作戦をまとめて保存し、ワンタップで全員へ一括切替。新メカ無し（既存の戦術/遺物設定を束ねるだけ）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D091-1 | **プリセット＝party 全体の「戦術＋遺物」セット**（武器/防具は含めない）。実体アイテム（武器/防具）は複数人同時装備で競合するため除外し、抽象選択（戦術/遺物）のみ束ねる | 競合ゼロで安全に一括適用。装備セット保存は後続 Decision |
| P3-D091-2 | **3スロット固定**（`GameState.COMBAT_PRESET_SLOTS=3`）。各スロット＝`{name, settings:{member_id:{tactics_id,relic_id}}}`。**member_id キー保持**で編成順が変わっても正しく復元 | 索引でなく id で持つことで party 入替に頑健 |
| P3-D091-3 | **API**＝`GameState.save_combat_preset(slot,name)` / `apply_combat_preset(slot)` / `get_combat_presets` / `has/get_combat_preset_name`。適用は現 party の member_id 一致分のみ `set_member_tactics`/`set_member_relic` を呼ぶ | 既存 setter 流用＝新規ロジック最小。未編成メンバー分はスキップ |
| P3-D091-4 | **セーブ永続**＝save ルートに `combat_presets`（party 横断のためメンバー直列化でなくトップレベル）。`duplicate(true)` で深複製 | per-member でなく party 設定のため roster 直列化と分離 |
| P3-D091-5 | **UI**＝装備画面スキルタブ最上部に「作戦: [プリセット▼] [適用] [保存]」（`EquipmentScene`・`_ensure_preset_ui`/`_refresh_preset_ui`）。保存＝現設定をスロットへ・適用＝全員反映後に戦術/遺物セレクタを再描画 | 戦術/遺物セレクタと同列に集約。新画面を作らない |
| P3-D091-6 | **スコープ外**: 武器/防具/アクセの装備セット保存・探索方針/プリセット連動・スロット数可変・プリセット名のリネームUI・ダンジョン開始画面からの切替 | MVP最小化。名前は既定「作戦N」自動付与 |

## 遺物 入手導線 MVP（2026-06-30 — P3-D093）

> D090（遺物=全種自由選択）に「集めて使えるようになる」進行を追加。オーナー確定＝**解放型A**（一度入手で恒久解放・全員装備可）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D093-1 | **所持＝解放型**（`GameState.owned_relics: Array[String]`）。一度入手で恒久解放・全員装備可。個数/重複/競合は持たない | MVP最小・競合ゼロ。「集めて広がる」体験を低リスクで成立。個数型は後続 |
| P3-D093-2 | **入手＝撃破ドロップ**（既存武器ドロップに相乗り）。`DungeonController.roll_kill_relic_drop(room_type)`＝**未所持から1つ抽選**。ボス=未所持あれば確定 / エリート=15% / 通常=なし / 全所持済=何も出ない | ボスを遺物の主入手源に。レアアイテム感を維持。確率は調整可 |
| P3-D093-3 | **解放は即時**（ドロップ時 `GameState.unlock_relic` で `owned_relics` 追加）。全滅時もロールバックしない（既存の武器/防具/アクセ ドロップが全滅でも inventory 保持なのと整合・Result 表示用 `last_run_relic_dropped` のみクリア） | 既存ドロップ挙動と一貫。失敗時の巻き戻し処理を増やさない |
| P3-D093-4 | **装備UI制限**＝D090 セレクタを「なし＋所持済みのみ」に変更（`EquipmentScene._refresh_relic_ui` で毎回再構築）。現在装備が未所持なら `(未所持)` 付きで参考表示し選択維持 | 未所持を選べないことで入手の意味を出す。旧セーブの未所持装備も壊さない |
| P3-D093-5 | **表示**＝戦闘ログ「遺物入手: ◯◯」＋Result 報酬行に遺物セル（アイコン無し・グリフ「遺」）。`GameState.last_run_relic_dropped`・セーブ永続（`owned_relics`） | 既存の武器/防具/アクセ報酬表示と同列。遺物アイコンは後続 |
| P3-D093-6 | **スコープ外**: 個数/重複・売却/分解・宝箱/イベント入手・ドロップ率バランス作り込み・遺物アイコン・図鑑連動 | MVP最小化 |

## 図鑑＝攻略本 拡充 MVP（2026-06-30 — P3-D092）

> 「調べるほど攻略しやすくなる」コア体験を前進。敵詳細の弱点/耐性ブロックを「戦闘データ」へ拡張し、調査段階に応じ戦闘直結情報を開示。新アート/敵データ追加なし（既存 EnemyData 流用・ヒントは自動生成）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D092-1 | **既存の段階開示（stage1-5）に乗せる**。stage4（追加調査）/stage5（調査完了）で開示量を増やす。低stageは従来通り | 既存の調査ループ（kills→stage）を再利用。新規進行を作らない |
| P3-D092-2 | **「弱点属性/耐性」ブロックを「戦闘データ」へ拡張**（`CodexScene._apply_enemy_combat_data`）。新ラベル/シーン変更なし（related ブロック流用） | UI 改修最小。1ブロックに集約 |
| P3-D092-3 | **stage4 開示**: 弱点/耐性 ＋ 行動間隔の目安（`attack_speed`→`BASE_ACTION_CT(2.0)/spd` の秒換算）＋ 攻撃付与状態異常（`on_hit_status_id`/`_chance`）＋ 特効分類 | CTテンポ・状態異常リスクという攻略に効く情報を先に開示 |
| P3-D092-4 | **stage5 追加開示**: 使用スキル一覧（`skill_ids`→表示名。ボス大技含む）＋ 有効戦術ヒント（弱点属性＋特効分類から**自動生成**、例「❄氷 が有効 ｜ 昆虫類特効が有効」） | 完全調査の報酬＝手の内開示。ヒントは手書きでなく派生＝データ増設ゼロ |
| P3-D092-5 | **データ供給**＝`CatalogHelper` 敵エントリに `attack_speed`/`on_hit_status_id`/`on_hit_status_chance`/`skill_ids` を追加。表示出し分けは CodexScene が stage で判定 | entry に素材を渡し、ゲートは表示側に集約 |
| P3-D092-6 | **スコープ外**: ボスのフェーズ/大技CTの手書き設定・調査専用テキスト・図鑑→装備への直接導線・武器特効の図鑑内逆引き | MVP最小化。自動生成で賄えない詳細は後続 |

## シナジータグ正式化 MVP（2026-06-30 — P3-D094）

> D089（状態異常コンボ）の上に、武器/スキルの「シナジータグ」を正式定義。攻撃の性質（斬撃/刺突/打撃・属性）をコンボ起爆条件に組み込み、編成・装備の連携軸を増やす。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D094-1 | **タグ正式定義＝`CombatTags`（静的・SSOT）**。物理(slash/pierce/blunt) + 属性(fire/ice/lightning/holy/dark) + 効果(bleed/poison/buff/debuff) の id↔和名。未知 id は無視（正規化） | タグ id を一元管理。武器/スキル/コンボが同一語彙を参照 |
| P3-D094-2 | **データ拡張**: `WeaponData.tags: Array[String]` を新設（`SkillData.tags` は既存流用）。攻撃のタグ＝武器タグ ∪（スキル時）スキルタグ。`DungeonScene._member_action_tags` が CombatTags で正規化して供給 | 攻撃ごとに性質タグが定まる。スキルは武器タグも継承＝武器選択がコンボに効く |
| P3-D094-3 | **コンボに `require_tag` を追加**（`CombatCombos`）。空=無条件、指定時は攻撃側がそのタグ保有時のみ起爆。`tag_eligible(trigger, tags)` で判定し `_consume_enemy_combo_bonus` に配線 | 「凍結→打撃で粉砕」「出血→斬撃で追撃」等のタグ連携を表現。既存の毒/冷却(無条件)は非回帰 |
| P3-D094-4 | **コンボ追加**: 出血(bleed)→**出血追撃**(require slash・per_stack6) / 感電(shock)→**感電**(require lightning・hit×0.4)。既存 毒爆発(無条件)/粉砕(無条件) は維持 | 追加は非回帰（タグ無し攻撃では発火しないだけ）。斬撃武器は普及済で出血追撃は到達容易 |
| P3-D094-5 | **武器タグ初期付与**: 朽刃=slash / 燻鉄=slash,fire / 霜結=slash,ice / 聖別刃=pierce,holy / 雷紋双刃=pierce,lightning / 呪杖=blunt,dark | 武器種(剣=斬/短=刺/杖=打)＋elementで整合。粉砕(杖=blunt)・感電(雷紋=lightning)の到達経路を確保 |
| P3-D094-6 | **スコープ外**: 同系統タグ揃えのシナジーボーナス・タグのUI/図鑑表示・敵側タグ耐性・タグ連鎖(3段)・スキルへの個別タグ付与作り込み | MVP最小化。まずタグ語彙＋タグ起点コンボの機構を実証 |

## 同系統タグ・シナジー＋タグ可視化 MVP（2026-06-30 — P3-D095）

> D094 のタグ基盤を活かし「同じ属性で揃える」ビルドに報酬を付与。さらに武器タグ/シナジーを装備画面で可視化し可読性を上げる。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D095-1 | **属性シナジー＝装備武器タグの共有数で発生**（`CombatSynergy`静的）。同一属性タグ(fire/ice/lightning/holy/dark)を**2人=+10% / 3人=+15%** の与ダメ。物理/効果タグは対象外（MVP） | 「炎で揃える」等の編成選択に報酬。属性に限定し効果を明快に |
| P3-D095-2 | **配線＝属性ダメージ段に1フック**。`CombatController.get_element_synergy_bonus(element)` を `DungeonScene._apply_enemy_mitigation` の属性処理に適用（attack_element 一致時のみ ×(1+bonus)・弱点/特効と乗算）。ログに `[シナジー:◯]` | 既存の属性処理に相乗り＝散在回避。味方攻撃のみ（敵被ダメ計算とは別経路） |
| P3-D095-3 | **算出は party 全員の装備武器タグ集計**（`compute_element_bonuses`）。スキル/遺物タグは含めず武器のみ（MVP） | 「武器選びで揃える」に焦点。毎ヒット算出だが party 小規模で軽量 |
| P3-D095-4 | **可視化＝装備スキルタブに情報行**（`EquipmentScene._refresh_tag_info`）。「武器タグ: 斬撃/炎 ｜ 属性シナジー: 炎 +10%」を表示。タグ和名は `CombatTags.display_name` | 既存セレクタ群と同列に集約。タグ/シナジーの効果を可読化 |
| P3-D095-5 | **スコープ外**: 物理/効果タグのシナジー・ロールボーナス(盾2人で防御UP等)・図鑑/戦闘中のシナジー表示・スキル/遺物タグの集計・属性別の専用VFX | MVP最小化。物理シナジーやロール系は後続 |

## ロールボーナス＋物理タグシナジー MVP（2026-06-30 — P3-D097）

> D095 の属性シナジーに加え、編成（ジョブ・ロール）と物理武器の揃えに報酬を付与。「誰を組ませるか／何で殴るか」を編成段階の選択肢にする。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D097-1 | **ロールボーナス＝party のジョブ role を 2人以上共有で発火**（`CombatSynergy.compute_role_bonuses`）。tank×2=被ダメ-8% / dps×2=与ダメ+6% / support×2=回復+20% / scout×2=会心+8%。role は `JobStatCalculator` 経由 | 同ロール重ね編成に明快な報酬。既存の役割語彙(tank/dps/support/scout)を流用 |
| P3-D097-2 | **物理タグシナジー＝物理タグ(slash/pierce/blunt)を 2人=+5% / 3人=+8% の与ダメ**（`compute_physical_bonus`・最大値採用・party 全体フラット）。属性シナジー(D095)とは別枠で乗算 | 属性で揃えにくい物理寄り編成にも揃え報酬。属性非依存のフラット枠で明快 |
| P3-D097-3 | **配線＝既存の中央倍率に相乗り**。与ダメ＝`get_member_outgoing_damage_multiplier` に ×(1+物理) ×role.outgoing。被ダメ＝`get_member_incoming_damage_multiplier` に ×role.incoming。回復＝`_apply_healing_bonus` に ×role.heal。会心＝`_calc_attack_base` に +role.crit | 散在回避。既存の状態/遺物倍率と同経路で一括適用 |
| P3-D097-4 | **可視化＝装備スキルタブの情報行に「編成ボーナス」行を追加**（`EquipmentScene._refresh_tag_info`）。物理連携・ロール各ラベルを列挙（無=「なし」） | D095 のタグ情報行に併記。編成の効果を装備段階で可読化 |
| P3-D097-5 | **スコープ外**: 陣形(2×2)・Aggro/Threat・3ロール以上の段階ボーナス・敵側ロール・素材/索敵への scout 反映・効果タグ(buff/debuff)のシナジー | MVP最小化。陣形/Threat は別系統で後続 |

## 探索方針プリセット連動 MVP（2026-06-30 — P3-D098）

> 既存の作戦プリセット（P3-D091＝戦術＋遺物）に「探索方針」を内包し、プリセット切替で *戦い方* と *探索の稼ぎ方* を一括変更できるようにする。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D098-1 | **探索方針＝run 単位で1つ**（`GameState.current_exploration_policy`）。`""`=なし / safe=安全優先 / material=素材優先 / relic=遺物優先 / codex=図鑑優先。run 中は固定（DG 中不変・敵Lv P3-D081 と同じ扱い） | 探索全体の傾向を1枚で表現。run 揮発でセーブ非依存（プリセットから復元） |
| P3-D098-2 | **効果（中央フックに相乗り）**: safe=被ダメ×0.92（`exploration_incoming_multiplier`→`get_member_incoming_damage_multiplier`）＋群れ出現率×0.5（`pick_combat_enemy_group`）／material=gold+15%（`accumulate_rewards`）＋ELITE 素材率 0.15→0.30（`apply_elite_bonus_loot`）／relic=ELITE 遺物率 0.15→0.25（`roll_kill_relic_drop`・BOSS据置1.0）／codex=撃破時 `add_enemy_kill` を二重計上し図鑑段階を加速（`_award_enemy_kill`） | 既存の倍率/抽選/ドロップ経路に最小フックで配線。新規システムを増やさない |
| P3-D098-3 | **プリセット連動**: `combat_presets[slot]` に `exploration_policy` キーを追加。`save_combat_preset` で現在方針も保存、`apply_combat_preset` で `set_exploration_policy` を反映。`SaveManager` は既存の `combat_presets` deep-duplicate で自動保存（変更不要） | 「Boss攻略/素材集め/図鑑調査」等の意図をプリセット単位で完結。保存配線の追加なし |
| P3-D098-4 | **UI＝プリセット行直下に「探索方針」セレクタ**（`EquipmentScene`・5項目）。選択即 `set_exploration_policy`、`apply`/`refresh` で同期。既定=なし（後方互換） | 既存プリセットUIと同列に集約。単体でも切替可・保存でプリセットに内包 |
| P3-D098-5 | **スコープ外**: 探索スキル(採取/採掘/鍵/解読/罠)・環境変化(雨/夜/霧/増水/落石)・方針による部屋構成変更・高速周回(戦闘スキップ)・方針別演出 | MVP最小化。探索システム拡張は後続 Decision |

## Biome 属性相性 MVP（2026-06-30 — P3-D099）

> ダンジョンごとに「地形で有利な属性」を持たせ、属性シナジー(D095)・図鑑・ダンジョン選択を噛み合わせる。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D099-1 | **データ＝`DungeonData.favored_element`（有利属性 id・空=補正なし）**。MVP は有利のみ（不利ペナルティ無し） | ダンジョンが理不尽にならない。後方互換（未設定=従来通り） |
| P3-D099-2 | **効果＝味方攻撃の attack_element が favored_element 一致で与ダメ ×1.15**（`BIOME_FAVORED_BONUS`）。弱点/特効/シナジーと乗算 | 「地形に合わせた属性編成」を選択肢に。倍率は控えめで明快 |
| P3-D099-3 | **配線＝D095 と同じ `_apply_enemy_mitigation` 属性段に1フック**（`_is_biome_favored`→`$DungeonController.current_dungeon_data.favored_element`）。ログに `[地形:◯]` | 既存の属性処理に相乗り＝散在回避。味方攻撃のみ |
| P3-D099-4 | **可視化＝ダンジョン選択に「地形相性: ◯ 有利」表示**（`DungeonSelectScene`・`ElementResolver.get_display_name`）。mourngate(王都地下)=dark を初期設定 | 編成前に地形が分かる。図鑑併記は後続 |
| P3-D099-5 | **スコープ外**: 不利属性ペナルティ・敵側の地形補正・環境変化(雨/夜/霧)・地形による部屋構成変更・複数属性地形・図鑑への地形表示 | MVP最小化 |
| P3-D099-6 | **整合修正（バランスパス）**: `thunder`/`lightning` の id 不整合で雷属性シナジーが恒久不発だったため、`CombatSynergy` で属性タグ集計時に `lightning→thunder` 正規化（`_ELEMENT_TAG_ALIAS`）し、シナジーキーを `ElementResolver` id（attack_element）に統一。コンボ(感電=require lightning)はタグ空間内で完結のため非影響。数値そのものは実機確認まで据置 | 雷シナジー/地形相性の発火を修正。バランス分析では乗算レンジ（与ダメ最大~4.0倍/被ダメ~0.76・暴走ループ無し）は許容と判定 |

## 属性武器の拡充 MVP（2026-06-30 — P3-D102）

> 属性シナジー(D095・同属性2本で発動)/地形相性(D099)を実用域にする。各属性1本のみでは「2人で同属性を揃える」が不可能だったため、各属性に2本目を追加。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D102-1 | **各属性に2本目を追加（+5本）**。武器種を1本目とずらして差別化: 炎=燻る炎牙(dual_blades/pierce) / 氷=氷霜の杖(staff/blunt) / 雷=雷鳴の大剣(greatsword/slash) / 闇=影喰みの短刃(dual_blades/pierce) / 聖=祝聖の大槌(greatsword/slash) | 「同属性でも戦い方が違う2本」で編成幅を確保。属性シナジー成立条件(2本)を満たせるように |
| P3-D102-2 | **新規アセット0**: アイコンは対応属性の既存 ICO_WPN を流用（`IconPaths`）、`fixed_skill_id` は既存同属性スキル流用（kindling/rime/static/hex、聖は slash_attack）。`element`/`tags` は `ElementResolver`/`CombatTags` id 準拠（雷は tag `lightning`＝D094 感電コンボ互換・D099-6 正規化で synergy も発火） | アート/スキル新規作成なしで即実用化。後でアート差替前提 |
| P3-D102-3 | **流通＝`DungeonController.WEAPON_POOL` に5本追加**（rarity 重みでドロップ）。`DataRegistry` は id→path 自動解決のため追加コード不要 | 既存ドロップ機構に相乗り。入手経路を確保 |
| P3-D102-4 | **スコープ外**: 専用アート・新規固有スキル・防具/装飾の属性拡充・属性武器の鍛冶/進化・gacha 排出調整 | MVP最小化。アート/スキル作り込みは後続 |

## 環境変化（天候）MVP（2026-06-30 — P3-D101）

> ダンジョン進入ごとに天候を抽選し、戦闘へ一時補正。属性武器(D102)/地形相性(D099)と噛み合わせ「天候を見て属性を選ぶ」判断を足す。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D101-1 | **天候＝run 開始時に1つ抽選・DG中不変**（`CombatWeather.roll()`→`GameState.current_weather`・揮発）。晴れ55% / 雨・夜・霧 各15% | 敵Lv(D081)/地形(D099)と同じ run 固定モデル。多くは晴れで過剰干渉を回避 |
| P3-D101-2 | **効果（属性 id は ElementResolver 準拠）**: 雨=雷+15%/炎−10%・夜=闇+15%/聖−10%・霧=与ダメ×0.95＋被ダメ×0.95（視界不良で双方手探り） | 属性天候は D102 の属性武器選択に意味を与える。霧は属性非依存の鈍化で差別化 |
| P3-D101-3 | **配線（既存中央フックに相乗り）**: 属性/全体与ダメ→`DungeonScene._apply_enemy_mitigation`（地形の隣・`CombatWeather.element_multiplier×outgoing_multiplier`・ログ `[天候:◯]`）。被ダメ→`CombatController.get_member_incoming_damage_multiplier`（`GameState.get_weather()` 参照） | D098/D099 と同じ相乗り方式。散在回避・味方攻撃/被弾の既存経路に統合 |
| P3-D101-4 | **可視化＝HUD 併記＋procedural オーバーレイ（新規アセット0）**。ダンジョン名に〔天候〕併記＋開始ナラティブ。`DungeonScene._setup_weather`: 夜=暗青 ColorRect / 霧=薄灰 ColorRect の alpha ドリフト(Tween) / 雨=`CPUParticles2D`（生成した 2×14 雨粒 ImageTexture・上端から落下）。全て MOUSE_FILTER_IGNORE・低 alpha で可読性維持 | アニメーション要望に対応しつつアセット追加ゼロ。CanvasLayer(layer3)で UI を阻害しない |
| P3-D101-5 | **スコープ外**: 増水/落石・フロアごとの天候変化・敵側への天候補正・天候別 VFX/BGM 作り込み・ダンジョン選択での事前表示（開始時抽選のため不可） | MVP最小化 |

## AIターゲット選択 — パーティ・フォーカス方針 MVP（2026-06-30 — P3-D100）

> D086 で保留した Target 層を、現行フォーカス撃破モデルを壊さない範囲で導入。各メンバー行動時に戦術 target ルールで生存敵から狙いを定める。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D100-1 | **target ルールを `CombatTactics` に追加**（front/lowest_hp/highest_hp/highest_atk）。割当: balanced/cautious=front・aggressive/survival/sweep=lowest_hp・boss_focus=highest_hp | 既存6戦術に狙い方の個性を付与。`highest_atk`/highest_hp は混成実装後に本領 |
| P3-D100-2 | **選択＝単一アクティブの付け替え**（`CombatController.set_focus_by_rule`）。生存敵からルールで1体選び active に設定。全員がそのフォーカスを攻撃 | 単一アクティブ維持＝既存の被ダメ/状態異常/コンボ/HPバー処理を一切変えずに狙い分けを実現 |
| P3-D100-3 | **配線＝`_do_member_turn` 冒頭で行動メンバーの戦術 target を適用**（`_apply_focus_target`）。発火条件: 群れ(生存2体以上)時のみ＋**アクティブ敵に状態異常が乗っている間は切替えない**（単一スロット "enemy" 状態の他個体への転移を防止） | 同種群れの focus-fire（lowest_hp で頭数を早く減らし被ダメ減）を安全に実現。DoT 整合を保護 |
| P3-D100-4 | **スコープ外（後続 大物）**: 混成エンカウント・敵別状態異常スロット・メンバー個別ターゲット（同時に別個体狙い）・Target条件9種全実装・狙いの可視化 | 同種群れ中心の現状では focus 方針で十分。基盤拡張は別 Decision |

## 防具の属性耐性 MVP（2026-06-30 — P3-D103・残ロードマップ フェーズA-1）

> 攻撃偏重だった属性システムを防御側へ拡張。防具が特定属性の敵攻撃を軽減し、天候(D101)/地形(D099)と対になる防御選択を生む。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D103-1 | **データ追加**: `ArmorData.resist_elements: Array[String]`（ElementResolver id）／`EnemyData.attack_element: String`（敵攻撃の属性・空=無属性）。旧 `base_resistance` は予約のまま非使用 | 攻撃側(敵 attack_element)↔防御側(防具 resist)のマッチングで属性防御を成立 |
| P3-D103-2 | **効果＝一致で被ダメ ×0.75**（`ARMOR_RESIST_MULTIPLIER`・ElementResolver の RESIST_MULTIPLIER と同値）。敵攻撃属性＝アクティブ敵の `attack_element`（群れは同種で共通） | 弱点/耐性と同じ −25% で体感を統一。単一倍率で明快 |
| P3-D103-3 | **配線＝`_calc_enemy_damage_to_member` に1フック**（incoming_mult の後）。`_member_resists_element`（装備防具 ArmorData の resist_elements を判定）。ログに `[耐性:◯]`（通常攻撃経路） | 既存の被ダメ中央計算に相乗り。散在回避・敵スキルダメージにも倍率は作用 |
| P3-D103-4 | **初期データ**: 防具 bone_armor=闇耐性 / leather_armor=氷耐性。敵 crystal_hedgehog=氷攻撃 / clock_moth=雷攻撃 / serdion(ボス)=闇攻撃。装備一覧に「耐性:◯」表示（`EquipmentScene._armor_resist_suffix`） | 既存2防具・6敵に最小付与で機能実証。プレイヤーが装備選択時に耐性を確認可能 |
| P3-D103-5 | **スコープ外**: 属性耐性の数値レアリティ/Affix・複数段階(半減/無効/吸収)・敵スキルごとの個別属性・耐性貫通・耐性の図鑑表示 | MVP最小化。耐性深掘りは後続 |

## Aggro / Threat 基盤 MVP（2026-06-30 — P3-D104・残ロードマップ フェーズA-2）

> 旧「簡易ヘイト」（ジョブ優先で vanguard→swordsman→ランダム）を本格 Threat 値システムへ置換。敵が誰を狙うかを動的にし、タンク/挑発・連携の土台を作る。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D104-1 | **Threat 値を party 各員に保持**（`CombatController.party_threat`）。戦闘開始時にジョブ基礎値で初期化（vanguard=4.0/swordsman=2.0/他=1.0）。敵は **最大 Threat のメンバー**を狙う（`pick_enemy_target_member_index` を threat 最大選択へ書換・助っ人除外は維持・同値は index 昇順） | 動的ターゲティングの基盤。タンクが自然に矢面へ。旧ジョブ優先は基礎重みとして吸収 |
| P3-D104-2 | **Threat 増加源**: 与ダメ ×0.10（`THREAT_DAMAGE_K`・通常/スキル/必殺の全ダメージ適用後）／被ダメ ×0.15（`THREAT_TAKEN_K`・敵通常/スキル被弾後）／**防御スロット＝挑発スパイク +40**（`apply_taunt`・`THREAT_TAUNT`） | アタッカーは殴るほど狙われ、タンクは殴られ・防御で能動的に Threat を稼ぐ。「防御＝挑発」で vanguard の役割を明確化 |
| P3-D104-3 | **減衰**: status tick ごとに基礎値へ向けて ×0.90（`decay_threat`・`THREAT_DECAY`）。挑発スパイクは時間で薄れ元のターゲットへ戻る | 「挑発→Threat最大→終了後元に戻る」を表現。CT/状態tickに相乗りで追加ループ無し |
| P3-D104-4 | **スコープ外**: 挑発専用スキル/遺物（王盾の欠片の挑発延長）・Threat の可視化(UI バー)・敵ごとの個別 Threat テーブル（現状は party 単一 Threat を全敵共有）・キャラ連携（挑発→連携斬り）・複数タンクの按分 | MVP最小化。連携(フェーズD-12)・遺物発火(D-11)で活用予定 |

## 4人編成化（A-3 前段）（2026-06-30 — P3-D105）

> 提案の陣形「2×2（前2・後2）」に合わせ、アクティブ編成を 3→4 人へ拡張。戦闘エンジンは既に4ユニット前提（スプライト/HPバー4枠・size 駆動ロジック）のため低コストで実現。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D105-1 | **`GameState.ACTIVE_PARTY_SIZE` 3→4**。ロスター選択・装備メンバー切替・戦闘表示は同定数/`party_members.size()`/`combatant_count()` 駆動のため自動追従。装備画面に `ButtonMember3` を追加（`for i in 3`→`ACTIVE_PARTY_SIZE`） | 既存スケーリングを活かし最小変更。スプライト/HPバーは .tscn に4枠既設 |
| P3-D105-2 | **助っ人衝突の解決（初版）**: 戦闘スロット上限 `COMBAT_SLOT_MAX=4`。当初 `_helper_active()`＝満員(4)なら event_helper を戦闘除外 | 5体目 UI 未整備時の描画破綻回避 |
| P3-D105-2r | **助っ人参加の再決定（2026-07-04 / P1-4）**: `_helper_active()`＝`event_helper != null` のみ。満編成でもイベント助っ人は戦闘参加。5体目＝`ChrSprite4`/`HpBarChr4`/`FORMATION_SLOT_POSITIONS[4]`/`PARTY_CARD_SLOT_COUNT=5`。`COMBAT_SLOT_MAX=4` はメイン編成上限として維持 | 実プレイ不具合（満員時助っ人不参加）解消。敵ターゲットから助っ人除外は従来通り |
| P3-D105-3 | **Threat(D104)/陣形(A-3)/状態UI/ターンオーダーは非改修**: いずれも size 駆動で4人へ自動対応 | 4人化と独立して機能。A-3 陣形を4人前提で載せられる |
| P3-D105-4 | **スコープ外/要追跡**: 4人化に伴うリバランス（アタッカー+1の火力過多・敵/群れ難度）・4人前提のレイアウト微調整（実機確認）・初期編成は roster 先頭4名 | 数値調整は実機後。まず機構を通す |

## 陣形（前列/後列）MVP（2026-06-30 — P3-D106・残ロードマップ フェーズA-3）

> 4人編成(D105)に前列/後列の概念を導入。A-2 Threat と直結し「タンク前・後衛保護」を機能させる。提案の 2×2（前2・後2）を 2列モデルで実現。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D106-1 | **行を `Adventurer.formation_row`（0=前列/1=後列）で保持**。GameState get/set＋プリセット（前衛/均衡=最後尾1人後列/後衛=後ろ2人後列）。SaveManager 直列化に追加 | tactics_id/relic_id と同じ per-member 保存パターン。プリセットで素早く配置 |
| P3-D106-2 | **効果**: 後列＝被ダメ ×0.85（`FORMATION_BACK_INCOMING`）＋ Threat 基礎 ×0.6（`FORMATION_BACK_THREAT`・狙われにくい）。前列＝等倍＋`war_banner`（王国軍旗）の与ダメ+10%を**前列限定**に整合 | A-2 Threat と連動し前衛が矢面・後衛が保護される。war_banner を提案「前列+10%」へ寄せる |
| P3-D106-3 | **配線（中央フック相乗り）**: 被ダメ→`get_member_incoming_damage_multiplier`×`formation_incoming_multiplier`／Threat→`_job_threat_base`×`formation_threat_multiplier`／war_banner→`_member_relic_effects` で後列時 outgoing 無効化 | 既存倍率/Threat/遺物計算に1フックずつ。散在回避 |
| P3-D106-4 | **UI＝スキルタブに陣形行**（`EquipmentScene`・選択メンバーの前列/後列トグル＋プリセット前衛/均衡/後衛ボタン） | 戦術/遺物セレクタと同列に集約。即時反映 |
| P3-D106-5 | **スコープ外（当時）**: 射程連動の近接ペナルティ・敵 AoE の列範囲・列ごとの被弾分散・散開/密集ボーナス・隊列の視覚表現 | MVP最小化。射程連動はフェーズC以降 |

## 陣形×射程 与ダメ補正（2026-07-01 — P3-D106b・B-1）

| # | 決定 | 根拠 |
|---|---|---|
| P3-D106b-1 | **倍率**: 後列+melee=×0.85／前列+long/global=×0.85／後列+mid=×0.92 | 近接は前列・遠隔は後列が理想 |
| P3-D106b-2 | **SSOT=`CombatRange`**: スキル range_type 優先 → 装備メタ | 二重定義回避 |
| P3-D106b-3 | **配線**: `get_member_outgoing_damage_multiplier(member, action_range)` | 回復/バフは未指定 |

## 陣形×敵 AoE 列範囲（2026-07-01 — P3-D106c・B-2）

| # | 決定 | 根拠 |
|---|---|---|
| P3-D106c-1 | **target_type**: party / all_party / party_front / party_back | 既存 all_party 維持 |
| P3-D106c-2 | **SSOT=`CombatFormation.resolve_enemy_party_targets`** | formation_row 連動 |
| P3-D106c-5 | **キャリア**: クロックモスに `enemy_sweep_front`（前列 AoE） | 実戦検証 |

## 陣形×列内被弾分散（2026-07-01 — P3-D106d・B-3）

| # | 決定 | 根拠 |
|---|---|---|
| P3-D106d-1 | **列スキル**: Threat 比率で与ダメ按分・`[分散]` | タンクが多く引き受ける |
| P3-D106d-2 | **列空→反対列フォールバック** | 空振り緩和 |
| P3-D106d-3 | **近接通常攻撃**: 前列 Threat 最大優先（attack_range≤2.5） | 後衛保護 |

## 陣形×散開/密集（2026-07-01 — P3-D106e・B-4）

> 同列（前列 or 後列）の**生存人数**で被ダメ倍率を変える。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D106e-1 | **密集**（同列2人以上）: 被ダメ ×1.08（`DENSE_ROW_INCOMING`） | 2-2 編成は両列密集。列攻撃リスク |
| P3-D106e-2 | **散開**（同列1人のみ）: 被ダメ ×0.94（`SPREAD_ROW_INCOMING`） | 1前3後 等の孤立メンバーが軽減 |
| P3-D106e-3 | **配線**: `get_member_incoming_damage_multiplier`×`CombatFormation.density_incoming_multiplier` | 後列軽減・guard と併用 |
| P3-D106e-4 | **ログ**: `[密集]` / `[散開]`（`get_density_log_tag`） | Alpha 可視化 |
| P3-D106e-5 | **スコープ外**: formation_slot 座標距離・与ダメ側・UI プレビュー | 行人数のみ |

## 本格射程（武器 attack_range 接続）（2026-07-01 — P3-D106f・B-5）

| # | 決定 | 根拠 |
|---|---|---|
| P3-D106f-1 | **数値→カテゴリ**: ≤1.5=melee／≤2.5=mid／それ以上=long。`CombatRange.attack_range_to_category` が SSOT | Combat Vision 理想距離の Alpha 代理。P3-D108 の bow/staff ヒューリスティックを置換 |
| P3-D106f-2 | **武器射程**: `WeaponInstance.attack_range` 優先 → なければ `WeaponData.base_attack_range`。`resolve_member_default` の最優先 | 07_武器_装備・26_CombatVision の未接続フィールドを戦闘へ配線 |
| P3-D106f-3 | **スキル**: `resolve_for_action` は `SkillData.range_type` 優先（B-1 維持）。武器なし時のみ装備スキルメタ fallback | 行動単位とメンバー既定を分離 |
| P3-D106f-4 | **敵近接判定**: `CombatController.MELEE_ATTACK_RANGE_MAX` = `CombatRange.MID_RANGE_MAX`（2.5） | B-3 前列優先ターゲットと閾値統一 |
| P3-D106f-5 | **データ整合**: 杖 `base_attack_range=2.5`（`glacier_staff` 修正）。弓=3.0・剣系≈1.0 は既存維持 | 中距離カテゴリを杖で実戦投入 |
| P3-D106f-6 | **スコープ外**: リアルタイム位置 AI・隊列移動・射程 UI 表示 | Combat Vision 本格は後続 |

## 陣形 B レーン Closeout（2026-07-01 — P3-D125）

> Combat Vision 陣形サブレーン B-1〜B-5（P3-D106b〜f）の完了宣言。コードはコミット済（`aa1b187` / `1081d97`）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D125-1 | **完了宣言**: 陣形 B レーン **5/5 完了** — B-1 射程×与ダメ／B-2 敵 AoE 列／B-3 Threat 按分・近接前列／B-4 散開密集／B-5 本格射程（`WeaponData.base_attack_range`） | P3-D106 スコープ外だった射程連動を消化 |
| P3-D125-2 | **SSOT 整理**: 射程カテゴリ=`CombatRange`・陣形効果=`CombatFormation`+`GameState.formation_*`・戦術距離=`CombatTactics.self_range` | CODEMAP / DungeonScene 配線と一致 |
| P3-D125-3 | **残 Defer**: 位置 AI・理想距離移動・射程 HUD・列座標距離の与ダメ | Combat Vision 本格は Backlog |
| P3-D125-4 | **実機**: headless import 済。体感は P3-ALPHA-003 | オーナー帰宅後 |

## 戦術プリセット微調整（2026-07-01 — P3-D126）

> B-5 本格射程（mid カテゴリ実用化）後のプリセット追随。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D126-1 | **`cautious` プリセット**: `self_range` 条件値 `long`→`mid` | 杖2.5・中距離スキルが「遠隔のみ優先」にならないよう調整。後列+mid 与ダメ補正（B-1）と整合 |

## 状態異常拡充 MVP（2026-06-30 — P3-D107・残ロードマップ フェーズB-4）

> 攻撃偏重だった状態異常を Control / Debuff 方向へ拡充。敵単一スロット制約（D082）は維持し、既存中央フックに相乗りで配線。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D107-1 | **追加3状態（敵付与・tres 駆動）**: 恐怖 fear＝`skip_action_chance=0.5`/2tick（スタンの弱版・確率行動失敗）／脆弱 vulnerable＝`incoming_damage_multiplier=1.25`/3tick（属性問わず被ダメ増・shock 1.15 より強い専用枠）／防御DOWN armor_break＝`defense_reduction=0.5`/3tick（敵 DEF を半減） | Control[恐怖]＋Debuff[脆弱/防御DOWN]を最小数で実装。既存 status tres パターン踏襲（戦闘ルール表ではないため tres 増設は方針内） |
| P3-D107-2 | **防御DOWN は新フィールド `StatusEffectData.defense_reduction`（0..1・既定0・後方互換）で別作用点**。`_apply_enemy_defense` の DEF 逓減前に実効 DEF を `×(1−reduction)` で下げる（脆弱＝最終被ダメ乗算とは作用点が異なり重複回避）。集約は乗算合成・上限0.95（`StatusResolver.get_defense_reduction`→`CombatController.get_enemy_defense_reduction`） | 脆弱と防御DOWN を機構レベルで差別化。マーキングは作用が重複し体感差が薄いため MVP から除外（フェーズC-8 個別ターゲット＋連携で「マーク＝集中」として本領化） |
| P3-D107-3 | **延長は既存挙動を流用**（同状態の再付与で `remaining_ticks` をリセット＝`StatusResolver.apply_status`）。専用「延長」機構（`extend_status`）は導入せず、フェーズB-6 のバフ→必殺コンボと併せて後続 | MVP最小化。再付与リセットで「撒き続けて維持」は既に成立 |
| P3-D107-4 | **キャリア＝既存スキル流用**（新スキル tres 増設なし）。SkillData に副次状態付与 `apply_status_id2`/`apply_status_chance2`（既定空・`_apply_skill_status` とは独立判定で `_execute_member_skill` から `_apply_skill_secondary_status` を呼ぶ）を追加。配分: guard_strike(vanguard)＋恐怖0.4（主スタンと併存）／hex_bolt(alchemist)＋脆弱0.45（主呪いと併存）／aimed_shot(ranger)＝防御DOWN0.45（空スロットへ主付与） | 既存3スキルの識別性（stun/curse）を温存しつつ新デバフを実戦投入。副次フィールドは加算的で他スキル非回帰 |
| P3-D107-5 | **可視化**: 頭上バッジに 恐(`fear`)/脆(`vulnerable`)/破(`armor_break`) を追加（`STATUS_ICON_DEF`）。防御DOWN 発火時は与ダメログに `[防御DOWN]` タグ | 既存バッジ/タグ機構に相乗り |
| P3-D107-6 | **スコープ外**: マーキング・延長専用機構・敵別状態スロット（単一スロット維持）・状態の図鑑表示・耐性貫通・敵→味方への新デバフ付与 | MVP最小化。混成/個別ターゲットはフェーズC |

## Condition 拡充 MVP（2026-06-30 — P3-D108・残ロードマップ フェーズB-5）

> P3-D086 の戦術発動条件を拡張。D107 の状態異常（出血/毒）と CT/装備射程を戦術 AI の判断材料にする。依存＝フェーズB-4 完了後。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D108-1 | **追加4条件（`CombatTactics.condition_met`）**: `enemy_has_bleed`＝アクティブ敵に出血スタック>0／`enemy_has_poison`＝毒スタック>0／`ultimate_ready`＝必殺技が CT/CD 待ちなし（`SkillExecutor.can_cast`・CT準備完了の実装定義）／`self_range`＋value `melee`\|`long`＝装備スキルの `range_type`/`ranged` タグ→武器種(bow/staff)→既定 melee | 提案の出血中/毒中/CT準備完了/距離を最小 id で実装。既存6条件と同じ rule 辞書形式 |
| P3-D108-2 | **コンテキスト供給＝`_build_tactics_context` に4キー追加**（`DungeonScene`）。敵状態は `CombatController.get_enemy_status_stacks`、必殺準備は `_is_member_ultimate_ready`、距離は `_member_combat_range` | 散在回避。`_do_member_turn` の評価経路は不変 |
| P3-D108-3 | **距離の MVP 定義**: 射程システム(D106 スコープ外)未実装のため、**装備メタで近接/遠隔を判定**（long/global range_type・ranged タグ・bow/staff 武器種）。列・敵距離・AoE 範囲は後続 | 機構を先に通し、本格射程連動は陣形フェーズ以降で置換可能 |
| P3-D108-4 | **戦術プリセット最小調整**: balanced/aggressive/survival の必殺＝`ultimate_ready`（CD中はスキップして下位スロットへ）／aggressive＝出血時にスキル優先／cautious＝遠隔(`self_range` long)時にスキル優先／sweep＝毒時にスキル優先。boss_focus は敵種条件維持 | 新条件の実戦投入。大規模プリセット組替えは実機後 |
| P3-D108-5 | **スコープ外**: 複合条件(AND)・敵→味方の距離・列連動ペナルティ・Condition UI 一覧・パッシブ側条件拡張・CT 残量% 閾値 | MVP最小化。複合条件は需要次第で後続 |

## シナジータグ残＋コンボ追加 MVP（2026-06-30 — P3-D109・残ロードマップ フェーズB-6）

> D094 のタグ SSOT を効果系で完成させ、D089 のコンボに「味方バフ→必殺」を追加。依存＝フェーズB-4/5 完了後。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D109-1 | **タグ SSOT 拡張**: `CombatTags` に `shield`(防御)・`heal`(回復) を追加（`buff`/`debuff` は既存）。和名表示は `display_name` に集約 | 提案の Shield/Heal/Buff タグ空間を完成。未知 id 無視の既存規約を維持 |
| P3-D109-2 | **既存スキルへタグ付与（新規 tres 0）**: empower→`buff`／mend→`heal`／guard_strike→`shield`／hex_bolt→`debuff`（snare_shot は既存 debuff 維持） | 装備スキルタブのタグ表示とコンボ起爆条件に即投入。アセット増設なし |
| P3-D109-3 | **味方バフコンボ＝`CombatCombos._ALLY_RULES`**: 鼓舞 empower ＋ 攻撃側タグ `ultimate` →「鼓舞必殺」追加ダメージ（`hit_fraction=0.35`）＋ empower 消費。1ヒット1コンボ＝**敵側コンボ優先**、不成立時のみ味方側評価（D089 非回帰） | バフ→必殺の gameplay ループ（鼓舞→渾身の一撃）。敵状態コンボと同じ bonus 式を流用 |
| P3-D109-4 | **配線**: `CombatController.get_member_status_stacks`/`consume_member_status` 追加。`DungeonScene._consume_combo_bonus` が敵→味方の順で評価。必殺経路（`slot_type=ultimate`・`_execute_member_skill`）のみ味方コンボ対象 | 通常攻撃/非必殺スキルは味方コンボ不発。散在回避・中央フック維持 |
| P3-D109-5 | **スコープ外**: 効果タグの party シナジー(D095 物理/属性と同型)・shield/heal 単体コンボ・延長専用機構・コンボ図鑑表示・複数味方バフの連鎖 | MVP最小化。効果タグシナジーは実機後 |

## 混成エンカウント＋敵別状態異常スロット MVP（2026-06-30 — P3-D110・残ロードマップ フェーズC-7）

> D082 の同種群れ＋単一 `"enemy"` 状態スロットを拡張。D100 のフォーカス撃破は維持しつつ、異種混成と個体別デバフを可能にする。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D110-1 | **混成エンカウント**: COMBAT で既存 `SWARM_CHANCE` により複数体化した際、**追加枠を別種にする確率 `MIXED_SWARM_CHANCE=0.50`**。候補＝ダンジョン `enemy_pool` 内の `can_swarm` 敵（MVP＝セピアハウンド/冠喰いネズミ）。先頭は従来抽選・ELITE/BOSS は単体維持 | D082 非破壊拡張。同種群れも残し混成は50%で差別化 |
| P3-D110-2 | **敵別状態スロット**: StatusResolver ユニット id を **`enemy_<slot>`**（CT の `enemy_<slot>` と整合）に変更。`tick`/`skip`/`incoming`/`outgoing`/`defense_reduction`/コンボはアクティブ敵＝`active_enemy_index` 経由。撃破時は当該スロットのみ `clear_enemy_slot_status`、繰り上げではクリアしない | 毒A＋出血B を同時維持。フォーカス切替で状態が転移しない（D100 の非切替ガードを撤去） |
| P3-D110-3 | **配線**: `CombatController` に `enemy_status_unit_id`/`apply_status_to_active_enemy`/`get_enemy_status_*_at(slot)`/`apply_damage_to_enemy_slot` 等。`DungeonScene` の敵付与・DoT・バッジをスロット対応。頭上バッジは**生存敵スロットごと**（`_status_icon_swarm_rows`） | 散在回避。既存味方攻撃経路はアクティブ敵向けのまま |
| P3-D110-4 | **可視化/ログ**: 混成出現時 `【混成】名前 / 名前` ログ。同種は従来「群れ（N体）」 | 編成の見分け。UI は既存横並びスロット流用 |
| P3-D110-5 | **スコープ外**: メンバー個別ターゲット(C-8)・Target条件9種・マーキング集中・敵別状態の図鑑・混成テーブル拡張(3種以上固定編成)・非 can_swarm 敵の混成参加 | MVP最小化。個別ターゲットは C-8 依存 |

## メンバー個別ターゲット MVP（2026-07-01 — P3-D111・残ロードマップ フェーズC-8）

> D110 の敵別状態スロットを活かし、D100 のパーティ一括フォーカスを廃止。各メンバーが戦術 `target` ルールで個別に敵スロットを狙う。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D111-1 | **個別ターゲット**: `CombatController.member_target_slot[i]` を行動開始時 `resolve_member_target(i, CombatTactics.get_target_rule)` で決定。通常/スキル/必殺/状態付与/コンボ/Threat は `_deal_member_damage_to_enemy` / `_apply_status_to_member_target` 経由で当該スロットへ | 混成時に「毒の敵を掃討」「後列を狙う」等が同時成立。D110 個体別デバフの本領化 |
| P3-D111-2 | **D100 フォーカス撃破の置換**: `_apply_focus_target` 廃止。`_do_member_turn` 冒頭でメンバーごとに target 解決。`active_enemy_index` は敵スキル/UI/報酬レガシー用に維持（撃破時 `advance_active_enemy`） | 一括フォーカスと個別ターゲットの二重管理を解消 |
| P3-D111-3 | **Target ルール拡張**: `enemy_with_status`（状態付き敵のうち最低HP）/ `back`（生存敵の末尾スロット）。プリセット: cautious→back / sweep→enemy_with_status | D108 の bleed/poison 条件と連動。9種全実装は後続 |
| P3-D111-4 | **撃破/DoT**: 非アクティブ敵撃破も `_on_enemy_slot_killed(slot)` で報酬・繰り上げ。DoT tick は従来どおりスロット別（D110） | 分散攻撃でも撃破処理が漏れない |
| P3-D111-5 | **可視化**: 群れ2体以上時、味方攻撃ログに `→敵名`（`_member_target_tag`）。コンボ VFX もメンバー target スロット位置 | 誰が誰を殴ったか判別可能 |
| P3-D111-6 | **スコープ外**: Target 条件9種全実装・マーキング集中・狙い UI ハイライト・敵→味方への新デバフ付与拡張 | MVP最小化。マーキングは個別ターゲット＋連携で後続 |

## 詠唱＋Action Lock MVP（2026-07-01 — P3-D112・残ロードマップ フェーズD-9）

> 高威力/魔法スキルにテンポ差を付与。詠唱中は Action Lock（戦術再評価なし・別行動不可）で CT の「自分番」を消費する。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D112-1 | **`SkillData.cast_time`（float・既定0）**: 0=即時。>0 は `ceil(cast_time)` 回の自分番を詠唱専用に消費し、完了後に効果発動＋CD消費（`SkillExecutor` は発動時のみ） | 詠唱と CD を分離。既存即時スキルは非回帰 |
| P3-D112-2 | **Action Lock**: `CombatController._pending_casts`（key=`party_i`/`enemy_slot`）で保持。詠唱中の `_do_member_turn`/`_do_enemy_turn` は戦術/スキル抽選をスキップし `_advance_*_cast` のみ | オート戦闘でも「唱えている間は別手を出さない」テンポ |
| P3-D112-3 | **ターゲット凍結**: 味方ダメージ系は詠唱開始時の `member_target_slot` を保存し、発動時に復元（D111 個別ターゲット整合） | 詠唱中にフォーカスが変わっても狙いがブレない |
| P3-D112-4 | **中断**: 味方死亡・敵撃破で当該ユニットの pending cast をクリア。敵の行動阻害（stun/fear）は詠唱進行を**停止**（その番は消費するが進まない） | MVP最小。プレイヤー側 fear 未配線のため味方は現状中断なし |
| P3-D112-5 | **キャリア（既存 tres 流用）**: cast_time=1.0 → `ultimate_strike`/`hex_bolt`/`mend`/`boss_decree_wave`。即時維持=通常攻撃・guard_strike・empower・aimed_shot・boss_enrage | 魔法/必殺/回復/ボスAoE にテンポ差。新 tres 増設なし |
| P3-D112-6 | **可視化**: ログ `[詠唱]` / 敵 `詠唱している`、頭上ラベル紫系 `◆スキル名` | 実機で唱えていることが分かる最小演出 |
| P3-D112-7 | **スコープ外**: 詠唱中の被ダメ増・キャンセル専用スキル・詠唱バーUI・味方 fear 中断・チャネリング（複数tick継続）・スキル予約(D-10) | MVP最小化。予約/ローテはフェーズD-10 |

## スキル予約＋ローテーション MVP（2026-07-01 — P3-D113・残ロードマップ フェーズD-10）

> 装備スキル①②の使い分けを深める。ローテで交互使用、温存で状況まで保留。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D113-1 | **ローテーション**: `CombatController.member_skill_rot_idx` を戦闘中保持。スキルスロット発動時、装備順を `rot` 起点で巡回し**最初に温存OKかつCD/詠唱OKの1つ**を撃つ。成功時 `rot=(used+1)%n` | ①②を毎回先頭固定で連打しない。タンク「挑発→防御→強撃」型の最小表現 |
| P3-D113-2 | **温存（予約）**: `SkillData.reserve_condition`/`reserve_value`（空=常時可）。`CombatTactics.skill_reserve_met` が既存 condition と同型評価。新条件 `ally_injured`＝最負傷者が存在 | 提案の「HP低下まで温存」「Eliteまで保持」をデータ駆動で表現 |
| P3-D113-3 | **キャリア**: mend→`ally_injured`（全快時は温存・攻撃へ）／hex_bolt→`enemy_is_elite`（通常戦はローテで他スキル/攻撃） | 新 tres 0・既存スキルにメタ付与 |
| P3-D113-4 | **非対象**: 必殺/防御/通常攻撃スロット（戦術 plan の condition で既に制御）。温存中はスキップしてローテ次候補を試す | 二重管理回避。必殺温存は boss_focus 等の plan 維持 |
| P3-D113-5 | **スコープ外**: プレイヤーUIでの温存編集・スキル別優先度テーブル・ボス部屋までのラン跨ぎ温存・3スキル以上の明示ローテ列・敵側ローテ | MVP最小化。編集UIは装備/戦術タブ拡張で後続 |

## 遺物発火型＋種類拡充 MVP（2026-07-01 — P3-D114・残ロードマップ フェーズD-11）

> P3-D090-6 でスコープ外だった発火型遺物を解禁。Passives と同型の Trigger→Condition→Effect→Cooldown。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D114-1 | **発火型定義**: `CombatRelics._DEFS` に `trigger`/`condition`/`effect`/`cooldown` 等を追加。`has_trigger`/`trigger_def` API。常時倍率は既存 `effects_for` 維持 | tres 非増設方針継続。Passives と評価パターン統一 |
| P3-D114-2 | **配線**: `DungeonScene._relic_cd`+`_relic_attack_hits`+`_fire_member_relic_triggers`/`_try_fire_relic_trigger`。フック=与ダメ後(`on_attack`・every_n)/被弾(`on_hit_taken`)/味方死亡(`on_ally_death`) | パッシブCD tick と同ループ。ログ `[遺物]`・頭上 `◈` |
| P3-D114-3 | **新遺物4種**: 狩人の印(4回与ダメ毎追撃30%)・反応の盾片(HP50%未満被弾で防御・CD8)・弔鐘の指輪(味方戦闘不能で鼓舞)・斥候の片眼(速度+5%/与ダメ+5%常時) | 既存4種維持。ドロッププールは `all_ids()` 自動追従 |
| P3-D114-4 | **スコープ外**: 王盾の欠片の挑発延長(P3-D104-4)・前列/HP条件の常時倍率切替・戦闘開始発火・プレイヤー向け発火UI・遺物アイコン | MVP最小化。連携(D-12)・Threat可視化は後続 |

## パーティシナジー連鎖＋キャラ連携 MVP（2026-07-01 — P3-D115・残ロードマップ フェーズD-12）

> P3-D104-4 で後送りした「挑発→連携斬り」等を実装。CombatCombos（状態消費）とは別枠のパーティ連携。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D115-1 | **`CombatLinks`（静的SSOT）**: 3連鎖＝挑発連携(taunt_link・防御スロット後・他員与ダメ+25%・最大3回)／デバフ追撃(debuff_mark・味方がデバフ付与→他員追撃+20%・1回)／治癒連携(heal_rally・回復対象の次攻撃+15%・1回) | Aggro/Threat 土台(D104)を活かす最小セット。数値は hit_fraction でコンボと同型 |
| P3-D115-2 | **配線**: `DungeonScene` に `_taunt_link_*`/`_debuff_marks`/`_heal_rally_member`。フック=防御(`apply_taunt`後)／敵デバフ付与成功(`_apply_status_to_member_target`)／回復スキル成功。ボーナス=`_consume_link_bonus` を `_consume_combo_bonus` 末尾で加算（**コンボと併用可**・link は1ヒット1種） | 既存ダメージ経路を1箇所拡張。撃破で mark クリア |
| P3-D115-3 | **可視化**: ログ `[連携]`・水色ダメージポップ・装備タブ情報行に `CombatLinks.hint_lines()` | 編成画面でルール可読化 |
| P3-D115-4 | **スコープ外**: ジョブ別専用連携・Threat 閾値連動・マーキング専用状態・連携図鑑・3段以上の連鎖・敵側連携 | MVP最小化。マーキング本格化は実機後 |

## ボスフェーズ移行 MVP（2026-07-01 — P3-D116・残ロードマップ フェーズE-13）

> HP 閾値でボス形態が変化し、スキル率・攻撃力が段階的に上昇。図鑑は目撃したフェーズのみ開示。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D116-1 | **`CombatBossPhases`（静的SSOT）**: 敵 id ごとにフェーズ配列（`threshold`/`label`/`skill_use_chance`/`attack_mult`/`log`/`skill_weight`）。MVP＝`serdion` 3段（100%/50%/25%） | tres 非増設。D079 スキル（激昂/断罪）をフェーズで差別化 |
| P3-D116-2 | **戦闘状態**: `CombatController.enemy_phase_index[]`＋`get/set_enemy_phase_index`/`get_enemy_hp_ratio_at`。与ダメ後＋DoT後に `_check_boss_phase_transition` | 群れスロット対応。上昇時のみ移行（降格なし） |
| P3-D116-3 | **効果**: フェーズで `skill_use_chance`/`attack_mult` 上書き。第3形態は `boss_decree_wave` 重み2倍。移行ログ＋ボス演出 | 挑発→激昂→断罪のテンポ。Threat 土台は既存維持 |
| P3-D116-4 | **図鑑接続**: `GameState.mark_boss_phase_seen`/`phases_seen` セーブ永続。Codex stage5 で目撃フェーズのみラベル開示（未目撃＝？？？） | P3-D092 戦闘データ拡張。討伐回数と独立の「目撃」進行 |
| P3-D116-5 | **スコープ外**: フェーズ別見た目差分・アニメ専用形態・複数ボス同時フェーズ・フェーズ限定スキル追加 tres・敵 AI 行動パターン全面変更 | MVP最小化。他ボスはデータ追加のみで拡張可 |

## 探索スキル群 MVP（2026-07-01 — P3-D117・残ロードマップ フェーズE-14）

> P3-D098-5 で後送りした探索スキル5種をロール連動の自動発動として実装。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D117-1 | **`ExplorationSkills`（静的SSOT）**: 5種＝採取(scout/support・EVENT)/採掘(scout/dps・TREASURE +12G)/鍵開け(scout/dps・TREASURE 装飾品再抽選35%)/解読(support/scout・lore EVENT +20G)/罠解除(scout/tank・COMBAT/ELITE) | 編成ロールで「誰が何をするか」を表現。新 tres 0 |
| P3-D117-2 | **配線**: 宝箱/イベント/戦闘開始に `_apply_exploration_*` / `_try_exploration_trap`。罠=20%で8ダメ（解除ロールで無効化） | 既存部屋フローに相乗り。全自動探索と整合 |
| P3-D117-3 | **効果**: 採取=material+1 or 40%で遺跡欠片 / 採掘・解読=gold加算 / 鍵=accessory再抽選 | 探索方針(material)の `_apply_material_bonus` と相乗り |
| P3-D117-4 | **可視化**: ログ `[探索]`・装備タブ `ExplorationSkills.active_labels` | 編成画面で使えるスキル可読化 |
| P3-D117-5 | **スコープ外**: プレイヤー手動発動・探索スキルCD・部屋構成変更・専用探索部屋・スキル習得/成長・罠の種類拡充 | MVP最小化。高速周回(E-15)は後続 |

## 高速周回・戦闘スキップ MVP（2026-07-01 — P3-D118・残ロードマップ フェーズE-15）

> クリア済みダンジョンの周回 QoL。通常戦闘のみ即時撃破し、報酬は通常撃破と同型。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D118-1 | **`CombatFastRun`（静的SSOT）**: 解禁＝`GameState.is_dungeon_cleared`／スキップ対象＝`RoomType.COMBAT` のみ（ELITE/BOSS/混成は実戦） | 初回クリアは体験維持。周回は雑魚戦のみ短縮 |
| P3-D118-2 | **UI**: ヘッダーにトグル「周回」（クリア前は disabled）。ON 時は x2 速度も自動適用 | 既存 x1/x2 と併存。新シーン編集最小（コード生成ボタン） |
| P3-D118-3 | **配線**: 戦闘開始後 `_try_combat_skip` → `_execute_combat_skip` で全敵即撃破・`_award_enemy_kill_at` 経由で報酬/ドロップ通常通り | CombatTimer 非起動。既存撃破・累計報酬フロー再利用 |
| P3-D118-4 | **ログ**: `[周回] 戦闘をスキップ` | スキップ発動の可視化 |
| P3-D118-5 | **スコープ外**: 戦闘結果の確率シミュレーション（敗北/被ダメ）・ELITE スキップ・報酬ペナルティ・セーブ永続トグル・ダンジョン選択画面からの既定ON | MVP最小化。**Combat System v1.0 残ロードマップ 全15項目完了** |

## Combat System v1.0 Closeout（2026-07-01 — P3-D119）

> P3-D103〜118（残ロードマップ 15 項目）完了をマイルストーンとして Closeout。コード変更なし（ProjectDocs 同期のみ）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D119-1 | **完了宣言**: Combat System v1.0 残ロードマップ **15/15 完了**（P3-D103〜118） | 2026-06-30 オーナー承認順序の全消化 |
| P3-D119-2 | **`CODEMAP.md` 同期**: `scripts/combat/` 16 モジュール・状態14種・DungeonScene 戦闘配線・EquipmentScene 探索/連携表示を反映 | 実装の正を現行コードへ |
| P3-D119-3 | **次焦点**: Phase 3-A Visual Production（本番 UI/ドット絵）＋ **P3-D103〜118 実機一括確認**（`AlphaPlaytest_Checklist.md`） | headless のみ検証済。未コミット塊はオーナー判断で分割コミット |
| P3-D119-4 | **Defer 集約**（各 Task スコープ外）: 敵別 Threat テーブル・探索手動/CD・ELITE スキップ・敗北シミュ・`CombatWeather` 本格・複数 DG 本格化。※本格射程/AoE＝P3-D106f 完了・**マーキング＝P3-D120 完了** | Backlog 候補。単独 Decision まで実装しない |

## マーキング状態 MVP（2026-07-01 — P3-D120）

> P3-D119 Defer「マーキング」を Alpha 必要項目として最小実装。A3 Closeout。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D120-1 | **状態 `mark`（標的）**: 被ダメ×1.15・3tick・max_stacks=1。`resources/status/mark.tres` | P3-D107 で除外したマーキングを個別ターゲット(D111)+連携(D115)土台の上で復活 |
| P3-D120-2 | **付与経路**: `aimed_shot` の `apply_status_id2=mark` / `chance2=0.4`（主=armor_break 維持） | レンジャー/ビーストテイマーの狩猟弓既定スキルで自然に発火 |
| P3-D120-3 | **ターゲット/条件**: `enemy_marked`（mark 付き敵を HP 低優先）・`enemy_has_mark`（戦術発動条件） | `CombatController`/`CombatTactics`/`DungeonScene` ctx 配線 |
| P3-D120-4 | **プリセット**: `sweep`→`target: enemy_marked`＋`enemy_has_mark`スキル優先／`aggressive`→`enemy_has_mark`スキル優先（出血の前） | 集火の体感を戦術プリセットで明示 |
| P3-D120-5 | **連携**: `CombatLinks.DEBUFF_MARK_STATUSES` 先頭に `mark` | 標的付与→他員追撃+20%（debuff_mark）と整合 |
| P3-D120-6 | **スコープ外**: マーク専用 UI ハイライト・複数マーク種・敵→味方マーク・図鑑追記 | MVP最小化。実機確認は P3-ALPHA-003 |

## 作戦プリセット装備セット（2026-07-01 — P3-D121）

> P3-D091 スコープ外だった装備セット保存を E1 として追加。準備専用ループの一括切替を完結。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D121-1 | **保存キー追加**＝`settings[member_id]` に `weapon_instance_id` / `armor_instance_id` / `accessory_instance_id`（空=未装備） | P3-D091 の member_id キー設計を維持。後方互換＝キー無しは装備を触らない |
| P3-D121-2 | **適用**＝`find_*_instance` で解決→`clear_item_from_other_members`→装備。同一 `apply` 内で既に他員へ割当済みの instance はスキップ | 競合時に後勝ちで奪わない。インベントリ欠落もスキップ（現装備維持） |
| P3-D121-3 | **API**＝`save/apply_combat_preset` 拡張のみ。`SaveManager` は `combat_presets` deep-duplicate で自動追従 | 新フィールド追加のみ |
| P3-D121-4 | **UI**＝`EquipmentScene` プリセット行にサマリー（装備数・探索方針）。適用後 `_refresh_display`＋`save_game` | 装備タブ全体を再描画 |
| P3-D121-5 | **スコープ外**: プリセット名リネーム UI・装備競合トースト・スキル装備セット・陣形行 | MVP最小化 |

## 4人編成リバランス（2026-07-01 — P3-BAL-003 / G1）

> P3-D105-4 で Defer した「4人化に伴う数値調整」。敵 .tres は個別改変せず中央補正。

| # | 決定 | 根拠 |
|---|---|---|
| P3-BAL-003-1 | **敵 HP/ATK を編成人数で補正**（`CombatController.start_combat_group`）。基準＝3人（`PARTY_BALANCE_BASE_SIZE`）。4人時 HP×≈1.28（share0.85）・ATK×≈1.13（share0.40） | 火力+1 と CT 上の行動回数増を相殺。フル線形(4/3)より控えめ＝シナジー過剰を避ける |
| P3-BAL-003-2 | **EXP/ゴールドは据置**（`exp_reward`/`gold_reward` は補正しない） | 4人化を進行ペナルティにしない |
| P3-BAL-003-3 | **群れ出現率** `SWARM_CHANCE` 0.20→0.24（安全優先方針の半減は維持） | 4人の群れ戦でターゲット分散が増え難度が下がりすぎるのを抑制 |
| P3-BAL-003-4 | **スコープ外**: 敵 .tres 個別改変・ボス専用フェーズ数値・UI レイアウト・助っ人5体目 | 実機後に微調整可。まず中央補正で一括 |

## カスタム戦術（ガンビット）MVP（2026-07-01 — P3-D122 / A1 Closeout）

> CombatGambit 骨格（A1前段）に UI・セーブ・作戦プリセット連動を追加。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D122-1 | **データ**＝`Adventurer.tactics_custom_enabled/target/plan`。OFF 時は従来 `tactics_id` プリセット | 後方互換。既存6プリセットを維持 |
| P3-D122-2 | **UI**＝装備画面「戦術」パネルにチェック＋標的＋5行（スロット/条件/値）＋「プリセットから複製」 | 新画面なし。ON 時はプリセット▼を無効化 |
| P3-D122-3 | **セーブ**＝`SaveManager` に `tactics_custom_*` 直列化。`combat_presets` も同キーを保存/適用 | E1 装備保存と同型 |
| P3-D122-4 | **戦闘**＝`CombatGambit.plan_from_member` / `target_from_member`（DungeonScene 既存配線） | コード変更はデータ/UI 中心 |
| P3-D122-5 | **スコープ外**: 行数可変・ドラッグ並替・条件プレビュー・ダンジョン中編集 | MVP最小化 |

## リタイア Result 差別化（2026-07-01 — P3-D123）

> 一時停止リタイアの帰還を完走 CLEAR と Result 上で区別する。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D123-1 | **`GameState.last_run_outcome`**＝`clear` / `retire` / `wipe`。DungeonScene の完走・リタイア・全滅で設定 | 単一フラグで Result 分岐。セーブ不要（ラン揮発） |
| P3-D123-2 | **Result ヘッダー**: 完走=`CLEAR`（金）／リタイア=`リタイア帰還`（青系）／全滅=`探索失敗`（赤系） | 視認性優先。タイトル「探索結果」は共通 |
| P3-D123-3 | **探索情報**に「帰還」行（完走 / リタイア（クリアなし） / 全滅） | クリア未達の明示 |
| P3-D123-4 | **リタイア時** `mark_dungeon_cleared` しない・token=0（既存維持） | 完走特典と分離 |

## 作戦プリセット名リネーム（2026-07-01 — P3-D124）

> P3-D091 スコープ外だったプリセット名変更 UI。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D124-1 | **`rename_combat_preset(slot,name)`** — 既存スロットの `name` のみ更新（settings 不変） | 中身を上書きせず名称だけ変えられる |
| P3-D124-2 | **UI**＝プリセット行直下に「名称」LineEdit＋「名前変更」。空スロットは変更不可・保存時に名称反映 | 初回保存で `save_combat_preset(slot, name)` に名称を渡す |
| P3-D124-3 | **制約**＝名称最大24文字・空白のみは不可 | 表示崩れ防止 |

## Alpha 実機一括確認（2026-07-01 — P3-ALPHA-003）

> Combat System v1.0 Closeout（P3-D119）後の実機検証。コード変更なし — チェックリスト更新のみ。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ALPHA-003-1 | **`AlphaPlaytest_Checklist.md` v2.0** — 対象をモーンゲート1本・フルオート・CT/ATB・戦闘v1.0（P3-D103〜118）に刷新 | v1.0 は白骸墓地/分岐/鑑定屋等が陳腐化 |
| P3-ALPHA-003-2 | **初回完走 8〜12 分 / 周回ON 3〜5 分** を目安。ステップ5で周回のみ別検証 | P3-D118 はクリア済み DG のみ解禁 |
| P3-ALPHA-003-3 | **GO 判定はオーナー実施後**に記録欄へ。P0なし・P1は P3-FIX-### 化 | HQ は文書発行まで。実機はオーナーレーン |
| P3-ALPHA-003-4 | **遺物・連携（3-H）は SKIP 可**（未装備時）。ボスフェーズ・探索は必須 | 装備依存機能の柔軟化 |

## ターゲット条件拡張（2026-07-01 — P3-D127 / A2）

> P3-D108/D120 の戦術条件・標的を P3-D107 状態群まで拡張。ガンビット UI は `CombatGambit.CONDITION_IDS` 追従で自動反映。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D127-1 | **発動条件4種追加**＝`enemy_has_stun` / `enemy_has_vulnerable` / `enemy_has_armor_break` / `enemy_has_fear`（いずれも生存敵のいずれかに該当状態） | bleed/poison/mark と同型。P3-D107 状態を戦術で使えるように |
| P3-D127-2 | **標的ルール追加**＝`enemy_with_debuff`（stun/fear/poison/bleed/vulnerable/armor_break/curse/chill/slow/mark 付き敵を HP 低優先） | `enemy_with_status`（任意状態）と差別化 |
| P3-D127-3 | **プリセット**: `cautious`→スタン時スキル優先／`sweep`→`enemy_with_debuff`＋`enemy_has_vulnerable` スキル優先 | デバフ集火の体感をプリセットで明示 |
| P3-D127-4 | **スコープ外**: 条件の敵スロット指定・状態種別の UI プレビュー・図鑑ヒント連動 | MVP最小化 |

## 図鑑調査実利報酬（2026-07-01 — P3-D128 / D2）

> P3-D098 の図鑑方針（撃破二重計上）に加え、未調査完了（stage<5）敵への実利ボーナスと P3-D067 ドロップ配線の欠落修正。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D128-1 | **P3-D067 配線復元**＝通常 COMBAT 撃破時に `_roll_ecology_material_drops` を実行（ELITE/BOSS は既存報酬プール維持で除外） | 関数は存在したが未呼び出しだった |
| P3-D128-2 | **図鑑方針×未完了敵**（stage<5）: EXP ×1.10・生態素材ドロップ率 ×1.50（上限1.0）・撃破ログに `[図鑑調査]` | 図鑑ランに経済/成長上の意味を付与。完了後は二重計上のみ |
| P3-D128-3 | **判定タイミング**＝`add_enemy_kill`（二重計上含む）の**前**に stage を評価 | 撃破その場でボーナス対象を確定 |
| P3-D128-4 | **スコープ外**: 図鑑専用ドロップテーブル・HE 解放・方針別部屋構成 | MVP最小化 |

## 探索方針効果ヒント（2026-07-01 — P3-D129）

> P3-D098 の探索方針 UI に、各方針のゲーム内効果を1行で表示。P3-D128 の図鑑ボーナスも明示。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D129-1 | **`GameState.exploration_policy_hint(policy)`** — safe/material/relic/codex/なし の効果要約を返す | 数値の SSOT は既存フック（D098/D128）。表示専用 |
| P3-D129-2 | **UI**＝`EquipmentScene` 探索方針セレクタ直下にヒント Label（12px・副色）。選択/プリセット適用で同期 | 準備画面で方針の意味が分かる |
| P3-D129-3 | **スコープ外**: ダンジョン中の方針表示・数値の動的プレビュー | MVP最小化 |

## Alpha チェックリスト追検（2026-07-01 — P3-ALPHA-004）

> P3-ALPHA-003 v2.0 に D120〜128 の実機確認項目を追加。コード変更なし（文書のみ）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ALPHA-004-1 | **`AlphaPlaytest_Checklist.md` v2.1** — ステップ1 DGサムネ / ステップ2 作戦・方針・ガンビット / ステップ3-K Alpha拡張 | 一括実機で新機能を取りこぼさない |
| P3-ALPHA-004-2 | **総合判定表**に「Alpha 拡張」行を追加 | GO/NO-GO 記録の粒度向上 |
| P3-ALPHA-004-3 | **次**＝オーナー実機（P3-ALPHA-003 本体） | HQ は文書発行まで |

## Alpha 実機確認 Closeout — headless 暫定（2026-07-01 — P3-ALPHA-003b）

> オーナーが帰宅後も実機プレイ不可のため、P3-ALPHA-003 の **実機 GO/NO-GO は Defer**。開発ブロックを解除する。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ALPHA-003b-1 | **実機一括確認を Defer**（記録欄は未記入のまま）。`AlphaPlaytest_Checklist.md` v2.1 は将来オーナー実施時の SSOT として維持 | オーナーレーン不可が継続。HQ/Impl は headless で継続 |
| P3-ALPHA-003b-2 | **暫定受理ゲート**＝`tools/smoke_test.sh`（import + 120f smoke）PASS。Task Closeout の「headless 検証済」で代替 | クラッシュ/パースエラーの回帰検知は維持 |
| P3-ALPHA-003b-3 | **既知リスク**: 戦闘体感・UI 視認性・テンポは未検証のまま。P1 発見時は実機可能になった時点で P3-FIX-### 化 | 品質リスクは明示して先送り |
| P3-ALPHA-003b-4 | **次焦点**＝Phase 3-A ポリッシュ / Backlog 小タスク（実装可能な範囲） | Alpha 戦術/探索拡張レーンは D120〜130 まで消化 |

## Result 探索方針表示（2026-07-01 — P3-D130）

> 帰還 Result に run 中の探索方針を記録表示。作戦プリセットサマリーも拡張。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D130-1 | **`last_run_exploration_policy`** — 完走/リタイア/全滅の Result 遷移直前に `snapshot_last_run_context()` で保存（ラン揮発） | D098/D128 の方針効果を帰還後に振り返れる |
| P3-D130-2 | **Result 情報行**に「探索方針」表示（空は非表示） | P3-D123 帰還種別と並列 |
| P3-D130-3 | **`get_combat_preset_summary`** にカスタム戦術ON人数（`カスタムN`）を追加 | P3-D122 のプリセット一覧可読性 |
| P3-D130-4 | **スコープ外**: ラン中獲得素材の Result 一覧 | インベントリ差分追跡は別 Task → **P3-D131 で実装** |

## Result 採取素材表示（2026-07-01 — P3-D131）

> P3-D130 スコープ外だったラン素材一覧を差分スナップショットで実装。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D131-1 | **`begin_run_material_tracking()`** — DG 開始時に `material_inventory` を複製。帰還時 `snapshot_last_run_context()` で差分を `last_run_material_gains` に保存 | 既存 `add_material` 経路を変更しない |
| P3-D131-2 | **Result 情報行**に採取素材を `名前 x数量` で列挙（0 件は非表示） | P3-D128 生態ドロップの帰還確認 |
| P3-D131-3 | **スコープ外**: 素材アイコン列・クラフト画面へのジャンプ | MVP最小化 |

## ダンジョン選択に探索方針表示（2026-07-01 — P3-D132）

> 出発前に現在の探索方針を確認できるよう DG カードに1行追加。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D132-1 | **`DungeonSelectScene`** の選択可能 DG カードに `探索方針: ◯◯`（方針なしは非表示） | P3-D129 ヒントは装備画面のみだったギャップを補完 |
| P3-D132-2 | **スコープ外**: 選択画面での方針変更 UI | 方針変更は装備画面（P3-D098）のまま |

## Result 天候表示（2026-07-01 — P3-D133）

> P3-D130 の探索方針表示に続き、run 固定の天候（P3-D101）も Result で振り返れるようにする。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D133-1 | **`last_run_weather`** — `snapshot_last_run_context()` で `current_weather` を保存（晴れ=空は非表示） | 探索方針と同型のラン揮発メタ |
| P3-D133-2 | **Result 情報行**に「天候」表示（`CombatWeather.label`） | DG 中 HUD と整合 |

## Alpha Combat Formation ブランチ Closeout（2026-07-01 — P3-ALPHA-005）

> `cursor/alpha-combat-formation-ui` に集約した D120〜133・リタイア/Result/ポリッシュ一式を `main` へ統合。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ALPHA-005-1 | **`main` へマージ** — Alpha 戦術/探索拡張レーン完了。実機 GO/NO-GO は P3-ALPHA-003b のとおり Defer 維持 | 長期フィーチャーブランチの統合。開発の正を main に戻す |
| P3-ALPHA-005-2 | **受理**＝`tools/smoke_test.sh` PASS | 実機代替ゲート |
| P3-ALPHA-005-3 | **次**＝Phase 3-A Visual（オーナー作画）/ Backlog（Decision 要） | コードレーンの Alpha 拡張は一区切り |

## 作戦プリセット装備競合トースト（2026-07-01 — P3-D134）

> P3-D121 スコープ外だった装備競合/未所持のサイレントスキップを、適用時に可視化する。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D134-1 | **`apply_combat_preset` 戻り値**＝`{ ok, skipped[] }`。各 skip＝`member_name` / `kind` / `reason`(missing\|conflict) | 戦術・遺物は従来通り適用。装備のみ報告 |
| P3-D134-2 | **UI**＝`EquipmentScene` 適用後、skip ありなら画面下部に3秒トースト（`装備スキップ: 名前・枠（理由）`） | 新シーン不要。Codex トーストと同型の軽量フィードバック |
| P3-D134-3 | **スコープ外**: 適用前プレビュー・自動解決（奪取順）・保存時の競合検知 | MVP最小化 |

## Result 採取素材アイコン行（2026-07-01 — P3-D135）

> P3-D131 スコープ外だった素材アイコン列を Result に追加。情報行のテキスト列挙はアイコン行へ移行。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D135-1 | **`MaterialPanel`** — `last_run_material_gains` を `RewardRow` と同型セル（`IconPaths` material / フォールバック字形）で横並び。0 件は非表示 | D131 差分スナップショットの可視化 |
| P3-D135-2 | **探索情報グリッド**から採取素材のテキスト行を削除（重複回避） | アイコン＋名称＋数量で十分 |
| P3-D135-3 | **スコープ外**: クラフト画面ジャンプ・素材詳細ツールチップ | MVP最小化 |

## 鍛冶屋復活 MVP（2026-07-01 — P3-D136）

> P3-D075 退避を逆操作。P3-D067/D128 で素材経済が回るようになったため、拠点からクラフト消費ループを再接続。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D136-1 | **`archive/blacksmith/` から本番パスへ復帰**（`scenes/blacksmith/` + `scripts/blacksmith/`）。`BaseScene` 左メニュー「赤鉄の工房」 | D075 逆・世界観（ガロ/赤鉄の工房） |
| P3-D136-2 | **全6レシピ有効**（武器3 / 防具2 / 装飾1）。生成ステは撃破ドロップ同型（ATK +0〜5 / DEF +0〜3 / Affix 自動付与） | P3-D067 済レシピをそのまま接続 |
| P3-D136-3 | **古き骨**＝`sepia_hound.codex_materials` に追加（商人削除 P3-D070 で入手不能だった骨鎧レシピを成立させる） | 最小差分で全レシピ成立 |
| P3-D136-4 | **不足時は「作成」ボタン無効**＋日本語ステータス | 旧UIのまま誤タップを抑制 |
| P3-D136-5 | **スコープ外**: UI本格化・NPC台詞・unlock条件・Result→鍛冶ジャンプ | MVP最小化 |

## ガンビット行並替（2026-07-01 — P3-D137）

> P3-D122 スコープ外だった優先度並替を装備画面に追加。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D137-1 | **各行に ↑↓ ボタン** — 隣接行と `tactics_custom_plan` をスワップ。先頭/末尾は片方無効 | ドラッグ並替より実装軽量。優先度調整の実用価値 |
| P3-D137-2 | **並替後即 `set_member_tactics_custom_plan`** — 作戦プリセット保存データと同型 | D122/E1 セーブ経路を変更しない |
| P3-D137-3 | **スコープ外**: 条件ライブプレビュー・行数可変・ダンジョン中編集 | MVP最小化 |

## 拠点素材可視化（2026-07-01 — P3-D138）

> D136 鍛冶復活後、拠点で素材が見えないギャップを TopBar で補う。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D138-1 | **`BaseScene` TopBar 左**に素材チップ — 所持>0 を数量降順、最大3種（アイコン+数量）+ `+N` オーバーフロー | 720幅でコンパクトに一覧性 |
| P3-D138-2 | **0 種は非表示**。ホバー/長押しツールチップに全素材 `名前 x数量` | 詳細はチップ外に逃がす |
| P3-D138-3 | **チップタップ → 赤鉄の工房** | 経済ループの導線短縮 |
| P3-D138-4 | **スコープ外**: 全素材インベントリ画面・装備画面への素材行 | MVP最小化 |

## 鍛冶屋軽 UX（2026-07-01 — P3-D139）

> P3-D136 最小 UI の可読性改善。D138 TopBar と同型の素材アイコン表示。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D139-1 | **所持素材**＝横スクロール行に `IconPaths` material チップ（名前 x数量） | D138 と視覚統一 |
| P3-D139-2 | **レシピ行**＝出力装備アイコン + 素材チップ（`所持/必要`・不足は赤）+ Gold | テキスト列挙から脱却 |
| P3-D139-3 | **ソート**＝作成可能レシピを上、`display_name` 昇順 | 即実行可能なものを先に |
| P3-D139-4 | **ボタン**＝不可時 `Gold不足` / `素材不足` を区別 | D136 の無効ボタンを補足 |
| P3-D139-5 | **スコープ外**: レシピカテゴリタブ・UI本格化・NPC台詞 | MVP最小化 |

## Result 作成可能レシピ表示（2026-07-01 — P3-D141）

> D135 スコープ外だった Result→鍛冶フィードバックをテキスト1行で実装。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D141-1 | **`CraftHelper`** — `can_craft` / `get_craftable_recipes` を共通化（鍛冶屋も利用） | 判定ロジックの重複排除 |
| P3-D141-2 | **Result `MaterialPanel`** — `last_run_material_gains` あり **かつ** 作成可能レシピがあるとき「赤鉄の工房で作成可能: …」1行 | 探索→素材→鍛冶の動線。ジャンプは D138 拠点タップに委譲 |
| P3-D141-3 | **Gold 判定**＝`_bank_rewards()` 後の `GameState.gold`（今回入手分込み） | Result 表示時点で実際に作れるか |
| P3-D141-4 | **スコープ外**: Result から鍛冶シーン直遷移・不足素材の内訳表示 | MVP最小化 |

## ガンビット条件静的ヒント（2026-07-01 — P3-D140）

> P3-D122-5 / D137 スコープ外だった条件プレビューの代替。戦闘コンテキスト不要の説明文。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D140-1 | **`CombatGambit.condition_hint(id)`** — 全16条件に静的説明を SSOT 化 | 装備画面・将来UIから参照 |
| P3-D140-2 | **ガンビット各行の下**にヒント1行（条件変更で即更新） | ライブ成立判定はスコープ外 |
| P3-D140-3 | **スコープ外**: 戦闘中の成立プレビュー・条件エディタ本格化 | MVP最小化 |

## 経済ループ Closeout（2026-07-01 — P3-ECO-001）

> P3-D134〜141 で準備ループ＋素材経済の縦切りを完了。作画・実機は別レーン。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ECO-001-1 | **経済ループ完了宣言** — 入手（生態ドロップ/イベント/ELITE）→ 可視化（TopBar/Result）→ 消費（鍛冶6レシピ）が一連で成立 | D067 配線 + D136 導線 + D138〜141 UX |
| P3-ECO-001-2 | **Closeout タスク一覧**＝D134 競合トースト / D135 Result素材UI / D136 鍛冶復活 / D137 ガンビット並替 / D138 拠点素材 / D139 鍛冶UX / D141 作成可能表示 / D140 条件ヒント | Alpha 準備+経済レーン |
| P3-ECO-001-3 | **SSOT 同期**＝`04_ゲームループ.md` Alpha現行ループ・`CODEMAP.md` CraftHelper/Result/Base | 仕様とコードの整合 |
| P3-ECO-001-4 | **次焦点**＝作画 Defer 維持。Impl 候補＝`P3-BAL-004` 経済バランス調整 or Backlog（Decision 要） | 機能追加より調整・大物は Decision 待ち |
| P3-ECO-001-5 | **スコープ外（本 Closeout）**＝商人復活・素材ショップ・全素材アイコン・UI本格化 | 既存 Decision 維持 |

## 経済バランス調整（2026-07-01 — P3-BAL-004）

> シミュレーション（5 COMBAT/周）で基本レシピの1周作成率が 7〜15% と低すぎたため、D067 確率帯を微調整＋レシピコストを引き下げ。目標＝**2周以内に基本武器/革鎧のいずれか1件作成可能**（銀の指輪は3周前後）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-BAL-004-1 | **生態ドロップ率**（`ECOLOGY_DROP_CHANCE`）: rarity0 60%→**65%** / rarity1 30%→**35%**（2/3 は据置） | 単一敵由来素材の詰まり緩和。図鑑×1.5 は維持 |
| P3-BAL-004-2 | **レシピコスト引下** — 鉄剣・狩猟弓・革鎧＝各素材 **1+1** / 骨鎧＝古き骨 **2** / 銀の指輪＝遺跡欠片 **2**+高品質1 | 1周7%台→約30〜45%（武器/革鎧） |
| P3-BAL-004-3 | **見習いの杖**＝`magic_antenna×1` + `crystal_spike×1`（晶核→水晶の棘。r0 化で杖のみ詰まり解消） | 単一敵2回依存（触角×2）を回避 |
| P3-BAL-004-4 | **ELITE 素材ボーナス** `ELITE_MATERIAL_CHANCE` 15%→**20%**（素材優先方針 30% は維持） | 銀の指輪の高品質欠片入手を微改善 |
| P3-BAL-004-5 | **据置**: Gold コスト（40/50/80）・敵プール・探索方針倍率・武器直ドロップ率 | 経済の他レーンは触らない |
| P3-BAL-004-6 | **スコープ外**: 商人復活・敵別ドロップ重み・ELITE 生態素材・実機プレイ感の最終調整 | 実機後に微調整可 |

## 高速周回 — ELITE スキップ拡張（2026-07-01 — P3-D142）

> P3-D118 の周回トグルを ELITE 部屋にも拡張。クリア後周回のテンポ改善。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D142-1 | **周回ON時**、スキップ対象を `COMBAT` に加え **`ELITE` も即撃破**（`CombatFastRun.can_skip_room` 拡張） | D118 と同型。初回クリア前は従来どおり実戦 |
| P3-D142-2 | **BOSS は常に実戦**（スキップ不可） | ボス体験維持 |
| P3-D142-3 | **報酬は通常通り** — ELITE 1.5倍・`apply_elite_bonus_loot`・撃破報酬は既存 kill 経路 | ペナルティなし。D118 と整合 |
| P3-D142-4 | **ログ** — COMBAT=`[周回] 戦闘をスキップ` / ELITE=`[周回] エリート戦闘をスキップ` | 区別可能に |
| P3-D142-5 | **スコープ外**: ELITE 専用トグル・報酬ペナルティ・敗北シミュ・周回既定ON | D118-5 継続 |

## ダンジョン HP 持ち越し（2026-07-01 — P3-FIX-004）

> 戦闘開始の `_init_party_hp()` が毎回フル回復していた実装バグを修正。P2-D017（HEAL +10）と整合。

| # | 決定 | 根拠 |
|---|---|---|
| P3-FIX-004-1 | **ラン開始時1回** `reset_party_hp_for_run()`（`DungeonScene` 進入時）で全員最大HP初期化 | 新ランはフルスタート |
| P3-FIX-004-2 | **戦闘開始時** `ensure_party_hp_for_combat()` — 既存 `party_combat_hp` を**維持**（死亡0も維持）。Threat のみ戦闘ごとリセット | 部屋間・戦闘間でダメージ持ち越し |
| P3-FIX-004-3 | **HEAL 部屋 / イベント回復 / スキル回復** は従来どおり部分回復 | 全回復経路はラン開始のみ |

## 罠部屋 MVP（2026-07-01 — P3-D151 / オーナー要望・**次 Impl 候補**）

> 戦闘なしの専用部屋として罠を追加。P3-D117 の罠解除スキルと連携。

| # | 決定（案） | 根拠 |
|---|---|---|
| P3-D151-1 | **新部屋タイプ `TRAP`**（`Enums.RoomType` 追加）— 戦闘なし・自動進行（TREASURE/EVENT 同型） | 「罠イベント部屋」を明確化。戦闘開始時罠(D117)とは別 |
| P3-D151-2 | **効果** — 入室時に罠判定：scout/tank がいれば **罠解除成功**（無ダメ）／否则 **パーティ1人にダメージ**（初期=8、既存 `ExplorationSkills.trap_damage` 流用可） | D117 探索スキルとの役割分担 |
| P3-D151-3 | **抽選** — 中間部屋重みに TRAP **~8%** 追加（COMBAT から微減 or 新規枠）。START/BOSS/EXIT 固定は維持 | モーンゲート floor_count 抽選に組込 |
| P3-D151-4 | **ログ** — `[罠]` 成功/失敗・被弾者名。ナラティブ1行（例:「床板の罠が作動した」） | フルオートでも可視化 |
| P3-D151-5 | **スコープ外**: 罠の種類拡充・手動解除UI・報酬付き罠・商人/HEAL 復活 | MVP最小化 |

**Closeout（2026-07-01）:** `RoomType.TRAP` 追加・抽選重み COMBAT52/EVENT15/TREASURE13/**TRAP8**/ELITE12・`DungeonScene._resolve_trap_room`・`ExplorationSkills.can_disarm_trap_room`・全滅時は Result へ。headless smoke PASS。

## 敵別 Threat ターゲット偏重（2026-07-01 — P3-D145）

> P3-D104 スコープ外だった敵種別の狙い方を `EnemyData.threat_target_bias` で実装。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D145-1 | **`threat_target_bias`** 4種＝`max_threat`(既定) / `lowest_hp` / `back_row` / `lowest_threat` | 獣=タンク狙い・遠隔=後列・ネズミ=仕留め、を最小データで表現 |
| P3-D145-2 | **配線**＝`pick_enemy_target_from_indices` が攻撃者スロットの敵データを参照してスコアリング | 群れ・混成でもスロット別に判定 |
| P3-D145-3 | **モーンゲート初期値** — 水晶ハリネズミ/クロックモス=`back_row`・冠喰いネズミ=`lowest_hp`・他=`max_threat` | 役割の差別化。数値は実機後に調整可 |
| P3-D145-4 | **スコープ外**: Threat UI バー・挑発専用スキル・複数タンク按分 | D104-4 継続 |

**Closeout（2026-07-01）:** headless smoke PASS。

## 鍛冶屋「炉研ぎ」武器強化（2026-07-01 — P3-D152）

> オーナー GO（案A）。赤鉄の工房で鑑定済み武器を +1〜+5 まで ATK フラット強化。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D152-1 | **対象＝武器のみ**。`WeaponInstance.enhance_level`（0〜5）。実効 ATK = `rolled_attack + enhance_level` | フェーズ1は武器更新感を優先。防具・装飾は後続 |
| P3-D152-2 | **表示名** `王国制式剣 +2` 形式。スキル/属性/タグ/Affix は不変 | 愛用装備の継続投資。ドロップ差別化は維持 |
| P3-D152-3 | **失敗なし**・鑑定済みのみ強化可 | MVP最小。鑑定ループと整合 |
| P3-D152-4 | **コスト** — +1=30G+欠片1 / +2=50G+欠片2 / +3=80G+欠片2+古き骨1 / +4=120G+欠片3+エリート欠片1 / +5=180G+欠片3+エリート欠片2 | モーンゲート素材で段階的到達 |
| P3-D152-5 | **UI** — `BlacksmithScene` に「作成｜炉研ぎ」タブ。`EquipmentEnhancer` がコスト判定・実行の SSOT | D136 鍛冶屋の延長 |
**Closeout（2026-07-01）:** headless smoke PASS。

## 編成画面モック寄せ（2026-07-01 — P3-UI2-017）

> オーナー GO（案1〜5）。`UI_Reference_003_03_Party` 骨格に寄せ、Tab 分離を廃止。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-017-1 | **1画面構成** — Header（通貨）/ 総合戦力 / 4カード編成 / リーダー帯 / 4列グリッド / 保存フッター / BottomNav | モック 003_03 構造 |
| P3-UI2-017-2 | **Party2/3タブは非表示**（複数編成プリセットは Defer） | Alpha スコープ外 |
| P3-UI2-017-3 | **リーダー＝スロット0表示のみ**（戦闘効果なし） | リーダースキルは別 Decision |
| P3-UI2-017-4 | **おすすめ編成1本**（role バランス＋前衛配置） | 一括編成は統合 |
| P3-UI2-017-5 | **陣形＝ポップアップ2×2**（別タブ廃止） | 既存 swap ロジック温存 |
| P3-UI2-017-6 | **詳細** → `EquipmentScene`（`equipment_focus_member_index`） | 装備導線 |
| P3-UI2-017-7 | **スコープ外** — リーダースキル効果・Party複数・本格フィルタ UI | 段階2以降 |

**P3-UI2-017b Closeout（2026-07-01）:** リーダー帯（♛+パッシブ説明）・CombatUiFrames 枠・グリッド名/職/編成中バッジ・ロールフィルタ・攻撃力/防御力/HP 表記。headless smoke PASS。

## 鍛冶屋モック寄せ（2026-07-01 — P3-UI2-018）

> オーナー GO（案1〜5）。生産＋強化 Master-Detail、分解は準備中ロック。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-018-1 | **生産タブ** — 左レシピリスト / 右詳細（アイコン・ステ・素材・作成）/ 下部横スクロール「製作可能」 | モック骨格 |
| P3-UI2-018-2 | **強化タブ** — 左鑑定済み武器 / 右炉研ぎ詳細。`EquipmentEnhancer` ロジック不変 | P3-D152 温存 |
| P3-UI2-018-3 | **分解タブ** — ロック表示のみ（`分解 🔒`） | Alpha スコープ外 |
| P3-UI2-018-4 | **カテゴリ** — 武器 / 防具 / 装飾（生産タブのみ） | 6レシピ分類 |
| P3-UI2-018-5 | **Header + BottomNav** — DungeonSelect 同型。`NavForge` ハイライト | 拠点 UI 統一 |
| P3-UI2-018-6 | **スコープ外** — 分解実装・NPC台詞・専用アート | 段階2以降 |

**P3-UI2-018 Closeout（2026-07-01）:** `BlacksmithUiHelper` + Master-Detail UI。headless smoke PASS。

## 装備画面モック寄せ（2026-07-01 — P3-UI2-019）

> オーナー GO 継続。`UI_Reference_003_04_Equipment` 骨格の第1段。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-019-1 | **Header + BottomNav** — 通貨チップ・`NavParty` ハイライト・鍛冶/図鑑/ショップ導線 | 017/018 と統一 |
| P3-UI2-019-2 | **キャラ切替** — ポートレート左右 ◀▶ + 既存メンバーボタン温存 | モック 003_04 |
| P3-UI2-019-3 | **タイトル**「キャラ装備」。装備/戦術タブ・ガンビット等は温存 | ロジック不変 |
| P3-UI2-019-4 | **スコープ外** — 6装備枠・足具タブ・ソート/フィルタ UI・ステ詳細ポップアップ | 段階2以降 |

**P3-UI2-019a Closeout（2026-07-01）:** Header/BottomNav/メンバー矢印。headless smoke PASS。

**P3-UI2-019b Closeout（2026-07-01）:** 装備枠をキャラカード内縦配置・炉研ぎ+Nバッジ・装備一覧ヘッダ・レアリティソート・`MemberSelectRow` 修復。headless smoke PASS。

### 装備画面モック寄せ 第2段（2026-07-01 — P3-UI2-019c〜e）

> オーナー GO（推奨案 A 一括）。`UI_Reference_003_04_Equipment` 骨格の第2段。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-019c-1（D1） | **装備枠3+足具🔒** — 2×2 `GridContainer`、足具カテゴリはロック表示のみ | モック 003_04 / Alpha 3枠据置 |
| P3-UI2-019c-2 | **キャラカード** — ★行・Lv行・職アイコン行・ステ2列グリッド | モック情報密度 |
| P3-UI2-019d-1（D2） | **一覧=全装備** — `get_appraised_*` 直参照。装備者ミニアイコン（他キャラ装備中） | モック一覧 |
| P3-UI2-019d-2 | **ソート/フィルタ UI** — レアリティ・名前ソート、すべて/装備中/未装備 | 019-4 から昇格 |
| P3-UI2-019d-3（D5） | **メンバー切替** — `MemberSelectRow` 非表示、肖像 ◀▶ のみ | モック簡素化 |
| P3-UI2-019e-1（D3） | **戦術/ガンビット** — スキルタブ内温存（ロジック不変） | 019-3 継続 |
| P3-UI2-019e-2（D4） | **覚醒/プロフィール** — タブ追加・`disabled`+🔒ラベル | モック準備中表示 |
| P3-UI2-019e-3 | **BottomNav** — `NavAdventure` 導線・鍛冶未読● | 017/018 統一 |

**P3-UI2-019c〜e Closeout（2026-07-01）:** `EquipmentUiHelper` 拡張・`EquipmentScene` レイアウト/一覧/タブ。headless smoke PASS。

## 召喚所・図鑑モック寄せ（2026-07-01 — P3-UI2-020）

> 017〜019 と同型の Header/BottomNav 統一。ガチャロジック・図鑑データは不変。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-020a-1 | **召喚所** — Header（通貨チップ）/ 天井表示 / 排出カード行 / BottomNav `NavShop` ハイライト | 017/018 統一 |
| P3-UI2-020a-2 | **ラインナップ** — 職アイコン・★・所持バッジのカード行 | 可読性 |
| P3-UI2-020b-1 | **図鑑** — Header + BottomNav `NavCodex` ハイライト。既存タブ/詳細温存 | 017 統一 |
| P3-UI2-020b-2 | **スコープ外** — 発見率バー・星評価・002 密度の一覧 | Beta |

**P3-UI2-020 Closeout（2026-07-01）:** `GachaScene` / `CodexScene` Header+BottomNav。headless smoke PASS。

## 召喚演出 MVP（2026-07-01 — P3-UI2-022）

> 段階A。`GachaSystem.pull()` 後にリビールオーバーレイ。ロジック不変。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-022-1 | **演出フロー** — 暗転→魔晶石フラッシュ→キャラアイコン拡大→NEW/重複表示→タップで閉じる | 段階A |
| P3-UI2-022-2 | **入力** — 演出中は召喚・ナビ無効。完了後タップで dismiss | 連打防止 |
| P3-UI2-022-3 | **天井表示** — 「未所持確定」表記（★3固定データに整合） | 仕様ゆれ解消 |
| P3-UI2-022-4 | **スコープ外** — 専用立ち絵・10連・SE/パーティクル本格 | Beta |

**P3-UI2-022 Closeout（2026-07-01）:** `SummonRevealLayer` + Tween。headless smoke PASS。

## ダンジョン選択モック第3段（2026-07-02 — P3-UI2-028）

> 003_05/06 モックのカード密度寄せ。段階A＝既存データのみ。スタミナ・下部パネルは対象外。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-028-1 | **`DungeonData.flavor_text`** — フィーチャーにフレーバー2行表示 | 003_05 |
| P3-UI2-028-2 | **階層一覧** — `floor_count` から B1F〜BnF カード生成。B1F のみ選択可 | Alpha 1DG |
| P3-UI2-028-3 | **カード行** — サムネ+CLEARリボン・敵3アイコン・推奨戦力・★・ドロップ・選択/ロック中 | 003_06 |
| P3-UI2-028-4 | **推奨戦力** — `(推奨Lv+階層-1)×130 + 難易度×45`（表示専用） | モック準拠 |
| P3-UI2-028-5 | **スコープ外** — スタミナ Header・日次挑戦・DGボーナス・下部3枠・複数DG本格 | Beta |

**P3-UI2-028 Closeout（2026-07-02）:** `DungeonSelectScene` 階層カード密度。headless smoke PASS。

## ギルド日課ミッション MVP（2026-07-02 — P3-DAILY）

> P3-D069-4 の Defer を Alpha MVP 例外で上書き。固定3件/日・報酬受取・5:00 JST リセット。

| # | 決定 | 根拠 |
|---|---|---|
| P3-DAILY-001-1 | **MVP 導入** — Alpha に日課3件（完走/戦闘勝利3/装備作成1） | リテンション最小 |
| P3-DAILY-001-2 | **リセット** — 毎日 5:00 JST。未受取は日跨ぎで失効 | 003 モック整合 |
| P3-DAILY-001-3 | **報酬** — Gold / 魔晶石 / 素材（新通貨なし） | 既存経済 |
| P3-DAILY-001-4 | **UI** — `BaseScene` 左下コンパクトパネル（進捗・受取） | 003_01 デイリー占位 |
| P3-DAILY-001-5 | **スコープ外** — 週間・抽選プール・スタミナ連動・専用シーン | Beta |

**P3-DAILY Closeout（2026-07-02）:** `DailyMissionSystem` + BaseScene パネル。headless smoke PASS。

## 助っ人専用立ち絵（2026-07-02 — P3-GACHA-003）

> ガチャ助っ人の UI 立ち絵パイプライン。戦闘スプライトは対象外。

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-003-1 | **`GachaHelperData.portrait_resource_path`** — 召喚演出・ラインナップ・編成・装備の肖像 SSOT | 差替容易 |
| P3-GACHA-003-2 | **命名** — `assets/gacha/portraits/ART_HELPER_{helper_id}.png` | 一貫性 |
| P3-GACHA-003-3 | **暫定アセット** — 職バストをコピー（ヴァルデン/イヴァル/セリン）。オーナー作画で差替可 | 作画待ち解消の最小 |
| P3-GACHA-003-4 | **フォールバック** — パス空/欠落時は `job_id` バストアイコン | 堅牢性 |
| P3-GACHA-003-5 | **スコープ外** — 戦闘スプライト（`sprite_resource_path`）・台詞演出 | Beta |

**P3-GACHA-003 Closeout（2026-07-02）:** 立ち絵配線+暫定3枚。headless smoke PASS。

## 拠点モック第2段（2026-07-01 — P3-UI2-027）

> `UI_Reference_003_01` / `003_02` 骨格の第2段。中央ビジュアル・メニュー密度向上。ロジック不変。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-027-1 | **TitlePanel** — ロゴ/タイトル/サブタイトルを `CombatUiFrames` 枠内に配置 | 003_01 |
| P3-UI2-027-2 | **SpotlightPanel** — 選択中DG名・発見率・難易度・サムネ+「挑戦」CTA | 003_05 フィーチャー |
| P3-UI2-027-3 | **左メニュー** — 7機能をアイコン+タイトル+サブタイトルのカード行に | 003_01 密度 |
| P3-UI2-027-4 | **FeatureGrid** — 中央3列グリッドで同一7機能をコンパクト表示 | 003_02 |
| P3-UI2-027-5 | **スコープ外** — デイリー・スタミナ・お知らせ・肖像・3×3全9タイル | Beta |

**P3-UI2-027 Closeout（2026-07-01）:** `BaseScene` Title/Spotlight/FeatureGrid + 左メニューカード化。headless smoke PASS。

## 拠点 BottomNav 表記統一（2026-07-01 — P3-UI2-025）

> 021 で確定した「冒険」「召喚」表記を全拠点系画面へ展開。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-025-1 | **BaseScene** — BottomNav `冒険`/`召喚`・`NavHome` ハイライト | 021 統一の起点 |
| P3-UI2-025-2 | **左メニュー** — `▶ 冒険` / `▶ 召喚` に表記合わせ | 導線一貫性 |
| P3-UI2-025-3 | **残画面** — Equipment/Blacksmith/Roster の `NavShop` を `召喚` に | 021 漏れ解消 |
| P3-UI2-025-4 | **スコープ外** — 鍛冶 `NavForge` 構成・Result 専用フッター | 画面固有 |

**P3-UI2-025 Closeout（2026-07-01）:** BottomNav 表記統一。headless smoke PASS。

## ガチャ助っ人コンテンツ（2026-07-01 — P3-GACHA-002）

> P3-W-012 / D036b-7 の仮名を HQ 暫定固有名へ差替。作画・専用立ち絵は対象外。

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-002-1 | **固有名（HQ暫定）** — A=ヴァルデン（Valden）/ B=イヴァル（Ivar）/ C=セリン（Serin） | 基本5職と重複回避・08 §14 背景整合 |
| P3-GACHA-002-2 | **来歴行** — `GachaHelperData.origin_note`・排出ラインナップに表示 | 可読性 |
| P3-GACHA-002-3 | **セーブ同期** — ロード時 `gacha_*` の display_name/rarity を helper 定義へ追従 | 旧仮名セーブ救済 |
| P3-GACHA-002-4 | **スコープ外** — 専用スプライト・台詞・オーナー最終名の強制 | 差替可 |

**P3-GACHA-002 Closeout（2026-07-01）:** `helper_a/b/c.tres` + world 同期。headless smoke PASS。

## ガチャ仕様整合（2026-07-01 — P3-GACHA-001）

> P3-D036b の実装差分を解消。UI 演出・10連・有償通貨は対象外。

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-001-1 | **プール** — `helper_a` を ★4、B/C は ★3 のまま | D036b-1/7 |
| P3-GACHA-001-2 | **排出** — 未所持優先のうえ ★4=20% / ★3=80% | D036b-4 |
| P3-GACHA-001-3 | **還元** — 重複 ★4=5 / ★3=2 | D036b-6 |
| P3-GACHA-001-4 | **ロスター** — 取得時 `Adventurer.rarity` を helper 値で反映 | 表示整合 |
| P3-GACHA-001-5 | **UI** — 排出率1行表示（`GachaSystem.rate_display_text`） | 可読性 |

**P3-GACHA-001 Closeout（2026-07-01）:** `GachaSystem` + `helper_a` + 画面表示。headless smoke PASS。

## ギルド認定モック寄せ（2026-07-01 — P3-UI2-024）

> 拠点「ギルド認定」画面の UI polish。認定ロジック不変（P3-D052-2 手動認定）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-024-1 | **Header/BottomNav** — Gold/魔晶石チップ・5タブ（召喚表記） | 017〜023 統一 |
| P3-UI2-024-2 | **認定リストカード化** — 肖像+職/到達形+認定CTA・`CombatUiFrames` | 編成/装備パターン |
| P3-UI2-024-3 | **ソート** — 認定可能→未達→認定済、Lv降順 | UX |
| P3-UI2-024-4 | **スコープ外** — 認定官NPC台詞・演出・一括認定 | Beta |

**P3-UI2-024 Closeout（2026-07-01）:** `GuildScene` polish。headless smoke PASS。

## 探索リザルトモック寄せ（2026-07-01 — P3-UI2-023）

> `UI_Reference_002` §7 骨格の段階A。報酬ロジック不変。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-023-1 | **パネル統一** — `CombatUiFrames`・報酬セルカード化 | 017〜022 統一 |
| P3-UI2-023-2 | **固定フッター** — 再挑戦/拠点へをスクロール外に配置 | 002 §7 |
| P3-UI2-023-3 | **探索情報** — 発見率（`dungeon_progress.discovery`）行を追加 | 002 発見率 |
| P3-UI2-023-4 | **セーブ** — フッター遷移時に `SaveManager.save_game()` | 報酬反映永続化 |
| P3-UI2-023-5 | **スコープ外** — 撃破数/最深階/時間・BottomNav | Beta |

**P3-UI2-023 Closeout（2026-07-01）:** `ResultScene` polish。headless smoke PASS。

## ダンジョン選択モック寄せ（2026-07-01 — P3-UI2-021）

> `UI_Reference_003_05_Dungeon` / `003_06_Dungeon_List` 骨格の第2段。スタミナ・週間ボーナスは Defer。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-021-1 | **フィーチャーカード** — 選択中DGを大サムネ+メタ+発見率+「挑戦」CTA | 003_05 |
| P3-UI2-021-2 | **難易度タブ** — ノーマルのみ有効、ハード/ナイトメア🔒 | 003_05 / Alpha 1DG |
| P3-UI2-021-3 | **一覧** — フィーチャー除外・ロック行🔒・発見率表示 | 003_06 |
| P3-UI2-021-4 | **BottomNav** — `NavAdventure` ハイライト・「召喚」表記統一 | 017〜020 統一 |
| P3-UI2-021-5 | **スコープ外** — スタミナ・週間ボーナス・複数DG本格 | Beta |

**P3-UI2-021 Closeout（2026-07-01）:** `DungeonSelectScene` フィーチャー+挑戦。headless smoke PASS。

## ガチャ通貨「魔晶石」（2026-07-01 — P3-ECO-002）

> 仮称 `gacha_token` / ◆ 表示を正式名称・アイコンへ統一。セーブキー `gacha_token` は互換維持。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ECO-002-1 | **表示名＝魔晶石**。内部 `GameState.gacha_token`・`CurrencyHelper` SSOT | D036b 通貨の世界観化 |
| P3-ECO-002-2 | **アイコン** `ICO_Currency_Arcanite.png`（紫晶・003 モック準拠） | Header/Result/Gacha 共通 |
| P3-ECO-002-3 | **ロジック不変** — 単発1・100G購入・ラン成功1〜2・重複還元 | D036b 温存 |

**Closeout（2026-07-01）:** headless smoke PASS。

## Alpha Closeout / Beta スコープ（2026-07-02 — P3-ALPHA-006 / P3-BETA-001）

> オーナー承認: 1=A, 2=B1+B2, 3=029 GO, 4=Queue 刷新 OK。

### Alpha Closeout（P3-ALPHA-006 — 案 A）

| # | 決定 | 根拠 |
|---|---|---|
| P3-ALPHA-006-1 | **Alpha Closeout = 薄い Close** — `smoke_test.sh` PASS 維持でコードレーン完了可。実機 GO は必須条件にしない（P3-ALPHA-003b Defer 継続） | 開発ブロック回避・作画/実機はオーナーレーン |
| P3-ALPHA-006-2 | **残コード polish** — P3-UI2-029（DG下部パネル占位のみ・スタミナロジックなし）を Alpha 最終 Impl | mock 穴の最小塞ぎ |
| P3-ALPHA-006-3 | **作画** — 5職ドット / env / 助っ人本番立ち絵はオーナー→Impl 並行。プレースホルダのまま Closeout 可 | 案 A の品質前提 |
| P3-ALPHA-006-4 | **スコープ外（Beta 送り）** — P3-DAILY-B / P3-UI2-026（音源なしは Defer）/ スタミナ実装 / 2本目 DG 実装 | Beta 最小パッケージへ |

### Beta 最小スコープ（P3-BETA-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-BETA-001-1 | **B1 コンテンツ** — 2本目 DG を Beta 第一柱（Biome/敵/イベントの具体は別 Decision で確定） | 横幅より「もう1本」 |
| P3-BETA-001-2 | **B2 メタ: スタミナ** — 挑戦回数制限を Beta 第二柱（029 占位の先に実ロジック） | 003 モック・日課と相乗 |
| P3-BETA-001-3 | **Beta 着手順** — Alpha Closeout（029）→ B1/B2 設計 Decision → Impl | 依存順 |
| P3-BETA-001-4 | **Beta 外（現状維持）** — 週間日課・10連ガチャ・6装備枠・天候本格・Affix本格・助っ人戦闘スプライト | スコープ抑制 |

## DG選択モック第4段 — 下部パネル占位（2026-07-02 — P3-UI2-029）

> 003_05/06 下部3枠 + ヘッダースタミナを占位表示。ロジックなし（P3-ALPHA-006 / Beta B2 先行）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI2-029-1 | **ヘッダー** — `⚡ 120/120` チップ（固定値） | 003_05 |
| P3-UI2-029-2 | **下部3枠** — 本日挑戦回数(3/3) / DGボーナス(地形属性+20%・残り時間) / 特別報酬プログレス(2/5) | 003_05/06 |
| P3-UI2-029-3 | **挑戦ボタン** — `挑戦 ⚡20` 表記（消費は未検証） | mock 整合 |
| P3-UI2-029-4 | **報酬一覧** — disabled + tooltip「準備中（Beta）」 | 占位 |
| P3-UI2-029-5 | **スコープ外** — スタミナ消費/回復・日次リセット・ボーナスタイマー・特別報酬付与 | **P3-BETA-B2** |

**P3-UI2-029 Closeout（2026-07-02）:** `DungeonSelectScene` FooterPanel + StaminaChip。headless smoke PASS。**Alpha コードレーン完了**。

## Beta スコープ修正 — スタミナ撤回（2026-07-02 — P3-BETA-001b）

> オーナー決定: スタミナシステムは不要。P3-BETA-001-2 を撤回。

| # | 決定 | 根拠 |
|---|---|---|
| P3-BETA-001b-1 | **B2 スタミナ実装を Beta から除外** | オーナー判断 |
| P3-BETA-001b-2 | **Beta 最小 = B1（2本目DG）のみ** | スコープ縮小 |
| P3-BETA-001b-3 | **029 占位**（⚡表示・挑戦回数）は **削除しない**（見た目のみ・ロジックなし）。整理は任意タスク | 手戻り回避 |

## ガチャ助っ人拡充（2026-07-02 — P3-GACHA-004）

> 基本5職のうち未カバーだった swordsman / beast_tamer をプールに追加。システムは DataRegistry 全件プール。

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-004-1 | **+2体** — `helper_d` レオン（swordsman・★3）/ `helper_e` ミラ（beast_tamer・★3） | 5職カバー完了 |
| P3-GACHA-004-2 | **排出率据置** — ★4=20% / ★3=80%（ティア内均等）・天井30・還元据置 | D036b 温存 |
| P3-GACHA-004-3 | **立ち絵** — 職バスト暫定コピー（GACHA-003 同型） | 作画待ち可 |
| P3-GACHA-004-4 | **スコープ外** — 戦闘スプライト・固有スキル・10連・有償通貨 | Beta 以降 |

**P3-GACHA-004 Closeout（2026-07-02）:** `helper_d/e.tres` + 肖像2枚 + world 同期。`GachaSystem` プール動的化。headless smoke PASS。

## ガチャ★1〜4・差別化・スターター分離（2026-07-02 — P3-GACHA-005）

> オーナー決定: ★1=ノーマル〜★4。全員基本5職のいずれか。差別化=パッシブ+初期ステ。スターター5職はガチャ対象外。

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-005-1 | **レアリティ ★1〜4** — 排出 45/30/20/5%。還元 1/2/4/8。天井30は未所持確定（現行維持） | 4段階化 |
| P3-GACHA-005-2 | **差別化** — `GachaRarityConfig` で HP/ATK/DEF 加算 + `GachaHelperData.passive_id` で戦闘パッシブ | 性能差はパッシブ+初期ステ |
| P3-GACHA-005-3 | **スターター分離** — `adventurer_0..4`（アルド等）は開始配布・★3表示・固有パッシブ。`gacha_helpers/` のみがプール | ガチャに基本5職を出さない（2026-07-14: ★4→★3） |
| P3-GACHA-005-4 | **現プール5体** — レオン★1/イヴァル★2/セリン★3/ミラ★3/ヴァルデン★4（各1職） | 5職カバー |
| P3-GACHA-005-5 | **スコープ外** — 凸・10連・戦闘スプライト・スタミナ | 据置 |

**P3-GACHA-005 Closeout（2026-07-02）:** `GachaRarityConfig` + 戦闘/表示配線 + helper 振り分け。headless smoke PASS。

## Beta 5 Biome ラインナップ（2026-07-02 — P3-D5DG-001）

> オーナー承認: モーンゲート含む **5 Biome 構成** を確定。③のみ **鍛冶遺構→南の沼** に差し替え。④⑤・解放条件・属性分散は原案承認。

| # | Biome | 地理 | 九王 | 適応テーマ | favored | 主状態異常 | diff | 推奨Lv |
|---|---|---|---|---|---|---|---|---|
| 1 | モーンゲート | 王都地下 | 継承王 | 鉱物化適応 | dark | 出血・スタン | 1 | 1 |
| 2 | ウィスパーウッド | ヴェルディア西 | 森護王 | 共生適応 | fire | 毒・chill | 2 | 10 |
| 3 | **ミストフェン（霧沼）** | 南・沼地 | 学識王 | **腐生適応** | thunder | 毒・出血 | 3 | 20 |
| 4 | 沈没航路 | ブラックショア | 海統王 | 潮汐適応 | holy | 標的・chill | 4 | 32 |
| 5 | 最果て氷裂 | フロストリッジ北 | 開拓王 | 寒冷適応 | ice | chill・スタン | 5 | 45 |

| # | 決定 | 根拠 |
|---|---|---|
| P3-D5DG-001-1 | **5本構成 GO** — 上表を Beta〜初期本編の Biome ロードマップ正とする | オーナー承認 |
| P3-D5DG-001-2 | **③＝ミストフェン（霧沼）** — 調査地通称「沈没封緘区」。鍛冶王／レッドフォージは **Biome-06 以降** に温存 | オーナー差し替え |
| P3-D5DG-001-3 | **解放** — 前 Biome Boss 初回討伐で次を解放（推奨Lvは目安のみ） | 原案承認 |
| P3-D5DG-001-4 | **MVP規模** — 各 Biome 雑魚4＋Elite1＋Boss1（モーンゲート準拠） | 原案承認 |
| P3-D5DG-001-5 | **②の次 Impl** — P3-BETA-001（ウィスパーウッド具体）を維持。③以降は設計ドラフト段階（`world/05_Biomes §3.3〜`） | 着手順 |

**③沼の設計要点:** ②（有機・共生・胞子毒）と差別化し **腐敗有機物の取り込み＝腐生適応**。学識王ゆかりの沈没書庫跡・封緘書庫 LF。Boss 候補＝伝承「霧沼の古茸」（`04_Classification §5.5`）。

## メイン／寄り道 Biome と周回進行（2026-07-02 — P3-D5DG-002）

> オーナー方針: **現フェーズはメイン5本でよい**が、将来 **寄り道（サイド）Biome** を追加する。**一発クリア想定にしない** — 複数周回で武器・装備を揃えてから次メインへ進む体験を正とする。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D5DG-002-1 | **Biome 二層** — **メイン**（5本ロードマップ）と **寄り道**（サイド・短編）を設計上区別する。寄り道はメインと同じ Biome ルール（適応テーマ・九王フック）に従うが、規模は小さく（目安: 雑魚2〜3＋Elite0〜1＋Boss0〜1・部屋6〜8） | 5本だけでは薄い。横幅は寄り道で補う |
| P3-D5DG-002-2 | **寄り道の役割** — ①特定属性武器・素材のファーム ②メイン初見前の戦力整備 ③地理・街道の「寄り道」演出。**次メインの必須ゲートにはしない**（スキップ可能だが、初見で詰まりやすい） | 強制グランドは避け、自然な周回動機 |
| P3-D5DG-002-3 | **難易度曲線** — 各メイン Biome は **初回単独クリアを設計目標にしない**。同帯メイン＋寄り道を **3〜6 周**（1周4〜6分 / D-002）回して装備・Lv・遺物が揃い、**安定クリア→Boss 討伐**が標準プレイ | オーナー要望「何度か周回して武器を揃える」 |
| P3-D5DG-002-4 | **次メイン解放** — P3-D5DG-001-3 を維持: **当該メイン Boss 初回討伐**で次メインを解放。ただし討伐到達までに寄り道ファーム＋当メイン周回が **想定ルート**（討伐=実力チェック、解放=進行の鍵） | 解放条件は単純・戦力差はコンテンツ難度で作る |
| P3-D5DG-002-5 | **データ（将来）** — `DungeonData` に `route_type: main \| side`（または同等）・`parent_biome_id`（紐づくメイン帯）・`recommended_runs_before_main`（目安周回数・UI表示用）を追加予定。Impl は Biome 追加 Task と同時 | スキーマは後続。設計 SSOT のみ先固定 |
| P3-D5DG-002-6 | **クリア後** — 既存 **周回トグル**（P3-D118/D142）でファーム効率化。寄り道はクリア後も素材・図鑑用に残す | 後半のリテンション |

**寄り道配置（構想・未確定）:**

| 帯 | 寄り道候補 | ファーム目的 |
|---|---|---|
| ①前後 | 王都地上外郭（アステリア廃墟・浅部） | 入門装備・闇/出血素材 |
| ②並行 | 翠の湿地（グリーンホロウ周辺） | 炎試練・毒耐性 |
| ③並行 | ブロークンマーシュ（崩落街道橋） | 電気素材・③前整備 |
| ④並行 | ウェストベイ干潟 | 聖属性・潮素材 |
| ⑤並行 | フロストウォール周辺雪道 | 氷素材・⑤前整備 |
| ⑥以降 | レッドフォージ短編 等 | 鍛冶王・炉印 LF |

※名称・採用は個別 Task。メイン5本（P3-D5DG-001）を優先実装。

## 階層数・イベント密度（2026-07-02 — P3-D5DG-003）

> オーナー GO: **ダンジョンごとに `floor_count` をバラバラにする** ＋ **イベント（EVENT 部屋）を増やす**。Biome 個性と周回時の「毎回ちょっと違う」を戦闘以外で補強。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D5DG-003-1 | **`floor_count` は Biome ごとに個別設定**（統一しない）。1周 **4〜6分**（D-002）を先に守り、階層が増えた DG は戦闘比率で調整 | 地下は深い・寄り道は短い等、世界観と一致。P3-D076 既存 |
| P3-D5DG-003-2 | **目安帯** — 寄り道 **5〜7**／メイン序盤①② **7〜8**／中盤③④ **8〜9**／終盤⑤ **9〜10** | route_type（P3-D5DG-002）と対応 |
| P3-D5DG-003-3 | **EVENT 重み** — `DungeonData.event_room_weight`（0＝グローバル15）。寄り道 **22〜28**／メイン **15〜22**／LF多めメイン **20〜22** | 差は COMBAT 重みから差し引き（合計100維持） |
| P3-D5DG-003-4 | **EVENT 下限** — `min_event_rooms`（0＝自動）。中間部屋 **≥3** かつ event 重み **>0** なら **最低1 EVENT** を列生成後に保証 | 長い DG でイベント0周を防ぐ |
| P3-D5DG-003-5 | **イベントプール** — 汎用 `EVENTS` ＋ Biome 別（`EVENTS_*`）。**lore / material / heal / buff** を Biome 設計時に **6〜10件** 目安で増やす | 観察・LF が探索の核 |
| P3-D5DG-003-6 | **深度連動（将来）** — 同一 Biome 内で深い層ほど高深度 LF を出す重み付け。モーンゲートは層位 SSOT（`§3`）と緩く対応 | 厳密層別は Biome Task |
| P3-D5DG-003-7 | **mourngate 初期値** — `floor_count=7` 据置・`event_room_weight=20`・`min_event_rooms=1` | イベント密度を先行反映 |

**スコープ外:** イベント中の分岐3択・長文 ADV・部屋ごとの固定 EVENT 配置（将来 Task）。

## 5 Biome 敵キャラ MVP（2026-07-02 — P3-D5DG-004）

> オーナー GO: 各メイン Biome **雑魚4＋Elite1＋Boss1** の設定値・採用個体を確定。③以降の表示名はモーンゲート命名（環境印象＋生物／Boss＝描写＋固有名）へ改稿。

| # | Biome | enemy_level | floor_count | event_weight | Boss |
|---|---|---|---|---|---|
| 1 | モーンゲート | 1 | 7 | 20 | 水晶骸竜 セルディオン |
| 2 | ウィスパーウッド | 10 | 8 | 18 | フローラベア・グランヴェル |
| 3 | ミストフェン | 20 | 8 | 22 | 底なしの王 モルドガル |
| 4 | 沈没航路 | 32 | 9 | 18 | 潮鳴王 ネレイオン |
| 5 | 最果て氷裂 | 45 | 10 | 15 | 始祖の竜 エルディオン |

| # | 決定 | 根拠 |
|---|---|---|
| P3-D5DG-004-1 | **MVP6体構成** を全メイン Biome の実装正とする（詳細は `world/05_Biomes` 各 §MVP採用） | オーナー承認 |
| P3-D5DG-004-2 | **命名規則** — 雑魚/Elite: **短い印象語（漢字1〜2またはカタカナ）＋カタカナ生物名**（例: 冠喰いネズミ／セピアハウンド／オケチリーチ）。Boss: `カタカナ描写＋固有名`（例: 水晶骸竜 セルディオン／フォギマシュ マルグラン） | ③以降の名称改稿 |
| P3-D5DG-004-2b | **漢字過多を避ける** — 全漢字名は使わない。生物部位はカタカナ（ガエル・リザード・ウルフ等）を基本とする | オーナー指摘（2026-07-02） |
| P3-D5DG-004-3 | **id** は英語 snake_case・**表示名** は和文を正。伝承仮称（霧沼の古茸等）は Codex ・伝承レイヤに残し、ゲーム表示名と分離可 | 実装・ロア両立 |
| P3-D5DG-004-4 | **寄り道** の敵は本 Decision 対象外（Biome 追加 Task） | スコープ |
| P3-D5DG-004-5 | **Impl 順** — ②ウィスパーウッドから `EnemyData` + ドロップ表 | P3-BETA-001 |

### 敵名称オーナー確定（2026-07-02 — P3-D5DG-004c）

> ③〜⑤の表示名・`id`・祖先をオーナー指定へ差し替え。戦闘パラメータ（弱点・状態異常・enemy_level 等）は P3-D5DG-004 据置。

| Biome | id 一覧（雑魚→Boss） |
|---|---|
| ③ | `blood_leech` / `dead_poison_frog` / `mist_mantis` / `marsh_king` / `bone_picker` / `mire_strider_spider` / `spore_needle_wasp` / `great_claw` / `nightfen` / `moldgar` |
| ④ | `ship_eater_crab` / `skull_turtle` / `undertaker_shark` / `samurai_fish` / `black_tide_shark` / `abyssal_squid` / `tide_lamp` / `ninja_octopus` / `anchor_lord` / `nereion` |
| ⑤ | `frost_claw_raptor` / `vergaron` / `storm_joe` / `oldrex` / `ice_tail_fox` / `glacier_warden` / `wind_ripper` / `greios` / `polar_tricera` / `eldion` |

## 拠点 UI 003_01 Phase A Closeout（2026-07-02 — P3-UI-Base-A）

> Design Brief Phase A 実装完了。headless 検証 PASS。専用 nav/UI フレーム art はオーナー判断で Close。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI-Base-A-1 | **Phase A Closeout** — Hub/MenuGrid 切替・左メニュー7項・下ナビ6タブ・全8画面 `BottomNavHelper` 統一 | `verify_base_hub` / `verify_bottom_nav` / smoke PASS |
| P3-UI-Base-A-2 | **#3 ナビ専用アイコン（ICO_NAV_*）は Close** — 暫定 `IconPaths` 流用のまま維持 | オーナー判断（2026-07-02） |
| P3-UI-Base-A-3 | **#4 拠点 UI フレーム art（MenuRow/Nav_Active/Event）は Close** — 既存 `UI_Btn_*` / `CombatUiFrames` のまま | オーナー判断（2026-07-02） |
| P3-UI-Base-A-4 | **Phase B**（スタミナ・イベント遷移・遺産の間/商人/設定実装）は **別 Decision** まで着手しない | P3-D069-4・Design Brief 分離 |

## モーンゲート難易度カーブ調整（2026-07-02 — P3-D153 / P3-BAL-006）

> バランスハーネス v2（通常攻撃＋装備スキル①②＋回復・CD準拠）で計測。全滅の 87〜100% がボス部屋に集中し、成長式の調整では目標帯（推奨Lv 70〜85% / 推奨−3 20〜40% / 推奨+5 95%+）に到達不能と確認。**案A** をオーナー承認（2026-07-02）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D153-1 | **モーンゲート敵ステ調整** — セルディオン HP 620→250 / ATK 38→15、クロックモス HP 138→124 / ATK 22→20、雑魚4種 HP/ATK ≈×0.9（DEF・EXP・ドロップ据置） | ハーネス v2 計測（各300ラン）: Lv1=22% / Lv3=75% / Lv4=90% / Lv6+=100% で目標帯に合致 |
| P3-D153-2 | **`mourngate.tres` `recommended_level` 1→3**（`enemy_level=1` 据置） | 推奨Lv3 で 70〜85% 帯・推奨−2 で 20〜40% 帯を満たす |
| P3-D153-3 | **レベル成長式は現行値維持**（HP+6/ATK+2 per Lv）。正は `BalanceConfig.HP_PER_LEVEL` / `ATTACK_PER_LEVEL` へ移設（`LevelSystem` は参照） | 成長値スイープの結果、減衰案（HP+4/ATK+1）は推奨Lv帯が 45% に沈み不採用 |
| P3-D153-4 | **Known Issue（別 Decision まで着手しない）** — 戦闘が決定論的（乱数はクリティカルのみ）なため、ステ1〜2点差でクリア率が数十%跳ぶブレークポイント体質。ダメージ±乱数導入は将来検討 | ハーネス計測でプロセス間ばらつきとして観測 |

## ② ウィスパーウッド一式（2026-07-03 — P3-D154 / P3-BETA-001）

> 2本目ダンジョン（Biome-02）実装。敵ステはハーネス v2＋想定装備ティア（②Rare帯: 武器ATK16/防具DEF10/HP+20）で目標帯（P3-D153 と共通）に合わせて導出。オーナー GO（2026-07-03、①〜④一括）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D154-1 | **② 敵6体ステ確定** — モスボア 75/16/4・モスシェル 104/12/12・ブルームサーペント 81/17/5・スポアウィドウ 65/17/4・深霧ワイバーン(E) 169/27/9・グランヴェル(B) 320/21/18（HP/ATK/DEF）。弱点 fire・状態異常は P3-D5DG-004 準拠。グランヴェルに serdion 型3フェーズ＋専用スキル2種、ワイバーンに凍霧ブレス | 検証（各200〜300ラン）: Lv9=40%/Lv12=71〜76%/Lv17=97% で目標帯合致 |
| P3-D154-2 | **whisperwood.tres** — difficulty=2・recommended_level=12・enemy_level=10・floor_count=8・event_room_weight=18・有利属性 fire（「推奨=敵Lv+2」ルールを踏襲） | P3-D5DG-003/004・P3-D153-2 の帯規則 |
| P3-D154-3 | **② 装備20点** — 武器12（◇4/◆4/✦2/★2: 森護王の誓剣シルヴァリア ATK22・翠杖ヴェルドの枝 ATK21）・防具5（DEF7〜14/HP+15〜30・fire/dark/ice 耐性）・装飾3。アイコンは既存流用 placeholder（オーナー作画待ち） | オーナー指定数量（武器10+★2/防具5/装飾3） |
| P3-D154-4 | **ドロップのダンジョン別プール化** — `DungeonData` に `weapon_pool`/`armor_pool`/`accessory_pool` 追加。空はグローバル既定（①現行維持）へフォールバック。防具/装飾もレア度重み抽選に統一 | ② 専用ドロップの前提。①の挙動不変 |
| P3-D154-5 | **既存レジェンダリー再ティア** — 属性武器7本（bolt_knife/ember_fang/frost_blade/glacier_staff/heater_blade/storm_edge/umbral_fang）rarity 3→2（✦）。聖別刃・祝聖の大槌の2本を①の★として維持 | 「各難易度★2」の一貫性（オーナー承認 §3） |
| P3-D154-6 | **ダンジョン切替 UI** — DungeonSelectScene にメインルート切替行を追加（2件以上で表示・選択中は無効化）。解放条件は未実装（全ダンジョン選択可・別 Decision） | ② 到達手段の最小実装 |

## スキル体系の全量確定（2026-07-03 — P3-D155）

> 同規模ゲーム比較（小規模チーム完成形=40〜80本帯）を踏まえ、**全量108本・増枠なし**で確定。オーナー承認（2026-07-03「推奨案で進めてください」）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D155-1 | **全量枠確定** — 通常50（5職×10・実装済/確定）／必殺5（実装済/確定）／武器固定5（+2: holy=sanctal_strike・dark=umbral_strike、④⑤装備と同時実装）／パッシブ25（+11）／敵・ボス23（+12、③〜⑤に同梱） | 同規模比較で標準帯上限。数より1本毎の体感差を優先 |
| P3-D155-2 | **将来の成長軸はスキル追加でなく ★パッシブ拡充と Affix 本格化**（Affix 本格は凍結解除の別 Decision が前提） | ハクスラのビルド深度はアイテム側で稼ぐ定石 |
| P3-D155-3 | **★3/★4 職固有パッシブ 10本＋recon 補完1本を実装**（P3-GACHA-006）— ★3=自己バフ系5・★4=隊全体系5。★1〜2は付与なし（現行踏襲）。★4 は★4定義のみ（★3と重複しない）。ranger ジョブFBを battle_fervor→foresight へ変更。パッシブ heal に self ターゲット＋`heal_value` キー追加 | 現行 DSL（trigger/condition/effect）内で実装・エンジン拡張なし |
| P3-D155-4 | 必殺の覚醒版・第2必殺・6職目以降のスキルは **Phase 4 以降の別 Decision** | スコープ固定 |

## ③ ミストフェン一式（2026-07-03 — P3-D156 / P3-BETA-002）

> 3本目ダンジョン（Biome-03 霧沼）実装。P3-D154 の型で反復。敵ステはハーネス v2＋想定装備ティア（③Rare帯: 武器ATK23/防具DEF15/HP+29）で目標帯（P3-D153 と共通）に合わせて導出。オーナー GO（2026-07-03「ミストフェンを進めてください」）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D156-1 | **③ 敵6体ステ確定** — 吸血ヒル 70/16/4・死毒の大蛙 90/18/6・ミストマンティス 75/19/5・沼地の王 115/14/12・大爪刀(E) 185/29/12・モルドガル(B) 300/21/20（HP/ATK/DEF）。弱点 thunder（ボスは+fire）・状態異常 poison/bleed は P3-D5DG-004 準拠。モルドガルに serdion 型3フェーズ＋専用スキル2種（底なしの顎/深淵の泥濤=dark）、大爪刀に断頭刃、雑魚共用=沼毒の飛沫（大蛙/沼地の王）— 敵スキル+4 は P3-D155-1 の③分 | 検証（200〜300ラン）: Lv19=50%/Lv22=77.7%/Lv27=93% で目標帯合致（初案 moldgar 350/23 は Lv22=60% で HP300/ATK21 へ調整） |
| P3-D156-2 | **mistfen.tres** — difficulty=3・recommended_level=22・enemy_level=20・floor_count=8・event_room_weight=22・有利属性 thunder（「推奨=敵Lv+2」ルール踏襲） | P3-D5DG-003/004・P3-D153-2 の帯規則 |
| P3-D156-3 | **③ 装備20点** — 武器12（◇4/◆4/✦2/★2: 沼王断ちの雷剣ヴォルグレイヴ ATK30・学識王の雷典杖セラディオン ATK29）・防具5（DEF12〜21/HP+22〜45・dark/fire 耐性）・装飾3。雷武器は `static_strike` 固定スキル（既存流用）。アイコンは既存流用 placeholder（オーナー作画待ち） | ② と同数量クォータ（P3-D154-3）。ATK帯は ①→② の伸び率（約+50%）を踏襲 |
| P3-D156-4 | ドロップは `DungeonData.weapon/armor/accessory_pool`（P3-D154-4 機構）へ③専用プール設定。切替 UI は既存（P3-D154-6）が自動追従 | 機構変更なし・データのみ |

## ダメージ±乱数（2026-07-03 — P3-D158 / P3-BAL-008）

> P3-D153-4 Known Issue（決定論戦闘のブレークポイント体質）の解消。オーナー GO（2026-07-03「全て承認します。順番に実装してください」— 承認順1）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D158-1 | **最終ダメージ × [1−v, 1+v] の一様乱数**（`BalanceConfig.DAMAGE_VARIANCE=0.10`・0で無効化可） | ±10%はブレークポイント緩和と計画可能性のバランス点。クリティカルとは独立 |
| P3-D158-2 | **適用点は中央2箇所のみ** — 味方→敵は `DamageCalculator.enemy_mitigation` 最終段（通常/スキル/必殺の全経路が通過・1回だけ）、敵→味方は `enemy_damage_to_member` 最終段。`apply_variance(damage, rng)` は rng 注入可（テスト/シミュ決定論） | 経路散在を避け二重適用を構造的に防止 |
| P3-D158-3 | **再検証で3ダンジョンとも目標帯維持** — ①Lv1=20%/Lv3=72%/Lv6=100%・②Lv9=40%/Lv12=74%/Lv17=97%・③Lv19=49%/Lv22=80%/Lv27=95%（各200ラン） | リチューニング不要を確認 |

## ダンジョン解放条件（2026-07-03 — P3-D157）

> 3ダンジョン化に伴い「Lv3 推奨の新規プレイヤーが Lv22 の③へ入れて即全滅」する導線問題を解消。オーナー GO（2026-07-03 承認順2）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D157-1 | **メインルートは難易度順の直列解放** — difficulty=1 は常時解放・以降は直前難易度のメインをクリアで解放（`GameState.is_dungeon_unlocked`） | 最小で分かりやすい導線。クリアフラグは既存 `mark_dungeon_cleared` 流用 |
| P3-D157-2 | **サブルート等は `DungeonData.unlock_after_dungeon_id`**（空=常時解放・指定ダンジョンのクリアで解放）— サブダンジョン導入（承認順4）の受け皿 | メイン直列と独立した条件式 |
| P3-D157-3 | UI=切替行の未解放ボタンを 🔒＋disabled 化。選択中ダンジョンが未解放を指す場合は解放済みへフォールバック（`_resolve_featured_dungeon_id`） | セーブ互換（旧セーブは①のみ解放から自然継続） |

## ダンジョン別イベント拡充（2026-07-03 — P3-EVT-001）

> ②③のイベントが①用の汎用流用のみで周回の飽きが早い問題への対処。オーナー GO（2026-07-03 承認順3）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-EVT-001-1 | **② 5件・③ 5件の Biome 専用イベント追加** — ②=苔清水(heal10)/木洞の備蓄(gold30)/共生花(buff1.12)/森番の刻印(lore)/梢のささやき(lore)。③=乾いた中州(heal12)/沈んだ革鞄(material)/沼灯り(gold34)/封緘の蝋印(lore)/水浸しの台帳(lore) | ①と同粒度（実利+ロア）。既存 outcome 型のみ使用でエンジン変更なし |
| P3-EVT-001-2 | **`DUNGEON_EVENTS` 辞書化** — `_get_event_pool` の mourngate ハードコードを dungeon_id→Array のテーブル参照へ。④⑤はデータ追加のみで対応 | 反復追加の型化 |
| P3-EVT-001-3 | **LF 断章 4件追加**（`world/12_Fragments.md` v1.2）— ②=森番/口伝系・③=封緘書庫（学識王セラディス）系。真相非開示（§0）維持 | lore イベント本文と Codex「記録」の解析源 |

## 寄り道ダンジョン パイロット（2026-07-03 — P3-D159 / P3-SUB-001）

> P3-D5DG-002 の寄り道 Biome 構想の初実装。Lv12→22（②→③）のレベル帯断絶を埋めるファーム用短編。オーナー GO（2026-07-03 承認順4）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D159-1 | **broken_marsh（崩落街道橋ブロークンマーシュ）** — route_type=side・difficulty=2・推奨Lv16/敵Lv15・floor 6・event_room_weight=25・thunder有利。敵は③の雑魚3種再利用（ヒル/大蛙/マンティス）・ボス=大爪刀（③Elite 転用）・新規アセット0 | P3-D5DG-002-1 の寄り道規模（雑魚2〜3+Boss・部屋6〜8）・P3-D5DG-002 表の「③並行=ブロークンマーシュ」 |
| P3-D159-2 | **解放=②クリア**（`unlock_after_dungeon_id="whisperwood"`・P3-D157-2 機構）。次メイン③の必須ゲートにはしない | P3-D5DG-002-2「スキップ可能な整備場」 |
| P3-D159-3 | **ドロップ=③の◇◆帯のみ**（✦★なし・武器8/防具3/装飾2）— ③初見前の装備整備が役割。イベントは③プール共用 | ✦★は③本編の報酬価値を守る |
| P3-D159-4 | **寄り道の目標帯を新定義** — 解放直後（推奨−3）≈80%・推奨Lv≈90%（メインの 70〜85% より緩い）。検証: Lv13=81.5%/Lv16=91%/Lv20=99% | ファームがウォールになってはいけない |
| P3-D159-5 | **切替UIを main+side 表示へ拡張** — メイン（難易度順）→寄り道（「寄」印・難易度順）。未解放🔒は共通 | P3-D154-6 の行を流用 |

## ④ ブラックショア一式（2026-07-03 — P3-D160 / P3-BETA-003）

> 4本目ダンジョン（Biome-04 沈没航路）実装。P3-D154/D156 の型で反復。敵ステはハーネス v2＋想定装備ティア（④Rare帯: 武器ATK34/防具DEF22/HP+44）で導出。オーナー GO（2026-07-03 承認順5）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D160-1 | **④ 敵6体ステ確定** — 船喰らい 76/16/9・スカルタートル 119/13/18・アンダーテイカー 68/19/5・サムライフィッシュ 84/20/7・ニンジャオクトパス(E) 185/29/13・ネレイオン(B) 347/23/22。弱点 holy（ボスは+thunder）・状態異常 mark/bleed/chill は P3-D5DG-004 準拠。ネレイオンに3フェーズ＋専用スキル2種（潮鳴りの慟哭/ブリーチング）、オクトパスに墨煙、鮫/カジキ共用=潮穿ち（敵スキル+4） | 検証（200ラン）: Lv31=67%/Lv34=78.5%/Lv39=86.5%。※高Lv帯は成長が相対的に薄く曲線が平坦化（+2ATK/Lv の構造）— rec+5=95% は本帯では未達で容認 |
| P3-D160-2 | **blackshore.tres** — difficulty=4・recommended_level=34・enemy_level=32・floor_count=9・event_room_weight=18・有利属性 holy | P3-D5DG-003/004 帯規則 |
| P3-D160-3 | **④ 装備20点** — 武器12（◇4/◆4/✦2/★2: 海統王の潮汐刃ネレイダス ATK44・灯守の聖杖ファロスライト ATK43）・防具5（DEF18〜31/HP+33〜67・ice/dark 耐性）・装飾3。**聖武器固定スキル `sanctal_strike`（サンクトエッジ・armor_break 0.35）を新設**（P3-D155-1 の+1） | ATK帯は③→+約45%踏襲。アイコン流用 placeholder |
| P3-D160-4 | ドロップ=④専用プール（P3-D154-4 機構）。解放=③クリア（メイン直列・P3-D157-1） | 機構変更なし |

## ⑤ フロストリッジ一式（2026-07-03 — P3-D161 / P3-BETA-004）

> 最終5本目ダンジョン（Biome-05 最果て氷裂）実装。メイン5 Biome ロードマップ（P3-D5DG-001）完遂。敵ステはハーネス v2＋想定装備ティア（⑤Rare帯: 武器ATK48/防具DEF31/HP+62）で導出。オーナー GO（2026-07-03 承認順5）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D161-1 | **⑤ 敵6体ステ確定** — 霜爪ラプター 70/16/6・ヴェルガロン 78/17/7・ストームジョー 90/19/9・オルドレクス 124/14/20・グレイオス(E) 185/29/14・エルディオン(B) 300/21/26。弱点 ice（E/Bは+fire）・状態異常 chill/bleed/stun は P3-D5DG-004 準拠。多数が ice 攻撃属性（竜鱗の大盾鎧で軽減可）。エルディオンに3フェーズ＋専用スキル2種（氷河の吐息/氷裂の顎）、グレイオスに鱗粉の白嵐、恐竜2種共用=吹雪の咆哮（敵スキル+4。**P3-D155-1 の敵スキル+12 完遂**） | 検証: 初案 390/25 は Lv47=28.5%（全滅の87%がボス）→ ボス中心に減衰し Lv44=59%/Lv47=71.3%/Lv50=82.3%（300ラン） |
| P3-D161-2 | **frostridge.tres** — difficulty=5・recommended_level=47・enemy_level=45・floor_count=10・event_room_weight=15・有利属性 ice。解放=④クリア | P3-D5DG-003/004 帯規則。Lv上限50のため rec+5 帯は存在せず、キャップ時 82% を終端体験とする |
| P3-D161-3 | **⑤ 装備20点** — 武器12（◇4/◆4/✦2/★2: 始祖竜の氷焔剣エルディオン・ブランド ATK62・終末の闇杖ウンブラ・テルミナス ATK60）・防具5（DEF25〜44/HP+46〜94・ice/dark 耐性）・装飾3。**闇武器固定スキル `umbral_strike`（アンブラエッジ・curse 0.35）を新設**（P3-D155-1 の+2/2 完遂＝武器固定5本体制完成） | 氷武器の固定スキルは既存 `rime_touch` 流用。ATK帯は④→+約40% |
| P3-D161-4 | ドロップ=⑤専用プール。イベントは汎用のみ（⑤専用イベントは別 Task 候補） | ⑤は event_room_weight=15 と最小のため優先度低 |

## ガチャキャラ拡充（2026-07-03 — P3-D162 / P3-GACHA-007）

> 助っ人プール 5→10体（全職2体・★1〜4全帯充実）。立ち絵はオーナー許可により AI 生成（2026-07-03「立ち絵も生成してもらって構いません」）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D162-1 | **新helper 5体** — カイダ（swordsman★2/闘技場崩れ）・シルヴィ（ranger★4/森縁の名射手）・ドランテ（alchemist★1/行商薬師）・ガルム（vanguard★2/元隊商護衛）・ユナ（beast_tamer★4/古龍種調査者・ノースリーチ帰り）。来歴は既存ロア（シーゲート/ウィスパーウッド/ノースリーチ）と接続 | 全5職×2体・レア分布 ★1×2/★2×3/★3×2/★4×3 |
| P3-D162-2 | **固有 passive_id は付けない**（空=ジョブフォールバック＋レア帯パッシブ P3-GACHA-006 が自動適用） | P3-D155 の総スキル数キャップ（パッシブ25）を維持 |
| P3-D162-3 | **立ち絵5枚 AI 生成**（既存 ART_HELPER と同スタイル: 金枠・紺放射背景・ピクセル調バスト・1254px）。プールは `gacha_helpers/` ディレクトリ駆動のためコード変更なし | 機構変更ゼロのデータ+アセット追加 |

> **上書き（2026-07-16 — P3-GACHA-008）:** プールを **6体**（★2×3 / ★3×2 / ★4×1）に縮小。詳細は下記セクション。

---

## ガチャプール縮小（2026-07-16 — P3-GACHA-008）

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-008-1 | **プール6体** — ★2×3 / ★3×2 / ★4×1。★1 はプールから除外 | オーナー指示 |
| P3-GACHA-008-2 | **残す** — ★2=イヴァル/カイダ/ガルム、★3=セリン/ミラ、★4=ヴァルデン | 5職カバー＋既存顔役維持。ヴァンガードのみ★2/★4で二重 |
| P3-GACHA-008-3 | **退避** — レオン/シルヴィ/ドランテ/ユナ → `gacha_helpers/_omitted/`（削除しない） | 旧セーブ同期・再投入余地 |
| P3-GACHA-008-4 | **排出率** — ★2 50% / ★3 35% / ★4 15%（★1 重み0）。還元テーブルは★1残置 | プール実態に合わせて再配分 |
| P3-GACHA-008-5 | **βフラグ** — `GACHA_HELPERS_PLAYABLE=false` は据置 | 再有効化は別 Task |

---

## ガチャ限界突破（2026-07-16 — P3-GACHA-LIMIT-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-LIMIT-001-1 | **案B** — 重複時に限界突破。パッシブ効果が強まる（ステ直加算なし） | オーナー GO |
| P3-GACHA-LIMIT-001-2 | **対象** — ガチャ助っ人のみ。スターター5は対象外 | ガチャ差別化 |
| P3-GACHA-LIMIT-001-3 | **上限 +5** — `owned_helpers` 所持数−1＝凸。6以上は効果頭打ち | インフレ抑制 |
| P3-GACHA-LIMIT-001-4 | **強化** — 凸ごと効果量 ×(1+0.1N)。固有 `passive_id` ＋ ★3/★4 帯パッシブ。ジョブ基礎は対象外 | 案Bの素直実装 |
| P3-GACHA-LIMIT-001-5 | **還元半減** — ★2→1 / ★3→2 / ★4→4（上限後も還元維持） | 石枯渇回避 |
| P3-GACHA-LIMIT-001-6 | **カイダ／ガルム** — 空欄だった固有パッシブを付与（与ダメ+6%／被ダメ-6%） | ★2も凸対象にするため |
| P3-GACHA-LIMIT-001-7 | **表示** — 召喚結果・ラインナップ・装備画面名に「限界突破 +N」 | 成長の可視化 |
| P3-GACHA-LIMIT-001-8 | **β** — `GACHA_HELPERS_PLAYABLE=false` 据置。再有効化時に体験可能 | 現行スコープ |

---

## ガチャ世界観コピー（2026-07-16 — P3-GACHA-COPY-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-COPY-001-1 | **画面タイトル** — 「ギルドへの招待状」。キャッチ「各地の探索者へ、ギルドからの招き」 | オーナー GO（召喚→招待状） |
| P3-GACHA-COPY-001-2 | **ボタン** — 1回「招待状を開く」／10連「束ねた招待状」（準備中ツールチップ） | 同上 |
| P3-GACHA-COPY-001-3 | **タブ** — 特達招待／推薦状／通常招待（前2つは準備中ロック維持） | 同上 |
| P3-GACHA-COPY-001-4 | **ラインナップ／天井／結果** — 「招きの候補」／「確実な招きまで ○/30」／新規「招きに応じた」・重複「重ねた推薦」 | 同上 |
| P3-GACHA-COPY-001-5 | **下ナビ短名** — 「招待状」。魔晶石の表示名は据置 | 同上 |
| P3-GACHA-COPY-001-6 | **リボン** — 「★3以上1名確定」。図鑑手引きも招待状語彙＋限界突破説明に同期 | 同上 |

---

## 招待状開封リビール（2026-07-16 — P3-GACHA-REVEAL-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-REVEAL-001-1 | **演出フロー** — 封緘→開封（琥珀光）→肖像顕現→文言。旧「魔晶石フラッシュ」主軸を置き換え | モック GO（案B簡略） |
| P3-GACHA-REVEAL-001-2 | **レア差** — ★2短／★3中／★4長＋Glow強。★2は鉄色封の封書テクスチャ | 陳腐な虹演出を避け「封の格」で差 |
| P3-GACHA-REVEAL-001-3 | **スキップ** — 演出中タップで最終状態へ。完了後タップで閉じる | テンポ維持 |
| P3-GACHA-REVEAL-001-4 | **アセット** — `UI_Gacha_Invite_*` 手続き生成＋`GachaRevealPresenter`。10連フル演出は対象外 | メンテ容易 |
| P3-GACHA-REVEAL-001-5 | **β** — `GACHA_HELPERS_PLAYABLE=false` 据置。再有効化時に体験 | スコープ分離 |
| P3-GACHA-REVEAL-001-6 | **見た目 polish** — AI 生成封書をクロマキー処理し `UI_Gacha_Invite_*` を差し替え。手続き生成はフォールバック／再生成用 | モック級質感 |

---

## UI ビジュアル強化・はみ出し修正（2026-07-03 — P3-UI3-001）

> モック準拠のフォント・金飾・アイコン・背景を適用し、`tools/ui_audit.gd`（実レンダリングでの自動スクリーンショット監査）で全ハブ7画面のはみ出しを検出・修正。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI3-001-1 | **見出しフォントを Shippori Mincho B1 Bold（OFL）に変更**。三層構成: 本文 Noto Sans JP / 見出し・タイトル Shippori Mincho / 戦闘数字 DelaGothicOne（`UiTypography.impact_font()` 新設） | モックの金セリフ見出しに一致。戦闘演出のインパクトは Dela Gothic を維持 |
| P3-UI3-001-2 | **画面タイトルに「✦ 〜 ✦」金飾**（`UiTypography.apply_screen_title` / `decorate_title_text`）。ハブ6画面＋リザルトに適用 | モックのヘッダー装飾を再現。多重適用ガードあり |
| P3-UI3-001-3 | **下ナビ実体化** — `BOTTOM_NAV_ENTRIES` を実シーンノード（NavHome/NavParty/NavAdventure/NavForge/NavShop/NavMenu）と 1:1 化（NavShop=召喚所・NavMenu=図鑑）。金アイコン8種（ナビ7+設定）を AI 生成し `assets/ui/nav/` に復旧（旧 PNG はソース欠損） | 旧定義は不在ノード参照で NavShop/NavMenu が未配線・無装飾だった |
| P3-UI3-001-4 | **はみ出し修正**: ①ダンジョン切替行を HFlowContainer 化（6ダンジョンで横幅超過しリスト全体が画面外へ広がる致命バグ）②Roster スクリプトのノードパス不整合修正（ActivePartyScroll/ListHeader — 画面が全損状態だった）③下部コンテンツのナビ重なり解消（実ナビ高 ~76px に対し余白 52px しかなかった全6画面 + ホームのデイリーパネル）④鍛冶屋タブ行の行高不足による重なり解消 ⑤図鑑/召喚所リストの端数行切れ調整 | `tools/ui_audit.gd` のスクリーンショットで実測検証 |
| P3-UI3-001-5 | **背景3枚生成**（鍛冶屋=UI_BG_Forge・召喚所=UI_BG_Summon・図鑑=UI_BG_Codex、720x1280・暗トーン）、**ダンジョンサムネ5枚生成**（whisperwood/mistfen/broken_marsh/blackshore/frostridge — mourngate と同スタイル）し IconPaths `dungeon:` に登録 | ②〜⑤とサイドはサムネ未設定でボスアイコン代用だった |
| P3-UI3-001-6 | **ホーム CurrencyStrip を実データ5列で実装**（ゴールド/魔晶石/冒険者/踏破/発見） | 空 PanelContainer が無内容のまま描画されていた |

## UI 監査 — 戦闘・リザルト編（2026-07-03 — P3-UI3-002）

> `tools/ui_audit_run.gd` 新設: DungeonScene を実走し複数時点（intro/early/mid/late）でスクショ、`last_run_*` を投入して ResultScene（clear/wipe 両方）を撮影。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI3-002-1 | **戦闘ヘッダー2ラベルに clip+ellipsis**（LabelDungeonName / LabelRoom）。長ダンジョン名でヘッダー最小幅が 763px と 720px を超過し、**戦闘UI全体（ログ・パーティカード・一時停止）が左右にはみ出す**根本原因だった | 実測: MainVBox min 763→510。「王都地下モーンゲート」+ 天候サフィックスで Mincho 化後に顕在化 |
| P3-UI3-002-2 | リザルト（clear/wipe）は監査で問題なし。✦金飾タイトルは `decorate_title_text` 適用済み | — |

## 装備クォータ補充 + アセット配線（2026-07-03 — P3-BAL-007）

| # | 決定 | 根拠 |
|---|---|---|
| P3-BAL-007-1 | ①難易度帯の装備クォータ不足を **新規5件**（防具3/装飾2）で補充。`mourngate` / `astoria_ruins` プールを更新 | 各難易度 防具5/装飾3 の設計目標 |
| P3-BAL-007-2 | 敵戦闘スプライトは **図鑑肖像→96×14シート** のプロシージャル生成で全30敵配線（モーンゲート既存5シートは流用） | 本番ドット待ちの間の暫定表示 |
| P3-BAL-007-3 | スキルアイコンは **実装81スキル全件** をプロシージャル生成し `IconPaths` を一括同期 | MVP 20枚のみでは UI 欠損 |
| P3-BAL-007-4 | `verify_icon_paths.py` で enemy/weapon/armor/accessory/material/skill/dungeon を機械検証 | 手動登録漏れ防止 |

## UI 監査 — 拠点画面編（2026-07-03 — P3-UI3-003）

> `tools/ui_audit.gd` 拡張: 図鑑7タブ個別スクショ。実測で拠点画面のはみ出し・重なりを修正。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI3-003-1 | 図鑑 **TabRow を HFlowContainer + 13px** に変更。7タブが 720px を超え歴史/記録/手引きが画面外に消えていた | `ui_audit` codex.png で4タブのみ表示 |
| P3-UI3-003-2 | 図鑑詳細名 **clip+ellipsis** | 長名称の横はみ出し防止 |
| P3-UI3-003-3 | DG選択 **FooterPanel（スタミナ占位）を非表示**、階層リスト `offset_bottom` を -176→-92 に拡大 | B3F 以降が占位パネルに隠れる。P3-UI2-029 占位は Decision まで温存しつつ UI から除去 |
| P3-UI3-003-4 | 召喚所の **単発/購入ボタンを SummonActionBar に固定**（ナビ直上）。ラインナップ Scroll と重ならない | 10体ラインナップでボタンがリストと視覚競合 |

## 期間限定バフイベント（2026-07-03 — P3-EVT-HUB / P3-D163）

> ソシャゲ型の週次キャンペーン＝探索中の経済バフ。デイリーミッション（P3-DAILY）とは別系統。オーナー GO（2026-07-03）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D163-1 | **週次バフ3種をローテ** — `exp`（戦闘EXP）/ `gold`（戦闘Gold）/ `weapon_drop`（撃破時武器直ドロップ率）。各 ×1.5・約7日間 | 通常プレイのまま恩恵。ミッション受取型は採用しない |
| P3-D163-2 | **端末日付 + JST 5:00 境界**（`EventScheduleHelper`・デイリーと同型）。`EventData.start_date_jst` / `end_date_jst` で `resources/events/*.tres` 追加のみで運用 | 個人タイマーではなく全員同じカレンダー |
| P3-D163-3 | **デイリーと完全分離** — `DailyMissionSystem` / `EventSystem` 別 autoload。イベント進捗のセーブ永続化なし | 役割の二重化を避ける |
| P3-D163-4 | **配線** — EXP/Gold=`DungeonScene` 撃破報酬・武器=`DungeonController.roll_kill_weapon_drop`。ログ `[イベント]` | 既存フックに乗せる最小差分 |
| P3-D163-5 | **スコープ外** — ダンジョン内 EVENT 部屋 UI 拡張・イベント専用 DG・10連ガチャ | P3-D070 フルオート維持 |

## 同一ダンジョン危険度ティア（2026-07-03 — P3-DG-TIER / P3-D164）

> Diablo 型の同一マップ難易度切替。オーナー GO: D1=3段 / D2=前ティアクリア解放 / D3=レア重み倍率 / D4・D5=Lv99は後続。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D164-1 | **ティア3段** — ノーマル(T0) / ハード(T1) / ナイトメア(T2)。`DungeonData.difficulty`（Biome★）とは別軸 | P3-UI2-021-2 の実装化 |
| P3-D164-2 | **解放=当該DGで前ティアクリア**（T0常時・T1←T0・T2←T1） | オーナー D2=A |
| P3-D164-3 | **効果** — 敵Lv +0/+3/+6、レア重み ×1.0/×1.3/×1.6、EXP/Gold ×1.0/×1.2/×1.4 | D3=A・P3-D081 敵Lvに加算 |
| P3-D164-4 | **次Biome解放はノーマルクリアのみ**（`mark_dungeon_cleared` は T0 のみ） | 導線維持（P3-D157） |
| P3-D164-5 | **Lv上限99は P3-LV-099 で後続**（D4=A・D5=A） | ティア先行 |

### キャンペーン周回帯へ再定義（2026-07-14 — P3-DG-TIER-002）

> **オーナー GO** — Hard はノーマル全クリア後。**H1-1 > N5-5**、**NM1-1 > H5-5**。βプレイ範囲外だが実装は本決定で正とする（P3-D164-2/3 を上書き）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-TIER-002-1 | **解放** — Hard＝メイン5 Biome のノーマル全クリア。Nightmare＝メイン5 のハード全クリア。当該DG前ティア解放は廃止 | 周回帯の階段 |
| P3-DG-TIER-002-2 | **敵Lvボーナス** — Hard = `main_normal_cap`（N5-5=49）、Nightmare = `2×cap`（98）。章ベースLvに加算 | H1-1=50>49、NM1-1=99>H5-5=98 |
| P3-DG-TIER-002-3 | **cap 導出** — メイン5の stage `enemy_level` 最大値（`DungeonTierConfig.main_normal_cap_level`） | ステージ改訂に追従 |
| P3-DG-TIER-002-4 | **レア／報酬倍率は据置** — ×1.3/×1.6・×1.2/×1.4 | P3-D164-3 の非Lv部維持 |
| P3-DG-TIER-002-5 | **β** — ②〜⑤封鎖中は Hard/NM 解禁条件を満たせない＝β体験外（ノーマル①がβ本体） | オーナー「β範囲外」 |

## レベル上限99（2026-07-03 — P3-LV-099 / P3-D165）

> オーナー GO（D4=A・D5=A）。危険度ティア（P3-D164）完了後に実装。

| # | 決定 | 根拠 |
|---|---|---|
| P3-D165-1 | **上限 Lv99**（`LevelSystem.MAX_LEVEL` / `BalanceConfig.MAX_PLAYER_LEVEL`） | エンドゲーム周回の伸びしろ |
| P3-D165-2 | **Lv1〜50 成長据置** — +6HP/+2ATK per Lv（P3-SKILL-001 と整合） | 既存バランス・習得10本の前提を維持 |
| P3-D165-3 | **Lv51〜99 逓減成長** — +3HP/+1ATK per Lv。**新スキル習得なし**（`skill_unlocks` は Lv50 まで） | B1 案。コンテンツ追加なしで上限拡張 |
| P3-D165-4 | **EXP 曲線は据置** — `exp_to_next = 100×Lv`、上限到達で EXP 0 固定 | 最小差分 |

## 遍在希少種（放浪個体）（2026-07-03 — P3-WANDER-001 / P3-D166）

| ID | 決定 | 理由 |
|---|---|---|
| P3-D166-1 | **COMBAT 部屋に低確率差し込み**（遠旅スズメ 2.5% / 聖遺甲虫 1.5%）。ELITE 枠は奪わない | 全 Biome 共通のサプライズ。Biome プールは温存 |
| P3-D166-2 | **遠旅スズメ** — 脆い・高 EXP（基準雑魚の約8倍）・武器0%・**3 回行動後逃走**（報酬なし） | メタルスライム型育成ピンチ |
| P3-D166-3 | **聖遺甲虫** — ELITE 級ステ・**武器撃破 85%**・レア重み ★2〜3 寄り（10/20/45/25） | レア武器ハント型 |
| P3-D166-4 | `EnemyData.is_wandering` / `weapon_drop_chance` / `weapon_rarity_weights` / `wander_flee_after_turns`。SSOT=`WanderingEnemyConfig.gd` | データ駆動・dungeon 別プール不要 |

## 遍在希少種差し替え（2026-07-19 — P3-WANDER-002）

> オーナー GO: スズメ／甲虫をコズミックダック／宝冠レイヴンへ置き換え。推奨値採用。

| # | 決定 | 根拠 |
|---|---|---|
| P3-WANDER-002-1 | **差し替え** — `cosmic_duck`（旧 wayfarer_sparrow）／`crown_raven`（旧 reliquary_beetle）。出現率 2.5% / 1.5% 据置 | 役割維持・枠数据置 |
| P3-WANDER-002-2 | **コズミックダック** — 高EXP（100）・装備ドロップ0・**3行動後逃走** | スズメ後継の育成ピンチ |
| P3-WANDER-002-3 | **宝冠レイヴンC** — 撃破85%で武器40%/防具35%/装飾25%。レア重み 10/20/40/30。逃走なし | レア装備ハント（武器以外含む） |
| P3-WANDER-002-4 | `EnemyData.equip_category_weights` ＋ `roll_kill_equip_drop` | 既存武器経路を拡張 |
| P3-WANDER-002-5 | **旧IDエイリアス** — DataRegistry／図鑑記録／セーブ v7 で新IDへマージ | セーブ破壊回避 |
| P3-WANDER-002-6 | ドットはプレースホルダ（後差し替え） | アート準備中 |
| P3-WANDER-002-7 | **伝説＋神話** — レイヴンは伝説装備をプールに補完。神話はドロップ成功時 1% 別枠（`MythicLoot`） | オーナー指示 |

**Closeout（2026-07-19）:** データ＋配線＋unit。

## ペット・オトモ制（2026-07-19 — P3-PET-OTOMO-001）

> オーナー GO: 推奨値すべて採用。入手＝ストーリー。陣形外・常時前衛。実装はアップデート枠（β後可）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-PET-OTOMO-001-1 | **職ではない随伴オトモ**。ビーストテイマーと **別系統** | 「ペット職」だと薄い6職＋BT衝突 |
| P3-PET-OTOMO-001-2 | 戦闘は **人間編成4の外＝5体目**。`ACTIVE_PARTY_SIZE=4` は不変 | オトモ感を維持 |
| P3-PET-OTOMO-001-3 | **装備不可**・**★1固定**・**パッシブなし**（進化特性もなし）・能力は低め | ビルド対象にしない |
| P3-PET-OTOMO-001-4 | 育成は **人間並み**（共有EXP・Lv）。スキルは **基本攻撃＋2本程度** | 成長の手触りだけ残す |
| P3-PET-OTOMO-001-5 | **自動AIのみ**。全滅判定 **対象外**（人間全滅で敗北） | イベント助っ人に近いリスク |
| P3-PET-OTOMO-001-6 | 所持は複数可・**出撃は常時1体**。敵から **低Threatで狙われうる** | コレクション＋戦場の存在感 |
| P3-PET-OTOMO-001-7 | **陣形システム対象外**。配置は **常に前衛**（固定スロット） | 陣形UIを増やさない |
| P3-PET-OTOMO-001-8 | **入手はストーリーのみ**（ガチャ・ドロップに載せない） | 招待状と混線しない |
| P3-PET-OTOMO-001-9 | 実装レーンは **アップデート枠**（β必須ではない） | β通しを優先 |
| P3-PET-OTOMO-001-10 | 初期実装の個体数は **1体のみ**（複数所持の枠は後拡張） | オーナー追記 |
| P3-PET-OTOMO-001-11 | **ドット絵は後差し**（実装時はプレースホルダ可） | アート後追い |
| P3-PET-OTOMO-001-12 | 初期個体名 **ジャック**（id 仮: `pet_jack`） | オーナー指定 |
| P3-PET-OTOMO-001-13 | **ニューゲーム開始時から初期パーティに随伴**（人間4枠外のオトモ枠）。途中ストーリー解放ではない | オーナー指定 |

**Closeout（2026-07-19）:** ジャック実装。NG開始時随伴・セーブ v9・戦闘5体目（前衛固定）・プレースホルダドット。

## BTオトモ連携スキル／パッシブ（2026-07-19 — P3-BT-PET-LINK-001）

> オーナー GO: 推奨値すべて。スキル3本差し替え＋`herd_call`改修、ミレイ／職FBをペット寄せ。

| # | 決定 | 根拠 |
|---|---|---|
| P3-BT-PET-LINK-001-1 | Lv6=`pet_bond_rally`（相棒鼓舞）／Lv48=`pet_command_fang`（指揮の牙）／Lv50=`pet_bond_guard`（絆の守り） | ペット強化を混ぜる |
| P3-BT-PET-LINK-001-2 | `herd_call`→**群れの號令** — オトモ本鼓舞＋他味方は弱い鼓舞 | 既存枠の意味付け |
| P3-BT-PET-LINK-001-3 | ミレイ固有→**相棒共鳴**（オトモ与ダメ+20%） | 案A |
| P3-BT-PET-LINK-001-4 | 職FB `pack_instinct`→**群れの指揮**（オトモ与ダメ+10%） | 案A・ミレイより弱 |
| P3-BT-PET-LINK-001-5 | ミラ固有・★帯データは据置 | スコープ外 |

**Closeout（2026-07-19）:** データ＋戦闘配線＋unit。

## 招待状 Featured Idle プレビュー（2026-07-19 — P3-GACHA-FEATURE-IDLE-001）

> オーナー GO: 案A（大 idle 左＋ステ右）。3アイコンカルーセル廃止。

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-FEATURE-IDLE-001-1 | **1体表示** — 大 CHR Idle 左／名前・★・職・HP/ATK/DEF・固有1行を右 | 候補の戦力感を一目で伝える |
| P3-GACHA-FEATURE-IDLE-001-2 | 対象は現行プールの **★4→★3のみ**（★2非表示） | Featured は高レア訴求 |
| P3-GACHA-FEATURE-IDLE-001-3 | 自動 **5秒**回転・クロスフェード0.3s・タップで次へ。召喚リビール中は一時停止 | バナー領域の単調さ回避 |
| P3-GACHA-FEATURE-IDLE-001-4 | 確率キャッチコピー／確率詳細オーバーレイは維持 | 既存導線を壊さない |

**Closeout（2026-07-19）:** UI＋unit。

## 天候シンクロ・レジェンド武器（2026-07-19 — P3-EQ-WEATHER-LEG-001）

> オーナー GO: 案A（雨・夜・霧の3本）。晴れ専用は作らない。

| # | 決定 | 根拠 |
|---|---|---|
| P3-EQ-WEATHER-LEG-001-1 | **3本** — 雨=`stormveil_needle`／夜=`noctumbra_fang`／霧=`mistpierce_halberd` | 天候出現15%帯に意味を持たせる |
| P3-EQ-WEATHER-LEG-001-2 | **雨** — 常時雷+15%、雨時雷+40% | 既存雨の雷補正と相乗 |
| P3-EQ-WEATHER-LEG-001-3 | **夜** — 常時闇+15%、夜時闇+40%＋撃破CT短縮50% | 夜の闇補正＋テンポ |
| P3-EQ-WEATHER-LEG-001-4 | **霧** — 常時会心+3%、霧時 outgoing×1.263（罰則打消+20%）＋会心+10% | 属性無し霧の差別化 |
| P3-EQ-WEATHER-LEG-001-5 | SSOT=`weather_bonus` on `CombatPassives`・入手=レイヴン伝説プール／mourngate・rookery 武器プール | 新規ドロップ経路最小 |

**Closeout（2026-07-19）:** データ＋配線＋unit。

## 宝冠レイヴン日次イベントDG（2026-07-19 — P3-DG-RAVEN-EVENT-001）

> オーナー GO: ダック版と同型のカラス版。装備ハント向けに戦闘寄り。

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-RAVEN-EVENT-001-1 | **`crown_rookery`（宝冠レイヴンの巣）** — event・5F・Bossなし・日1回 | ダック版の対 |
| P3-DG-RAVEN-EVENT-001-2 | **敵は `crown_raven` のみ**・放浪無効・群れ 8%（2〜3体） | レイヴンは硬めのため群れ低め |
| P3-DG-RAVEN-EVENT-001-3 | **部屋** — COMBAT50 / TRAP20 / treasure15 / heal10 / lore5 | 装備ドロップ機会優先 |
| P3-DG-RAVEN-EVENT-001-4 | 日次枠は `cosmic_rift` と **別カウント** | 両方一日1回ずつ |
| P3-DG-RAVEN-EVENT-001-5 | 武器/防具/装飾プールはモーンゲート帯流用（伝説・神話は既存レイヴン経路） | 新規アセット0 |

**Closeout（2026-07-19）:** データ＋unit。

## イベントDGサブステージ共通化（2026-07-21 — P3-DG-EVENT-STG-001）

> オーナー指示: イベントもメイン同様、バナークリックで下にサブダンジョン名を並べて選択突入。ダンジョン共通ルール化。コズミックダック／宝冠レイヴンにサブ章を追加。  
> **追記（同日）:** オーナー指示でイベントは **各1章のみ**（5章は不要）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-EVENT-STG-001-1 | **共通ルール** — `SUB_STAGES_PLAYABLE` かつ章データがある Biome は **route_type を問わず** バナー展開＋章カード（`_uses_stage_cards`） | メイン専用ガードを撤廃 |
| P3-DG-EVENT-STG-001-2 | **`cosmic_rift` / `crown_rookery` 各 1 章** — `*_1_1` のみ・Boss なし（`closing_type=exit`）・日次1回は Biome 単位据置 | バナー→1章ダンジョン。クリアで Biome CLEAR |
| P3-DG-EVENT-STG-001-3 | **ダック章** — `cosmic_rift_1_1`＝コズミックダックの裂け目（5F・敵Lv3・推奨Lv5） | 旧単体DG相当 |
| P3-DG-EVENT-STG-001-4 | **レイヴン章** — `crown_rookery_1_1`＝宝冠レイヴンの巣（5F・敵Lv10・推奨Lv12） | 旧単体DG相当 |
| P3-DG-EVENT-STG-001-5 | 章クリックで確認→突入（既存 `_on_stage_card_pressed`）。敵プール／部屋重み／日次枠は Biome `DungeonData` 継承 | 新規アセット0 |

**Closeout（2026-07-21）:** データ＋UI共通化＋unit（各1章に縮小）。

## コズミックダック日次イベントDG（2026-07-19 — P3-DG-DUCK-EVENT-001）

> オーナー GO: ダック専用・5F・罠多め・稀に群れ・一日1回。イベントタブへ掲載。

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-DUCK-EVENT-001-1 | **`cosmic_rift`（コズミックダックの裂け目）** — `route_type=event`・5F・Bossなし | 育成ピンチ用短編 |
| P3-DG-DUCK-EVENT-001-2 | **敵は `cosmic_duck` のみ**・`disable_wandering`・`forced_swarm_chance=12%`（2〜3体） | 要望どおり |
| P3-DG-DUCK-EVENT-001-3 | **部屋重み** — TRAP45 / COMBAT30 / lore10 / treasure10 / heal5 / elite0 | 罠多め |
| P3-DG-DUCK-EVENT-001-4 | **日次1回** — JST5:00 リセット・出発時消費（失敗も消費）・セーブ v8 | 日課と同型 |
| P3-DG-DUCK-EVENT-001-5 | **UI** — イベントダンジョンタブ。Hard/NM なし。βでも選択可（`EVENT_DUNGEONS_PLAYABLE`） | プレースホルダ解消 |
| P3-DG-DUCK-EVENT-001-6 | 装備ドロップなし（ダック仕様据置）。クリア金は軽め（通常経路） | 報酬はEXP主 |

**Closeout（2026-07-19）:** データ＋配線＋unit。

## 罠ダメージ割合化＋全体パターン（2026-07-19 — P3-TRAP-PCT-001）

> オーナー GO: 固定ダメ廃止→最大HP割合。全体被弾パターン追加。

| # | 決定 | 根拠 |
|---|---|---|
| P3-TRAP-PCT-001-1 | **割合** — 対象の `party_max_hp` に対する％ダメージ（最低1） | ステータススケール後も相対脅威を維持 |
| P3-TRAP-PCT-001-2 | **単体** — 探索 10% / 罠部屋 15% | 旧 flat≈序盤HP比に相当 |
| P3-TRAP-PCT-001-3 | **全体** — 発動時 35% で全体。探索 5% / 部屋 8%（各員） | 単体より低め・全滅リスク抑制 |
| P3-TRAP-PCT-001-4 | SSOT=`BalanceConfig` / `ExplorationSkills`・配線=`DungeonScene`・イヴァル免疫は据置 | 既存解除・演出と両立 |

**Closeout（2026-07-19）:** Config＋配線＋unit。

## 遍在希少種・周回帯出現率（2026-07-19 — P3-WANDER-003）

> オーナー GO: 全ダンジョン出現は維持。出現率は周回難易度（N/H/NM）で上昇（案A）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-WANDER-003-1 | **ダンジョン制限なし** — COMBAT 差し込みは全 DG 共通（据置） | 遍在の意図 |
| P3-WANDER-003-2 | **基準率** — ダック 2.5% / レイヴン 1.5%（ノーマル） | 既存据置 |
| P3-WANDER-003-3 | **倍率** — `DungeonTierConfig.rarity_weight_mult` と同型（N×1.0 / H×1.3 / NM×1.6） | レア装備曲線と整合 |
| P3-WANDER-003-4 | SSOT=`WanderingEnemyConfig`・配線=`try_pick_wandering_enemy`（`GameState.current_dungeon_tier`） | データ駆動 |

**Closeout（2026-07-19）:** Config＋unit。

## 昇格特質（2026-07-03 — P3-EVO-TRAIT-001 / P3-D167）

| ID | 決定 | 理由 |
|---|---|---|
| P3-D167-1 | **進化必要 Lv を 10→30 に引上げ**（`JobData.evolution_level` 全5職） | Lv99 環境での中盤マイルストーン |
| P3-D167-2 | **昇格特質＝常時倍率10本**（職×2）。`CombatPassives`（トリガー型25本）とは別カテゴリ | P3-D155 枠を侵食しない |
| P3-D167-3 | **解放＝進化認定と同時・固定2つ自動**（二択なし） | MVP最小・意図明確 |
| P3-D167-4 | ドロップ/EXP 特質は**編成中パーティ全体**に恩恵（レンジャー/ビーストテイマー） | 共有報酬モデルと整合 |
| P3-D167-5 | SSOT=`EvolutionTraits.gd`・フック=`CombatController`/`DamageCalculator`/`DungeonController`/`DungeonScene` | 遺物と同型の中央倍率 |

## ダンジョン選択 UI 再構成（2026-07-04 — P3-UI-DG-001 / P3-D168）

| ID | 決定 | 理由 |
|---|---|---|
| P3-D168-1 | **案C** — Featured=選択Biome概要+「選択して出発」、一覧=メインBiome直列+寄り道セクション | モック整合・P3-D157解放と両立 |
| P3-D168-2 | **階層 B1F〜一覧・HFlow切替行を撤去**（1 Biome=1探索のまま） |  floor 別出発は Phase2 |
| P3-D168-3 | **Header スタミナ非表示維持**（P3-BETA-001b） | 既存 Decision 尊重 |
| P3-D168-4 | **Footer=EventSystem のみ実データ**（日次挑戦/特別報酬は非表示） | 承認どおり占位排除 |
| P3-D168-5 | カード「選択」=出発、サムネ/情報タップ=Featured プレビュー切替 | モック操作感 |

## 調査地ロードマップ SSOT 化（2026-07-03 — P3-LORE-006）

> ブレインストーム（16マップ候補・三層モデル・Top5・意図的非ダンジョン）を `world/` へ正式反映。実装コミットではない（候補の正典化のみ）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-LORE-006-1 | **三層モデルを SSOT 化** — `main` / `side` / `apex`（`05_Biomes §2.1`）。P3-D5DG-002 の二層を征討で拡張。apex は次メイン解放に **影響しない** | P3-LORE-005 実装済8本と整合 |
| P3-LORE-006-2 | **Biome-06〜08 を候補確定**（未実装）— ⑥レッドフォージ（熱適応・鍛冶王）／⑦ストームクラウン（高所適応・守護王）／⑧アイゼンプレイン（開放地適応・信義王）。詳細 `05_Biomes §6` | P3-D5DG-001-2 温存の具体化 |
| P3-LORE-006-3 | **将来候補16件を Tier A〜E で列挙**（`07_Geography §4.5`）。征討先行実装分（storm_crown / red_ridge / thunder_peak / red_forge_depths / blackshore_abyss）は候補表に **実装済み** と明記 | 地理正典とコードの二重管理を解消 |
| P3-LORE-006-4 | **意図的非ダンジョン3件** — 灯火の守り手／第二の巨木／アイアンヘイブン本体（`07 §4.4`）。永久未確定主題・拠点は DG 化しない | P3-D043 / `10_LoreDelivery §9` |
| P3-LORE-006-5 | **Top5 推奨**（HQ案・オーナー GO 前）— ①Biome-06 ②Biome-07 ③アステリア地上回廊 ④シーゲート地下港 ⑤Biome-08（`07 §4.6`） | メイン5完遂後の着手順ガイド |
| P3-LORE-006-6 | **白王の神殿** — 調査型候補。討伐 Boss 非推奨（Tier E #15） | 信仰・先王時代は「問い」として温存 |

**スコープ外:** 候補16件の一括実装・Biome-06 生態詳細・新 id 確定 — 個別 Task で Decision 後に着手。

## 戦闘可読性 UX 段1（2026-07-06 — P3-UX-002）

> オーナー承認: 提案バンドル **E+F+G**（D 演出横展開は後続）。Alpha=観察ゲームのまま「今・次・なぜ」を補う。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-002-1 | **E — Now Playing 帯** — 戦闘フロア中 `NarrativePanel` を 1 行サマリーに転用（味方=◆ / 敵=⚠・詠唱残 tick 表示）。非戦闘は従来ナラティブ | 「戦闘中何をしているか分からない」への直接対応。新規 UI ノードなし |
| P3-UX-002-2 | **F — 戦術ログ** — 味方行動時 `[戦術] 条件 → スロット`（`CombatGambit.condition_summary`）。全不発=「不発→通常攻撃」/ 条件0件=「条件未達→通常攻撃」 | 戦術プランが裏側のみだったギャップ解消 |
| P3-UX-002-3 | **G — ターン順バッジ** — CT 順アイコン下に 攻/技/必/防/詠n（pending cast・戦術プレビュー） | 次行动者の行動種別をログ不要で把握 |
| P3-UX-002-4 | **スコープ外（段2以降）** — I ログ束ね / J 状態レーン / K スマート速度 | 段1 実機評価後に Task 化 |
| P3-UX-002-D | **演出横展開（D）** — 敵詠唱=ThreatBanner+vignette+pulse・開始時 flash/shake / 味方 HP≤25%=赤枠+「瀕死」pulse / 必殺 ready=金枠+「必殺」バッジ / CRITICAL・大ダメ(≥100)=画面 shake+flash（クールダウン付） | 段1と同バンドルでオーナー GO。新規アセット0 |

## 潜入演出（2026-07-06 — P3-UX-003）

> オーナー承認: A〜E 全件・順次実装。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-003-A | **潜入イントロ** — DG開始時1回: 暗転→サムネ+名称+メタ+「探索開始」。`_start_auto_progress` は完了まで停止。タップ/クリックでスキップ可 | 入場の「一幕」 |
| P3-UX-003-B | **部屋種別トランジション** — フェード→`_advance_to_next_room`→種別FX（戦闘=剪影/宝箱=金粒子/罠=赤/回復=緑/出口=青/ボス=枠pulse）→部屋名キャプション | 毎フロアの変化 |
| P3-UX-003-C | **Biome 入場** — A に `flavor_text`+パーティアイコン列フェードインを同梱（`DungeonData` SSOT） | 選択画面 Featured と整合 |
| P3-UX-003-D | **パーティ登場** — 戦闘開始 `_show_chr_sprites(true)`: 前衛即/後衛遅延スライド+fade。ELITE/BOSS=軽 shake | 戦闘開始の体感 |
| P3-UX-003-E | **ランHUD** — Header 下に 部屋 n/N バー + 種別チップ + 発見率%。図鑑登録で更新 | 探索進行の常時可視化 |

## ボス登場演出（2026-07-06 — P3-UX-004）

> オーナー承認: 毎回フル / 表記 `WARNING` / 周回は短縮版。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-004-1 | **毎回フル** — ボス戦開始: 赤 `WARNING` テロップ → 画面 shake+flash → Biome 色落石 → ボス pop（scale+fade）→ ログ → `CombatTimer` 開始。演出中 `_boss_intro_active` で自動進行停止 | ボス戦の特別感 |
| P3-UX-004-2 | **表記 `WARNING`** — `BOSS_INTRO_WARNING_TEXT` 固定。`UiTypography` 赤+強アウトライン | オーナー指定 |
| P3-UX-004-3 | **周回短縮** — `_fast_run_enabled` 時 `_boss_intro_timings(true)`: 表示時間・粒子数・shake 弱体化。スキップ不可（段1） | 周回テンポ維持 |

## エリート登場演出（2026-07-06 — P3-UX-005）

> オーナー承認: 案 D（ELITE 短テロップ + 枠 pulse + 敵スライド）/ 表記 `ELITE` / 周回短縮。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-005-1 | **案 D** — 金 `ELITE` テロップ → amber flash+shake → 敵スライドイン → `【エリート】` ログ → `CombatTimer`。戦闘中 ELITE 枠常時表示 + 開始時 1 回 pulse | ボスより短く（~0.7s）。1ラン最大2回 |
| P3-UX-005-2 | **部屋トランジション** — ELITE 専用: 金粒子 + 橙オーバーレイ（BOSS 赤と分離） | 入場から差別化 |
| P3-UX-005-3 | **周回短縮** — `_fast_run_enabled` 時 `_elite_intro_timings(true)`。撃破スキップ（P3-D142）は演出後に実行 | ボス同型 |

## 宝箱開封演出（2026-07-06 — P3-UX-006）

> オーナー承認: 案 B（Closed→Open 差し替え + 金粒子）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-006-1 | **2枚差し替え** — 入室=`OBJ_TreasureChest_Closed` → shake → `Open` 切替 + 金粒子 + scale pop → 報酬ナラティブ → 自動進行 | 開封の体感。`_treasure_presentation_active` で AutoProgress 停止 |
| P3-UX-006-2 | **アセット** — `tools/generate_env_and_vfx.py` で Biome 別 Closed/Open 生成（母版=mourngate Closed + `derive_open_chest`） | 全 DG 統一 |
| P3-UX-006-3 | **装飾品時** — 粒子数増（56 vs 36） | レア感の最小差 |

## イベント改善 A+B+D（2026-07-06 — P3-EVT-002）

> オーナー承認: 推奨値で一括（A 演出 ~0.6s 固定 / B ラン内去重+枯渇フォールバック / D ①生態素材+②〜⑤文言）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-EVT-002-A | **outcome 演出** — description 表示 → shake+flash+粒子（heal/gold/buff/material/lore 色分け）→ 報酬適用。`_event_presentation_active` で AutoProgress 停止。計 ~0.6s | 宝箱/ELITE と体験整合 |
| P3-EVT-002-B | **ラン内去重** — `_seen_event_ids` で `pick_event` フィルタ。枯渇時はフルプールにフォールバック | 同一イベント連続を抑制 |
| P3-EVT-002-D | **素材多様化** — ①帯（mourngate/astoria 等）の material+relic_shard を `MOURNGATE_EVENT_MATERIAL_POOL` へ差し替え。②〜⑤ material は `relic_shard` 維持・label のみ Biome 化 | codex 未整備 Biome は文言改善のみ（D-2 は別 Task） |

## メイン Biome サブステージ（2026-07-06 — P3-DG-STG-001）

> オーナー GO: 案 B（`DungeonStage` スキーマ）・章ごと拠点戻り・**1 章 5〜10 分**・最終章は多フロア＋末尾 Boss。

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-STG-001-1 | **メイン Biome を 5 章** — 表示 `{biome}-{stage}`（例: モーンゲート **1-1〜1-5**）。②以降も **2-1〜2-5** 同型 | 進行の可視化・難易度段階設計 |
| P3-DG-STG-001-2 | **1 章（= サブステージ 1-1 / 1-2 等）= 1 ラン = 1 ダンジョン単位**。当該章の EXIT 到達で **拠点戻り** → Result → 次章選択。**フロア単位・Biome 通し突入はなし** | オーナー指定「1-1 などダンジョン単位で戻る」 |
| P3-DG-STG-001-3 | **プレイ時間** — **1 章あたり 5〜10 分**（旧 D-002「1 Biome 4〜6 分」を **上書き**）。`floor_count`・戦闘比率・自動進行速度で調整 | 初期案からの時間目標変更 |
| P3-DG-STG-001-4 | **1-1〜1-4** — `floor_count` **章ごと可変**（バラバラ可）。`enemy_level` **段階上昇**。Boss **なし**（EXIT=章クリア） | 例: 1-1=浅い4F / 1-4=6F+ELITE |
| P3-DG-STG-001-5 | **最終章（1-5）** — **Boss 専用短編にしない**。例: **floor_count≈10**・通常中間部屋（戦闘/EVENT/宝箱等）の後 **最終フロアで Boss** | オーナー指定「10F 作って最後にボス」 |
| P3-DG-STG-001-6 | **解放** — **1-5 Boss 初回討伐（ノーマル）** → 次メイン Biome **第1章** 解放（P3-D5DG-002 / P3-D157 維持）。Biome 全体クリア＝最終章 Boss 討伐 | 既存直列解放を章構造に載せ替え |
| P3-DG-STG-001-7 | **実装** — データ=`DungeonStage`（案 B）。**PoC=mourngate 1-1〜1-5 のみ**。寄り道・危険度ティア×章の詳細は別 Decision | 段階移行。旧 `floor_count` 単体 DG は PoC 後に置換 |
| P3-DG-STG-001-8 | **周回** — クリア済み章は **周回トグル**（P3-D118/D142）で再挑戦可。標準プレイ＝**複数章＋最終章 Boss**（旧「同一 DG 3〜6 周」の意味は **章横断ファーム** に再定義） | P3-D5DG-002 との整合 |

## サブステージ階層表（2026-07-06 — P3-DG-STG-002）

> **オーナー承認（2026-07-06）** — 下表を SSOT とする。**Impl は保留**（P3-DG-STG-001 PoC 着手前）。

**共通ルール**

| ルール | 内容 |
|---|---|
| floor_count | 下表の数値を `DungeonStage.floor_count` にそのまま使用（Impl 時。1-4 は Boss なし列を別生成） |
| x-1〜x-4 | **EXIT 締め**・Boss なし。**x-4 は ELITE 1 回必須** |
| x-5 | 中間部屋あり・**最終F = Boss**（floor_count=10） |
| enemy_level | 章内固定。x-5 は表の Boss 戦 Lv |
| 解放 | x-5 Boss 初回討伐 → 次 Biome **(N+1)-1** |

### ① 王都地下モーンゲート（`mourngate` / Boss: セルディオン `serdion`）

| 章 | floor_count | enemy_level | 推奨Lv | 締め |
|---|---|---|---|---|
| 1-1 | **6** | 1 | 3 | EXIT |
| 1-2 | **7** | 2 | 4 | EXIT |
| 1-3 | **7** | 3 | 5 | EXIT |
| 1-4 | **8** | 4 | 6 | EXIT + ELITE |
| 1-5 | **10** | 5 | 7 | **serdion** |

### ② 囁きの森ウィスパーウッド（`whisperwood` / Boss: グランヴェル `granvel`）

| 章 | floor_count | enemy_level | 推奨Lv | 締め |
|---|---|---|---|---|
| 2-1 | **6** | 10 | 12 | EXIT |
| 2-2 | **7** | 11 | 13 | EXIT |
| 2-3 | **8** | 12 | 14 | EXIT |
| 2-4 | **8** | 13 | 15 | EXIT + ELITE |
| 2-5 | **10** | 14 | 16 | **granvel** |

### ③ 霧沼ミストフェン（`mistfen` / Boss: モルドガル `moldgar`）

| 章 | floor_count | enemy_level | 推奨Lv | 締め |
|---|---|---|---|---|
| 3-1 | **7** | 20 | 22 | EXIT |
| 3-2 | **7** | 21 | 23 | EXIT |
| 3-3 | **8** | 22 | 24 | EXIT |
| 3-4 | **9** | 23 | 25 | EXIT + ELITE |
| 3-5 | **10** | 24 | 26 | **moldgar** |

### ④ 沈没航路ブラックショア（`blackshore` / Boss: ネレイオン `nereion`）

| 章 | floor_count | enemy_level | 推奨Lv | 締め |
|---|---|---|---|---|
| 4-1 | **7** | 32 | 34 | EXIT |
| 4-2 | **8** | 33 | 35 | EXIT |
| 4-3 | **8** | 34 | 36 | EXIT |
| 4-4 | **9** | 35 | 37 | EXIT + ELITE |
| 4-5 | **10** | 36 | 38 | **nereion** |

### ⑤ 最果て氷裂フロストリッジ（`frostridge` / Boss: エルディオン `eldion`）

| 章 | floor_count | enemy_level | 推奨Lv | 締め |
|---|---|---|---|---|
| 5-1 | **7** | 45 | 47 | EXIT |
| 5-2 | **8** | 46 | 48 | EXIT |
| 5-3 | **9** | 47 | 49 | EXIT |
| 5-4 | **9** | 48 | 50 | EXIT + ELITE |
| 5-5 | **10** | 49 | 50 | **eldion** |

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-STG-002-1 | 上表を **メイン5 Biome × 5 章** の floor / enemy_level **SSOT（設計）** とする | 旧1本 DG（7〜10F）を5分割。Biome 合計 **38〜43F** |
| P3-DG-STG-002-2 | **①②は x-1=6F**（序盤短め）・**③〜⑤は x-1=7F**（中盤以降やや深い） | 5〜10 分/章のバランス |
| P3-DG-STG-002-3 | **x-5 は全 Biome floor_count=10 統一**・末尾 Boss | オーナー「10F＋最後にボス」 |
| P3-DG-STG-002-4 | **Impl 前 PoC** — 数値は mourngate **1-1〜1-5** で実機 5〜10 分を確認後に微調整可 | バランスハーネス/実機 |

## サブステージ表示名 — メイン5 Biome（2026-07-06 — P3-DG-STG-003）

> **オーナー GO（2026-07-06）** — 案A（`world/05_Biomes` 探索縦軸＋敵 `codex_habitat` ベース）。Impl=`DungeonStage.display_name`（PoC=mourngate 1-1〜1-5）。

**UI 表示例:** `2-3 古樹の庭園` / バナー `ウィスパーウッド — 古樹の庭園`（Biome 短名＋章名）。

### ① 王都地下モーンゲート（`mourngate` / 縦軸＝降下）

| 章 | `stage_id` | **display_name** | 対応層位 | floor | enemy_level | 締め |
|:---:|---|---|---|---:|---:|---|
| 1-1 | `mourngate_1_1` | **崩れた地下水路** | L0〜L1 | 6 | 1 | EXIT |
| 1-2 | `mourngate_1_2` | **忘れられた納骨堂** | L1〜L2 | 7 | 2 | EXIT |
| 1-3 | `mourngate_1_3` | **王墓の回廊** | L2〜L3 | 7 | 3 | EXIT |
| 1-4 | `mourngate_1_4` | **封鎖監獄** | L4〜L5 | 8 | 4 | EXIT + ELITE |
| 1-5 | `mourngate_1_5` | **王座の深淵** | L6〜L7 | 10 | 5 | **serdion** |

### ② 囁きの森ウィスパーウッド（`whisperwood` / 縦軸＝深森）

| 章 | `stage_id` | **display_name** | 対応区域 | floor | enemy_level | 締め |
|:---:|---|---|---|---:|---:|---|
| 2-1 | `whisperwood_2_1` | **囁きの林道** | ヴェルディア外縁・盟約国遺構 | 6 | 10 | EXIT |
| 2-2 | `whisperwood_2_2` | **胞子の湿原** | 林床 | 7 | 11 | EXIT |
| 2-3 | `whisperwood_2_3` | **古樹の庭園** | 花蔓回廊 | 8 | 12 | EXIT |
| 2-4 | `whisperwood_2_4` | **寄生樹の深林** | 樹冠＋霧の谷 | 8 | 13 | EXIT + ELITE |
| 2-5 | `whisperwood_2_5` | **世界樹の根域** | 最深部 | 10 | 14 | **granvel** |

### ③ 霧沼ミストフェン（`mistfen` / 縦軸＝沈下）

| 章 | `stage_id` | **display_name** | 対応区域 | floor | enemy_level | 締め |
|:---:|---|---|---|---:|---:|---|
| 3-1 | `mistfen_3_1` | **霞渡り** | 沈没封緘区・踏査起点 | 7 | 20 | EXIT |
| 3-2 | `mistfen_3_2` | **沈泥湿原** | 停滞池・腐水域 | 7 | 21 | EXIT |
| 3-3 | `mistfen_3_3` | **黒霧樹海** | 軟泥帯・倒木 | 8 | 22 | EXIT |
| 3-4 | `mistfen_3_4` | **瘴胞の森** | 崩落街道・半没遺構 | 9 | 23 | EXIT + ELITE |
| 3-5 | `mistfen_3_5` | **マルグランの菌域** | 底なし沼・最深部 | 10 | 24 | **moldgar** |

### ④ 沈没航路ブラックショア（`blackshore` / 縦軸＝离岸）

| 章 | `stage_id` | **display_name** | 対応区域 | floor | enemy_level | 締め |
|:---:|---|---|---|---:|---:|---|
| 4-1 | `blackshore_4_1` | **潮見の浜** | 潮間帯・干潟 | 7 | 32 | EXIT |
| 4-2 | `blackshore_4_2` | **黒礁の入り江** | 座礁船骨群 | 8 | 33 | EXIT |
| 4-3 | `blackshore_4_3` | **難破船墓地** | 浅瀬・潮境 | 8 | 34 | EXIT |
| 4-4 | `blackshore_4_4` | **沈没航路** | 海統王ゆかりの防波堤 | 9 | 35 | EXIT + ELITE |
| 4-5 | `blackshore_4_5` | **ネレイオンの深海** | 潮境の深み | 10 | 36 | **nereion** |

### ⑤ 最果て氷裂フロストリッジ（`frostridge` / 縦軸＝極寒）

| 章 | `stage_id` | **display_name** | 対応区域 | floor | enemy_level | 締め |
|:---:|---|---|---|---:|---:|---|
| 5-1 | `frostridge_5_1` | **白雪平原** | フロストウォール北・雪原 | 7 | 45 | EXIT |
| 5-2 | `frostridge_5_2` | **氷裂峡谷** | 吹雪帯 | 8 | 46 | EXIT |
| 5-3 | `frostridge_5_3` | **古獣の氷河** | 氷河縁・遺構帯 | 9 | 47 | EXIT |
| 5-4 | `frostridge_5_4` | **極冠尾根** | 裂け目上空 | 9 | 48 | EXIT + ELITE |
| 5-5 | `frostridge_5_5` | **エルディオンの氷裂** | 氷河の果て | 10 | 49 | **eldion** |

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-STG-003-1 | 上表 **全25章** を `DungeonStage.display_name` **SSOT** とする | P3-DG-STG-002 数値と整合 |
| P3-DG-STG-003-2 | ①は層位圧縮（L0〜L7）。②〜⑤は **探索縦軸**（深森／沈下／离岸／極寒）＋ `codex_habitat` で5章割当。厳密1:1フロア対応は不要 | `05_Biomes` 探索ナラティブ |
| P3-DG-STG-003-3 | **`stage_id`** — `{biome_id}_{N}_{1〜5}`（例: `whisperwood_2_3`） | P3-DG-STG-001 案 B |
| P3-DG-STG-003-4 | x-5 章名は **区域名**（Boss 固有名と分離）。例: 1-5=王座の深淵／2-5=世界樹の根域／3-5=マルグランの菌域 | ①「王座の深淵＝区域、Boss＝セルディオン」と同型 |
| P3-DG-STG-003-5 | ②〜⑤ — **2026-07-06 オーナー承認**（本 Decision で確定） | P3-DG-STG-003-4（旧「別 Decision」）を置換 |

## サブダンジョン・サブステージ一旦オミット（2026-07-06 — P3-DG-OMIT-001）

> **オーナー指示（2026-07-06）** — モーンゲート完成優先。**side/apex のプレイ対象除外**＋**1-1 分割 Impl も保留**。設計 SSOT（P3-DG-STG-002/003・P3-ENEMY-001）は温存。

| 対象 | 扱い |
|---|---|
| **寄り道（`route_type=side`）** | UI 非表示・`is_dungeon_unlocked`=false。`.tres` は削除しない |
| **征討（`route_type=apex`）** | 同上 |
| **サブステージ（1-1〜1-5 分割）** | ~~Impl オミット~~ → **P3-DG-STG-ENABLE（2026-07-10）で有効化** | `SUB_STAGES_PLAYABLE=true` |
| **P3-DG-STG-002/003 章名・floor 表** | 設計 SSOT として残置（再開時に使用） |

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-OMIT-001-1 | **`Constants.SUB_DUNGEONS_PLAYABLE=false`** — side/apex を選択・出発不可 | 一旦スコープ外 |
| P3-DG-OMIT-001-2 | ~~**`Constants.SUB_STAGES_PLAYABLE=false`**~~ → **P3-DG-STG-ENABLE で再有効化**（2026-07-10） | 単体 mourngate 完成優先（**解除済**） |
| P3-DG-OMIT-001-3 | 再有効化は **別 Decision + GO** でフラグを true に | **→ P3-DG-STG-ENABLE 実施** |

## サブステージ再有効化（2026-07-10 — P3-DG-STG-ENABLE）

> **オーナー正式承認（2026-07-10）** — `P3-DG-STG-001` / `P3-DG-STG-003` に基づく **メイン5 Biome×5章** のサブステージ分割をプレイ対象として有効化。`P3-DG-OMIT-001-2` を上書き。

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-STG-ENABLE-1 | **`Constants.SUB_STAGES_PLAYABLE=true`** — 全メイン Biome（①〜⑤）で 1-1〜x-5 章進行を有効 | 設計 SSOT（P3-DG-STG-001）の本番適用 |
| P3-DG-STG-ENABLE-2 | データ=`resources/stages/` 25章・`DungeonStage`・章クリア連鎖・DG選択 UI | 既存 Impl を正とする |
| P3-DG-STG-ENABLE-3 | **寄り道・征討は引き続きオミット**（`SUB_DUNGEONS_PLAYABLE=false` 維持） | P3-DG-OMIT-001-1 は継続 |
| P3-DG-STG-ENABLE-4 | 旧単体 DG（`mourngate.tres` 等）はデータ温存。`SUB_STAGES_PLAYABLE=true` 時は章データがラン生成を主導 | 後方互換・フラグ切替用 |

## サブステージ一旦再オミット（2026-07-20 — P3-DG-STG-OMIT-002）

> **オーナー指示（2026-07-20）** — 現行のサブダンジョン／章分割を一旦すべてオミット。

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-STG-OMIT-002-1 | **`Constants.SUB_STAGES_PLAYABLE=false`** — 1-1〜x-5 UI・章進行を停止。単体 DG ランに戻す | オーナー指示 |
| P3-DG-STG-OMIT-002-2 | **寄り道・征討は引き続きオミット**（`SUB_DUNGEONS_PLAYABLE=false` 維持） | P3-DG-OMIT-001-1 |
| P3-DG-STG-OMIT-002-3 | `resources/stages/` データは削除しない。再有効化はフラグ true＋別 GO | 再開容易 |

## サブステージ再有効化（2026-07-21 — P3-DG-STG-ENABLE-002）

> **オーナー実機報告（2026-07-21）** — 単体 DG 運用だと初回ラン（体感 1-1）から最終ボス（serdion）が出現し、章別 spawn も効かない。`P3-DG-STG-OMIT-002` を撤回して章分割を復帰。

| # | 決定 | 根拠 |
|---|---|---|
| P3-DG-STG-ENABLE-002-1 | **`Constants.SUB_STAGES_PLAYABLE=true`** — 1-1〜x-5 を再有効化 | 実機: 1-1 相当でボス出現 |
| P3-DG-STG-ENABLE-002-2 | **1-1〜x-4 = Boss なし** / **x-5 最終Fのみ Boss**（P3-DG-STG-001 維持） | SSOT |
| P3-DG-STG-ENABLE-002-3 | 章別 `spawn_weights` を復帰（1-1 は D3 除外など） | P3-ENEMY-001 |
| P3-DG-STG-ENABLE-002-4 | 寄り道・征討は引き続きオミット | P3-DG-OMIT-001-1 |

## メイン Biome 敵プール拡充・章別危険度 spawn（2026-07-06 — P3-ENEMY-001）

> **オーナー GO（2026-07-06）** — 章別需要・危険度一覧・奥行き spawn 重みを SSOT 化。**新種アート/データ追加は別 Task**。**spawn 重み Impl は P3-DG-STG PoC（mourngate 1-1〜1-5）に同梱**。

### 背景・需要（現行部屋生成＋P3-DG-STG-002 想定）

| 粒度 | COMBAT | ELITE | BOSS | 戦闘計 |
|---|---:|---:|---:|---:|
| 1-1（fc=6） | ~3.1 | ~0.3 | — | **~3.4** |
| 1-2（fc=7） | ~3.3 | ~0.4 | — | **~3.8** |
| 1-3（fc=7） | ~3.3 | ~0.4 | — | **~3.8** |
| 1-4（fc=8） | ~3.6 | **1.1** | — | **~4.7** |
| 1-5（fc=10） | ~4.5 | ~0.7 | 1.0 | **~6.2** |
| **1 Biome 計（5章）** | **~19** | **~3** | **1** | **~22** |
| **全25章** | **~95** | **~25** | **5** | **~110** |

均等抽選・雑魚4種の現状 → **~4.7 回/種/Biome**（単調化）。目標 **2〜3 回/種** → 雑魚 **6〜7 種/Biome**（現4 → **+2〜3**）。

### 三軸の役割分担（二重強化禁止）

| 軸 | 役割 | SSOT |
|---|---|---|
| 章 `enemy_level` | 絶対ステ補正 | P3-DG-STG-002 |
| `codex_danger` (1〜5) | **同章内** spawn 重み | 本 Decision |
| 危険度ティア T0/T1/T2 | 周回再挑戦 | P3-D164 |

**禁止:** D5 を雑魚プールに混ぜる / `codex_danger` で章間 `enemy_level` を代替 / ティアと混同。

### 現行メイン6種×5 Biome（危険度）

| Biome | 雑魚×4（危険度） | Elite | Boss |
|---|---|---|---|
| ① mourngate | crown_eater_rat **1** / sepia·rune·crystal **2** | clock_moth **3** | serdion **5** |
| ② whisperwood | moss_boar·shell·iron_horn **2** / spore_widow·blood_bloom·rune_carcinos **3**（serpent は P3-ENEMY-WW-OMIT-001 でオミット） | mist_wyvern·mirror_boa **4** | granvel **5** |
| ③ mistfen | 4種すべて **3** | great_claw **4** | moldgar **5** |
| ④ blackshore | 4種すべて **3** | ninja_octopus **4** | nereion **5** |
| ⑤ frostridge | 4種すべて **4** | greios **5** | eldion **5** |

**ギャップ:** ③④=雑魚が全D3で章内差なし。⑤=全D4。①のみ D1/D2 幅あり。

### 拡充目標

| 項目 | 現状 | 目標 | 追加 |
|---|---:|---:|---:|
| 雑魚/Biome | 4 | **6〜7** | **+2〜3** |
| Elite/Biome | 1 | 1（据置） | 0 |
| Boss/Biome | 1 | 1（据置） | 0 |
| **メイン計** | 30 | **38〜42** | **+8〜12 雑魚** |

**制作優先:** ① → ③ → ④ → ② → ⑤（危険度幅の欠如が大きい順）。

**新種スロット（命名・生態は別 Task / world 整合必須）:**

| Biome | 追加危険度帯 | 目安 |
|---|---|---|
| ① | D1×1, D2×1〜2 | 浅層・中深層 |
| ② | D2×1, D3×1 | 序章用・深層用 |
| ③④ | D2×1, D4×1 | 序章/深層（現全D3を解消） |
| ⑤ | D3×1, D4×1 | 序章/深層（現全D4を解消） |

### 章別 spawn 重み SSOT（雑魚 COMBAT のみ・%）

ELITE/BOSS/遍在希少種（P3-D166）は別枠。重みは **当該 Biome 雑魚プール内** の `codex_danger` 一致種へ按分。

**① モーンゲート（D1/D2/[D3 trash 追加後]）**

| 章 | D1 | D2 | D3 |
|---|---:|---:|---:|
| 1-1 | 60 | 40 | 0 |
| 1-2 | 45 | 55 | 0 |
| 1-3 | 30 | 70 | 0 |
| 1-4 | 15 | 75 | 10 |
| 1-5 | 0 | 60 | 40 |

**② ウィスパーウッド（D2/D3）**

| 章 | D2 | D3 |
|---|---:|---:|
| 2-1 | 70 | 30 |
| 2-2 | 55 | 45 |
| 2-3 | 40 | 60 |
| 2-4 | 25 | 75 |
| 2-5 | 10 | 90 |

**③ ミストフェン（D2/D3/D4 trash）**

| 章 | D2 | D3 | D4 |
|---|---:|---:|---:|
| 3-1 | 50 | 50 | 0 |
| 3-2 | 35 | 65 | 0 |
| 3-3 | 20 | 70 | 10 |
| 3-4 | 10 | 60 | 30 |
| 3-5 | 0 | 45 | 55 |

**④ ブラックショア（D2/D3/D4 trash）** — ③と同型

| 章 | D2 | D3 | D4 |
|---|---:|---:|---:|
| 4-1 | 50 | 50 | 0 |
| 4-2 | 35 | 65 | 0 |
| 4-3 | 20 | 70 | 10 |
| 4-4 | 10 | 60 | 30 |
| 4-5 | 0 | 45 | 55 |

**⑤ フロストリッジ（D3/D4）**

| 章 | D3 | D4 |
|---|---:|---:|
| 5-1 | 50 | 50 |
| 5-2 | 35 | 65 |
| 5-3 | 20 | 80 |
| 5-4 | 10 | 90 |
| 5-5 | 0 | 100 |

> ⑤に D4 trash 追加後も最終章 100% D4 は「最高危険度雑魚のみ」意図。D3 種は 5-1〜5-4 の序盤寄与に限定。

### 実装スキーマ（P3-DG-STG PoC 同梱）

| 項目 | 方針 |
|---|---|
| データ | `DungeonStage.spawn_weights: Dictionary` — キー=`codex_danger` 文字列 `"1"`〜`"5"`、値=整数重み |
| 抽選 | COMBAT 雑魚: `enemy_pool` ∩ 重み>0 の danger 帯で重み付き抽選。プールに該当 danger が無い帯は **同帯内既存種へフォールバック**（PoC 期間） |
| ELITE | `elite_pool` 均等（変更なし）。x-4 必須 ELITE は P3-DG-STG-002 維持 |
| BOSS | `boss_id`（変更なし） |

| # | 決定 | 根拠 |
|---|---|---|
| P3-ENEMY-001-1 | 雑魚 **6〜7 種/Biome**（+2〜3）。Elite/Boss 据置 | ~2〜3 回/種/Biome |
| P3-ENEMY-001-2 | **`codex_danger`＝章内 spawn 重み SSOT**。章 `enemy_level` は P3-DG-STG-002 据置 | 二重強化回避 |
| P3-ENEMY-001-3 | 上表を **5 Biome × 5 章** spawn 重み SSOT とする | 奥の章ほど高危険度比率 UP |
| P3-ENEMY-001-4 | **`DungeonStage.spawn_weights`** を P3-DG-STG PoC（mourngate）で実装 | 均等 pool だけでは効果不足 |
| P3-ENEMY-001-5 | 新種 **+8〜12** は **①→③→④→②→⑤** で Task 化（命名・world 後） | ギャップ優先 |
| P3-ENEMY-001-6 | 遍在希少種・apex Boss・side DG は **本 Decision スコープ外** | P3-D166 / apex 既存 |

## 召喚所モック寄せ（2026-07-06 — P3-UI-GACHA / D-GACHA-1〜7）

> モック準拠の chrome・演出 polish。`GachaSystem.pull()` 単発のみ・天井30・10連本体は凍結のまま。

| # | 決定 | 根拠 |
|---|---|---|
| D-GACHA-1 | 画面タイトル **「英雄召喚」**。下ナビ表記（召喚所）は現行維持 | モック整合・P3-UI2-025 温存。**→ P3-GACHA-COPY-001 で招待状語彙へ上書き** |
| D-GACHA-2 | 排出 **★1〜4 表記維持**（`GachaRarityConfig.rate_display_text`） | 現行ロジック SSOT |
| D-GACHA-3 | **3タブ見た目のみ**（ピックアップ/プレミアム=disabled、ノーマルのみ有効） | 将来プール差し替え用の占位 |
| D-GACHA-4 | **10連ボタン配置＋SRリボン**（「★3以上1体確定」文言・押下不可） | モック見た目・10連ロジックは凍結 |
| D-GACHA-5 | **マイルストーン行は非表示**（天井バーのみ） | モックに無い要素を排除 |
| D-GACHA-6 | 通貨チップは現行データ・ラインナップは **横スクロールカルーセル**＋確率詳細オーバーレイ | P3-UI3-003 SummonActionBar と両立 |
| D-GACHA-7 | chrome は **`tools/generate_gacha_ui_assets.py`** で PIL 生成（17枚） | オーナー作画待ちの暫定アセット |

**P3-UI-GACHA Closeout（2026-07-06）:** Phase1〜5 完了。`GachaUiTokens`/`GachaUiHelper`・Reveal `UiTypography`・`ui_audit` gacha_detail/gacha_reveal。unit 151 PASS・smoke PASS。

## 防具・装飾品レジェンド（2026-07-07 — P3-EQ-LEG-001）

> **オーナー GO（2026-07-07）** — 案C（ボス初回確定★）+ パターンβ（`fixed_passive_id`）。①モーンゲート PoC 先行、②〜⑤は横展開 Task。

| # | 決定 | 根拠 |
|---|---|---|
| P3-EQ-LEG-001-1 | **入手= x-5 初回ボス討伐（ノーマル）確定**。通常 `armor_pool`/`accessory_pool` は ◇〜✦ のまま（レジェンドはプール外） | ドロップインフレ抑制・「Biome 極め」の証 |
| P3-EQ-LEG-001-2 | **各 Biome 防具★1 + 装飾★1**（計10+10）。①= `serdion_ward_plate` / `mourngate_royal_seal` | 武器★2と同型のブランド装備 |
| P3-EQ-LEG-001-3 | **`fixed_passive_id`** を `ArmorData` / `AccessoryData` に追加。`CombatPassives` SSOT で発火（武器 `fixed_skill_id` と同型） | スキル枠を増やさず個性付与 |
| P3-EQ-LEG-001-4 | **ステ目安** — ✦比 DEF/HP +25% 前後・装飾 crit +1段階。バランスハーネスで各 Biome 目標帯維持 | P3-D154 帯規則踏襲 |
| P3-EQ-LEG-001-5 | **データ** — `DungeonStage.legendary_armor_id` / `legendary_accessory_id`（x-5 のみ）。`DungeonController.apply_boss_legendary_loot` | 章構造（P3-DG-STG）と整合 |
| P3-EQ-LEG-001-6 | **②〜⑤横展開** — ① PoC Closeout 後に Biome 別 Task（命名・passive・ステ一括） | 段階移行 |
| P3-EQ-LEG-001-7 | **スコープ外** — セットボーナス（案γ）/ COMBAT 抽選への★混入 / Affix 本格化 | 別 Decision |

## レジェンド武器アイコン個別作画（2026-07-09 — P3-ART-LEG-WPN-001）

> **オーナー GO（2026-07-09）** — ★武器10本を手描き差し替え。Phase A=運用整備。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ART-LEG-WPN-001-1 | **64×64 透過 PNG** を `assets/ui/equipment/ICO_WPN_{PascalName}.png` に納品。枠・★は焼き込まない | P3-D002 / UI 側でレア表現 |
| P3-ART-LEG-WPN-001-2 | **作画 SSOT** — `docs/art/LegendaryWeaponIcon_Brief.md`（10本リスト・Biome フレーバー） | オーナー作画用 |
| P3-ART-LEG-WPN-001-3 | **`generate_equipment_icons.py`** — `LEGENDARY_HAND_DRAWN_WEAPON_IDS` で再生成スキップ（上書き防止） | 暫定自動生成アイコン保護 |
| P3-ART-LEG-WPN-001-4 | **Phase B** — ①②から順次作画・PNG 上書きのみ（`IconPaths` 変更不要） | コード最小 |
| P3-ART-LEG-WPN-001-5 | **スコープ外** — レジェンド防具・装飾アイコン / ドロップ VFX / ★枠グロー | 別 Task |
| P3-ART-LEG-WPN-001-6 | **Phase B 初版（2026-07-09）** — 10本 WIP 原画納品 + `tools/import_legendary_weapon_icons.py` で 64×64 取り込み | オーナー差し替え可（WIP 上書き→再 import） |

## 装備レベル（2026-07-07 — P3-EQ-LVL-001）

> **オーナー GO（2026-07-07）** — 案B（全装備 equip_level）+ Biome 連動ドロップLv。

| # | 決定 | 根拠 |
|---|---|---|
| P3-EQ-LVL-001-1 | **全装備**（武器・防具・装飾）に `equip_level`（1〜99）+ `equip_exp` | 序盤レジェンドの後半退役を緩和 |
| P3-EQ-LVL-001-2 | **成長式** — `effective = base + floor(base × k × (Lv−1))`。k=0.04、★は ×1.25 | 案B。炉研ぎ（+ATK）と併用 |
| P3-EQ-LVL-001-3 | **ドロップLv** — `stage.enemy_level`（無ければ `dungeon.enemy_level`）±1 | Biome/章帯で自然に変動 |
| P3-EQ-LVL-001-4 | **装備EXP** — 戦闘勝利時、装備中アイテムへ `max(1, enemy_level/2)`。上限=装着者キャラLv | 育成ループ |
| P3-EQ-LVL-001-5 | **SSOT** — `EquipmentEnhancer.gd`（装備レベル節）。戦闘/UI/セーブ配線 | P3-D152 炉研ぎは上乗せ枠として維持 |
| P3-EQ-LVL-001-6 | **旧セーブ** — 未設定時 `equip_level=1` | 互換 |

## レジェンド武器固有スキル（2026-07-07 — P3-SKILL-LEG-001）

> **オーナー GO（2026-07-07）** — 10本それぞれ `leg_*` 固有スキル。汎用属性斬撃は非レジェンド武器専用のまま維持。

| # | 決定 | 根拠 |
|---|---|---|
| P3-SKILL-LEG-001-1 | **1武器1スキル** — `skill_id=leg_<weapon_id>`、表示名は武器固有名詞＋技名 | レジェンド識別・収集動機 |
| P3-SKILL-LEG-001-2 | **数値枠** — 単体火力 1.45〜1.55 / デバフ特化 1.30〜1.40 / 複合デバフ・詠唱 1.25〜1.35 | 既存ジョブスキルと差別化 |
| P3-SKILL-LEG-001-3 | **奇抜枠（Phase1）** — エルディオン=冷却+炎上二重 / ウンブラ=呪い+恐怖+エリート温存 | 既存 `SkillData` フィールドのみ |
| P3-SKILL-LEG-001-4 | **汎用スキル維持** — `kindling_strike` 等は ★2〜✦ 武器用 | P3-SKILL-001-4 継続 |
| P3-SKILL-LEG-001-5 | **アイコン** — `IconPaths` で既存属性スキルアイコン流用 | アセット新規0 |
| P3-SKILL-LEG-001-6 | **Phase2 保留** — on_kill・AOE 等は `P3-SKILL-LEG-003` | スコープ分離 |

## 状態異常・属性 VFX（2026-07-07 — P3-VFX-STATUS-001）

> **オーナー GO（2026-07-07）** — Phase B（付与バースト + 常駐オーラ + DoT tick）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-VFX-STATUS-001-1 | **`CombatVfxManager.gd`** — 状態付与=ワンショット `CPUParticles2D`、常駐=スプライト子オーラ | `DungeonScene` 肥大化抑制 |
| P3-VFX-STATUS-001-2 | **オーラ対象** — poison/chill/shock/ignite/curse/bleed/stun/fear（8種） | 視認性の高いデバフ |
| P3-VFX-STATUS-001-3 | **付与時** — パーティクルバースト + 属性系は既存 `_spawn_hit_vfx` 連動 | 属性ヒット資産を再利用 |
| P3-VFX-STATUS-001-4 | **DoT tick** — ミニバースト + 既存ダメージ数字 | tick ごとの手触り |
| P3-VFX-STATUS-001-5 | **スコープ外** — 専用 `.tscn` アセット / シェーダーグロー / レジェンドスキル専用 VFX | Phase C へ |

## 罠部屋ヒット演出（2026-07-07 — P3-UX-TRAP-001）

> **オーナー GO（2026-07-07）** — 赤点滅 + ダメージ浮遊 + `_begin_trap_hit_presentation` 配線。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-TRAP-001-1 | **罠部屋** — 点滅3回（周回2）・ダメージ scale 1.35・軽シェイク・スプライト頭上数字 | 被弾体感 |
| P3-UX-TRAP-001-2 | **探索中罠** — 点滅2回・scale 1.2・シェイクなし | 戦闘テンポ維持 |
| P3-UX-TRAP-001-3 | **`TrapPresentation.gd`** — パルス数/alpha/scale SSOT | テスト可能化 |
| P3-UX-TRAP-001-4 | **`_begin_trap_hit_presentation` 配線** + AutoProgress 停止 | 未接続 UI を有効化 |
| P3-UX-TRAP-001-5 | **解除成功** — 演出なし | MVP |
| P3-UX-TRAP-001-6 | **スコープ外** — 専用 SE・罠スプライト・画面中央大数字 | Phase2 |

## イベント部屋テロップ演出（2026-07-07 — P3-UX-EVENT-001）

> **オーナー GO（2026-07-07）** — 案 A: 中央2段テロップ + 既存 flash/粒子。回復=緑・ダメージ=赤を共通色 SSOT 化。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-EVENT-001-1 | **2段テロップ** — 1段目=情景 `description`、2段目=結果短文（HP/Gold/攻撃UP/素材/碑文） | イベント結果の即時可読性 |
| P3-UX-EVENT-001-2 | **`EventPresentation.gd`** — 色・タイミング・文言フォーマット SSOT。回復=緑・ダメージ=赤 | 罠/戦闘数字と色言語統一 |
| P3-UX-EVENT-001-3 | **演出** — 暗転オーバーレイ + 中央フェード + 既存粒子/flash/shake。報酬適用は2段目表示と同期 | ボス/宝箱より短尺（~1.0s） |
| P3-UX-EVENT-001-4 | **周回短縮** — `_fast_run_enabled` で hold/shake/粒子弱体化 | ボス/エリート同型 |
| P3-UX-EVENT-001-5 | **lore** — テロップはタイトルのみ。本文はログ+Codex | 長文テロップ禁止 |
| P3-UX-EVENT-001-6 | **種別 BG** — `assets/dungeon/common/event/BG_Event_*.png`（6枚）を演出中に `TransitionLayer` へ重ね表示 | テロップ可読性 + 結果の視覚差別化 |
| P3-UX-EVENT-001-7 | **スコープ外** — Biome 別イベント BG・種別 SE | Phase2 |

## 結果画面ウィザード（2026-07-07 — P3-UX-RESULT-001〜004）

> **オーナー GO（2026-07-07）** — 報酬→レベルアップ→MVP の3ステップ・各30秒自動遷移・EXPバーアニメ・MVP統計。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-RESULT-001-1 | **3ステップ** — 報酬→LvUP→MVP。`次へ`+30秒/ステップ。MVPのみリトライ/拠点 | オーナー指定フロー |
| P3-UX-RESULT-001-2 | **全滅** — LvUPスキップ→MVPは表示（統計0なら「活躍データなし」） | D2 推奨値 |
| P3-UX-RESULT-002-1 | **EXP付与を LvUP アニメ後に遅延** — `ExpRunSnapshot` で付与前状態を保存 | ポケモン風バー演出 |
| P3-UX-RESULT-002-2 | **1人ずつ順番**にバー加算・Lv UP フラッシュ | D3 推奨値 |
| P3-UX-RESULT-003-1 | **`RunCombatStats`** — 与ダメ/最大ヒット/スキル名/回復をラン中集計 | MVP 前提データ |
| P3-UX-RESULT-004-1 | **MVP score** = damage + heal×0.5。同点=最大ヒット→与ダメ | D4 推奨値 |

## 行動ルールUI可読化（2026-07-07 — P3-UX-GAMBIT-001）

> **オーナー GO（2026-07-07）** — 「ガンビット」UI非表示・プリセット常時＋アコーディオン・戦闘ログ同型プレビュー。長文ヒントは廃止し `UiTypography` で可読サイズ維持。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-GAMBIT-001-1 | **表示名** — UIから「ガンビット」削除。「行動ルールを自分で設定」+ アコーディオン「行動ルールを編集」 | 初見で意味が伝わる |
| P3-UX-GAMBIT-001-2 | **プリセット一行サマリー** — `CombatGambit.preset_summary_line` を戦術 Option 直下に表示 | 編集なしでも戦術の中身が分かる |
| P3-UX-GAMBIT-001-3 | **行プレビュー** — `rule_preview`（`condition_summary → slot`）を各行下に金文字・BODY_SMALL | 戦闘 `[戦術]` ログと同型 |
| P3-UX-GAMBIT-001-4 | **入力** — HP=整数%表示、射程=近/中/遠。列見出し=順/行動/条件/値 | 0.30・melee 直感を排除 |
| P3-UX-GAMBIT-001-5 | **コピー** — 「今の戦術をコピーして編集」。適用中はアコーディオンに（適用中） | D122 導線の明確化 |
## 行動ルールUI可読化（2026-07-07 — P3-UX-GAMBIT-002）

> **オーナー GO（2026-07-07）** — 左=使う技（スキル名）/ 右=いつ使うか。防御含む。`skill_index` で装備①②を個別指定。未装備スキルは選択肢非表示。武器スキルはスコープ外。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-GAMBIT-002-1 | **UI列** — 優先 / 使う技 / いつ使うか。ドロップダウン=必殺・防御・装備スキル名・通常攻撃 | ユーザー案の2列表 |
| P3-UX-GAMBIT-002-2 | **データ** — `skill_index`(0/1) を custom plan に追加。プリセットの汎用 `skill` はローテ維持 | 後方互換 |
| P3-UX-GAMBIT-002-3 | **戦闘** — `_try_member_equipped_skill_at` で指定枠のみ発動 | 個別スキル条件 |
| P3-UX-GAMBIT-002-4 | **コピー** — `assign_skill_indices_for_copy` で複数 skill 行を 0/1 交互割当 | プリセット複製の初期値 |
| P3-UX-GAMBIT-002-5 | **ログ** — `[戦術]` にスキル表示名（`action_label`） | UX-001 プレビューと同型 |

## 装備ステータス定義（2026-07-08 — P3-EQ-STAT-001）

> **オーナー指示（2026-07-08）** — ステータス SSOT 整備。射程は使用状況に応じてオミット。幸運は3分割。

| # | 決定 | 根拠 |
|---|---|---|
| P3-EQ-STAT-001-1 | **SSOT** — `docs/specs/game/30_装備ステータス定義.md` | ディアブロ型ランダム化の前提資料 |
| P3-EQ-STAT-001-2 | **射程** — 戦闘内部で `base_attack_range`→`range_category`(melee/mid/long) は**使用中**（P3-D106f）。装備ステータス定義・ロール対象から**数値射程はオミット**（固定メタのみ） | プレイヤー向け stat ではない |
| P3-EQ-STAT-001-3 | **`luck` 廃止** — `exp_gain_rate` / `gold_gain_rate` / `rare_drop_rate` に3分割。宝箱品質・イベント成功率は装備 stat 外 | 効果の粒度を明確化 |
| P3-EQ-STAT-001-4 | **会心ダメ** — `critical_damage` を装備ロール対象として新設（現状全員 1.5 固定） | ディアブロ型拡張の柱 |
| P3-EQ-STAT-001-5 | **コード移行（P3-EQ-STAT-002）** — `AccessoryData.luck_bonus` 廃止→3率。`AffixStatCalculator` 配線。Affix `scholarly`/`treasure_hunter` 追加 | 定義→実装完了 |

## 武器ロール再定義（2026-07-08 — P3-EQ-STAT-003）

> **オーナー指示（2026-07-08）** — 属性・生態特効も変動値。SPD/CRT/会心ダメは必須外・デフォルトあり。

| # | 決定 | 根拠 |
|---|---|---|
| P3-EQ-STAT-003-1 | **必須ロール** — 攻撃力 / 属性 / 生態特効（`bane_class`+倍率）。全ドロップ武器に必ず付与 | ディアブロ型の個体差の柱 |
| P3-EQ-STAT-003-2 | **属性プール** — `ElementResolver` 5属性 + 無属性（`""`） | 既存弱点/耐性と整合 |
| P3-EQ-STAT-003-3 | **生態特効プール** — 敵 `codex_class` 分類 + 特効なし（`""`） | P3-D087 流用 |
| P3-EQ-STAT-003-4 | **任意ロール** — 攻撃速度 / 会心率 / 会心ダメは必須外。未設定時デフォルト: SPD=1.0 / CRT=0.05 / 会心ダメ=1.5 | 全武器に必ず付けない |
| P3-EQ-STAT-003-5 | **コード未実装** — `WeaponInstance` への `rolled_element` 等追加は別 Task | → P3-EQ-STAT-005 で実装 |

## 武器必須項目・属性値（2026-07-08 — P3-EQ-STAT-004 / P3-EQ-STAT-005）

| # | 決定 | 根拠 |
|---|---|---|
| P3-EQ-STAT-004-1 | **必須ロール=攻撃力のみ**。属性/生態特効は任意（未設定=無属性/なし） | オーナー指示 |
| P3-EQ-STAT-005-1 | **属性値案A実装** — `damage × (1 + element_power × 0.01)`。無属性時無視 | オーナー GO |
| P3-EQ-STAT-005-2 | **`WeaponStatResolver`** — ドロップ/解決/セーブ移行 SSOT | 単一責務 |

## レリック統合（2026-07-08 — P3-RELIC-PASSIVE 案A）

| # | 決定 | 根拠 |
|---|---|---|
| P3-RELIC-PASSIVE-1 | **案A** — 遺物タブ廃止。レリック=`CombatPassives` の `category:"relic"`。枠=キャラパッシブ1+レリック1 | オーナー GO |
| P3-RELIC-PASSIVE-2 | **id** — `relic_*`（旧 `war_banner` 等はマイグレーション） | パッシブ命名統一 |
| P3-RELIC-PASSIVE-3 | **所持** — `owned_relics` 解放型維持。装備は `equipped_passive_ids` 末尾 | 既存ドロップ継続 |
| P3-RELIC-PASSIVE-4 | **セーブ v4** — `relic_id` 廃止・`equipped_passives` へ統合 | スキーマ正規化 |
| P3-RELIC-PASSIVE-5 | **`CombatRelics`** — 表示/互換ファサード。定義 SSOT=`CombatPassives` | P3-D114 発火型と同居 |
## 図鑑採取素材＝炉研ぎ共通3種（2026-07-11 — P3-MAT-CODEx-001）

> **オーナー GO（推奨案A）** — 素材一新（3種）に合わせ、図鑑と実ドロップの乖離を解消。

| # | 決定 | 根拠 |
|---|---|---|
| P3-MAT-CODEx-001-1 | 敵詳細 S5 の採取欄は **敵別 `codex_materials` を使わない** | 実ドロップは `pick_combat_drop_material()` で共通抽選 |
| P3-MAT-CODEx-001-2 | 表示文言＝**「炉研ぎ素材（ダンジョン共通）」**＋ `ENHANCEMENT_MATERIAL_IDS` 3種 | 空欄（②〜⑤）と偽の敵別リストを防ぐ |
| P3-MAT-CODEx-001-3 | `EnemyData.codex_materials` は **表示・ドロップ非参照**（フィールドは残置可） | データ掃除は別 Task |
| P3-MAT-CODEx-001-4 | 素材タブは従来どおり enhancement 3種のみ | CatalogHelper 既存フィルタと一致 |

## 炉研ぎ素材3種一新（正式確定）（2026-07-11 — P3-MAT-003）

> **オーナー GO（推奨値）** — コード／`world/05` 先行の3種体制を Decision で確定。旧生態素材ドロップ（P3-D067）は本 Decision で上書き。

| # | 決定 | 根拠 |
|---|---|---|
| P3-MAT-003-1 | 素材 SSOT＝`relic_shard` / `ancient_bone` / `elite_relic_shard` のみ | 炉研ぎ・クラフト・ドロップを一本化 |
| P3-MAT-003-2 | 通常 COMBAT ドロップ＝`pick_combat_drop_material()`（欠片主・骨副）。`codex_materials` 非参照 | P3-D067-1 を上書き |
| P3-MAT-003-3 | 旧生物素材 ID はセーブ時 `sanitize_material_inventory()` で除去 | セーブ汚染防止 |
| P3-MAT-003-4 | **P3-D067**（生態素材実ドロップ／生態レシピ）は **履歴扱い・本 Decision で上書き済** | 現行と矛盾して読めるのを防ぐ |

## 高品質欠片の供給（2026-07-11 — P3-MAT-SUPPLY-001）

> **オーナー GO（推奨: ボス確定）** — 炉研ぎ+4/+5 と銀指輪クラフトの詰まり解消。

| # | 決定 | 根拠 |
|---|---|---|
| P3-MAT-SUPPLY-001-1 | **ボス撃破で `elite_relic_shard` を確定付与**（ノーマル1／ハード以上2） | 入手経路を1本確保 |
| P3-MAT-SUPPLY-001-2 | ELITE ボーナス素材は抽選成功時に **実際に `add_material`**（従来は ID のみ返却で未付与だった） | バグ修正＋既存20%経路を有効化 |
| P3-MAT-SUPPLY-001-3 | 通常 COMBAT プールには elite を入れない | 希少性維持 |

## クラフトレシピ差（数・Gold）（2026-07-11 — P3-MAT-CRAFT-001）

> **オーナー GO（推奨）** — 素材種類は増やさず、必要数と Gold でレシピ差を付ける。

| # | 決定 | 根拠 |
|---|---|---|
| P3-MAT-CRAFT-001-1 | レシピ差＝**必要数＋gold_cost**（種類は3種のまま） | 旧生態素材の職感代替 |
| P3-MAT-CRAFT-001-2 | 銀指輪のみ `elite_relic_shard` 必須（高段ゲート） | ボス供給と連動 |
| P3-MAT-CRAFT-001-3 | 目安: 杖30g / 弓40g / 革50g / 鉄剣55g / 骨鎧70g / 銀指輪120g | 推奨値 |

## レジェンド武器固有効果（2026-07-08 — P3-WPN-LEG-EFFECT）

> **オーナー GO** — `fixed_passive_id` + `CombatPassives.eq_wpn_*`。`leg_*` 自動スキル廃止。

| # | 決定 | 根拠 |
|---|---|---|
| P3-WPN-LEG-EFFECT-1 | **データ** — `WeaponData.fixed_passive_id` → `CombatPassives`（category=weapon） | 防具レジェンド同型 |
| P3-WPN-LEG-EFFECT-2 | **10本** — オーナー定義効果を数値確定して実装（下表） | 個性はオーナー、数値はHQ確定 |
| P3-WPN-LEG-EFFECT-3 | **重複** — 装備者ごとに独立発火（案A） | 前回GO |
| P3-WPN-LEG-EFFECT-4 | **`leg_*` 廃止** — 第3系統武器スキルはレジェンドから外す | 固有効果へ移行 |

## 指揮官・調査許可等級（2026-07-11 — P3-CMD-001）

> **オーナー GO** — 指揮官（隊長）プロフィール・調査点（SP）・D〜S級。メインBiome/章/ティア解放は現行クリア連鎖を維持。

| # | 決定 | 根拠 |
|---|---|---|
| P3-CMD-001-1 | **TopBar** — 編成1番手ではなく指揮官名・調査許可等級・SP進捗を表示。許可証glyph | 指揮官≠前線戦闘員 |
| P3-CMD-001-2 | **SP** — `CommanderSurveyPoints` が discovery/stage/codex深度/完走・撤退から再計算（非永続） | マイグレーション容易 |
| P3-CMD-001-3 | **等級** — D(0)/C(100)/B(350)/A(750)/S(1200)。副題=仮〜広域調査許可 | `08_SeekersGuild §9` |
| P3-CMD-001-4 | **隊長台帳** — C級解放。タブ=概要/資産/仲間/記録/称号 | 調査報告書フレーム |
| P3-CMD-001-5 | **通算統計** — Save v5 `commander.lifetime` + ラン終了マージ | MVP/最大一撃/出撃回数 |
| P3-CMD-001-6 | **称号** — コスメのみ10件（戦闘力変化なし）。B級報酬=コスメのみ（Gold+%は見送り） | 経済影響回避 |
| P3-CMD-001-7 | **解放** — メイン進行の `is_dungeon_unlocked` / tier / stage は **変更しない** | 二重ゲート回避 |
| P3-CMD-001-8 | **隊長台帳閲覧** — **ランク不問で常時閲覧可**（案A）。~~名前変更=C級~~・記録詳細=A級・称号枠等の**操作制限は維持**。C級到達の代替報酬は別途設計 | オーナー GO 2026-07-13 |
| P3-CMD-001-9 | **指揮官名変更** — 隊長台帳（マイページ）から **ランク不問で常時変更可**（案A）。起動時命名フロー未実装の代替。空名不可・最大16文字 | オーナー GO 2026-07-13（P3-CMD-001-8 の名前制限を上書き） |

## 週替わり「野外の変化」（2026-07-11 — P3-EVT-WEEK-002）

> **オーナー GO** — 経済週3種を残しつつ6週ローテ拡張。注目Biomeはサイクルごとに5 Biome ローテ。

| # | 決定 | 根拠 |
|---|---|---|
| P3-EVT-WEEK-002-1 | **6週ローテ SSOT**=`EventWeekRotation`（anchor=2026-07-01・7日境界）。0=EXP / 1=Gold / 2=武器 / 3=図鑑 / 4=注目Biome / 5=ELITE素材 | 経済週維持+調査テーマ |
| P3-EVT-WEEK-002-2 | **注目Biome** — 週4のみ `featured_biome_id` に EXP/Gold ×1.5（当Biome限定）。Biome id は `(absolute_week/6)%5` でローテ | オーナー GO |
| P3-EVT-WEEK-002-3 | **生態活発期** — 図鑑撃破 +1 回（×2 相当・stage<5） | 探索方針codexと独立 |
| P3-EVT-WEEK-002-4 | **UI** — ホーム帯「今週の野外」・DG選択Footer・ラン開始ログ。経済ログタグ `[野外]` | ライブ感 |
| P3-EVT-WEEK-002-5 | **`PERIODIC_EVENTS_ENABLED=true`** 再有効化。固定 `.tres` 日付はローテに置換 | 運用簡素化 |

---

## メイン5以外キャラ一旦オミット（2026-07-12 — P3-CHR-OMIT-001）

> オーナー GO（案C）: 新ドット絵適用前に、メイン5（アルド／リーヴァ／エリアス／ガレン／ミレイ）以外を一旦オミット。

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-CHR-OMIT-001-1 | **旧 batch7 CHR**（Warrior/Guardian/Scout）を `assets/characters/_omitted/batch7/` + `resources/animation/_omitted/` へ退避。本番参照はメイン5の `CHR_*.tres` のみ | 未使用プレースホルダ整理 |
| P3-CHR-OMIT-001-2 | **`GACHA_HELPERS_PLAYABLE=false`** — 召喚所ロック・抽選不可・ロスターから `gacha_*` 除外。`gacha_helpers/` データと `owned_helpers` セーブは残置 | P3-DG-OMIT と同型。再有効化で復帰可。**→ P3-GACHA-ENABLE-001 で true に上書き** |
| P3-CHR-OMIT-001-3 | ゲーム本編のプレイ対象キャラ＝**スターター5人のみ**（ジョブは従来どおり5職） | ドット一新の対象範囲を明確化。**ガチャ助っ人は ENABLE-001 で追加可** |

---

## ガチャ助っ人常時有効化（2026-07-17 — P3-GACHA-ENABLE-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-ENABLE-001-1 | **`GACHA_HELPERS_PLAYABLE=true` 常時** — 招待状／抽選／ロスター参加を開放 | オーナー GO（案A） |
| P3-GACHA-ENABLE-001-2 | **既知リスク受容** — 戦力インフレ・専用戦闘ドット未・10連準備中・魔晶石経済が前面化 | STOP 確認済 |
| P3-GACHA-ENABLE-001-3 | **10連／専用ドットは別 Task** — 本 Task はフラグと文書同期のみ | スコープ分離 |

---

## ガチャ UI 単線化（2026-07-17 — P3-GACHA-UI-TRIM-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-GACHA-UI-TRIM-001-1 | **10連・推薦状・通常招待タブを完全削除**（UI／文言／専用アセット）。再導入しない | オーナー指示 |
| P3-GACHA-UI-TRIM-001-2 | **招待画面は単発魔晶石＋チケットボタンのみ** | 同上 |
| P3-GACHA-UI-TRIM-001-3 | **専用戦闘ドットは別 Task のまま** | ENABLE-001 スコープ分離を維持 |

---

## 神話装備（2026-07-17 — P3-EQ-MYTHIC-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-EQ-MYTHIC-001-1 | **`Enums.Rarity.MYTHIC`** をレジェンド上位に追加。表示名「神話」 | オーナー GO 案A |
| P3-EQ-MYTHIC-001-2 | **初版3本** — 武器「葬冠の大剣」／防具「不滅の墓碑甲」／装飾「評議会の覇印」 | 部位各1・ぶっ壊れルール改変 |
| P3-EQ-MYTHIC-001-3 | **入手** — 通常レア抽選外。モーンゲートボス**再クリア**時のみ 1% で1枠（未所持優先） | 初見レジェンドと分離 |
| P3-EQ-MYTHIC-001-4 | **効果** — 武器:与ダメ+25%＋撃破CT短縮／防具:戦闘1回致死耐え＋短時間被ダメ減／装飾:パーティ与ダメ+20%・被ダメ-15%・EXP+25% | 単体ルール改変 |
| P3-EQ-MYTHIC-001-5 | **鍛冶** — 分解可・錬成（主材/素材）不可 | 希少性 |
| P3-EQ-MYTHIC-001-6 | **他Biome横展開は後続** | β範囲 |

---

## メイン5職ダンジョンドット差し替え（2026-07-12 — P3-ART-CHR-002）

> オーナー提供 ZIP（walk / atack / hurt / death / idle）。ゲーム使用＝歩行・攻撃・被弾・死亡。Idle はファイル保管のみ。

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-ART-CHR-002-1 | 5職を `assets/characters/{job}/` 個別フレーム（232px）へ差替。`atack`→`attack`。向きは素材どおり（行動=north/NE、idle=south） | 提供パック構造に追随 |
| P3-ART-CHR-002-2 | SpriteFrames のループ名は既存互換で **`idle`＝walk フレーム**。attack/hurt/death は同名。`idle_*.png` は別用途用に残置・戦闘未配線 | コード変更最小化（案B） |
| P3-ART-CHR-002-3 | 旧 `CHR_Swordsman_Sheet.png` は `_omitted/` へ退避。取込スクリプト=`tools/import_job_chr_sprites.py` | swordsman も個別フレーム統一 |

---

## 新規ゲーム導入フロー（2026-07-14 — P3-INTRO-001）

> オーナー GO（推奨案一式）。チュートリアル嫌い方針＝操作講習なし・最短で拠点解放。SSOT=`docs/specs/decisions/02_NewGameIntro.md`。

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-INTRO-001-1 | **フロー確定**: はじめから → 世界観スクロール → 隊長名入力 → ニーナ（最大3吹き出し） → 初期隊員選択 → **拠点解放**。強制ダンジョン突入なし | 最低限導入＋世界に解き放つ |
| P3-INTRO-001-2 | **案内役＝記録官ニーナ**。先輩説明は操作講習にしない（属性/CT/陣形/鍛冶/ガチャは不記載） | `world/08` の初心者案内役。詳細は図鑑・現地へ委譲 |
| P3-INTRO-001-3 | ナレーションは **6パネル相当・スキップ常時可**。真相（王冠/第十王等）は出さない | 空気は渡すが長編・スポイラーは禁止 |
| P3-INTRO-001-4 | 隊長名は拠点表示名として保存。初期隊員選択は既存 StarterPick を導入後段に維持 | 指揮官フレームと WIP タイトル導線に整合 |

---

## 導入アート配線（2026-07-15 — P3-INTRO-002）

> オーナー GO（推奨値＝案A core）。パネル挿絵（案B）・操作チュートは後続/非採用。SSOT=`docs/specs/decisions/02_NewGameIntro.md`。

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-INTRO-002-1 | **案A core**: Lore/Name/Starter BG＋ニーナ立ち絵＋スターター枠。パネル挿絵は後回し | 導入の空気感を最短で足す |
| P3-INTRO-002-2 | ニーナ＝左立ち絵／右吹き出し／下に次へ。スターター＝BG＋大きめ職ポート＋枠 | 縦モバイルUIでの読みやすさ |
| P3-INTRO-002-3 | アセットに焼き込みテキストなし。既存 hub BG（Codex系）の暗色ゴシック調に合わせる | UI文言はエンジン側・世界観トーン統一 |

---

## 導入演出 polish（2026-07-17 — P3-INTRO-SCROLL-001）

> オーナー GO（案A 自動クロール＋ニーナ文字送り＋隊員一行説明）。SSOT=`docs/specs/decisions/02_NewGameIntro.md`。

| # | 決定事項 | 根拠 |
|---|---|---|
| P3-INTRO-SCROLL-001-1 | 世界観ナレーションは **自動縦クロール**（入場後開始・タップ／ドラッグで加速・下端で「続ける」） | Decision の縦スクロールを演出として完成 |
| P3-INTRO-SCROLL-001-1b | **案A polish** — 上下フェード帯・開始/終端の緩急・パネル中心付近の減速（速度基準50px/s・加速は据置） | オーナー GO 2026-07-19 |
| P3-INTRO-SCROLL-001-2 | ニーナは **ドラクエ風文字送り**（1吹き出しずつ。送り中＝全文、完了後＝次へ） | 読み味を会話演出に寄せる |
| P3-INTRO-SCROLL-001-3 | 隊員選択カードに **職の一行説明**（`JobData.description`）を表示 | 初回選択の判断材料 |

## 素材レアリティ＋装備同型フレーム（2026-07-12 — P3-MAT-RARITY-001）

> **オーナー GO（推奨案A）** — `MaterialData.rarity` を UI に反映。装備 `INV_CELLS`（N/R/SR/SSR）を素材セルにも共用。

| # | 決定 | 根拠 |
|---|---|---|
| P3-MAT-RARITY-001-1 | **3種 rarity** — `relic_shard`=0（通常） / `ancient_bone`=1（レア） / `elite_relic_shard`=2（エピック） | 入手経路・炉研ぎ段階と整合 |
| P3-MAT-RARITY-001-2 | **UI SSOT** — `MaterialUiTokens` → `EquipmentUiTokens.rarity_slot_style()`。鍛冶コスト・Result 採取・図鑑詳細に適用 | 装備と視覚統一 |
| P3-MAT-RARITY-001-3 | **【希少】テキストプレフィックス廃止** — 枠＋名前色で表現 | 二重表現の排除 |
| P3-MAT-RARITY-001-4 | **`ancient_bone` ドロップ率連動** — rarity=1 により `ENHANCEMENT_DROP_CHANCE` 35%（A1 採用） | 見た目＝希少＝入手しにくさ |

---

## 炉研ぎ素材5種＋全装備炉研ぎ（2026-07-12 — P3-MAT-004 / P3-FORGE-002）

> **オーナー GO（案A）** — 素材3種（P3-MAT-003）を5種へ拡張。炉研ぎ対象を武器・防具・装飾に統一。装備Lv（戦闘EXP）は据置。

### P3-MAT-004 — 素材5種

| # | 決定 | 根拠 |
|---|---|---|
| P3-MAT-004-1 | **素材 SSOT＝5種** — `relic_shard`（共通）/ `base_ore`（◇）/ `ancient_bone`（◆）/ `epic_ore`（✦）/ `elite_relic_shard`（★） | レア別主素材＋共通。ID は既存3種を可能な限り役割継承 |
| P3-MAT-004-2 | **表示名** — 遺跡の結晶（共通）/ 基礎鉱（◇）/ 蒼古の骨鉱（◆）/ 深層結晶（✦）/ 王墓の欠片（★） | 世界観暫定。Biome別名称差は後続可 |
| P3-MAT-004-3 | **入手** — 共通・◇＝通常COMBAT（◇主・共通副）／◆＝ELITE・中深層章／✦＝ボス副報酬／★＝**ボス確定**（N1・H+2。P3-MAT-SUPPLY-001 継承） | 詰まり防止。★は希少維持 |
| P3-MAT-004-4 | **消費** — 基本 **装備レア対応鉱石 + 共通**（2種）。+4/+5 で上位鉱石1種追加（最大3種） | 1回の管理負荷抑制 |
| P3-MAT-004-5 | **消費表（+段×レア）** — ◇:+1〜3=共通+◇ / +4〜5=共通+◇多め。◆:+1〜3=共通+◆ / +4〜5=共通+◆+✦少量。✦:+1〜3=共通+✦ / +4〜5=共通+✦+★少量。★:+1〜3=共通+★ / +4〜5=共通+★多め | 数値は Impl 初期値（HQ表） |
| P3-MAT-004-6 | **旧セーブ** — 旧3種所持はそのまま有効（ID 継続）。新規 `base_ore`/`epic_ore` は0開始 | 破壊的マイグレーション不要 |
| P3-MAT-004-7 | **P3-MAT-003 / CODEx-001 を上書き** — 図鑑S5・`ENHANCEMENT_MATERIAL_IDS`・ドロッププールを5種に更新 | SSOT 一本化 |

**+4/+5 追加素材目安（HQ初期値・調整可）:**

| 装備レア | +4 追加 | +5 追加 |
|---|---|---|
| ◇ | — | — |
| ◆ | ✦ ×1 | ✦ ×1 |
| ✦ | ★ ×1 | ★ ×1 |
| ★ | — | —（共通+★の数量増のみ） |

### P3-FORGE-002 — 炉研ぎ全装備

| # | 決定 | 根拠 |
|---|---|---|
| P3-FORGE-002-1 | **対象＝武器・防具・装飾**。各 `*Instance.enhance_level` 0〜5 | P3-D152 拡張 |
| P3-FORGE-002-2 | **効果（+1あたり）** — 武器: 実効ATK +1／防具: 実効DEF +1・実効HP +2／装飾: ロール済み整数（HP/ATK/DEF）各+1（0は+0） | 案A。float・Affix・固有効果は対象外 |
| P3-FORGE-002-3 | **表示** — `名称 Lv.N +M`（武器と同型）。P3-D152-2 維持 | UI 一貫 |
| P3-FORGE-002-4 | **コスト** — Gold は P3-D152-4 表を**3カテゴリ共通**継承。素材は P3-MAT-004-5（装備**レア**で主鉱石決定） | +段とレアの二軸 |
| P3-FORGE-002-5 | **UI** — `BlacksmithScene` 炉研ぎタブに **武器｜防具｜装飾** 切替（作成タブ同型） | P3-UI2-018 延長 |
| P3-FORGE-002-6 | **SSOT** — `EquipmentEnhancer.gd`（判定・コスト・実行・実効ステ）。セーブ `enhance_level` 永続 | 単一責務 |
| P3-FORGE-002-7 | **据置** — 装備Lv（equip_level/EXP）・炉研ぎ失敗なし・floatステ強化。分解は **P3-FORGE-003** | P3-EQ-LVL-001 / P3-D152-3 |
| P3-FORGE-002-8 | **P3-D152-1 を上書き**（武器のみ → 全装備） | 履歴整合 |

**Gold（据置・全カテゴリ共通）:** +1=30 / +2=50 / +3=80 / +4=120 / +5=180

**素材数量目安（HQ初期値・+1〜3 / 装備レア=主鉱石）:**

| +段 | 共通 | ◇ | ◆ | ✦ | ★ |
|---:|---:|---:|---:|---:|---:|
| +1 | 1 | 1 | 1 | 1 | 1 |
| +2 | 1 | 2 | 2 | 2 | 2 |
| +3 | 2 | 2 | 2 | 2 | 2 |

+4/+5 は上表に P3-MAT-004-5 の追加列を加算（★+4/+5 は 共通3+★2 / 共通3+★3）。

---

## 鍛冶屋「分解」（2026-07-12 — P3-FORGE-003）

> **オーナー GO（案1・HQ推奨値）** — レア別スクラップ返却＋炉研ぎ少量ボーナス。P3-MAT-004 の5種素材経済の出口。P3-UI2-018-3（分解🔒）を解消。

| # | 決定 | 根拠 |
|---|---|---|
| P3-FORGE-003-1 | **場所** — `BlacksmithScene` 分解タブ（既存 `BtnDismantle` を有効化） | P3-UI2-018 延長 |
| P3-FORGE-003-2 | **対象** — 武器・防具・装飾。鑑定済み・**未装備のみ** | 装備中消失防止 |
| P3-FORGE-003-3 | **UI** — 武器｜防具｜装飾切替（炉研ぎ同型）。左リスト / 右プレビュー「獲得素材」/ `[分解する]` | Master-Detail 維持 |
| P3-FORGE-003-4 | **★確認** — レジェンド装備は **2段階確認** ダイアログ必須 | 誤操作防止 |
| P3-FORGE-003-5 | **返却（ベース）** — 装備レア＝P3-MAT-004 主鉱石。◇=基礎鉱×2+共通×1 / ◆=蒼古×1+共通×1 / ✦=深層×1+共通×2 / ★=王墓×1+共通×2 | 案1スクラップ |
| P3-FORGE-003-6 | **返却（炉研ぎボーナス）** — `enhance_level` 每に **共通+1**。+4/+5 強化品は同帯主鉱石+0〜1、**+4/+5 のみ**上位鉱石+1（P3-MAT-004 帯に準拠） | 100%還元禁止・投資の一部回収 |
| P3-FORGE-003-7 | **exploit 防止** — 分解返却 ≤ 同一装備クラフト必要素材×**60%**（クラフト品）。ドロップ品は固定表 | クラフトループ増殖禁止 |
| P3-FORGE-003-8 | **SSOT** — `EquipmentEnhancer.dismantle_preview` / `dismantle_item`（返却 Dictionary・inventory 削除） | 炉研ぎと同ファイル |
| P3-FORGE-003-9 | **据置** — Gold 返却・お気に入りロック・`equip_level` による返却差 | MVP最小化 |
| P3-FORGE-003-10 | **Impl 順** — **P3-MAT-004 / P3-FORGE-002 完了後** | 返却先5種 ID の確定が先 |
| P3-FORGE-003-11 | **一括分解** — 分解タブ内に **`◇◆を一括分解`** ボタン。対象＝**未装備・鑑定済み・◇◆のみ**（武器+防具+装飾を横断） | インベントリ整理。✦★は個別分解のみ |
| P3-FORGE-003-12 | **一括UI** — 押下で確認ダイアログ（**件数**＋**獲得素材合計**プレビュー）→ OK で実行。0件時はボタン disabled またはトースト | 誤操作防止 |
| P3-FORGE-003-13 | **一括SSOT** — `EquipmentEnhancer.dismantle_bulk_preview` / `dismantle_bulk_common_rare`（単体 `dismantle_item` の合算・同一削除規則） | 返却表は P3-FORGE-003-5/6 と同一 |
| P3-FORGE-003-14 | **一括据置** — レア別フィルタ UI・✦★混在チェック・炉研ぎ+4以上の除外トグル | MVPは ◇◆固定のみ |

**炉研ぎボーナス詳細（HQ初期値）:**

| enhance_level | 共通追加 | 主鉱石追加 | 上位鉱石（+4/+5 のみ） |
|---:|---:|---:|---|
| +1〜+3 | +N（N=enhance_level） | — | — |
| +4 | +4 | 同帯 +1 | ◆→✦×1 / ✦→★×1 / 他— |
| +5 | +5 | 同帯 +1 | 同上 |

**P3-UI2-018-3 / P3-UI2-018-6 を上書き**（分解ロック → 本 Decision で実装対象）。

---

## βスコープ再設定（2026-07-14 — P3-BETA-SCOPE）

| # | 決定 | 根拠 |
|---|---|---|
| P3-BETA-SCOPE-1 | **公開β＝モーンゲート編の完成**をゴールとする | コアループ完成度を優先。5 Biome 同時磨きは工数が膨らむ |
| P3-BETA-SCOPE-2 | **②〜⑤・寄り道はデータ／コードを削除しない**。選択UIで未解放／非表示 | 既実装を活かし、アップデートで解禁 |
| P3-BETA-SCOPE-3 | **EQ-LEG-002 / ENEMY-002 残りはアップデート枠**へ移動 | β必須ではない横断拡張 |
| P3-BETA-SCOPE-4 | **BGM は後回し**（Suno・オーナー）。SE 最小配線は維持 | 音なしでもβ通し可能 |
| P3-BETA-SCOPE-5 | Task 仕分けの正は `CurrentSprint.md`（必須／推奨／Update／凍結） | 旧「5 Biome 拡張」スプリントを上書き |
| P3-BETA-SCOPE-6 | **UI=案B** — ②以降は一覧に残し **🔒 / 「🔒 ロック中」**（非表示にしない）。ツールチップ「今後のアップデートで解放予定」 | オーナー選択 2026-07-14 |
| P3-BETA-SCOPE-7 | **実装フラグ** — `Constants.BETA_MOURNGATE_ONLY`。`is_dungeon_unlocked` でモーンゲート以外の main を false | OFF で従来直列解放に復帰可能 |

---

## 初期5人ストーリー編成（2026-07-14 — P3-STORY-STARTER-001）

> **オーナー GO（案B）** — バランス検証のため、βから「開始1人＋章進行で初期5人を加入」を採用。

| # | 決定 | 根拠 |
|---|---|---|
| P3-STORY-STARTER-001-1 | **案B** — βから本フローを有効化（ソロ〜少人数で通し、バランスを実測） | オーナー選択 |
| P3-STORY-STARTER-001-2 | **開始** — ニューゲームで初期5人から **1人選択**。ロスターはその1人のみ | 指揮官ストーリー |
| P3-STORY-STARTER-001-3 | **加入** — メイン Biome の **章5（×-5）ノーマル初回クリア**ごとに、未加入の初期5人から **ランダム1人** | オーナー原案 |
| P3-STORY-STARTER-001-4 | **Hard/NM の×-5では加入しない**（二重防止）。同一 Biome ノーマル×-5は1回のみ | 周回汚染防止 |
| P3-STORY-STARTER-001-5 | **`ensure_base_roster_complete` の全職強制補完は廃止／ゲート** | ストーリー破壊防止 |
| P3-STORY-STARTER-001-6 | **旧セーブ** — 既存ロスターに初期5がいる場合は全員解放済みとして互換 | 破壊的マイグレーション回避 |
| P3-STORY-STARTER-001-7 | **β検証** — `STARTER_RECRUIT_BETA_EXTRA`（①の1-2/1-3/1-4 初回クリアでも未加入から1人）。①内で最大開始1+4加入＝5人まで検証可 | 当初 ON |
| P3-STORY-STARTER-001-7b | **2026-07-19** — `STARTER_RECRUIT_BETA_EXTRA=false`（本番寄り）。加入は **章5（×-5）ノーマル初回のみ**。β内は開始1＋1-5クリアで最大2人 | オーナー指示 |
| P3-STORY-STARTER-001-8 | **編成** — 上限4維持。5人目は控え。1〜3人戦闘は現行パーティ人数補正を活かし、足りなければ最小調整 Task を別発行 | 検証ファースト |
| P3-STORY-STARTER-001-9 | **2026-07-22** — ×-5 クリア時は候補のみ確定。**拠点帰還後に加入セリフ→ガチャ入手と同型リビールで roster 追加**。Result/MVP には出さない | オーナー実機（加入が突然／MVPに並ぶ） |

---

## タイトル画面（2026-07-14 — P3-UI-TITLE-001）

> **オーナー GO** — セーブ切替検証のため Continue / New Game。複数スロットは不要。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI-TITLE-001-1 | **起動** — Boot はロードせず Title へ。Continue 時のみ `load_game` | New Game を綺麗に開始 |
| P3-UI-TITLE-001-2 | **つづきから** — セーブあり時のみ。ロード後はスターター選択待ちなら Pick、否則拠点 | 既存進行の継続 |
| P3-UI-TITLE-001-3 | **はじめから** — セーブ削除＋`reset_for_new_game`→スターター選択。セーブあり時は確認ダイアログ | 検証・リセット用途 |
| P3-UI-TITLE-001-4 | **スロット** — 単一セーブ（`user://save_data.json`）のみ。複数スロットはスコープ外 | オーナー指定 |
| P3-UI-TITLE-001-5 | **設定戻り** — Title から開いた設定は Title へ戻る（下ナビ非表示） | 空拠点への誤遷移防止 |

---

## 鍛冶屋「錬成」（2026-07-14 — P3-FORGE-ALCHEMY-001）

> **オーナー GO（全推奨値）** — 装備×装備で主材の装備Lvを上げる。分解・炉研ぎと併存。

| # | 決定 | 根拠 |
|---|---|---|
| P3-FORGE-ALCHEMY-001-1 | **同種のみ**（武器↔武器 / 防具↔防具 / 装飾↔装飾）。同一ID不要 | 在庫が回り、育成用途に合う |
| P3-FORGE-ALCHEMY-001-2 | **上昇** — `max(1, floor(素材Lv × 0.5))`。結果は 99 まで。実上昇量で Gold 計算 | わかりやすさ |
| P3-FORGE-ALCHEMY-001-3 | **Gold** — `20 × 実上昇Lv`。素材コストなし | シンク最小 |
| P3-FORGE-ALCHEMY-001-4 | **引き継ぎなし** — レア／ロール／接頭接尾／炉研ぎ＋は主材維持。素材は消滅（分解報酬なし） | 軸分離 |
| P3-FORGE-ALCHEMY-001-5 | **装備中不可**（主材・素材とも）。★3以上 or 炉研ぎ+3以上素材は確認ダイアログ | 事故防止 |
| P3-FORGE-ALCHEMY-001-6 | **装着時クリップ** — インベントリでは 99 まで可。装備時に冒険者Lvへ丸め | UI簡略 |
| P3-FORGE-ALCHEMY-001-7 | **UI** — 鍛冶タブ「錬成」。左=主材・下段=素材。既存 Master-Detail 準拠 | 他タブ整合 |

---

## モーンゲート3体ハード／NM見た目＋呼称個性（2026-07-14 — P3-ENEMY-TIER-VAR-001）

> **オーナー GO（全推奨値）** — 同 `enemy_id`。ベース数値は据置（ティア Lv+3/+6 に任せる）。図鑑は同一エントリ。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ENEMY-TIER-VAR-001-1 | **同ID** — `grave_bell_bat` / `crystal_scorpion` / `skullface_mantis`。別リソース化しない | 図鑑肥大・二重ステ防止 |
| P3-ENEMY-TIER-VAR-001-2 | **見た目** — Hard/Nightmare 専用シートをティアで差し替え（既存配線） | 色替え承認済 |
| P3-ENEMY-TIER-VAR-001-3 | **呼称** — Hard: 血鐘／紫晶／血面。NM: 月鐘／熔晶／屍面 | 推奨名GO |
| P3-ENEMY-TIER-VAR-001-4 | **個性のみ上書き** — スキル率・異常・属性・会心・耐性／弱点。HP/ATK/DEF は不変 | P3-D164 と二重加算しない |
| P3-ENEMY-TIER-VAR-001-5 | **熔晶NM** — 攻撃属性炎・弱点水・on_hit=`ignite` | 推奨アイデンティティ |
| P3-ENEMY-TIER-VAR-001-6 | **実装** — `EnemyTierVariantConfig`＋`DungeonController` 抽選時 duplicate 適用 | レジストリ汚染防止 |

### モーンゲート全プール拡張＋ティア排他（2026-07-14 — P3-ENEMY-TIER-VAR-002）

> **オーナー GO（全推奨値）** — 残り雑魚4＋ELITEクロックモス＋ボスセルディオンも Hard/NM 色・呼称・個性。**Hard用はHard限定・Nightmare用はNightmare限定。ノーマルには色替え敵を出さない。** Hard↔NM 相互フォールバック禁止。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ENEMY-TIER-VAR-002-1 | **対象追加** — sepia_hound / rune_roach / crown_eater_rat / crystal_hedgehog / clock_moth / serdion | モーンゲート完成 |
| P3-ENEMY-TIER-VAR-002-2 | **呼称** — Hard: 錆影／朱紋／貪冠／紅晶／血刻／紅骸。NM: 幽嗅／蒼紋／奪冠／黒晶／停時／蒼骸 | 推奨GO |
| P3-ENEMY-TIER-VAR-002-3 | **排他** — `ENEMY_SPRITE_MAP_BY_TIER` / `BOSS_*_BY_TIER` は鍵1・2のみ。T0は常にノーマルシート | オーナー注意事項 |
| P3-ENEMY-TIER-VAR-002-4 | **フォールバック** — 該当ティア資産が無いときのみノーマルへ。HardシートをNMで使わない | 誤表示防止 |
| P3-ENEMY-TIER-VAR-002-5 | **個性** — ベース数値据置。異常・属性・スキル率のみ（既存方針継続） | P3-D164 と非二重 |

---

## SE 基盤（2026-07-14 — P3-AUDIO-SE-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-AUDIO-SE-001-1 | **音源** — Kenney.nl（Interface / RPG / Impact / Digital）CC0 を採用・リネーム配置 | iOS 商用可・クレジット任意・差分管理しやすい |
| P3-AUDIO-SE-001-2 | **再生入口** — Autoload `AudioManager` + `SfxCatalog`（ID→path） | シーン直書き禁止・差し替え容易 |
| P3-AUDIO-SE-001-3 | **バス** — SE は `SFX`、BGM は `BGM`（`SettingsPrefs` 音量） | 設定画面と整合 |
| P3-AUDIO-SE-001-4 | **連打抑制** — SE ごとに短いクールダウン（オート戦闘向け） | ×2速の耳負担低減 |
| P3-AUDIO-SE-001-5 | **BGM** — Suno 等はオーナー制作。API `play_bgm` のみ先置き | SE と責務分離 |
| P3-AUDIO-SE-001-6 | **権利** — `assets/audio/sfx/ATTRIBUTION.md` + 各 License.txt を同梱 | App Store 説明用台帳 |

---

## SE 未配線完了（2026-07-14 — P3-AUDIO-SE-002）

| # | 決定 | 根拠 |
|---|---|---|
| P3-AUDIO-SE-002-1 | **combat_skill** — スキル resolve／即時発動の頭上ラベル時（詠唱中・必殺は対象外。必殺は `combat_ultimate`） | 未使用 SE の埋込・耳の二重化回避 |
| P3-AUDIO-SE-002-2 | **combat_death** — 敵撃破・味方戦闘不能 | 死亡フィードバック |
| P3-AUDIO-SE-002-3 | **ui_error** — 鍛冶の失敗／不足ログ | 操作ミスの即時フィードバック |
| P3-AUDIO-SE-002-4 | **ui_cancel** — タイトル New Game／鍛冶確認のキャンセル | 確認ダイアログの打ち切り音 |
| P3-AUDIO-SE-002-5 | **罠** — 専用音なし → `combat_hit` 再利用 | 新規収録なしで手応え |
| P3-AUDIO-SE-002-6 | **ボス登場** — 専用音なし → `room_enter`（pitch 微上げ） | 入場感。必殺と音を分離 |

---

## BGM 配線（2026-07-16 — P3-AUDIO-BGM-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-AUDIO-BGM-001-1 | **音源** — オーナー制作 MP3（Suno 等）を `assets/audio/bgm/` に配置 | P3-AUDIO-SE-001-5 の後続 |
| P3-AUDIO-BGM-001-2 | **カタログ** — `BgmCatalog`（title / hub / dungeon_explore / battle / boss / result）＋ループ既定 | SE と同型の ID→path |
| P3-AUDIO-BGM-001-3 | **再生** — `AudioManager.play_bgm`。タイトル・拠点・探索／戦闘／ボス／リザルトへ配線 | シーン直書き禁止 |
| P3-AUDIO-BGM-001-4 | **権利** — BGM クレジット文面は後続（設定／クレジット画面とセット） | 出荷前に明文化 |

---

## 必殺技 resolve 演出（2026-07-13 — P3-UX-ULTIMATE-001）

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-ULTIMATE-001-1 | **案A** — resolve 時のみグローバルロック（詠唱中は現行維持＝詠唱者のみ Action Lock） | テンポと演出の両立 |
| P3-UX-ULTIMATE-001-2 | **resolve 尺** — announce 1.0s + windup 0.65s + release 0.25s（合計約1.9s）。戦闘速度倍率でスケール | `UltimatePresentationConfig` SSOT |
| P3-UX-ULTIMATE-001-3 | **テロップ** — 画面中央「必殺技」＋スキル名（resolve 時。頭上テロップは使わない） | 視認性 |
| P3-UX-ULTIMATE-001-4 | **ダメージ/回復** — インパクト段で適用（VFX と同フレーム即時適用を廃止） | 手応え |
| P3-UX-ULTIMATE-001-5 | **データ** — `ultimate_strike` の `cast_time` を 2.0 に変更（詠唱2ターン） | 案Aと整合 |
| P3-UX-ULTIMATE-001-6 | **ロック中** — `CombatTimer` 停止・CT/DoT 進行なし | カットシーン割り込み防止 |
| P3-UX-ULTIMATE-001-7 | **スコープ外** — ジョブ別必殺の個別尺・カメラワーク・専用 BGM | 横展開は後続 |

---

## キャラ固有パッシブ見直し（2026-07-17 — P3-PASSIVE-CHAR-001）

> オーナー GO: 味方死亡時系を廃止。メイン5の★3固有を標準とし、ガチャ★2は弱く／★4は強く。職帯パッシブは案α（自動付与しない）。

| # | 決定 | 根拠 |
|---|---|---|
| P3-PASSIVE-CHAR-001-1 | **強さ軸** — メイン5★3固有＝標準。ガチャ★2＜★3≦標準＜★4 | オーナー指示 |
| P3-PASSIVE-CHAR-001-2 | **案α** — ★3/★4 職帯パッシブは選択プール・自動付与から外す（定義データは残置） | 固有だけで★差を付ける |
| P3-PASSIVE-CHAR-001-3 | **リーヴァ** — 攻撃時25%で毒 | 死亡時反撃から置換 |
| P3-PASSIVE-CHAR-001-4 | **エリアス** — 戦闘フロア入場時（`on_combat_start`）に味方全体HP30%回復 | 死亡時回復から置換。行動ごと回復は過強のため入場時のみに修正 |
| P3-PASSIVE-CHAR-001-5 | **カイダ★2** — HP50%以下で与ダメ+30% | 条件付き火力 |
| P3-PASSIVE-CHAR-001-6 | **イヴァル★2** — 非戦闘（罠・探索）ダメージ無効 | 探索ユーティリティ |
| P3-PASSIVE-CHAR-001-7 | **ガルム★2** — 致死を10%でHP1耐える | 低確率セーフティ |
| P3-PASSIVE-CHAR-001-8 | **セリン★3** — 非戦闘エリア入場時に味方全体HP30%回復 | エリアスと同格・場面違い |
| P3-PASSIVE-CHAR-001-9 | **ミラ★3** — 攻撃時20%で拘束 | 死亡時バフから置換 |
| P3-PASSIVE-CHAR-001-10 | **ヴァルデン★4** — 被ダメ-12%＋被弾時戦闘中1回だけ味方全体被ダメ-10% | ★4として明確に強く |
| P3-PASSIVE-CHAR-001-11 | **アルド／ガレン／ミレイ** — 据置 | 標準として維持 |
| P3-PASSIVE-CHAR-001-12 | **レオン★1**（`_omitted`）— 状態異常の敵へ与ダメ+25%（病隙の刃） | オーナー指定。プール外だがデータ／旧セーブ用に定義 |
| P3-PASSIVE-CHAR-001-13 | **ドランテ★1**（`_omitted`）— 攻撃後10%で装備スキル発動（薬瓶の反響） | オーナー指定。連鎖防止あり |

**Closeout（2026-07-17）:** 定義・戦闘／探索配線・unit 更新。職帯自動付与撤去。★1二人は追記 Closeout。

---

## キャラ個人ステ補正（2026-07-17 — P3-STAT-CHAR-001）

> オーナー GO: 案A — ★帯ステを基準に残し、キャラごとに HP/ATK/DEF 補正を加算。

| # | 決定 | 根拠 |
|---|---|---|
| P3-STAT-CHAR-001-1 | **案A** — `STAT_BONUS_BY_RARITY` ＋ `CharacterStatBonuses` 個人補正 | ★序列を維持しつつ個性 |
| P3-STAT-CHAR-001-2 | **SSOT** — `scripts/roster/CharacterStatBonuses.gd`（メイン5＋helper） | データ一箇所 |
| P3-STAT-CHAR-001-3 | **適用** — 生成／正規化／セーブ同期で `GachaRarityConfig.apply_stats_for_adventurer` | 旧セーブもロード時に再計算 |
| P3-STAT-CHAR-001-4 | **初版数値** — ロール寄せの小幅補正（盾=HP/DEF、火力=ATK）。要実機調整 | たたき台 |
| P3-STAT-CHAR-001-5 | **差拡大** — ★帯（★2/3/4 = HP+6/14/26・ATK+2/5/11・DEF+1/3/7）＋個人補正も大きく | オーナー指示 |
| P3-STAT-CHAR-001-6 | **個人補正を二桁規模へ**（例: ガレン HP+24/DEF+16、カイダ ATK+18） | オーナー指示 |
| P3-STAT-CHAR-001-7 | **全キャラで最終ステ組を一意に**（個人補正も全員別値）。差はさらに拡大 | オーナー指示 |
| P3-STAT-CHAR-001-8 | **3桁見栄え** — 素体HP 30→100、★帯／個人補正を同スケール。ATK/DEF 最低1 | オーナー GO |
| P3-STAT-CHAR-001-9 | **ATK/DEF差を圧縮** — 個性は主にHP。ATK/DEFは近い帯に収める（組は一意維持） | オーナー指示 |
| P3-STAT-CHAR-001-10 | **全体×8** — 素体HP 800、ATK目安300台（例: アルド304） | オーナー指示（もう一桁） |
| P3-STAT-CHAR-001-11 | **初期バランス数値** — 都度調整。**ルール化しない** | オーナー指示 |
| P3-STAT-CHAR-001-12 | **初期バランス** — ★合計で 4>3>2>1。個差はだいたい50前後でバラす（均等梯子にしない）。★帯ボーナスも拡大 | オーナー指示 |
| P3-STAT-CHAR-001-13 | **GO（2026-07-18）** — 現行数値（ヴァルデン1674/418/392 他）で採用。以降の変更は都度調整 | オーナー GO |

**Closeout（2026-07-18）:** 配線＋unit＋初期バランス GO。数値は今後も都度調整可。

---

## 戦闘ステ一括スケール（2026-07-18 — P3-BAL-STAT-SCALE-001）

> オーナー指示: キャラ×8後に装備上昇幅を合わせ、続けて敵ステも同倍率。固定回復・Lv成長・DEF軽減Kも追随。

| # | 決定 | 根拠 |
|---|---|---|
| P3-BAL-STAT-SCALE-001-1 | **共通倍率 `BalanceConfig.STAT_SCALE=8`** | キャラ見栄えスケールと一致 |
| P3-BAL-STAT-SCALE-001-2 | **装備マスター×8** — 武器 `base_attack`／防具 DEF・HP／装飾 平坦ボーナス | 装備寄与が素体の数%しか無かった |
| P3-BAL-STAT-SCALE-001-3 | **ドロップロール上限×8**（ATK/DEF/HP）。属性値・率系は据置 | 相対ロール幅を維持 |
| P3-BAL-STAT-SCALE-001-4 | **炉研ぎ平坦** — ATK/DEF +8/Lv、防具HP +16/Lv | 旧 +1/+2 の同倍率 |
| P3-BAL-STAT-SCALE-001-5 | **敵 max_hp/attack/defense ×8** | 即死／ノーダメ化を防ぐ |
| P3-BAL-STAT-SCALE-001-6 | **`DEFENSE_MITIGATION_K`×8**・`HEAL_SKILL_BASE`×8・Lv成長平坦×8 | 曲線・回復・成長を同スケールに |
| P3-BAL-STAT-SCALE-001-7 | **セーブ v6** — 所持装備の平坦ステ×8マイグレーション | 旧インベントリ追従 |
| P3-BAL-STAT-SCALE-001-8 | **Affix 平坦** Attack/Defense/Healing ×8。率系据置 | 付与値の相対維持 |
| P3-BAL-STAT-SCALE-001-9 | **追随完了** — 図鑑手引き／鍛冶プレビュー／回復部屋・イベントheal／罠／spare_vial／DoT flat／コンボ flat／Threat taunt。docs・balance_sim 同期 | オーナー GO（洗い出し順） |

**Closeout（2026-07-18）:** マスター一括＋BalanceConfig＋追随UI/探索/DoT＋unit。実機で体感確認可。

---

## 調査許可等級アップ演出（2026-07-19 — P3-CMD-RANKUP-001）

> **オーナー依頼** — ランクアップ条件達成時、メイン（拠点）で紙吹雪＋「x級 ランクアップ！！」ポップアップ。

| # | 決定 | 根拠 |
|---|---|---|
| P3-CMD-RANKUP-001-1 | **検知** — `commander.acknowledged_rank` と現行 `current_rank()` を比較。SP 自体は非永続のまま | P3-CMD-001-2 整合 |
| P3-CMD-RANKUP-001-2 | **表示場所** — `BaseScene`（拠点ホーム）入場時。ダンジョン／結果画面では出さない | オーナー指定「メイン画面」 |
| P3-CMD-RANKUP-001-3 | **演出** — 暗転＋紙吹雪＋等級アイコン＋「{等級}級 ランクアップ！！」＋副題。タップで閉じる。SE=`level_up` | 戦闘クリア演出と同系 |
| P3-CMD-RANKUP-001-4 | **既存セーブ** — `acknowledged_rank` 欠落時は現行等級で埋める（ロード直後の誤表示防止） | 回帰回避 |
| P3-CMD-RANKUP-001-5 | **複数段ジャンプ** — 到達等級を一度だけ表示し、その等級まで ack | UX 簡潔 |

---

## ③〜⑤敵プール拡充（2026-07-20 — P3-ENEMY-002）

> **オーナー依頼** — ミストフェン／ブラックショア／フロストリッジへ雑魚各3＋Elite各1を追加。ステ・設定は Impl 委任。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ENEMY-002-1 | **③ mistfen** — 雑魚 `bone_picker` / `mire_strider_spider` / `spore_needle_wasp`（D2/D3/D4）＋ Elite `nightfen`。既存 Elite `great_claw` 併存 | オーナー指定＋P3-ENEMY-001 危険度幅 |
| P3-ENEMY-002-2 | **④ blackshore** — 雑魚 `black_tide_shark` / `tide_lamp` / `abyssal_squid`（D2/D3/D4）＋ Elite `anchor_lord`。既存 `ninja_octopus` 併存 | 同上 |
| P3-ENEMY-002-3 | **⑤ frostridge** — 雑魚 `ice_tail_fox` / `glacier_warden` / `wind_ripper`（D3/D4）＋ Elite `polar_tricera`。既存 `greios` 併存 | 同上 |
| P3-ENEMY-002-4 | **spawn_weights** — ③④⑤章データを P3-ENEMY-001 SSOT（D2/D3/D4 および D3/D4）へ同期 | 追加種が章別重みに乗るため |
| P3-ENEMY-002-5 | **Elite 複数** — Biome あたり Elite 2（均等抽選）。P3-ENEMY-001「Elite据置1」をオーナー指示で上書き | 明示リクエスト |
| P3-ENEMY-002-6 | **アート** — 戦闘／図鑑は既存近縁スプライトのプレースホルダ。本番ドットは後差し | ② ENEMY-002 同型 |

---

## ブルームサーペント一旦オミット（2026-07-20 — P3-ENEMY-WW-OMIT-001）

> **オーナー指示（2026-07-20）** — ウィスパーウッド接続時にドット／図鑑素材が無いため、ブルームサーペントを一旦オミット。

| # | 決定 | 根拠 |
|---|---|---|
| P3-ENEMY-WW-OMIT-001-1 | **`whisperwood` / `green_hollow` の `enemy_pool` から `bloom_serpent` を除外** | 出現停止 |
| P3-ENEMY-WW-OMIT-001-2 | **`EnemyData` / スプライト／図鑑マップは残置**（削除しない） | 再投入余地・旧参照互換 |
| P3-ENEMY-WW-OMIT-001-3 | **再有効化** — 本番ドット＋図鑑 PNG 受領後にプール復帰 | 別 Task |


---

## スキル／必殺ゲージ再設計（2026-07-21 — P3-COMBAT-GAUGE-001）

> **オーナー承認 GO** — 案B。装備スキル1本。必殺＝与ダメ・被ダメチャージ。満タン後は従来どおり AI が発動。下UI＝スキルゲージ＋必殺ゲージ。

| # | 決定 | 根拠 |
|---|---|---|
| P3-COMBAT-GAUGE-001-1 | **装備スキル上限＝1**（`MAX_EQUIPPED_SKILLS=1`）。P3-D077-2（2枠）を上書き。既存セーブは先頭1本に切り詰め。満枠時の新規装備は置換 | 並列2本ゲージが読みにくい。ビルドは「どれを1本持つか」 |
| P3-COMBAT-GAUGE-001-2 | **スキルゲージ**＝時間経過で増加（既存 CD の満タン＝使用可表示を維持）。1本のみ表示 | 視認可能な溜め演出を残す |
| P3-COMBAT-GAUGE-001-3 | **必殺ゲージ**＝与ダメージ・被ダメージでチャージ（時間 CD は使わない）。満タンで `ultimate_ready`。発動で 0 に戻す。必殺自身の与ダメではチャージしない | 「戦って貯める」差別化 |
| P3-COMBAT-GAUGE-001-4 | **チャージ係数（MVP・調整可）** — 上限 100。与ダメ ×0.10／被ダメ ×0.20 | 初速。実機で頻度調整 |
| P3-COMBAT-GAUGE-001-5 | **戦闘下カード**＝キャラ（顔・名）→ HP → スキルゲージ → 必殺ゲージの2段。旧①②並び廃止 | オーナー指定レイアウト |
| P3-COMBAT-GAUGE-001-6 | **満タン後の発動**＝戦術／ガンビットどおり即発射（温存しない） | オーナー指定「今まで通り」 |
| P3-COMBAT-GAUGE-001-7 | **罠ダメージは必殺チャージ対象外**。戦闘中の敵攻撃・敵スキル・DoT 被弾は対象 | 探索罠で貯まるのを防止 |

---

## 戦術プリセット表示名の一行化（2026-07-21 — P3-UI-TACTICS-LABEL-001）

> **オーナー承認 案A** — 挙動は据置。ドロップダウン名だけ「何をするか」が一行で分かる文言へ。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI-TACTICS-LABEL-001-1 | **display_name のみ変更**（id / plan / target 不変） | 案A＝改名のみ |
| P3-UI-TACTICS-LABEL-001-2 | **文言**: スキル優先（ピンチで防御）／スキル多用・火力寄り／防御多め／防御を最優先／強敵を集中攻撃／複数敵・弱体を優先 | オーナー提示の「一行でわかる」方針 |
| P3-UI-TACTICS-LABEL-001-3 | **探索方針は対象外**（今回は戦術のみ） | 相談スコープ |

---

## 必殺演出カットイン強化（2026-07-21 — P3-UX-ULTIMATE-002）

> **オーナー GO 案B** — 顔カットイン＋帯＋暗転＋シェイク。フレーム無し。ダメージ／回復どちらも派手。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UX-ULTIMATE-002-1 | **案B** — announce 段に顔アイコン＋ジョブ色帯の横スライドカットインを追加。中央テロップは帯上に統合 | 「名前だけ」感の解消 |
| P3-UX-ULTIMATE-002-2 | **顔は既存ポートレート／アイコン流用。レア枠・キャラ枠は付けない** | オーナー指定 |
| P3-UX-ULTIMATE-002-3 | **ダメージ必殺・回復必殺とも同格のフラッシュ／シェイク／リング** | オーナー指定「どちらも派手」 |
| P3-UX-ULTIMATE-002-4 | **新アート・職別専用VFXはスコープ外**（案Cは後続） | 最小で特別感 |
| P3-UX-ULTIMATE-002-5 | **尺** — 既存 announce/windup/release を維持（速度倍率スケール継続） | テンポ維持 |

---

## 序盤戦闘が易しすぎる再調整（2026-07-21 — P3-BAL-OPENING-001）

> **オーナー GO** — 案C・しっかり危ない・全ダンジョン。初期＋ガチャ★3＋ジャック編成で敵が紙に見える問題。

| # | 決定 | 根拠 |
|---|---|---|
| P3-BAL-OPENING-001-1 | **案C** — 敵を上げ＋味方ボーナスを圧縮。全ダンジョン共通 | 片方だけに寄せない |
| P3-BAL-OPENING-001-2 | **敵グローバル倍率** — HP ×1.50／ATK ×1.30（`BalanceConfig`・戦闘開始時に適用） | 「しっかり危ない」。tres 個別改変を避ける |
| P3-BAL-OPENING-001-3 | **味方★／個人ボーナス ×0.70**（`GachaRarityConfig.apply_base_stats`） | 初期火力・耐久の厚みを削る。素体800は据置 |
| P3-BAL-OPENING-001-4 | **人数補正にオトモを含める**（`combatant_count`） | ジャックが5人目なのに敵が4人前提だった穴を塞ぐ |
| P3-BAL-OPENING-001-5 | **DEF／EXP は据置**（今回はHP/ATKと味方ボーナスのみ） | スコープ最小化。実機後に再調整可 |

---

## 拠点ニーナ案内ナビ（2026-07-21 — P3-UI-NINA-NAV-001）

> **オーナー承認 案A** — ホーム右上・10秒切替・タップで次へ・自動おすすめ1件。

| # | 決定 | 根拠 |
|---|---|---|
| P3-UI-NINA-NAV-001-1 | **配置＝案A** ホーム右上に顔＋吹き出し（既存 `ART_NPC_Nina`） | オーナー指定 |
| P3-UI-NINA-NAV-001-2 | **自動切替 10秒**。タップで次へ（タイマーリセット） | オーナー指定 |
| P3-UI-NINA-NAV-001-3 | **ローテ**＝おすすめ1件 → 天気／今週の野外 → 雑談 | 優先度はこの順 |
| P3-UI-NINA-NAV-001-4 | **おすすめ優先**＝日課受取 → 日課未完了 → 編成空き → 次探索 → フォールバック | 自動1件 |
| P3-UI-NINA-NAV-001-5 | **タップ遷移・文字送り・新アートはスコープ外** | 案内のみ・導入ニーナと分離 |

SSOT: `docs/specs/decisions/03_HubNinaNav.md`

---

## 野外速報・30分スロット（2026-07-21 — P3-EVT-FIELD-001）

> **オーナー GO** — 推奨P1＋追記。30分固定切替。「何も無し」最頻。天候寄り／ダック／レイヴン等を追加。旧週次ローテを置換。

| # | 決定 | 根拠 |
|---|---|---|
| P3-EVT-FIELD-001-1 | **周期＝30分固定スロット**（全端末同時・anchor=2026-07-01 05:00 JST） | オーナー GO・案A |
| P3-EVT-FIELD-001-2 | **UI名＝「いまの野外」**（週次文言を置換） | 「今週」と矛盾するため |
| P3-EVT-FIELD-001-3 | **重み付きプール**。**none（穏やか）が最大重み** | オーナー指定 |
| P3-EVT-FIELD-001-4 | **追加種別** — 雨／夜／霧（ラン天候固定）・ダック目撃増・レイヴン目撃増・敵Lv+2・群れ↑・ELITE部屋↑ | 推奨P1＋オーナー追記 |
| P3-EVT-FIELD-001-5 | **経済系は残すが弱体**（概ね×1.2、図鑑×1.5） | FOMO抑制 |
| P3-EVT-FIELD-001-6 | **日次イベントDG（裂け目／巣）の開催ルールは変更しない**。放浪目撃増は通常探索のみ | 紛らわしさ分離 |
| P3-EVT-FIELD-001-7 | **P3-EVT-WEEK-002 の7日ローテは本 Decision で置換** | 実装一本化 |

SSOT: `docs/specs/decisions/04_FieldSurveySlots.md`

---

## 調査室・拠点調査サイクル（2026-07-22 — P3-HUB-SURVEY-001）

> **オーナー GO** — 目的 B（拠点サイクル＋②解禁）。報酬=素材・石主＋武器（★1–2低確率／稀に★3）。解放=①ボス＋調査ゲージクリア（70%）。UI=オーナー提示モック「調査室」構成準拠（下ナビは無視）。Phase1 から本実装。

| # | 決定 | 根拠 |
|---|---|---|
| P3-HUB-SURVEY-001-1 | **三系統** — SURVEY（永続解放進行）／DISPATCH（調査室サイクル）／ACHIEVE（図鑑実績）。混同禁止 | 放置と本編進行の分離 |
| P3-HUB-SURVEY-001-2 | **②解放** — ①ボス初回討伐 **かつ** ① SURVEY≥70%。100%=完全調査（解放必須にしない） | オーナー Q1=B |
| P3-HUB-SURVEY-001-3 | **調査室 UI** — モックの画面構成を正。**モック下ナビ案は無視**（調査室タブ追加なし）。**既存の通常 BottomNav は他画面どおり表示**。入室は左メニュー等 | オーナー訂正（2026-07-22） |
| P3-HUB-SURVEY-001-4 | **サイクル** — 短＋標準の実時間。完了=当該ラン100%で受取。Phase1 同時枠=1（拡張UIは後続） | Q2=C / Q5=A |
| P3-HUB-SURVEY-001-5 | **調査員配置** — 速度ボーナス（モックの担当スロット）。派遣中は編成ロック | モック準拠 |
| P3-HUB-SURVEY-001-6 | **報酬** — 主=素材・魔晶石。武器=★1–2低確率＋稀に★3。次DG手がかりは確定フレーバー／SURVEY加算 | Q4=A+C |
| P3-HUB-SURVEY-001-7 | **ACHIEVE** — 図鑑「実績」タブ・埋め％一回限り報酬 | 解放と分離 |
| P3-HUB-SURVEY-001-8 | **β封鎖更新** — `BETA_MOURNGATE_ONLY` 恒久封鎖を条件付き②解禁へ | Q3=A |
| P3-HUB-SURVEY-001-9 | **SSOT** — `docs/specs/decisions/05_HubSurveyRoom.md` | Decision 文書 |

