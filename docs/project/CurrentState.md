# CurrentState.md — Crownfall Project Dashboard

---

## Last Update

2026-07-21（**P3-UI-NINA-NAV-001**: 拠点ホーム右上ニーナ案内 — 10秒／タップ・おすすめ1件ローテ。Decision＋Impl）
2026-07-21（**P3-BAL-OPENING-001**: 全DG敵HP×1.5/ATK×1.3・味方ボーナス×0.7・オトモ人数補正。しっかり危ない）
2026-07-21（**P3-UX-ULTIMATE-002**: 必殺カットイン（顔ノフレーム＋帯＋暗転）。ダメ／回復とも派手化）
2026-07-21（**P3-UI-TACTICS-LABEL-001**: 戦術プリセット表示を一行化。挙動据置。統合＋main 反映）
2026-07-21（**P3-COMBAT-GAUGE-001**: 装備スキル1本／必殺＝与ダメ・被ダメチャージ／下UI＝技＋必殺ゲージ。Decision＋Impl）
2026-07-21（**P3-DG-EVENT-STG-001**: イベントもバナー下にサブ章（各1章）。ダック／レイヴン。ダンジョン共通ルール化。統合＋`main` 反映済）
2026-07-21（**UX実機QA修正#4**: ダメージ白板VFX透過／戦闘ログ上余白。統合＋`main` 反映済）
2026-07-21（**UX実機QA修正#3**: 装備ステアイコン本番反映／キャラ★を黄色／結果「次のダンジョンへ」。統合＋`main` 反映済）
2026-07-21（**UX実機QA修正#2**: 報酬受取後の通貨アイコン拡大／マイページスクロール／陣形キャラ複製。統合＋`main` 反映済）
2026-07-21（**UX実機QA修正**: 戦闘ログ1倍／イントロ続けるSafeArea／キャラ説明句点統一／ガチャ・鍛冶の確認＆結果ダイアログ。統合＋`main` 反映済）

2026-07-21（**P3-DG-STG-ENABLE-002**: サブステージ再有効化 — 単体DGだと初回ランからボス＋章別spawn無効化が起きていた。`SUB_STAGES_PLAYABLE=true`。1-1〜x-4 Bossなし／x-5のみ Boss）

2026-07-20（**P3-ENEMY-WW-OMIT-001**: ブルームサーペントを一旦オミット — WW／寄り道プールから除外。`EnemyData` 残置）

2026-07-20（**P3-DG-STG-OMIT-002**: サブステージ（1-1〜x-5）を `SUB_STAGES_PLAYABLE=false` で一旦オミット。寄り道・征討は従来どおりオミット維持）

2026-07-20（**P3-ENEMY-002**: ③〜⑤に雑魚各3＋Elite各1追加。章 spawn_weights を SSOT 同期。スプライトは近縁プレースホルダ）

2026-07-19（**P3-BT-PET-LINK-001**: BTスキルに相棒鼓舞／指揮の牙／絆の守り。群れの號令はオトモ特化。ミレイ相棒共鳴・職FB群れの指揮）

2026-07-19（**P3-PET-OTOMO-001**: 随伴オトモ「ジャック」実装 — NG開始時随伴・人間4枠外・★1・装備/パッシブなし・常時前衛・共有EXP・セーブv9。ドットはプレースホルダ）

2026-07-19（**P3-PET-OTOMO-001 Decision**: ペット＝随伴オトモ「ジャック」。NG開始時から初期パーティに随伴（4人枠外）・装備不可・★1・パッシブなし・常時前衛・ドット後差し）

2026-07-19（**P3-GACHA-FEATURE-IDLE-001**: 招待状バナーを★4/★3 Featured Idle＋ステパネル化。5秒回転・タップ送り・召喚中停止。旧3アイコンカルーセル廃止）

2026-07-19（**P3-EQ-WEATHER-LEG-001**: 天候レジェンド3本 — 雷雨の穿針／宵闇の牙／霧穿ちの戦鉾。`weather_bonus` 配線）

2026-07-19（**P3-DG-RAVEN-EVENT-001**: イベントDG「宝冠レイヴンの巣」— 5F・レイヴンのみ・戦闘寄り・群れ8%・日1回（ダック枠と別））

2026-07-19（**P3-DG-DUCK-EVENT-001**: イベントDG「コズミックダックの裂け目」— 5F・ダックのみ・罠多め・群れ12%・日1回。イベントタブ／セーブv8）

2026-07-19（**P3-TRAP-PCT-001**: 罠ダメージを最大HP割合化。単体10%/15%・全体35%で5%/8%。探索・罠部屋）

2026-07-19（**P3-WANDER-003**: 放浪出現率を周回帯で上昇 — N 2.5/1.5% → H×1.3 → NM×1.6。全DG共通は据置）

2026-07-19（**P3-WANDER-002**: 宝冠レイヴンに伝説プール補完＋神話1%別枠。ダック／レイヴン差し替え・旧IDエイリアス＋セーブv7）

2026-07-19（**P3-STORY-STARTER-001-7b**: `STARTER_RECRUIT_BETA_EXTRA=false` — 初期5加入を本番寄り（章5のみ）。①内は開始1＋1-5で最大2人）

2026-07-18（**P3-BAL-STAT-SCALE-001**: 装備・敵・成長×8に加え、図鑑手引き／鍛冶表示／回復部屋・イベントheal／罠／DoT・コンボ・Threat まで追随）

2026-07-18（**P3-STAT-CHAR-001 GO**: キャラ個人ステ初期バランス確定 — ★合計4>3>2>1・個差バラつき・素体HP800）

2026-07-17（**P3-PASSIVE-CHAR-001**: メイン5＋ガチャ6の固有パッシブ見直し。味方死亡時廃止／★帯職パッシブ自動付与撤去（案α）。リーヴァ毒・エリアス戦闘入場回復30%等）

2026-07-17（**P3-INTRO-SCROLL-001 GO**: 導入 polish — 世界観自動クロール／ニーナ文字送り／隊員一行説明。統合＋`main` 反映済）

2026-07-17（**P3-EQ-MYTHIC-001**: 神話レア追加。葬冠の大剣／不滅の墓碑甲／評議会の覇印。モーンゲートボス再クリア1%。錬成不可）

2026-07-15（**P3-INTRO-002**: 導入アート配線 — Lore/Name/Starter BG・ニーナ立ち絵・スターター枠。パネル挿絵は後続）

2026-07-15（**P3-INTRO-001 Impl**: はじめから→世界観スクロール→隊長名→ニーナ3吹き出し→初期隊員選択→拠点。Boot=Title。操作チュートなし）

2026-07-14（**P3-INTRO-001 Decision**: 新規ゲーム導入＝世界観スクロール→隊長名→ニーナ3吹き出し→初期隊員選択→拠点。操作チュートなし・スキップ可。SSOT=`docs/specs/decisions/02_NewGameIntro.md`）

2026-07-17（**P3-GACHA-UI-TRIM-001**: 10連・推薦状／通常招待タブを完全削除。単発魔晶石＋チケットボタンのみ）
2026-07-17（**P3-GACHA-ENABLE-001**: `GACHA_HELPERS_PLAYABLE=true` 常時。招待状・抽選・ロスター参加を開放。戦力／ドットの既知リスクは Decision に記録）

2026-07-16（**P3-GACHA-REVEAL-001 polish**: Invite封書を AI 生成＋クロマキー差し替え。閉/★2/開封/Glow。演出ロジック据置）

2026-07-16（**P3-GACHA-REVEAL-001**: 招待状開封リビール — 封緘→開封→顕現。★差尺／Glow／スキップ。`GachaRevealPresenter`＋Inviteアセット。`GACHA_HELPERS_PLAYABLE=false` 据置）

2026-07-16（**P3-GACHA-COPY-001**: ガチャUI世界観リネーム — 召喚→招待状。タイトル／ナビ／天井／結果／図鑑手引きを同期。魔晶石名据置。`GACHA_HELPERS_PLAYABLE=false` 据置）

2026-07-16（**P3-GACHA-LIMIT-001**: ガチャ重複＝限界突破案B。パッシブ効果×(1+0.1N)・上限+5・還元半減。カイダ／ガルムに固有パッシブ付与。`GACHA_HELPERS_PLAYABLE=false` 据置）

2026-07-16（**P3-GACHA-008**: ガチャプール 10→6体 — ★2×3 / ★3×2 / ★4×1。排出率 ★2 50%/★3 35%/★4 15%。残り4体は `_omitted` 退避。`GACHA_HELPERS_PLAYABLE=false` 据置）

2026-07-16（**リモート再開**: `cursor/sub-mac-ui-integration-cca2` 同期済。GUT 395 PASS。次＝オーナー実機通し／QA）

2026-07-16（**P3-AUDIO-BGM-001**: BGM 配置＋配線 — title/hub/explore/battle/boss/result。戦闘SE差し替え・行動順敵アイコン・結果EXPアイコン等の polish WIP 同梱）

2026-07-14（**P3-AUDIO-SE-002**: 未使用SE配線 — skill resolve / death / cancel / error。罠=`combat_hit`・ボス登場=`room_enter`。新規収録なし）

2026-07-14（**P3-FORGE-ALCHEMY-001**: 鍛冶「錬成」タブ — 同種装備合成で装備Lv上昇（素材Lv×0.5・Gold 20×上昇）。炉研ぎ／分解と併存。装着時に冒険者Lvへクリップ）

2026-07-14（**P3-CODEX-COPY-001**: 図鑑手引きを日本語化・鑑定等オミット語削除・素材名等を現行に同期。詳細本文 RichText 色強調。調査記録の誤字修正）

2026-07-14（**P3-UI-TITLE-001**: タイトル Continue/New Game。Boot→Title（起動時ロードなし）。単一セーブ削除で再開始。設定は戻り先対応）

2026-07-14（**P3-STORY-STARTER-001**: 開始1人選択＋章クリアで初期5加入（案B）。`STARTER_RECRUIT_BETA_EXTRA=ON` で①1-2〜1-4でも加入。旧セーブは全員解放互換）

2026-07-14（**P3-DG-TIER-002**: Hard/NMをキャンペーン周回帯に再定義。解放=メイン5ノーマル全クリア／ハード全クリア。敵Lv +cap/+2cap（H1-1>N5-5, NM1-1>H5-5）。β体験外）
2026-07-14（**P3-ENEMY-TIER-VAR-002**: モーンゲート全雑魚＋クロックモス＋セルディオンを Hard/NM 色・呼称・個性化。**色替えは Hard/NM 限定（ノーマル非表示）**。ベース数値据置）

2026-07-14（**P3-ENEMY-TIER-VAR-001**: 墓鐘／水晶サソリ／骸面 Hard・NM — 専用色＋呼称（血鐘・紫晶・血面／月鐘・熔晶／屍面）＋個性のみ。ベース数値据置。図鑑同一）
2026-07-14（**P3-BETA-SCOPE-001**: 公開β＝モーンゲートのみ。`BETA_MOURNGATE_ONLY`・②以降は解放 false／UI 案B 🔒表示。データ残置。①クリアしても次Biomeは解禁しない）

2026-07-14（**βスコープ再設定**: 公開β＝**モーンゲート編完成**。②以降はデータ保持のまま封鎖→アップデート解禁。Task 仕分けは `CurrentSprint.md`。旧キュー先頭だった EQ-LEG-002 / ENEMY-002 はアップデート枠へ）

2026-07-14（**P3-AUDIO-SE-001**: SE基盤 — Kenney CC0 18音・`AudioManager`/`SfxCatalog`・SFXバス連動。UI/戦闘/宝箱/必殺/結果/召喚へ配線。BGMはオーナー（Suno）枠を `assets/audio/bgm/` に予約）

2026-07-14（**メイン5 ★3化**: `Adventurer.STARTER_RARITY` 4→3。既存セーブも `normalize_roster_rarity` で揃う。初期ステは★3帯）

2026-07-13（**P3-CMD-001-9**: 指揮官名変更を隊長台帳から常時可能に（C級ロック撤廃）。起動時命名の代替）

2026-07-13（**P3-UI-BTN-002〜004 撤回**: 文字可読性のため DG入場/結果/隊長台帳・日課のボタン画像化をテキストボタンへ戻した。アセットは残置。フェーズ5は引き続き STOP）

2026-07-13（**P3-UX-ULTIMATE-001**: 必殺 resolve 演出案A — announce/windup/release 3段・resolve 時のみグローバルロック・中央テロップ・インパクトでダメ/回復適用・`UltimatePresentationConfig`・`ultimate_strike` 詠唱2.0s。unit 355 PASS・smoke PASS・**要実機確認**）

2026-07-13（**P3-VFX-ALPHA-001**: 戦闘VFX透過修正 — `batch6` Hit/Heal の暗背景残存を `key_dark_background` で再生成・全28枚監査合格。`known-pitfalls` 追記。unit PASS）

2026-07-13（**P3-UI-BTN-002〜004**: ボタン画像化フェーズ2〜4 — ダンジョン入場・結果画面・隊長台帳/デイリー。**→ 同日撤回（可読性）**。フェーズ5（装備・編成）は **STOP**）

2026-07-13（**P3-ENEMY-002（部分）**: ウィスパーウッド新雑魚4種（iron_horn/blood_bloom/rune_carcinos/mirror_boa）・pool/elite 配線・spawn テスト更新。残り+4〜8は未着手）

