# エリート行動アイデンティティ（P3-BAL-ELITE-IDENTITY-001）

**ID:** P3-BAL-ELITE-IDENTITY-001  
**日付:** 2026-08-09  
**状態:** 承認（オーナー GO）  
**関連:** P3-BAL-ENEMY-SKILL-CA-001／35_EnemyTrickySkills／38_EliteBossPressure  
**上書き:** `P3-ENEMY-FR-OMIT-001` を一旦復帰させたが、**`116_FrostEliteMammoth` で `polar_tricera` 再オミット・`glacier_warden` が FR エリート**

## 要旨

エリートが「単／列ダメか通常」に見えやすい。1体＝覚えられる役割1つにキットを寄せ、章内で役割が被らないようにする。

## 確定ロール

| 敵 | ロール | 手段 |
|---|---|---|
| クロックモス | 加速旗 | 加速を主技（重み↑）。単独時は自己加速可 |
| 夜沼 | 再生沼 | 自己 regen ＋吸い取り。全体は従／撤去 |
| 大爪刀 | 処刑単体 | 断頭を主 |
| 深霧ワイバーン | 吐息専 | 凍霧を主（重み↑） |
| ミラーボア | 反術・後衛崩し | T7維持。後列毒を主 |
| グレイオス | 吹雪制圧 | 白嵐を主。槍突は後列 |
| 氷晶マンモス | 硬殻戦車 | 通常軽減＋氷晶の蹂躙（防御無視全体）。`116` |
| ~~極冠トリケラ~~ | ~~突進戦車~~ | **オミット**（`116`） |
| 深海司祭 | 墨の妨害 | T7維持。silence 主＋後列鞭 |
| アンカーロード | 錨タンク | 通常軽減＋錨打ち主 |

## ルール

1. `EnemyData.skill_weights` で主技バイアス（ボス位相が無いエリート用）
2. 同章で回復／AoE専／T7／甲殻を重複させない
3. エンジン新規は最小（既存 heal／regen／haste／silence／軽減）

## SSOT

- `resources/enemies/{elite}.tres`／関連 `resources/skills/enemy_*.tres`
- `EnemyData.skill_weights`
- `DungeonScene._pick_enemy_skill`／haste 単独時自己加速
- フロスト系 `elite_pool` に `greios`＋`glacier_warden`（`polar_tricera` はオミット）
