extends SceneTree
var failed := false
func _initialize(): call_deferred("run")
func frames(n: int):
	for i in range(n): await physics_frame
func check(value: bool, message: String):
	print("PASS: " if value else "FAIL: ", message)
	if not value: failed = true
func key(code: int):
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	e = InputEventKey.new()
	e.keycode = code
	e.pressed = false
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func joy(code: int):
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
func run():
	var world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var menu = world.get_node("GameMenu")
	await frames(70)
	check(paused and menu.mode == "start" and world.elapsed == 0 and get_nodes_in_group("enemies").is_empty(), "Start screen freezes game before play")
	key(KEY_ENTER)
	await frames(22)
	check(paused and world.starting_upgrade, "Start offers a free upgrade before combat")
	key(KEY_1)
	await frames(70)
	check(not paused and get_nodes_in_group("enemies").size() == 5, "Enter starts game and spawning")
	world.player._weapon.set_physics_process(false)
	key(KEY_ESCAPE)
	var elapsed: float = world.elapsed
	var left: float = world.get_node("SpawnTimer").time_left
	var position: Vector3 = world.player.position
	await frames(70)
	check(paused and menu.mode == "pause" and world.elapsed == elapsed and world.get_node("SpawnTimer").time_left == left and world.player.position == position, "Pause freezes clock, player and spawn timer")
	joy(JOY_BUTTON_B)
	check(not paused, "Xbox B resumes")
	joy(JOY_BUTTON_START)
	check(paused and menu.mode == "pause", "Xbox Start pauses")
	joy(JOY_BUTTON_A)
	check(not paused, "Xbox A confirms resume")
	world.kills = 49
	world._enemy_killed()
	await frames(22)
	var upgrade = world.get_node("UpgradeMenu")
	var choices: Array = upgrade.offers.duplicate()
	key(KEY_ESCAPE)
	joy(JOY_BUTTON_DPAD_DOWN)
	joy(JOY_BUTTON_DPAD_UP)
	joy(JOY_BUTTON_A)
	check(paused and upgrade.active and upgrade.visible and upgrade.offers == choices, "Resume preserves upgrade choices and paused combat")
	key(KEY_1)
	check(not paused and world.upgrades_chosen == 2, "Upgrade selection still resumes gameplay")
	key(KEY_ESCAPE)
	menu.activate(1)
	await frames(6)
	world = current_scene
	menu = world.get_node("GameMenu")
	check(paused and world.starting_upgrade and menu.mode.is_empty() and world.kills == 0 and world.upgrades_chosen == 0, "Restart resets run and offers initial upgrade")
	key(KEY_ESCAPE)
	menu.activate(2)
	await frames(6)
	world = current_scene
	menu = world.get_node("GameMenu")
	check(paused and menu.mode == "start" and world.kills == 0, "Home returns to start screen with fresh run")
	joy(JOY_BUTTON_DPAD_DOWN)
	var muted: bool = world.get_node("Audio").muted
	joy(JOY_BUTTON_A)
	check(world.get_node("Audio").muted != muted and paused, "Sound toggle works without starting game")
	joy(JOY_BUTTON_DPAD_UP)
	joy(JOY_BUTTON_A)
	check(paused and world.starting_upgrade, "Xbox starts a fresh game with initial upgrade")
	paused = false
	world.free()
	await frames(10)
	print("MENU TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)


