extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run")

func frames(n: int) -> void:
	for i in range(n):
		await physics_frame

func check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ", message)
	if not value:
		failed = true

func key(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	e = InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = false
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func joy(code: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = code
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	e = InputEventJoypadButton.new()
	e.button_index = code
	e.pressed = false
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func run() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	world.show_start_menu = false
	root.add_child(world)
	current_scene = world

	await frames(5)
	check(world.game_speed == 1.0 and is_equal_approx(Engine.time_scale, 1.0), "Initial game speed is 1x and Engine.time_scale is 1.0")
	check(world.speed_button != null and world.speed_button.text == "⚡ 1x", "Speed button exists and displays 1x")

	# Test keyboard toggle (T)
	key(KEY_T)
	await frames(2)
	check(world.game_speed == 2.0 and is_equal_approx(Engine.time_scale, 2.0), "Key T toggles game speed to 2x")
	check(world.speed_button.text == "⚡ 2x", "Speed button text updates to ⚡ 2x")

	# Test controller toggle (Xbox X)
	joy(JOY_BUTTON_X)
	await frames(2)
	check(world.game_speed == 1.0 and is_equal_approx(Engine.time_scale, 1.0), "Xbox button X toggles game speed back to 1x")
	check(world.speed_button.text == "⚡ 1x", "Speed button text updates to ⚡ 1x")

	# Test direct UI button press
	world.speed_button.pressed.emit()
	await frames(2)
	check(world.game_speed == 2.0 and is_equal_approx(Engine.time_scale, 2.0), "UI button press toggles game speed to 2x")

	# Test restart game resets Engine.time_scale to 1.0
	Engine.time_scale = 2.0
	world.restart_game()
	check(is_equal_approx(Engine.time_scale, 1.0), "restart_game resets Engine.time_scale to 1.0")

	# Test cleanup
	world.free()
	await frames(10)
	check(is_equal_approx(Engine.time_scale, 1.0), "Freeing world resets Engine.time_scale to 1.0")

	print("SPEED TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)
