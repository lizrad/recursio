extends Node

signal animation_over

export var min_velocity := 0.5
export var middle_speed := 1.0
export var back_speed := 5.0
export var back_rotation_extent := PI*0.25

onready var back_pivot = get_node("../RootPivot/BackPivot")
onready var middle_pivot = get_node("../RootPivot/MiddlePivot")
onready var front_pivot = get_node("../RootPivot/FrontPivot")

var _rotate_to_zero := false
var _middle_phase := 0.0
var _middle_speed :=0.0
var _back_phase := 0.0
var _velocity := 0.0
var _default_back_z := -0.567
var _start_back_z  := -0.567
var _start_front_z  := 0.548
var _z_lerp_weight := 0.0

func start_animation():
	_rotate_to_zero = false
	_start_back_z = back_pivot.transform.origin.z
	_start_front_z = front_pivot.transform.origin.z
	_z_lerp_weight = 0.0
	_middle_speed=middle_speed
	
func stop_animation():
	_rotate_to_zero = true
	_velocity = min_velocity
	_middle_speed=middle_speed*10

func set_velocity(velocity):
	_velocity = max(velocity,min_velocity)

func get_keyframe(delta):
	var keyframes = {}
	
	if not (_rotate_to_zero and _middle_phase == 0 ):
		_middle_phase += delta*_middle_speed*_velocity
	if not (_rotate_to_zero and  _back_phase == 0):
		_back_phase += delta*back_speed*_velocity
	
	
	_z_lerp_weight = min(_z_lerp_weight + 0.025,1.0) if not _rotate_to_zero else max(_z_lerp_weight - 0.025,0.0) 
	var back_z = lerp(_start_back_z, _default_back_z, _z_lerp_weight)
	
	if _middle_phase >= 2*PI:
		if _rotate_to_zero:
			_middle_phase = 0
		else:
			_middle_phase-=2*PI
			
	if _back_phase >= 2*PI:
		if _rotate_to_zero:
			_back_phase = 0
		else:
			_back_phase-=2*PI
	var back_angle = sin(_back_phase) * back_rotation_extent
	
	if _rotate_to_zero and _middle_phase == 0 and _back_phase == 0 and _z_lerp_weight == 0:
		emit_signal("animation_over")
	
	keyframes[back_pivot] =  Transform(
		Basis(Vector3(0,0,back_angle)),
		Vector3(0,0,back_z))
	var middle_angle = _middle_phase
	keyframes[middle_pivot] =  Transform(
		Basis(Vector3(0,0,middle_angle)),
		Vector3(0,0,0))
	keyframes[front_pivot] =  Transform(
		Basis(Vector3(0,0,0)),
		Vector3(0,0,_start_front_z))
	return keyframes
