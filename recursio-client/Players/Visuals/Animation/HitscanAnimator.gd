extends BaseAnimator

export var animation_duration := 0.5
export var hitscan_rotation_periods := 10
export var hitscan_log_base := 3000
export var middle_scale_extent := 0.35
export var front_scale_extent := 0.35


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
	
	var remapped_rotation_ratio = logWithBase(1+(hitscan_log_base-1)*ratio,hitscan_log_base)
	var remapped_scale_ratio = pow(ratio*2,2) if ratio<=0.5 else pow((ratio-1)*2,2)
	
	var angle = hitscan_rotation_periods* 2 * PI * remapped_rotation_ratio
	
	var front_scale = Vector3(front_scale_extent,front_scale_extent,front_scale_extent) * remapped_scale_ratio + _default_scales[_front_pivot]
	_keyframes[_front_pivot].basis = _keyframes[_front_pivot].basis.rotated(Vector3(0,0,1),angle)
	_keyframes[_front_pivot].basis = _keyframes[_front_pivot].basis.scaled(front_scale)
	
	
	var middle_scale = Vector3(middle_scale_extent,middle_scale_extent,middle_scale_extent) * remapped_scale_ratio + _default_scales[_middle_pivot]
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.rotated(Vector3(0,0,1),angle)
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.scaled(middle_scale)
	
	return _keyframes

func logWithBase(value, base):
	return log(value) / log(base)
