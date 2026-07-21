class_name HubNinaNavHelper
extends RefCounted

## 拠点ニーナ案内の文案生成（P3-UI-NINA-NAV-001）。UI 非依存で単体テスト可能。

const KIND_RECOMMEND: String = "recommend"
const KIND_FIELD: String = "field"
const KIND_CHAT: String = "chat"

const CHAT_LINES: Array[String] = [
	"記録は欠かさないわ。あなたは前線を任せて。",
	"無理は禁物よ。装備と編成も時々見直してね。",
	"ギルドはいつでも待ってるわ。いってらっしゃい。",
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
		return "日課の報酬が受け取れるわ。下の日課を確認してね。"
	for entry in DailyMissionSystem.get_entries():
		if not bool(entry.get("claimed", false)) and not bool(entry.get("complete", false)):
			var title: String = str(entry.get("title", "")).strip_edges()
			if title.is_empty():
				return "今日の日課がまだ残ってるわよ。"
			return "日課「%s」がまだね。進めておきましょう。" % title
	if _has_party_vacancy():
		return "編成に空きがあるわ。キャラ画面で仲間を入れてね。"
	var explore: String = _explore_recommend_line()
	if not explore.is_empty():
		return explore
	return "ギルドは落ち着いているわ。好きなところから動いて大丈夫よ。"


static func field_or_weather_line() -> String:
	if EventSystem.PERIODIC_EVENTS_ENABLED and EventSystem.is_event_running():
		var event_data: Resource = EventSystem.get_active_event()
		if event_data != null:
			var title: String = str(event_data.title).strip_edges()
			var desc: String = str(event_data.banner_desc).strip_edges()
			if not title.is_empty() and not desc.is_empty():
				return "いまの野外は「%s」。%s" % [title, desc]
			if not title.is_empty():
				return "いまの野外は「%s」よ。記録も忘れずに。" % title
	var weather: String = GameState.get_weather()
	if not weather.is_empty():
		return "直近の野外は%sだったわ。次の探索でも気をつけて。" % CombatWeather.label(weather)
	return "今日の野外は穏やかね。無理のない範囲で調査を。"


static func chat_line() -> String:
	if CHAT_LINES.is_empty():
		return ""
	## 日付キーで安定選択（テスト再現性）。
	var day_key: String = str(Time.get_date_dict_from_system().get("day", 1))
	var idx: int = int(day_key.to_int()) % CHAT_LINES.size()
	return CHAT_LINES[idx]


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
				return "次は%sの「%s」がおすすめよ。" % [dungeon_name, stage_name]
			return "次は%sの探索が進みそうね。" % dungeon_name
	if not GameState.is_dungeon_cleared(biome_id):
		return "次は%sへ出てみない？ 下ナビのダンジョンから出発よ。" % dungeon_name
	return ""
