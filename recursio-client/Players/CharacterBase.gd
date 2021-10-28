extends KinematicBody
class_name CharacterBase

signal hit
signal action_status_changed(action_type, status)
signal velocity_changed(velocity, front_vector, right_vector)
signal ghost_index_changed(ghost_index)


var velocity := Vector3.ZERO setget set_velocity
var ghost_index := -1 setget set_ghost_index
var round_index := -1

class MovementFrame:
	var position

var spawn_point := Vector3.ZERO

func set_action_status(action_type, status):
	emit_signal("action_status_changed",action_type, status)
	
func set_velocity(new_velocity):
	emit_signal("velocity_changed", velocity, -transform.basis.z, transform.basis.x)
	velocity = new_velocity

func set_ghost_index(new_ghost_index):
	emit_signal("ghost_index_changed", new_ghost_index)
	ghost_index=new_ghost_index
