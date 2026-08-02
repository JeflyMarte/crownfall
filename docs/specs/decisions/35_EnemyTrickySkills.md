# 敵トリッキースキル多様化

**Status:** Decision 承認済（2026-08-02 — 相談方針 GO／未決は本 Decision 既定でクローズ）  
**Impl:** Phase1〜3 ✅（`P3-BAL-ENEMY-TRICKY-001`〜`003`）／章展開 ✅（`P3-BAL-ENEMY-TRICKY-004`）／軽減テロップ ✅（`P3-UX-ENEMY-RESIST-TELOP-001`）
**関連:** P3-BAL-ENEMY-SKILL-CA-001／FIT-001／AUDIT-001／P3-D079

---

## 1. 方針

敵キットを「単／列ダメ＋状態」一辺倒から広げ、**ところどころのトリッキー個体**だけに特殊役割を載せる。  
全敵への一律付与はしない。ボス位相の全面置換もしない。

| 原則 | 内容 |
|---|---|
| スポット配置 | 1戦闘あたりトリッキーは原則 0〜1体 |
| 連発禁止 | 同一タイプを章内で連発しない |
| 読み | T2/T3＝回復／バフ役を優先キル。T6⇔T7 は突破手段が対になる |
| 段階実装 | Phase1（T1〜T3）→ Phase2（T5）→ Phase3（T4/T6/T7） |

---

## 2. 相談クローズ（実装前の未決）

| 項目 | 確定 |
|---|---|
| T6/T7 軽減倍率 | **被ダメ ×0.2**（80%カット）。完全無効（×0）は禁止 |
| Phase1 パイロット | **既存敵のキット差し替え／1本追加**。新敵・新アートなし |
| 図鑑 | **短いヒントを出す**。T6/T7 は図鑑生態 or 特徴1行必須。T1〜T3 はスキル説明で可読なら図鑑追記は任意 |

---

## 3. 7タイプ定義

| ID | タイプ | 挙動 | 難度 | 配置 |
|---|---|---|---|---|
| T1 | 全体状態バラマキ | 低〜無ダメ＋パーティ全体へ状態。既存 `apply_status_*` | 低 | 群れ1体 |
| T2 | 回復 | `effect_type=heal` を敵実行経路へ。自己 or 味方敵 | 中 | サポ1〜2種／章 |
| T3 | 敵味方バフ | `buff` を他スロット敵へ解決（自己 enrage のみから拡張） | 中 | 旗持ち1体 |
| T4 | 自爆 | 発動後自スロット撃破＋パーティ AoE。報酬／EXPは **通常撃破扱い** | 高 | 希少専用 |
| T5 | 逃走 | スキル／条件発火で逃走。報酬は放浪と同型で **なし** | 中 | 金／レア寄り |
| T6 | 通常が効きにくい | 通常攻撃被ダメ ×0.2 | 高 | 甲殻テーマ |
| T7 | スキルが効きにくい | スキル／必殺被ダメ ×0.2。通常は普通 | 高 | 反術・鏡テーマ |

### Phase 分割

| Phase | 含む | Task ID | 状態 |
|---|---|---|---|
| 1 | T1 / T2 / T3 | **P3-BAL-ENEMY-TRICKY-001** | ✅ |
| 2 | T5 | **P3-BAL-ENEMY-TRICKY-002** | ✅ |
| 3 | T4 / T6 / T7 | **P3-BAL-ENEMY-TRICKY-003** | ✅ |

---

## 4. パイロット割当（全 Phase・確定）

新敵なし。スポット配置。

| タイプ | パイロット敵 | 実装 |
|---|---|---|
| T1 | **`spore_widow`** | `enemy_spore_cloud` 低ダメ＋高毒率 |
| T2 | **`moss_shell`** | `enemy_moss_mend`（heal） |
| T3 | **`rune_roach`** | `enemy_rune_ward`（他敵 enrage）。carcinos 据置 |
| T5 | **`grave_bell_bat`** | `enemy_grave_flee`（報酬なし逃走） |
| T4 | **`crystal_hedgehog`** | `enemy_crystal_burst`＝explode（撃破報酬あり） |
| T6 | **`skull_turtle`** | `incoming_basic_mult=0.2` |
| T7 | **`mirror_boa`** | `incoming_skill_mult=0.2` |

