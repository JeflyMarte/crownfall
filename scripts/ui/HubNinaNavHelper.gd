class_name HubNinaNavHelper
extends RefCounted

## 拠点ニーナ案内の文案生成（P3-UI-NINA-NAV-001）。UI 非依存で単体テスト可能。
## 口調: 支援してくれる後輩の女の子（です・ます／元気で具体的な注意）。

const KIND_RECOMMEND: String = "recommend"
const KIND_FIELD: String = "field"
const KIND_CHAT: String = "chat"

## 1ローテに載せる雑談件数（おすすめ・野外のあとに続く）。
const CHAT_IN_ROTATION: int = 4

const CHAT_LINES: Array[String] = [
	"記録は任せてください！隊長は前線に集中してくださいね！",
	"無理は禁物ですよ。装備と編成、ときどき見直しましょう！",
	"ギルドはいつでも待ってます。いってらっしゃい！",
	"断片でも記録に残せば、あとで繋がることがありますよ！",
	"戻ってきたら、まずは補給と装備の確認からいきましょう！",
	"今日も調査、おつかれさまです！無理せずいきましょうね！",
	"図鑑の空欄、気になりますよね。少しずつ埋めていきましょう！",
	"歴史の一行が増えるたびに、世界が少しだけ近くなります！",
	"記録官としては、隊長の安全が一番大事です。気をつけて！",
	"拠点にいるあいだは、深呼吸して整える時間ですよ！",
	"モーンゲートの空気、まだ慣れますか？ 焦らなくて大丈夫です！",
	"レアな反応があったら、すぐメモしますね。頼ってください！",
	"今日の記録、きれいに残せそうな気がします！頑張りましょう！",
	"編成の相性、たまに見直すだけで全然違いますよ！",
	"日課を片付けると、気持ちまで軽くなりますよね！",
	"鍛冶屋の炉の音、落ち着くんです。私も好きです！",
	"招待状の気配、今日は穏やかみたいですよ！",
	"調査隊の隊長って、かっこいいですよね。応援してます！",
	"戻る道も調査のうちです。焦って遭難しないでくださいね！",
	"敵の習性は、図鑑に残せば次が楽になりますよ！",
	"私も机の前で待ってます。無事に帰ってきてくださいね！",
	"断片が足りなくても大丈夫。積み重ねが歴史になります！",
	"今日の天気メモ、もう書いてあります。参考にしてください！",
	"ギルドの廊下、朝は人が多いです。気をつけて歩いてくださいね！",
	"記録のインクが乾くにおい、私は好きなんです。変ですかね？",
	"隊長の報告書、読みやすいと助かります！短くて大丈夫ですよ！",
	"強敵のあとは休息も仕事です。無理に連戦しないでくださいね！",
	"新しい仲間が増えたら、ぜひ編成も試してみてください！",
	"遺跡の名前、覚えるの大変ですよね。私もまだ勉強中です！",
	"『歴史を持ち帰れ』——私もその言葉、大事にしてます！",
	"今日もいい発見がありますように。いってらっしゃい！",
	"帰ってきたら、お茶くらい淹れときますね。…机の上で！",
	"危険度の高い階層は、装備を厚めにしてからがおすすめです！",
	"記録漏れがないか、あとで一緒に確認しましょうね！",
	"隊長が元気だと、ギルド全体の空気も明るくなりますよ！",
	"小さな発見も大歓迎です。私、そういうの拾うの得意なので！",
]

const FALLBACK_RECOMMEND_LINES: Array[String] = [
	"ギルドは落ち着いてます。好きなところから動いて大丈夫ですよ！",
	"いまは急ぎの用事はなさそうです！好きな調査からどうぞ！",
	"隊長のペースで大丈夫です。私も記録の準備、してますね！",
	"今日は自由探索日、って感じです！気になる場所へ行きましょう！",
	"やることは一通り片付いてます。探索でも整備でも、お好きに！",
]

const CALM_FIELD_LINES: Array[String] = [
	"今日のダンジョンは穏やかみたいです！無理のない範囲で調査してくださいね！",
	"大きな異変の報告はまだです！いつもどおりの調子で大丈夫そうです！",
	"野外の気配は穏やか寄りです。油断は禁物ですが、進めやすそうですよ！",
	"速報は静かめです！記録係としては、落ち着いた調査日が好きです！",
	"きょうは特別な警報なしです！気をつけて、いってらっしゃい！",
]

