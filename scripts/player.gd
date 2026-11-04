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
var _aim_timer: float = 0.0

var _player_materials: Array[StandardMaterial3D] = []
var _hit_tween: Tween
var _ring_material: StandardMaterial3D

@onready var visual: Node3D = $Visual
@onready var model_slot: Node3D = $Visual/ModelSlot
@onready var placeholder: Node3D = $Visual/Placeholder
@onready var selection_ring: MeshInstance3D = get_node_or_null("SelectionRing")
@onready var health_bar: MeshInstance3D = get_node_or_null("HealthBar")
@onready var health_label: Label3D = get_node_or_null("HealthLabel")

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
	_setup_health_bar()
	_init_hit_feedback()
	health_changed.connect(func(_c, _m): _update_health_display())
	_update_health_display()

func _setup_health_bar() -> void:
	if health_bar != null and health_bar.mesh != null and health_bar.mesh.material != null:
		health_bar.material_override = health_bar.mesh.material.duplicate()

func _update_health_display() -> void:
	if health_bar != null:
		var ratio := clampf(float(health) / float(maxi(1, max_health)), 0.0, 1.0)
		var mat := health_bar.material_override as ShaderMaterial
		if mat == null and health_bar.mesh != null:
			mat = health_bar.mesh.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("health_ratio", ratio)
		health_bar.visible = health > 0
	if health_label != null:
		health_label.text = "%d / %d" % [health, max_health]
		health_label.visible = health > 0

func _init_hit_feedback() -> void:
	_player_materials.clear()
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var mat = mesh.get_active_material(surface)
			if mat is StandardMaterial3D:
				var dup := mat.duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(surface, dup)
				_player_materials.append(dup)
	if selection_ring != null and selection_ring.mesh != null:
		var r_mat = selection_ring.get_active_material(0)
		if r_mat is StandardMaterial3D:
			_ring_material = r_mat.duplicate() as StandardMaterial3D
			selection_ring.set_surface_override_material(0, _ring_material)

func _play_hit_feedback() -> void:
	if _hit_tween != null:
		_hit_tween.kill()
	_hit_tween = create_tween().set_parallel(true)
	visual.position = Vector3(randf_range(-0.08, 0.08), 0.05, randf_range(-0.08, 0.08))
	_hit_tween.tween_property(visual, "position", Vector3.ZERO, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for mat in _player_materials:
		mat.emission_enabled = true
		mat.emission = Color(1.5, 0.2, 0.2)
		_hit_tween.tween_property(mat, "emission", Color.BLACK, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _ring_material != null:
		_ring_material.albedo_color = Color(1.0, 0.25, 0.2)
		_hit_tween.tween_property(_ring_material, "albedo_color", Color(0.4, 0.95, 0.82), 0.25)
	_hit_tween.chain().tween_callback(func():
		for mat in _player_materials:
			mat.emission_enabled = false
	)

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
	_aim_timer -= get_physics_process_delta_time()
	var shot_range_sq: float = _weapon.shot_range * _weapon.shot_range
	if is_instance_valid(current_target) and not current_target.is_queued_for_deletion() and current_target.health > 0:
		var current_diff := current_target.global_position - global_position
		if Vector2(current_diff.x, current_diff.z).length_squared() <= shot_range_sq:
			if _aim_timer > 0.0:
				_weapon.target = current_target
				_weapon.aim_point = current_target.global_position
				_weapon.aiming = true
				if Vector2(current_diff.x, current_diff.z).length() > 0.01:
					visual.global_rotation.y = atan2(current_diff.x, current_diff.z)
				return
	_aim_timer = 0.08
	_weapon.aiming = false
	_weapon.target = null
	current_target = null
	var nearest_distance: float = shot_range_sq
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
	_play_hit_feedback()
	if health == 0:
		velocity = Vector3.ZERO
		current_target = null
		if _weapon != null:
			_weapon.target = null
			_weapon.aiming = false
		if _animation_player != null and _animation_player.has_animation(&"die"):
			_animation_player.play(&"die", 0.1)
		died.emit()
