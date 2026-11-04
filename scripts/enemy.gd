extends CharacterBody3D
signal died

@export var enemy_type: String = "melee"
@export var max_health: int = 100
@export var damage: int = 10
@export var speed: float = 2.2
@export var attack_interval: float = 1.0
@export var attack_range: float = 1.35
@export var attack_windup: float = 0.25

@export var melee_model_scene: PackedScene = preload("res://assets/models/kenney/mini-dungeon/Models/GLB format/character-human.glb")
@export var ranged_model_scene: PackedScene = preload("res://assets/models/kenney/mini-dungeon/Models/GLB format/character-orc.glb")

var health: int
var player: CharacterBody3D
var arena: Node3D
var _dead: bool = false
var _attack_cooldown: float = 0.0
var _windup: float = -1.0
var _attack_lock: float = 0.0
var _animation: AnimationPlayer
var _character_instance: Node3D
var _weapon_grip: Node3D
var _weapon_node: Node3D
var _weapon_mesh: MeshInstance3D

func _ready() -> void:
	health = max_health
	$Health.hide()
	add_to_group("enemies")
	_setup_character_model()
	_update_label()

func set_enemy_type(type: String, base_max_hp: int = -1) -> void:
	enemy_type = type
	if base_max_hp > 0:
		if enemy_type == "ranged":
			max_health = int(round(base_max_hp * 0.5))
		else:
			max_health = base_max_hp
		health = max_health
	if is_node_ready():
		_setup_character_model()

func _setup_character_model() -> void:
	if _character_instance != null and is_instance_valid(_character_instance):
		_character_instance.queue_free()
		_character_instance = null
		_weapon_grip = null
		_weapon_node = null
		_weapon_mesh = null

	for child in $Model.get_children():
		child.queue_free()

	if enemy_type == "ranged":
		attack_range = 13.0
		attack_interval = 1.6
		$Health.modulate = Color(1.0, 0.45, 0.45, 1.0)
		_character_instance = ranged_model_scene.instantiate() as Node3D
	else:
		attack_range = 1.35
		attack_interval = 1.0
		$Health.modulate = Color(0.9, 0.9, 0.9, 1.0)
		_character_instance = melee_model_scene.instantiate() as Node3D

	$Model.add_child(_character_instance)

	for mesh in $Model.find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var anim_players := $Model.find_children("*", "AnimationPlayer", true, false)
	if not anim_players.is_empty():
		_animation = anim_players[0] as AnimationPlayer
		for name in _animation.get_animation_library_list():
			var library := _animation.get_animation_library(name).duplicate(true) as AnimationLibrary
			_animation.remove_animation_library(name)
			_animation.add_animation_library(name, library)
		for clip in [&"idle", &"walk"]:
			if _animation.has_animation(clip):
				_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR

	var skeletons := $Model.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		var skeleton := skeletons[0] as Skeleton3D
		var attachment := BoneAttachment3D.new()
		attachment.name = "RightHandAttachment"
		attachment.bone_name = &"arm-right"
		skeleton.add_child(attachment)
		var grip := Node3D.new()
		grip.name = "WeaponGrip"
		grip.position = Vector3(-0.2, 0, 0)
		attachment.add_child(grip)
		_weapon_grip = grip

		if enemy_type == "ranged":
			var spear_scene := load("res://assets/models/kenney/mini-dungeon/Models/GLB format/weapon-spear.glb") as PackedScene
			if spear_scene != null:
				_weapon_node = spear_scene.instantiate() as Node3D
				_weapon_node.position = Vector3(0, -0.22, 0)
				_weapon_node.rotation_degrees = Vector3(-45, 0, 0)
				_weapon_grip.add_child(_weapon_node)
				var meshes := _weapon_node.find_children("*", "MeshInstance3D", true, false)
				if not meshes.is_empty():
					_weapon_mesh = meshes[0] as MeshInstance3D
					_weapon_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			var sword_scene := load("res://assets/models/kenney/mini-dungeon/Models/GLB format/weapon-sword.glb") as PackedScene
			if sword_scene != null:
				_weapon_node = sword_scene.instantiate() as Node3D
				_weapon_node.rotation_degrees = Vector3(-35, 0, 0)
				_weapon_grip.add_child(_weapon_node)
				var meshes := _weapon_node.find_children("*", "MeshInstance3D", true, false)
				if not meshes.is_empty():
					_weapon_mesh = meshes[0] as MeshInstance3D
					_weapon_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	$Feedback.setup_materials()
	if _weapon_mesh != null:
		$Feedback.register_weapon_mesh(_weapon_mesh)

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
			if enemy_type == "melee":
				if distance <= attack_range + 0.2 and _can_reach_player():
					player.take_damage(damage)
			elif enemy_type == "ranged":
				_throw_spear()
	var direction := Vector3.ZERO
	if distance <= attack_range and _attack_cooldown <= 0.0001 and _can_reach_player():
		_attack_cooldown = attack_interval
		_windup = attack_windup
		_attack_lock = 0.55
		_play(&"attack-melee-right", true)
	elif _attack_lock <= 0.0:
		if enemy_type == "melee" or distance > attack_range * 0.8:
			direction = _chase_direction(delta)
			_play(&"walk")
		else:
			_play(&"idle")
	if distance <= attack_range and _attack_lock <= 0.0:
		if enemy_type == "melee" or distance <= attack_range * 0.8:
			_play(&"idle")
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _throw_spear() -> void:
	if not is_instance_valid(player) or player.health <= 0:
		return
	var spear_scene := preload("res://scenes/enemy_spear.tscn")
	var spear := spear_scene.instantiate() as Node3D
	spear.shooter = self
	spear.damage = damage
	var spawn_pos := global_position + Vector3.UP * 1.2
	if is_instance_valid(_weapon_grip):
		spawn_pos = _weapon_grip.global_position
	spear.position = spawn_pos
	var aim_target := player.global_position + Vector3.UP * 0.8
	var dir := (aim_target - spawn_pos).normalized()
	if dir.length_squared() < 0.001:
		dir = -global_transform.basis.z
	spear.direction = dir
	if is_instance_valid(arena):
		arena.add_child(spear)
	else:
		get_parent().add_child(spear)
	spear.look_at(spawn_pos + dir, Vector3.UP)

	if is_instance_valid(_weapon_mesh):
		_weapon_mesh.visible = false
		var tw := create_tween()
		tw.tween_interval(maxf(0.1, attack_interval - 0.4))
		tw.tween_callback(func():
			if is_instance_valid(_weapon_mesh):
				_weapon_mesh.visible = true
		)

func _chase_direction(_delta: float) -> Vector3:
	var toward := player.global_position - global_position
	toward.y = 0.0
	var len_sq := toward.length_squared()
	if len_sq > 0.01:
		return toward / sqrt(len_sq)
	return Vector3.ZERO

func _can_reach_player() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, player.global_position + Vector3.UP, 1, [get_rid(), player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func increase_max_health(amount: int) -> void:
	if _dead: return
	var actual_amount := amount
	if enemy_type == "ranged":
		actual_amount = int(round(amount * 0.5))
	max_health += actual_amount
	health += actual_amount
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
	if _animation != null and _animation.has_animation(clip) and (restart or _animation.current_animation != clip):
		_animation.play(clip, 0.12)

func _update_label() -> void:
	var type_label := "HUMAN" if enemy_type == "melee" else "ORC (RANGED)"
	$Health.text = "%s  %d / %d" % [type_label, health, max_health]
