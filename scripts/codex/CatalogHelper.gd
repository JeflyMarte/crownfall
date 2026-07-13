class_name CatalogHelper
extends RefCounted

const _CodexContent := preload("res://scripts/codex/CodexContentHelper.gd")

## M9 Codex カタログ取得（P2-Task046〜049）。

const UNKNOWN_DISPLAY: String = "???"
# History Entry（HE-001〜009）は world/01_History の機械可読ブロックを解析する（旧 16/37 は削除）。
const HISTORY_BIBLE_PATH: String = "res://docs/specs/world/01_History.md"
# 旧 22_DungeonBible は削除。DUNGEON_ID_TO_BIBLE が空のため未使用（file_exists=false で graceful に {} を返す）。
const DUNGEON_BIBLE_PATH: String = ""
const FRAGMENTS_PATH: String = "res://docs/specs/world/12_Fragments.md"

# HE-001〜004=基幹、HE-005〜009=追加（P3-W-019）。lore ドロップ未実装のため全て starter 開示。
const STARTER_HISTORY_IDS: Array[String] = [
	"HE-001", "HE-002", "HE-003", "HE-004",
	"HE-005", "HE-006", "HE-007", "HE-008", "HE-009",
]

const LORE_TO_HISTORY: Dictionary = {}

const DUNGEON_ID_TO_BIBLE: Dictionary = {}

var _history_entries_cache: Array = []
var _dungeon_bible_cache: Dictionary = {}
var _fragment_entries_cache: Array = []

static func get_enemy_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_enemy_entries()

static func get_dungeon_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_dungeon_entries()

static func get_material_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_material_entries()

static func get_weapon_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_weapon_entries()

static func get_history_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_history_entries()

static func get_lore_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_lore_entries()

static func get_lore_body(lore_id: String) -> String:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	for raw in helper._load_fragment_entries():
		if str(raw.get("id", "")) == lore_id:
			return str(raw.get("body", ""))
	return ""


static func get_lore_title(lore_id: String) -> String:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	for raw in helper._load_fragment_entries():
		if str(raw.get("id", "")) == lore_id:
			return str(raw.get("title", ""))
	return ""

