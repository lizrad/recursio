extends Control
class_name HUD

onready var timer_pb: TextureProgress = get_node("TimerProgressBar")
onready var phase = get_node("Phase")
onready var ammo = get_node("WeaponAmmo")
onready var dash = get_node("DashAmmo")

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
var round_state = Latency_Delay
var _max_time := -1.0
var _start_time := -1.0

func _ready() -> void:
	pass

func _process(delta):
	timer_pb.value = _calculate_progress()

# Calculates the remaining time and maps it between 0 and 1
func _calculate_progress() ->float:
	if _max_time < 0 or _start_time < 0:
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

func round_start(round_index, start_time) ->void:
	phase.text = "Round "+str(round_index)+" starting..."
	_max_time = Constants.get_value("gameplay", "latency_delay")
	_start_time = start_time
	
func prep_phase_start(round_index, start_time) ->void:
	phase.text = "Preparation Phase "+str(round_index)
	_max_time = Constants.get_value("gameplay", "prep_phase_time")
	_start_time = start_time
	
func game_phase_start(round_index, start_time) ->void:
	phase.text = "Game Phase "+str(round_index)
	_max_time = Constants.get_value("gameplay", "game_phase_time")
	_start_time = start_time

func rewind_phase_start(round_index, start_time) ->void:
	phase.text = "Rewind Phase "+str(round_index)
	_max_time = Constants.get_value("gameplay", "rewind_phase_time")
	_start_time = start_time


func update_ammo(action_type: int, amount: int) ->void:
	Logger.info("update ammo for type: %s - %s" %[action_type, amount], "HUD")
	assert(action_type in Constants.ActionType.values(), "update_ammo argument is expected to be an ActionType")
	if action_type == Constants.ActionType.SHOOT and ammo:
		ammo.text = str(amount)
	elif action_type == Constants.ActionType.DASH and dash:
		dash.text = str(amount)


# Sets the internal player id for the capture points
func set_player_id(player_id):
	for capture_point in _capture_points:
		capture_point.set_player_id(player_id)

# Adds a new capture point HUD item to the HUD
func add_capture_point():
	var capture_point: CapturePointHUD = _capture_point_scene.instance()
	_capture_point_hb.add_child(capture_point)
	_capture_points.append(capture_point)
	
	_number_of_capture_points += 1
	# Convert number to letter
	var capture_point_name = str(char(_number_of_capture_points + 64))
	capture_point.set_name(capture_point_name)


# Sets the capture point progress of the specified capture point
# The progress is between 0 and 1
func update_capture_point(capture_point_id, progress, team):
	_capture_points[capture_point_id].update_status(progress, team)
