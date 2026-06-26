extends CanvasLayer

# Drives all in-run HUD elements: health bar, ammo counter,
# score, distance, and the crosshair.

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var score_label: Label = $TopRight/ScoreLabel
@onready var distance_label: Label = $TopRight/DistanceLabel
@onready var reload_indicator: Label = $Center/ReloadIndicator
@onready var crosshair: Label = $Center/Crosshair
@onready var hit_flash: ColorRect = $HitFlash
@onready var game_over_panel: Panel = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBox/FinalScore
@onready var high_score_label: Label = $GameOverPanel/VBox/HighScore
@onready var restart_button: Button = $GameOverPanel/VBox/RestartButton

# --- Touch controls (iOS PWA / any touchscreen) ---
@onready var touch_controls: Control = $TouchControls
@onready var left_button: Button = $TouchControls/LeftButton
@onready var right_button: Button = $TouchControls/RightButton
@onready var fire_button: Button = $TouchControls/FireButton
@onready var reload_button: Button = $TouchControls/ReloadButton

var _player: CharacterBody3D
var _firing: bool = false


func _ready() -> void:
	game_over_panel.visible = false
	hit_flash.modulate.a = 0.0
	reload_indicator.visible = false

	# Connect GameManager signals
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over.connect(_on_game_over)

	restart_button.pressed.connect(GameManager.restart)

	_setup_touch_controls()


# --- Touch controls ---

func _setup_touch_controls() -> void:
	# Only surface the on-screen controls on touch hardware so desktop/web
	# players keep a clean screen and use keyboard + mouse.
	touch_controls.visible = DisplayServer.is_touchscreen_available()
	if not touch_controls.visible:
		return
	left_button.pressed.connect(_on_touch_left)
	right_button.pressed.connect(_on_touch_right)
	reload_button.pressed.connect(_on_touch_reload)
	# Hold-to-fire: weapon enforces its own fire-rate cooldown.
	fire_button.button_down.connect(_on_touch_fire_down)
	fire_button.button_up.connect(_on_touch_fire_up)


func _on_touch_left() -> void:
	if _player:
		_player.switch_lane(-1)


func _on_touch_right() -> void:
	if _player:
		_player.switch_lane(1)


func _on_touch_reload() -> void:
	if _player:
		_player.reload()


func _on_touch_fire_down() -> void:
	_firing = true


func _on_touch_fire_up() -> void:
	_firing = false


func _process(_delta: float) -> void:
	if _firing and _player:
		_player.shoot()


# --- Player connections (called by main.gd after instancing player) ---

func connect_player(player: CharacterBody3D) -> void:
	_player = player
	player.health_changed.connect(_on_health_changed.bind(player.max_health))
	var weapon = player.get_node("CameraMount/Camera3D/WeaponMount")
	weapon.ammo_changed.connect(_on_ammo_changed)
	weapon.reloading.connect(_on_reloading)
	# Initialise displays
	_on_health_changed(player.health, player.max_health)
	_on_ammo_changed(weapon.current_ammo, weapon.max_ammo)


# --- Signal handlers ---

func _on_health_changed(new_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = new_health
	_flash_hit()


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	ammo_label.text = "%d / %d" % [current, max_ammo]


func _on_reloading(duration: float) -> void:
	reload_indicator.visible = true
	await get_tree().create_timer(duration).timeout
	reload_indicator.visible = false


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score


func update_distance(meters: float) -> void:
	distance_label.text = "%dm" % int(meters)


func _on_game_over(final_score: int, _distance: float) -> void:
	game_over_panel.visible = true
	final_score_label.text = "Score: %d" % final_score
	high_score_label.text = "Best: %d" % GameManager.high_score
	# Focus the button so a controller (ui_accept = A) or keyboard can restart.
	restart_button.grab_focus()


func _flash_hit() -> void:
	hit_flash.modulate.a = 0.35
	var tween := create_tween()
	tween.tween_property(hit_flash, "modulate:a", 0.0, 0.4)
