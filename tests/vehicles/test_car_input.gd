extends TestCase


func test_scroll_up_shifts_up_once() -> void:
	var input := CarInput.new()
	input.register_scroll(MOUSE_BUTTON_WHEEL_UP)
	input.update(true)
	assert_true(input.shift_up_pressed, "rolar para cima sobe a marcha")
	assert_true(not input.shift_down_pressed, "rolar para cima nao desce a marcha")
	input.update(true)
	assert_true(not input.shift_up_pressed, "um giro vale uma troca so")


func test_scroll_down_shifts_down_once() -> void:
	var input := CarInput.new()
	input.register_scroll(MOUSE_BUTTON_WHEEL_DOWN)
	input.update(true)
	assert_true(input.shift_down_pressed, "rolar para baixo desce a marcha")
	assert_true(not input.shift_up_pressed, "rolar para baixo nao sobe a marcha")
	input.update(true)
	assert_true(not input.shift_down_pressed, "um giro vale uma troca so")


func test_other_buttons_do_not_shift() -> void:
	var input := CarInput.new()
	input.register_scroll(MOUSE_BUTTON_LEFT)
	input.update(true)
	assert_true(not input.shift_up_pressed, "clique nao sobe a marcha")
	assert_true(not input.shift_down_pressed, "clique nao desce a marcha")
