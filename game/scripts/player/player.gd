extends CharacterBody3D

# --- Constants ---
const MOUSE_SENSITIVITY := 0.002
const BOB_FREQUENCY := 2.4
const BOB_AMPLITUDE := 0.06

# --- Exported settings ---
@export var max_health: int = 100
@export var lane_switch_speed: float = 8.0

# --- State ---
var health: int
var is_dead: bool = false
var current_lane: int = 1          # 0 = left, 1 = center, 2 = right
var target_x: float = 0.0

# --- Node references ---
@onready var camera: Camera3D = $CameraMount/Camera3D
@onready var camera_mount: Node3D = $CameraMount
@onready var weapon: Node3D = $CameraMount/Camera3D/WeaponMount
@onready var muzzle_flash: OmniLight3D = $CameraMount/Camera3D/WeaponMount/MuzzleFlash

# --- Signals ---
signal health_changed(new_health: int)
signal player_died

# Lane X positions matching the world lane layout
const LANE_POSITIONS := [-3.0, 0.0, 3.0]

var _bob_time: float = 0.0
var _game_manager: Node  # set by GameManager after ready


func _ready() -> void:
	health = max_health
	# On touch devices (iOS PWA) there is no pointer to capture — leave the
	# cursor visible so the on-screen HUD buttons stay tappable.
	if DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	muzzle_flash.visible = false


func _input(event: InputEvent) -> void:
	if is_dead:
		return

	# Mouse look (vertical only — horizontal is locked, player runs forward)
	if event is InputEventMouseMotion:
		camera_mount.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, -0.4, 0.4)

	# Lane switching
	if event.is_action_pressed("move_left"):
		_switch_lane(-1)
	if event.is_action_pressed("move_right"):
		_switch_lane(1)

	# Shooting (mouse). On touchscreens, firing is driven by the on-screen
	# FIRE button instead — Godot emulates mouse clicks from taps, so we skip
	# this to avoid the lane/reload buttons also firing the weapon.
	if event.is_action_pressed("shoot") and not DisplayServer.is_touchscreen_available():
		_try_shoot()

	# Reload
	if event.is_action_pressed("reload"):
		$CameraMount/Camera3D/WeaponMount.reload()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Smooth lateral lane movement
	var target := Vector3(LANE_POSITIONS[current_lane], position.y, position.z)
	position.x = lerp(position.x, target.x, lane_switch_speed * delta)

	# Head bob while running
	_bob_time += delta
	var bob_offset := sin(_bob_time * BOB_FREQUENCY) * BOB_AMPLITUDE
	camera_mount.position.y = lerp(camera_mount.position.y, bob_offset, 10.0 * delta)

	move_and_slide()


func _switch_lane(direction: int) -> void:
	current_lane = clamp(current_lane + direction, 0, 2)


# --- Public API (used by on-screen touch controls) ---

func switch_lane(direction: int) -> void:
	if is_dead:
		return
	_switch_lane(direction)


func shoot() -> void:
	if is_dead:
		return
	_try_shoot()


func reload() -> void:
	if is_dead:
		return
	$CameraMount/Camera3D/WeaponMount.reload()


func _try_shoot() -> void:
	var weapon_node = $CameraMount/Camera3D/WeaponMount
	if weapon_node.has_method("shoot"):
		weapon_node.shoot()


func take_damage(amount: int) -> void:
	if is_dead:
		return
	health = max(0, health - amount)
	health_changed.emit(health)
	if health == 0:
		_die()


func _die() -> void:
	is_dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player_died.emit()
