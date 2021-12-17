extends CharacterBase
class_name PlayerBase

signal wall_spawn(position, rotation, wall_index)

var _wall_index = 0

# The acceleration applied to the velocity
var acceleration: Vector3 = Vector3.ZERO

# only trigger shoot actions in aim_mode
var aim_mode: bool = false

# Blocks any movement applied to it (includes rotation-movement)
var block_movement: bool = true
var block_input: bool = false

var input_movement_direction: Vector3 = Vector3.ZERO

var timestamp_of_previous_packet = -1
var previously_applied_packets := RingBuffer.new(InputData.RING_BUFFER_SIZE)

var user_name: String

# Used for applying drag (e.g. moving platform velocity)
var _target_velocity: Vector3 = Vector3.ZERO

# Values from constants.ini
var _drag_factor = Constants.get_value("movement", "drag_factor")
var _base = Constants.get_value("movement", "scale_to_view_base")
var _factor = Constants.get_value("movement", "scale_to_view_factor")
var _move_acceleration = Constants.get_value("movement", "acceleration")

# RecordManager for recording movement and actions
var _record_manager: RecordManager = RecordManager.new()


func player_base_init(action_manager) -> void:
	.character_base_init(action_manager)
	_auto_respawn_on_death = true


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
	if block_movement or currently_dying or currently_spawning:
		return

	var delta = get_physics_process_delta_time()
	input_movement_direction = movement_vector

	# Only rotate if input is given
	if rotation_vector != Vector3.ZERO:
		kb.look_at(rotation_vector + kb.global_transform.origin, Vector3.UP)

	# Scale movement depending on the direction the player is looking
	var scale = (_base + movement_vector.dot(rotation_vector)) / _factor
	acceleration = movement_vector * _move_acceleration * scale
	
	# Lerp to target velocity to simulate drag
	self.velocity = lerp(velocity, _target_velocity, _drag_factor * delta)
	# Apply acceleration to velocity (important: after lerp)
	self.velocity += acceleration * delta
	var _collision_velocity = kb.move_and_slide(velocity)
	
	# Trigger all actions with base
	if aim_mode == false && not block_input:
		.trigger_actions(buttons)

	# Add everything to the recording
	_record_manager.add_record_frame(.get_position(), .get_rotation_y(), 0 if block_input else buttons)

func reset_record_data():
	_record_manager.reset()

func reset_wall_indices():
	_wall_index = 0

func get_record_data() -> RecordData:
	var record_data: RecordData = _record_manager.record_data
	record_data.timeline_index = self.timeline_index
	return record_data


func set_record_data_timestamp(timestamp: int) -> void:
	_record_manager.record_data.timestamp = timestamp


# OVERRIDE #
func wall_spawned(wall):
	emit_signal("wall_spawn", wall.global_transform.origin, wall.global_transform.basis.get_euler().y, _wall_index)
	_wall_index += 1
