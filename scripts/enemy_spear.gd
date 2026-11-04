extends Node3D

@export var speed: float = 12.0
@export var max_distance: float = 35.0
@export var damage: int = 10

var direction := Vector3.FORWARD
var shooter: CharacterBody3D
var _travelled: float = 0.0
var _spent: bool = false

@onready var sweep: ShapeCast3D = $Sweep

func _ready() -> void:
	add_to_group("enemy_projectiles")
	if is_instance_valid(shooter):
		sweep.add_exception(shooter)

func _physics_process(delta: float) -> void:
	if _spent:
		return
	var step := minf(speed * delta, max_distance - _travelled)
	if step <= 0.0:
		queue_free()
		return
	_travelled += step
	sweep.target_position = global_basis.inverse() * (direction * step)
	sweep.force_shapecast_update()
	if sweep.is_colliding():
		for i in range(sweep.get_collision_count()):
			var collider = sweep.get_collider(i)
			if collider == shooter or (collider is Node and collider.is_in_group("enemies")):
				continue
			_spent = true
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
			queue_free()
			return
	global_position += direction * step
