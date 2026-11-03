extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failed = true
		push_error(message)

func run() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	world.show_start_menu = false
	root.add_child(world)
	current_scene = world
	world.player._weapon.set_physics_process(false)

	# Bắt đầu trận đấu: chọn starting upgrade
	world.begin_run()
	await frames(25)
	var menu = world.get_node("UpgradeMenu")
	check(paused and menu.active and world.starting_upgrade, "Trận đấu bắt đầu với chọn nâng cấp khởi đầu")

	menu.choose(0)
	await frames(5)
	check(not paused and not menu.active and not world.starting_upgrade, "Chọn xong khởi đầu, game unpause")
	check(world.current_wave == 1 and world.wave_total_enemies == 20, "Wave 1 có 20 quái")
	check(world.enemy_max_health == 100, "Wave 1 quái có 100 HP")
	check(is_equal_approx(world.get_node("SpawnTimer").wait_time, 0.5), "Thời gian spawn toàn bộ wave là 10s (20 quái -> 0.5s / quái)")
	check(not world.get_node("SpawnTimer").is_stopped(), "Spawn timer tự động chạy")

	# Chờ 10 giây spawn quái (10s x 60fps = 600 frames, thêm 30 frames đệm)
	await frames(630)
	check(world.wave_spawned == 20, "Wave 1 sinh chính xác 20 quái trong 10 giây")
	check(world.get_node("SpawnTimer").is_stopped(), "SpawnTimer tự dừng khi sinh đủ 20 quái của wave")

	var enemies = get_nodes_in_group("enemies")
	check(enemies.size() == 20, "Trên sân có đúng 20 quái")
	check(enemies[0].max_health == 100, "Quái Wave 1 có đúng 100 HP")

	# Tiêu diệt 19 con đầu tiên
	for i in range(19):
		enemies[i].take_damage(enemies[i].max_health)
	await frames(10)
	check(world.kills == 19 and not menu.active and not paused, "Chưa diệt hết 20 quái thì chưa mở nâng cấp")

	# Tiêu diệt con quái thứ 20 của Wave 1
	enemies[19].take_damage(enemies[19].max_health)
	await frames(25)
	check(paused and menu.active, "Tiêu diệt hết 20 quái của Wave 1 thì mở nâng cấp")
	check(world.kills == 20 and world.next_upgrade_kills == 20, "Mốc kills Wave 1 đạt 20")

	# Người chơi chọn nâng cấp
	menu.choose(0)
	await frames(5)
	check(not paused and not menu.active, "Chọn xong nâng cấp, game tự động tiếp tục")
	check(world.current_wave == 2, "Tự động bắt đầu Wave 2")
	check(world.wave_total_enemies == 24, "Wave 2 có 24 quái (20 + 20%)")
	check(world.enemy_max_health == 120, "Wave 2 quái có 120 HP (100 + 20)")
	check(world.next_upgrade_kills == 44, "Cột mốc kills của Wave 2 là 44 (20 + 24)")
	check(is_equal_approx(world.get_node("SpawnTimer").wait_time, 10.0 / 24.0), "Wave 2 spawn trong 10 giây (10 / 24 s mỗi quái)")

	# Kiểm tra giới hạn 300 quái trên map:
	# Giả lập spawn quái đến 300
	var dummy_enemies: Array[Node] = []
	for i in range(300):
		var e = world.spawn_enemy(Vector3(0, 0.1, -25))
		dummy_enemies.append(e)
	check(get_nodes_in_group("enemies").size() >= 300, "Map có 300 quái")
	var spawned_before = world.wave_spawned
	world._spawn_next()
	check(world.wave_spawned == spawned_before, "Khi map đạt 300 quái, spawner không sinh thêm")

	# Giết bớt 1 quái
	dummy_enemies[0].take_damage(dummy_enemies[0].max_health)
	await frames(5)
	check(get_nodes_in_group("enemies").size() < 300, "Map giảm xuống dưới 300 quái")
	world._spawn_next()
	check(world.wave_spawned == spawned_before + 1, "Khi map dưới 300 quái, spawner tiếp tục sinh quái")

	# Dọn dẹp quái test
	for e in dummy_enemies:
		if is_instance_valid(e):
			e.free()

	world.free()
	await frames(5)
	print("WAVE TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)
