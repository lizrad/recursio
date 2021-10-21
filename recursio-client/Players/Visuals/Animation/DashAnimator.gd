extends Node

signal animaton_over

export var speed :=50

onready var back_pivot = get_node("../RootPivot/BackPivot")

var _rotate_to_zero = false
var _angle = 0
func start_animation():
	print("start_animation")
	_rotate_to_zero = false
	_angle = back_pivot.transform.basis.get_euler().z
func stop_animation():
	print("stop_animation")
	_rotate_to_zero = true

func get_keyframe(delta):
	var keyframes = {}
	_angle += delta*speed
	if _angle >= 2*PI:
		if _rotate_to_zero:
			_angle = 2*PI
			emit_signal("animaton_over")
		else:
			_angle-=2*PI
	keyframes[back_pivot] =  Transform(
		Basis(Vector3(0,0,_angle)),
		Vector3(0,0,0))
	return keyframes
