# 14 — ダンジョン演出・ナラティブ落とし穴（再発防止）

宝箱結果コメントが「探索を開始した」に戻る類のミスを、同系統ごと防ぐためのチェックリスト。  
詳細既往表: `.cursor/rules/known-pitfalls.mdc`（按需・ポインタ）。本ファイルは **レビュー／Impl 前の確認用 SSOT**。

---

## 1. 下帯ナラティブ（RichText vs Label）

| BAD | GOOD |
|---|---|
| `_set_room_narrative_bbcode(結果)` の直後に `_reset_narrative_typography()` | 結果は次フロア入場まで残す（碑文成功と同じ） |
| BBCode だけ更新し Label を放置 | `_set_room_narrative_bbcode` で Label にも平文同期（`strip_bbcode`） |
| 入場文を上書きせずにモード切替 | `_reset_narrative_typography` は Rich 表示中は no-op |
| 非戦闘ナラティブだけ本文フォント（Noto） | 図鑑登録テロップと同じ `apply_display` / `apply_display_rich`（Shippori） |
| 下帯サイズが部屋／段階で変わる（22↔26） | `NARRATIVE_BAND_FONT_SIZE` 固定。`_set_room_narrative_bbcode` に size 引数を持たせない |
| Rich `fit_content` で説明1行↔報酬複数行の枠高が跳ぶ | `NARRATIVE_BAND_HEIGHT_PX` 固定＋縦中央。Rich は `fit_content=false` |
| 入手行が文字だけ（アイコン無し） | `NonCombatNarrativeColors` の金／素材／武飾／加護に汎用 `[img]` |
| 碑文加護を自動フェードで消す／泉に緑数字無し／宝箱を単色 Label | 碑文テロップは次フロア入場まで。加護効果は次の戦闘フロアまで。泉は緑VFX＋緑数字。宝箱は BBCode で金／武／飾色分け |
| 野戦調合／野営の調合で緑VFXだけ・+N無し／即 hide | `_present_member_heal`（VFX+緑数字）。非戦闘入場は短い hold 後に `_end_noncombat_party_feedback` |
| 分かれ道・応急手当がログだけ／暗転中に演出／中央テロップだけ違う | HPは入場時適用、VFX・+N・**スキル名ポップ**・SEは暗転明け（戦闘は `_on_room_transition_finished`、非戦闘は overlay 待ち）。中央 display テロップ禁止。SEは泉と同型で直鳴らし |

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

## 3. スキル名ポップの SE・サイズ

`_spawn_skill_name` の既定 `sfx_id` は **`combat_skill`（ヒット寄り）**。

| 用途 | 渡す sfx / サイズ |
|---|---|
| 通常攻撃・ダメージスキル resolve | `combat_skill`（既定）で可。フォント28 |
| 回復・バフ・パッシブ名・加護・武器名ポップ | `""`（無音）。SE は heal/buff/hit 側。`PASSIVE_NAME_FONT_SIZE`（18） |
| パッシブ発動なのに名が出ない | 発動前 `_clear_member_skill_labels`／`sprite.visible==false` で return | `_announce_passive_fire`＋`allow_hidden_sprite`。名は積む（消さない） |
| 状態付与「〇〇を付与！」 | `STATUS_APPLY_TELOP_FONT_SIZE`（22）。48px 禁止 |
| T6/T7 軽減が毎回テロップ | `_try_announce_enemy_incoming_resist`＋`EnemyResistTelop` キーで戦闘内1回。毎回禁止 |
| T8召集で群れUIが消える | `_show_enemy_swarm` 全クリア禁止。`_reveal_appended_enemy_slot` で増分 |
| T8途中召集で強制終了（Lambda capture freed） | `_ensure_swarm_slots` は `DUPLICATE_SIGNALS` なし＋named handler。既存スロットの `sprite_frames`／`play("idle")` を潰さない。スキル名ラベルは `free()` 禁止 |
| 敵スキル名 | 味方と同型で `_sprite_top_y_global`／スロット指定。`【技名】`＋同寸。`global_position-150` 固定＋`visible` 即 return 禁止 |
| 敵通常攻撃名 | 通常攻撃も `_spawn_enemy_skill_name`＋`EnemyData.basic_attack_name`（P3-UX-ENEMY-BASIC-NAME-001）。❗️のみに戻さない |
| 詠唱中 `persist=true` | もともと無音 |

**症状:** 回復やパッシブ名と同時にダメージ音／敵技名が見えない／付与テロップがダメ数字より大きい。

---

## 4. 戦闘開始前の impact SE・入場音

