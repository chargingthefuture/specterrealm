extends CharacterBody3D

# Basic zombie enemy.
# Spawned inside world chunks and moves toward the player.
# The world scrolls toward the player, so zombies only need to
# face and lurch forward — the chunk movement does the rest.

# --- Exported settings ---
@export var max_health: int = 50
@export var move_speed: float = 1.5       # zombie's own forward shuffle
@export var attack_damage: int = 10
@export var attack_range: float = 1.2
@export var attack_cooldown: float = 1.5
@export var score_value: int = 10

# --- State ---
var health: int
var _attack_timer: float = 0.0
var _player: CharacterBody3D = null
var _is_dead: bool = false

# --- Signals ---
signal died(score: int)


func _ready() -> void:
	health = max_health
	# Find player via group — player must be in group "player"
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _physics_process(delta: float) -> void:
	if _is_dead or _player == null:
		return

	_attack_timer -= delta

	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	if dist <= attack_range:
		_try_attack()
	else:
		# Shuffle toward player on the Z axis only (lanes handled by world scroll)
		velocity.z = -move_speed
		velocity.y -= 9.8 * delta
		move_and_slide()

	# Always face the player
	look_at(Vector3(_player.global_position.x, global_position.y, _player.global_position.z), Vector3.UP)


func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown
	if _player.has_method("take_damage"):
		_player.take_damage(attack_damage)


func take_damage(amount: int) -> void:
	if _is_dead:
		return
	health -= amount
	if health <= 0:
		_die()


func _die() -> void:
	_is_dead = true
	died.emit(score_value)
	# Simple death: disable collision and fade out, then free
	$CollisionShape3D.disabled = true
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free)
