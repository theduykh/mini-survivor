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

	# 1. Kiểm tra thanh HP trên đầu player & hiệu ứng trúng đòn
	var p = world.player
	check(p.health_bar != null and p.health_label != null, "Player có thanh HP và nhãn HP trên đầu")
	check(p.health_bar.visible and p.health_label.visible, "Thanh HP và nhãn HP hiển thị khi đầy máu")
	check(p.health_label.text == "100 / 100", "Nhãn HP hiển thị đúng 100 / 100")

	p.take_damage(20)
	await frames(2)
	check(p.health == 80, "Player nhận sát thương còn 80 HP")
	check(p.health_label.text == "80 / 100", "Nhãn HP trên đầu cập nhật thành 80 / 100")
	var mat = p.health_bar.material_override as ShaderMaterial
	check(mat != null and is_equal_approx(mat.get_shader_parameter("health_ratio"), 0.8), "Thanh bar shader tỉ lệ 0.8")
	check(p._hit_tween != null and p._hit_tween.is_running(), "Kích hoạt hiệu ứng hit feedback khi trúng đòn")

	# 2. Kiểm tra quái cận chiến (Melee) - Dùng model character-human, cầm weapon-sword
	var melee = world.spawn_enemy(Vector3(0, 0.1, -10), "melee")
	await frames(5)
	check(melee.enemy_type == "melee", "Quái cận chiến có enemy_type là melee")
	check(melee.max_health == world.enemy_max_health, "Quái cận chiến có máu bằng enemy_max_health (100)")
	check(melee._character_instance != null, "Quái cận chiến có model instance")
	check("human" in melee._character_instance.scene_file_path.to_lower(), "Quái cận chiến dùng model character-human")
	check(melee._weapon_node != null and melee._weapon_mesh != null, "Quái cận chiến có gắn vũ khí")
	check("sword" in melee._weapon_mesh.name.to_lower(), "Quái cận chiến cầm weapon-sword")

	# 3. Kiểm tra quái đánh xa (Ranged) - Dùng model character-orc (màu mặc định), cầm weapon-spear
	var ranged = world.spawn_enemy(Vector3(0, 0.1, -10), "ranged")
	await frames(5)
	check(ranged.enemy_type == "ranged", "Quái đánh xa có enemy_type là ranged")
	check(ranged.max_health == int(round(world.enemy_max_health * 0.5)), "Quái đánh xa có máu ít hơn cận chiến 50% (50 HP)")
	check(ranged._character_instance != null, "Quái đánh xa có model instance")
	check("orc" in ranged._character_instance.scene_file_path.to_lower(), "Quái đánh xa dùng model character-orc")
	check(ranged._weapon_node != null and ranged._weapon_mesh != null, "Quái đánh xa có gắn vũ khí")
	check("spear" in ranged._weapon_mesh.name.to_lower(), "Quái đánh xa cầm weapon-spear")

	# 4. Quái đánh xa phóng spear tấn công player & kiểm tra mũi giáo không bị ngược
	ranged.global_position = world.player.global_position + Vector3(0, 0, -8.0)
	var player_hp_before = world.player.health
	await frames(30)
	var spears = get_nodes_in_group("enemy_projectiles")
	check(spears.size() > 0, "Quái đánh xa phóng spear tấn công")
	if spears.size() > 0:
		var spear = spears[0]
		var model = spear.get_node("Model")
		var tip_local = model.transform * Vector3(0, 0.6, 0)
		var base_local = model.transform * Vector3.ZERO
		check(tip_local.z < base_local.z, "Mũi giáo nhọn ở phía trước (-Z) so với cán giáo (+Z), không bị ngược")

	# Chờ cây spear bay trúng player
	await frames(60)
	check(world.player.health < player_hp_before, "Spear gây sát thương cho player")

	# 5. Kiểm tra phân bổ wave: 85% cận chiến, 15% đánh xa
	world.wave_total_enemies = 20
	world._prepare_wave_spawn_types()
	var melee_count := 0
	var ranged_count := 0
	for t in world._wave_spawn_types:
		if t == "melee": melee_count += 1
		elif t == "ranged": ranged_count += 1
	check(melee_count == 17 and ranged_count == 3, "Wave 20 quái: 17 cận chiến (85%), 3 đánh xa (15%)")

	world.wave_total_enemies = 100
	world._prepare_wave_spawn_types()
	melee_count = 0
	ranged_count = 0
	for t in world._wave_spawn_types:
		if t == "melee": melee_count += 1
		elif t == "ranged": ranged_count += 1
	check(melee_count == 85 and ranged_count == 15, "Wave 100 quái: 85 cận chiến (85%), 15 đánh xa (15%)")

	world.free()
	await frames(5)
	print("ENEMY TYPES & PLAYER HEALTH TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)
