extends Node3D
## +Z is forward. Sweep the whole frame's travel so fast rounds hit walls.
signal impacted(hit: Dictionary)

@export var speed: float = 18.0
@export var max_distance: float = 28.0
@export var damage: int = 10

var direction := Vector3.FORWARD
var shooter: CharacterBody3D
var _travelled: float = 0.0
var _spent: bool = false
var pierces_left: int = 0
var bounces_left: int = 0
var _hit_bodies: Array[RID] = []

@onready var sweep: ShapeCast3D = $Sweep

func _ready() -> void:
	add_to_group("projectiles")
	if is_instance_valid(shooter):
		sweep.add_exception(shooter)

func _physics_process(delta: float) -> void:
	if _spent:
		return
	var step := minf(speed * delta, max_distance - _travelled)
	if step <= 0.0:
		queue_free()
		return
	# Consume the remaining step after each pierce/bounce, preserving range.
	for _collision in range(8):
		if _spent or step <= 0.0001:
			break
		sweep.target_position = global_basis.inverse() * (direction * step)
		sweep.force_shapecast_update()
		if not sweep.is_colliding():
			global_position += direction * step
			_travelled += step
			break
		var hit := {"collider": sweep.get_collider(0), "position": sweep.get_collision_point(0), "normal": sweep.get_collision_normal(0)}
		var travel := step * sweep.get_closest_collision_safe_fraction()
		global_position += direction * travel
		_travelled += travel
		step -= travel
		impact(hit)
	if _travelled >= max_distance - 0.0001:
		queue_free()

func impact(hit: Dictionary) -> void:
	if _spent:
		return
	var body: Object = hit.get("collider")
	if is_instance_valid(body) and body.has_method("take_damage"):
		var body_rid: RID = body.get_rid()
		if body_rid in _hit_bodies:
			return
		_hit_bodies.append(body_rid)
		sweep.add_exception_rid(body_rid)
		body.take_damage(damage)
	impacted.emit(hit)
	if is_instance_valid(body) and body.has_method("take_damage"):
		if bounces_left > 0 and _ricochet():
			bounces_left -= 1
			return
		if pierces_left > 0:
			pierces_left -= 1
			return
	_spent = true
	queue_free()

func _ricochet() -> bool:
	var nearest: Node3D
	var best_distance := 8.0 * 8.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.health <= 0 or enemy.get_rid() in _hit_bodies:
			continue
		var point := Vector3(enemy.global_position.x, global_position.y, enemy.global_position.z)
		var distance := global_position.distance_squared_to(point)
		if distance >= best_distance or distance < 0.0001:
			continue
		var exclusions: Array[RID] = _hit_bodies.duplicate()
		if is_instance_valid(shooter): exclusions.append(shooter.get_rid())
		var query := PhysicsRayQueryParameters3D.create(global_position, point, 3, exclusions)
		var obstruction := get_world_3d().direct_space_state.intersect_ray(query)
		if obstruction.is_empty() or obstruction.collider == enemy:
			best_distance = distance
			nearest = enemy
	if nearest == null:
		return false
	direction = (Vector3(nearest.global_position.x, global_position.y, nearest.global_position.z) - global_position).normalized()
	look_at(global_position + direction, Vector3.UP, true)
	return true
