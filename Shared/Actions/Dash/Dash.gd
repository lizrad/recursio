extends Node

var _owning_player: CharacterBase

var _time: float = 0.0
var _dash_impulse = Constants.get_value("dash", "impulse")
var _dash_exponent = Constants.get_value("dash", "impulse")


func initialize(owning_player):
	_owning_player = owning_player


func _physics_process(delta):
	if not _owning_player is PlayerBase:
		return
	
	_time += delta
	_time = min(_time, 1)

	var steepness = 2
	var e_section = max(exp(-steepness*_time),0.0)
	
	var factor = 10
	_owning_player.velocity += _owning_player.input_movement_direction * e_section * factor

	#always finish after one second
	if _time == 1:
		_time = 1
		queue_free()
