extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if ok: print("PASS: ", message)
	else:
		failed = true
		push_error(message)
func run() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	world.show_start_menu = false
	root.add_child(world)
	current_scene = world
	world.set_process(false)
	world.player.set_physics_process(false)
	world.get_node("SpawnTimer").stop()
	check(not world.has_node("ObstacleA") and not world.has_node("ObstacleB"), "Old obstacles removed")
	check(world.get_node("ArenaMap").get_child_count() > 200, "Forest and ruin map instances loaded")
	for gate in world.get_node("Spawners").get_children():
		check(gate.global_position.z == -27 and gate.get_node("SpawnPoint").global_position.z > -29, "Northern gate spawns inside arena")
	for dimensions in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(2560, 720)]:
		root.size = dimensions
		await process_frame
		for x in [-19.0, 0.0, 19.0]:
			for z in [-59.0, 0.0, 59.0]:
				world.camera_rig.position = world._clamp_camera(Vector3(x, 0, z) + world.camera_offset)
				var footprint: Rect2 = world._camera_footprint()
				footprint.position += Vector2(world.camera_rig.position.x, world.camera_rig.position.z)
				check(world.camera_map_bounds.grow(0.01).encloses(footprint), "Ground view stays in map %s at %s" % [dimensions, Vector2(x,z)])
				var screen = world.get_node("CameraRig/Camera3D").unproject_position(Vector3(x, 1, z))
				check(root.get_visible_rect().has_point(screen), "Player remains visible at edge")
	print("MAP TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)



