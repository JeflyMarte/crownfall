# CurrentSprint.md — Sprint Dashboard

---

## Sprint Name

**β — モーンゲート編完成**（2026-07-14 スコープ再設定）

---

## Goal

**メイン5 Biome の通常直列解放を有効化**（β封鎖解除）。②は①クリアのみ（調査ゲージは解放非関与）。  
寄り道／征討は引き続きオミット（`SUB_DUNGEONS_PLAYABLE=false`）。

---

## スコープ方針

| 方針 | 内容 |
|---|---|
| βプレイ範囲 | メイン①〜⑤ノーマル（直列解放）。②は①クリアのみ。Hard/NM はメイン5ノーマル全クリア後 |
| ②〜⑤ | **β封鎖解除**（通常の直列解放） |
| 調査ゲージ | 完全調査100%→景品→0%サイクル。解放条件には使わない |
| 寄り道／征討 | **引き続きオミット**（データ残置・`SUB_DUNGEONS_PLAYABLE=false`） |
| 助っ人ガチャ | ✅ **常時 ON**（P3-GACHA-ENABLE-001）。単発＋チケットのみ（10連／複数タブは削除） |
| BGM | ✅ 配置＋配線済（**P3-AUDIO-BGM-001**・要実機）。クレジット文面は後続 |
| 横断コンテンツ拡張 | EQ-LEG-002 / ENEMY-002 残り等は **アップデート枠** |

---

## Task 仕分け（正）

### A. β必須（出荷前に片付ける）

| 順 | ID / 項目 | 内容 | レーン |
|---|---|---|---|
| 1 | **P3-BETA-SCOPE-001** | ~~②以降封鎖~~ → **2026-07-23 解除**（寄り道はオミット継続） | ✅ |
| 2 | **実機通し** | モーンゲート 1-1〜1-5＋ボスまで。必殺演出・VFX・SE・セーブ復帰 | オーナー |
| 3 | **P3-BETA-QA-001** | Known Issues / クラッシュ / 進行不能の遮断。許容リスト明文化 | HQ+オーナー |
| 4 | **バランス通し** | ①のみで周回が成立するか（報酬・難易度・離脱）。必要なら最小調整のみ | HQ→Impl |

### B. β推奨（時間があれば・完成度アップ）

| ID / 項目 | 内容 | 備考 |
|---|---|---|
| **P3-STORY-STARTER-001** | 開始1人選択＋×-5で初期5加入（β Extra OFF・本番寄り） | ✅ Impl（検証待ち） |
| **P3-UI-TITLE-001** | タイトル Continue / New Game（単一セーブ） | ✅ Impl（要実機） |
| **P3-FORGE-ALCHEMY-001** | 鍛冶・錬成（装備Lv合成） | ✅ Impl（要実機） |
| P3-AUDIO-SE-002 | 未使用SE配線（skill / death / cancel / error）＋罠・ボス登場 | ✅ Impl（要実機） |
| **P3-AUDIO-BGM-001** | BGM（title/hub/explore/battle/boss/result）配置＋配線 | ✅ Impl（要実機） |
| P3-ALPHA-003 | 実機チェックリスト v2.1 の要約版（①専用） | 旧 Defer を β向けに再起動 |
| P3-DAILY-B | 日課 UI polish | 任意 |
| 設定／クレジット | 音量確認・権利表記（Kenney / BGM）画面 | iOS 見据え |
| ①向け polish | モーンゲート env / UI の目立つ欠け | 新規大規模不可 |

### C. アップデート枠（β後・②以降解禁と同時でも可）