const CLAIMABLE_LINES: Array[String] = [
	"日課の報酬、受け取れるみたいです！下の日課を確認してみてくださいね！",
	"日課クリアのお礼、まだ受け取ってないみたいですよ！下を見てみてください！",
	"報酬が届いてるようです！日課パネルから受け取っちゃいましょう！",
]

const INCOMPLETE_DAILY_LINES: Array[String] = [
	"日課「%s」がまだみたいです。一緒に片付けちゃいましょう！",
	"今日の日課「%s」、残ってますよ！サクッと進めておきませんか？",
	"日課の「%s」が未完了です！終わるころには報酬も待ってますよ！",
]

const INCOMPLETE_DAILY_GENERIC: Array[String] = [
	"今日の日課、まだ残ってるみたいです！進めておきましょう！",
	"日課が残ってますよ！スキマ時間で片付けちゃうのがおすすめです！",
]

const PARTY_VACANCY_LINES: Array[String] = [
	"編成に空きがありますよ！キャラ画面で仲間を入れてみてください！",
	"パーティに空き枠があります！仲間を入れてから出ると安心ですよ！",
	"まだ編成に入れられる仲間がいますよ！キャラ画面を見てみてください！",
]

## ニューゲーム直後の優先案内（おすすめより前にローテへ載せる）。
const START_GACHA_TIP: String = (
	"招待状アイコンを押して、仲間を集めましょう！\n必要な魔晶石はバッグに入れときました！"
)
const START_SURVEY_TIP: String = "調査室に行って、ダンジョンを開放しましょう！"


## ローテ用メッセージ列。先頭=おすすめ1件 → 野外/天候 → 雑談複数。
## 開始直後は招待状／調査室の優先案内を先に載せる。
static func build_rotation() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var early: Array[String] = early_hub_tips()
	if not early.is_empty():
		for tip in early:
			out.append({"kind": KIND_RECOMMEND, "text": tip})
	else:
		out.append({"kind": KIND_RECOMMEND, "text": recommend_line()})
	out.append({"kind": KIND_FIELD, "text": field_or_weather_line()})
	for chat in pick_chat_lines(CHAT_IN_ROTATION):
		out.append({"kind": KIND_CHAT, "text": chat})
	return out


## 開始時優先案内。該当するものを招待状→調査室の順で返す。
static func early_hub_tips() -> Array[String]:
	var out: Array[String] = []
	if _should_tip_start_gacha():
		out.append(START_GACHA_TIP)
	if _should_tip_start_survey():
		out.append(START_SURVEY_TIP)
	return out


static func recommend_line() -> String:
	var early: Array[String] = early_hub_tips()
	if not early.is_empty():
		return early[0]
	DailyMissionSystem.ensure_refreshed()
	if DailyMissionSystem.has_claimable():
		return _pick_from(CLAIMABLE_LINES, 11)
	for entry in DailyMissionSystem.get_entries():
		if not bool(entry.get("claimed", false)) and not bool(entry.get("complete", false)):
			var title: String = str(entry.get("title", "")).strip_edges()
			if title.is_empty():
				return _pick_from(INCOMPLETE_DAILY_GENERIC, 13)
			var tmpl: String = _pick_from(INCOMPLETE_DAILY_LINES, 17)
			return tmpl % title
	if _has_party_vacancy():
		return _pick_from(PARTY_VACANCY_LINES, 19)
	var explore: String = _explore_recommend_line()
	if not explore.is_empty():
		return explore
	return _pick_from(FALLBACK_RECOMMEND_LINES, 23)


static func field_or_weather_line() -> String:
	if EventSystem.PERIODIC_EVENTS_ENABLED and EventSystem.is_event_running():
		var event_data: Resource = EventSystem.get_active_event()
		if event_data != null:
			var tip: String = _field_tip_for_event(event_data)
			if not tip.is_empty():
				return tip
	var weather: String = GameState.get_weather()
	if not weather.is_empty():
		return _weather_tip(weather)
	return _pick_from(CALM_FIELD_LINES, 29)


static func chat_line() -> String:
	return _pick_from(CHAT_LINES, 31)


## 日付シードで重複なしの雑談を最大 count 件返す。
static func pick_chat_lines(count: int) -> Array[String]:
	var out: Array[String] = []
	if CHAT_LINES.is_empty() or count <= 0:
		return out
	var order: Array[int] = []
	for i in CHAT_LINES.size():
		order.append(i)
	var rng := RandomNumberGenerator.new()
	rng.seed = _day_seed() * 9973 + 41
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	var n: int = mini(count, order.size())
	for k in n:
		out.append(CHAT_LINES[order[k]])
	return out


