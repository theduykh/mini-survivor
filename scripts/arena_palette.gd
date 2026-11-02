@tool
extends Node3D
## Muted scenery materials; keep the original imported assets untouched.
@export var foliage_tint := Color(0.42, 0.56, 0.34)
@export var stone_tint := Color(0.62, 0.57, 0.48)
@export var dirt_tint := Color(0.38, 0.30, 0.23)

func _ready() -> void:
	var materials: Dictionary = {}
	for prop in get_children():
		var tint := stone_tint
		if str(prop.name).begins_with("tree") or str(prop.name).begins_with("plant"):
			tint = foliage_tint
		elif str(prop.name).begins_with("patch"):
			tint = dirt_tint
		for mesh in prop.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
				if source == null:
					continue
				var key := str(source.get_instance_id()) + str(tint)
				if not materials.has(key):
					var material := source.duplicate() as StandardMaterial3D
					material.albedo_color *= tint
					if str(prop.name).begins_with("patch"):
						# The stock dirt palette is vivid orange; use a soft earth tone.
						material.albedo_texture = null
						material.albedo_color = dirt_tint
					material.roughness = 1.0
					material.metallic = 0.0
					materials[key] = material
				mesh.set_surface_override_material(surface, materials[key])
