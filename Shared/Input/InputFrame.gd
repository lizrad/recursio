extends Reference

class_name InputFrame

var timestamp: int = -1
var buttons: int = 0
var movement: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO


func from_array(data: Array):
	timestamp = data[0]
	buttons = data[1]
	movement = data[2]
	rotation = data[3]
	return self


func to_array()-> Array:
	return [timestamp, buttons, movement, rotation]
