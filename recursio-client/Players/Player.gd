extends CharacterBase
class_name Player

export(float) var inner_deadzone := 0.2
export(float) var outer_deadzone := 0.8
export(float) var rotate_threshold := 0.0

onready var hud :HUD = get_node("HUD")
var game_id := -1
var player_id := -1

var drag = Constants.get_value("movement", "drag")
var move_acceleration = Constants.get_value("movement", "acceleration")

var _last_rotation = 0.0
var rotation_velocity := 0.0

var position_at_frame_begin := Vector3.ZERO

var past_frames = {}
var _just_corrected = false
var last_server_position
var last_server_time

var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO

# TODO: set per property?
var dash_start := 0  # ticks, used to determine dash intensity
var _time_since_dash_start := 0.0  # ms

var current_target_velocity := Vector3.ZERO

var _rotate_input_vector := Vector3.ZERO
var _input_enabled := true  # disable user input in rewind

onready var _trigger_manager := get_node("TriggerManager")

var block_weapon_swap = false


var game_in_progress:= false
func reset():
	_last_rotation = 0.0
	rotation_velocity = 0.0
	past_frames.clear()
	_just_corrected = false
	last_server_position = Vector3.ZERO
	last_server_time = 0
	velocity = Vector3.ZERO
	acceleration = Vector3.ZERO
	dash_start = 0  
	_time_since_dash_start = 0.0  
	current_target_velocity = Vector3.ZERO
	_rotate_input_vector = Vector3.ZERO
	_input_enabled = true  
	block_weapon_swap = false
	game_in_progress = false
	hud.reset()

func move_back_to_spawnpoint():
	Logger.info("Moving player back to spawnpoint at "+str(spawn_point),"spawnpoints")
	transform.origin = spawn_point


func set_overview_light_enabled(enabled):
	$TransformReset/OverviewLight.enabled = enabled


func move_camera_to_overview():
	$TransformReset/LerpedFollow.target = $TransformReset/OverviewTarget


func follow_camera():
	$TransformReset/LerpedFollow.target = $ViewTarget


func get_normalized_input(type, outer_deadzone, inner_deadzone, min_length = 0.0):
	var input = Vector2(
		Input.get_action_strength(type + "_up") - Input.get_action_strength(type + "_down"),
		Input.get_action_strength(type + "_right") - Input.get_action_strength(type + "_left")
	)

	# Remove signs to reduce the number of cases
	var signs = Vector2(sign(input.x), sign(input.y))
	input = Vector2(abs(input.x), abs(input.y))

	if input.length() < min_length:
		return Vector2.ZERO

	# Deazones for each axis
	if input.x > outer_deadzone:
		input.x = 1.0
	elif input.x < inner_deadzone:
		input.x = 0.0
	else:
		input.x = inverse_lerp(inner_deadzone, outer_deadzone, input.x)

	if input.y > outer_deadzone:
		input.y = 1.0
	elif input.y < inner_deadzone:
		input.y = 0.0
	else:
		input.y = inverse_lerp(inner_deadzone, outer_deadzone, input.y)

	# Re-apply signs
	input *= signs

	# Limit at length 1
	if input.length() > 1.0:
		input /= input.length()

	return input


func handle_network_update(position, time):
	last_server_position = position
	last_server_time = time

	if not past_frames.has(time):
		# TODO: Need to handle this?
		return

	# Get value we had at that time
	var position_diff = position - past_frames[time].position

	# If the difference is too large, correct it
	if position_diff.length() > 0.1:
		# TODO: Lerp there rather than setting it outright
		var before = transform.origin
		transform.origin += position_diff

		Logger.info(("Corrected from " + str(before) + " to " + str(transform.origin)
			+ " (should be at " + str(position) + " according to server)"), "movement_validation")

		# Hotfix for overcompensation - we could also fix all following past states, but is that required?
		past_frames.clear()

		_just_corrected = true


func _physics_process(delta):
	if not game_in_progress:
		return
	position_at_frame_begin = transform.origin

	var rotation_velocity = (rotation.y - _last_rotation) / delta
	_last_rotation = rotation.y
	if _input_enabled:
		_handle_user_input()

	if _just_corrected:
		past_frames.clear()
		_just_corrected = false
	else:
		var frame = MovementFrame.new()
		frame.position = transform.origin
		past_frames[Server.get_server_time()] = frame


func _handle_user_input():
	# movement and aiming
	var delta = get_physics_process_delta_time()
	var input = get_normalized_input("player_move", outer_deadzone, inner_deadzone)
	InputManager.add_movement_to_input_frame(input)
	
	var movement_input_vector = Vector3(input.y, 0.0, -input.x)

	var rotate_input = get_normalized_input("player_look", 1.0, 0.0, 0.5)
	InputManager.add_rotation_to_input_frame(rotate_input)
	
	var rotate_input_vector = Vector3(rotate_input.y, 0.0, -rotate_input.x)
	if rotate_input_vector.distance_to(_rotate_input_vector) > rotate_threshold:
		if rotate_input_vector != Vector3.ZERO:
			_rotate_input_vector = rotate_input_vector
			look_at(rotate_input_vector + global_transform.origin, Vector3.UP)

	var move_direction_scale = (
		(3.0 + movement_input_vector.dot(rotate_input_vector)) / 4.0
		if Constants.get_value("movement", "scale_to_view_direction")
		else 1.0
	)

	apply_acceleration(movement_input_vector * move_acceleration * move_direction_scale)

	# apply dash
	if dash_start > 0:
		var e_section = max(
			exp(
				log(
					(
						Constants.get_value("dash", "impulse")
						- 1 / Constants.get_value("dash", "exponent") * _time_since_dash_start
					)
				)
			),
			0.0
		)

		velocity += movement_input_vector * e_section
		_time_since_dash_start += delta
	else:
		_time_since_dash_start = 0.0
	
	move_and_slide(velocity)
	transform.origin.y = 0

	# shoot, place wall, dash, melee, ...
	_trigger_manager.handle_input()


func get_visibility_mask():
	return $LightViewport.get_texture()


func apply_acceleration(new_acceleration):
	acceleration = new_acceleration

	# First drag, then add the new acceleration
	# For drag: Lerp towards the target velocity
	# This is usually 0, unless we're on something that's moving, in which case it is that object's
	#  velocity
	velocity = lerp(velocity, current_target_velocity, drag)
	velocity += acceleration

func swap_weapon_type(ghost_index):
	_trigger_manager.swap_weapon_type(ghost_index)

func receive_hit():
	Logger.info("Own player was hit!", "attacking")
	# TODO: Do we need to move to the spawn point? Not really - the position will be corrected anyways
	# Maybe just do something visually?
