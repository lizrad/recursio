extends BaseAnimator

onready var _spawn_particles = get_node("../RootPivot/SpawnParticles")
onready var _middle = get_node("../RootPivot/MiddlePivot/Middle")

var _max_time = Constants.get_value("gameplay", "spawn_time")
var _time_since_start = 0


func _ready():
	var _error =  get_parent().connect("color_scheme_changed",self,"_on_color_scheme_changed")
	_spawn_particles.lifetime = _max_time;

func _on_color_scheme_changed(new_color_scheme, timeline_index):
	var main_color = Color(Constants.get_value("colors",new_color_scheme + "_main"))
	_spawn_particles.material_override.albedo_color = main_color
	_spawn_particles.material_override.emission = main_color


func start_animation():
	_time_since_start = 0
	_spawn_particles.restart()

#adapted from: https://easings.net/#easeOutElastic
func ease_out_elastic(x: float, wobble: float) -> float:
	var c4 = (2.0 * PI) / 3.0
	return 0.0 if x == 0 else (1.0 if x == 1 else  pow(2.0, -10.0 * x) * sin((x * wobble - 0.75) * c4) + 1.0);


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
	var remapped_ratio_middle = pow(ease_out_elastic(min(ratio*2, 1), 20),2)
	var remapped_ratio_outer_z = ease_out_elastic(max(ratio-0.5, 0)*2,10)
	var remapped_ratio_outer_scale = ease_out_elastic(max(ratio-0.5, 0)*2,10)
	
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
