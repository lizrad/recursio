extends BaseAnimator


export var speed :=50.0

var _rotate_to_zero = false
var _angle = 0

func start_animation():
	_rotate_to_zero = false
	
func stop_animation():
	_rotate_to_zero = true

func get_keyframe(delta):
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