2026-07-12（**P3-ART-CHR-002**: メイン5職ダンジョンドット差替 — walk/attack/hurt/death を `assets/characters/{job}/` へ。SpriteFrames `idle`＝歩行。Idle PNG は別用途保管。`import_job_chr_sprites.py`）

2026-07-12（**P3-CHR-OMIT-001**: メイン5以外一旦オミット — batch7 Warrior/Guardian/Scout を `_omitted/` 退避・`GACHA_HELPERS_PLAYABLE=false` で助っ人召喚/ロスター除外。データ残置）

2026-07-11（**P3-CMD-001**: 指揮官・調査許可 D〜S・SP進捗・隊長台帳（C級解放）・Save v5 通算統計・TopBar 指揮官表示。unit 313/314 PASS・既存 EquipmentCatalog パース1件は非起因）

2026-07-11（**P3-EVT-WEEK-002**: 6週ローテ「今週の野外」— 経済週3種維持+図鑑/注目Biome/ELITE素材。`EventWeekRotation` SSOT・ホームバナー・PERIODIC_EVENTS 再有効化）

2026-07-11（**P3-MAT-003 / SUPPLY-001 / CRAFT-001**: 炉研ぎ3種正式確定・ボス高品質欠片確定・クラフト数/Gold差・図鑑S5共通表示）

2026-07-11（**P3-MAT-CODEx-001**: 図鑑敵S5採取欄＝炉研ぎ共通3種表示。敵別`codex_materials`非参照。実ドロップと一致）

2026-07-10（**P3-DG-STG-ENABLE**: サブステージ正式承認 — メイン5 Biome×5章を `SUB_STAGES_PLAYABLE=true` で有効化。`P3-DG-OMIT-001-2` 上書き）

2026-07-08（**P3-WPN-LEG-EFFECT**: レジェンド武器10本→`fixed_passive_id`固有効果・`leg_*`廃止）

2026-07-08（**P3-RELIC-PASSIVE 案A**: 遺物→レリックパッシブ統合・パッシブタブ2枠・Save v4・`CombatPassives` SSOT）

2026-07-07（**P3-UX-GAMBIT-002 行動ルールUI スキル名表示**: 使う技/いつ使うか・skill_index・個別発動・防御含む）

2026-07-07（**P3-UX-GAMBIT-001 行動ルールUI**: ガンビット非表示・アコーディオン・プリセット一行サマリー・行プレビュー・HP%・射程日本語）

2026-07-07（**P3-UX-RESULT-001〜004 結果ウィザード**: 報酬→LvUPバー→MVP・30秒遷移・戦闘統計）

2026-07-07（**P3-VFX-STATUS-001 状態異常VFX**: `CombatVfxManager`・付与バースト/常駐オーラ8種/DoT tick・`DungeonScene` 配線）

2026-07-07（**P3-SKILL-LEG-001 レジェンド武器固有スキル**: 10本 `leg_*` 新設・武器 `fixed_skill_id` 差替・汎用属性斬撃は非レジェンド維持）

2026-07-07（**P3-EQ-LVL-001 装備レベル**: 案B全装備 equip_level・Biome連動ドロップ±1・戦闘勝利で装備EXP・`EquipmentEnhancer`）

2026-07-07（**P3-EQ-LEG-001 防具・装飾レジェンド**: 案C= x-5 初回ボス（ノーマル）確定★ + `fixed_passive_id`/`CombatPassives` 配線。①PoC=`serdion_ward_plate`/`mourngate_royal_seal`・`mourngate_1_5` 登録。②〜⑤横展開は次 Task）

2026-07-06（**P3-UI-GACHA 召喚所モック寄せ Closeout**: D-GACHA-1〜7 — タイトル「英雄召喚」・3タブ chrome（ノーマルのみ有効）・HeroBanner/Pity/カルーセル/SummonActionBar・10連リボン「★3以上1体確定」（押下不可）・確率詳細オーバーレイ・Reveal `UiTypography` polish・`GachaUiTokens`/`GachaUiHelper`・`generate_gacha_ui_assets.py` 17枚・`ui_audit` gacha_detail/gacha_reveal。ロジック不変（単発のみ・天井30）。unit 151 PASS・smoke PASS）

2026-07-06（**P3-DG-STG-003 全25章名**: ②〜⑤ 章名確定 — **オーナー承認**。SSOT=`03`/`05_Biomes`/`game/05`。**Impl ✅**（P3-DG-STG-ENABLE））

2026-07-06（**P3-DG-OMIT-001**: side/apex を一旦オミット — `SUB_DUNGEONS_PLAYABLE=false`。**サブステージは P3-DG-STG-ENABLE で再有効化**）

2026-07-06（**P3-DG-STG-003 ①章名**: 1-1崩れた地下水路〜1-5王座の深淵 — **GO**。**Impl ✅**（P3-DG-STG-ENABLE））

2026-07-06（**P3-ENEMY-001 敵プール拡充・章別 spawn 重み**: 雑魚6〜7種/Biome・`codex_danger`重み SSOT・5Biome×5章表 — **オーナー GO**。spawn Impl=P3-DG-STG PoC 同梱・新種+8〜12は別 Task）

2026-07-06（**P3-DG-STG-002 階層表**: メイン5Biome×5章 floor/enemy_level — **オーナー承認**。Impl 保留）

2026-07-06（**P3-EVT-002 イベント A+B+D**: outcome 演出~0.6s / ラン内去重 / ①生態素材差し替え+②〜⑤ label Biome 化。Decision P3-EVT-002。unit 91 PASS）

2026-07-06（**P3-UX-006 宝箱開封演出**: Closed→Open 差し替え+shake+金粒子。`generate_env_and_vfx.py` Biome別 Closed/Open。Decision P3-UX-006。unit 88 PASS）

2026-07-06（**P3-UX-005 エリート登場演出**: 案D=金 `ELITE` テロップ+枠pulse+敵スライド。部屋トランジション金粒子。周回短縮。Decision P3-UX-005。unit 88 PASS）

2026-07-06（**P3-UX-004 ボス登場演出**: 毎回フル `WARNING` 赤テロップ+shake+落石+pop。周回 `_fast_run_enabled` は短縮版。Decision P3-UX-004。unit 88 PASS）

2026-07-06（**P3-UX-003 潜入演出 A〜E**: イントロ+Biomeバナー / 部屋種別トランジション / パーティ登場 / ランHUD。Decision P3-UX-003。unit 88 PASS）

2026-07-06（**P3-UX-002-D 戦闘演出横展開**: 敵詠唱ThreatBanner / 瀕死赤枠 / 必殺ready金枠 / CRITICAL・大ダメ shake+flash。`CombatUiFrames` 枠3種追加。unit 88 PASS）

2026-07-06（**P3-UX-002 戦闘可読性 段1**: E=Now Playing 帯 / F=[戦術]ログ / G=ターン順バッジ（攻技必防詠）。`CombatGambit.condition_summary`・Decision P3-UX-002。unit 88 PASS）

2026-07-04（**P3-UI-DG-001 ダンジョン選択モック再構成**: 案C=Featured全幅バナー+Biome直列カード（メイン/寄り道）・HFlow/階層一覧撤去・Footer=EventSystemのみ・Headerスタミナなし。unit 86 PASS・smoke PASS）

2026-07-03（**P3-EVO-TRAIT-001 昇格特質**: 進化Lv30・職ごと常時パッシブ2つ（遠旅/聖遺甲虫と別系統）。`EvolutionTraits`・中央倍率フック10本。unit 86 PASS・smoke PASS）

2026-07-03（**P3-WANDER-001 遍在希少種**: 遠旅スズメ（EXP8倍相当・3行動後逃走・武器0%）・聖遺甲虫（ELITE級・武器85%・★2〜3重み寄り）。COMBAT 2.5%/1.5% 差し込み・`WanderingEnemyConfig`・撃破時武器率上書き。unit 78 PASS・smoke PASS）

2026-07-03（**P3-LV-099-001 レベル上限99**: Lv1〜50=+6HP/+2ATK据置・Lv51〜99=+3HP/+1ATK逓減・スキル習得はLv50まで不変。unit 69 PASS・smoke PASS）

2026-07-03（**P3-DG-TIER-001 危険度ティア**: 同一DGでノーマル/ハード/ナイトメア3段。前ティアクリアで解放・敵Lv+3/+6・レア重み×1.3/×1.6・報酬×1.2/×1.4。Biome解放はノーマルクリアのみ。unit 65 PASS・smoke PASS）

2026-07-03（**P3-EVT-HUB 期間限定バフイベント**: 端末日付+JST 5:00 境界で週次ローテ（EXP/Gold/武器ドロップ ×1.5）。`EventSystem` autoload・`EventBanner`/`EventScene`・戦闘報酬/直ドロップへ配線。デイリーミッションとは独立（進捗セーブなし）。第1弾=7/1〜7/22 の3週。unit 60 PASS・smoke PASS）

2026-07-03（**P3-UI3-003 UI 監査 拠点画面編**: 図鑑タブ行を HFlow+13px に折返し（歴史/記録/手引きが画面外に消える不具合解消）・詳細名 clip+ellipsis・DG選択のスタミナ占位 FooterPanel 非表示＋階層リスト領域拡大・召喚所の単発/購入ボタンを固定アクションバー化（ラインナップと重ならない）・`ui_audit.gd` に図鑑7タブ個別スクショ追加。unit 54 PASS・smoke PASS）

2026-07-03（**P3-BAL-007 + アセット配線バンドル**: 装備クォータ5件（crypt_weave/sepia_hide/lament_guard/clockwing_brooch/pilgrim_lantern）・mourngate/astoria プール更新・アイコン生成。敵戦闘スプライト25+ボス5（`generate_enemy_battle_assets.py`→`ENEMY/BOSS_SPRITE_MAP`）。スキルアイコン81枚（`generate_all_skill_icons.py`）。`verify_icon_paths.py` OK・`05_ダンジョン.md` P3-D070 同期。unit 54 PASS・smoke PASS）

2026-07-03（**P3-UI3-002 UI 監査 戦闘・リザルト編**: `tools/ui_audit_run.gd` 新設（DungeonScene 実走スクショ4時点＋ResultScene clear/wipe）。戦闘ヘッダーの LabelDungeonName/LabelRoom に clip+ellipsis — 長ダンジョン名でヘッダー最小幅 763px>720px となり戦闘UI全体が左右はみ出しする根本原因を解消（MainVBox min 763→510）。リザルト両系統は問題なし。unit 50 PASS・smoke PASS）

2026-07-03（**P3-UI3-001 UI ビジュアル強化・はみ出し修正**: 見出しフォント Shippori Mincho B1 Bold（OFL）導入（三層: 本文 Noto / 見出し Mincho / 戦闘数字 DelaGothic=`impact_font`）・画面タイトル「✦〜✦」金飾・下ナビ実体化（実ノード NavShop=召喚所/NavMenu=図鑑 と 1:1、金アイコン8種 AI 生成で `assets/ui/nav/` ソース欠損復旧）・ダンジョンサムネ5枚＋画面背景3枚（鍛冶屋/召喚所/図鑑）AI 生成・ホーム CurrencyStrip 実装。はみ出し修正: ダンジョン切替行 HFlow 化（リスト全損バグ）・Roster ノードパス不整合（画面全損）・全6画面のナビ重なり（余白52→84px）・鍛冶屋タブ行高・図鑑/召喚所リスト端数行。検証は新設 `tools/ui_audit.gd`（実レンダのスクショ監査）。unit 50 PASS・smoke PASS）

2026-07-03（**P3-GACHA-007 / P3-D162 ガチャキャラ拡充**: 助っ人 5→10体（全5職×2体・★1×2/★2×3/★3×2/★4×3）。新規=カイダ★2/シルヴィ★4/ドランテ★1/ガルム★2/ユナ★4（固有パッシブなし=ジョブ+レア帯パッシブ自動適用で P3-D155 キャップ維持）。立ち絵5枚を既存スタイルで AI 生成（オーナー許可済）。プールはディレクトリ駆動でコード変更なし。smoke PASS）

2026-07-03（**P3-BETA-004 / P3-D161 ⑤ フロストリッジ一式**: 敵6体（エルディオン3フェーズ＋専用2種・白嵐・吹雪の咆哮=敵スキル+4で**P3-D155 敵スキル+12 完遂**）・frostridge.tres（推奨Lv47/敵Lv45/ice有利/difficulty=5/floor10）・装備20点（★2=エルディオン・ブランド/ウンブラ・テルミナス・**闇固定スキル umbral_strike 新設=武器固定5本完成**）・⑤専用プール。検証（装備ATK48/DEF31/HP62・300ラン）: Lv44=59%/Lv47=71.3%/Lv50=82.3%。**メイン5 Biome ロードマップ（P3-D5DG-001）完遂**。unit 50 PASS・smoke PASS）

