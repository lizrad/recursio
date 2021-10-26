extends BaseAnimator

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


var _middle_shiver_timer = 0
var _middle_shiver_extent = 0
var _middle_shiver_speed = 0
var _middle_shiver_periods = 0


var _rng = RandomNumberGenerator.new()

var _idle_phases:={}

func _ready():
	_rng.randomize()
	_middle_shiver_timer = middle_shiver_timer_range.x + (middle_shiver_timer_range.y-middle_shiver_timer_range.x)*randf()
	_middle_shiver_speed = middle_shiver_speed.x + (middle_shiver_speed.y-middle_shiver_speed.x)*randf()
	_middle_shiver_extent = middle_shiver_extent.x + (middle_shiver_extent.y-middle_shiver_extent.x)*randf()
	_middle_shiver_periods = middle_shiver_periods.x + randi()%int(middle_shiver_periods.y-middle_shiver_periods.x)
	_idle_phases[_front_pivot] = 0.0
	_idle_phases[_back_pivot] = 0.0
	
func get_keyframe(delta):
	_reset_keyframes()
	_keyframes[_front_pivot].origin.z = _calculate_position_z(delta, _front_pivot, front_idle_movement_speed, front_idle_movement_offset, front_idle_movement_extent)
	_keyframes[_back_pivot].origin.z = _calculate_position_z(delta, _back_pivot, back_idle_movement_speed, back_idle_movement_offset, back_idle_movement_extent)
	
	_middle_shiver_timer-=delta
	if _middle_shiver_timer<=0:
		_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.rotated(Vector3(0,0,1),_calculate_shiver_angle(delta))
	return _keyframes


var _middle_rotation_phase = 0.0
func _calculate_shiver_angle(delta:float):
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
	return angle

func _calculate_position_z(delta: float, pivot:Node, speed:float, offset:float,  extent: float ):
	_idle_phases[pivot] += delta * speed
	_idle_phases[pivot] = _idle_phases[pivot] if _idle_phases[pivot] <= 2.0 * PI else 0
	var sin_value = sin(_idle_phases[pivot]+offset)
	var z = _default_positions[pivot].z + extent - sin_value * extent
	return z
