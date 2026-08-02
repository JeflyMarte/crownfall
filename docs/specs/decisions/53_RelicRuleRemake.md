# レリック効果ルール改変（8種差し替え）

**Status:** Decision 承認済（2026-08-02 — オーナー「goで」）  
**Impl:** `P3-BAL-RELIC-REMAKE-001`  
**関連:** P3-RELIC-PASSIVE／P3-UX-RELIC-TACTICS-B001／P3-BAL-RELIC-ACC-CD-001

---

## 1. 方針

レリックは各キャラ1枠の**入手困難なパッシブ付き装備**（解放型・同時装備は1人のみ）。  
帯は**ビルド拡張**（クリア必須にしない）。装備者中心。敵全体常時弱体／パーティ恒久大強化は原則NG。

既存8 ID は維持し、**名称・効果のみ差し替え**（セーブ互換）。

---

## 2. 差し替え一覧（数値初案＝本 Decision の正）

| ID | 新名称 | 効果 | 数値 |
|---|---|---|---|
| `relic_war_banner` | 指揮の軍旗 | 撃破時味方鼓舞＋オトモ強化／自身与ダメ↓ | 与ダメ 0.70／pet与 1.35・防 1.15／on_kill `empower` party |
| `relic_aegis_shard` | 身代わりの鏡 | 後衛被弾を確率で自分へ＋ガード | `redirect_rear_hit_chance` 0.40 |
| `relic_old_hourglass` | 連撃の歯車 | スキルCD短縮／必殺チャージ遅 | `skill_cd_mult` 0.70／`ultimate_charge_dealt_mult` 0.65 |
| `relic_berserker_charm` | 生命の脈 | 戦闘中リジェネ／与ダメ控えめ | 3秒ごと最大HP 2.5%／与ダメ 0.85 |
| `relic_hunter_sigil` | 一騎の契 | 標的特化 | mark +55%／非標的 0.70／pre_hit mark |
| `relic_reactive_aegis` | 吸血契約 | 与ダメの一部回復／被弾やや痛い | `lifesteal_ratio` 0.12／`incoming_mult` 1.08 |
| `relic_lament_ring` | 不死鳥の羽 | 致死1回耐えて低HP復帰／その後与ダメ↓ | `death_save_once`＋heal 30%＋outgoing 0.75×8s |
| `relic_scout_lens` | 宝箱の羅針 | 宝箱部屋率UP（戦闘火力触らない） | `treasure_room_weight_add` +20（combatから減） |

---

## 3. 配線

| キー | 発火点 |
|---|---|
| on_kill `party_rally` | 既存 `_fire_member_passives` |
| `redirect_rear_hit_chance` | 敵単体／スキル被弾前に後衛→装備者へ振替＋guard |
| `skill_cd_mult` / `ultimate_charge_dealt_mult` | 既存 |
| `combat_regen_*` | 戦闘中リアルタイム tick |
| mark focus | 既存 `relic_mark_focus_outgoing_mult` |
| `lifesteal_ratio` | 味方与ダメ適用後に自己回復 |
| `death_save_*` | `CombatController.apply_damage_to_member`（回復％・与ダメペナルティ延長） |
| `treasure_room_weight_add` | `DungeonController._resolve_room_weights` |

---

## 4. スコープ外

- 新レリック追加／入手経路変更
- アイコン差し替え（IDキー流用）
- 二度撃ちの砂・逆境の鐘（不採用）
