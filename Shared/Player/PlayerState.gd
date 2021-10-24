extends Object
class_name PlayerState

var timestamp = 0
var position: Vector3
var velocity: Vector3
var acceleration: Vector3
var rotation: Vector3
var rotation_velocity: Vector3


func to_array()-> Array:
	return [timestamp, position, velocity, acceleration, rotation, rotation_velocity]


static func from_array(data : Array)-> PlayerState:
	var player_state: PlayerState
	player_state.timestamp = data[0]
	player_state.position = data[1]
	player_state.velocity = data[2]
	player_state.acceleration = data[3]
	player_state.rotation = data[4]
	player_state.rotation_velocity = data[4]
	return player_state
