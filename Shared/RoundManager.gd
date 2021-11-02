extends Node
class_name RoundManager

signal round_started(round_index, latency)
signal latency_delay_phase_started(latency)
signal preparation_phase_started(latency)
signal countdown_phase_started(countdown_time, latency)
signal game_phase_started(latency)
signal game_phase_ended()
signal round_ended(round_index)

enum Phases {
	LATENCY_DELAY,
	PREPARATION,
	COUNTDOWN,
	GAME,
	NONE
}

var round_index: int = -1

var _latency_delay_time: float = Constants.get_value("gameplay", "latency_delay")
var _preparation_time: float = Constants.get_value("gameplay", "prep_phase_time")
var _countdown_time: float = Constants.get_value("gameplay","countdown_phase_seconds")
var _game_time: float = Constants.get_value("gameplay", "game_phase_time")

var _timer: float = 0.0
# Time difference due to latency. Used for synchronisation
var _latency: float = 0.0
var _phase = Phases.NONE

var _round_started: bool = false



func _physics_process(delta):
	_timer += delta
	
	match _phase:
		Phases.NONE:
			if _round_started:
				_timer = 0
				_phase = Phases.LATENCY_DELAY
				Logger.info("Latency delay phase started","gameplay")
				emit_signal("latency_delay_phase_started", _latency)
		Phases.LATENCY_DELAY:
			if _timer >= _latency_delay_time - _latency:
				_timer -= _latency_delay_time
				_phase = Phases.PREPARATION
				Logger.info("Preparation phase started","gameplay")
				emit_signal("preparation_phase_started", _latency)
		Phases.PREPARATION:
			if _timer >= _preparation_time:
				_timer -= _preparation_time
				_phase = Phases.COUNTDOWN
				Logger.info("Countdown phase started","gameplay")
				emit_signal("countdown_phase_started", _countdown_time, _latency)
		Phases.COUNTDOWN:
			if _timer >= _countdown_time:
				_timer -= _countdown_time
				_phase = Phases.GAME
				Logger.info("Game phase started","gameplay")
				emit_signal("game_phase_started", _latency)
		Phases.GAME:
			if _timer >= _game_time:
				_timer -= _game_time
				_phase = Phases.NONE
				_round_started = false
				Logger.info("Game phase ended","gameplay")
				emit_signal("game_phase_ended")


# Called to start the game loop
func start_round(round_index, latency) -> void:
	self.round_index = round_index
	_latency = latency
	_round_started = true
	Logger.info("Round started","gameplay")
	emit_signal("round_started", round_index, latency)


func stop_round() -> void:
	_round_started = false
	_phase = Phases.NONE
	Logger.info("Round ended","gameplay")
	emit_signal("round_ended", round_index)


func round_is_running() -> bool:
	return _round_started


func get_current_phase() -> int:
	return _phase


func get_latency() -> float:
	return _latency



