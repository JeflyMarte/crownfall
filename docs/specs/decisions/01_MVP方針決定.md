# MVP方針決定 v1.0

開発開始時に確定した仕様補完・追記事項。
これらは元仕様書を上書きする。

---

## 1. 装備枠

MVPでは3枠。

- 武器
- 防具
- 装飾品

正式版で4枠目「王遺産」を追加。MVPでは実装しない。

---

## 2. 味方死亡時の挙動

1人死亡しても探索は継続する。
3人全滅した時点で探索失敗とする。

---

## 3. 自動探索の進行方式

ステップ進行（部屋単位）を採用する。リアルタイム進行は不採用。

各部屋で戦闘・宝箱・イベントを処理し、完了後に次の部屋へ進む。

---

## 4. セーブタイミング

MVPでのセーブ発生タイミング。

- ダンジョン帰還時
- 鑑定完了時
- 装備変更時

リアルタイム保存は不要。

---

## 5. ゴールドの用途

MVP 初期方針: 鑑定費用のみ。

**現行（M8 以降 — P3-D024f）:**

| 用途 | 状態 | 備考 |
|---|---|---|
| 鑑定 | 実装済 | 100G/件（AppraisalScene） |
| 鍛冶 | 実装済 | BlacksmithScene（Phase2-M8） |
| 酒場消費 | Backlog | — |

SSOT 参照: `04_ゲームループ.md` §ゴールド用途 / `28_ゲームデザイン点検.md` §P3-D024f

---

## 6. 宝箱

MVPでの簡易仕様。

内容物：

- 武器
- 防具
- 装飾品
- ゴールド
- 素材

レアリティ設定：通常敵よりRare以上が出やすくする。

---

## 7. イベント

MVPでは仮仕様3種のみ実装する。

- 崩れた祭壇
- 古文書
- 封印扉

詳細内容は後のTaskで詰める。

---

## 8. 中ボス（MID_BOSS）

MVPでは「HPとドロップが高いエリート」として扱う。

固有行動は実装しない。

---

## 9. クリティカルビルド

MVPでは以下のみで成立させる。

- クリ率
- クリダメ
- 攻撃速度
- クリティカル時バフ

複雑な専用システムは後回し。

---

## 10. 防具・装飾品データ

ArmorData：HP・防御中心の簡易構造。
AccessoryData：Affix中心の簡易構造。
WeaponDataほど複雑にしない。

---

## 11. MVPゲームループ確定

BaseScene → DungeonScene → ResultScene → AppraisalScene → EquipmentScene → BaseScene の6シーン固定順とする。

パーティ編成・ダンジョン選択は正式版で追加。

---

## 12. AppraisalScene・EquipmentSceneをMVP対象に含める

鑑定と装備変更はBaseSceneに統合せず、それぞれ独立したシーンとして実装する。

ResultScene → AppraisalScene → EquipmentScene → BaseScene の導線とする。

---

## 13. 鑑定済み武器のみ装備可能

WeaponInstance.is_appraised が true の武器のみ EquipmentScene に表示し、装備できる。

未鑑定武器は AppraisalScene で鑑定するまで装備不可。

---

## 14. 装備状態の保存仕様

SaveManager は装備中武器を WeaponInstance.instance_id として保存する。

```json
"equipment": { "weapon": "<instance_id>" }
```

instance_id は `Time.get_ticks_msec() + "_" + randi()` 形式で生成し、インベントリ内での一意性を保証する。

---

## 15. equipment復元はinventory復元後に行う

_apply_save_data() 内で inventory → equipment の順に復元する。

装備武器の復元は inventory から instance_id で検索して参照を取得する。inventory 復元前に equipment を復元するとオブジェクト参照が取れずnullになる。

---

## 16. Gold報酬バランス（MVP調整済み）

1周で最低1回の鑑定（100G）を賄えるGold報酬に調整する。

MVP確定値：

| 敵 | gold_reward |
|---|---|
| 亡国兵 | 22 |
| 廃墟守兵 | 25 |
| 廃墟漁り | 28 |
| 錆剣騎士 | 35 |
| 王都守護兵長（ボス） | 150 |

王都跡1周（戦闘部屋クリア時）で150G以上獲得可能。

---

## 17. MVP UIテーマ

MVP期間中は `assets/ui/mvp_theme.tres` の単一Themeリソースを全シーンに適用する。

Button・Labelの共通スタイルを定義し、シーンごとのスタイル個別定義を行わない。

アート実装（本番UI）は正式版フェーズで行う。
