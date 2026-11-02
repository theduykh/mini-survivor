extends SceneTree
## Run: Godot --headless --path . --script res://tests/survivor_smoke.gd
var failed: bool = false

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failed = true
		push_error(message)

func clear_enemies(world: Node) -> void:
	for enemy in world.get_node("Enemies").get_children():
		enemy.free()
	for projectile in get_nodes_in_group("projectiles"):
		projectile.free()

func run() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	world.show_start_menu = false
	root.add_child(world)
	current_scene = world
	var player = world.player
	var gun = player._weapon
	gun.set_physics_process(false)
	await frames(130)
	check(world.get_node("Spawners").get_child_count() == 5, "Five wall-opening spawn gates")
	check(get_nodes_in_group("enemies").size() == 2, "One orc total per second")
	check(world.get_node("Spawners/GateLeft").spawned == 1 and world.get_node("Spawners/GateCenter").spawned == 1 and world.get_node("Spawners/GateRight").spawned == 0, "Gates take turns spawning")
	world.get_node("SpawnTimer").stop()
	clear_enemies(world)
	check(Vector2(player.position.x, player.position.z).length() < 0.1, "Spawning enemies never teleports the player")
	check(player.health == 100 and gun.damage == 100 and is_equal_approx(gun.shot_interval, 1.0), "Player HP and gun stats match requested values")
	# Stationary enemies isolate target selection and the real automatic shots.
	var far = world.spawn_enemy(Vector3(6, 0.1, 0))
	var near = world.spawn_enemy(Vector3(0, 0.1, -4))
	far.set_physics_process(false)
	near.set_physics_process(false)
	await frames(5)
	check(player.current_target == near, "Auto aim selects nearest living enemy")
	check(Vector3(sin(player.visual.rotation.y), 0, cos(player.visual.rotation.y)).dot(Vector3.FORWARD) > 0.99, "Character turns its gun toward the nearest enemy")
	check(near.health == 100 and near.damage == 10, "Orc stats match requested values")
	var shots: Array = []
	gun.fired.connect(func(_projectile): shots.append({"frame": Engine.get_physics_frames()}))
	gun.set_physics_process(true)
	await frames(2)
	check(shots.size() == 1 and near.health == 100, "Auto fire launches a projectile without instant damage")
	await frames(20)
	check(near.health == 0 and world.kills == 1, "Flying projectile deals 100 damage and kills base orc")
	await frames(25)
	check(shots.size() == 1, "No second shot before one second")
	await frames(35)
	check(shots.size() == 2 and world.kills == 2, "Two shots kill two base orcs")
	if shots.size() >= 2:
		check(shots[1].frame - shots[0].frame == 60, "Shots are exactly one second apart at sixty physics ticks")
	await frames(3)
	check(player.current_target == null, "No target remains after both orcs die")
	gun.set_physics_process(false)
	clear_enemies(world)
	await frames(3)
	check(player.current_target == null and gun.target == null, "No living enemies clears aim and firing target")

	# Verify pursuit across the open arena after removing the old obstacles.
	var chaser = world.spawn_enemy(Vector3(-4, 0.1, -7))
	await frames(360)
	var distance: float = Vector2(chaser.position.x - player.position.x, chaser.position.z - player.position.z).length()
	check(distance < 1.6, "Orc crosses open arena and reaches player")
	check(player.health < 100, "Chasing orc attacks player")
	clear_enemies(world)
	player.health = 100
	var attacker = world.spawn_enemy(player.global_position + Vector3(0, 0, 1.1))
	await frames(8)
	check(player.health == 100, "Melee attack has a windup")
	await frames(16)
	check(player.health == 90, "Melee strike deals exactly ten damage")
	await frames(30)
	check(player.health == 90, "Melee cooldown prevents damage every frame")
	await frames(25)
	check(player.health == 80, "Orc attacks again after one second")

	# Walking away during windup should dodge the next hit.
	attacker._attack_cooldown = 0
	attacker._attack_lock = 0
	await frames(2)
	player.position = Vector3(6, 0.1, 6)
	var before: int = player.health
	await frames(18)
	check(player.health == before, "Moving out of melee range avoids the hit")

	# Game over freezes spawning and shooting, and R reloads fresh state.
	player.take_damage(1000)
	check(player.health == 0 and not world.running, "Zero HP triggers game over")
	check(world.get_node("SpawnTimer").is_stopped(), "Game over stops spawn timer")
	var count := shots.size()
	gun.set_physics_process(true)
	await frames(70)
	check(shots.size() == count, "Dead character cannot auto fire")
	Input.action_press("reset_player")
	await frames(1)
	Input.action_release("reset_player")
	await frames(5)
	var restarted = current_scene
	check(restarted != world and restarted.running and restarted.player.health == 100 and restarted.kills == 0, "R restarts with full health and cleared kills")
	check(get_nodes_in_group("enemies").is_empty(), "Restart removes all old enemies")
	await frames(22)
	restarted.get_node("UpgradeMenu").choose(0)
	await frames(65)
	check(get_nodes_in_group("enemies").size() == 1, "Shared spawn schedule restarts correctly")
	current_scene.free()
	await frames(10) # Let audio playback release its mixing buffers.
	print("SURVIVOR TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)





