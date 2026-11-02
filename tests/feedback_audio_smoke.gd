extends SceneTree
var failed := false

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

func run() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	world.show_start_menu = false
	root.add_child(world)
	current_scene = world
	world.get_node("SpawnTimer").stop()
	world.player._weapon.set_physics_process(false)
	var audio = world.get_node("Audio")
	await frames(3)
	check(audio.music.playing and audio.music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Music starts and loops")
	check(audio.music.stream.get_length() > 27.0, "Music contains the full sixteen-bar arrangement")
	var orc = world.spawn_enemy(Vector3(0, 0.1, -4))
	var other = world.spawn_enemy(Vector3(4, 0.1, -4))
	orc.set_physics_process(false)
	other.set_physics_process(false)
	await frames(3)
	world.player._weapon.try_fire()
	check(audio.shot.playing, "Firing triggers blaster sound")
	for projectile in get_nodes_in_group("projectiles"):
		projectile.free()
	orc.take_damage(10)
	var feedback = orc.get_node("Feedback")
	check(orc.get_node("Model").rotation.x < 0 and feedback._materials[0].get_shader_parameter("hit_flash") > 0, "Hit triggers brief body recoil and flash")
	check(other.get_node("Feedback")._materials[0].get_shader_parameter("hit_flash") == 0, "Hit effects do not alter other orcs")
	await frames(16)
	check(absf(orc.get_node("Model").rotation.x) < 0.001 and feedback._materials[0].get_shader_parameter("hit_flash") < 0.001, "Hit feedback returns to normal")
	orc.take_damage(90)
	check(audio.death.playing and world.kills == 1, "Death triggers sound and one kill")
	await frames(24)
	check(is_instance_valid(orc) and feedback.dissolve_progress > 0.0 and feedback.dissolve_progress < 1.0, "Corpse visibly dissolves before removal")
	check(not orc.is_in_group("enemies") and orc.collision_layer == 0, "Dissolving corpse cannot block shots or be retargeted")
	await frames(40)
	check(not is_instance_valid(orc), "Dissolved corpse is cleaned up")
	audio.toggle_mute()
	check(audio.music.stream_paused and not audio.shot.playing and not audio.death.playing, "Mute silences music and effects")
	audio.play_death()
	check(not audio.death.playing, "Muted sounds cannot retrigger")
	audio.toggle_mute()
	check(not audio.music.stream_paused, "Unmute resumes music")
	world.player.take_damage(1000)
	await frames(45)
	check(audio.music.volume_db < audio.music_volume_db - 9.0, "Game over fades music down")
	world.free()
	await frames(10)
	print("FEEDBACK/AUDIO TEST: ", "FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)