static func _field_tip_for_event(event_data: Resource) -> String:
	var mod: String = str(event_data.modifier_type).strip_edges()
	var weather_id: String = str(event_data.weather_id).strip_edges()
	if mod == "weather" or not weather_id.is_empty():
		return _weather_tip(weather_id if not weather_id.is_empty() else "rain")
	match mod:
		"none":
			return _pick_from([
				"特に大きな変化はなさそうです！いつもの調子で大丈夫だと思います！",
				"異変なしの報告です！平常運転で調査して大丈夫そうですよ！",
				"きょうは特別な修飾なしみたいです。落ち着いて進めましょう！",
			], 37)
		"wander_duck":
			return _pick_from([
				"コズミックダックの目撃が増えてるみたいです！見つけたら逃さないでくださいね！",
				"ダックの気配が強めです！珍しい子なので、見かけたら要チェックですよ！",
				"空がざわついてます…コズミックダック、出やすいかもです！",
			], 41)
		"wander_raven":
			return _pick_from([
				"宝冠レイヴンの気配が強めです！珍しい子なので、見かけたら要チェックですよ！",
				"レイヴンの羽音が近いみたいです！宝冠関連の反応、要注目です！",
				"黒い影の目撃が増えてます。宝冠レイヴン、チャンスかもですよ！",
			], 43)
		"enemy_level":
			return _pick_from([
				"強めの敵が増えてるみたいです！無理せず、編成と装備を見直してくださいね！",
				"敵の勢いが強めです！無理な深追いより、備えを厚くしましょう！",
				"危険度が上がってる気配です。回復と装備、確認してから出てくださいね！",
			], 47)
		"swarm":
			return _pick_from([
				"群れ遭遇が増えやすいみたいです！範囲攻撃や回復、忘れずに用意しましょう！",
				"群れが出やすい日みたいです！まとめて倒せる備えがあると安心ですよ！",
				"集団遭遇の報告が増えてます。押しつぶされないよう、気をつけて！",
			], 53)
		"elite_rooms":
			return _pick_from([
				"エリート遭遇が増えそうです！手応えはありますが、素材も期待できそうですね！",
				"強敵部屋が増え気味です！勝てそうなら狙って、無理なら回避で！",
				"エリートの気配が濃いです。報酬も厚めなので、余裕があれば挑戦を！",
			], 59)
		"exp":
			return _pick_from([
				"経験の記録がちょっと好調みたいです！探索のタイミング、いいかもですよ！",
				"成長の兆しが良い日みたいです！経験を稼ぎたいなら今がチャンスです！",
				"経験値の調子が良さそうです。育成したい仲間、連れていきませんか？",
			], 61)
		"gold":
			return _pick_from([
				"調査報酬が少し多めみたいです！今日の探索、お得な気がします！",
				"金貨の反応が好調です！稼ぎたい日は、今日が出撃日かもですよ！",
				"報酬が厚めの気配です。探索のついでに、財布も潤いそうです！",
			], 67)
		"weapon_drop":
			return _pick_from([
				"遺物の反応が少し活発です！武器ドロップ、期待していいと思います！",
				"武器の気配が強めです！掘り出し物、見つかるかもですよ！",
				"遺物センサーが反応してます。装備強化のチャンス日かもしれません！",
			], 71)
		"codex":
			return _pick_from([
				"未確認の気配が増えてるみたいです！図鑑調査、進めてみるチャンスですよ！",
				"図鑑向きの反応が良いです！未知の記録、今日は増えやすそうです！",
				"調査記録が埋まりやすい日みたいです。図鑑優先でもいいかもですよ！",
			], 73)
		"featured_biome":
			return _pick_from([
				"注目区域の調査がおすすめです！報酬も少し上がってるみたいなので、ぜひ！",
				"きょうの注目地点、報酬が厚めです！気になる区域から行きましょう！",
				"フィーチャー区域が熱いみたいです。遠征するなら今が良さそうです！",
			], 79)
		"elite_material":
			return _pick_from([
				"エリート素材が採れやすいみたいです！余裕があれば狙ってみてくださいね！",
				"強敵素材の反応が良いです！炉研ぎ用を集めたい日にぴったりですよ！",
				"エリート素材日和です！鍛冶の在庫、補充チャンスかもしれません！",
			], 83)
		_:
			var title: String = str(event_data.title).strip_edges()
			if not title.is_empty():
				return _pick_from([
					"いまは「%s」みたいです！無理せず、気をつけてくださいね！",
					"速報は「%s」です！状況に合わせて動いてくださいね！",
					"きょうの注目は「%s」みたいです。無理は禁物ですよ！",
				], 89) % title
			return ""


