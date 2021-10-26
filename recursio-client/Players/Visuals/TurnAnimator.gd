extends Node

onready var root_pivot = get_node("../RootPivot")
export var max_rotation := PI/3.0
export var max_velocity := 3.0
export var waver_speed := 8
export var waver_extent = PI/12.0

var _phase = 0

func get_keyframe(delta, right_velocity):
	var ratio = abs(right_velocity/max_velocity)
	var rotation = lerp(0,max_rotation,ratio) * sign(right_velocity)
	_phase += delta*waver_speed
	if right_velocity!=0:
		rotation+=sin(_phase)*waver_extent
	var keyframes = {}
	keyframes[root_pivot] =  Transform(
		Basis(Vector3(0,0,rotation)),
		Vector3(0,0,0))
	return keyframes
