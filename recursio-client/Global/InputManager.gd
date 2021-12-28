extends Node


signal controller_changed(controller)

# joypad type or "keyboard"
var _current_controller := ""


func _ready() -> void:
	if not Input.is_connected("joy_connection_changed", self, "_on_joy_connection_changed"):
		var _error = Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")

	_update_controller_buttons()


func get_current_controller() -> String:
	return _current_controller


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
	if Server.is_connection_active:
		_input_data.timestamp = Server.get_server_time()
		Server.send_player_input_data(_input_data)


func _on_joy_connection_changed(_device_id, _connected) -> void:
	_update_controller_buttons()


func _update_controller_buttons() -> void:
	var controller = Input.get_connected_joypads()
	Logger.info("connected controllers: " + str(controller.size()), "InputManager")
	for device_id in controller:
		Logger.info(Input.get_joy_name(device_id), "InputManager")

	# no controller: "keyboard"
	if controller.size() < 1:
		_current_controller = "keyboard"
	else:
		# take the first connected controller
		var name = Input.get_joy_name(controller[0])
		# Xbox Series Controller or XInput Gamepad for older: "xbox"
		if name.count("Xbox") > 0 or name.begins_with("XInput"):
			_current_controller = "xbox"
		# Playstation
		elif name.begins_with("PS"):
			_current_controller = "ps"
		# switch???
		# 	"switch"
		else:
			_current_controller = "generic"

	emit_signal("controller_changed", _current_controller)
