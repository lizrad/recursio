extends Control
class_name HUD

onready var _timer_pb: TextureProgress = get_node("TimerProgressBar")
onready var _phase = get_node("Phase")
onready var _ammo = get_node("WeaponAmmo")
onready var _ammo_type_bg = get_node("WeaponAmmo/WeaponTypeBG")
onready var _ammo_type = get_node("WeaponAmmo/WeaponTypeBG/WeaponType")
onready var _dash = get_node("DashAmmo")
onready var _capture_point_hb = get_node("TimerProgressBar/CapturePoints")

var _round_manager

# Capture point HUD scene for dynamically initializing them
var _capture_point_scene = preload("res://UI/CapturePointHUD.tscn")

var _number_of_capture_points := 0
# Array of all capture points in the HUD
var _capture_points = []

# Array of all spawn points
var _spawn_points = []

enum {
	Latency_Delay,
	Prep_Phase,
	Game_Phase
}
var _max_time := -1.0

func pass_round_manager(round_manager):
	_round_manager = round_manager

func _ready() -> void:
	reset()

func reset():
	_phase.text = "Waiting for game to start..."
	_max_time = -1.0
	_dash.visible = false
	_ammo.visible = false

func _process(_delta):
	var val = _calculate_progress()
	_timer_pb.value = val
	if val < 0.15:
		_timer_pb.tint_progress = Color.red
	elif val < 0.35:
		_timer_pb.tint_progress = Color.yellow
	else:
		_timer_pb.tint_progress = Color.white

# Calculates the remaining time and maps it between 0 and 1
func _calculate_progress() -> float:
	if _max_time <= 0:
		return 0.0
	return _round_manager.get_current_phase_time_left() / 1000.0 / _max_time

func prep_phase_start(round_index) -> void:
	_phase.text = "Preparation Phase " + str(round_index + 1)
	_max_time = Constants.get_value("gameplay", "prep_phase_time")
	_dash.visible = true
	_ammo.visible = true

func countdown_phase_start() -> void:
	_phase.text = "Get ready!"
	_max_time = Constants.get_value("gameplay", "countdown_phase_seconds")

func game_phase_start(round_index) -> void:
	_phase.text = "Game Phase " + str(round_index + 1)
	_max_time = Constants.get_value("gameplay", "game_phase_time")


func update_fire_action_ammo(amount: int) -> void:
	Logger.info("Set fire ammo to: " + str(amount), "HUD")
	_ammo.text = str(amount)


func update_special_movement_ammo(amount: int) -> void:
	Logger.info("Set special movement ammo to: " + str(amount), "HUD")
	_dash.text = str(amount)


func update_weapon_type(img_bullet, color) -> void:
	Logger.info("Update ammo type", "HUD")
	_ammo_type_bg.modulate = color
	_ammo_type.texture = img_bullet


func activate_spawn_point(timeline_index) -> void:
	Logger.info("Activate SpawnPoint " + str(timeline_index), "HUD")
	for spawn_point in _spawn_points:
		if spawn_point.get_child_count() > 0:
			spawn_point.get_child(0).set_active(spawn_point.get_index() == timeline_index)


# Sets the internal player id for the capture points
func set_player_id(player_id) -> void:
	for capture_point in _capture_points:
		capture_point.set_player_id(player_id)


# Adds a new capture point HUD item to the HUD
func add_capture_point() -> void:
	var capture_point: CapturePointHUD = _capture_point_scene.instance()
	_capture_point_hb.add_child(capture_point)
	_capture_points.append(capture_point)

	# Convert number to letter
	var capture_point_name = char(65 + _number_of_capture_points)
	capture_point.set_name(capture_point_name)

	_number_of_capture_points += 1


# Sets the capture point progress of the specified capture point
# The progress is between 0 and 1
func update_capture_point(capture_point_id, progress, team) -> void:
	_capture_points[capture_point_id].update_status(progress, team)


func set_spawn_points(spawn_points):
	_spawn_points = spawn_points
