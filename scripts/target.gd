extends StaticBody3D

@export var max_health: int = 3
var health: int
var _material: StandardMaterial3D
var _flash: Tween

func _ready() -> void:
	health = max_health
	_material = $Mesh.get_active_material(0).duplicate() as StandardMaterial3D
	$Mesh.material_override = _material
	_update_label()

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	_update_label()
	if health == 0:
		queue_free()
		return
	if _flash != null:
		_flash.kill()
	_material.albedo_color = Color.WHITE
	_flash = create_tween()
	_flash.tween_property(_material, "albedo_color", Color(0.95, 0.4, 0.12), 0.15)

func _update_label() -> void:
	$Label.text = "TARGET  %d / %d" % [health, max_health]
