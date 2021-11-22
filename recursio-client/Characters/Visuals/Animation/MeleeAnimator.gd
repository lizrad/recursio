extends BaseAnimator

export var front_extent := 0.75
export var front_x_scale_extent := 0.85
export var middle_z_extent := 0.375
export var middle_scale_extent := 0.3
export var middle_rotation_periods := 2


onready var _front = get_node("../RootPivot/FrontPivot/Front")
onready var _front_variant = get_node("../RootPivot/FrontPivot/FrontVariant")
onready var _front_melee_attack = get_node("../RootPivot/FrontPivot/FrontMeleeAttack")
onready var _front_melee_attack_variant = get_node("../RootPivot/FrontPivot/FrontMeleeAttackVariant")
onready var _melee_particles_left = get_node("../RootPivot/FrontPivot/MeleeParticlesLeft")
onready var _melee_particles_right = get_node("../RootPivot/FrontPivot/MeleeParticlesRight")
onready var _max_time = Constants.get_value("melee", "max_time")

var _time_since_start = 0
var _timeline_index = 0

func _ready():
	var _error =  get_parent().connect("color_scheme_changed",self,"_on_color_scheme_changed")


func _on_color_scheme_changed(new_color_scheme, timeline_index):
	_timeline_index = timeline_index
	var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
	var accent_type = "primary" if wall_index != timeline_index else "secondary"
	var attack_color = Color(Constants.get_value("colors", new_color_scheme+"_"+accent_type+"_accent"))
	_front_melee_attack.material_override.albedo_color = attack_color
	_front_melee_attack_variant.material_override.albedo_color = attack_color
	_front_melee_attack.material_override.emission = attack_color
	_front_melee_attack_variant.material_override.emission = attack_color
	_melee_particles_left.material_override.emission = attack_color
	_melee_particles_right.material_override.emission = attack_color
	
func start_animation():
	_time_since_start = 0
	_front.hide()
	_front_variant.hide()
	var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
	if _timeline_index == wall_index:
		_front_melee_attack_variant.show()
	else:	
		_front_melee_attack.show()
	_melee_particles_left.emitting=true
	_melee_particles_right.emitting=true

func get_keyframe(delta):
	_reset_keyframes()
	
	if _time_since_start > _max_time:
		emit_signal("animation_over")
		_front_melee_attack_variant.hide()
		_front_melee_attack.hide()
		var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
		if _timeline_index == wall_index:
			_front_variant.show()
		else:	
			_front.show()
		_time_since_start = _max_time
	else:
		_time_since_start += delta
	
	var ratio = _time_since_start/_max_time
	if ratio >=0.35 and _melee_particles_left.emitting:
		_melee_particles_left.emitting = false
		_melee_particles_right.emitting = false
		
	var remapped_ratio = pow(ratio*2,2) if ratio<=0.5 else pow((ratio-1)*2,2)
	var z_front = front_extent * remapped_ratio + _default_positions[_front_pivot].z
	_keyframes[_front_pivot].origin.z = z_front
	var x_scale_front = front_x_scale_extent * remapped_ratio + _default_scales[_front_pivot].x
	var scale_front = Vector3(x_scale_front, _default_scales[_front_pivot].y, _default_scales[_front_pivot].z)
	_keyframes[_front_pivot].basis = _keyframes[_front_pivot].basis.scaled(scale_front)
	
	var angle_middle = ratio * 2*PI * middle_rotation_periods
	var z_middle = middle_z_extent * remapped_ratio + _default_positions[_middle_pivot].z
	var scale_middle = _default_scales[_middle_pivot] + Vector3(middle_scale_extent * remapped_ratio ,0,0)
	_keyframes[_middle_pivot].origin.z = z_middle
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.rotated(Vector3(0,0,1),angle_middle)
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.scaled(scale_middle)
	return _keyframes
