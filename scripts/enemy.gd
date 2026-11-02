extends CharacterBody3D
signal died

@export var max_health: int = 100
@export var damage: int = 10
@export var speed: float = 2.2
@export var attack_interval: float = 1.0
@export var attack_range: float = 1.35
@export var attack_windup: float = 0.25

var health: int
var player: CharacterBody3D
var arena: Node3D
var _dead: bool = false
var _attack_cooldown: float = 0.0
var _windup: float = -1.0
var _attack_lock: float = 0.0
var _path_timer: float = 0.0
var _path := PackedVector3Array()
var _waypoint: int = 0
var _animation: AnimationPlayer

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_animation = $Model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for name in _animation.get_animation_library_list():
		var library := _animation.get_animation_library(name).duplicate(true) as AnimationLibrary
		_animation.remove_animation_library(name)
		_animation.add_animation_library(name, library)
	for clip in [&"idle", &"walk"]:
		_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_play(&"walk")
	_update_label()

func _physics_process(delta: float) -> void:
	if _dead or not is_instance_valid(player) or player.health <= 0:
		if not _dead:
			_play(&"idle")
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_attack_lock = maxf(0.0, _attack_lock - delta)
	var toward := player.global_position - global_position
	toward.y = 0.0
	var distance := toward.length()
	if toward.length_squared() > 0.001:
		$Model.rotation.y = atan2(toward.x, toward.z)
	if _windup >= 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_windup = -1.0
			if distance <= attack_range + 0.2 and _can_reach_player():
				player.take_damage(damage)
	var direction := Vector3.ZERO
	if distance <= attack_range and _can_reach_player():
		if _attack_cooldown <= 0.0001:
			_attack_cooldown = attack_interval
			_windup = attack_windup
			_attack_lock = 0.55
			_play(&"attack-melee-right", true)
	elif _attack_lock <= 0.0:
		direction = _chase_direction(delta)
		_play(&"walk")
	if distance <= attack_range and _attack_lock <= 0.0:
		_play(&"idle")
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _chase_direction(delta: float) -> Vector3:
	_path_timer -= delta
	if _path_timer <= 0.0:
		_path_timer = 0.4
		_path = arena.get_chase_path(global_position, player.global_position)
		_waypoint = 0
	while _waypoint < _path.size():
		var offset := _path[_waypoint] - global_position
		offset.y = 0.0
		if offset.length() > 0.18:
			return offset.normalized()
		_waypoint += 1
	return Vector3.ZERO

func _can_reach_player() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, player.global_position + Vector3.UP, 1, [get_rid(), player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func increase_max_health(amount: int) -> void:
	if _dead: return
	max_health += amount
	health += amount # Preserve damage already taken; never revive dead enemies.
	_update_label()

func take_damage(amount: int) -> void:
	if _dead or amount <= 0:
		return
	$Feedback.hit()
	health = maxi(0, health - maxi(0, amount))
	_update_label()
	if health > 0:
		return
	_dead = true
	remove_from_group("enemies")
	add_to_group("corpses")
	velocity = Vector3.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	$Health.hide()
	_play(&"die", true)
	died.emit()
	$Feedback.dissolve_and_remove()

func _play(clip: StringName, restart: bool = false) -> void:
	if _animation.has_animation(clip) and (restart or _animation.current_animation != clip):
		_animation.play(clip, 0.12)

func _update_label() -> void:
	$Health.text = "ORC  %d / %d" % [health, max_health]
