extends CharacterBase
class_name PlayerBase


# The acceleration applied to the velocity
var acceleration: Vector3 = Vector3.ZERO

# Blocks any movement applied to it (includes rotation-movement)
var block_movement: bool = true

var input_movement_direction: Vector3 = Vector3.ZERO

var timestamp_of_previous_packet = -1
var previously_applied_packets := RingBuffer.new(10)

# Used for applying drag (e.g. moving platform velocity)
var _target_velocity: Vector3 = Vector3.ZERO

# Values from constants.ini
var _drag = Constants.get_value("movement", "drag")
var _base = Constants.get_value("movement", "scale_to_view_base")
var _factor = Constants.get_value("movement", "scale_to_view_factor")
var _move_acceleration = Constants.get_value("movement", "acceleration")

# RecordManager for recording movement and actions
var _record_manager: RecordManager = RecordManager.new()


func player_base_init(action_manager) -> void:
	.character_base_init(action_manager)


# OVERRIDE #
func reset() -> void:
	.reset()
	_record_manager.reset()
	block_movement = true
	acceleration = Vector3.ZERO
	_target_velocity = Vector3.ZERO


# Should only be called in "physics_update()"
func apply_input(movement_vector: Vector3, rotation_vector: Vector3, buttons: int) -> void:
	# Nothing to do if player can't move
	if block_movement:
		return
	
	input_movement_direction = movement_vector

	# Only rotate if input is given
	if rotation_vector != Vector3.ZERO:
		_kb.look_at(rotation_vector + _kb.global_transform.origin, Vector3.UP)

	# Scale movement depending on the direction the player is looking
	var scale = (_base + movement_vector.dot(rotation_vector)) / _factor
	acceleration = movement_vector * _move_acceleration * scale
	
	# Lerp to target velocity to simulate drag
	self.velocity = lerp(velocity, _target_velocity, _drag)
	# Apply acceleration to velocity (important: after lerp)
	self.velocity += acceleration * get_physics_process_delta_time()
	_kb.move_and_slide(velocity)
	
	# Trigger all actions with base
	.trigger_actions(buttons)
	
	# Add everything to the recording
	_record_manager.add_record_frame(.get_position(), .get_rotation_y(), buttons)

func reset_record_data():
	_record_manager.reset()

func get_record_data() -> RecordData:
	var record_data: RecordData = _record_manager.record_data
	record_data.timeline_index = self.timeline_index
	return record_data
