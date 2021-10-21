extends Node

# All input frames for sending to the server
# Consists of 15 
var _input_data: InputData = InputData.new(15)

var _current_input_frame: InputFrame

var _timer = 0
# Sends the player state every frame
func _physics_process(delta):
	_close_current_input_frame()

	if _timer < 5.0:
		_timer += delta
		return
	_timer = 0
	_send_player_input_data_to_server()



# Adds a new triggered trigger to the input frame
func add_trigger_to_input_frame(trigger_type: int)-> void:
	_current_input_frame.add_button(trigger_type)


# Removes the triggered trigger from the input frame
func remove_trigger_from_input_frame(trigger_type: int)-> void:
	_current_input_frame.remove_button(trigger_type)


# Adds new movement data to the input frame
func add_movement_to_input_frame(movement: Vector2)-> void:
	_current_input_frame.movement = movement

# Adds new rotation data to the input frame
func add_rotation_to_input_frame(rotation: Vector2)-> void:
	_current_input_frame.rotation = rotation


# Adds the current frame to the ringbuffer and resets the current frame
func _close_current_input_frame() -> void:
	_input_data.append(_current_input_frame.duplicate())


# Send input data with timestamp to the server
func _send_player_input_data_to_server()-> void:
	_input_data.timestamp = Server.get_server_time()
	Server.send_player_input_data(_input_data.to_array())