static func get_guide_entries() -> Array:
	return [
		{
			"id": "COMBAT-G001",
			"display_name": "属性の基礎",
			"description": (
				"属性（Element）は 5 種：炎 / 氷 / 電気 / 闇 / 聖\n\n"
				+ "【敵への与ダメ補正】\n"
				+ "弱点属性 … ×1.25\n"
				+ "耐性属性 … ×0.75\n"
				+ "それ以外 … ×1.0\n\n"
				+ "武器の element が空（\"\"）の場合は無属性。\n"
				+ "無属性は弱点・耐性の判定を受けない。\n\n"
				+ "【属性値（element_power）】\n"
				+ "装備の属性値が 1 以上あると、\n"
				+ "与ダメ × (1 + 属性値 × 1%) が加算される。\n\n"
				+ "【ダンジョン地形（Biome）】\n"
				+ "ダンジョンの有利属性と一致すると与ダメ ×1.15。\n\n"
				+ "【属性シナジー（編成）】\n"
				+ "同じ属性武器を 2 人で共有 … 与ダメ +10%\n"
				+ "同じ属性武器を 3 人以上で共有 … 与ダメ +15%\n\n"
				+ "⚠ 炎属性（fire）≠ 炎上（ignite）\n"
				+ "  属性はダメージ倍率にのみ影響する。\n"
				+ "  炎上はスキルや Affix が付与する状態異常（DoT）であり別物。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G002",
			"display_name": "状態異常一覧",
			"description": (
				"状態異常は全 15 種。継続時間は「tick」で計測される。\n"
				+ "戦闘 CT が約 2.0 進むごとに 1 tick（標準速度の 1 行動分に相当）。\n\n"
				+ "【DoT（継続ダメージ）】\n"
				+ "毒 … +4/tick、5tick、最大 3 スタック\n"
				+ "炎上 … +3/tick、4tick、最大 3 スタック\n"
				+ "出血 … 与ダメの 20%/tick、5tick、最大 5 スタック\n\n"
				+ "【行動妨害】\n"
				+ "スタン … 行動 100% スキップ、2tick\n"
				+ "冷却 … 行動 50% スキップ、3tick\n"
				+ "恐怖 … 行動 50% スキップ、2tick\n"
				+ "鈍化 … 行動 50% スキップ（追加で遅延判定あり）、3tick\n\n"
				+ "【被ダメ補正（デバフ）】\n"
				+ "感電 … 被ダメ ×1.15 + 行動 30% スキップ、3tick、最大 2 スタック\n"
				+ "標的 … 被ダメ ×1.15、3tick\n"
				+ "脆弱 … 被ダメ ×1.25、3tick\n"
				+ "防御DOWN … 敵 DEF を 50% 減少、3tick\n\n"
				+ "【与ダメ補正】\n"
				+ "呪い … 与ダメ ×0.75、4tick\n"
				+ "激昂 … 与ダメ ×1.4、3tick（敵にも付与あり）\n\n"
				+ "【味方バフ】\n"
				+ "防御 … 被ダメ ×0.5、2tick（防御スロットで付与）\n"
				+ "鼓舞 … 与ダメ ×1.3、3tick\n\n"
				+ "付与経路：スキルの状態付与 / 武器の on_hit / パッシブ / Affix 等。\n"
				+ "付与は確率判定あり（スキルごとに apply_status_chance を設定）。\n\n"
				+ "⚠ 属性と状態異常は別系統。炎属性武器が炎上を自動付与するわけではない。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G003",
			"display_name": "陣形（前衛・後衛）",
			"description": (
				"4人編成を「前列2・後列2」に分ける戦闘配置。\n"
				+ "編成画面の「陣形」で各メンバーの位置を設定する。\n\n"
				+ "【前列＝前衛】\n"
				+ "・敵の近接攻撃を引き受けやすい（Threat が高い）\n"
				+ "・被ダメージ倍率 ×1.0\n"
				+ "・遠隔攻撃の与ダメージ ×0.85（-15%）\n\n"
				+ "【後列＝後衛】\n"
				+ "・狙われにくい（Threat 基礎 ×0.6）\n"
				+ "・被ダメージ倍率 ×0.85（-15%）\n"
				+ "・近接攻撃の与ダメージ ×0.85（-15%）\n"
				+ "・中距離攻撃の与ダメージ ×0.92（-8%）\n\n"
				+ "【同列の人数】\n"
				+ "同じ列に 2 人以上 → 被ダメ ×1.08（密集）\n"
				+ "同じ列に 1 人だけ → 被ダメ ×0.94（散開）\n\n"
				+ "近接の敵は基本、前列を優先して攻撃する。\n"
				+ "一部の敵・スキルは後列を狙うことがある。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G004",
			"display_name": "射程（近距離・中距離・遠距離）",
			"description": (
				"攻撃の射程は武器の attack_range から次の 3 区分に分類される。\n\n"
				+ "近距離（melee）  … 射程 ≤ 1.5（例: 剣・大剣・短刃）\n"
				+ "中距離（mid）    … 射程 ≤ 2.5（例: 杖）\n"
				+ "遠距離（long）    … 射程 2.6 以上（例: 弓）\n\n"
				+ "スキルに range_type が設定されている場合は、\n"
				+ "武器よりスキル側の区分が優先される。\n\n"
				+ "【陣形との関係（与ダメージ）】\n"
				+ "前列 × 近距離 … ×1.0\n"
				+ "前列 × 遠距離 … ×0.85\n"
				+ "後列 × 近距離 … ×0.85\n"
				+ "後列 × 中距離 … ×0.92\n"
				+ "後列 × 遠距離 … ×1.0\n\n"
				+ "⚠ 敵の近接判定は射程 ≤ 2.5 を近接とみなす（中距離の上限と同値）。\n"
				+ "  そのため杖（2.5）も、敵の「近接優先ターゲット」の対象になりうる。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G005",
			"display_name": "行動順（CT）",
			"description": (
				"戦闘はラウンド制ではなく CT（カウントダウンタイマー）制。\n"
				+ "各ユニット（味方・敵）が個別の行動 CT を持ち、\n"
				+ "CT が 0 になったユニットから 1 体ずつ行動する。\n\n"
				+ "【速度（initiative）】\n"
				+ "武器の attack_speed × ジョブ補正 × Affix × 遺物 で決まる。\n"
				+ "速度が高いほど行動 CT が短く、同じ時間で多く動ける。\n"
				+ "基準行動 CT = 2.0 ÷ 速度。\n\n"
				+ "【CT の進行と連動するもの】\n"
				+ "・スキル CD … 進行した CT 量だけ減少\n"
				+ "・パッシブ CD … 同上\n"
				+ "・状態異常 tick … CT 約 2.0 ごとに 1 tick\n"
				+ "・Threat 減衰 … 状態異常 tick 時に発生\n\n"
				+ "UI の行動順表示は、CT 残量が少ない（次に動く）順。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G006",
			"display_name": "スキルとクールダウン",
			"description": (
				"各メンバーは次の行動スロットを持つ。\n"
				+ "必殺 / 防御 / スキル①② / 通常攻撃\n\n"
				+ "【スキル種別（effect_type）】\n"
				+ "damage … 攻撃スキル（威力 = 基礎攻撃力 × power_multiplier）\n"
				+ "heal   … 回復スキル\n"
				+ "buff   … 味方へ状態異常（鼓舞等）を付与\n\n"
				+ "【クールダウン（CD）】\n"
				+ "単位は CT 秒。発動後、戦闘 CT が進むたびに減少する。\n"
				+ "一般スキルの既定 CD は 5 CT 秒（スキルごとに個別設定あり）。\n"
				+ "CD 中は再発動できない。パーティカードに残り時間が表示される。\n\n"
				+ "【詠唱（cast_time）】\n"
				+ "cast_time > 0 のスキルは詠唱が必要。\n"
				+ "詠唱中は自分の番を消費し、完了後の自分番で効果発動。\n"
				+ "例: cast_time 1.0 → 1 回詠唱して次の自分番で発動。\n\n"
				+ "【温存（reserve_condition）】\n"
				+ "スキルに温存条件が設定されている場合、\n"
				+ "条件成立まで AI はそのスキルを使わない。\n"
				+ "（例: ally_injured = 味方に負傷者がいる時のみ回復）\n\n"
				+ "装備スキルは 2 枠。ローテーションで交互に試行される。\n"
				+ "レジェンド武器には装備枠外の固有スキルがある。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G007",
			"display_name": "必殺技",
			"description": (
				"必殺技は slot_type = \"ultimate\" のスキル。\n"
				+ "ジョブごとに 1 つ割り当てられる大技。\n\n"
				+ "【特徴】\n"
				+ "・長い CD（例: 30〜32 CT 秒）\n"
				+ "・高い power_multiplier（例: 2.4〜3.0）\n"
				+ "・詠唱ありのものが多い（cast_time 1.0 等）\n"
				+ "・tags に \"ultimate\" を含む（コンボ判定に使用）\n\n"
				+ "【戦術での使用】\n"
				+ "汎用プリセットはボス・エリート等の条件で自動発動。\n"
				+ "ultimate_ready 条件（CD 明けなら即発動）は\n"
				+ "カスタム戦術（ガンビット）向けに温存されている。\n\n"
				+ "【コンボ】\n"
				+ "自身に「鼓舞」が乗った状態で必殺を放つと、\n"
				+ "「鼓舞必殺」コンボが起爆し追加ダメージ（与ダメの 35%）を得る。\n"
				+ "起爆時に鼓舞は消費される。\n\n"
				+ "パッシブや遺物で必殺威力が増幅されることがある。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G008",
			"display_name": "防御スロット",
			"description": (
				"防御は独立した行動スロット。戦術条件（HP低下等）で AI が選択する。\n\n"
				+ "【効果】\n"
				+ "・自身に「防御」状態を付与（被ダメ ×0.5、2tick）\n"
				+ "・Threat（挑発）を大幅に上昇（+40）\n"
				+ "・パーティ連携「挑発リンク」が発動する場合あり\n\n"
				+ "【制約】\n"
				+ "既に「防御」中は再発動できない（硬直防止）。\n\n"
				+ "慎重・生存優先などの戦術は、\n"
				+ "HP が一定以下になると防御を優先する。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G009",
			"display_name": "戦術（AI）",
			"description": (
				"各メンバーに戦術プリセットを設定し、行動を自動制御する。\n"
				+ "戦術は「優先度順のスロット計画」＋「狙い方（target）」で構成される。\n\n"
				+ "【行動スロット】\n"
				+ "ultimate / defend / skill / attack\n"
				+ "上から条件を評価し、最初に発動できたスロットで行動確定。\n\n"
				+ "【条件の例】\n"
				+ "always / self_hp_below / enemy_is_boss / enemy_is_elite\n"
				+ "enemy_count_gte / ally_dead / ally_injured / self_range\n"
				+ "enemy_has_bleed / enemy_has_poison / enemy_has_mark\n"
				+ "enemy_has_stun / enemy_has_vulnerable / enemy_has_armor_break\n"
				+ "enemy_has_fear / ultimate_ready\n\n"
				+ "【狙い方（target）】\n"
				+ "front … 前列の敵\n"
				+ "back … 後列の敵\n"
				+ "lowest_hp / highest_hp / highest_atk\n"
				+ "enemy_with_status / enemy_marked / enemy_with_debuff\n\n"
				+ "【プリセット 6 種】\n"
				+ "バランス / 積極攻撃 / 慎重 / 生存優先 / ボス集中 / 雑魚掃討\n\n"
				+ "カスタム戦術（ガンビット）で行ごとに条件とスロットを細かく設定できる。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G010",
			"display_name": "Threat（挑発）",
			"description": (
				"Threat は敵が誰を狙うかを決める値。\n"
				+ "近接敵は基本、Threat が最も高い味方を攻撃する。\n\n"
				+ "【基礎 Threat（ジョブ）】\n"
				+ "ヴァンガード … 4.0\n"
				+ "ソードマン … 2.0\n"
				+ "その他 … 1.0\n"
				+ "後列は基礎 Threat ×0.6。\n\n"
				+ "【Threat の増減】\n"
				+ "与ダメ 1 あたり … +0.10\n"
				+ "被ダメ 1 あたり … +0.15\n"
				+ "防御スロット（挑発）… +40\n"
				+ "状態異常 tick 時 … 基礎値へ 90% 減衰\n\n"
				+ "【敵の狙い方バイアス】\n"
				+ "一部の敵は max_threat / lowest_hp / back_row / lowest_threat 等、\n"
				+ "固有のターゲット優先度を持つ。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G011",
			"display_name": "ダメージ計算",
			"description": (
				"与ダメは多段の倍率が順に乗算される。\n\n"
				+ "【味方→敵（攻撃）】\n"
				+ "1. 基礎攻撃力（装備・レベル・ジョブ補正）\n"
				+ "2. 会心（既定倍率 ×1.5、武器個別設定あり）\n"
				+ "3. 陣形×射程の与ダメ補正\n"
				+ "4. 属性（弱点 ×1.25 / 耐性 ×0.75）\n"
				+ "5. 属性値ボーナス / 生態特効（codex_class 一致で ×1.3 等）\n"
				+ "6. 属性シナジー / Biome 有利属性（×1.15）\n"
				+ "7. 天候の属性・全体補正\n"
				+ "8. 敵 DEF 逓減軽減 … damage × 100/(100+DEF)\n"
				+ "   （防御DOWN で実効 DEF 低下）\n"
				+ "9. 敵の被ダメ状態補正（標的・脆弱・感電等）\n"
				+ "10. 最終 ±10% 乱数\n\n"
				+ "【敵→味方（被ダメ）】\n"
				+ "敵 ATK × 威力 − 味方 DEF（最低 1）\n"
				+ "→ 防御状態・陣形・パッシブ被ダメ軽減\n"
				+ "→ 回避判定（装備合算、上限 50%）\n"
				+ "→ 防具の属性耐性（一致時 ×0.75）\n"
				+ "→ 最終 ±10% 乱数\n\n"
				+ "スキルダメージ = 基礎攻撃力 × power_multiplier を起点に上記を適用。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G012",
			"display_name": "状態異常コンボ",
			"description": (
				"味方の攻撃が敵に命中した瞬間、\n"
				+ "敵に特定の状態異常が乗っていれば「起爆」して追加ダメージを与える。\n"
				+ "1 ヒットにつき 1 コンボのみ。起爆時にその状態は消費される。\n\n"
				+ "【敵状態コンボ】\n"
				+ "毒爆発 … 毒スタック × 8 追加ダメ\n"
				+ "出血追撃 … 出血スタック × 6 追加ダメ（斬 tag 必須）\n"
				+ "粉砕 … 与ダメの 50% 追加（冷却が必要）\n"
				+ "感電 … 与ダメの 40% 追加（電気 tag 必須）\n\n"
				+ "【味方バフコンボ】\n"
				+ "鼓舞必殺 … 必殺技のみ。与ダメの 35% 追加（鼓舞消費）\n\n"
				+ "評価順: 毒 → 出血 → 冷却 → 感電（敵側）。\n"
				+ "敵コンボ不成立時のみ味方バフコンボを評価する。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G013",
			"display_name": "天候",
			"description": (
				"ダンジョン run 開始時に天候が 1 つ抽選され、\n"
				+ "その run 中は固定される（敵 Lv や地形と同様）。\n\n"
				+ "【種類と効果】\n"
				+ "晴れ … 補正なし（出現率 55%）\n"
				+ "雨 … 電気属性 ×1.15 / 炎属性 ×0.90\n"
				+ "夜 … 闇属性 ×1.15 / 聖属性 ×0.90\n"
				+ "霧 … 全体与ダメ ×0.95 / 全体被ダメ ×0.95\n\n"
				+ "天候は属性別補正と全体補正の両方があり、\n"
				+ "戦闘ログに [天候:○○] として表示される。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G014",
			"display_name": "探索方針",
			"description": (
				"run 単位で 1 つ設定する探索の優先方針。\n"
				+ "編成プリセットに保存され、ダンジョン突入時に適用される。\n\n"
				+ "なし … 通常報酬\n"
				+ "安全優先 … 被ダメ ×0.92・群れ出現率半減\n"
				+ "素材優先 … ゴールド +15%・エリート素材率 UP\n"
				+ "レリック優先 … ボス/エリートのレリック率 UP\n"
				+ "図鑑優先 … 図鑑進捗 2 倍・未完了敵は経験値 +10%・素材率 UP\n\n"
				+ "安全優先の被ダメ軽減は、陣形・防御等の他補正と乗算される。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G015",
			"display_name": "遺物パッシブ",
			"description": (
				"遺物（Relic）はメンバー 1 人につき 1 つ装備できるパッシブ。\n"
				+ "ダンジョンで入手し、図鑑で確認できる。\n\n"
				+ "【全 8 種】\n"
				+ "王国軍旗 … 与ダメ +10%（前列のみ）\n"
				+ "王盾の欠片 … 被ダメ -10%\n"
				+ "古い砂時計 … 行動速度 +10%（CT 短縮）\n"
				+ "狂戦士の護符 … 与ダメ +20% / 被ダメ +15%\n"
				+ "狩人の印 … 4 回与ダメごとに追撃（30%）\n"
				+ "反応の盾片 … 被弾時 HP50% 未満で防御付与\n"
				+ "弔鐘の指輪 … 味方戦闘不能時に自身を鼓舞\n"
				+ "斥候の片眼 … 行動速度 +5% / 与ダメ +5%\n\n"
				+ "常時効果（与ダメ/被ダメ/速度）と、\n"
				+ "トリガー型（被弾時・攻撃時・味方死亡時）がある。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G016",
			"display_name": "キャラ・ジョブパッシブ",
			"description": (
				"各冒険者はキャラ固有パッシブを持つ（基本 5 人ロスター）。\n"
				+ "助っ人・非基本ロスターはジョブフォールバックパッシブを使用。\n\n"
				+ "【パッシブの種類】\n"
				+ "常時効果 … 与ダメ/被ダメ/回避/経験値/必殺威力 等\n"
				+ "トリガー型 … 戦闘開始 / 被弾 / 攻撃 N 回 / 味方死亡 等で発動\n"
				+ "効果例 … 反撃 / 追撃 / 回復 / 状態付与 / 次攻撃威力 UP\n\n"
				+ "トリガー型には CT 秒単位の内部 CD があるものもある。\n"
				+ "（例: 聖盾の砦 … 被弾時反撃、CD 3 CT 秒）\n\n"
				+ "ジョブパッシブ例:\n"
				+ "鉄壁（ヴァンガード）/ 高揚（ソードマン）/ 先読み（レンジャー）\n"
				+ "野戦救護（アルケミスト）/ 群れの本能（ビーストテイマー）"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G017",
			"display_name": "編成シナジー",
			"description": (
				"パーティ編成により、戦闘ボーナスが付与される。\n\n"
				+ "【属性シナジー】（武器タグ）\n"
				+ "同属性 2 人 … その属性の与ダメ +10%\n"
				+ "同属性 3 人以上 … +15%\n\n"
				+ "【物理タグシナジー】（斬/刺/打）\n"
				+ "同タグ 2 人 … 与ダメ +5%\n"
				+ "同タグ 3 人以上 … +8%\n\n"
				+ "【ロールシナジー】（ジョブ role）\n"
				+ "タンク 2 人以上 … 被ダメ -8%\n"
				+ "DPS 2 人以上 … 与ダメ +6%\n"
				+ "サポート 2 人以上 … 回復 +20%\n"
				+ "スカウト 2 人以上 … 会心 +8%\n\n"
				+ "複数のシナジーは同時に成立しうる。"
			),
			"discovered": true,
		},
		{
			"id": "EQUIP-G001",
			"display_name": "装備レアリティ",
			"description": (
				"武器・防具・装飾品には 4 段階のレアリティがある。\n\n"
				+ "コモン（★1）… 基本性能。ボーナスステ 1 種\n"
				+ "レア（★2）  … ボーナスステ 2 種\n"
				+ "エピック（★3）… ボーナスステ 3 種\n"
				+ "レジェンド（★4）… ボーナスステ 4 種・固有効果あり\n\n"
				+ "レアリティが高いほど、\n"
				+ "・ランダムステの振れ幅が大きい\n"
				+ "・炉研ぎに必要な高級素材が変わる\n"
				+ "・ドロップ率が低い\n\n"
				+ "表示は ★ の数と宝石記号（◇◆✦★）で区別される。\n"
				+ "レジェンド装備には専用バッジが付く。"
			),
			"discovered": true,
		},
		{
			"id": "EQUIP-G002",
			"display_name": "キャラクターレアリティ",
			"description": (
				"冒険者（キャラ）にも ★1〜★4 のレアリティがある。\n"
				+ "装備レアリティとは別体系。\n\n"
				+ "【基本 5 職スターター】\n"
				+ "★4 固定。ガチャ対象外。\n\n"
				+ "【ガチャ助っ人】\n"
				+ "★1 45% / ★2 30% / ★3 20% / ★4 5%\n"
				+ "★が高いほど素体ステータスが上昇:\n"
				+ "★2 … HP+3 / ATK+1\n"
				+ "★3 … HP+6 / ATK+2 / DEF+1\n"
				+ "★4 … HP+10 / ATK+4 / DEF+2\n\n"
				+ "重複取得時は欠片（還元）を得る（★1=1 … ★4=8）。"
			),
			"discovered": true,
		},
		{
			"id": "EQUIP-G003",
			"display_name": "冒険者レベルアップ",
			"description": (
				"冒険者は最大 Lv.99 まで成長する。\n"
				+ "経験値（EXP）はラン成功時にパーティ全員へ付与される。\n\n"
				+ "【次レベルまでの EXP】\n"
				+ "100 × 現在レベル（例: Lv10→11 は 1000 EXP）\n\n"
				+ "【レベルアップ成長】\n"
				+ "Lv1〜50 … HP +6 / ATK +2（累積ボーナス）\n"
				+ "Lv51〜99 … HP +3 / ATK +1（ソフトキャップ・逓減成長）\n\n"
				+ "Lv50 以降は新スキル習得なし（ステのみ成長）。\n"
				+ "パッシブや装備の経験値ボーナスで獲得 EXP が増える。\n\n"
				+ "装備レベルの上限も冒険者レベルに連動する。"
			),
			"discovered": true,
		},
		{
			"id": "EQUIP-G004",
			"display_name": "装備レベル",
			"description": (
				"装備品には個別の装備レベル（equip_level）がある。\n"
				+ "表示名に「Lv.X」として付く（Lv.1 は非表示）。\n\n"
				+ "【成長の仕組み】\n"
				+ "戦闘で装備中のアイテムに経験値が入る。\n"
				+ "敵撃破ごとに max(1, 敵Lv÷2) の装備 EXP を獲得。\n\n"
				+ "【次レベルまで】\n"
				+ "10 + 現在装備レベル × 5 の EXP\n"
				+ "（例: Lv5→6 は 35 EXP）\n\n"
				+ "【ステ上昇】\n"
				+ "実効ステ = 基礎値 + floor(基礎値 × 成長率 × (Lv-1))\n"
				+ "成長率 … 通常 4% / レジェンド 5%\n\n"
				+ "【上限】\n"
				+ "装備レベル上限 = 装備者の冒険者レベル（最大 99）。\n"
				+ "ドロップ時の初期レベルはダンジョン敵 Lv 付近（±1）。"
			),
			"discovered": true,
		},
		{
			"id": "EQUIP-G005",
			"display_name": "炉研ぎ（強化）",
			"description": (
				"鍛冶屋の「炉研ぎ」で装備を +1〜+5 まで強化できる。\n"
				+ "武器・防具・装飾品が対象。鑑定済みのみ可能。\n\n"
				+ "【効果】\n"
				+ "武器 … 攻撃力 +1（炉研ぎ値ぶん加算）\n"
				+ "防具 … 防御力 +1 / HP +2（炉研ぎ値ぶん加算）\n"
				+ "装飾 … 各ステ +1（炉研ぎ値ぶん加算）\n"
				+ "※装備レベル成長とは別枠で加算される。\n\n"
				+ "【消費（+N するごと）】\n"
				+ "ゴールド … +1=30 / +2=50 / +3=80 / +4=120 / +5=180\n"
				+ "素材 … 遺物の欠片（全段階）＋レアリティ別の鉱石\n"
				+ "  コモン … 基礎鉱石\n"
				+ "  レア … 古代の骨\n"
				+ "  エピック … エピック鉱石\n"
				+ "  レジェンド … 精鋭遺物の欠片（+4 以降は追加消費）\n\n"
				+ "高レア・高段階ほど素材消費が増える。"
			),
			"discovered": true,
		},
		{
			"id": "EQUIP-G006",
			"display_name": "武器ステータス",
			"description": (
				"武器は個体ごとにランダムステが付く（ドロップ/鍛冶生成時）。\n\n"
				+ "【必須】\n"
				+ "攻撃力（基礎値 + ランダムボーナス）\n"
				+ "属性 / 射程 / 重量 / ノックバック 等\n\n"
				+ "【ランダムボーナス候補】\n"
				+ "属性値 … 属性武器のみ\n"
				+ "生態特効（bane）… 特定の敵クラスに ×1.3\n"
				+ "攻撃速度 … 行動 CT 短縮に影響\n"
				+ "会心率 / 会心ダメージ\n"
				+ "on_hit 状態異常 … 毒/冷却/感電/炎上/呪い 等\n\n"
				+ "最大値に振れたステには ⭐️ が付く（パーフェクトロール）。\n"
				+ "Affix（接頭/接尾）による追加補正もある。"
			),
			"discovered": true,
		},
		{
			"id": "EQUIP-G007",
			"display_name": "防具・装飾ステータス",
			"description": (
				"【防具の必須】\n"
				+ "防御力（基礎値 + ランダムボーナス）\n\n"
				+ "【防具のランダムボーナス候補】\n"
				+ "HP ボーナス\n"
				+ "属性耐性（最大 1〜3 属性、被ダメ軽減）\n"
				+ "回避率\n"
				+ "経験値/ゴールド/レアドロップ率 UP\n"
				+ "状態異常免疫（毒/冷却/感電/炎上/呪い/スタン 等）\n\n"
				+ "【装飾品】\n"
				+ "必須ステなし。レアリティに応じ 1〜4 種のボーナス。\n"
				+ "HP / 攻撃 / 防御 / 会心率 / 回避率\n"
				+ "経験値/ゴールド/レアドロップ率 UP\n\n"
				+ "防具の属性耐性は敵攻撃属性と一致時 ×0.75（-25%）。\n"
				+ "回避率は装備合算で上限 50%。"
			),
			"discovered": true,
		},
		{
			"id": "EQUIP-G008",
			"display_name": "Affix（接頭・接尾）",
			"description": (
				"装備には Affix（接頭語・接尾語）が付くことがある。\n"
				+ "ドロップ時・鍛冶生成時に自動付与（鑑定済み状態）。\n\n"
				+ "【枠】\n"
				+ "武器 … 接頭（prefix）+ 接尾（suffix）\n"
				+ "防具・装飾 … 接頭（prefix）のみ\n\n"
				+ "【効果例】\n"
				+ "攻撃力/防御力/HP 加算\n"
				+ "会心・攻撃速度・回避\n"
				+ "ゴールド/経験値/素材/回復量 UP\n"
				+ "攻撃時の状態異常付与確率（感電/炎上/冷却/毒 等）\n\n"
				+ "Affix の tier は装備レアリティに応じて抽選される。\n"
				+ "装備中の全 Affix が戦闘・報酬計算に反映される。"
			),
			"discovered": true,
		},
		{
			"id": "EQUIP-G009",
			"display_name": "分解と強化素材",
			"description": (
				"鍛冶屋で不要装備を分解し、炉研ぎ素材を回収できる。\n"
				+ "鑑定済み・未装備のみ対象。\n\n"
				+ "【分解産出（レアリティ別）】\n"
				+ "コモン … 基礎鉱石×2 + 遺物の欠片×1\n"
				+ "レア … 古代の骨×1 + 遺物の欠片×1\n"
				+ "エピック … エピック鉱石×1 + 遺物の欠片×2\n"
				+ "レジェンド … 精鋭遺物の欠片×1 + 遺物の欠片×2\n\n"
				+ "炉研ぎ済み（+N）装備は追加で遺物の欠片を返す。\n"
				+ "コモン/レアは一括分解にも対応。\n\n"
				+ "【戦闘ドロップ素材】\n"
				+ "基礎鉱石・遺物の欠片が敵から落ちる（炉研ぎ用）。\n"
				+ "探索方針「素材優先」でドロップ率が上昇する。"
			),
			"discovered": true,
		},
	]

static func is_discovered(category: String, entry_id: String) -> bool:
	if entry_id.is_empty() or category.is_empty():
		return false
	if category == "history":
		if entry_id in STARTER_HISTORY_IDS:
			return true
		if _registry_has("history", entry_id):
			return true
		for lore_id in LORE_TO_HISTORY:
			if str(LORE_TO_HISTORY[lore_id]) == entry_id and _registry_has("lore", lore_id):
				return true
		return false
	return _registry_has(category, entry_id)

static func _registry_has(category: String, entry_id: String) -> bool:
	return GameState.discovery_registry.has("%s:%s" % [category, entry_id])

func _build_enemy_entries() -> Array:
	var entries: Array = []
	for data in DataRegistry.get_all_enemy_data():
		if data == null or data.id.is_empty():
			continue
		var stage: int = GameState.get_enemy_stage(data.id)
		entries.append({
			"id": data.id,
			"display_name": data.display_name if stage >= 2 else UNKNOWN_DISPLAY,
			"stage": stage,
			"codex_class": data.codex_class,
			"codex_danger": data.codex_danger,
			"codex_habitat": data.codex_habitat,
			"element_weakness": data.element_weakness.duplicate(),
			"element_resist": data.element_resist.duplicate(),
			"codex_research_note": data.codex_research_note,
			"codex_materials": data.codex_materials.duplicate(),
			"attack_speed": data.attack_speed,
			"on_hit_status_id": data.on_hit_status_id,
			"on_hit_status_chance": data.on_hit_status_chance,
			"skill_ids": data.skill_ids.duplicate(),
		})
	return entries

func _build_dungeon_entries() -> Array:
	var entries: Array = []
	var bible_map: Dictionary = _load_dungeon_bible_map()
	for data in DataRegistry.get_all_dungeon_data():
		if data == null or data.id.is_empty():
			continue
		var bible_id: String = str(DUNGEON_ID_TO_BIBLE.get(data.id, ""))
		var bible: Dictionary = bible_map.get(bible_id, {})
		var display_name: String = str(bible.get("name", ""))
		if display_name.is_empty():
			display_name = data.display_name
		var overview: String = _CodexContent.build_dungeon_overview(data, str(bible.get("overview", "")))
		entries.append(_make_dungeon_entry(data.id, display_name, overview, bible, data))
	return entries

func _build_material_entries() -> Array:
	var entries: Array = []
	for data in DataRegistry.get_all_material_data():
		if data == null or data.id.is_empty():
			continue
		if not EquipmentEnhancer.is_enhancement_material(str(data.id)):
			continue
		var description: String = str(data.description)
		var lore_id: String = str(data.lore_id)
		if not lore_id.is_empty():
			description += "\n\n関連歴史: %s" % _history_title(lore_id)
		entries.append(_make_entry(
			data.id,
			data.display_name,
			str(data.icon),
			description,
			"material"
		))
		entries[entries.size() - 1]["rarity"] = int(data.rarity)
	return entries

func _build_weapon_entries() -> Array:
	var entries: Array = []
	for data in DataRegistry.get_all_weapon_data():
		if data == null or data.id.is_empty():
			continue
		var description: String = _CodexContent.build_weapon_description(data)
		entries.append(_make_entry(
			data.id,
			data.display_name,
			"",
			description,
			"weapon"
		))
	return entries

func _build_history_entries() -> Array:
	var entries: Array = []
	for raw in _load_history_bible_entries():
		var he_id: String = str(raw.get("id", ""))
		if he_id.is_empty():
			continue
		entries.append(_make_history_entry(raw))
	return entries

func _build_lore_entries() -> Array:
	var entries: Array = []
	for raw in _load_fragment_entries():
		var lf_id: String = str(raw.get("id", ""))
		if lf_id.is_empty():
			continue
		var body: String = str(raw.get("body", ""))
		var medium: String = str(raw.get("medium", ""))
		var source: String = str(raw.get("source", ""))
		var description: String = body
		if not medium.is_empty():
			description += "\n\n媒体: " + medium
		if not source.is_empty():
			description += "\n出自: " + source
		entries.append(_make_entry(lf_id, str(raw.get("title", "")), "", description, "lore"))
	return entries

func _load_fragment_entries() -> Array:
	if not _fragment_entries_cache.is_empty():
		return _fragment_entries_cache
	if not FileAccess.file_exists(FRAGMENTS_PATH):
		_fragment_entries_cache = []
		return _fragment_entries_cache
	var lines: PackedStringArray = FileAccess.get_file_as_string(FRAGMENTS_PATH).split("\n")
	var entries: Array = []
	var i: int = 0
	while i < lines.size():
		var line: String = lines[i].strip_edges()
		if not line.begins_with("# LF "):
			i += 1
			continue
		var body_text: String = line.substr(5).strip_edges()
		var space_idx: int = body_text.find(" ")
		var lf_id: String = body_text.substr(0, space_idx) if space_idx >= 0 else body_text
		var title: String = body_text.substr(space_idx + 1).strip_edges() if space_idx >= 0 else ""
		i += 1
		var sections: Dictionary = _collect_markdown_sections(lines, i, "## ", "# LF ")
		i = int(sections.get("next_index", i))
		entries.append({
			"id": lf_id,
			"title": title,
			"body": str(sections.get("Body", "")),
			"medium": str(sections.get("Medium", "")),
			"source": str(sections.get("Source", "")),
		})
	_fragment_entries_cache = entries
	return _fragment_entries_cache

func _make_entry(entry_id: String, display_name: String, icon: String, description: String, category: String) -> Dictionary:
	var discovered: bool = is_discovered(category, entry_id)
	return {
		"id": entry_id,
		"display_name": display_name if discovered else UNKNOWN_DISPLAY,
		"icon": icon if discovered else "",
		"description": description if discovered else "",
		"discovered": discovered,
	}

func _make_history_entry(raw: Dictionary) -> Dictionary:
	var he_id: String = str(raw.get("id", ""))
	var title: String = str(raw.get("title", ""))
	var overview: String = str(raw.get("overview", ""))
	var entry: Dictionary = _make_entry(he_id, title, "", overview, "history")
	if not bool(entry.get("discovered", false)):
		entry["era"] = ""
		entry["related_entries"] = []
		return entry
	entry["era"] = str(raw.get("era", ""))
	entry["related_entries"] = raw.get("related_entries", []).duplicate()
	return entry

func _make_dungeon_entry(entry_id: String, display_name: String, overview: String, bible: Dictionary, dungeon_data: Resource = null) -> Dictionary:
	var entry: Dictionary = _make_entry(entry_id, display_name, "", overview, "dungeon")
	if not bool(entry.get("discovered", false)):
		entry["location"] = ""
		entry["exploration_theme"] = ""
		entry["related_history"] = []
		return entry
	var location: String = str(bible.get("location", ""))
	if location.is_empty():
		location = _CodexContent.dungeon_location(entry_id, display_name)
	entry["location"] = location
	var theme: String = str(bible.get("exploration_theme", ""))
	if theme.is_empty() and dungeon_data != null:
		theme = _CodexContent.dungeon_exploration_theme(dungeon_data)
	entry["exploration_theme"] = theme
	var related: Array = bible.get("related_history", []).duplicate()
	if related.is_empty():
		related = _CodexContent.dungeon_related_history(entry_id)
	entry["related_history"] = related
	return entry

func _load_history_bible_entries() -> Array:
	if not _history_entries_cache.is_empty():
		return _history_entries_cache
	if not FileAccess.file_exists(HISTORY_BIBLE_PATH):
		_history_entries_cache = []
		return _history_entries_cache
	var lines: PackedStringArray = FileAccess.get_file_as_string(HISTORY_BIBLE_PATH).split("\n")
	var entries: Array = []
	var i: int = 0
	while i < lines.size():
		var line: String = lines[i].strip_edges()
		if not line.begins_with("# HE-"):
			i += 1
			continue
		var body: String = line.substr(2).strip_edges()
		var space_idx: int = body.find(" ")
		var he_id: String = body.substr(0, space_idx) if space_idx >= 0 else body
		var title: String = body.substr(space_idx + 1).strip_edges() if space_idx >= 0 else ""
		i += 1
		var sections: Dictionary = _collect_markdown_sections(lines, i, "## ", "# HE-")
		i = int(sections.get("next_index", i))
		entries.append({
			"id": he_id,
			"title": title,
			"overview": str(sections.get("Overview", "")),
			"era": str(sections.get("Era", "")),
			"related_entries": _parse_related_ids(str(sections.get("Related History Entries", ""))),
		})
	_history_entries_cache = entries
	return _history_entries_cache

func _load_dungeon_bible_map() -> Dictionary:
	if not _dungeon_bible_cache.is_empty():
		return _dungeon_bible_cache
	if not FileAccess.file_exists(DUNGEON_BIBLE_PATH):
		_dungeon_bible_cache = {}
		return _dungeon_bible_cache
	var lines: PackedStringArray = FileAccess.get_file_as_string(DUNGEON_BIBLE_PATH).split("\n")
	var map: Dictionary = {}
	var i: int = 0
	while i < lines.size():
		var line: String = lines[i].strip_edges()
		if not line.begins_with("## Dungeon-"):
			i += 1
			continue
		var body: String = line.substr(3).strip_edges()
		var space_idx: int = body.find(" ")
		var bible_id: String = body.substr(0, space_idx) if space_idx >= 0 else body
		var name: String = body.substr(space_idx + 1).strip_edges() if space_idx >= 0 else ""
		i += 1
		var sections: Dictionary = _collect_markdown_sections(lines, i, "### ", "## Dungeon-")
		i = int(sections.get("next_index", i))
		map[bible_id] = {
			"id": bible_id,
			"name": name,
			"overview": str(sections.get("Overview", "")),
			"location": str(sections.get("Location", "")),
			"exploration_theme": str(sections.get("Exploration Theme", "")),
			"related_history": _parse_related_ids(str(sections.get("Related History Entries", ""))),
		}
	_dungeon_bible_cache = map
	return _dungeon_bible_cache

func _collect_markdown_sections(
	lines: PackedStringArray,
	start_index: int,
	section_prefix: String,
	stop_prefix: String
) -> Dictionary:
	var sections: Dictionary = {"next_index": start_index}
	var i: int = start_index
	while i < lines.size():
		var line: String = lines[i].strip_edges()
		if line.begins_with(stop_prefix):
			sections["next_index"] = i
			return sections
		if line.begins_with(section_prefix):
			var section_name: String = line.substr(section_prefix.length()).strip_edges()
			i += 1
			var parts: PackedStringArray = []
			while i < lines.size():
				var inner: String = lines[i].strip_edges()
				if inner.begins_with(section_prefix) or inner.begins_with(stop_prefix) or inner == "---":
					break
				if not inner.is_empty():
					parts.append(inner)
				i += 1
			sections[section_name] = "\n".join(parts)
			continue
		i += 1
	sections["next_index"] = i
	return sections

func _history_title(he_id: String) -> String:
	for raw in _load_history_bible_entries():
		if str(raw.get("id", "")) == he_id:
			var title: String = str(raw.get("title", ""))
			if title.is_empty():
				return he_id
			return "%s %s" % [he_id, title]
	return he_id


func _parse_related_ids(section_body: String) -> Array[String]:
	var ids: Array[String] = []
	if section_body.is_empty():
		return ids
	for line in section_body.split("\n"):
		var trimmed: String = line.strip_edges()
		if not trimmed.begins_with("- "):
			continue
		var rest: String = trimmed.substr(2).strip_edges()
		if not rest.begins_with("HE-"):
			continue
		var space_idx: int = rest.find(" ")
		var he_id: String = rest.substr(0, space_idx) if space_idx >= 0 else rest
		if not he_id.is_empty():
			ids.append(he_id)
	return ids