| BAD | GOOD |
|---|---|
| CT 開始前に `combat_hit` / `combat_heal` / `combat_buff` 直鳴らし | `CombatImpactSfxGate` + `_combat_impact_sfx_enabled` |
| 遅延ヒットで前戦闘の SE | `_combat_session_id` 照合 |
| 戦闘行きで `room_enter`／黒幕中に戦闘 BGM 切替 | 戦闘行きは `room_enter` スキップ。BGM は一幕後 |
| 帯VFXを `ColorRect` 手続き生成 | ColorRect 禁止。`FX_Band_*.tres` があるときだけ再生。未配置は無演出 |

例外（導入演出）: ボス着地・罠部屋ヒットなど。新規に Gate 外で鳴らすときは Decision／コメント必須。

---

## 5. ヒットタイミング・必殺・入場テロップ

| BAD | GOOD |
|---|---|
| `play("attack")` と同フレームでダメ適用 | ヒットは `ATTACK_IMPACT_FRAME_RATIO` まで遅延＋cinematic lock |
| 必殺 resolve 同フレームで攻撃開始＋全 VFX／ダメ数字 | windup 開始で攻撃開始。ダメ必殺の resolve はヒット側。Heal／attack テクスチャは入場時ウォーム |
| 必殺回復数字を `ULTIMATE_GOLD` | 回復は `HEAL_NUM_GREEN`。金はダメージ必殺用 |
| ボス大技バナーを短い固定 hold | `UltimatePresentationConfig` の announce+windup。効果1行＋`combat_ultimate` |
| エリート入場で中央「エリート」Label | 中央テロップ禁止。遷移 `[エリート]`＋ネームバッジのみ |
| ボス警告中に本体が先に写る | 警告中は `visible=false`。落下開始で初めて表示。状態tintが modulate を WHITE に戻すので intro 中は tint／HPバー更新を止める |
| 戦闘／エリートで部屋名を省略しすぎ | `[種別]\nF` を出す。ボスのみ専用入場で省略可 |
| 「自動戦闘中」行を戦闘で再表示 | 行は常時 `false`。停止はヘッダ ButtonStop |

---

## 6. オーバーレイ z・敵サイズ・行動順

| BAD | GOOD |
|---|---|
| PauseOverlay `z_index` ＜ HPバー／行動順 | Pause は CanvasLayer 55 |
| 状態異常アイコンが敵HPバー裏／ネーム帯と同帯 | `COMBAT_OVERLAY_Z+3`＋ネーム（エリートはバッジ）上端より上 |
| ボスの激昂など頭上アイコンが付かない | `_update_status_icons` がボス時に行を全非表示にしていた | ボスも `_boss_sprite` 上に表示。スタック上端は `_enemy_nameplate.offset_top` |
| ボス／エリートを雑魚と同寸、またはボス過大で Header 貫通 | `BOSS_BODY_*`／`ENEMY_BODY_SCALE_MULT`／`FROSTRIDGE_SOLO_DISPLAY_SCALE`。群れは体数スケール |
| ボス呼び出し敵が BossSprite に隠れる／slot0 二重表示 | BossSprite 据置＋連れは `BossSummonLayout` で左右手前。slot0 群れ非表示。HP/状態も連れ分表示 |
| 連れネーム／技名がボス胴体に貼る | 立ち位置オフセット拡大＋`overlay_nudge_px` で外側・上へクリアランス |
| 2体召喚の右連れだけ胴に戻る | 右オフセットが `X_MAX` クランプ。2体時はボス錨左寄せ（`layout_boss_ratio`） |
| 複数敵が右にはみ出す（ratio>0.9） | `_swarm_x_ratio_for_slot` で MIN/MAX 内 |
| 行動順敵アイコンに紫板を PNG 焼込 | 焼込禁止。枠は常に `CombatUiFrames`（焼込枠前提で UI 枠を外すと縁なし／薄く見える）。差替後 `.godot/imported` の `ICO_ENM_Turn_*` を消して再インポート |
| 状態異常レジェンドに半透明 Panel | `StyleBoxEmpty`（アイコン＋文言のみ） |
| 戦闘ログ最上行が見切れる | `BATTLE_LOG_LINE_HEIGHT` と上余白を本文サイズに同期 |

---

## 7. グローバル／組み込み名の衝突

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

戦闘演出／テロップ／敵サイズを触ったら:

6. [ ] ヒットがアニメ中盤以降か／必殺 resolve が同フレーム集中していないか
7. [ ] Pause／状態異常アイコンの z が HPバーより上か
8. [ ] 帯VFXに ColorRect を戻していないか

---

## 関連

- `.cursor/rules/known-pitfalls.mdc`（按需）
- `.cursor/rules/gdscript.mdc`（命名衝突・SE・ホットパス）
- `.cursor/rules/recurrence-prevention.mdc`
- Decision: 非戦闘ナラティブ色分け / 宝箱演出（`03_Decision_Log.md`）
