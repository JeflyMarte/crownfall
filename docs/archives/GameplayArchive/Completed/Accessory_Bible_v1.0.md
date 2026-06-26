# Accessory_Bible_v1.0

**Status:** Completed
**Approved By:** DevelopmentHQ
**Version:** v1.0
**関連文書:**
- Phase2_Accessory_System_v1.0（基盤実装）
- Phase2_Accessory_Loot_Appraisal_v1.0（Loot/Appraisal統合）

---

## 1. 概要・位置づけ

Accessoryは武器・防具に続く第3の装備枠。

- 武器がダメージ出力を担う
- 防具がHP・防御を担う
- **Accessoryは補助効果と運（Luck）を担う**

AccessoryはWeapon / Armorの性能を補完し、ビルドの方向性を微調整する役割を持つ。

Accessoryが「ゲームの主役」になることはない。あくまで武器体験を引き立てる補助装備として設計する。

---

## 2. AccessoryData 設計

AccessoryDataはマスターデータ（Resource）として定義する。

### フィールド

| フィールド | 型 | 説明 |
|---|---|---|
| accessory_id | String | 識別ID（例: silver_ring） |
| display_name | String | 表示名 |
| rarity | int | Rarity enum値 |
| hp_bonus | int | HP加算値 |
| attack_bonus | int | 攻撃力加算値。武器性能を超えない微小補正 |
| defense_bonus | int | 防御力加算値 |
| crit_rate_bonus | float | クリティカル率加算値 |
| luck_bonus | float | 幸運値 |

### 設計原則

- 効果値はAccessoryDataに固定値として定義する（ランダムロールなし）
- AccessoryInstanceは効果値を持たず、IDでAccessoryDataを参照して取得する
- attack_bonusは武器性能を超えない微小補正として設計する。Accessoryが攻撃の主役になることはない

---

## 3. AccessoryInstance 設計

AccessoryInstanceは個体データ（Resource）として定義する。

### フィールド

| フィールド | 型 | 説明 |
|---|---|---|
| instance_id | String | 個体識別ID |
| accessory_id | String | 参照するAccessoryDataのID |
| is_appraised | bool | 鑑定済みフラグ |

### 武器個体・防具個体との差分

AccessoryInstanceはロール値を持たない。武器個体が攻撃力ロール値、防具個体が防御力ロール値を個体ごとに持つのに対し、AccessoryInstanceはIDで参照するのみ。これはAccessoryが「固定効果型の補助装備」であるためである。

---

## 4. 効果値仕様

### MVP接続状況

| 効果値 | MVP接続状況 | 適用先 |
|---|---|---|
| attack_bonus | **接続済み** | 攻撃ダメージに加算 |
| defense_bonus | **接続済み** | 敵ダメージの軽減計算に加算 |
| crit_rate_bonus | **接続済み** | クリティカル率に加算 |
| hp_bonus | 未接続（保存済み・将来実装） | 戦闘HP上限への加算は将来実装 |
| luck_bonus | 未接続（保存済み・将来実装） | セクション5「Luck仕様」参照 |

### 防御計算式（確定）

```
総防御力 = 防具防御値 + 装飾品防御補正
最終ダメージ = max(1, 敵攻撃力 - 総防御力)
```

最低1ダメージ保証。Luck・Resistanceは別計算系。

---

## 5. Luck仕様

### 影響範囲（確定版）

Luckは以下のみに影響する。

| 影響先 | 内容 |
|---|---|
| Rare Drop率 | ドロップ発生時のRarity上限を引き上げる |
| Treasure Quality | 宝箱部屋の内容物品質を向上させる |
| Event Success率 | イベント成功判定の確率を高める |
| 将来システム | 未定義拡張ポイント（例: 商人値引き、隠し部屋発見率） |

### 影響しないもの（明示的除外）

- Critical発生率（武器クリティカル率と装飾品クリティカル補正のみで決定）
- 攻撃力・防御力
- EXP / Gold報酬量

### MVP実装状況

Luckはluck_bonusとしてAccessoryDataに保持・AccessoryInstanceに引き継がれているが、MVP時点では戦闘・ドロップへの接続なし。将来フェーズでDrop / Event Systemへ接続する。

---

## 6. 入手方法・優先順位

プレイヤーがAccessoryを入手できる経路。優先順位順に記載する。

| 順位 | 経路 | 詳細 |
|---|---|---|
| 1 | **Dungeon Reward** | ダンジョン終了時に一定確率でドロップ。主要入手経路 |
| 2 | **Treasure Room** | ダンジョン内の宝箱部屋で取得可能 |
| 3 | **Boss Reward** | ボス撃破時のドロップ報酬 |
| 4 | **Merchant**（補助入手） | 拠点商人からGold購入。入手の補助手段 |

### MVP実装状況

MVP時点ではDungeon Rewardのみ実装済み。Treasure Room / Boss Reward / Merchantは将来実装。

---

## 7. 鑑定仕様

Accessoryは入手時に未鑑定状態で追加される。

| 項目 | 仕様 |
|---|---|
| 鑑定コスト | **100G**（武器・防具と統一） |
| 鑑定後 | 鑑定済みとなり、効果値がUIに表示される |
| 鑑定ロジック | 鑑定システムで処理する |
| 未鑑定表示 | `・未鑑定の装飾品 [accessory_id]` |
| 鑑定ログ | `鑑定完了: accessory_id` |

---

## 8. 装備仕様

| 項目 | 仕様 |
|---|---|
| 装備条件 | 鑑定済みであること |
| 装備操作 | 装備画面から選択して装備する |
| 保存 | 装備した装飾品はセーブデータに保存される |
| 復元 | 起動時にセーブデータから復元する |
| 外し操作 | 将来実装 |

---

## 9. MVP実装サマリー

| システム | 状態 |
|---|---|
| AccessoryData Resource | **完了** |
| AccessoryInstance Resource | **完了** |
| 所持品・装備管理 | **完了** |
| Save / Load | **完了** |
| Dungeon Loot（一定確率ドロップ） | **完了** |
| Appraisal（100G） | **完了** |
| Equipment（装備・UI表示） | **完了** |
| 戦闘接続（attack / defense / crit_rate） | **完了** |
| hp_bonus接続 | 将来実装 |
| luck_bonus接続 | 将来実装 |
| Treasure Room入手 | 将来実装 |
| Boss Reward入手 | 将来実装 |
| Merchant入手 | 将来実装 |

---

## 10. 将来拡張候補

- hp_bonus を戦闘HPへ接続
- luck_bonus をドロップRarity判定へ接続
- luck_bonus を Event成功判定に接続
- Treasure Room・Boss Reward・Merchant 入手経路の実装
- Accessory複数スロット（正式版候補）
- Set Effect（Accessory + Weapon の組み合わせ効果）（Phase3候補）
