extends BaseAnimator

onready var _max_time = Constants.get_value("dash", "max_time")
onready var _back = get_node("../RootPivot/BackPivot/Back")
onready var _back_dash = get_node("../RootPivot/BackPivot/BackDashVariant")
onready var _back_dash_variant = get_node("../RootPivot/BackPivot/BackDash")
onready var _dash_particles_left = get_node("../RootPivot/BackPivot/DashParticlesLeft")
onready var _dash_particles_right = get_node("../RootPivot/BackPivot/DashParticlesRight")

export var after_image_start_offset := 0.2
export var after_image_end_offset := 0.1
export var speed :=50.0

var _rotate_to_zero = false
var _angle = 0
var _time_since_start = 0
var _timeline_index = -1

var _current_position

func _ready():
	var _error =  get_parent().connect("color_scheme_changed",self,"_on_color_scheme_changed")
	_dash_particles_left.lifetime = _max_time
	_dash_particles_right.lifetime = _max_time
	
func start_animation():
	_current_position = _back.global_transform.origin
	_time_since_start = 0
	_rotate_to_zero = false
	_dash_particles_left.emitting = true
	_dash_particles_right.emitting = true
	
	var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
	if _timeline_index != wall_index:
		_back_dash.show()
	else:
		_back_dash_variant.show()

func _on_color_scheme_changed(new_color_scheme, timeline_index):
	
	var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
	var accent_type = "primary" if wall_index != timeline_index else "secondary"
	var accent_color_name = new_color_scheme+"_"+accent_type+"_accent"
	var main_color_name = new_color_scheme + "_main"
	ColorManager.color_object_by_method(main_color_name, _back_dash_variant.material_override, "set_shader_param", ["color"])
	ColorManager.color_object_by_method(main_color_name, _back_dash.material_override, "set_shader_param", ["color"])
	ColorManager.color_object_by_property(accent_color_name, _dash_particles_left.material_override, "albedo_color")
	ColorManager.color_object_by_property(accent_color_name, _dash_particles_right.material_override, "albedo_color")
	_timeline_index = timeline_index

func stop_animation():
	_rotate_to_zero = true
	_dash_particles_left.emitting = false
	_dash_particles_right.emitting = false
	_back_dash.hide()
	_back_dash_variant.hide()

func get_keyframe(delta):
	_time_since_start += delta
	if _time_since_start > _max_time:
		stop_animation()
	if _time_since_start > _max_time * after_image_start_offset:
		if _time_since_start < _max_time * (1.0 - after_image_end_offset):
			_current_position = lerp(_current_position,_back.global_transform.origin, 0.01)
		else:
			var t = (_time_since_start - _max_time * (1.0 - after_image_end_offset))/(_max_time * after_image_end_offset)
			_current_position = lerp(_current_position,_back.global_transform.origin, t)
	
	_back_dash.global_transform.origin = _current_position
	_back_dash_variant.global_transform.origin = _current_position
		
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
