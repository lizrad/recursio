extends Control
class_name HUD

onready var _timer_pb: TextureProgress = get_node("TimerProgressBar")
onready var _phase = get_node("Phase")
onready var _ammo = get_node("WeaponAmmo")
onready var _ammo_type = get_node("WeaponAmmo/WeaponType")
onready var _dash = get_node("DashAmmo")
onready var _capture_point_hb = get_node("TimerProgressBar/CapturePoints")

# Capture point HUD scene for dynamically initializing them
var _capture_point_scene = preload("res://UI/CapturePointHUD.tscn")

var _number_of_capture_points := 0
# Array of all capture points in the HUD
var _capture_points = []

enum {
	Latency_Delay,
	Prep_Phase,
	Game_Phase
}
#var _round_state = Latency_Delay
var _max_time := -1.0
var _start_time := -1.0

func _ready() -> void:
	reset()

func reset():
	_phase.text = "Waiting for game to start..."
	#_round_state = Latency_Delay
	_max_time = -1.0
	_start_time = -1.0

func _process(_delta):
	_timer_pb.value = _calculate_progress()

# Calculates the remaining time and maps it between 0 and 1
func _calculate_progress() -> float:
	if _max_time <= 0 or _start_time <= 0:
		return 0.0
	return 1.0 - (((Server.get_server_time() - _start_time) / 1000.0) / _max_time)

# DEBUG: Still useful for checking client synchronization?
func _calculate_current_time() -> String:
	if _max_time < 0 or _start_time < 0:
		return "0:00"
	var time_diff = (Server.get_server_time() - _start_time) / 1000.0
	var time = max(_max_time - time_diff,0)
	# Give seconds a zero as padding if below 10 sekonds
	return ("%d:%0*d" % [floor(time/60), 2, time])

func round_start(round_index, start_time) -> void:
	_phase.text = "Round "+str(round_index)+" starting..."
	_max_time = Constants.get_value("gameplay", "latency_delay")
	_start_time = start_time

func latency_delay_phase_start(start_time, time_diff) -> void:
	_phase.text = "Waiting for server..."
	_max_time = Constants.get_value("gameplay", "latency_delay")-time_diff
	_start_time = start_time

func prep_phase_start(round_index, start_time) -> void:
	_phase.text = "Preparation Phase "+str(round_index)
	_max_time = Constants.get_value("gameplay", "prep_phase_time")
	_start_time = start_time

func countdown_phase_start(start_time) -> void:
	_phase.text = "Get ready!"
	_max_time = Constants.get_value("gameplay", "countdown_phase_seconds")
	_start_time = start_time

func game_phase_start(round_index, start_time) -> void:
	_phase.text = "Game Phase "+str(round_index)
	_max_time = Constants.get_value("gameplay", "game_phase_time")
	_start_time = start_time

func rewind_phase_start(round_index, start_time) -> void:
	_phase.text = "Rewind Phase "+str(round_index)
	_max_time = Constants.get_value("gameplay", "rewind_phase_time")
	_start_time = start_time


func update_ammo(action_type: int, amount: int) -> void:
	Logger.info("update ammo for type: %s - %s" %[action_type, amount], "HUD")
	if action_type == GlobalActionManager.Trigger.FIRE_START:
		if not _ammo:
			_ammo = get_node("WeaponAmmo")
		_ammo.text = str(amount)
	elif action_type == GlobalActionManager.Trigger.SPECIAL_MOVEMENT_START:
		if not _dash:
			_dash = get_node("DashAmmo")
		_dash.text = str(amount)


func update_ammo_type(tex: StreamTexture) -> void:
	Logger.info("update ammo type", "HUD")
	if not _ammo_type:
		_ammo_type = get_node("WeaponAmmo/WeaponType")
	_ammo_type.texture = load(tex.resource_path)

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
