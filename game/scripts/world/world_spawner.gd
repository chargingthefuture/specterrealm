extends Node3D

# Procedurally spawns and recycles ground chunks and obstacles ahead of the player.
# Chunks scroll toward the player rather than moving the player forward,
# keeping the player at a fixed Z and simplifying collision/camera logic.

# --- Exported settings ---
@export var chunk_length: float = 20.0
@export var visible_chunks: int = 6          # how many chunks ahead to keep loaded
@export var lane_width: float = 3.0
@export var initial_run_speed: float = 8.0
@export var speed_increment: float = 0.5     # added every speed_interval seconds
@export var speed_interval: float = 10.0
@export var max_run_speed: float = 22.0

@export var enemy_scene: PackedScene
@export var obstacle_scene: PackedScene

# --- State ---
var run_speed: float
var _chunks: Array[Node3D] = []
var _spawn_z: float = 0.0
var _speed_timer: float = 0.0
var _distance_traveled: float = 0.0

# --- Signals ---
signal speed_changed(new_speed: float)
signal distance_updated(distance: float)

# Lane X positions
const LANES := [-3.0, 0.0, 3.0]


func _ready() -> void:
	run_speed = initial_run_speed
	# Pre-fill the view with chunks
	for i in visible_chunks:
		_spawn_chunk()


func _process(delta: float) -> void:
	_scroll_world(delta)
	_recycle_chunks()
	_tick_speed(delta)


func _scroll_world(delta: float) -> void:
	var move := run_speed * delta
	_distance_traveled += move
	distance_updated.emit(_distance_traveled)

	for chunk in _chunks:
		chunk.position.z += move


func _recycle_chunks() -> void:
	# Remove chunks that have passed behind the player (positive Z = behind)
	for chunk in _chunks.duplicate():
		if chunk.position.z > chunk_length:
			chunk.queue_free()
			_chunks.erase(chunk)
			_spawn_chunk()


func _spawn_chunk() -> void:
	var chunk := Node3D.new()
	chunk.name = "Chunk"
	add_child(chunk)
	chunk.position.z = _spawn_z

	_add_ground(chunk)
	_add_lane_markers(chunk)
	_maybe_spawn_enemies(chunk)
	_maybe_spawn_obstacles(chunk)

	_chunks.append(chunk)
	_spawn_z -= chunk_length


func _add_ground(chunk: Node3D) -> void:
	var ground := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(lane_width * 3.0, chunk_length)
	ground.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.12, 0.1)
	ground.material_override = mat

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(lane_width * 3.0, 0.1, chunk_length)
	col.shape = shape
	body.add_child(col)
	body.add_child(ground)
	chunk.add_child(body)
	body.position = Vector3(0, -0.05, -chunk_length * 0.5)


func _add_lane_markers(chunk: Node3D) -> void:
	# Simple divider lines between lanes
	for i in 2:
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.1, 0.02, chunk_length)
		marker.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.5, 0.3, 0.5)
		marker.material_override = mat
		marker.position = Vector3(LANES[i] + lane_width * 0.5, 0.01, -chunk_length * 0.5)
		chunk.add_child(marker)


func _maybe_spawn_enemies(chunk: Node3D) -> void:
	if enemy_scene == null:
		return
	# Spawn 1-3 enemies per chunk, randomly placed in lanes
	var count := randi_range(1, 3)
	var used_lanes: Array = []
	for _i in count:
		var lane := _pick_unused_lane(used_lanes)
		if lane == -1:
			break
		used_lanes.append(lane)
		var enemy: Node3D = enemy_scene.instantiate()
		enemy.position = Vector3(LANES[lane], 0, -randi_range(4, int(chunk_length) - 4))
		chunk.add_child(enemy)


func _maybe_spawn_obstacles(chunk: Node3D) -> void:
	if obstacle_scene == null:
		return
	if randf() < 0.4:
		var lane := randi_range(0, 2)
		var obs: Node3D = obstacle_scene.instantiate()
		obs.position = Vector3(LANES[lane], 0, -randi_range(3, int(chunk_length) - 3))
		chunk.add_child(obs)


func _pick_unused_lane(used: Array) -> int:
	var available := [0, 1, 2].filter(func(l): return not used.has(l))
	if available.is_empty():
		return -1
	return available[randi() % available.size()]


func _tick_speed(delta: float) -> void:
	_speed_timer += delta
	if _speed_timer >= speed_interval and run_speed < max_run_speed:
		_speed_timer = 0.0
		run_speed = min(run_speed + speed_increment, max_run_speed)
		speed_changed.emit(run_speed)
