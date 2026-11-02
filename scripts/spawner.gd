extends Node3D

var arena: Node3D
var spawned: int = 0

func _ready() -> void:
	$Label.text = "ORC GATE"

func spawn_one() -> void:
	if arena == null or not arena.running:
		return
	spawned += 1
	var spread := global_basis.x * sin(float(spawned) * 2.4) * 0.35
	arena.spawn_enemy($SpawnPoint.global_position + spread)
