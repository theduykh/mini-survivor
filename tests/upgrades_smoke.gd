extends SceneTree
const Upgrades = preload("res://scripts/upgrades.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func check(ok: bool, message: String) -> void:
	if ok: print("PASS: ", message)
	else:
		failed = true
		push_error(message)

func game() -> Node3D:
	var world = load("res://scenes/world.tscn").instantiate()
	world.show_start_menu = false
	root.add_child(world)
	current_scene = world
	world.player._weapon.set_physics_process(false)
	return world

func button(index: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func clear_combat(world: Node) -> void:
	for enemy in world.get_node("Enemies").get_children(): enemy.free()
	for bullet in get_nodes_in_group("projectiles"): bullet.free()

func bullet(world: Node3D, pierces: int, bounces: int) -> Node3D:
	var round = load("res://scenes/projectile.tscn").instantiate()
	round.pierces_left = pierces
	round.bounces_left = bounces
	round.shooter = world.player
	round.direction = Vector3.FORWARD
	world.add_child(round)
	round.global_position = Vector3(0, 1.2, 0)
	round.look_at(round.global_position + Vector3.FORWARD, Vector3.UP, true)
	return round

func enemy(world: Node3D, at: Vector3) -> CharacterBody3D:
	var orc = world.spawn_enemy(at)
	orc.set_physics_process(false)
	return orc

func run() -> void:
	var world = game()
	await frames(185)
	check(get_nodes_in_group("enemies").size() == 15, "Three seconds creates fifteen enemies across all gates")
	for gate in world.get_node("Spawners").get_children():
		check(gate.spawned == 3, "All five gates spawn simultaneously each second")
	check(not paused and not world.get_node("UpgradeMenu").active, "No upgrade before twenty-five kills")
	world.kills = 24
	get_nodes_in_group("enemies")[0].take_damage(100)
	await frames(3)
	var menu = world.get_node("UpgradeMenu")
	check(paused and menu.active and world.kills == 25, "Twenty-fifth real enemy death pauses and opens choices")
	check(menu.offers.size() == 3 and menu.offers[0].id != menu.offers[1].id and menu.offers[1].id != menu.offers[2].id and menu.offers[0].id != menu.offers[2].id, "Three distinct upgrades offered")
	var count := get_nodes_in_group("enemies").size()
	var time: float = world.elapsed
	var timer: float = world.get_node("SpawnTimer").time_left
	var position: Vector3 = get_nodes_in_group("enemies")[0].global_position
	await frames(75)
	check(get_nodes_in_group("enemies").size() == count and world.elapsed == time and world.get_node("SpawnTimer").time_left == timer and get_nodes_in_group("enemies")[0].global_position == position, "Upgrade menu pauses spawning, enemies and survival clock")
	check(world.get_node("Audio").music.playing, "Music continues during upgrade selection")
	var selected: String = menu.offers[1].id
	button(JOY_BUTTON_DPAD_RIGHT, true)
	button(JOY_BUTTON_DPAD_RIGHT, false)
	button(JOY_BUTTON_A, true)
	button(JOY_BUTTON_A, false)
	check(not paused and not menu.active and world.upgrades_chosen == 1 and world.upgrade_levels.get(selected, 0) == 1, "Xbox D-pad and A apply one choice and resume")
	menu.choose(0)
	check(world.upgrades_chosen == 1 and world.next_upgrade_kills == 50, "Duplicate confirm does not grant an extra upgrade")
	check(is_equal_approx(world.get_node("SpawnTimer").wait_time, 0.95) and world.get_node("SpawnTimer").time_left <= timer, "First upgrade reduces delay to 0.95 without postponing pending spawn")
	var spawned_before := get_nodes_in_group("enemies").size()
	await frames(120)
	check(get_nodes_in_group("enemies").size() >= spawned_before + 2, "Reduced timer continues spawning enemies")
	world.get_node("SpawnTimer").stop()
	clear_combat(world)
	var test_milestones := [50, 75, 100, 150]
	var test_next := [75, 100, 150, 200]
	for idx in range(test_milestones.size()):
		var milestone: int = test_milestones[idx]
		world.kills = milestone - 1
		world._enemy_killed()
		await frames(22)
		check(paused and menu.active, "Milestone %d opens a new choice" % milestone)
		menu.choose(0)
		check(world.next_upgrade_kills == test_next[idx], "Next milestone matches progression")
		check(is_equal_approx(world.get_node("SpawnTimer").wait_time, 1.0 - 0.05 * world.upgrades_chosen), "Every chosen upgrade reduces delay by 0.05 seconds")
	world.kills = 399
	world._enemy_killed()
	for milestone in [200, 250, 300, 400]:
		await frames(22)
		check(paused and world.next_upgrade_kills == milestone, "Crossed milestones are queued without losing choices")
		menu.choose(0)
	check(world.next_upgrade_kills == 500 and not paused, "All queued choices resume normally")
	world.upgrades_chosen = 30
	world._update_spawn_delay()
	check(is_equal_approx(world.get_node("SpawnTimer").wait_time, 0.05), "Long runs retain a positive minimum spawn delay")
	var capped := {}
	for entry in Upgrades.ALL:
		if entry.limit > 0: capped[entry.id] = entry.limit
	var options := Upgrades.offers(capped)
	check(options.size() == 3, "Infinite milestones still have three meaningful options")
	for option in options: check(option.limit == 0, "Capped upgrades never appear again")
	Input.action_press("reset_player")
	await frames(1)
	Input.action_release("reset_player")
	await frames(5)
	world = current_scene
	check(world.upgrades_chosen == 0 and world.next_upgrade_kills == 25 and world.upgrade_levels.is_empty() and world.player._weapon.damage == 100, "Restart resets milestones and all upgrades")
	check(is_equal_approx(world.get_node("SpawnTimer").wait_time, 1.0), "Restart restores one-second spawn delay")
	world.get_node("SpawnTimer").stop()
	world.player._weapon.set_physics_process(false)
	world.get_node("UpgradeMenu").active = false
	world.get_node("UpgradeMenu")._root.hide()
	world.starting_upgrade = false
	paused = false
	var player = world.player
	var gun = player._weapon
	Upgrades.apply("attack", player)
	Upgrades.apply("haste", player)
	Upgrades.apply("critical", player)
	Upgrades.apply("agility", player)
	player.health = 50
	Upgrades.apply("vitality", player)
	check(gun.damage == 130 and is_equal_approx(gun.shot_interval, 1.0 / 1.2) and is_equal_approx(gun.critical_chance, 0.2) and player.speed > 5.5 and player.max_health == 125 and player.health == 75, "Stat upgrades change actual combat values")
	world.upgrade_levels["vampire"] = 2
	world._enemy_killed()
	check(player.health == 79, "Stacked absorption heals four HP per kill")
	player.set_physics_process(false)
	var first = enemy(world, Vector3(0, 0.1, -3))
	var second = enemy(world, Vector3(0, 0.1, -5))
	await frames(3)
	bullet(world, 1, 0)
	await frames(25)
	check(first.health == 90 and second.health == 90, "Piercing hits two enemies exactly once each")
	clear_combat(world)
	first = enemy(world, Vector3(0, 0.1, -3))
	second = enemy(world, Vector3(3, 0.1, -3))
	await frames(3)
	bullet(world, 0, 1)
	await frames(30)
	check(first.health == 90 and second.health == 90, "Ricochet redirects to another nearby enemy")
	clear_combat(world)
	Upgrades.apply("front", player)
	Upgrades.apply("burst", player)
	Upgrades.apply("diagonal", player)
	gun.critical_chance = 1.0 # Deterministic critical damage test.
	gun.aiming = true
	gun.aim_point = Vector3(0, 1, -10)
	player.visual.rotation.y = PI
	await frames(3)
	gun.try_fire()
	check(get_nodes_in_group("projectiles").size() == 4, "Double front shot and diagonal shot combine")
	await frames(12)
	check(get_nodes_in_group("projectiles").size() == 8, "Multishot repeats the entire upgraded volley")
	for round in get_nodes_in_group("projectiles"):
		check(round.damage == 260, "Critical damage is doubled on real projectiles")
	clear_combat(world)
	world.free()
	await frames(10)
	print("UPGRADE TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)




