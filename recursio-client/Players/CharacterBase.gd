extends KinematicBody
class_name CharacterBase

signal hit
signal action_status_changed(action_type, status)
signal velocity_changed(velocity, front_vector, right_vector)


var ghost_index := -1
var round_index := -1

class MovementFrame:
	var position

var spawn_point := Vector3.ZERO

func set_action_status(action_type, status):
	emit_signal("action_status_changed",action_type, status)
