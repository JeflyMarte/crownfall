# Enemy_Bible_v1.0

**Status:** Completed
**Approved By:** DevelopmentHQ
**Version:** v1.0
**関連文書:**
- 12_モンスター（敵一覧仕様）
- 08_戦闘_AI（AI・ダメージ計算）
- 03_Resource設計（EnemyData定義）

---

## 1. 概要・位置づけ

EnemyはCrownfallにおけるプレイヤーの主要な障害であり、ダンジョン体験を構成する中心要素。

- 各Enemyは EnemyData（Resource）として定義する
- ダンジョンテーマごとに配置する敵を固定し、世界観の一貫性を保つ
- 武器特効・図鑑・イベント連携のため、Enemy Family分類を導入する

---

## 2. Enemy Family

EnemyはFamily（種族）によって分類される。

| Family | 説明 | 主なダンジョンテーマ |
|---|---|---|
| Human | 人間・元兵士・盗賊など生者の人類 | 王都跡 |
| Undead | 骸骨・死体・亡霊など死者の集合 | 白骸墓地 |
| Beast | 獣・狼・変異生物など自然の脅威 | 将来拡張 |
| Construct | 自動人形・ゴーレム・機械兵器など人工造物 | 地下工廠 |
| Demon | 悪魔・憑依存在など異界の脅威 | 将来拡張 |

### 用途

| 用途 | 内容 |
|---|---|
| 武器特効 | 特定Familyへの追加ダメージを持つ武器・Affixの判定に使用 |
| 図鑑 | プレイヤーの図鑑でFamily別に分類・表示 |
| ダンジョンテーマ | ダンジョンごとの出現Familyを固定して世界観を統一 |
| Event | Family依存イベントの判定に使用 |
| 将来のゲームシステム拡張 | Family耐性・AI挙動分岐・スキル効果分岐など |

---

## 3. Threat Level

各Enemyに Threat Level（危険度）を設定する。

| Threat Level | 定義 | 用途 |
|---|---|---|
| ★ | 序盤限定の弱体敵 | チュートリアル・入門ダンジョン |
| ★★ | 標準的な通常敵 | 通常Room・出現率高め |
| ★★★ | 強化された通常敵 | 後半Room・出現率中程度 |
| ★★★★ | エリート・中ボス候補 | 特殊Room・出現率低め |
| ★★★★★ | ボス | ボスRoom固定 |

### Threat Levelの用途

| 用途 | 内容 |
|---|---|
| 出現率 | Threat Level が高いほど出現確率を下げる |
| Elite候補 | ★★★★以上をElite扱いの判定基準にする |
| Room生成 | ボスRoomは★★★★★のみ配置。特殊Roomは★★★★以上を優先 |
| ダンジョン難易度調整 | ダンジョン難易度に応じてThreat Level上限・出現比率を調整する |

---

## 4. EnemyData 設計

EnemyDataはマスターデータ（Resource）として定義する。

### フィールド

| フィールド | 型 | 説明 |
|---|---|---|
| id | String | 識別ID（例: fallen_soldier） |
| display_name | String | 表示名 |
| max_hp | int | 最大HP |
| attack | int | 攻撃力 |
| defense | int | 防御力 |
| attack_speed | float | 攻撃速度（将来CombatTimerに接続） |
| critical_rate | float | クリティカル率 |
| move_speed | float | 移動速度（将来実装） |
| detection_range | float | 感知範囲（将来実装） |
| attack_range | float | 攻撃射程（将来実装） |
| enemy_type | int | 内部分類ID（enum予定） |
| ai_type | String | AIパターン識別子 |
| exp_reward | int | 撃破時EXP報酬 |
| gold_reward | int | 撃破時Gold報酬 |
| drop_table_id | String | ドロップテーブルID |

### Family・Threat Levelの扱い

MVP時点ではEnemyDataにfamilyおよびthreat_levelフィールドは未追加。本仕様をもとに将来フェーズでフィールドを追加する。

---

## 5. 敵一覧 — 王都跡（Human）

王都跡に出現する敵。Family = Human。