| ID | 内容 |
|---|---|
| **P3-SHOWCASE-ONLINE-001** | 展示室「みんなの展示」（サーバー公開自慢）— β据置。空タブ先行なし |
| **P3-COMBAT-BOSS-CUTIN-001** | ボス詠唱大技カットイン（顔＋技名・詠唱開始時） |
| P3-DG-UPDATE-002+ | ②ウィスパーウッド解禁（演出・文案・バランス確認） |
| P3-BETA-002〜004 磨き | ③〜⑤の実機確認・アセット不足解消 |
| P3-EQ-LEG-002 | 防具・装飾★ ②〜⑤横展開 |
| P3-ENEMY-002 残り | 新雑魚（②+4済以外）→ **③④⑤+12 済**（アート後差し） |
| P3-SUB 表示 | broken_marsh 等寄り道の解禁 |
| **P3-DG-ABYSS-001** | Biome深層×5。**A/B Impl**／Cレジェンド／D磨きは後続 | アップデート枠 |
| P3-CHR / Gacha 再有効 | ✅ ENABLE-001 済。残り＝専用ドット |
| **P3-PET-OTOMO-001** | オトモ「ジャック」— NG開始から随伴（4人枠外）・★1・常時前衛 | ✅ Impl（ドット後差し） |
| **P3-WANDER-004** | ゴールデンスカラベ／影狩り（放浪） | ✅ Impl（アート接続済） |
| **P3-DG-WANDER-EVENT-002** | 砂金の巣穴／影狩りの狩場（日次イベント） | ✅ Impl |
| P3-UI-BTN-005 | 装備・編成ボタン画像化（002〜004撤回後の再検討） |

### D. 凍結（Decision まで触らない）

天候本格 / 週間日課 / 6装備枠 / Affix本格 / 位置AI本格 / 探索手動+CD / ボタン全面画像化の再開

---

## 優先 Task（現行）

