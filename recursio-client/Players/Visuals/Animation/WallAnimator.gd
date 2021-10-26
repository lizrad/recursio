extends BaseAnimator

export var animation_duration := 0.5


var _time_since_start = 0

func start_animation():
	_time_since_start = 0

func get_keyframe(delta):
	_reset_keyframes()
	_time_since_start += delta
	if _time_since_start > animation_duration:
		emit_signal("animation_over")
		_time_since_start = animation_duration
	var ratio = _time_since_start/animation_duration
	
	var remapped_ratio = abs(1-2*pow(1-ratio,2))
	var scale = Vector3(remapped_ratio,remapped_ratio,remapped_ratio)
	_keyframes[_middle_pivot].basis = _keyframes[_front_pivot].basis.scaled(scale)
	return _keyframes