| 敵ID | 表示名 | HP | ATK | DEF | EXP | Gold | Threat Level | 備考 |
|---|---|---|---|---|---|---|---|---|
| fallen_soldier | 亡国兵 | 80 | 12 | 5 | 10 | 22 | ★★ | 標準的な近接敵 |
| ruined_guard | 崩れた衛兵 | 100 | 15 | 8 | 12 | 25 | ★★ | 亡国兵より堅め |
| ruins_looter | 王都の盗掘者 | 70 | 20 | 3 | 11 | 28 | ★★ | 高ATK・低DEF |
| rusted_knight | 朽ちた騎士 | 160 | 12 | 22 | 25 | 35 | ★★★ | 重装・高防御 |
| royal_guard_captain | 王都守護兵長 | 600 | 35 | 18 | 120 | 150 | ★★★★★ | ボス |

### MVP実装状況

全5体のEnemyDataが `.tres` として実装済み。

---

## 6. 敵一覧 — 白骸墓地（Undead）

白骸墓地に出現する敵。Family = Undead。ステータスは将来Taskで確定する。

| 敵ID | 表示名 | Threat Level | 備考 |
|---|---|---|---|
| skeleton_soldier | 骸骨兵 | ★★ | 標準的な近接Undead |
| corpse_carrier | 死体運び | ★★ | 低速・高HP |
| bell_ringer | 鐘鳴らし | ★★★ | 支援型・他の敵を強化 |
| bone_hound | 白骨の番犬 | ★★★ | 高速・連続攻撃 |
| great_bell_keeper | 千鐘の墓守 | ★★★★★ | ボス |

### MVP実装状況

EnemyData未実装。将来Taskで追加する。

---

## 7. 敵一覧 — 地下工廠（Construct）

地下工廠に出現する敵。Family = Construct。ステータスは将来Taskで確定する。

| 敵ID | 表示名 | Threat Level | 備考 |
|---|---|---|---|
| broken_automaton | 壊れた自動人形 | ★★ | 標準的な機械兵 |
| furnace_worker | 炉心作業兵 | ★★ | 近接・炎属性候補 |
| iron_hound | 鉄の番犬 | ★★★ | 高速・突進型 |
| mass_golem | 量産型ゴーレム | ★★★★ | エリート・高耐久 |
| furnace_giant | 炉心の巨人 | ★★★★★ | ボス |

### MVP実装状況

EnemyData未実装。将来Taskで追加する。

---

## 8. AIパターン

| ai_type | 説明 | MVP実装状況 |
|---|---|---|
| default | 近接攻撃・ランダムターゲット | **実装済み** |
| ranged | 遠距離攻撃 | 将来実装 |
| rush | 突進型 | 将来実装 |
| summon | 召喚型 | 将来実装 |
| support | 支援型（他の敵を強化） | 将来実装 |
| trap | 罠型 | 将来実装 |

---

## 9. MVP実装サマリー

| 項目 | 状態 |
|---|---|
| EnemyData Resource | **完了** |
| 王都跡 5体 (.tres) | **完了** |
| 自動戦闘（default AI） | **完了** |
| ATK / DEF / HP 計算接続 | **完了** |
| EXP / Gold 報酬 | **完了** |
| Enemy Family フィールド | 将来実装 |
| Threat Level フィールド | 将来実装 |
| 白骸墓地 5体 | 将来実装 |
| 地下工廠 5体 | 将来実装 |
| 遠距離・突進・召喚・支援 AI | 将来実装 |
| attack_speed 接続 | 将来実装（CombatTimer） |
| 状態異常（出血） | 将来実装 |

---

## 10. 将来拡張候補

- EnemyDataにfamilyおよびthreat_levelフィールドを追加
- 白骸墓地・地下工廠のEnemyData実装
- Beast / Demon Family のダンジョンテーマ追加
- 武器Affixへの武器特効（Family別ダメージ補正）接続
- 図鑑システム（Family別表示・解放条件）
- ai_typeの拡張（ranged / rush / summon / support / trap）
- Threat Levelを使った動的Room生成
- attack_speed の CombatTimer への接続
