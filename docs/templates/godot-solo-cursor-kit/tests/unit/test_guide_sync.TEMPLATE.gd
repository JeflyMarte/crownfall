extends GutTest

## 手引き同期の雛形。プロジェクトの GuideCatalog 相当に合わせて直す。
## ファイル名例: tests/unit/test_guide_sync.gd


func test_guide_has_no_dev_words() -> void:
	## CatalogHelper / GuideCatalog 等からプレイヤー向け本文を集める。
	var joined := ""
	# for entry in YourGuideCatalog.get_entries():
	# 	joined += str(entry.get("description", ""))
	assert_true(true, "TODO: GuideCatalog 接続後に有効化")
	assert_false(joined.contains("オミット"), "プレイヤー向けにオミット禁止")
	assert_false(joined.contains("SURVEY"), "内部英語禁止")


func test_omit_flags_match_copy() -> void:
	## 例: 寄り道オミットなら案内に「選択できない」があり、「一部休止」だけにしない。
	assert_true(true, "TODO: Constants.SUB_* と手引き本文を突合")
