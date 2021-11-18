extends BaseAnimator

var _max_time = Constants.get_value("gameplay", "spawn_time")
var _time_since_start = 0

func start_animation():
	_time_since_start = 0

#from: https://easings.net/#easeInCirc
func ease_in_circ(x: float) -> float:
	return 1 - sqrt(1 - pow(x, 2));


#from: https://easings.net/#easeOutElastic
func ease_out_elastic(x: float) -> float:
	var c4 = (2.0 * PI) / 3.0
	return  0.0 if x == 0 else (1.0 if x == 1 else  pow(2.0, -10.0 * x) * sin((x * 10.0 - 0.75) * c4) + 1.0);

#from: https://easings.net/#easeOutBounce
func ease_out_bounce(x: float) -> float: 
	var n1 = 7.5625
	var d1 = 2.75

	if x < 1 / d1 :
		return n1 * x * x
	elif x < 2 / d1:
		x -= 1.5 / d1
		return n1 * x * x + 0.75
	elif x < 2.5 / d1:
		x -= 2.25 / d1
		return n1 * x * x + 0.9375
	else:
		x -= 2.625 / d1
		return n1 * x * x + 0.984375

func get_keyframe(delta):
	if _time_since_start > _max_time:
		_stop_animation()
		_time_since_start = _max_time
	else:
		_time_since_start += delta

	_front_pivot.visible = true
	_middle_pivot.visible = true
	_back_pivot.visible = true
	_reset_keyframes()

	var ratio = _time_since_start/_max_time
	var remapped_ratio_middle = ease_out_elastic(min(ratio*2,1))
	var remapped_ratio_outer_z = ease_out_elastic(max(ratio-0.5, 0)*2)
	var remapped_ratio_outer_scale = ease_out_elastic(max(ratio-0.5, 0)*2)
	
	var middle_scale = _default_scales[_middle_pivot] * remapped_ratio_middle
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.scaled(middle_scale)
	
	var front_z = _default_positions[_front_pivot].z * remapped_ratio_outer_z
	var back_z = _default_positions[_back_pivot].z * remapped_ratio_outer_z
	var front_scale = _default_scales[_front_pivot] * remapped_ratio_outer_scale
	var back_scale = _default_scales[_back_pivot] * remapped_ratio_outer_scale
	_keyframes[_front_pivot].origin.z = front_z
	_keyframes[_back_pivot].origin.z = back_z
	_keyframes[_front_pivot].basis = _keyframes[_front_pivot].basis.scaled(front_scale)
	_keyframes[_back_pivot].basis = _keyframes[_back_pivot].basis.scaled(back_scale)
	return _keyframes

func _stop_animation():
	emit_signal("animation_over")
