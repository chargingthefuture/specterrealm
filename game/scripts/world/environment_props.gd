extends Node3D

# Spawns atmospheric side props (dead trees, fog walls, distant silhouettes)
# alongside the main lane chunks to sell the zombie apocalypse setting.

@export var prop_density: float = 0.6   # 0-1 chance per side per chunk
@export var side_offset: float = 6.0    # how far left/right of the lanes

var _chunk_length: float = 20.0  # should match WorldSpawner.chunk_length


func spawn_side_props(chunk: Node3D, chunk_z: float) -> void:
	for side in [-1, 1]:
		if randf() < prop_density:
			_add_dead_tree(chunk, side, chunk_z)


func _add_dead_tree(chunk: Node3D, side: int, chunk_z: float) -> void:
	# Placeholder geometry — replace with actual mesh assets
	var trunk := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.1
	mesh.bottom_radius = 0.2
	mesh.height = randi_range(3, 6)
	trunk.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.15, 0.1)
	trunk.material_override = mat

	trunk.position = Vector3(
		side * (side_offset + randf_range(0.0, 2.0)),
		mesh.height * 0.5,
		-randf_range(2.0, _chunk_length - 2.0)
	)
	chunk.add_child(trunk)
