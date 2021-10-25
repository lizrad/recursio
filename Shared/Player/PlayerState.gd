extends Object
class_name PlayerState

var timestamp: int
var id: int
var position: Vector3
var velocity: Vector3
var acceleration: Vector3
var rotation: float
var rotation_velocity: float

# Fills the object with the data from the given array
func from_array(data: Array)-> PlayerState:
	timestamp = data[0]
	id = data[1]
	position = data[2]
	velocity = data[3]
	acceleration = data[4]
	rotation = data[5]
	rotation_velocity = data[6]
	return self


func to_array()-> Array:
	return [timestamp, id, position, velocity, acceleration, rotation, rotation_velocity]
