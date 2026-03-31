extends Node

# Singleton (Autoload as "GameManager").
# Owns game state: score, run distance, speed tier, and game lifecycle.

# --- State ---
var score: int = 0
var distance: float = 0.0
var high_score: int = 0
var is_running: bool = false
var is_game_over: bool = false

# --- Signals ---
signal score_changed(new_score: int)
signal game_started
signal game_over(final_score: int, final_distance: float)
signal game_restarted


func _ready() -> void:
	_load_high_score()


# Called by main scene once all nodes are ready
func start_game() -> void:
	score = 0
	distance = 0.0
	is_running = true
	is_game_over = false
	score_changed.emit(score)
	game_started.emit()


func add_score(amount: int) -> void:
	if not is_running:
		return
	score += amount
	score_changed.emit(score)


func update_distance(d: float) -> void:
	distance = d


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_running = false
	is_game_over = true
	if score > high_score:
		high_score = score
		_save_high_score()
	game_over.emit(score, distance)


func restart() -> void:
	game_restarted.emit()
	# Reload the main scene to reset all nodes cleanly
	get_tree().reload_current_scene()


# --- Persistence ---
const SAVE_PATH := "user://save.cfg"

func _save_high_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "high_score", high_score)
	cfg.save(SAVE_PATH)


func _load_high_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = cfg.get_value("scores", "high_score", 0)
