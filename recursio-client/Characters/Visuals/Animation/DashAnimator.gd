extends BaseAnimator


onready var _max_time = Constants.get_value("dash", "max_time")

export var speed :=50.0

var _rotate_to_zero = false
var _angle = 0
var _time_since_start = 0
func start_animation():
	_time_since_start = 0
	_rotate_to_zero = false
	
func stop_animation():
	_rotate_to_zero = true

func get_keyframe(delta):
	#TODO: this is just a hacky solution so dash always stops after 0.5 second
	_time_since_start += delta
	if _time_since_start > _max_time:
		stop_animation()
	_reset_keyframes()
	_angle += delta*speed
	if _angle >= 2*PI:
		if _rotate_to_zero:
			_angle = 2*PI
			emit_signal("animation_over")
		else:
			_angle-=2*PI
	_keyframes[_back_pivot].basis = _keyframes[_back_pivot].basis.rotated(Vector3(0,0,1),_angle)
	return _keyframes
