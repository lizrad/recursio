extends CharacterBase
class_name Enemy

var last_position
var last_velocity

var velocity := Vector3.ZERO

var server_position
var server_velocity
var server_acceleration

func reset():
	velocity = Vector3.ZERO
	last_position = Vector3.ZERO
	last_velocity = Vector3.ZERO
	server_position = Vector3.ZERO
	server_velocity = Vector3.ZERO
	server_acceleration = Vector3.ZERO
