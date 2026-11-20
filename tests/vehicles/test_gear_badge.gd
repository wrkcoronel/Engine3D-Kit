extends TestCase


func test_badge_is_red_in_manual_and_white_in_auto() -> void:
	assert_eq(GearBadge.background_color(true), GearBadge.MANUAL_COLOR, "manual e vermelha")
	assert_eq(GearBadge.background_color(false), GearBadge.AUTO_COLOR, "auto e branca")
