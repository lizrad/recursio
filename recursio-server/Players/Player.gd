extends CharacterBase
class_name Player

var velocity := Vector3.ZERO
var current_target_velocity := Vector3.ZERO
var acceleration := Vector3.ZERO
var rotation_velocity := 0.0

var input_movement_direction: Vector3 = Vector3.ZERO

onready var dash_activation_timer = get_node("DashActivationTimer")
var dash_charges = Constants.get_value("dash", "charges")
var dash_cooldown = Constants.get_value("dash", "cooldown")
var dash_start_times = []

onready var dash_confirmation_timer = get_node("DashConfirmationTimer")
var _waiting_for_dash := false
var _collected_illegal_movement_if_not_dashing := Vector3.ZERO
var _collected_illegal_movement := Vector3.ZERO
var _dashing := false
var wait_for_player_to_correct = 0

var _recording = false
var action_last_frame
var gameplay_record = {}

var can_move: bool = false

var action_manager
var world_processing_offset

var _drag = Constants.get_value("movement", "drag")
var _move_acceleration = Constants.get_value("movement", "acceleration")


func reset():
	_recording=false
	gameplay_record.clear()
	velocity = Vector3.ZERO
	acceleration = Vector3.ZERO
	for i in range(dash_start_times.size()):
		dash_start_times[i] =- 1
	_waiting_for_dash = false
	_collected_illegal_movement_if_not_dashing= Vector3.ZERO
	_collected_illegal_movement = Vector3.ZERO
	_dashing = false
	wait_for_player_to_correct = 0
	can_move = false
	ghost_index = 0

	
func start_recording():
	gameplay_record.clear()
	_recording = true
	#time the recording started
	gameplay_record["T"] = Server.get_server_time()
	#index of the ghost
	gameplay_record["G"] = ghost_index
	#TODO: connect weapon information recording with actuall weapon system when ready
	gameplay_record["W"] = action_manager.ActionType.HITSCAN \
			if ghost_index != Constants.get_value("ghosts", "wall_placing_ghost_index") \
			else action_manager.ActionType.WALL
	#array of gameplay data per frame
	gameplay_record["F"] = []

func stop_recording():
	_recording = false


func _create_record_frame(time, position, rotation, attack = action_manager.Trigger.NONE, dash = action_manager.Trigger.NONE) -> Dictionary:
	var frame = {"T": time, "P": position, "R": rotation, "A": attack, "D": dash}
	return frame


func _ready():
	action_last_frame = action_manager.Trigger.NONE
	
	for i in range(dash_charges):
		dash_start_times.append(-1)
	dash_confirmation_timer.connect("timeout", self, "_on_dash_confirmation_timeout")
	#TODO: value found by testing think about correct value
	dash_confirmation_timer.wait_time = 0.5
	dash_activation_timer.connect("timeout", self, "_on_dash_activation_timeout")
	#TOOD: value found by testing think about correct value
	dash_activation_timer.wait_time = 1.25


func apply_player_input_data(input_data: InputData, physics_delta):
	
	var input_frame: InputFrame = input_data.get_closest_or_earlier(Server.get_server_time() - world_processing_offset)
	var movement: Vector2 = input_frame.movement
	var rotation: Vector2 = input_frame.rotation
	
	# Clamp movement
	var length = movement.length()
	movement /= length if length > 1.0 else 1
	
	# Clamp rotation
	length = rotation.length()
	rotation /= length if length > 1.0 else 1
	
	var movement_vector = Vector3(movement.y, 0.0, -movement.x)
	input_movement_direction = movement_vector
	var rotation_vector = Vector3(rotation.y, 0.0, -rotation.x)
	
	# Only apply movement when player is allowed to move
	if can_move:
		# Only rotate if input is given
		if rotation_vector != Vector3.ZERO:
			look_at(rotation_vector + global_transform.origin, Vector3.UP)

		var acceleration = StaticInput.calculate_acceleration(movement_vector, rotation_vector);
		_apply_acceleration(acceleration)
		
		move_and_slide(velocity)
		transform.origin.y = 0
	
	# Buttons pressed in this frame
	var buttons: int = input_frame.buttons
	
	if buttons & action_manager.Trigger.SPECIAL_MOVEMENT_START:
		if _valid_dash_start_time(input_frame.timestamp):
			Logger.info("Dash received", "movement_validation")
			_dashing = true
			dash_activation_timer.start()
			#reset collection of illegal movement if we get confirmation of dash
			_waiting_for_dash = false
			_collected_illegal_movement_if_not_dashing = Vector3.ZERO
			
			if _recording:
				var i = max(0,gameplay_record["F"].size() - 1)
				while gameplay_record["F"][i]["T"] > input_frame.timestamp && i >= 0:
					i -= 1
				gameplay_record["F"][i]["D"] = action_manager.Trigger.SPECIAL_MOVEMENT_START
		else:
			Logger.info("Illegal dash", "movement_validation")

	if _recording:
		gameplay_record["F"].append(
			_create_record_frame(Server.get_server_time(), transform.origin, rotation.y, action_last_frame)
		)
		action_last_frame = action_manager.Trigger.NONE


func _apply_acceleration(new_acceleration):
	acceleration = new_acceleration

	# First drag, then add the new acceleration
	# For drag: Lerp towards the target velocity
	# This is usually 0, unless we're on something that's moving, in which case it is that object's
	#  velocity
	velocity = lerp(velocity, current_target_velocity, _drag)
	velocity += acceleration

func _valid_dash_start_time(time):
	for i in range(dash_charges):
		if dash_start_times[i] == -1:
			dash_start_times[i] = time
			return true
		if time - dash_start_times[i] >= dash_cooldown * 1000:
			dash_start_times[i] = time
			return true
	return false


func _on_dash_activation_timeout():
	Logger.info("Turn off dashing", "movement_validation")
	_dashing = false


func _on_dash_confirmation_timeout():
	if _waiting_for_dash:
		_waiting_for_dash = false
		_collected_illegal_movement += _collected_illegal_movement_if_not_dashing
		_collected_illegal_movement_if_not_dashing = Vector3.ZERO


# TODO: Move partially to CharacterBase?
func receive_hit():
	emit_signal("hit")
