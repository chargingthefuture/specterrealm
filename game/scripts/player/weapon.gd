extends Node3D

# --- Exported settings ---
@export var damage: int = 25
@export var fire_rate: float = 0.15       # seconds between shots
@export var max_ammo: int = 30
@export var reload_time: float = 1.8
@export var max_range: float = 100.0

# --- State ---
var current_ammo: int
var is_reloading: bool = false
var _fire_cooldown: float = 0.0

# --- Node references ---
@onready var muzzle_flash: OmniLight3D = $MuzzleFlash
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var raycast: RayCast3D = $RayCast3D

# --- Signals ---
signal ammo_changed(current: int, max_ammo: int)
signal reloading(duration: float)


func _ready() -> void:
	current_ammo = max_ammo
	raycast.target_position = Vector3(0, 0, -max_range)


func _process(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta


func shoot() -> void:
	if is_reloading or _fire_cooldown > 0.0:
		return
	if current_ammo <= 0:
		reload()
		return

	_fire_cooldown = fire_rate
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)

	_play_muzzle_flash()
	if anim_player:
		anim_player.play("shoot")

	# Raycast hit detection
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit.has_method("take_damage"):
			hit.take_damage(damage)

	if current_ammo == 0:
		reload()


func reload() -> void:
	if is_reloading or current_ammo == max_ammo:
		return
	is_reloading = true
	reloading.emit(reload_time)
	if anim_player:
		anim_player.play("reload")
	await get_tree().create_timer(reload_time).timeout
	current_ammo = max_ammo
	is_reloading = false
	ammo_changed.emit(current_ammo, max_ammo)


func _play_muzzle_flash() -> void:
	muzzle_flash.visible = true
	await get_tree().create_timer(0.05).timeout
	muzzle_flash.visible = false
