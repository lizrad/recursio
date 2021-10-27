extends BaseAnimator

export var animation_duration := 0.2
export var front_extent := 0.75
export var middle_z_extent := 0.375
export var middle_scale_extent := 0.3
export var middle_rotation_periods := 2
export var attack_color = Color.tomato

onready var front = get_node("../RootPivot/FrontPivot/Front")

var _time_since_start = 0
var _default_color 


func start_animation():
	_default_color = front.material_override.albedo_color
	_time_since_start = 0
	front.material_override.albedo_color = attack_color

func get_keyframe(delta):
	_reset_keyframes()
	
	if _time_since_start > animation_duration:
		emit_signal("animation_over")
		front.material_override.albedo_color = _default_color
		_time_since_start = animation_duration
	else:
		_time_since_start += delta
	
	var ratio = _time_since_start/animation_duration
	var remapped_ratio = pow(ratio*2,2) if ratio<=0.5 else pow((ratio-1)*2,2)
	var z_front = front_extent * remapped_ratio + _default_positions[_front_pivot].z
	_keyframes[_front_pivot].origin.z = z_front
	
	var angle_middle = ratio * 2*PI * middle_rotation_periods
	var z_middle = middle_z_extent * remapped_ratio + _default_positions[_middle_pivot].z
	var scale = _default_scales[_middle_pivot] + Vector3(middle_scale_extent * remapped_ratio ,0,0)
	_keyframes[_middle_pivot].origin.z = z_middle
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.rotated(Vector3(0,0,1),angle_middle)
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.scaled(scale)
	return _keyframes
