extends SceneTree
var failed := false
func _initialize(): call_deferred("run")
func frames(n: int):
	for i in range(n): await physics_frame
func check(ok: bool, message: String):
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failed = true
func run():
	var world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	check(world.player._weapon.damage == 100 and world.enemy_max_health == 100, "Base damage and enemy HP are 100")
	world.get_node("GameMenu").activate(0)
	await frames(25)
	check(paused and world.starting_upgrade and world.kills == 0, "Free starting choice before any kills or spawns")
	var menu = world.get_node("UpgradeMenu")
	menu.choose(0)
	check(world.upgrades_chosen == 1 and world.next_upgrade_kills == 25 and world.enemy_max_health == 120, "Starting upgrade scales HP and keeps first reward at twenty-five")
	world.player._weapon.set_physics_process(false)
	world.player.set_physics_process(false)
	await frames(290)
	check(world.get_node("Spawners").get_child_count() == 5, "Five spawn gates")
	for gate in world.get_node("Spawners").get_children():
		check(gate.spawned == 5, "All gates spawn simultaneously on each tick")
	var orc = get_nodes_in_group("enemies")[0]
	orc.set_physics_process(false)
	check(orc.health == 120 and orc.max_health == 120, "Spawned orcs use upgraded HP")
	orc.take_damage(30)
	world.get_node("SpawnTimer").stop()
	var test_milestones := [25, 50, 75, 100, 150, 200, 250, 300]
	var test_next := [50, 75, 100, 150, 200, 250, 300, 400]
	for idx in range(test_milestones.size()):
		var milestone: int = test_milestones[idx]
		world.kills = milestone - 1
		check(not menu.active, "No reward before threshold")
		world._enemy_killed()
		await frames(22)
		check(paused and menu.active, "Reward opens at %d kills" % milestone)
		menu.choose(0)
		check(world.next_upgrade_kills == test_next[idx], "Next reward matches milestone progression")
		check(orc.max_health == world.enemy_max_health and orc.health == orc.max_health - 30, "Alive enemies gain twenty HP without erasing prior damage")
		check(world.enemy_max_health == 100 + 20 * world.upgrades_chosen, "Enemy scaling matches upgrades")
		check(is_equal_approx(world.get_node("SpawnTimer").wait_time, 1.0 - 0.05 * world.upgrades_chosen), "Spawn delay scales per upgrade")
	var fresh = world.spawn_enemy(Vector3(10, 0.1, -25))
	check(fresh.health == world.enemy_max_health, "New enemies inherit latest scaling")
	check(world._navigation.region == Rect2i(-19, -29, 39, 59), "Navigation covers extended map")
	check(world.get_chase_path(Vector3(0, 0, -27), Vector3(0, 0, 27)).size() > 50, "Paths reach both ends of longer map")
	check(world.get_node("Ground/CollisionShape3D").shape.size == Vector3(64, 1, 96), "Ground length grows fifty percent")
	check(world.get_node("Boundaries/North").position.z == -30 and world.get_node("Boundaries/East").shape.size.x == 60, "Collision boundaries fit forty by sixty arena")
	world.free()
	await frames(10)
	print("BALANCE TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)
