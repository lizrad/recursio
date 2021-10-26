extends Node

var _owning_player: CharacterBase

var _time: float = 0.0
var _dash_impulse = Constants.get_value("dash", "impulse")
var _dash_exponent = Constants.get_value("dash", "impulse")


func initialize(owning_player):
	_owning_player = owning_player


func _physics_process(delta):
	
	if not _owning_player is Player:
		return
	
	var steepness = 20.0
	var e_section = max(exp(log((1 + 1 / steepness) / (steepness * _time + 1))) - 1.0 / steepness,0.0)

	print(e_section)
	_owning_player.velocity += _owning_player.input_movement_direction * e_section
	_time += delta
	
	if e_section <= 0.01:
		queue_free()
