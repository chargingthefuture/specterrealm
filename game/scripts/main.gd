extends Node3D

# Root scene controller.
# Wires together Player, WorldSpawner, HUD, and GameManager.

@onready var player: CharacterBody3D = $Player
@onready var world_spawner: Node3D = $WorldSpawner
@onready var hud: CanvasLayer = $HUD
@onready var environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun


func _ready() -> void:
	# Connect world events to GameManager and HUD
	world_spawner.distance_updated.connect(_on_distance_updated)

	# Connect player events
	player.player_died.connect(_on_player_died)
	player.add_to_group("player")

	# Connect enemy score events (enemies added dynamically — use group signal pattern)
	# Each zombie emits died(score) which we catch via a callable connected at spawn time
	# See world_spawner._spawn_chunk → zombie.died.connect(GameManager.add_score)

	# Wire HUD to player
	hud.connect_player(player)

	# Start the run
	GameManager.start_game()


func _on_distance_updated(distance: float) -> void:
	GameManager.update_distance(distance)
	hud.update_distance(distance)


func _on_player_died() -> void:
	GameManager.trigger_game_over()
	# Freeze world scroll
	world_spawner.set_process(false)
	world_spawner.set_physics_process(false)
