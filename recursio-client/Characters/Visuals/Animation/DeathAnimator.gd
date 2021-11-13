extends BaseAnimator

export var middle_scale_extent := 0.3

var _max_time = 0.2
var _time_since_start = 0
var _default_color 


func start_animation():
	_time_since_start = 0

#from: https://easings.net/#easeInOutBack
func _ease_out_back(x):
	var c1 = 1.70158;
	var c3 = c1 + 1;
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0);


func get_keyframe(delta):
	_reset_keyframes()
	
	if _time_since_start > _max_time:
		emit_signal("animation_over")
		_time_since_start = _max_time
	else:
		_time_since_start += delta
	
	var ratio = _time_since_start/_max_time
	var remapped_ratio = _ease_out_back(ratio)
	
	var new_scale = middle_scale_extent * ratio
	var scale = _default_scales[_middle_pivot] + Vector3(new_scale, new_scale, new_scale)
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.scaled(scale)
	return _keyframes

