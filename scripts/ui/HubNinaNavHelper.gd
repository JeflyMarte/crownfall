class_name HubNinaNavHelper
extends RefCounted

## 拠点ニーナ案内の文案生成（P3-UI-NINA-NAV-001）。UI 非依存で単体テスト可能。
## 口調: 支援してくれる後輩の女の子（です・ます／元気で具体的な注意）。

const KIND_RECOMMEND: String = "recommend"
const KIND_FIELD: String = "field"
const KIND_CHAT: String = "chat"

const CHAT_LINES: Array[String] = [
	"記録は任せてください！隊長は前線に集中してくださいね！",
	"無理は禁物ですよ。装備と編成、ときどき見直しましょう！",
	"ギルドはいつでも待ってます。いってらっしゃい！",
]


## ローテ用メッセージ列。先頭=おすすめ1件 → 野外/天候 → 雑談。
static func build_rotation() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append({"kind": KIND_RECOMMEND, "text": recommend_line()})
	out.append({"kind": KIND_FIELD, "text": field_or_weather_line()})
	var chat: String = chat_line()
	if not chat.is_empty():
		out.append({"kind": KIND_CHAT, "text": chat})
	return out


static func recommend_line() -> String:
	DailyMissionSystem.ensure_refreshed()
	if DailyMissionSystem.has_claimable():
		return "日課の報酬、受け取れるみたいです！下の日課を確認してみてくださいね！"
	for entry in DailyMissionSystem.get_entries():
		if not bool(entry.get("claimed", false)) and not bool(entry.get("complete", false)):
			var title: String = str(entry.get("title", "")).strip_edges()
			if title.is_empty():
				return "今日の日課、まだ残ってるみたいです！進めておきましょう！"
			return "日課「%s」がまだみたいです。一緒に片付けちゃいましょう！" % title
	if _has_party_vacancy():
		return "編成に空きがありますよ！キャラ画面で仲間を入れてみてください！"
	var explore: String = _explore_recommend_line()
	if not explore.is_empty():
		return explore
	return "ギルドは落ち着いてます。好きなところから動いて大丈夫ですよ！"


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
	return "今日のダンジョンは穏やかみたいです！無理のない範囲で調査してくださいね！"


static func chat_line() -> String:
	if CHAT_LINES.is_empty():
		return ""
	## 日付キーで安定選択（テスト再現性）。
	var day_key: String = str(Time.get_date_dict_from_system().get("day", 1))
	var idx: int = int(day_key.to_int()) % CHAT_LINES.size()
	return CHAT_LINES[idx]


static func _field_tip_for_event(event_data: Resource) -> String:
	var mod: String = str(event_data.modifier_type).strip_edges()
	var weather_id: String = str(event_data.weather_id).strip_edges()
	if mod == "weather" or not weather_id.is_empty():
		return _weather_tip(weather_id if not weather_id.is_empty() else "rain")
	match mod:
		"none":
			return "特に大きな変化はなさそうです！いつもの調子で大丈夫だと思います！"
		"wander_duck":
			return "コズミックダックの目撃が増えてるみたいです！見つけたら逃さないでくださいね！"
		"wander_raven":
			return "宝冠レイヴンの気配が強めです！珍しい子なので、見かけたら要チェックですよ！"
		"enemy_level":
			return "強めの敵が増えてるみたいです！無理せず、編成と装備を見直してくださいね！"
		"swarm":
			return "群れ遭遇が増えやすいみたいです！範囲攻撃や回復、忘れずに用意しましょう！"
		"elite_rooms":
			return "エリート遭遇が増えそうです！手応えはありますが、素材も期待できそうですね！"
		"exp":
			return "経験の記録がちょっと好調みたいです！探索のタイミング、いいかもですよ！"
		"gold":
			return "調査報酬が少し多めみたいです！今日の探索、お得な気がします！"
		"weapon_drop":
			return "遺物の反応が少し活発です！武器ドロップ、期待していいと思います！"
		"codex":
			return "未確認の気配が増えてるみたいです！図鑑調査、進めてみるチャンスですよ！"
		"featured_biome":
			return "注目区域の調査がおすすめです！報酬も少し上がってるみたいなので、ぜひ！"
		"elite_material":
			return "エリート素材が採れやすいみたいです！余裕があれば狙ってみてくださいね！"
		_:
			var title: String = str(event_data.title).strip_edges()
			if not title.is_empty():
				return "いまは「%s」みたいです！無理せず、気をつけてくださいね！" % title
			return ""


static func _weather_tip(weather: String) -> String:
	match CombatWeather.normalize(weather):
		CombatWeather.RAIN:
			return "今日は雨が多めみたいですね！ダンジョンのぬかるみに気をつけてください！"
		CombatWeather.NIGHT:
			return "今夜寄りみたいですね！暗がりに気をつけて、編成はしっかり整えてください！"
		CombatWeather.FOG:
			return "霧が濃いみたいです！見通しが悪いので、無理な突進は控えましょうね！"
		_:
			return "天気は落ち着いてそうです！いつもどおり、気をつけて行ってくださいね！"


static func _has_party_vacancy() -> bool:
	if GameState.party_members.size() >= GameState.ACTIVE_PARTY_SIZE:
		return false
	for adv in GameState.roster:
		if adv != null and not GameState.is_member_active(adv):
			return true
	return false


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
				return "次は%sの「%s」がおすすめです！下ナビのダンジョンから出発しましょう！" % [dungeon_name, stage_name]
			return "次は%sの探索が進みそうです！行ってみませんか？" % dungeon_name
	if not GameState.is_dungeon_cleared(biome_id):
		return "次は%sへ出てみませんか？ 下ナビのダンジョンから出発できますよ！" % dungeon_name
	return ""