static func _weather_tip(weather: String) -> String:
	match CombatWeather.normalize(weather):
		CombatWeather.RAIN:
			return _pick_from([
				"今日は雨が多めみたいですね！ダンジョンのぬかるみに気をつけてください！",
				"雨模様です！足元と視界、いつもより慎重にいきましょうね！",
				"雨の日は滑りやすいです。急な突進は控えめにしてくださいね！",
			], 97)
		CombatWeather.NIGHT:
			return _pick_from([
				"今夜寄りみたいですね！暗がりに気をつけて、編成はしっかり整えてください！",
				"夜寄りです！視界が悪いので、無理な深追いしないでくださいね！",
				"闇が濃い時間帯みたいです。回復と偵察、忘れずに！",
			], 101)
		CombatWeather.FOG:
			return _pick_from([
				"霧が濃いみたいです！見通しが悪いので、無理な突進は控えましょうね！",
				"深い霧です！距離感が狂いやすいので、慎重に進んでください！",
				"霧日和です。迷子になりやすいので、無理せず戻る判断も大事ですよ！",
			], 103)
		_:
			return _pick_from([
				"天気は落ち着いてそうです！いつもどおり、気をつけて行ってくださいね！",
				"空模様は穏やかです！いつも通りの調子で調査して大丈夫そうです！",
				"天候に大きな乱れはなさそうです。油断せず、いってらっしゃい！",
			], 107)


static func _has_party_vacancy() -> bool:
	if GameState.party_members.size() >= GameState.ACTIVE_PARTY_SIZE:
		return false
	for adv in GameState.roster:
		if adv != null and not GameState.is_member_active(adv):
			return true
	return false


## 招待状未使用（助っ人未所持）なら開始案内を出す。
static func _should_tip_start_gacha() -> bool:
	return GameState.owned_helpers.is_empty()


## 調査室を一度も使っていなければ開始案内を出す。
static func _should_tip_start_survey() -> bool:
	if SurveySystem.has_active_cycle():
		return false
	for dungeon_id in GameState.hub_survey_progress.keys():
		if float(GameState.hub_survey_progress[dungeon_id]) > 0.0:
			return false
	return true


static func _explore_recommend_line() -> String:
	var biome_id: String = Constants.DEFAULT_DUNGEON_ID
	var dungeon: Resource = DataRegistry.get_dungeon_data(biome_id)
	var dungeon_name: String = "探索"
	if dungeon != null and not str(dungeon.display_name).is_empty():
		dungeon_name = str(dungeon.display_name)
	if Constants.SUB_STAGES_PLAYABLE:
		var stage_id: String = GameState.resolve_stage_for_run(biome_id)
		if not stage_id.is_empty() and not GameState.is_stage_cleared(stage_id):
			var stage: Resource = DataRegistry.get_stage_data(stage_id)
			var stage_name: String = str(stage.display_name) if stage != null else ""
			if not stage_name.is_empty():
				return _pick_from([
					"次は%sの「%s」がおすすめです！下ナビのダンジョンから出発しましょう！",
					"進捗的には%sの「%s」が次ですね！準備できたら出発どうぞ！",
					"いまの本線は%sの「%s」です！下ナビから行けますよ！",
				], 109) % [dungeon_name, stage_name]
			return _pick_from([
				"次は%sの探索が進みそうです！行ってみませんか？",
				"%s、まだ進めそうな気がします！出撃してみましょう！",
			], 113) % dungeon_name
	if not GameState.is_dungeon_cleared(biome_id):
		return _pick_from([
			"次は%sへ出てみませんか？ 下ナビのダンジョンから出発できますよ！",
			"%sの調査、まだ続きがありそうです！下ナビからどうぞ！",
			"本線は%sです！備えが済んだら、下ナビから出発してくださいね！",
		], 127) % dungeon_name
	return ""


static func _day_seed() -> int:
	var d: Dictionary = Time.get_date_dict_from_system()
	return int(d.get("year", 2026)) * 10000 + int(d.get("month", 1)) * 100 + int(d.get("day", 1))


static func _pick_from(pool: Array[String], salt: int = 0) -> String:
	if pool.is_empty():
		return ""
	var idx: int = absi(_day_seed() * 31 + salt) % pool.size()
	return pool[idx]
