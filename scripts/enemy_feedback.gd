extends Node

@export var flash_duration: float = 0.18
@export var dissolve_duration: float = 0.8
var dissolve_progress: float = 0.0
var _materials: Array[ShaderMaterial] = []
var _hit_tween: Tween
var _dying: bool = false
@onready var model: Node3D = get_parent().get_node("Model")

func _ready() -> void:
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			var material := ShaderMaterial.new()
			material.shader = preload("res://shaders/enemy_damage.gdshader")
			material.set_shader_parameter("hit_flash", 0.0)
			material.set_shader_parameter("dissolve", 0.0)
			if source != null:
				material.set_shader_parameter("albedo_texture", source.albedo_texture)
				material.set_shader_parameter("base_color", source.albedo_color)
			mesh.set_surface_override_material(surface, material)
			_materials.append(material)

func hit() -> void:
	if _dying:
		return
	if _hit_tween != null:
		_hit_tween.kill()
	_set_flash(1.0)
	model.rotation.x = -0.12
	_hit_tween = create_tween().set_parallel(true)
	_hit_tween.tween_method(_set_flash, 1.0, 0.0, flash_duration)
	_hit_tween.tween_property(model, "rotation:x", 0.0, flash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func dissolve_and_remove() -> void:
	if _dying:
		return
	_dying = true
	var tween := create_tween()
	tween.tween_interval(0.15)
	tween.tween_method(_set_dissolve, 0.0, 1.0, dissolve_duration)
	tween.tween_callback(get_parent().queue_free)

func _set_flash(value: float) -> void:
	for material in _materials:
		material.set_shader_parameter("hit_flash", value)

func _set_dissolve(value: float) -> void:
	dissolve_progress = value
	for material in _materials:
		material.set_shader_parameter("dissolve", value)
