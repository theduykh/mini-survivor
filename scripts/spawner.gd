extends Node3D

var arena: Node3D
var spawned: int = 0

func spawn_one() -> void:
	if arena == null or not arena.running:
		return
	spawned += 1
	var random_x := randf_range(-18.0, 18.0)
	var spawn_pos := Vector3(random_x, 0.1, -27.0)
	arena.spawn_enemy(spawn_pos)
