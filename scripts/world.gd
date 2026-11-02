extends Node3D

@export var camera_offset := Vector3(0, 0, -8)
@export var camera_map_bounds := Rect2(-24, -36, 48, 72)
@export var camera_view_size: float = 26.0
@export_range(0.05, 0.8, 0.01) var controller_deadzone: float = 0.2
@export var spawn_interval: float = 1.0
@export var show_start_menu: bool = true
static var skip_start_once: bool = false
const Upgrades = preload("res://scripts/upgrades.gd")
var upgrade_levels: Dictionary = {}
var next_upgrade_kills: int = 50
var starting_upgrade: bool = false
var enemy_max_health: int = 100
var upgrades_chosen: int = 0
var _upgrade_queued: bool = false
var _next_gate: int = 0

var running: bool = true
var kills: int = 0
var elapsed: float = 0.0
var _navigation := AStarGrid2D.new()

@onready var player: CharacterBody3D = $Player
@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("move_forward", [KEY_W, KEY_UP])
	_bind_keys("move_back", [KEY_S, KEY_DOWN])
	_bind_keys("reset_player", [KEY_R])
	_bind_keys("toggle_audio", [KEY_M])
	_bind_joy_button("toggle_audio", JOY_BUTTON_BACK)
	_bind_controller()
	_setup_navigation()
	for gate in $Spawners.get_children():
		gate.arena = self
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.timeout.connect(_spawn_next)
	$UpgradeMenu.chosen.connect(_choose_upgrade)
	player.died.connect(_game_over)
	if player._weapon != null:
		player._weapon.fired.connect($Audio.play_shot)
	camera_rig.position = _clamp_camera(player.position + camera_offset)
	_update_hud()
	var menu = preload("res://scripts/game_menu.gd").new()
	menu.name = "GameMenu"
	add_child(menu)
	if show_start_menu and not skip_start_once:
		menu.open("start")
	elif show_start_menu:
		begin_run()
	skip_start_once = false

func begin_run() -> void:
	starting_upgrade = true
	_show_upgrade()

func _process(delta: float) -> void:
	var target := _clamp_camera(Vector3(player.position.x, 0, player.position.z) + camera_offset)
	camera_rig.global_position = _clamp_camera(camera_rig.global_position.lerp(target, 1.0 - exp(-8.0 * delta)))
	if running:
		elapsed += delta
	_update_hud()

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset_player"):
		restart_game()
		return
	if Input.is_action_just_pressed("toggle_audio"):
		$Audio.toggle_mute()

func restart_game(to_start: bool = false) -> void:
	skip_start_once = not to_start
	get_tree().paused = false
	get_tree().reload_current_scene()

func spawn_enemy(at: Vector3) -> CharacterBody3D:
	var enemy := preload("res://scenes/enemy.tscn").instantiate() as CharacterBody3D
	enemy.max_health = enemy_max_health
	enemy.player = player
	enemy.arena = self
	# Position before entering the physics world: adding at the origin first
	# can overlap the player and make it ride the teleported body as a platform.
	enemy.position = $Enemies.to_local(at)
	$Enemies.add_child(enemy)
	enemy.died.connect(_enemy_killed)
	return enemy

func _spawn_next() -> void:
	if not running or get_tree().paused:
		return
	var gates := $Spawners.get_children()
	gates[_next_gate].spawn_one()
	_next_gate = (_next_gate + 1) % gates.size()

func _enemy_killed() -> void:
	kills += 1
	$Audio.play_death()
	player.heal(int(upgrade_levels.get("vampire", 0)) * 2)
	_queue_upgrade()

func _queue_upgrade() -> void:
	if running and kills >= next_upgrade_kills and not _upgrade_queued and not $UpgradeMenu.active:
		_upgrade_queued = true
		_show_upgrade.call_deferred()

func _show_upgrade() -> void:
	_upgrade_queued = false
	if not is_inside_tree(): return
	if not running or player.health <= 0 or $UpgradeMenu.active:
		return
	_update_hud()
	$UpgradeMenu.show_choices(Upgrades.offers(upgrade_levels), 0 if starting_upgrade else next_upgrade_kills, upgrade_levels)
	get_tree().paused = true
	if has_node("GameMenu"):
		$GameMenu.upgrade_opened()

func _choose_upgrade(id: String) -> void:
	# Only accept an offered choice while the milestone menu has paused play.
	if not get_tree().paused or not running:
		return
	var offered := false
	for entry in $UpgradeMenu.offers:
		if entry.id == id: offered = true
	if not offered: return
	upgrade_levels[id] = int(upgrade_levels.get(id, 0)) + 1
	Upgrades.apply(id, player)
	upgrades_chosen += 1
	if starting_upgrade:
		starting_upgrade = false
	else:
		next_upgrade_kills += 50
	enemy_max_health += 20
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.increase_max_health(20)
	_update_spawn_delay()
	get_tree().paused = false
	_update_hud()
	_queue_upgrade() # Handles several crossed milestones without losing choices.

