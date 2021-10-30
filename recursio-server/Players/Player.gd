extends CharacterBase
class_name Player

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
