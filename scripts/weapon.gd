extends Node3D
## Attached to the animated hand. +Z is the barrel direction.
signal fired(projectile: Node3D)

@export var gun_model: PackedScene
@export var gun_scale: float = 0.5
@export var gun_offset := Vector3(0, 0.07, 0.0725)
@export var gun_rotation_degrees := Vector3.ZERO
@export var muzzle_offset := Vector3(0, 0.1, 0.29)
@export_range(0.05, 2.0) var shot_interval: float = 1.0
@export var shot_range: float = 28.0
@export var damage: int = 100
@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
@export_range(1.0, 200.0, 1.0) var projectile_speed: float = 18.0

var shooter: CharacterBody3D
var muzzle: Marker3D
var aim_point := Vector3.ZERO
var aiming: bool = false
var target: CharacterBody3D
var _cooldown: float = 0.0
var _gun_visual: Node3D
var _recoil: Tween
var front_projectiles: int = 1
var burst_count: int = 1
var diagonal_count: int = 0
var diagonal_shots: bool:
	get: return diagonal_count > 0
var pierce_count: int = 0
var ricochet_count: int = 0
var critical_chance: float = 0.0
var critical_multiplier: float = 2.0

func _ready() -> void:
	if gun_model != null:
		var model := gun_model.instantiate() as Node3D
		if model != null:
			_gun_visual = model
			add_child(model)
			model.scale = Vector3.ONE * gun_scale
			model.position = gun_offset
			model.rotation_degrees = gun_rotation_degrees
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	add_child(muzzle)
	muzzle.position = muzzle_offset

func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if shooter != null and shooter.health > 0 and is_instance_valid(target) and not target.is_queued_for_deletion() and target.health > 0:
		aim_point = target.global_position
		try_fire()

func try_fire() -> bool:
	if _cooldown > 0.0001 or shooter == null or shooter.health <= 0:
		return false
	_cooldown = shot_interval
	var start := muzzle.global_position
	var direction := global_basis.z.normalized()
	if aiming:
		var toward := Vector3(aim_point.x, start.y, aim_point.z) - start
		if toward.length_squared() > 0.01:
			direction = toward.normalized()
	_fire_volley(direction)
	for i in range(1, burst_count):
		# Pausable timers preserve the burst while the upgrade menu is open.
		get_tree().create_timer(0.12 * i, false, true).timeout.connect(_fire_followup.bind(direction))
	if _gun_visual != null:
		if _recoil != null:
			_recoil.kill()
		_gun_visual.position = gun_offset - Vector3(0, 0, 0.015)
		_recoil = create_tween()
		_recoil.tween_property(_gun_visual, "position", gun_offset, minf(0.1, shot_interval))
	return true

func _fire_followup(direction: Vector3) -> void:
	if is_instance_valid(shooter) and shooter.health > 0:
		_fire_volley(direction)

func _fire_volley(direction: Vector3) -> void:
	var start := muzzle.global_position
	var side := Vector3(direction.z, 0, -direction.x).normalized()
	for i in range(front_projectiles):
		var offset := (float(i) - float(front_projectiles - 1) * 0.5) * 0.28
		var projectile := _spawn_projectile(start + side * offset, direction, false)
		if i == 0:
			fired.emit(projectile) # One sound per volley, even for multiple bullets.
	if diagonal_count > 0:
		for angle in [-25.0, 25.0]:
			var diag_dir := direction.rotated(Vector3.UP, deg_to_rad(angle))
			var diag_side := Vector3(diag_dir.z, 0, -diag_dir.x).normalized()
			for i in range(diagonal_count):
				var offset := (float(i) - float(diagonal_count - 1) * 0.5) * 0.28
				_spawn_projectile(start + diag_side * offset, diag_dir, true)

func _spawn_projectile(start: Vector3, direction: Vector3, is_diagonal: bool = false) -> Node3D:
	# Check from the body to the muzzle too: a barrel inside a wall cannot
	# shoot through it. The shooter is excluded from both raycasts.
	var origin := shooter.global_position + Vector3.UP * (start.y - shooter.global_position.y)
	var query := PhysicsRayQueryParameters3D.create(origin, start, 3, [shooter.get_rid()])
	query.hit_from_inside = true
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(query)
	var projectile := projectile_scene.instantiate() as Node3D
	projectile.direction = direction
	projectile.shooter = shooter
	var is_crit := randf() < critical_chance
	var mult := critical_multiplier if is_crit else 1.0
	var shot_dmg := float(damage) * mult
	if is_diagonal:
		shot_dmg *= 0.6
	projectile.damage = maxi(1, int(round(shot_dmg)))
	projectile.speed = projectile_speed
	projectile.max_distance = shot_range
	projectile.pierces_left = pierce_count
	projectile.bounces_left = ricochet_count
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = start
	projectile.look_at(start + direction, Vector3.UP, true)
	# Contact at an obstructed muzzle is immediate; distant targets are only
	# damaged later when the moving projectile actually reaches them.
	if not hit.is_empty():
		projectile.impact(hit)
	return projectile