2026-07-03（**P3-BETA-003 / P3-D160 ④ ブラックショア一式**: 敵6体（ネレイオン3フェーズ＋専用2種・墨煙・潮穿ち=敵スキル+4）・blackshore.tres（推奨Lv34/敵Lv32/holy有利/difficulty=4）・装備20点（★2=ネレイダス潮汐刃/ファロスライト聖杖・**聖固定スキル sanctal_strike 新設**=P3-D155-1の+1）・④専用プール。検証（装備ATK34/DEF22/HP44）: Lv31=67%/Lv34=78.5%/Lv39=86.5%（高Lv帯は成長相対減で曲線平坦化を容認）。unit 50 PASS・smoke PASS）

2026-07-03（**P3-SUB-001 / P3-D159 寄り道ダンジョン パイロット**: broken_marsh（崩落街道橋・side/推奨Lv16/敵Lv15/floor6/thunder有利）。敵=③雑魚3種+大爪刀ボス転用（新規アセット0）・ドロップ=③◇◆帯のみ・解放=②クリア（unlock_after_dungeon_id）。切替UIを main+side 表示へ拡張（「寄」印）。検証: Lv13=81.5%/Lv16=91%（寄り道帯=推奨−3≈80%/推奨≈90% を新定義）。unit 50 PASS・smoke PASS）

2026-07-03（**P3-EVT-001 ダンジョン別イベント拡充**: ②5件・③5件の Biome 専用イベント（実利3+ロア2 の①型）＋ LF 断章4件（`world/12` v1.2）。`_get_event_pool` を `DUNGEON_EVENTS` 辞書化（④⑤はデータ追加のみ）。unit 50 PASS・smoke PASS）

2026-07-03（**P3-D157 ダンジョン解放条件**: メインは難易度順の直列解放（`GameState.is_dungeon_unlocked`・①常時→②は①クリア→③は②クリア）。サブルートは `DungeonData.unlock_after_dungeon_id` で個別指定（空=常時）。切替UIの未解放は🔒 disabled・未解放選択時はフォールバック。unit 47 PASS・smoke PASS）

2026-07-03（**P3-BAL-008 / P3-D158 ダメージ±乱数**: 最終ダメージ×[0.9,1.1] 一様乱数（`BalanceConfig.DAMAGE_VARIANCE=0.10`）。適用は中央2箇所のみ（味方→敵=`enemy_mitigation` 最終段・敵→味方=`enemy_damage_to_member` 最終段・rng注入可）。再検証: ①Lv3=72%/②Lv12=74%/③Lv22=80% で3ダンジョン目標帯維持。Known Issue「ブレークポイント体質」解消。unit 43 PASS・smoke PASS）

2026-07-03（**P3-BETA-002 / P3-D156 ③ ミストフェン一式**: 敵6体（モルドガル3フェーズ＋専用スキル2種・大爪刀断頭刃・雑魚共用沼毒=敵スキル+4）・mistfen.tres（推奨Lv22/敵Lv20/thunder有利/difficulty=3）・装備20点（★2=ヴォルグレイヴ雷剣/セラディオン雷杖・雷武器=static_strike・アイコン流用placeholder）・③専用ドロッププール・切替UIは自動追従。ハーネス検証（想定装備 ATK23/DEF15/HP29）: Lv19=50%/Lv22=77.7%/Lv27=93%。unit 40 PASS・smoke PASS。**残**: ③敵/装備の本番アート、実機確認）

2026-07-03（**P3-D155 スキル全量確定 + P3-GACHA-006**: 全量108本で増枠なし確定（通常50/必殺5/武器固定5/パッシブ25/敵23）。★3/★4 職固有パッシブ10本＋recon補完1本を実装（`CombatPassives.tier_def_for`・自動付与・self回復対応）。将来の成長軸=★パッシブ+Affix本格化（P3-D155-2）。unit 40 PASS・smoke PASS。**残**: 武器固定+2は④⑤と同時・敵スキル+12は③〜⑤に同梱）

2026-07-03（**P3-BETA-001 / P3-D154 ② ウィスパーウッド一式**: 敵6体（グランヴェル3フェーズ＋専用スキル）・whisperwood.tres（推奨Lv12/敵Lv10/fire有利）・装備20点（★2=シルヴァリア誓剣/ヴェルド枝杖・アイコンは流用placeholder）・ドロップのダンジョン別プール化（`DungeonData.weapon/armor/accessory_pool`・①現行維持）・既存属性武器7本を✦へ再ティア（①の★=聖別刃/祝聖の大槌）・ダンジョン切替UI。ハーネス検証: ②Lv9=40%/Lv12=71〜76%/Lv17=97%・①回帰なし（Lv3=74%）。unit 34 PASS・smoke PASS。**残**: ②敵/装備の本番アート、ダンジョン解放条件、実機確認）

2026-07-02（**P3-BAL-006 / P3-D153 モーンゲート難易度カーブ調整**: バランスハーネス v2（スキル/回復/CD・敵倍率 what-if・成長スイープ）→ セルディオン HP620→250/ATK38→15・Elite/雑魚≈×0.9・`recommended_level` 1→3。成長式は現行維持で正を `BalanceConfig` へ移設。検証: Lv1=22%/Lv3=75%/Lv6+=100%（目標帯合致）。unit 34 PASS・smoke PASS。Known Issue: 決定論戦闘のブレークポイント体質＝P3-D153-4）

2026-07-02（**外部レビュー対応バンド**: P3-SAVE-001 save_version / P3-REF-001 DamageCalculator 分離 / P3-BAL-005 BalanceConfig+バランスシミュ `tools/balance_sim.sh` / P3-UX-001 Result「効いた戦闘要素」。GUT/CI/未コミット分もコミット整理。unit 34 PASS・smoke PASS）

2026-07-02（**P3-UI-Base-A Closeout**: 003_01 Phase A・下ナビ8画面統一・nav/UIフレーム art はオーナー Close）

2026-07-02（**P3-D5DG-004c**: ③〜⑤敵名称・idオーナー確定）

2026-07-02（**P3-D5DG-004**: 5Biome敵MVP確定）

2026-07-02（**P3-D5DG-003**: floor_count個別・event_room_weight・mourngate=20%）

2026-07-02（**P3-D5DG-002**: メイン5＋寄り道Biome・周回3〜6で次メイン想定）

2026-07-02（**P3-D5DG-001**: 5 Biome ロードマップ確定。③＝ミストフェン沼・鍛冶は⑥以降）

2026-07-02（**P3-SKILL Closeout**: 基本5職 Lv50 習得10 完遂・CODEMAP 同期）

2026-07-02（**P3-SKILL-005/006 ヴァンガード・ビーストテイマー習得10**: 各新規7スキル。基本5職スキル習得完遂。smoke PASS）

2026-07-02（**P3-SKILL-004 アルケミスト習得10**: 新規7スキル+skill_unlocks。smoke PASS）

2026-07-02（**P3-SKILL-003 レンジャー習得10**: 新規7スキル+skill_unlocks。smoke PASS）

2026-07-02（**P3-SKILL-002 ソードマン習得10**: 新規9スキル+skill_unlocks。smoke PASS）

2026-07-02（**P3-SKILL-001 スキル習得+武器スキル**: Lv上限50・skill_unlocks・レジェンド武器スキル・属性斬撃は武器専用。smoke PASS）

2026-07-02（**P3-GACHA-005 ガチャ★1〜4**: パッシブ+初期ステ差別化・スターター5職はガチャ除外。smoke PASS）

2026-07-02（**P3-GACHA-004 ガチャ助っ人+2**: レオン/ミラ・5職カバー・プール動的化。smoke PASS）

2026-07-02（**P3-BETA-001b**: スタミナ Beta 除外。Beta最小=B1(2本目DG)のみ）

2026-07-02（**P3-UI2-029 DG下部パネル占位**: スタミナチップ・下部3枠・挑戦⚡20表記。smoke PASS。**Alpha コードレーン完了**）

2026-07-02（**P3-ALPHA-006 / P3-BETA-001**: Alpha Closeout=案A・Beta最小=B1(2本目DG)+B2(スタミナ)・次Impl=P3-UI2-029）

2026-07-02（**P3-DAILY ギルド日課**: 固定3件/日・5:00 JST リセット・BaseScene パネル・進捗フック。smoke PASS）

2026-07-02（**P3-UI2-028 DG選択モック第3段**: フレーバーテキスト・B1〜B7階層カード・敵/戦力/CLEARリボン。smoke PASS）

2026-07-02（**P3-GACHA-003 助っ人専用立ち絵**: portrait_resource_path 配線・暫定3枚・召喚/編成/装備反映。smoke PASS）

2026-07-01（**P3-UI2-027 拠点モック第2段**: TitlePanel/Spotlight/FeatureGrid・左メニューカード化・7機能グリッド。smoke PASS）

2026-07-01（**P3-GACHA-002 ガチャ助っ人コンテンツ**: ヴァルデン/イヴァル/セリン・来歴行・セーブ同期。smoke PASS）

2026-07-01（**P3-UI2-025 拠点 BottomNav 統一**: 冒険/召喚表記・NavHomeハイライト・装備/鍛冶/編成のNavShop統一。smoke PASS）

2026-07-01（**P3-GACHA-001 ガチャ仕様整合**: ★4=20%/★3=80%・還元★4=5・helper_a★4・ロスターrarity反映。smoke PASS）

2026-07-01（**P3-UI2-024 ギルド認定 polish**: Header/BottomNav・認定リストカード化・ソート。smoke PASS）

2026-07-01（**P3-UI2-023 探索リザルト polish**: CombatUiFrames・固定フッター・発見率表示・遷移時セーブ。smoke PASS）

2026-07-01（**P3-UI2-022 召喚演出**: 暗転→魔晶石→キャラリビール・タップ閉じ・演出中入力ロック。smoke PASS）

2026-07-01（**P3-UI2-021 ダンジョン選択モック寄せ**: フィーチャーカード+挑戦CTA・発見率・難易度🔒タブ・NavAdventure統一。smoke PASS）

2026-07-01（**P3-UI2-020 召喚所・図鑑モック寄せ**: Header/BottomNav統一・排出カード行・図鑑タブ温存。smoke PASS）

2026-07-01（**P3-UI2-019c〜e 装備画面モック第2段**: 2×2装備枠+足具🔒・全装備一覧+装備者バッジ・ソート/フィルタ・覚醒/プロフィール🔒タブ・◀▶のみ切替。smoke PASS）

2026-07-01（**P3-ECO-002 魔晶石通貨**: 表示名・アイコン・UI統一。`gacha_token` セーブ互換。smoke PASS）

2026-07-01（**P3-UI2-019b 装備画面 polish**: 装備枠カード内配置・+Nバッジ・装備一覧。headless smoke PASS）

2026-07-01（**P3-UI2-019a 装備画面モック寄せ**: Header/BottomNav・キャラ◀▶切替。headless smoke PASS）

2026-07-01（**P3-UI2-018 鍛冶屋モック寄せ**: Master-Detail 生産/強化・分解ロック・BottomNav。headless smoke PASS）

2026-07-01（**P3-UI2-017 編成画面モック寄せ Closeout**: Header/BottomNav・4カード編成・陣形ポップアップ。headless smoke PASS）

2026-07-01（**Combat Polish バンドル**: 基本5人固有名・★3固定・キャラ固有パッシブ・職別必殺・敵スキル・スキル名頭上表示・回復/バフVFX・必殺派手演出。`6696ac7` smoke PASS）

2026-07-01（**P3-D145 敵別Threatターゲット**: `threat_target_bias`・遠隔/ネズミ偏重。headless smoke PASS）

2026-07-01（**P3-D151 罠部屋 MVP**: `RoomType.TRAP`・解除ロール連携・抽選8%・全滅対応。headless smoke PASS）

2026-07-01（**P3-FIX-004 HP持ち越し**: ラン中ダメージ維持・戦闘開始フル回復を廃止。headless smoke PASS）

2026-07-01（**P3-D142 周回ELITEスキップ**: `CombatFastRun` が ELITE も即撃破・ログ差別化。headless smoke PASS）

2026-07-01（**P3-BAL-004 経済バランス**: 生態ドロップ率微増・6レシピコスト引下・ELITE素材20%。headless smoke PASS）

2026-07-01（**P3-ECO-001 経済ループ Closeout**: D134〜141 完了宣言・`04_ゲームループ`/`CODEMAP` 同期）

2026-07-01（**P3-D140 ガンビット条件静的ヒント**: `CombatGambit.condition_hint`・装備画面各行に説明1行。headless smoke PASS）

2026-07-01（**P3-D141 Result 作成可能レシピ表示**: 採取素材あり時に鍛冶作成可能レシピ名を表示・`CraftHelper` 抽出。headless smoke PASS）

2026-07-01（**P3-D139 鍛冶屋軽 UX**: 所持/レシピ素材アイコン・作成可能優先ソート・出力アイコン行。headless smoke PASS）

2026-07-01（**P3-D138 拠点素材可視化**: BaseScene TopBar 素材チップ（最大3種+overflow・ツールチップ・タップで鍛冶）。headless smoke PASS）

2026-07-01（**P3-D137 ガンビット行並替**: 装備画面カスタム戦術5行に↑↓・優先度入替・セーブ連動。headless smoke PASS）

2026-07-01（**P3-D136 鍛冶屋復活 MVP**: 赤鉄の工房導線復帰・全6レシピ・古き骨=セピアハウンドドロップ追加。headless smoke PASS）

