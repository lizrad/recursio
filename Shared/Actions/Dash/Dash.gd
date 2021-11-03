extends Node

var _owning_player: CharacterBase

var _time: float = 0.0
var _steepness = Constants.get_value("dash", "steepness")
var _factor = Constants.get_value("dash", "factor")
var _max_time = Constants.get_value("dash", "max_time")


func initialize(owning_player):
	_owning_player = owning_player


func _physics_process(delta):
	if not _owning_player is PlayerBase:
		return
	
	
	# Always finish after defined second
	_time += delta * (1.0 / _max_time)
	_time = min(_time, 1)

	var e_section = max(exp(log((1 + 1 / _steepness) / (_steepness * _time + 1))) - 1.0 / _steepness,0.0)
	
	_owning_player.velocity += _owning_player.input_movement_direction * e_section * _factor

	if _time == 1:
		queue_free()
