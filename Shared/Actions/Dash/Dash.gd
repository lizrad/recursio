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

	var direction = _owning_player.input_movement_direction.normalized()
	if direction == Vector3.ZERO:
		direction = Vector3.FORWARD.rotated(Vector3.UP, _owning_player.get_rotation_y())
	_owning_player.velocity += direction * _factor

	# Always finish after defined second
	_time += delta * (1.0 / _max_time)
	_time = min(_time, 1)
	if _time == 1:
		queue_free()
