extends Spatial


var _initialized: bool = false
var _round_manager: RoundManager
var _server: Server
var rotation_amount = 10


func init() -> void:
	_initialized = true
	_round_manager = get_parent()._round_manager
	_server = get_tree().get_root().get_node("Server")
	var _error = _round_manager.connect("game_phase_stopped", self, "_reset_rotation")


func _physics_process(_delta) -> void:
	if not _initialized:
		if get_parent()._round_manager == null:
			return
		else:
			init()
	else:
		if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
			_rotate()


func _rotate() -> void:
	var ratio = _round_manager.get_current_phase_time_left()/_round_manager.get_current_phase_time()
	rotation.y = (1-ratio)*rotation_amount

func _reset_rotation() -> void:
	rotation.y = 0
