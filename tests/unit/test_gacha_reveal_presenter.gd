extends GutTest

## 招待状開封リビール（P3-GACHA-REVEAL-001）

const _Presenter := preload("res://scripts/gacha/GachaRevealPresenter.gd")

func test_invite_asset_paths_exist() -> void:
	for path in [
		GachaUiTokens.INVITE_SEALED,
		GachaUiTokens.INVITE_SEALED_STAR2,
		GachaUiTokens.INVITE_OPENING,
		GachaUiTokens.INVITE_OPEN_FRAME,
		GachaUiTokens.INVITE_GLOW,
		GachaUiTokens.INVITE_SEAL_SHARD,
	]:
		assert_true(ResourceLoader.exists(path), "missing invite asset: %s" % path)

func test_rarity_clamp_and_durations() -> void:
	assert_eq(_Presenter.clamp_rarity(1), 2)
	assert_eq(_Presenter.clamp_rarity(5), 4)
	assert_lt(
		_Presenter.duration_for(_Presenter.DUR_OPENING, 2),
		_Presenter.duration_for(_Presenter.DUR_OPENING, 4)
	)
	assert_lt(
		_Presenter.glow_alpha_for(2),
		_Presenter.glow_alpha_for(4)
	)

func test_presenter_skip_when_idle_is_false() -> void:
	var p = _Presenter.new()
	assert_false(p.request_skip())
