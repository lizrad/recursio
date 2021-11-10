extends BaseAnimator

export var front_extent := 0.75
export var middle_z_extent := 0.375
export var middle_scale_extent := 0.3
export var middle_rotation_periods := 2

var _attack_color = Color.tomato

onready var _front = get_node("../RootPivot/FrontPivot/Front")
onready var _front_variant = get_node("../RootPivot/FrontPivot/FrontVariant")
onready var _max_time = Constants.get_value("melee", "max_time")

var _time_since_start = 0
var _default_color 

func _ready():
	var _error =  get_parent().connect("color_scheme_changed",self,"_on_color_scheme_changed")

func _on_color_scheme_changed(new_color_scheme, timeline_index):
	var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
	var accent_type = "primary" if wall_index != timeline_index else "secondary"
	_attack_color= Color(Constants.get_value("colors", new_color_scheme+"_"+accent_type+"_accent"))
	_default_color = Color(Constants.get_value("colors",new_color_scheme + "_main"))
	
func start_animation():
	_time_since_start = 0
	_front.material_override.set_shader_param("color",_attack_color)
	_front_variant.material_override.set_shader_param("color",_attack_color)

func get_keyframe(delta):
	_reset_keyframes()
	
	if _time_since_start > _max_time:
		emit_signal("animation_over")
		_front.material_override.set_shader_param("color",_default_color)
		_front_variant.material_override.set_shader_param("color",_default_color)
		_time_since_start = _max_time
	else:
		_time_since_start += delta
	
	var ratio = _time_since_start/_max_time
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
