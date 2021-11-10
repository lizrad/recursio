extends Node
class_name RoundManager

signal preparation_phase_started()
signal countdown_phase_started()
signal game_phase_started()
signal preparation_phase_stopped()
signal countdown_phase_stopped()
signal game_phase_stopped()

enum Phases {
	PREPARATION,
	COUNTDOWN,
	GAME,
	NONE
}

export var autonomous := true
onready var server = get_node("/root/Server")

var _phase_order = [Phases.PREPARATION, Phases.COUNTDOWN, Phases.GAME]

var round_index: int = -1

var _running = false

var _preparation_phase_time: float = Constants.get_value("gameplay", "prep_phase_time")
var _countdown_phase_time: float = Constants.get_value("gameplay","countdown_phase_seconds")
var _game_phase_time: float = Constants.get_value("gameplay", "game_phase_time")

var _phase_deadline = -1.0
var _current_phase_index = -1

var _future_phase = Phases.NONE
var _future_phase_switch_time = -1.0
var _future_phase_switch_imminent = false


var _future_game_imminent = false
var _future_game_start_time = -1.0


# Called to start the game loop
func future_start_game(start_time):
	_future_game_imminent = true
	_future_game_start_time = start_time

func _start_game():
	_start_phase(Phases.PREPARATION)
	_current_phase_index = 0
	round_index = 0
	_running = true


func is_switch_imminent():
	return _future_phase_switch_imminent


func get_current_phase_time_left():
	return (_phase_deadline - server.get_server_time)

func get_deadline():
	return _phase_deadline

func get_current_phase() -> int:
	return _phase_order[_current_phase_index]

func is_running():
	return _running

func future_switch_to_phase(phase, switch_time):
	assert(phase != Phases.NONE)
	_future_phase_switch_imminent = true
	_future_phase = phase
	_future_phase_switch_time = switch_time


func switch_to_phase(phase, delay = 0):
	assert(phase != Phases.NONE)
	_switch_to_phase_index(_phase_order.find(phase), delay)


func _physics_process(_delta):
	_check_for_game_start()
	_check_for_external_phase_switch()
	_check_for_internal_phase_switch()

func _check_for_game_start():
	if _future_game_imminent:
		if server.get_server_time() >= _future_game_start_time:
			_future_game_imminent = false
			_start_game()


func _check_for_external_phase_switch():
	if _future_phase_switch_imminent:
		assert(_future_phase_switch_time != -1.0)
		if server.get_server_time() >= _future_phase_switch_time:
			_future_phase_switch_imminent = false
			_future_phase_switch_time = -1.0
			assert(_future_phase != Phases.NONE)
			var delay = server.get_server_time()-_future_phase_switch_time
			switch_to_phase(_future_phase, delay)
			_future_phase = Phases.NONE


func _check_for_internal_phase_switch():
	if autonomous and _running:
		if server.get_server_time() >= _phase_deadline:
			Logger.info("Current phase timer run out.","gameplay")
			var next_phase_index = (_current_phase_index+1)%_phase_order.size()
			_switch_to_phase_index(next_phase_index)


func _switch_to_phase_index(next_phase_index, delay = 0):
	assert(next_phase_index != -1)
	while _current_phase_index != next_phase_index:
		_stop_phase(_phase_order[_current_phase_index])
		_current_phase_index += 1
		_current_phase_index %= _phase_order.size()
		_start_phase(_phase_order[_current_phase_index], delay)


func _start_phase(phase, delay = 0):
	Logger.info(str(phase)+" phase started","gameplay")
	match phase:
		Phases.PREPARATION:
			round_index += 1
			_phase_deadline = server.get_server_time() + _preparation_phase_time * 1000 - delay
			emit_signal("preparation_phase_started")
		Phases.COUNTDOWN:
			_phase_deadline = server.get_server_time() + _countdown_phase_time * 1000 - delay
			emit_signal("countdown_phase_started")
		Phases.GAME:
			_phase_deadline = server.get_server_time() + _game_phase_time * 1000 - delay
			emit_signal("game_phase_started")


func _stop_phase(phase):
	Logger.info(str(phase)+" phase stopped","gameplay")
	match phase:
		Phases.PREPARATION:
				emit_signal("preparation_phase_stopped")
		Phases.COUNTDOWN:
				emit_signal("countdown_phase_stopped")
		Phases.GAME:
				emit_signal("game_phase_stopped")
	pass
