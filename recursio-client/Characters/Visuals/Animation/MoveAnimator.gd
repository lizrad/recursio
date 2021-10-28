extends BaseAnimator

export var min_velocity := 0.5
export var middle_speed := 1.0
export var back_speed := 5.0
export var max_back_rotation_extent := PI*0.25
export var max_velocity := 3.0

var _rotate_to_zero := false
var _middle_phase := 0.0
var _back_phase := 0.0
var _velocity := 0.0
var _middle_rotate_to_zero_phase_stop = 2*PI
var _back_rotate_to_zero_phase_stop = 2*PI


func start_animation():
	_rotate_to_zero = false
	
func stop_animation():
	_rotate_to_zero = true
	_velocity = min_velocity
	_middle_rotate_to_zero_phase_stop = PI if _middle_phase<PI else 2*PI
	_back_rotate_to_zero_phase_stop = PI if _back_phase<PI else 2*PI

func set_velocity(velocity):
	if _rotate_to_zero:
		return
	_velocity = max(velocity,min_velocity)
	

func get_keyframe(delta):
	_reset_keyframes()
	
	if not (_rotate_to_zero and _middle_phase == 0 ):
		_middle_phase += delta * middle_speed
	if not (_rotate_to_zero and  _back_phase == 0):
		_back_phase += delta*back_speed
	
	if _rotate_to_zero:
		if _middle_phase >_middle_rotate_to_zero_phase_stop:
			_middle_phase = 0
		if _back_phase >_back_rotate_to_zero_phase_stop:
			_back_phase = 0
	else:
		if _middle_phase >= 2*PI:
			_middle_phase-=2*PI
		if _back_phase >= 2*PI:
			_back_phase-=2*PI
	
	if _rotate_to_zero and _middle_phase == 0 and _back_phase == 0:
		emit_signal("animation_over")
	
	var ratio = _velocity/max_velocity
	var back_angle = sin(_back_phase) * max_back_rotation_extent *ratio
	_keyframes[_back_pivot].basis = _keyframes[_back_pivot].basis.rotated(Vector3(0,0,1),back_angle)
	var middle_angle = _middle_phase*ratio
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.rotated(Vector3(0,0,1),middle_angle)
	
	return _keyframes
