extends Node

# All input frames for sending to the server
# Consists of 15 
var _input_data: InputData = InputData.new()

var _current_input_frame: InputFrame = InputFrame.new()

# Sends the player state every frame
func _physics_process(_delta):
	if Server.get_server_time() <= 0:
		return
	_close_current_input_frame()
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
	_current_input_frame.timestamp = Server.get_server_time()
	var input_frame : InputFrame = InputFrame.new()
	input_frame.timestamp = _current_input_frame.timestamp
	input_frame.buttons = _current_input_frame.buttons
	input_frame.movement = _current_input_frame.movement
	input_frame.rotation = _current_input_frame.rotation
	_input_data.add(input_frame)


# Send input data with timestamp to the server
func _send_player_input_data_to_server()-> void:
	_input_data.timestamp = Server.get_server_time()
	Server.send_player_input_data(_input_data)