### 章展開パイロット（`P3-BAL-ENEMY-TRICKY-004`）

スポット配置のまま、未カバー章へ各2体。エンジン追加なし。

| 章 | 敵 | タイプ | 実装 |
|---|---|---|---|
| ミストフェン | **`blood_leech`** | T2 | `enemy_mire_mend`（heal） |
| ミストフェン | **`mist_mantis`** | T7 | `incoming_skill_mult=0.2` |
| フロストリッジ | **`wind_ripper`** | T5 | `enemy_rift_flee`（報酬なし逃走） |
| フロストリッジ | **`glacier_warden`** | T6 | `incoming_basic_mult=0.2` |

---

## 5. 技術フック（実装済）

- `effect_type`: `heal` / `flee` / `explode`（＋既存 damage/buff）
- `EnemyData.incoming_basic_mult` / `incoming_skill_mult`（DoT は非適用）
- `_deal_member_damage_to_enemy` で通常／スキル分類して倍率

---

## 5.1 軽減フィードバック（`P3-UX-ENEMY-RESIST-TELOP-001`・案A）

T6/T7 で被ダメ倍率が効いたとき、**戦闘内・スロット×（通常/スキル）で初回のみ**敵頭上テロップ＋ログ。

| 項目 | 確定 |
|---|---|
| 文言 | 「通常攻撃が通りにくい」／「スキルが通りにくい」（定型） |
| 頻度 | 毎回禁止。キー `slot:basic|skill` で1回 |
| 見た目 | `◇`＋状態付与テロップ同寸・シェイクなし |
| 対象外 | DoT／属性耐性ログ／逃走・自爆・回復の別演出 |

---

## 6. スコープ外（本 Decision 全体）

- 全雑魚へのトリッキー一律付与
- ボスキットの全面置換
- T6/T7 の完全無効
- Phase2/3 の同時実装（別 Task）
- 属性耐性・Miss の同型テロップ横展開（別 Task）

---

## 7. Impl Task — Phase1（発行済み・実装は別セッション）

```text
Task: P3-BAL-ENEMY-TRICKY-001（敵トリッキー Phase1 = T1/T2/T3）

Read:
- docs/project/CurrentState.md
- docs/project/CurrentSprint.md
- docs/specs/decisions/35_EnemyTrickySkills.md
- docs/specs/core/03_Decision_Log.md（P3-BAL-ENEMY-TRICKY-001 節のみ）
- docs/specs/implementation/CODEMAP.md（skills / enemies / DungeonScene 行）
- scripts/data/SkillData.gd
- scripts/data/EnemyData.gd
- DungeonScene の _execute_enemy_skill / _try_enemy_skill

Do:
- 敵スキル実行に heal 分岐を追加（自己／味方敵ターゲット解決）
- buff を他敵スロットへ付与できるようターゲット解決を拡張
- T1: 低〜無ダメ全体状態のパイロット技（既存流用可）
- T2/T3: パイロット各1体にキット反映（§4）
- スキル説明を可読に。図鑑追記は任意（T1〜T3）
- ユニット or headless で実行経路を確認
- CurrentState / CODEMAP を必要最小更新

Do NOT:
- T4 自爆 / T5 逃走スキル / T6・T7 軽減
- 新敵・新アート追加
- 全雑魚への横展開
- ボス位相の書き換え
- skill_use_chance の章全体いじり（パイロット個体のみ可）

Done when:
- Decision §3 Phase1（T1〜T3）がパイロットで動く
- 1戦闘にトリッキーが群れ全員に載っていない
- GUT or smoke 相当の確認結果を報告
```
