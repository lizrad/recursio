extends Reference
class_name PlayerState

var timestamp: int
var id: int
var position: Vector3
var velocity: Vector3
var acceleration: Vector3
var rotation_y: float
var buttons: int = 0

# Fills the object with the data from the given array
func from_array(data: Array)-> PlayerState:
	timestamp = data[0]
	id = data[1]
	position = data[2]
	velocity = data[3]
	acceleration = data[4]
	rotation_y = data[5]
	buttons = data[6]
	return self


func to_array()-> Array:
	return [timestamp, id, position, velocity, acceleration, rotation_y, buttons]
