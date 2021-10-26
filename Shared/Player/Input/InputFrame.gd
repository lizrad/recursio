extends Object

class_name InputFrame

var timestamp: int
var buttons: int = 0x00
var movement: Vector2 = Vector2.ZERO
var rotation: Vector2 = Vector2.ZERO

func add_button(bit_index: int):
	buttons = buttons | bit_index

func remove_button(bit_index: int):
	buttons = buttons & ~bit_index

func from_array(data: Array):
	timestamp = data[0]
	buttons = data[1]
	movement = data[2]
	rotation = data[3]
	return self


func to_array()-> Array:
	return [timestamp, buttons, movement, rotation]
