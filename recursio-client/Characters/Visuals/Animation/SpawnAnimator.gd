extends BaseAnimator

var _max_time = Constants.get_value("gameplay", "spawn_time")
var _time_since_start = 0

func start_animation():
	_time_since_start = 0

func get_keyframe(delta):
	_reset_keyframes()
	if _time_since_start > _max_time:
		_stop_animation()
		_time_since_start = _max_time
	else:
		_time_since_start += delta
	return _keyframes

func _stop_animation():
	_front_pivot.visible = true
	_middle_pivot.visible = true
	_back_pivot.visible = true
	emit_signal("animation_over")