2026-07-01（**P3-D135 Result 採取素材アイコン行**: `MaterialPanel`+`IconPaths` material セル・InfoGrid テキスト重複除去。headless smoke PASS）

2026-07-01（**P3-D134 作戦プリセット装備競合トースト**: `apply_combat_preset` が skipped 返却・装備画面フィードバック表示。headless smoke PASS）

2026-07-01（**実装順序 HQ 確定** — 下記 `Next Implementation Queue`）

2026-07-01（**P3-ALPHA-005 Alpha Combat Formation ブランチ Closeout**: `cursor/alpha-combat-formation-ui` → `main` マージ。D120〜133 + headless Closeout 一式。smoke PASS）

2026-07-01（**P3-D133 Result 天候表示**: `last_run_weather` スナップショット・Result 情報行）

2026-07-01（**P3-ALPHA-003 Closeout（headless）**: 実機一括確認はオーナー実施困難のため **Defer**。暫定ゲート＝`smoke_test.sh` PASS。開発継続可。**次=Phase 3-A ポリッシュ / Backlog 小タスク**）

2026-07-01（**P3-D130 Result 探索方針表示**: `last_run_exploration_policy` スナップショット・Result 情報行。作戦プリセットサマリーにカスタム戦術数。headless import 検証済 / コミット済）

2026-07-01（**P3-D129 探索方針効果ヒント** + **P3-ALPHA-004 チェックリスト v2.1**: 装備画面ヒント・D120〜128 追検項目。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機**）

2026-07-01（**P3-D128 図鑑調査実利報酬（D2）**: P3-D067 生態素材ドロップ配線復元・図鑑方針×未完了敵でEXP+10%/素材率×1.5・ログ`[図鑑調査]`。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機**）

2026-07-01（**P3-D127 ターゲット条件拡張（A2）**: 条件4種（stun/vulnerable/armor_break/fear）・標的`enemy_with_debuff`・cautious/sweep プリセット反映。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**ポリッシュ**: 全滅2秒待機復元・モーンゲートDGサムネイル。コミット済）

2026-07-01（**P3-D125 陣形 B レーン Closeout** + **P3-D126 `cautious`→`self_range=mid`**: B-1〜5 完了宣言・Decision Log 追記。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機**）

2026-07-01（**P3-D124 作戦プリセット名リネーム**: `rename_combat_preset`・装備画面名称入力/名前変更・保存時名称反映。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**P3-D123 リタイア Result 差別化**: `last_run_outcome`(clear/retire/wipe)・Result ヘッダー「リタイア帰還」/「探索失敗」/「CLEAR」・探索情報に帰還種別。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**P3-D122 カスタム戦術ガンビット MVP（A1 Closeout）**: `tactics_custom_*`・装備画面5行UI・セーブ/作戦プリセット連動。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機 or 小タスク**）

2026-07-01（**P3-BAL-003 4人編成リバランス（G1 Closeout）**: `CombatController` 人数補正（HP×1.28/ATK×1.13 @4人）・群れ率 20%→24%。EXP/ゴールド据置。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機**）

2026-07-01（**P3-D121 作戦プリセット装備セット保存（E1 Closeout）**: `weapon/armor/accessory_instance_id` 保存・適用・競合/欠落スキップ・`find_*_instance`・UIサマリー表示。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機 or G1 バランス**）

2026-07-01（**P3-D120 マーキング状態 MVP（A3 Closeout）**: `mark`（被ダメ×1.15・3tick）・`aimed_shot`副次付与・`enemy_marked`/`enemy_has_mark`・プリセット反映（aggressive/sweep）・`CombatLinks`先頭登録。headless import 検証済 / 実機未確認 / コミット済。**次=E1 装備プリセット**）

2026-07-01（**未コミット整理**: リタイア・A3・CombatGambit を3コミット分割。B-5 コミット済）

2026-07-01（**P3-D106f 陣形 B レーン（B-5）本格射程**: `WeaponInstance`/`WeaponData.base_attack_range`→`CombatRange`（≤1.5 melee/≤2.5 mid/超 long）。スキル range_type 優先維持。`glacier_staff` 2.5 修正。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**P3-D106b〜e 陣形 B レーン（B-1〜4）**: 射程×陣形与ダメ/敵AoE列/Threat按分/散開密集。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**P3-ALPHA-003 Combat v1.0 実機一括確認チェックリスト**: `AlphaPlaytest_Checklist.md` v2.0 更新（モーンゲート/フルオート/CT/戦闘v1.0 全項目）。**次=オーナー実機実施 → GO/NO-GO 記録**）

2026-07-01（**P3-D119 Combat System v1.0 Closeout**: 残ロードマップ 15/15 完了宣言。`CODEMAP.md` に combat モジュール群（P3-D103〜118）・状態14種・探索/周回配線を同期。Decision Log P3-D119 追記。**次=Phase 3-A ポリッシュ / P3-D103〜118 実機一括確認**）

2026-07-01（**P3-D118 高速周回・戦闘スキップ MVP（フェーズE-15）**: `CombatFastRun`・クリア済みDGのみ「周回」トグル。COMBATのみ即撃破・報酬通常通り。ON時x2自動。ログ`[周回]`。headless import 検証済 / 実機未確認 / 未コミット。**Combat System v1.0 残ロードマップ 全15項目完了**）

2026-07-01（**P3-D117 探索スキル群 MVP（フェーズE-14）**: `ExplorationSkills`5種=採取/採掘/鍵開け/解読/罠解除。ロール連動自動発動(EVENT/TREASURE/COMBAT/ELITE)。罠20%×8ダメ。ログ`[探索]`+装備タブ表示。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズE-15 高速周回）

2026-07-01（**P3-D116 ボスフェーズ移行 MVP（フェーズE-13）**: `CombatBossPhases`静的3段(serdion HP50/25%)。`enemy_phase_index`+移行チェック(与ダメ/DoT)。フェーズでskill率/攻撃力/断罪重み。図鑑=`phases_seen`目撃開示。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズE-14 探索スキル群）

2026-07-01（**P3-D115 パーティシナジー連鎖＋キャラ連携 MVP（フェーズD-12）**: `CombatLinks`3連鎖=挑発連携(防御後他員+25%×3)/デバフ追撃(他員+20%)/治癒連携(回復対象次攻+15%)。`_consume_link_bonus`をコンボ末尾で併用。ログ`[連携]`+装備タブhint。headless import 検証済 / 実機未確認 / 未コミット。**フェーズD完了**→次=フェーズE-13 ボスフェーズ移行）

2026-07-01（**P3-D114 遺物発火型＋種類拡充 MVP（フェーズD-11）**: `CombatRelics`にtrigger定義+`has_trigger/trigger_def`。配線=`DungeonScene._fire_member_relic_triggers`(on_attack every_n/on_hit_taken/on_ally_death)・CD/攻撃カウント。新遺物4種=狩人の印/反応の盾片/弔鐘の指輪/斥候の片眼。ログ`[遺物]`・◈ラベル。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズD-12 パーティシナジー連鎖）

2026-07-01（**P3-D113 スキル予約＋ローテーション MVP（フェーズD-10）**: 装備スキル①②を`member_skill_rot_idx`でローテ（成功時次スキルへ）。温存=`SkillData.reserve_condition/value`+`CombatTactics.skill_reserve_met`（新条件ally_injured）。mend=負傷時のみ/hex_bolt=Elite時のみ。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズD-11 遺物発火型）

2026-07-01（**P3-D112 詠唱＋Action Lock MVP（フェーズD-9）**: `SkillData.cast_time`(0=即時・>0=自分番ロック)。`CombatController._pending_casts`+`_try/_advance_*_cast`で詠唱中は戦術再評価なし(Action Lock)。CDは発動時のみ。ターゲット凍結(D111)。中断=死亡/撃破クリア・敵stun/fearは進行停止。キャリア=ultimate/hex_bolt/mend/boss_decree_waveにcast_time1.0。紫系◆ラベル+ログ。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズD-10 スキル予約/ローテ）

2026-07-01（**P3-D111 個別ターゲット MVP（フェーズC-8）**: D100一括フォーカス廃止→`member_target_slot`+`resolve_member_target`でメンバーごとに戦術target解決。新ルール=enemy_with_status/back（cautious→back/sweep→enemy_with_status）。配線=通常/スキル/状態/コンボ/Threatを`_deal_member_damage_to_enemy`/`_apply_status_to_member_target`経由でスロット別。撃破=非アクティブも`_on_enemy_slot_killed`。ログ群れ時`→敵名`。`CombatController`に`class_name`追加。headless import 検証済 / 実機未確認 / 未コミット。**フェーズC完了**→次=フェーズD-9 詠唱/Action Lock）

2026-06-30（**P3-D110 混成エンカウント＋敵別状態スロット MVP（フェーズC-7）**: 混成=SWARM抽選後追加枠50%で別種(can_swarm池)・ログ【混成】。敵状態=`enemy_<slot>`単位(StatusResolver)・撃破時のみクリア・フォーカス切替可(D100非切替ガード撤去)。配線=CombatController slot API+DoT/バッジ/スキル付与をスロット対応。headless import 検証済 / 実機未確認 / 未コミット）

2026-06-30（**P3-D109 シナジータグ残＋コンボ MVP（フェーズB-6）**: `CombatTags`にshield/heal追加。スキルタグ付与=empower→buff/mend→heal/guard_strike→shield/hex_bolt→debuff。味方バフコンボ=empower+ultimateタグ→「鼓舞必殺」(hit×0.35・empower消費)・1ヒット1コンボは敵側優先。`CombatCombos._ALLY_RULES`+`get/consume_member_status`+`_consume_combo_bonus`配線。headless import 検証済 / 実機未確認 / 未コミット。**フェーズB完了**→次=フェーズC-7 混成エンカウント）

2026-06-30（**P3-D108 Condition拡充 MVP（フェーズB-5）**: 戦術発動条件4種追加＝`enemy_has_bleed`/`enemy_has_poison`/`ultimate_ready`(必殺CT/CD準備完了)/`self_range`(melee|long・装備スキルrange_type/rangedタグ→bow/staff武器種→既定melee)。`_build_tactics_context`に4キー供給。プリセット最小調整=balanced/aggressive/survival必殺→ultimate_ready・aggressive出血時スキル優先・cautious遠隔スキル優先・sweep毒時スキル優先。headless import 検証済 / 実機未確認 / 未コミット。残=フェーズB-6 タグ残＋コンボ）

2026-06-30（**P3-D107 状態異常拡充 MVP（フェーズB-4）**: Control/Debuff 3状態追加＝恐怖fear(行動失敗50%/2t)・脆弱vulnerable(被ダメ×1.25/3t)・防御DOWN armor_break(敵DEF半減/3t)。新field`StatusEffectData.defense_reduction`で防御DOWNを脆弱と作用点分離(DEF逓減前にDEF×(1−r)・上限0.95乗算合成)。`SkillData.apply_status_id2/chance2`(副次状態・主と独立判定)を追加しキャリア＝既存スキル流用: guard_strike+恐怖0.4/hex_bolt+脆弱0.45(主stun/curse温存)・aimed_shot=防御DOWN0.45(空スロット)。頭上バッジ恐/脆/破＋`[防御DOWN]`ログ。headless import 検証済(新規parse error 0・既存CombatController reload警告6件はベースライン同一の良性) / 実機未確認 / 未コミット。残=フェーズB-5 Condition拡充）

2026-06-30（**戦闘システム v1.0 MVP縦切り①②③: P3-D084 CT/ATB ＋ P3-D085 5スロット/防御/必殺 ＋ P3-D086 AI設定(戦術)**。①CT/ATB=各ユニット個別CT・速度で行動回数差・1パルス1行動・上部UIをCTプレビュー化。②1行動=5スロットから1手(通常/防御/スキル①②/必殺)・必殺=汎用`ultimate_strike`(×3/CD30)・防御=`guard`(被ダメ0.5/2tick)でメンバー被ダメ補正を実配線。③メンバー単位の戦術プリセット6種(バランス/積極/慎重/生存/ボス集中/掃討)でスロット選択を優先度＋発動条件(always/HP%/Boss/Elite/敵数/味方死亡)駆動に。`CombatTactics`静的＋`Adventurer.tactics_id`セーブ永続＋キャラ管理スキルタブに戦術セレクタ。Target層(敵個体狙い分け)は現行フォーカス撃破で無効のため別Decisionへ分離。headless import 検証済 / 実機未確認 / 未コミット）

2026-06-29（**Phase 3-A UI/バランス ポリッシュ**: ホーム(BaseScene)モック準拠リニューアル＋タイトル背景アート導入(P3-A-UI-007)・ダンジョン選択画面新設(P3-D080)・序盤バランス調整(P3-BAL-001)・死にステ解消=敵DEF/耐性を与ダメ計算へ統合(P3-BAL-002)・スキル名 世界観リネーム(P3-W-024)。鑑定ワード一掃は現行spec/player向けへ反映済）

2026-06-28（**Phase 3-B' システム実装 ほぼ完了**: ガチャ/ロスター・ジョブ進化・スプライト取り込み・ダンジョン全自動化(P3-D053)・中ボス廃止(P3-D054)・敵アニメ配線・助っ人targeting修正・graveyard残骸一掃(P3-Cleanup-001)・残り2ジョブ スキル(P3-D066)・Codex5段階監査・武器クラフト実機能化(P3-D067)。→ Phase 3-A ポリッシュへ）

