extends Node

export var speed := 5.0
export var back_rotation_extent := PI*0.25

onready var back_pivot = get_node("../RootPivot/BackPivot")
onready var middle_pivot = get_node("../RootPivot/MiddlePivot")

var _rotate_to_zero := false
var _phase := 0.0
var _velocity := 0.0
var _default_back_z := -0.567
var _start_back_z  := -0.567
var _z_lerp_weight := 0.0

func start_animation():
	_rotate_to_zero = false
	_start_back_z = back_pivot.transform.origin.z
	_z_lerp_weight = 0.0
	
func stop_animation():
	_rotate_to_zero = true
	_velocity = 0

func set_velocity(velocity):
	_velocity = velocity

func get_keyframe(delta):
	var keyframes = {}
	_phase += delta*speed*_velocity
	var angle = sin(_phase) * back_rotation_extent
#	if _angle >= 2*PI:
#		if _rotate_to_zero:
#			_angle = 2*PI
#			emit_signal("animaton_over")
#		else:
#			_angle-=2*PI
	_z_lerp_weight = min(_z_lerp_weight + 0.025,1.0)
	var back_z = lerp(_start_back_z, _default_back_z, _z_lerp_weight)
	print(back_z)
	keyframes[back_pivot] =  Transform(
		Basis(Vector3(0,0,angle)),
		Vector3(0,0,back_z))
	return keyframes
