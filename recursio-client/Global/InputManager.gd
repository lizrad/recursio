extends Node


# All input frames for sending to the server
# Consists of 15 
var _input_data: InputData = InputData.new()

var _current_input_frame: InputFrame = InputFrame.new()


# Sets the entire button bitmask with the given bits
func set_triggers_in_input_frame(triggers: int) -> void:
	_current_input_frame.buttons = triggers


# Adds new movement data to the input frame
func add_movement_to_input_frame(movement: Vector3) -> void:
	_current_input_frame.movement = movement

# Adds new rotation data to the input frame
func add_rotation_to_input_frame(rotation: Vector3) -> void:
	_current_input_frame.rotation = rotation


# Adds the current frame to the ringbuffer and resets the current frame
func close_current_input_frame() -> void:
	_current_input_frame.timestamp = Server.get_server_time()
	var input_frame : InputFrame = InputFrame.new()
	input_frame.timestamp = _current_input_frame.timestamp
	input_frame.buttons = _current_input_frame.buttons
	input_frame.movement = _current_input_frame.movement
	input_frame.rotation = _current_input_frame.rotation
	_input_data.add(input_frame)
	_current_input_frame = InputFrame.new()


# Send input data with timestamp to the server
func send_player_input_data_to_server() -> void:
	_input_data.timestamp = Server.get_server_time()
	Server.send_player_input_data(_input_data)



