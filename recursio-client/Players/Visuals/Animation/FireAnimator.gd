extends Node

signal animation_over

export var animation_duration := 0.5
export var hitscan_rotation_periods := 10
export var hitscan_log_base := 3000
export var middle_scale_extent := 0.35

onready var front_pivot = get_node("../RootPivot/FrontPivot")
onready var middle_pivot = get_node("../RootPivot/MiddlePivot")

var _time_since_start = 0
var _fire_type
var _default_middle_scale = 1
var _default_middle_z = 0
var _default_front_z = 0.548

func start_animation(fire_type):
	_time_since_start = 0
	_fire_type = fire_type

func get_keyframe(delta):
	_time_since_start += delta
	if _time_since_start > animation_duration:
		emit_signal("animation_over")
		_time_since_start = animation_duration
	var ratio = _time_since_start/animation_duration
	if _fire_type == ActionManager.ActionType.HITSCAN:
		return get_hitscan_keyframe(ratio)
	else:
		return get_wall_keyframe(ratio)

func logWithBase(value, base):
	return log(value) / log(base)

func get_hitscan_keyframe(ratio):
	var keyframes = {}
	var remapped_rotation_ratio = logWithBase(1+(hitscan_log_base-1)*ratio,hitscan_log_base)
	var angle = hitscan_rotation_periods* 2 * PI * remapped_rotation_ratio
	keyframes[front_pivot] =  Transform(
		Basis(Vector3(0,0,angle)),
		Vector3(0,0,_default_front_z))
	
	
	var remapped_scale_ratio = pow(ratio*2,2) if ratio<=0.5 else pow((ratio-1)*2,2)
	var scale = middle_scale_extent * remapped_scale_ratio + _default_middle_scale
	keyframes[middle_pivot] = Transform(
		Basis(Vector3(0,0,angle)),
		Vector3(0,0,_default_middle_z)
	)
	keyframes[middle_pivot].basis = keyframes[middle_pivot].basis.scaled(Vector3(scale,scale,scale))
	return keyframes

func get_wall_keyframe(ratio):
	var keyframes = {}
	var remapped_ratio = abs(1-2*pow(1-ratio,2))
	var scale = remapped_ratio
	keyframes[middle_pivot] =  Transform(
		Basis(Vector3(0,0,0)),
		Vector3(0,0,_default_middle_z))
	keyframes[middle_pivot].basis = keyframes[middle_pivot].basis.scaled(Vector3(scale,scale,scale))
	return keyframes
