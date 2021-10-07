extends Control

onready var timer = get_node("Timer")
onready var phase = get_node("Phase")
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

func do_stuff() -> void:
	Logger.info("TODO: implement stuff to do...", "HUD")

func _process(delta):
	timer.text = _calculate_current_time()

func _calculate_current_time() -> String:
	if _max_time<0 or _start_time<0:
		return ""
	var time_diff = (Server.get_server_time()-_start_time)/1000.0
	var time = max(_max_time - time_diff,0)
	return ("%.2f" % time)

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