---

## Next Implementation Queue（HQ 確定 2026-07-14 — β＝モーンゲート編）

> **公開β＝モーンゲート完成。** ②以降は保持封鎖→アップデート解禁。詳細仕分けは `CurrentSprint.md`。

| 帯 | 順 | ID | 内容 | 状態 |
|---|---|---|---|---|
| **β必須** | 1 | **P3-BETA-SCOPE-001** | ②以降＋寄り道を選択不可（データ削除なし） | ✅ **Closeout**（案B 🔒） |
| **β必須** | 2 | 実機通し | ① 1-1〜ボス・必殺/VFX/SE/セーブ | オーナー |
| **β必須** | 3 | **P3-BETA-QA-001** | 進行不能・クラッシュ遮断／許容リスト | HQ+オーナー |
| **β必須** | 4 | バランス通し | ①周回が成立する最小調整 | 要なら Impl |
| **β推奨** | — | **P3-UI-TITLE-001** | タイトル Continue / New Game（単一セーブ） | ✅ Impl（要実機） |
| **β推奨** | — | P3-STORY-STARTER-001 | 開始1人＋章加入 | ✅ Impl（要実機） |
| **β推奨** | — | P3-AUDIO-SE-002 | SE 未配線（skill/death/cancel/error 等） | ✅ Impl（要実機） |
| **β推奨** | — | **P3-AUDIO-BGM-001** | BGM 配置＋配線（title〜result） | ✅ Impl（要実機） |
| **β推奨** | — | P3-DAILY-B / 権利表記 | 日課 polish・Kenney/BGM クレジット | 任意 |
| **Update** | — | ②〜⑤解禁＋磨き | 旧 BETA-B1〜004 の実機・資産 | 後続 |
| **Update** | — | P3-EQ-LEG-002 | 防具・装飾★ ②〜⑤ | 後続（旧キュー4） |
| **Update** | — | P3-ENEMY-002 | ②+4／③④⑤+12 済（本番ドット後差し） | アート待ち |
| **Update** | — | 助っ人再有効 / UI-BTN-005 | ガチャ・ボタン画像 | 後続 |
| — | — | P3-UX-ULTIMATE-001 / P3-AUDIO-SE-001 | 必殺演出・SE基盤 | ✅ Closeout（要実機） |
| — | — | P3-DG-STG-ENABLE 等 | サブステージ有効化済み | ✅（βでは①のみ解放） |

**凍結（Decision まで着手しない）:** 天候本格 / 週間日課 / 6装備枠 / Affix本格 / 位置AI本格 / 探索手動+CD / ボタン全面画像化再開。

---

## Project Version

ProjectDocs **v3.6.0**

---

## Current Phase

**β — モーンゲート編完成**（2026-07-14 再設定）。システム／①〜⑤データは実装済み。公開体験は①に絞り、②以降はアップデート解禁。
- 受理ゲート=`smoke_test.sh` PASS ＋ オーナー実機通し（①）
- 次=実機通し（①）＋タイトル／スターター加入の確認

---

## Current Milestone

**Phase3-B-M2** — **完了**（P3-D023）— 属性5種 + 状態6種

---

## Active Tasks

