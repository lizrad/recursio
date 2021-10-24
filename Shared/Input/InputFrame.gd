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
