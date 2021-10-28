extends CharacterBase
class_name Enemy

var last_position
var last_velocity


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

func set_velocity(new_velocity):
	emit_signal("velocity_changed", velocity, -transform.basis.z, transform.basis.x)
	velocity = new_velocity
	
	
func receive_hit():
	Logger.info("Enemy player was hit!", "attacking")
	# TODO: Do we need to move to the spawn point? Not really - the position will be corrected anyways
	# Maybe just do something visually?