| ID | 内容 | 状態 |
|---|---|---|
| — | P3-D024 spec 同期 | **完了** |
| P3-TH-001 | 簡易ヘイト | **完了** |
| P3-HW-001 | 聖属性武器 | **完了** |
| P3-D024b | 簡易ヘイト | **完了**（P3-TH-001） |
| P3-D024j | 聖属性武器 | **完了**（P3-HW-001） |
| P3-D024i | 属性 vs 状態チュートリアル | **完了**（P3-CX-001） |
| P3-HW-002 | slash_attack bleed 削除 | **完了** |
| P3-UI2-001 | 戦闘状態テキスト表示 | **完了** |
| P3-APPR-001 | 一括鑑定 | **完了** |
| P3-INIT-001 | イニシアチブ Phase 1 | **完了** |
| P3-EQ-CMP-001 | 装備比較 1 行 | **完了** |
| P3-UI2-002 | 状態ラベル折り返し | **完了** |
| P3-INIT-002 | イニシアチブ Phase 2 | **完了** |
| P3-JOB-001 | preferred_weapon +5% ATK | **完了** |
| P3-EQ-CMP-002 | 防具比較 1 行 | **完了** |
| P3-D024d-001 | 敵 curse エリート限定 | **完了** |
| P3-AFFIX-SPD-001 | Affix 速度 → イニシアチブ | **完了** |
| P3-D024c-001 | stagger_power リネーム | **完了** |
| P3-UI2-003 | viewport 縦長固定 720×1280 | **完了** |
| P3-UI2-004 | 浮動ダメージ数字 | **完了** |
| P3-EQ-CMP-003 | 装飾品比較 1 行 | **完了** |
| P3-UI2-005 | HP バー座標のスプライト追従 | **完了** |
| P3-SPEC-001 | 戦闘 AI spec イニシアチブ同期 | **完了** |
| P3-UI2-006 | バトルログ枠 art / スプライト位置 | **完了** |
| P3-SPEC-002 | UI spec / CODEMAP 同期 | **完了** |
| P3-THEME-001 | Panel 9-slice margin 調整 | **完了** |
| P3-ALPHA-001 | Alpha 5 分周回チェックリスト | **完了** |
| P3-UI2-007 | 浮動ダメージ座標（CanvasLayer） | **完了** |
| P3-UI2-009 | 宝箱中央配置 / 下部テキスト可読性 | **完了** |
| P3-UI2-008 | 戦闘スプライト scale / 遠近配置 | **完了** |
| P3-UI2-BG-001 | 王都跡戦闘 BG v3 差し替え | **完了** |
| P3-ALPHA-002 | 旧セーブ job_id マイグレーション | **完了** |
| P3-UI2-011 | ヘッダー B1 / 部屋表示 | **完了** |
| P3-UI2-012 | バトルログ戦闘限定 / ナレーション Panel | **完了** |
| P3-UI2-013 | 状態異常アイコン（頭上バッジ） | **完了** |
| P3-UI2-014 | エリート/ボス戦闘枠 | **完了** |
| P3-UI2-015 | Codex 初見トースト | **完了** |
| P3-UI2-016 | Build チップ（拠点・装備） | **完了** |
| P3-SPEC-004 | UI-2+ spec / CODEMAP 同期 | **完了** |
| P3-B-001 | 白骸墓地 完走検証・バランス初調整 | **完了**（オーナー GO） |
| P3-B-002 | 王都跡専用イベント 3 件 | **完了**（オーナー GO） |
| P3-B-003 | 地下工廠 Proposal | **完了**（オーナー GO） |
| P3-B-004 | 地下工廠プレイアブル追加 | **完了**（オーナー GO） |
| P3-B-005 | 地下工廠バランス初調整 | **完了**（オーナー GO） |
| P3-D026〜033 | 世界観刷新 Postwar Ecology（文書反映） | **完了**（Bible 29〜36 新設・既存 spec 同期） |
| P3-D035a | レベル制（共有EXP/Lv50/HP+ATK成長/セーブ） | **完了** |
| P3-D036a | 助っ人（戦闘 編成3+助っ人固定枠1 / イベント助っ人） | **完了** |
| P3-D036b | 助っ人ガチャ/ロスター（A〜D・gacha_token・天井・編成入替） | **完了**（smoke PASS） |
| P3-D037/052 | ジョブ進化（is_evolved・ギルド認定**Lv30**・専門深化×1.3・**昇格特質×2**） | **完了** |
| — | 敵6体＋主人公(swordsman)スプライト取り込み（96px/14コマ・LANCZOS） | **完了** |
| P3-D053 | ダンジョン進行 全自動化（分岐撤廃・自動進行・x1/x2/pause・EXIT自動リザルト） | **完了**（承認済） |
| P3-D054 | 中ボス(MID_BOSS)廃止（ROOM_SEQUENCE[7]=COMBAT・列挙値温存） | **完了**（承認済） |
| — | 敵 attack/hurt アニメ配線（idle復帰接続・ボス対応） | **完了** |
| — | 助っ人 targeting 修正（event_helper を狙撃対象外） | **完了** |
| P3-Cleanup-001 | 旧graveyard残骸一掃＋mourngate env改称＋部屋オブジェ修正 | **完了**（HQ巻取り・敵tres6+シート削除/env→mourngate改称/dead branch撤去） |
| P3-D066 | 残り2ジョブ スキル確定（vanguard=守護斬り/stun・beast_tamer=拘束矢/chill・副スキル状態付与有効化） | **完了** |
| P3-CODEX5-AUDIT | Codex 5段階 静的監査（P3-D051 a〜e 充足確認） | **完了**（コード変更不要・軽微な逸脱2件は容認） |
| P3-D067 | 武器クラフト実機能化（codex_materials 実ドロップ化・レシピ新生態素材改訂・apprentice_staff 追加） | **完了** |
| P3-D068 | 装備ドロップを直ドロップ化（鑑定済み100%・Affix自動付与・鑑定システムは温存） | **完了**（Claude実装・HQ diff承認 `fed5ffd`） |
| P3-D069 | Phase 3-A スコープ確定（純ポリッシュ・人数3/装備3枠/メタ無し据置） | **確定** |
| P3-A-UI-001 | 拠点(BaseScene) を 003_01 へ寄せる（テーマ基準づくり） | ✅ 完了 |
| P3-UI-Base-A | 拠点 003_01 Phase A（Hub/MenuGrid・左7・下ナビ6・8画面統一・verify PASS） | ✅ **Closeout**（nav/UIフレーム art Close） |
| P3-A-UI-002 | 装備画面をタブ分割（現在の装備／所持一覧） | ✅ 完了 |
| P3-A-UI-003 | 装備名のUI表示をID→display_name（日本語名）へ統一（全画面） | ✅ 完了（Claude実装・HQ承認） |
| P3-D070 | ダンジョン完全フルオート化（商人削除・イベント無選択化・全部屋自動進行） | ✅ 完了（Claude実装・HQ承認） |
| P3-A-UI-004 | 敵スプライト頭上に敵名ネームプレート表示（モック003_07準拠・下部敵名ラベルは集約） | ✅ 完了（HQ実装） |
| P3-D071 | 戦闘 下部パーティパネル（アイコン/HP/武器・MP不採用・CD維持） | ✅ 完了（HQ実装） |
| P3-A-UI-005 | 命中時Hitエフェクト＋ダメージ数値を敵味方両方に適用 | ✅ 完了（HQ実装・要実機確認） |
| P3-D072 | 鑑定機能オミット・退避（導線撤去・クラフト自動鑑定・archive移動） | ✅ 完了（HQ実装） |
| P3-D073 | 部屋移動トランジション演出（暗転＋部屋名・速度連動・軽量） | ✅ 完了（HQ実装・要実機確認） |
| P3-D074 | 撃破演出強化（武器直ドロップ＋取得アニメ・全滅時敵残置・攻撃時間差・素材オミット） | ✅ 完了（HQ実装・要実機確認） |
| P3-ART-001 | レンジャー／アルケミスト専用ドット絵を実装（generic batch7流用を専用SpriteFramesに差替・idle/attack/hurt/death） | ✅ 完了（HQ実装・要実機確認） |
| P3-D075 | 鍛冶屋オミット・退避（BaseScene導線撤去・archive/blacksmithへ移動） | ✅ 完了（HQ実装） |
| P3-A-UI-006 | 戦闘下部パーティパネルに専用キャラアイコン（バスト）。IconPaths chrカテゴリ追加・仮アイコンは正面ドット絵から自動生成 | ✅ 完了（HQ実装・仮アイコン/要差替） |
| P3-FIX-001 | 味方CHRサイズ不揃い修正（フレーム高基準→α実体高基準のfloat正規化・実体140px統一・足元bbox下端整列） | ✅ 完了（HQ実装・要実機確認） |
| P3-D076 | 部屋抽選ランダム化（中間=重み付き戦闘多め60/15/13/12・両端固定・ガード全適用ELITE≤2/連続禁止/COMBAT≥3）＋ダンジョン別`floor_count`（mourngate=7） | ✅ 完了（HQ実装・headless2万試行検証・要実機確認） |
| P3-D077 | スキル装備システム（メニュー「キャラ管理」改称・2スロット・ジョブ別プール・全員が装備スキルのみ発動・武器自動付与廃止・キャラ管理スキルタブ） | ✅ 完了（HQ実装・要実機確認） |
| P3-SKILL-001 | スキル習得+武器スキル（Lv上限50・`skill_unlocks` Lv解放・レジェンド武器`fixed_skill_id`自動・属性斬撃は武器専用・スキルタブ🔒表示） | ✅ 完了（HQ実装・smoke PASS） |
| P3-SKILL-002 | ソードマン習得10（Lv1/6/12/…/50・新規9 SkillData・連刃=出血温存） | ✅ 完了（HQ実装・smoke PASS） |
| P3-SKILL-003 | レンジャー習得10（Lv1/6/12/…/50・新規7 SkillData・追標射=標的温存） | ✅ 完了（HQ実装・smoke PASS） |
| P3-SKILL-004 | アルケミスト習得10（Lv1/6/12/…/50・新規7 SkillData・崩呪=脆弱温存） | ✅ 完了（HQ実装・smoke PASS） |
| P3-SKILL-005 | ヴァンガード習得10（タンク軸・恐怖追撃=恐怖温存） | ✅ 完了（HQ実装・smoke PASS） |
| P3-SKILL-006 | ビーストテイマー習得10（生態軸・猛毒噴射=毒温存） | ✅ 完了（HQ実装・smoke PASS） |
| P3-SKILL-007 | スキル習得バンド Closeout（5職×10・CODEMAP/06 同期） | ✅ 完了 |
| P3-D072-LORE | 断片ロア実機配信（碑文イベント本文表示＋Codex「記録」カテゴリ・`world/12` LFブロック解析・mourngate碑文イベント拡充） | ✅ 完了（HQクローズ 2026-06-29: LFブロック6件↔碑文イベントID一致・パーサ/表示/Codex記録 配線確認済） |
| P3-D078 | 回復/バフスキルMVP（SkillExecutor heal/buff解禁・`mend`治癒=最負傷者単体回復・`empower`鼓舞=味方与ダメ+30%/3tick・alchemistに付与・回復+/攻アイコン演出） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D079 | ボススキルMVP（EnemyData `skill_ids`/`skill_use_chance`追加・敵ターンでCD付きスキル発動・Serdionに激昂(自己与ダメ+40%)＋断罪の波動(全体AoE attack×0.7)・赤スキル名ポップ演出） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| OD-UI-003 | レベル制 | **完了**（P3-D035a） |
| P3-BAL-001 | 序盤バランス（武器世界観改名＋レアリティ調整・レア度重み付きドロップ・hunting_bow/apprentice_staff/bone_armor をドロップ追加） | ✅ 完了（HQ実装・要実機確認） |
| P3-BAL-002 | 死にステ解消（敵DEF逓減軽減 `K/(K+DEF)` K=100＋属性耐性0.75x を与ダメ計算 `_apply_enemy_mitigation` へ統合） | ✅ 完了（HQ実装・要実機確認） |
| P3-BAL-003 | 4人編成リバランス（G1）— 敵HP/ATK 人数補正・群れ率微増 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-W-024 | スキル名 世界観リネーム（ハイブリッド: 基本=和名/属性技・弓・杖=カタカナ・hex_bolt→アンブラボルト＋説明文を闇エルダ整合） | ✅ 完了（HQ実装） |
| P3-A-UI-007 | ホーム(BaseScene)モック準拠リニューアル＋タイトル背景アート(`UI_BG_Title.png`)導入（上部通貨バー/左メニュー/下部タブナビ・中央ロゴのみ・浮遊CTA/肖像撤去・通貨=gold/gacha_token） | ✅ 完了（HQ実装・要実機確認） |
| P3-ALPHA-003 | Combat v1.0 実機一括確認チェックリスト（`AlphaPlaytest_Checklist.md` v2.0） | ✅ 文書完了（**要オーナー実機実施**） |
| P3-D119 | Combat System v1.0 Closeout（CODEMAP 同期・15/15 完了宣言・Decision Log） | ✅ 完了 |
| P3-D120 | マーキング状態 MVP（A3 Closeout） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D121 | 作戦プリセット装備セット保存（E1 Closeout） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D122 | カスタム戦術ガンビット MVP（A1 Closeout） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D123 | リタイア Result 差別化 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D124 | 作戦プリセット名リネーム | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D125 | 陣形 B レーン Closeout（B-1〜5） | ✅ 完了（文書化・要実機確認） |
| P3-D126 | `cautious` 戦術 `self_range=mid` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D118 | 高速周回・戦闘スキップ MVP（残ロードマップ フェーズE-15）。`CombatFastRun`・クリア済みDGで「周回」トグル・COMBATのみ即撃破（報酬通常）。ON時x2自動。配線=`_try/_execute_combat_skip` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D117 | 探索スキル群 MVP（残ロードマップ フェーズE-14）。`ExplorationSkills`5種=採取/採掘/鍵開け/解読/罠解除。ロール連動自動発動(EVENT/TREASURE/COMBAT/ELITE)。罠20%×8ダメ・解除で無効。配線=`_apply_exploration_*`/`_try_exploration_trap` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D116 | ボスフェーズ移行 MVP（残ロードマップ フェーズE-13）。`CombatBossPhases`静的SSOT(serdion3段・HP50/25%)。`enemy_phase_index`+`_check_boss_phase_transition`(与ダメ/DoT)。フェーズでskill率/attack_mult/断罪重み2。図鑑=`phases_seen`目撃開示(stage5) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D115 | パーティシナジー連鎖＋キャラ連携 MVP（残ロードマップ フェーズD-12）。`CombatLinks`3連鎖=挑発連携(防御後他員+25%×3)/デバフ追撃(他員+20%)/治癒連携(回復次攻+15%)。配線=`_consume_link_bonus`をコンボ末尾・防御/デバフ付与/回復フック。可視化=`[連携]`+装備hint | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D114 | 遺物発火型＋種類拡充 MVP（残ロードマップ フェーズD-11）。`CombatRelics`にtrigger/condition/effect/cooldown+`has_trigger/trigger_def`。配線=`_relic_cd`/`_relic_attack_hits`+`_fire_member_relic_triggers`(on_attack every_n/on_hit_taken/on_ally_death)。新4種=狩人の印(4回追撃30%)/反応の盾片(HP50%未満防御CD8)/弔鐘の指輪(味方戦闘不能鼓舞)/斥候の片眼(速度+5%与+5%)。既存4種+ドロップ`all_ids`追従 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D113 | スキル予約＋ローテーション MVP（残ロードマップ フェーズD-10）。ローテ=`member_skill_rot_idx`で装備スキル巡回・成功時次へ。温存=`reserve_condition/value`+`skill_reserve_met`（ally_injured新設）。mend=ally_injured/hex_bolt=enemy_is_elite | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D112 | 詠唱＋Action Lock MVP（残ロードマップ フェーズD-9）。`SkillData.cast_time`(ceil=詠唱自分番数・CDは発動時)。`CombatController._pending_casts`+味方/敵`_try/_advance_*_cast`でAction Lock(戦術再評価スキップ)。ターゲット凍結・死亡/撃破クリア・敵stun/fearで進行停止。キャリア=ultimate/hex_bolt/mend/boss_decree_wave=1.0 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D111 | 個別ターゲット MVP（残ロードマップ フェーズC-8・D110依存）。D100一括フォーカス廃止→`member_target_slot`+`resolve_member_target`（行動開始時戦術target）。新ルール=enemy_with_status/back（cautious→back/sweep→enemy_with_status）。配線=通常/スキル/状態/コンボ/Threatをスロット別（`_deal_member_damage_to_enemy`/`_apply_status_to_member_target`）。撃破=非アクティブも`_on_enemy_slot_killed`・DoT同。ログ群れ時`→敵名` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D110 | 混成エンカウント＋敵別状態スロット MVP（残ロードマップ フェーズC-7）。混成=複数体抽選時`MIXED_SWARM_CHANCE0.5`で追加枠を別種(can_swarm池)・【混成】ログ。敵状態=`enemy_<slot>`(CT整合)・個体保持/撃破時クリア・フォーカス切替可。配線=`apply_status_to_active_enemy`/`get_enemy_status_*_at`/DoTスロット別/頭上バッジ`_status_icon_swarm_rows` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D109 | シナジータグ残＋コンボ MVP（残ロードマップ フェーズB-6・B-4/5依存）。`CombatTags`にshield/heal追加(buff/debuff既存)。スキルタグ=empower/buff・mend/heal・guard_strike/shield・hex_bolt/debuff。味方バフコンボ=`CombatCombos._ALLY_RULES` empower+`ultimate`タグ→鼓舞必殺(hit×0.35・empower消費)・1ヒット1コンボは敵側優先。配線=`get/consume_member_status`+`_consume_combo_bonus`(必殺`slot_type`のみ味方評価) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D108 | Condition拡充 MVP（残ロードマップ フェーズB-5・B-4依存）。戦術AI発動条件4種=`enemy_has_bleed`/`enemy_has_poison`/`ultimate_ready`(必殺`SkillExecutor.can_cast`) /`self_range`+value melee|long(`_member_combat_range`: skill range_type/rangedタグ→bow/staff→melee)。ctx=`_build_tactics_context`拡張。プリセット調整=balanced/aggressive/survival必殺→ultimate_ready・aggressive出血/sweep毒/cautious遠隔でスキル優先。距離は装備メタ代理(本格射程は後続) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D107 | 状態異常拡充 MVP（残ロードマップ フェーズB-4）。Control/Debuff 方向へ3状態追加(敵単一スロット維持)。恐怖fear(`skip_action_chance0.5`/2t)・脆弱vulnerable(`incoming×1.25`/3t)・防御DOWN armor_break(`defense_reduction0.5`/3t)。防御DOWNは新field`StatusEffectData.defense_reduction`(0..1・後方互換)で`_apply_enemy_defense`の実効DEFを×(1−r)＝脆弱(最終乗算)と作用点分離(`StatusResolver.get_defense_reduction`→`CombatController.get_enemy_defense_reduction`・乗算合成上限0.95)。キャリア=既存スキル流用＋`SkillData.apply_status_id2/chance2`(副次・独立判定`_apply_skill_secondary_status`)。配分=guard_strike+恐怖0.4/hex_bolt+脆弱0.45(主stun/curse併存)・aimed_shot=防御DOWN0.45(空スロット主付与)。可視化=頭上バッジ恐/脆/破＋`[防御DOWN]`ログ。延長=再付与リセット流用。マーキング/延長機構/敵別スロットは後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D106 | 陣形(前列/後列)MVP（残ロードマップ フェーズA-3）。4人編成(D105)に2列モデル導入・A-2 Threatと直結。行=`Adventurer.formation_row`(0前/1後)・GameState get/set＋プリセット(前衛/均衡=最後尾1後列/後衛=後ろ2後列)・SaveManager直列化。効果=後列:被ダメ×0.85(`FORMATION_BACK_INCOMING`)＋Threat基礎×0.6(`FORMATION_BACK_THREAT`)/前列:等倍＋`war_banner`与ダメ+10%を前列限定に整合。配線=被ダメ`get_member_incoming...`×`formation_incoming_multiplier`/Threat`_job_threat_base`×`formation_threat_multiplier`/war_banner`_member_relic_effects`で後列outgoing無効。UI=スキルタブに陣形行(前列/後列トグル＋プリセット3ボタン)。射程連動近接ペナルティ/AoE列範囲/散開密集は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D105 | 4人編成化（A-3前段）。陣形2×2(前2後2)に合わせアクティブ編成3→4。`GameState.ACTIVE_PARTY_SIZE`3→4。助っ人=`COMBAT_SLOT_MAX=4`（メイン上限）＋`_helper_active()`＝`event_helper != null`（**P3-D105-2r**: 満編成でも参加・5体目 UI 追加）。Threat/陣形/状態UI/ターンオーダーはsize駆動で非改修 | ✅ 完了（P1-4 で助っ人再参加・要実機確認） |
| P3-D104 | Aggro/Threat基盤 MVP（残ロードマップ フェーズA-2）。旧簡易ヘイト(ジョブ優先)を本格Threat値へ置換。`CombatController.party_threat`を各員保持・戦闘開始時ジョブ基礎値で初期化(vanguard4.0/swordsman2.0/他1.0)。敵は最大Threatを狙う(`pick_enemy_target_member_index`書換・助っ人除外維持・同値index昇順)。増加=与ダメ×0.10(`THREAT_DAMAGE_K`)/被ダメ×0.15(`THREAT_TAKEN_K`)/防御スロット=挑発スパイク+40(`apply_taunt`)。減衰=status tickごと基礎値へ×0.90(`decay_threat`)で挑発が時間で薄れる。挑発専用スキル/遺物・Threat可視化・敵別Threatテーブル・キャラ連携は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D103 | 防具の属性耐性 MVP（残ロードマップ フェーズA-1）。攻撃偏重の属性を防御側へ拡張。データ=`ArmorData.resist_elements`/`EnemyData.attack_element`追加(旧base_resistance予約)。効果=敵攻撃属性が防具耐性と一致で被ダメ×0.75(`ARMOR_RESIST_MULTIPLIER`・弱点/耐性と同値)。配線=`_calc_enemy_damage_to_member`に1フック(incoming後・`_member_resists_element`・`[耐性:◯]`ログ)。初期=bone_armor闇/leather_armor氷耐性・crystal_hedgehog氷攻撃/clock_moth雷/serdion闇攻撃・装備一覧に「耐性:◯」表示。数値レア/多段階(半減/無効)/敵スキル別属性は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D100 | AIターゲット選択(パーティ・フォーカス方針)MVP。D086保留のTarget層をフォーカス撃破モデル非破壊で導入。targetルールを`CombatTactics`に追加(front/lowest_hp/highest_hp/highest_atk・balanced/cautious=front・aggressive/survival/sweep=lowest_hp・boss_focus=highest_hp)。選択=単一アクティブの付け替え(`CombatController.set_focus_by_rule`・生存敵からルールで1体選びactiveに設定・全員集中)で既存の被ダメ/状態異常/コンボ/HPバー処理を不変。配線=`_do_member_turn`冒頭で行動メンバーのtarget適用(`_apply_focus_target`・群れ2体以上時のみ＋アクティブ敵に状態異常がある間は非切替＝単一スロット状態の転移防止)。混成エンカウント/敵別状態異常/個別ターゲット/Target条件9種は後続(大物) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D101 | 環境変化(天候)MVP。run開始時に天候抽選・DG中不変(`CombatWeather.roll()`→`GameState.current_weather`・揮発・晴れ55%/雨夜霧各15%)。効果(属性idはElementResolver準拠)=雨:雷+15%/炎-10%・夜:闇+15%/聖-10%・霧:与ダメ×0.95＋被ダメ×0.95。配線=属性/全体与ダメ→`_apply_enemy_mitigation`(地形隣・`[天候:◯]`ログ)/被ダメ→`get_member_incoming_damage_multiplier`(GameState参照)。可視化=HUDにダンジョン名〔天候〕併記＋ナラティブ＋procedural オーバーレイ(`_setup_weather`・夜=暗青ColorRect/霧=薄灰alphaドリフトTween/雨=CPUParticles2D＋生成雨粒テクスチャ・新規アセット0・CanvasLayer layer3・MOUSE_IGNORE)。増水/落石/フロア毎変化/敵側補正は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D102 | 属性武器拡充 MVP。属性シナジー(D095・同属性2本)/地形相性(D099)を実用域に。各属性1本のみで「2人で同属性」不可だったため各属性2本目を+5追加: 燻る炎牙(fire/dual_blades/pierce)/氷霜の杖(ice/staff/blunt)/雷鳴の大剣(thunder/greatsword/slash)/影喰みの短刃(dark/dual_blades/pierce)/祝聖の大槌(holy/greatsword/slash)。新規アセット0=アイコンは対応属性の既存ICO_WPN流用(`IconPaths`)・`fixed_skill_id`は既存同属性スキル流用(kindling/rime/static/hex・聖=slash_attack)・雷tag=`lightning`(D094感電互換・D099-6正規化でsynergy発火)。流通=`WEAPON_POOL`に5本追加(`DataRegistry`はid→path自動解決で追加コード不要)。専用アート/新規スキルは後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D099 | Biome属性相性 MVP。ダンジョンごとの有利属性。データ=`DungeonData.favored_element`(空=補正なし・MVP有利のみ/不利ペナルティ無し・後方互換)。効果=味方attack_elementが一致で与ダメ×1.15(`BIOME_FAVORED_BONUS`・弱点/特効/シナジーと乗算)。配線=D095同様`_apply_enemy_mitigation`属性段に1フック(`_is_biome_favored`→`current_dungeon_data.favored_element`・`[地形:◯]`ログ)。可視化=ダンジョン選択に「地形相性: ◯有利」(`DungeonSelectScene`)。mourngate(王都地下)=dark初期設定。不利ペナルティ/敵側補正/環境変化/部屋構成変更は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D098 | 探索方針プリセット連動 MVP。作戦プリセット(P3-D091)に「探索方針」を内包。方針=run単位1つ(`GameState.current_exploration_policy`・""/safe/material/relic/codex・DG中不変)。効果(中央フック相乗り)=safe:被ダメ×0.92＋群れ率×0.5/material:gold+15%＋ELITE素材率0.15→0.30/relic:ELITE遺物率0.15→0.25(BOSS据置)/codex:撃破時`add_enemy_kill`二重計上で図鑑段階加速。連動=`combat_presets[slot].exploration_policy`追加・`save/apply_combat_preset`で保存/反映(`SaveManager`は既存deep-duplicateで自動保存・変更不要)。UI=プリセット行直下に探索方針セレクタ(`EquipmentScene`・選択即反映・既定なし)。探索スキル/環境変化/部屋構成変更/高速周回は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D097 | ロールボーナス＋物理タグシナジー MVP。編成(ジョブrole)と物理武器の揃えに報酬。ロール=`CombatSynergy.compute_role_bonuses`がparty role(`JobStatCalculator`経由)を2人以上共有で発火: tank×2=被ダメ-8%/dps×2=与ダメ+6%/support×2=回復+20%/scout×2=会心+8%。物理タグシナジー=`compute_physical_bonus`が物理タグ(slash/pierce/blunt)を2人+5%/3人+8%の与ダメ(最大値・party全体フラット・属性シナジーと別枠乗算)。配線=既存中央倍率に相乗り(与ダメ`get_member_outgoing_damage_multiplier`×(1+物理)×role.outgoing/被ダメ`get_member_incoming...`×role.incoming/回復`_apply_healing_bonus`×role.heal/会心`_calc_attack_base`+role.crit)。可視化=装備スキルタブの情報行に「編成ボーナス」行追加(`_refresh_tag_info`)。陣形/Aggro/scout素材反映は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D095 | 同系統タグ・シナジー＋タグ可視化 MVP。D094タグ基盤を活用。属性シナジー=`CombatSynergy`(静的)がparty装備武器タグを集計し同一属性タグ(fire/ice/lightning/holy/dark)を2人+10%/3人+15%の与ダメ(物理/効果タグ対象外)。配線=`CombatController.get_element_synergy_bonus`→`_apply_enemy_mitigation`属性段に1フック(attack_element一致時×(1+bonus)・弱点/特効と乗算・`[シナジー:◯]`ログ・味方攻撃のみ)。可視化=装備スキルタブに情報行(`EquipmentScene._refresh_tag_info`「武器タグ: 斬撃/炎 ｜ 属性シナジー: 炎+10%」・`CombatTags.display_name`)。物理シナジー/ロールボーナス/図鑑表示は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D094 | シナジータグ正式化 MVP。D089コンボにタグ起爆を追加。タグ正式定義=`CombatTags`(静的SSOT・物理slash/pierce/blunt＋属性fire/ice/lightning/holy/dark＋効果bleed/poison/buff/debuff・未知id無視)。`WeaponData.tags`新設(`SkillData.tags`既存流用)・攻撃タグ=武器∪スキル(`_member_action_tags`正規化)。`CombatCombos`に`require_tag`追加(`tag_eligible`)＝指定タグ保有時のみ起爆。追加コンボ=出血→出血追撃(require slash・per_stack6)/感電→感電(require lightning・hit×0.4)・既存毒爆発/粉砕(無条件)は非回帰維持。武器タグ付与=朽刃slash/燻鉄slash,fire/霜結slash,ice/聖別刃pierce,holy/雷紋pierce,lightning/呪杖blunt,dark。同系統シナジー/タグUI表示は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D092 | 図鑑＝攻略本 拡充 MVP。既存段階開示(stage1-5)に乗せ、敵詳細の弱点/耐性ブロックを「戦闘データ」へ拡張(`CodexScene._apply_enemy_combat_data`・新シーン変更なし)。stage4=弱点/耐性＋行動間隔目安(`attack_speed`→`2.0/spd`秒)＋攻撃付与状態異常(`on_hit_status_id/_chance`)＋特効分類。stage5=使用スキル一覧(`skill_ids`・ボス大技含む)＋有効戦術ヒント(弱点属性＋特効分類から自動生成)。`CatalogHelper`敵エントリに`attack_speed`/`on_hit_status_id`/`on_hit_status_chance`/`skill_ids`追加・表示出し分けはstageで判定。手書きノート不要(派生生成) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D093 | 遺物 入手導線 MVP（解放型A）。D090の自由選択に「集めて使えるようになる」進行を追加。所持=`GameState.owned_relics`(一度入手で恒久解放・全員装備可・`has_relic/unlock_relic/unowned_relic_ids`)。入手=撃破ドロップ`DungeonController.roll_kill_relic_drop`(未所持から抽選・ボス確定/エリート15%/通常なし/全所持済なし)・即時解放(全滅でも巻戻さず既存ドロップと整合・`last_run_relic_dropped`のみクリア)。装備UI=遺物セレクタを「なし＋所持済みのみ」に制限(`EquipmentScene._refresh_relic_ui`再構築・未所持装備は`(未所持)`参考表示)。表示=戦闘ログ「遺物入手」＋Result報酬セル(グリフ「遺」)。セーブ永続(`owned_relics`)。個数型/売却/アイコンは後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D091 | 作戦プリセット MVP。party全体の「戦術＋遺物」セットを3スロット保存しワンタップ一括適用(武器/防具は競合回避のため除外)。各スロット=`{name, settings:{member_id:{tactics_id,relic_id}}}`・member_idキー保持で編成順変化に頑健。API=`GameState.save_combat_preset/apply_combat_preset/get_combat_presets/has/get_combat_preset_name`(適用は現partyのid一致分のみ既存setter流用)。セーブ=saveルートに`combat_presets`(深複製)。UI=装備スキルタブ最上部「作戦:[▼][適用][保存]」(`EquipmentScene`)。装備セット保存/探索方針連動は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D090 | 遺物（Relics）MVP。第3装備枠「どう戦うか」。1メンバー1遺物(`Adventurer.relic_id`空=なし・セーブ永続/`GameState.get_member_relic_id/set_member_relic`)。カタログ=`CombatRelics`(静的・tres非増設)で常時倍率`outgoing_mult`/`incoming_mult`/`speed_mult`(既定1.0・`effects_for`マージ)。配線=中央3フックのみ(与ダメ`get_member_outgoing_damage_multiplier`/被ダメ`get_member_incoming_damage_multiplier`/速度`get_member_initiative_score`・状態異常倍率と乗算・助っ人除外)。MVP4種=王国軍旗(与ダメ×1.10)/王盾の欠片(被ダメ×0.90)/古い砂時計(速度+10%)/狂戦士の護符(与×1.20・被×1.15)。UI=装備スキルタブ戦術行直下に遺物OptionButton(`EquipmentScene`)。入手/インベントリ/発火型は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D089 | 状態異常コンボ MVP。味方の攻撃ヒット時、アクティブ敵に乗った前提状態を「起爆」＝追加ダメージをヒット値へ上乗せ＋状態消費（1ヒット1コンボ・既存撃破判定をそのまま通す）。ルール=`CombatCombos`(静的・tres非増設)・`bonus=per_stack×stacks+round(hit_fraction×hit_damage)`。MVP2種=毒→毒爆発(per_stack8・毒消費)/冷却→粉砕(hit_fraction0.5・冷却消費)。基盤=`StatusResolver.get_status_stacks/consume_status`＋`CombatController.get_enemy_status_stacks/consume_enemy_status`、`_consume_enemy_combo_bonus`を通常攻撃＋スキル3経路のapply直前に配線。頭上`毒爆発 +N`(橙)＋`[コンボ]`ログ。シナジータグ正式分類は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D088 | パッシブ/リアクション MVP。戦闘中自動発火の常在能力（共通フォーマット Trigger→Condition→Effect→Cooldown）を`CombatPassives`(静的・ジョブ紐付け・tres非増設)で導入。Trigger=on_combat_start/on_hit_taken/on_ally_death・Condition=always/self_hp_below・Effect=apply_status(self\|party)/heal(party)。CD=CT秒管理(`_passive_cd`/`_run_combat_step`減算・発火成功時のみセット・戦闘開始でクリア)。被弾フック`_on_member_damaged`を敵通常`_do_enemy_attack`/敵スキル`_execute_enemy_damage`に挿入(生存=on_hit_taken・死亡=生存者on_ally_death)。頭上`◇名称`＋`[パッシブ]`ログ。初期=vanguard鉄壁(被弾&HP<50%→guard CD6)/swordsman・ranger高揚(開始→empower自己)/alchemist野戦救護(味方死亡→party回復12)/beast_tamer群れの本能(味方死亡→empower全体) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D087 | 生態特効＋図鑑連動 MVP。武器`bane_class`/`bane_multiplier`(既定×1.3)が敵`codex_class`(獣類/昆虫類/古代種)と一致で与ダメ増幅・属性弱点と乗算併用・`[特効:◯]`タグ。`_apply_enemy_mitigation`にmember_index追加＋`_get_weapon_bane`。図鑑連動=情報表示のみ(特効は常時適用)・Codex敵詳細(stage≥4)に`特効:{codex_class}`併記。初期付与=燻鉄の大剣(獣類)/霜結びの剣(昆虫類)/霊廟の聖別刃(古代種)。敵tres編集不要(codex_class流用) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D086 | AI設定（Tactics→Condition→Priority）MVP（戦闘v1.0 MVP縦切り③）。メンバー単位の戦術プリセット6種(`CombatTactics`静的: バランス/積極攻撃/慎重/生存優先/ボス集中/雑魚掃討)でスロット選択を優先度＋発動条件駆動に。Condition MVP=always/self_hp_below/enemy_is_boss/enemy_is_elite/enemy_count_gte/ally_dead。`_do_member_turn`を戦術プラン駆動へ置換(`_build_tactics_context`供給・防御条件は戦術へ移譲し二重ガードのみ抑止)。`Adventurer.tactics_id`セーブ永続(`GameState.get/set_member_tactics`)・キャラ管理スキルタブ上部に戦術OptionButton(`EquipmentScene`)。**Target層(敵個体狙い分け)はフォーカス撃破モデルで無効のため別Decisionへ分離** | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D085 | スキルスロット5＋防御＋必殺技（戦闘v1.0 MVP縦切り②）。1行動=5スロットから1手だけ実行(通常攻撃/防御/スキル①②/必殺技)・暫定選択優先度=必殺→防御→スキル①②→通常(D086でAI設定化)。必殺=長CD高威力(`JobData.ultimate_skill_id`/既定`ultimate_strike` power×3/CD30/`slot_type=ultimate`)。防御=自己被ダメ減バフ(新`guard` incoming×0.5/2tick)＋`CombatController.get_member_incoming_damage_multiplier`新設→`_calc_enemy_damage_to_member`配線。防御暫定条件=自HP<30%かつguard未付与。`SkillData`に`slot_type`/`range_type`追加。スキル①②はP3-D077(最大2)流用・必殺/防御は当面ジョブ/既定供給 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D084 | 戦闘 CT/ATB 移行（戦闘v1.0 土台・MVP縦切り①）。ラウンド制(P3-D083)を置換＝各生存ユニット個別CT・`BASE_ACTION_CT/initiative_score`で行動CT・CT0で1体ずつ行動・速度で行動回数差。スケジューラ=`CombatController.advance_to_next_actor()`/`get_ct_order()`（決定的・同時0は味方優先→index昇順）。1パルス1行動（x1=0.55s/x2=0.28s・同期実行で再入なし）。スキルCDは進行CT量・状態異常は`CT_PER_STATUS_TICK=2.0`ごと1tick。スキルは現行CD暫定流用。上部UIを行動順→CTプレビュー(残量昇順)へ転用。3人据置 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| ~~P3-D083~~ | ~~行動順制＋行動順表示~~ → **P3-D084 で置換（CT/ATB 制へ移行）** | 置換 |
| P3-D083 | 行動順制＋行動順表示（ラウンド制・イニシアチブ降順で1体ずつ逐次行動・同時攻撃を解消／速度=initiative_score流用・同値は味方優先／逐次await＋`_round_active`再入防止／上部アイコン列ターンオーダー表示=行動中ハイライト・このラウンドのみ／`does_enemy_act_first`先制ログ廃止・撃破処理を分割） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D082 | 群れ出現MVP（`EnemyData.can_swarm`/swarm_min/max・COMBATで20%群れ化(2〜3体)・ELITE/BOSS除外・sepia_hound/crown_eater_rat対象・CombatController群れ配列化+アクティブ繰り上げ・先頭フォーカス撃破/敵は各自攻撃・状態異常はアクティブ単一スロット流用・横並びスロットUI/個別HPバー&Lv名・撃破ごと報酬/武器個別ドロップ） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D081 | 敵レベル制MVP（`DungeonData.enemy_level`でDG単位固定・戦闘開始時確定/DG中不変・HP/ATK×(1+0.10×(Lv−1))/DEF据置・EXP×(1+0.15×(Lv−1))・共有Resource不汚染=CombatControllerの派生スケール値・ネームプレート`Lv{n} 名前`） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D080 | ダンジョン選択画面新設（ホーム「ダンジョン」→`DungeonSelectScene`→ラン。カード=ボス絵/★(difficulty)/推奨Lv/主なドロップ/CLEARバッジ・難易度タブ(ロック表示)・ロック行3件(仮名)・下部ナビ。`DungeonData.recommended_level`追加・`GameState.mark/is_dungeon_cleared`・完走時マーク） | ✅ 完了（HQ実装・要実機確認） |

