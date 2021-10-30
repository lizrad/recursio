extends Object

class_name InputFrame

var timestamp: int = -1
var buttons: Bitmask = Bitmask.new(0)
var movement: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO


func from_array(data: Array):
	timestamp = data[0]
	buttons.mask = data[1].mask
	movement = data[2]
	rotation = data[3]
	return self


func to_array()-> Array:
	return [timestamp, buttons.mask, movement, rotation]
