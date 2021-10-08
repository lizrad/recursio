extends Control
class_name HUD

onready var timer = get_node("Background/Timer")
onready var phase = get_node("Phase")
onready var ammo = get_node("WeaponAmmo")
onready var dash = get_node("DashAmmo")
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
	timer.text = _calculate_current_time()

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

func set_capture_point_progress(capture_point_id, progress):
	pass