### Combat System v1.0 残実装ロードマップ — **完了**（2026-06-30 確定 / 2026-07-01 Closeout P3-D119）

> 提案「Crownfall Combat System v1.0」の未実装/部分要素を、依存関係と費用対効果で並べた実装順序。原則＝土台先行・小さく効くもの先行・大物後段。採番は着手時に P3-Dxxx を付与。**全15項目 = P3-D103〜118 完了。**

**フェーズA：防御と編成の土台（タンクを機能させる）**
1. ✅ 防具の属性耐性 — **P3-D103**
2. ✅ Aggro / Threat 基盤 — **P3-D104**
3. ✅ 陣形 2×2 前後列 — **P3-D106**（4人編成 P3-D105）

**フェーズB：状態異常と条件の解像度**
4. ✅ 状態異常拡充 — **P3-D107**
5. ✅ Condition 拡充 — **P3-D108**
6. ✅ シナジータグ残＋コンボ追加 — **P3-D109**

**フェーズC：戦闘の多様性（Target 本格化）**
7. ✅ 混成エンカウント＋敵別状態異常スロット — **P3-D110**
8. ✅ 個別ターゲット＋Target 条件拡充 — **P3-D111**

**フェーズD：テンポ・AI深化**
9. ✅ Cast/詠唱＋Action Lock — **P3-D112**
10. ✅ スキル予約／ローテーション — **P3-D113**
11. ✅ 遺物：発火型＋種類拡充 — **P3-D114**
12. ✅ パーティシナジー連鎖＋キャラ連携 — **P3-D115**

