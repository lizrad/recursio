extends CharacterBase
class_name PlayerBase

# The current velocity of this player
var _velocity: Vector3 = Vector3.ZERO
# Used for applying drag (e.g. moving platform velocity)
var _target_velocity: Vector3 = Vector3.ZERO
# The acceleration applied to the velocity
var _acceleration: Vector3 = Vector3.ZERO

# Blocks any movement applied to it (includes rotation-movement)
var _block_movement: bool = false


# Values from constants.ini
var _drag = Constants.get_value("movement", "drag")
var _base = Constants.get_value("movement", "scale_to_view_base")
var _factor = Constants.get_value("movement", "scale_to_view_factor")
var _move_acceleration = Constants.get_value("movement", "acceleration")


# Sets "_movement_vector" and thereby moves it
# Should only be called in "physics_update()"
func move_and_rotate(movement: Vector3, rotation: Vector3) -> void:
	# Nothing to do if player can't move
	if _block_movement:
		return
	
	# Clamp movement
	var length = movement.length()
	movement /= length if length > 1.0 else 1
	
	# Clamp rotation
	length = rotation.length()
	rotation /= length if length > 1.0 else 1
	
	var movement_vector = Vector3(movement.y, 0.0, -movement.x)
	var rotation_vector = Vector3(rotation.y, 0.0, -rotation.x)

	# Only rotate if input is given
	if rotation_vector != Vector3.ZERO:
		_kb.look_at(rotation_vector + _kb.global_transform.origin, Vector3.UP)

	# Scale movement depending on the direction the player is looking
	var scale = (_base + movement_vector.dot(rotation_vector)) / _factor
	_acceleration = movement_vector * _move_acceleration * scale
	
	# Lerp to target velocity to simulate drag
	_velocity = lerp(_velocity, _target_velocity, _drag)
	# Apply acceleration to velocity (important: after lerp)
	_velocity += _acceleration * get_physics_process_delta_time()
	
	_kb.move_and_slide(_velocity)
