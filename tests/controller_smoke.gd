extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if ok: print("PASS: ", message)
	else:
		failed = true
		push_error(message)
func axis(value: float, index: int = JOY_AXIS_LEFT_X) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func button(index: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")
func run() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	world.show_start_menu = false
	root.add_child(world)
	current_scene = world
	world.get_node("SpawnTimer").stop()
	axis(0.1)
	check(vector().is_zero_approx(), "Stick deadzone suppresses drift")
	axis(0.5)
	check(vector().x > 0 and vector().x < 1, "Partial stick gives analog speed")
	axis(1.0)
	for i in range(30): await physics_frame
	check(world.player.position.x > 1.0, "Left stick moves character")
	axis(-1.0, JOY_AXIS_LEFT_Y)
	check(vector().y < 0 and vector().length() <= 1.001, "Up direction and diagonal speed are correct")
	axis(0.0)
	axis(0.0, JOY_AXIS_LEFT_Y)
	button(JOY_BUTTON_DPAD_LEFT, true)
	check(vector().x == -1.0, "D-pad moves at full speed")
	button(JOY_BUTTON_DPAD_LEFT, false)
	check(vector().is_zero_approx(), "Released controls stop movement input")
	world.player.take_damage(1000)
	button(JOY_BUTTON_Y, true)
	await physics_frame
	button(JOY_BUTTON_Y, false)
	for i in range(5): await physics_frame
	check(current_scene != world and current_scene.player.health == 100, "Y restarts after game over")
	print("CONTROLLER TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)



