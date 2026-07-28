# 14 — ダンジョン演出・ナラティブ落とし穴（再発防止）

宝箱結果コメントが「探索を開始した」に戻る類のミスを、同系統ごと防ぐためのチェックリスト。  
詳細既往表: `.cursor/rules/known-pitfalls.mdc`。本ファイルは **レビュー／Impl 前の確認用**。

---

## 1. 下帯ナラティブ（RichText vs Label）

| BAD | GOOD |
|---|---|
| `_set_room_narrative_bbcode(結果)` の直後に `_reset_narrative_typography()` | 結果は次フロア入場まで残す（碑文成功と同じ） |
| BBCode だけ更新し Label を放置 | `_set_room_narrative_bbcode` で Label にも平文同期（`strip_bbcode`） |
| 入場文を上書きせずにモード切替 | `_reset_narrative_typography` は Rich 表示中は no-op |
| 非戦闘ナラティブだけ本文フォント（Noto） | 図鑑登録テロップと同じ `apply_display` / `apply_display_rich`（Shippori） |

**症状:** 宝箱／泉／碑文／罠の直後に「〜の探索を開始した」や空帯が出る。

---

## 2. 味方非表示のまま VFX／ダメージ数字

| BAD | GOOD |
|---|---|
| `_hide_chr_sprites()` 後に `_spawn_damage_number` / heal VFX | 先に `_begin_noncombat_party_feedback()` |
| `_member_sprite_world_pos` が非表示で `ZERO` → VFX スキップ | カード位置フォールバック、または表示してから出す |
| ペナルティ適用だけして即 `_finish_room` | 数字が見える短い hold の後に `_end_noncombat_party_feedback()` |

**対象フロー:** 宝箱失敗／泉失敗／碑文失敗／罠ヒット／`on_noncombat_enter` 回復／碑文回復・加護。

---

## 3. スキル名ポップの SE

`_spawn_skill_name` の既定 `sfx_id` は **`combat_skill`（ヒット寄り）**。

| 用途 | 渡す sfx |
|---|---|
| 通常攻撃・ダメージスキル resolve | `combat_skill`（既定）で可 |
| 回復・バフ・パッシブ名・加護・武器名ポップ | `""`（無音）。SE は heal/buff/hit 側 |
| 詠唱中 `persist=true` | もともと無音 |

**症状:** 回復やパッシブ名と同時にダメージ音が鳴る。

---

## 4. 戦闘開始前の impact SE

| BAD | GOOD |
|---|---|
| CT 開始前に `combat_hit` / `combat_heal` / `combat_buff` 直鳴らし | `CombatImpactSfxGate` + `_combat_impact_sfx_enabled` |
| 遅延ヒットで前戦闘の SE | `_combat_session_id` 照合 |

例外（導入演出）: ボス着地・罠部屋ヒットなど。新規に Gate 外で鳴らすときは Decision／コメント必須。

---

## 5. グローバル／組み込み名の衝突

| BAD | GOOD |
|---|---|
| 静的ヘルパ `wrap` / `lerp` / `clamp` を同ファイルから短引数で呼ぶ | `bb_wrap` など衝突しない名前 |

**症状:** Parse Error → `DungeonScene` 未ロード → 入場即終了。

---

## Impl / レビュー時チェック（短縮）

非戦闘部屋（宝箱・泉・碑文・罠）を触ったら:

1. [ ] 結果コメントを出したあと `_reset_narrative_typography` していないか
2. [ ] ダメージ／回復数字の直前に味方が見えるか（または位置フォールバックがあるか）
3. [ ] 名ポップが回復・バフなのに `combat_skill` のままになっていないか
4. [ ] 入場〜CT開始前に幽霊 SE が増えていないか
5. [ ] headless で `DungeonScene` ロードが通るか

---

## 関連

- `.cursor/rules/known-pitfalls.mdc`
- `.cursor/rules/gdscript.mdc`（命名衝突・SE）
- `.cursor/rules/recurrence-prevention.mdc`
- Decision: 非戦闘ナラティブ色分け / 宝箱演出（`03_Decision_Log.md`）