func _update_spawn_delay() -> void:
	# A positive floor avoids zero/negative timer durations in very long runs.
	var delay := maxf(0.05, spawn_interval - 0.05 * upgrades_chosen)
	var timer: Timer = $SpawnTimer
	if not timer.is_stopped():
		# Apply immediately without extending the already pending spawn.
		timer.start(minf(timer.time_left, delay))
	timer.wait_time = delay

func _game_over() -> void:
	running = false
	$Audio.game_over()
	$SpawnTimer.stop()

func _update_hud() -> void:
	var controls := "Left stick / D-pad: move | Y: restart" if not Input.get_connected_joypads().is_empty() else "WASD: move | R: restart"
	var status := ("AUTO AIM + FIRE | " if running else "GAME OVER | ") + controls
	status += " | M/Back: sound " + ("OFF" if $Audio.muted else "ON")
	status += " | Esc/Start: pause"
	$HUD/Panel/Margin/Label.text = "MINI SURVIVOR   HP %d / %d\nKills: %d / %d   Upgrades: %d   Orcs: %d   Time: %ds\n%s" % [player.health, player.max_health, kills, next_upgrade_kills, upgrades_chosen, get_tree().get_nodes_in_group("enemies").size(), int(elapsed), status]

func _setup_navigation() -> void:
	# The combat floor is open; scenery sits beyond the boundary.
	_navigation.region = Rect2i(-19, -29, 39, 59)
	_navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_navigation.update()

func get_chase_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := _walkable_cell(from)
	var finish := _walkable_cell(to)
	var path := PackedVector3Array()
	var cells := _navigation.get_id_path(start, finish)
	for i in range(1, cells.size()):
		path.append(Vector3(cells[i].x, 0, cells[i].y))
	var exact := Vector2i(roundi(to.x), roundi(to.z))
	if finish == exact:
		path.append(Vector3(to.x, 0, to.z))
	return path

func _walkable_cell(point: Vector3) -> Vector2i:
	var cell := Vector2i(clampi(roundi(point.x), -19, 19), clampi(roundi(point.z), -29, 29))
	if not _navigation.is_point_solid(cell):
		return cell
	for radius in range(1, 6):
		var closest := cell
		var best_distance := INF
		for x in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, z)
				if _navigation.is_in_boundsv(candidate) and not _navigation.is_point_solid(candidate):
					var distance := Vector2(candidate.x - point.x, candidate.y - point.z).length_squared()
					if distance < best_distance:
						best_distance = distance
						closest = candidate
		if closest != cell:
			return closest
	return cell

func _bind_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _bind_controller() -> void:
	var bindings := [
		["move_left", JOY_AXIS_LEFT_X, -1.0, JOY_BUTTON_DPAD_LEFT],
		["move_right", JOY_AXIS_LEFT_X, 1.0, JOY_BUTTON_DPAD_RIGHT],
		["move_forward", JOY_AXIS_LEFT_Y, -1.0, JOY_BUTTON_DPAD_UP],
		["move_back", JOY_AXIS_LEFT_Y, 1.0, JOY_BUTTON_DPAD_DOWN],
	]
	for binding in bindings:
		InputMap.action_set_deadzone(binding[0], controller_deadzone)
		var axis := InputEventJoypadMotion.new()
		axis.device = -1 # Accept any connected controller, including hot-plugged ones.
		axis.axis = binding[1]
		axis.axis_value = binding[2]
		if not InputMap.action_has_event(binding[0], axis):
			InputMap.action_add_event(binding[0], axis)
		_bind_joy_button(binding[0], binding[3])
	_bind_joy_button("reset_player", JOY_BUTTON_Y)

func _bind_joy_button(action: StringName, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _camera_footprint() -> Rect2:
	var camera := $CameraRig/Camera3D as Camera3D
	var viewport_size := get_viewport().get_visible_rect().size
	var ground := Plane(Vector3.UP, 0.0)
	var footprint := Rect2()
	var first := true
	for corner in [Vector2.ZERO, Vector2(viewport_size.x, 0), viewport_size, Vector2(0, viewport_size.y)]:
		var hit = ground.intersects_ray(camera.project_ray_origin(corner), camera.project_ray_normal(corner))
		if hit == null: continue
		var offset: Vector3 = hit - camera_rig.global_position
		var point := Vector2(offset.x, offset.z)
		if first:
			footprint = Rect2(point, Vector2.ZERO)
			first = false
		else:
			footprint = footprint.expand(point)
	return footprint

func _clamp_camera(desired: Vector3) -> Vector3:
	var camera := $CameraRig/Camera3D as Camera3D
	camera.size = camera_view_size
	var footprint := _camera_footprint()
	# Fit unusually wide/tall windows before constraining the full ground view.
	var fit := minf(1.0, minf(camera_map_bounds.size.x / maxf(footprint.size.x, 0.001), camera_map_bounds.size.y / maxf(footprint.size.y, 0.001)))
	if fit < 1.0:
		camera.size *= fit
		footprint = _camera_footprint()
	var low := camera_map_bounds.position - footprint.position
	var high := camera_map_bounds.end - footprint.end
	return Vector3(clampf(desired.x, low.x, maxf(low.x, high.x)), 0, clampf(desired.z, low.y, maxf(low.y, high.y)))


