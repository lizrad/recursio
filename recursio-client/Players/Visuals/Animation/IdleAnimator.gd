extends Node

export var front_idle_movement_extent:= 0.1
export var front_idle_movement_speed := 1.0
export var front_idle_movement_offset := 0.0
export var back_idle_movement_extent:= -0.1
export var back_idle_movement_speed := 1.0
export var back_idle_movement_offset := 0

export var middle_shiver_timer_range = Vector2(3,8)
export var middle_shiver_extent = Vector2(0.1*PI,0.5*PI)
export var middle_shiver_speed = Vector2(3,8)
export var middle_shiver_periods = Vector2(1,3)

onready var front_pivot = get_node("../RootPivot/FrontPivot")
onready var middle_pivot = get_node("../RootPivot/MiddlePivot")
onready var back_pivot = get_node("../RootPivot/BackPivot")
onready var root_pivot = get_node("../RootPivot")

var _middle_shiver_timer = 0
var _middle_shiver_extent = 0
var _middle_shiver_speed = 0
var _middle_shiver_periods = 0


var _rng = RandomNumberGenerator.new()

var _idle_phases:={}
var _default_zs:= {}

func _ready():
	_rng.randomize()
	_middle_shiver_timer = middle_shiver_timer_range.x + (middle_shiver_timer_range.y-middle_shiver_timer_range.x)*randf()
	_middle_shiver_speed = middle_shiver_speed.x + (middle_shiver_speed.y-middle_shiver_speed.x)*randf()
	_middle_shiver_extent = middle_shiver_extent.x + (middle_shiver_extent.y-middle_shiver_extent.x)*randf()
	_middle_shiver_periods = middle_shiver_periods.x + randi()%int(middle_shiver_periods.y-middle_shiver_periods.x)
	_idle_phases[front_pivot] = 0.0
	_idle_phases[back_pivot] = 0.0
	_default_zs[front_pivot] = front_pivot.transform.origin.z
	_default_zs[back_pivot] = back_pivot.transform.origin.z
	
func get_keyframe(delta):
	var keyframes = {}
	keyframes[front_pivot]= _create_idle_movement_keyframe(delta, front_pivot, front_idle_movement_speed, front_idle_movement_offset, front_idle_movement_extent)
	keyframes[back_pivot]= _create_idle_movement_keyframe(delta, back_pivot, back_idle_movement_speed, back_idle_movement_offset, back_idle_movement_extent)
	
	_middle_shiver_timer-=delta
	if _middle_shiver_timer<=0:
		keyframes[middle_pivot] = _create_middle_shiver_keyframe(delta)
	return keyframes


var _middle_rotation_phase = 0.0
func _create_middle_shiver_keyframe(delta:float):
	_middle_rotation_phase += delta * _middle_shiver_speed
	if(_middle_rotation_phase >= PI*2):
		_middle_shiver_periods-=1
		_middle_shiver_speed = middle_shiver_speed.x + (middle_shiver_speed.y-middle_shiver_speed.x)*randf()
		_middle_shiver_extent = middle_shiver_extent.x + (middle_shiver_extent.y-middle_shiver_extent.x)*randf()
		_middle_rotation_phase -= PI*2
		if _middle_shiver_periods<=0:
			_middle_shiver_periods = middle_shiver_periods.x + randi()%int(middle_shiver_periods.y-middle_shiver_periods.x)
			_middle_shiver_timer = middle_shiver_timer_range.x + (middle_shiver_timer_range.y-middle_shiver_timer_range.x)*randf()
	var sin_value = sin(_middle_rotation_phase)
	var angle = _middle_shiver_speed * sin_value
	var keyframe = Transform(
		Basis(Vector3(0,0,angle)),
		Vector3(0,0,0))
	return keyframe

func _create_idle_movement_keyframe(delta: float, part:Node, speed:float, offset:float,  extent: float ):
	_idle_phases[part] += delta * speed
	_idle_phases[part] = _idle_phases[part] if _idle_phases[part] <= 2.0 * PI else 0
	var sin_value = sin(_idle_phases[part]+offset)
	var z = _default_zs[part] + extent - sin_value * extent
	var keyframe = Transform(
		Basis(Vector3(0,0,0)),
		Vector3(0,0,z))
	return keyframe
