extends Node

signal animation_over

export var animation_duration := 0.2
export var front_extent := 0.75
export var middle_z_extent := 0.375
export var middle_scale_extent := 0.3
export var middle_rotation_periods := 2

onready var front_pivot = get_node("../RootPivot/FrontPivot")
onready var middle_pivot = get_node("../RootPivot/MiddlePivot")

var _time_since_start = 0
var _default_front_z = 0.548
var _default_middle_scale = 1
var _default_middle_z = 0


func start_animation():
	_time_since_start = 0

func get_keyframe(delta):
	_time_since_start += delta
	if _time_since_start > animation_duration:
		emit_signal("animation_over")
		_time_since_start = animation_duration
	var ratio = _time_since_start/animation_duration
	
	var keyframes = {}
	var remapped_ratio = pow(ratio*2,2) if ratio<=0.5 else pow((ratio-1)*2,2)
	print(remapped_ratio)
	var z_front = front_extent * remapped_ratio + _default_front_z
	keyframes[front_pivot] =  Transform(
		Basis(Vector3(0,0,0)),
		Vector3(0,0,z_front))
	
	var angle_middle = ratio * 2*PI * middle_rotation_periods
	var z_middle = middle_z_extent * remapped_ratio + _default_middle_z
	var scale = Vector3(middle_scale_extent * remapped_ratio + _default_middle_scale,1,1)
	keyframes[middle_pivot] =  Transform(
		Basis(Vector3(0,0,angle_middle)),
		Vector3(0,0,z_middle))
	keyframes[middle_pivot].basis = keyframes[middle_pivot].basis.scaled(scale)
	return keyframes
