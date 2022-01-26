extends Node

onready var _max_time = Constants.get_value("dash", "max_time")

var _owning_player: CharacterBase
var _time: float = 0.0
var _factor = Constants.get_value("dash", "factor")


func initialize(owning_player):
	_owning_player = owning_player


func _physics_process(delta):
	if not _owning_player is PlayerBase:
		return

	var direction = _owning_player.input_movement_direction.normalized()
	if direction == Vector3.ZERO:
		direction = Vector3.FORWARD.rotated(Vector3.UP, _owning_player.get_rotation_y())
	_owning_player.velocity += direction * _factor * delta

	# Always finish after defined max time
	_time += delta 
	if _time >= _max_time:
		free()
