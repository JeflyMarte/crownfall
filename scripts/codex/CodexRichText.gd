class_name CodexRichText
extends RefCounted

## 図鑑本文の BBCode 強調（P3-CODEX-COPY-001）。

const COLOR_SECTION: String = "#D4B56A"
const COLOR_PROPER: String = "#9FD0EA"
const COLOR_EMPH: String = "#E8C48A"
const COLOR_WARN: String = "#E09070"

## 固有名詞・用語（長い語を先に置換）
const PROPER_NOUNS: Array[String] = [
	"モーンゲート",
	"ウィスパーウッド",
	"ミストフェン",
	"ブラックショア",
	"フロストリッジ",
	"アステリア",
	"セルディオン",
	"ネレイオン",
	"エルディオン",
	"モルドガル",
	"グランヴェル",
	"潮脈王",
	"海統王",
	"ヴァンガード",
	"ソードマン",
	"レンジャー",
	"アルケミスト",
	"ビーストテイマー",
	"遺跡の結晶",
	"王墓の欠片",
	"蒼古の骨鉱",
	"深層結晶",
	"基礎鉱",
	"炉研ぎ",
	"必殺技",
]


static func section(title: String) -> String:
	return "[color=%s]【%s】[/color]" % [COLOR_SECTION, title]


static func proper(term: String) -> String:
	return "[color=%s]%s[/color]" % [COLOR_PROPER, term]


static func emph(term: String) -> String:
	return "[color=%s]%s[/color]" % [COLOR_EMPH, term]


static func warn(term: String) -> String:
	return "[color=%s]%s[/color]" % [COLOR_WARN, term]


## 手引き（既に BBCode）はそのまま。ロア等の平文に見出し・固有名詞色を付与。
static func decorate(text: String) -> String:
	if text.is_empty():
		return text
	if text.find("[color=") >= 0:
		return text
	var out: String = text
	var re_sec := RegEx.new()
	if re_sec.compile("【([^】]+)】") == OK:
		out = re_sec.sub(out, "[color=%s]【$1】[/color]" % COLOR_SECTION, true)
	for noun: String in PROPER_NOUNS:
		out = out.replace(noun, proper(noun))
	return out