**フェーズE：コンテンツ・周回**
13. ✅ ボスのフェーズ移行 — **P3-D116**
14. ✅ 探索スキル群 — **P3-D117**
15. ✅ 高速周回（戦闘スキップ） — **P3-D118**

依存固定: 2→3→12 / 4→5→6 / 7→8 — すべて充足。

**Closeout 後の Defer（各 Task スコープ外の集約）:** 敵別 Threat テーブル・探索スキル手動発動/CD・ELITE スキップ・戦闘スキップ敗北シミュ・`CombatWeather` 本格配線・複数 DG 本格コンテンツ。※本格射程/AoE・陣形 B レーン＝**P3-D125 完了**・マーキング＝**P3-D120 完了**。

---

### 残スケジュール（Phase 3-B' システム完成まで）

1. ~~P3-Cleanup-001 完了確認（graveyard一掃）~~ **完了**
2. ~~残り2ジョブ（ヴァンガード/ビーストテイマー）~~ **完了**（P3-D066・スキル付与）
3. ~~Ecology Codex 5段階調査（P3-D051 a〜e）完成~~ **完了**（HQ静的監査: データ/トリガー/セーブ/UI段階ゲート/6敵コンテンツ すべて充足）
4. ~~武器クラフト有効化~~ **完了**（機構=P3-CRAFT-001 / 実機能化=P3-D067: 敵 codex_materials 実ドロップ化＋レシピ新生態素材改訂＋apprentice_staff 追加）
5. → **システム完成** → Phase 3-A ポリッシュ（本番UI 003系 / 本番ドット絵量産 C案）← 次フェーズ

> アート並行（オーナーレーン）: 残り4ジョブのドット絵（ranger/alchemist/vanguard/beast_tamer）。swordsman 取り込み済。

### 世界観刷新（Postwar Ecology — 2026-06-26）

世界観を「戦後生態系」へ刷新。世界観 SSOT は **`docs/specs/world/`**（旧 `game/29`〜`37` から移行・統合済み / 2026-06-27 cutover, P3-D041b）。**コード未変更**（既存敵・DG・ジョブの実装移行は将来 Task）。

| world/ 文書 | 内容 |
|---|---|
| 00_Overview | 世界観マスター・三本柱・読み順 |
| 01_History | 歴史・HE エントリ（Codex 解析対象） |
| 02_Relics | 遺産・伝説武器・中核の謎 |
| 03_Ecology | 戦後生態系 総論 |
| 04_Classification | Class I〜VII |
| 05_Biomes | Biome |
| 06_MonsterNaming | 命名ガイド |
| 07_Geography | エルド大陸 |
| 08_SeekersGuild | 探索者ギルド |
| 09_Jobs | ジョブ（世界観面。数値は game/06） |
| 10_LoreDelivery | ロア提示ガイド |
| 11_Glossary | 用語レジストリ |

> 図鑑システム仕様は `game/33_EcologyCodex.md`（存置）。

#### 世界観 深掘り（2026-06-27〜28 / 採番 `P3-W-###`）

world 文書を一通り深掘り・整合済（**P3-W-001〜017**）。採番は world＝`P3-W-###`、HQ＝`P3-D###` に分離（旧 D050〜D066 衝突を改番解消 / `core/03` 末尾注記）。

| # | 確定 | 反映先 |
|---|---|---|
| W-001〜003 | マップ空間構成 / 歴史深化 / 地方誌 | `world/07`,`01` |
| W-004 | 属性=自然力**エルダ**（闇=瘴気・聖=浄化の光・魔法不在） | `world/03 §6`,`game/27`(ポインタ) |
| W-005 | 暦・時間・季節（崩落後 A.F./ギルド暦 G.118・澱みの季） | `world/01 §7` |
| W-006〜008 | ギルド組織/階級・戦後人類社会・経済交易 | `world/08 §8-12` |
| W-009 | 信仰・死生観（神不在・灯火/継承・還りと記録） | `world/08 §13` |
| W-010 | ロア提示の具体運用（Codex文体・HE運用・公開vs内部・新語） | `world/10 §7-10` |
| W-011 | Biome-02 **囁きの森ウィスパーウッド**（共生適応・fire弱点/poison） | `world/05 §3.2`,`04`,`07` |
| W-012 | アイアンヘイブン主要NPC（オーレン他6＋助っ人A/B/C背景） | `world/08 §14` |
| W-013 | 伝説個体（Legendary）/古龍種（カイル盟約↔ビーストテイマー） | `world/04 §5`,`09` |
| W-014 | 現在の情勢（ゲーム開始の"今"・モーンゲート調査契機） | `world/01 §8` |
| W-015 | Relics 深化（王遺産の現状・第十の王 公開断片拡充） | `world/02 §3.5・§4` |
| W-016 | 言語・文字（共通語・三層文字・「ルーン」=生物紋様） | `world/08 §15` |
| W-017 | ジョブの世界観深化（系譜・五部門親和・社会的役割） | `world/09 §5` |
| W-018 | モーンゲート敵6体の Codex 調査記録を改稿（祖先・鉱物化・王都接続） | `world/05 §3`,`resources/enemies/*.tres` |
| W-019 | HE 拡充（HE-005〜009 で六時代を概説・基幹4本と相互リンク・starter 開示） | `world/01`,`scripts/codex/CatalogHelper.gd` |
| W-020 | 素材21件のロア改稿（由来ベース・超自然語/退役DG名是正・lore_id 注釈） | `world/05 §3`,`resources/materials/*.tres` |
| W-021 | 伝説武器9対の公開断片を執筆（碑文/記録/噂・真相非記載・将来フレーバー素材） | `world/02 §3` |
| W-022 | 断片ロア集「モーンゲートの断章」新設（中核6謎×公開断片 計21点・媒体/出自付き・CANON非転記）＋ Codex調査記録6体を増補（S5稿に中核の謎フック1文追記・実機反映） | `world/12`（新設）,`README`,`world/05 §3`,`resources/enemies/*.tres` |
| W-023 | モーンゲート垂直層位を設計（L0崩れた地下水路〜L7王座の深淵最深部・L8〜未踏査／旧用途・情景・生息・出土・配置LF）。降下＝王都の過去への遡行。CANON地理フック整合・真相非公開 | `world/05 §3` |

> モンスター名・ダンジョン名・NPC固有名はオーナー確定済（採用個体の**ゲーム実装は別途選定**）。整合レビュー完了（`world/06` ミラーボア・`game/27` 退役敵参照を修正済）。

**実装移行 整合課題:** 既存敵の生物化 / DG↔Biome 再マッピング / ジョブ 3→5 / Codex 拡張 → 移行 Proposal 待ち。

---

## Known Issues

| 課題 | 詳細 |
|---|---|
| viewport 比率 | **720×1280** ✅。スプライト 720 幅内 ✅（P3-UI2-006） |
| 状態 UI | 頭上アイコン ✅（013）。Codex トースト ✅（015）。Build チップ ✅（016）。PA art は Phase 3-A |
| 聖属性武器 | ~~未実装~~ → **sanctified_dagger**（P3-HW-001） |
| タンク fantasy | ~~ランダム被弾~~ → 簡易ヘイト（P3-TH-001） |
| ラン中介入 | Alpha=準備専用（P3-D024a）。方針切替は Phase 2 |
| 助っ人 targeting | ~~ヘイト優先で狙われ無敵タンク化~~ → **解消**: `pick_enemy_target_member_index` で event_helper を狙撃対象から完全除外（メイン編成のみ標的） |
| mourngate アセット依存 | 敵6体＋swordsman は本番ドット絵取り込み済。残4ジョブは旧32px placeholder（オーナー作画待ち）。環境アート（BG/タイル/オブジェ）は **`assets/dungeon/mourngate/env/` へ改称移設済**（P3-Cleanup-001）。BG/出口は `*_Mourngate` 名 |
| 決定論戦闘のブレークポイント | ~~乱数がクリティカルのみ~~ → **解消**: ダメージ±10%乱数導入（P3-D158 / P3-BAL-008） |

---

## Design References

| 文書 | 用途 |
|---|---|
| [28_ゲームデザイン点検.md](../specs/game/28_ゲームデザイン点検.md) | **GD 点検 SSOT** — P3-D024 |
| [27_状態異常と属性.md](../specs/game/27_状態異常と属性.md) | 属性/状態 SSOT v1.1 |
| [03_Decision_Log.md](../specs/core/03_Decision_Log.md) | P3-D016〜024 |
| [05_Backlog.md](../specs/core/05_Backlog.md) | P3-D024 / Initiative |
