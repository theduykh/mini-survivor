extends SceneTree
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

func launch(world: Node3D, speed: float = 18.0, distance: float = 28.0) -> Node3D:
	var bullet := load("res://scenes/projectile.tscn").instantiate() as Node3D
	bullet.shooter = world.player
	bullet.speed = speed
	bullet.max_distance = distance
	bullet.direction = Vector3.FORWARD
	world.add_child(bullet)
	bullet.global_position = Vector3(0, 1.2, 0)
	bullet.look_at(bullet.global_position + bullet.direction, Vector3.UP, true)
	return bullet

func run() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	world.show_start_menu = false
	root.add_child(world)
	current_scene = world
	world.player._weapon.set_physics_process(false)
	world.player.set_physics_process(false)
	world.get_node("SpawnTimer").stop()
	var enemy = world.spawn_enemy(Vector3(0, 0.1, -6))
	enemy.set_physics_process(false)
	await frames(3)
	var bullet := launch(world)
	var initial := bullet.global_position
	check(bullet.get_node("Model").global_basis.y.normalized().dot(Vector3.FORWARD) > 0.99, "Model tip points in direction of flight")
	await frames(3)
	check(bullet.global_position.distance_to(initial) > 0.5 and enemy.health == 100, "Bullet moves visibly before damaging a distant enemy")
	await frames(25)
	check(enemy.health == 90 and not is_instance_valid(bullet), "Impact deals damage once and removes bullet")

	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.05)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = Vector3(0, 1.5, -2)
	world.add_child(wall)
	await frames(3)
	var fast := launch(world, 1000.0)
	var hits: Array = []
	fast.impacted.connect(func(hit): hits.append(hit.collider))
	await frames(3)
	check(hits.size() == 1 and hits[0] == wall and enemy.health == 90, "Fast bullet hits thin wall first and cannot damage enemy behind it")
	wall.free()
	var expired := launch(world, 18.0, 1.0)
	await frames(8)
	check(not is_instance_valid(expired), "Bullet disappears at maximum travel distance")
	check(world.player.health == 100, "Projectiles never damage their shooter")
	print("PROJECTILE TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)




