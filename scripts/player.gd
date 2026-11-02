extends CharacterBody3D
## Movement belongs to the body; replace only the children of ModelSlot.
signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 100
var health: int = 100

@export var speed: float = 5.5
@export var acceleration: float = 24.0
@export var turn_speed: float = 12.0
## Drag an imported .glb/.gltf from FileSystem into this field.
@export var character_model: PackedScene
@export var model_scale: float = 1.0
@export var model_y_offset: float = 0.0
@export var model_yaw_degrees: float = 0.0

@export_group("Locomotion Animation")
@export var idle_animation: StringName = &"idle"
@export var move_animation: StringName = &"walk"
@export_range(0.0, 1.0, 0.01) var animation_blend_time: float = 0.15
@export_range(0.1, 3.0, 0.05) var move_animation_speed: float = 1.0

var _animation_player: AnimationPlayer

@export_group("Weapon")
@export var weapon_scene: PackedScene = preload("res://scenes/weapon.tscn")
@export var hand_bone: StringName = &"arm-right"
@export var holding_animation: StringName = &"holding-right"
## In the character model's unscaled bone coordinates.
@export var hand_offset := Vector3(-0.22, 0, 0)
@export var hand_rotation_degrees := Vector3(0, -60, 0)

var _weapon: Node3D
var _armed_clips: Dictionary = {}
var current_target: CharacterBody3D

@onready var visual: Node3D = $Visual
@onready var model_slot: Node3D = $Visual/ModelSlot
@onready var placeholder: Node3D = $Visual/Placeholder

func _ready() -> void:
	health = max_health
	collision_layer = 4
	collision_mask = 3
	platform_floor_layers = 1
	if character_model != null:
		var model := character_model.instantiate()
		if model is Node3D:
			model_slot.add_child(model)
			model.scale = Vector3.ONE * model_scale
			model.position.y = model_y_offset
			model.rotation.y = deg_to_rad(model_yaw_degrees)
			placeholder.hide()
		else:
			model.free()
			push_warning("Character Model must have a Node3D root.")
	# Also support a model manually dragged under ModelSlot in the editor.
	if model_slot.get_child_count() > 0:
		placeholder.hide()
	_setup_animation()
	_setup_weapon()
	_update_animation(0.0)

func _setup_weapon() -> void:
	if weapon_scene == null:
		return
	var skeletons := model_slot.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_warning("Gun attachment requires a Skeleton3D.")
		return
	var skeleton := skeletons[0] as Skeleton3D
	if skeleton.find_bone(hand_bone) < 0:
		push_warning("Gun attachment bone not found: %s" % hand_bone)
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = "RightHandAttachment"
	attachment.bone_name = hand_bone
	skeleton.add_child(attachment)
	var grip := Node3D.new()
	grip.name = "GunGrip"
	attachment.add_child(grip)
	grip.position = hand_offset
	grip.rotation_degrees = hand_rotation_degrees
	_weapon = weapon_scene.instantiate() as Node3D
	_weapon.shooter = self
	grip.add_child(_weapon)
	_create_armed_clips()

func _create_armed_clips() -> void:
	if _animation_player == null or not _animation_player.has_animation(holding_animation):
		push_warning("Holding animation missing; gun will follow the swinging arm.")
		return
	# Copy just the right-arm tracks from the holding pose over locomotion.
	# Legs, torso and left arm retain their original idle/walk animation.
	var pose := _animation_player.get_animation(holding_animation)
	var library := AnimationLibrary.new()
	for clip_name in [idle_animation, move_animation]:
		if not _animation_player.has_animation(clip_name):
			continue
		var clip := _animation_player.get_animation(clip_name).duplicate(true) as Animation
		for track in range(clip.get_track_count() - 1, -1, -1):
			if clip.track_get_path(track).get_subname_count() > 0 and clip.track_get_path(track).get_subname(0) == hand_bone:
				clip.remove_track(track)
		for track in range(pose.get_track_count()):
			if pose.track_get_path(track).get_subname_count() > 0 and pose.track_get_path(track).get_subname(0) == hand_bone:
				pose.copy_track(track, clip)
		clip.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(clip_name, clip)
		_armed_clips[clip_name] = StringName("armed/" + str(clip_name))
	_animation_player.add_animation_library(&"armed", library)

func _setup_animation() -> void:
	var players := model_slot.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		if model_slot.get_child_count() > 0:
			push_warning("Character model has no AnimationPlayer; use an animated GLB.")
		return
	_animation_player = players[0] as AnimationPlayer
	# Local copies keep loop settings independent of other model instances.
	for library_name in _animation_player.get_animation_library_list():
		var library := _animation_player.get_animation_library(library_name).duplicate(true) as AnimationLibrary
		_animation_player.remove_animation_library(library_name)
		_animation_player.add_animation_library(library_name, library)
	for animation_name in [idle_animation, move_animation]:
		if _animation_player.has_animation(animation_name):
			_animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
		else:
			push_warning("Missing animation '%s'. Available: %s" % [animation_name, _animation_player.get_animation_list()])
	_update_animation(0.0)

func _update_animation(horizontal_speed: float) -> void:
	if _animation_player == null:
		return
	var moving := horizontal_speed > 0.1
	var next_animation := move_animation if moving else idle_animation
	if _weapon != null:
		next_animation = _armed_clips.get(next_animation, next_animation)
	if not _animation_player.has_animation(next_animation):
		return
	_animation_player.speed_scale = move_animation_speed if moving else 1.0
	# Do not restart the clip every physics frame.
	if _animation_player.current_animation != next_animation or not _animation_player.is_playing():
		_animation_player.play(next_animation, animation_blend_time)

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input.x, 0.0, input.y)
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if _weapon != null:
		_aim_nearest_enemy()
	elif direction.length_squared() > 0.001:
		# The placeholder faces +Z; Model Yaw Degrees corrects imported models.
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-turn_speed * delta))
	if global_position.y < -10.0:
		global_position = Vector3(0.0, 0.1, 0.0)
		velocity = Vector3.ZERO
		_update_animation(0.0)
	else:
		# Actual displacement stops the walk cycle when blocked by a wall.
		var real_velocity := get_real_velocity()
		_update_animation(Vector2(real_velocity.x, real_velocity.z).length())

func _aim_nearest_enemy() -> void:
	_weapon.aiming = false
	_weapon.target = null
	current_target = null
	var nearest_distance: float = _weapon.shot_range * _weapon.shot_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.health <= 0:
			continue
		var offset: Vector3 = enemy.global_position - global_position
		var distance := Vector2(offset.x, offset.z).length_squared()
		if distance < nearest_distance:
			nearest_distance = distance
			current_target = enemy
	if current_target == null:
		return
	_weapon.target = current_target
	_weapon.aim_point = current_target.global_position
	_weapon.aiming = true
	var toward := current_target.global_position - global_position
	if Vector2(toward.x, toward.z).length() > 0.01:
		visual.global_rotation.y = atan2(toward.x, toward.z)

func heal(amount: int) -> void:
	if health > 0:
		health = mini(max_health, health + maxi(0, amount))
		health_changed.emit(health, max_health)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - maxi(0, amount))
	health_changed.emit(health, max_health)
	if health == 0:
		velocity = Vector3.ZERO
		current_target = null
		if _weapon != null:
			_weapon.target = null
			_weapon.aiming = false
		if _animation_player != null and _animation_player.has_animation(&"die"):
			_animation_player.play(&"die", 0.1)
		died.emit()