| 順 | ID | 内容 | 状態 |
|---|---|---|---|
| — | **P3-CODEX-HIST-GUIDE-050** | 図鑑 歴史50／世界観手引き50（HE-001〜050・WORLD-G001〜050） | ✅ GO・統合＋main |
| — | **P3-EQ-DIABLO-001** | 装備ステ・ディアブロ寄せ（固定ATK/DEF＋random_mods／Affix統合） | ✅ GO・統合＋main |
| — | **P3-EQ-JOB-WPN-001** | 職別武器種制限（preferred＝装備可能リスト） | ✅ GO・統合＋main |
| — | **P3-UI-FORGE-CHROME-001** | 鍛冶屋モック寄せ（枠／タブ／リスト／ボタン Texture 化）＋詳細ステアイコン／武器背景フォロー | ✅ GO・統合＋main |
| — | **P3-DG-ROCK-STAMPEDE-001** | 岩角の群れ道（ロックバイソン日次イベント） | ✅ GO・統合＋main |
| — | **P3-DG-VALGARD-DESCENT-001** | 境界の番　降臨／ストームクラウン境界廊（JST 1/4/7/10・N/H/NM） | ✅ Impl（専用ドット／BGMは後続） |
| — | **P3-LORE-VALGARD-001** | ヴァルガード＝擬機械ゴーレム改稿＋戦力（クロノス一段下） | ✅ Impl |
| — | **P3-UX-STATUS-LEGEND-001** | 戦闘右上・発生中状態異常レジェンド | ✅ GO・Impl |
| — | **P3-UX-STATUS-TELOP-001** | 状態付与「を付与！」テロップ＋DoT頭上 | ✅ GO・Impl |
| — | **P3-UX-SKILL-LEARN-PERSIST-001** | 経験値画面・スキル習得をキャラ名横に常時表示 | ✅ GO・Impl |
| — | **P3-UX-NONCOMBAT-POLISH-001** | 非戦闘フロア（碑文／泉／宝箱）表示 polish | ✅ GO・Impl |
| — | **P3-UX-SURVEY-CANCEL-001** | 調査室・進行中調査の中止ボタン | ✅ GO・Impl |
| — | **P3-UX-WIPE-CAUSE-001** | 全滅リザルト・敗因分析（1〜2行） | ✅ GO・Impl |
| — | **P3-UX-EQUIP-SCROLL-PERF-001** | キャラ画面スクロール軽量化（入れ子・キャッシュ） | ✅ GO・Impl |
| — | **P3-AUDIO-BGM-EXPLORE-OMIT-001** | ダンジョン探索BGMオミット・戦闘BGM常時 | ✅ GO・Impl |
| — | **P3-SKILL-KIT-001** | 職スキル7本＋全体技（役割案A・Lv1並立） | ✅ GO・Impl |
| — | **P3-EQ-ROSTER-PRESET-001** | ベンチ装備＋パーティ戦闘プリセット保存／適用 | ✅ GO・統合＋main |
| — | **P3-SURVEY-NONOKA-JOIN-001** | ノノカ＝ミストフェン初回クリア後に調査室合流 | ✅ GO・統合＋main |
| — | **P3-UI-BANNER-TITLE-001** | ダンジョンバナー名フォント幅フィット統一 | ✅ GO・統合＋main |
| — | **P3-BAL-DEAD-EXP-001** | 死者は後続撃破EXPなし（生存者のみ積立） | ✅ GO・統合＋main |
| — | **P3-EQ-ELDION-GLYPH-001** | 始祖竜の氷鱗鎧の簡体字混入修正 | ✅ GO・統合＋main |
| — | **P3-GACHA-FEATURE-BLURB-001** | 招待状 Featured 特徴行＋キャラ下げ | ✅ GO・Impl |
| — | **P3-BAL-TRAP-TIER-001** | 罠 N/H/NM 段階化（発動・ダメ・状態異常） | ✅ GO・Impl |
| — | **P3-DG-EVENT-SET-001** | 降臨セット装備（時環の刻／アンティーク・レア「セット」・3部位加護・レリック廃止） | ✅ Impl |
| — | **P3-DG-EVENT-REWARD-001** | 降臨専用単品＋レリック（旧） | ❌ Superseded by SET-001 |
| — | **P3-UX-REDEEM-001** | 設定・特典コード受取（`CROWNFALL-BETA`） | ✅ GO・統合＋main |
| — | **P3-ENEMY-ROCK-BISON-001** | ロックバイソン（素材率×1.75・全DG・仮アート） | ✅ GO・統合＋main |
| 1 | P3-BETA-SCOPE-001 | βプレイ範囲＝モーンゲートのみ（案B 🔒） | ✅ |
| — | **P3-EVT-FIELD-001** | 今日のダンジョン状態＝30分スロット（穏やか最頻＋天候／放浪等） | ✅ Impl（要実機） |
| 1 | P3-BETA-SCOPE-001 | βプレイ範囲＝モーンゲートのみ（案B 🔒） | ✅（②は **P3-HUB-SURVEY-001** 条件付き解禁へ更新） |
| — | **P3-HUB-SURVEY-001** | 調査室（モック準拠）＋SURVEY／派遣／②条件解禁（実績タブは OMIT） | Phase1 Impl・要実機。実績UIは **P3-CODEX-ACHIEVE-OMIT** |
| — | **P3-CODEX-ACHIEVE-OMIT** | 図鑑「実績」タブ一旦オミット | ✅ GO・統合＋main |
| — | **P3-EQ-LEG-WPN-BOW-DUAL-001** | 弓★3＋双刃★2＋専用アイコン | ✅ GO・統合＋main |
| — | **P3-CODEX-GUIDE-003** | 手引き: 高＋中＋世界観12条／DG概要正典同期 | ✅ GO・統合＋main |
| — | **P3-UX-LORE-002** | 碑文判読80%＋記録未所持の初回保証 | ✅ GO・統合＋main |
| — | **P3-CODEX-WORLD-002** | 世界観手引き G013〜022 拡充（職・信仰・時代等） | ✅ GO・統合＋main |
| — | **P3-EVT-FIELD-001** | いまの野外＝30分スロット（穏やか最頻＋天候／放浪等） | ✅ Impl（要実機） |
| — | **P3-UI-NINA-NAV-001** | 拠点ニーナ案内（右上・10秒／タップ・おすすめ1件） | ✅ Impl（要実機） |
| — | **P3-COMBAT-GAUGE-001** | スキル1本＋必殺チャージ＋下ゲージ2段 | ✅ Impl（要実機） |
| 2 | 実機通し + QA | ①クリア体験の GO/NO-GO（BGM/SE/錬成/タイトル含む） | **オーナー・次**（調査室と並行可） |
| 3 | P3-ALPHA-003 / クレジット | ①チェックリスト要約・権利表記 | リモート可・任意 |
| — | P3-INTRO-001 / 002 / SCROLL-001 | 新規導入（自動クロール・ニーナ文字送り・隊員一行説明） | ✅ GO・統合＋main 済（要実機） |
| — | P3-EQ-LEG-002 / ENEMY-002 | 旧キュー先頭だった項目 | **アップデートへ移動** |

---

## Notes

- ②〜⑤の実装済みコンテンツを **削除しない**（解放制御のみ）
- 受理ゲート: `smoke_test.sh` PASS ＋ オーナー実機通し
- 詳細履歴は `CurrentState.md` / `03_Decision_Log.md`
