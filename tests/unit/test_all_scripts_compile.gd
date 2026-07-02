extends GutTest

## P3-FIX-005 — 全 .gd コンパイル検証。
##
## smoke_test.sh は起動時にロードされるスクリプトしか踏まないため、
## 画面遷移で初めてロードされるスクリプト（BottomNavHelper 等）の
## Parse Error を検出できない。ここで res:// 以下の全 .gd を load() し、
## パース/コンパイル失敗（load が null を返す）を洗い出す。
## GUT はプロジェクト通常起動のため autoload（GameState 等）は解決済み。

const SKIP_PREFIXES: PackedStringArray = [
	"res://addons/",
]

func test_all_scripts_load_without_parse_errors() -> void:
	var scripts: Array[String] = []
	_collect_scripts("res://", scripts)
	assert_gt(scripts.size(), 50, "スクリプト収集が機能していること")
	var failures: Array[String] = []
	for path in scripts:
		var script: GDScript = load(path) as GDScript
		if script == null:
			failures.append(path)
	if failures.is_empty():
		pass_test("全 " + str(scripts.size()) + " スクリプトがロード可能")
	else:
		fail_test("コンパイル不能: " + ", ".join(failures))

func _collect_scripts(dir_path: String, out: Array[String]) -> void:
	for prefix in SKIP_PREFIXES:
		if dir_path.begins_with(prefix):
			return
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while not name.is_empty():
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full: String = dir_path.path_join(name)
		if dir.current_is_dir():
			_collect_scripts(full, out)
		elif name.ends_with(".gd"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
