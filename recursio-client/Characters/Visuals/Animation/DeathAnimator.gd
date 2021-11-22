extends BaseAnimator

onready var _front = get_node("../RootPivot/FrontPivot/Front")
onready var _front_variant = get_node("../RootPivot/FrontPivot/FrontVariant")
onready var _middle = get_node("../RootPivot/MiddlePivot/Middle")
onready var _middle_death_variant = get_node("../RootPivot/MiddlePivot/MiddleDeathVariant")
onready var _middle_death_front_particles = get_node("../RootPivot/MiddleDeathFrontParticles")
onready var _middle_death_back_particles = get_node("../RootPivot/MiddleDeathBackParticles")
onready var _back = get_node("../RootPivot/BackPivot/Back")
onready var _back_variant = get_node("../RootPivot/BackPivot/BackVariant")


export var emission_energy_extent := 15.0
export var front_extent := 1.0
export var back_extent := -1.0
export var middle_scale_extent := 0.15
export var middle_rotation_periods := 2

var _max_time = Constants.get_value("gameplay", "death_time")
var _time_since_start = 0
var _default_color 



var _middle_scale_extents = []

func _ready():
	_middle_death_front_particles.lifetime = _max_time
	_middle_death_back_particles.lifetime = _max_time

func _on_color_scheme_changed(new_color_scheme, timeline_index):
	var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
	var accent_type = "primary" if wall_index != timeline_index else "secondary"
	var accent_color = Color(Constants.get_value("colors", new_color_scheme+"_"+accent_type+"_accent"))
	var main_color = Color(Constants.get_value("colors",new_color_scheme + "_main"))
	_middle_death_variant.material_override.emission = accent_color
	_middle_death_variant.material_override.albedo_color = accent_color
	_middle_death_front_particles.material_override.albedo_color = main_color
	_middle_death_front_particles.material_override.emission =main_color
	_middle_death_back_particles.material_override.albedo_color = main_color
	_middle_death_back_particles.material_override.emission = main_color
	
func start_animation():
	_time_since_start = 0

	_front.set_layer_mask_bit(0, true)
	_front.set_layer_mask_bit(9, false)
	_front_variant.set_layer_mask_bit(0, true)
	_front_variant.set_layer_mask_bit(9, false)
	_middle.visible = false
	_middle_death_variant.visible = true
	_back.set_layer_mask_bit(0, true)
	_back.set_layer_mask_bit(9, false)
	_back_variant.set_layer_mask_bit(0, true)
	_back_variant.set_layer_mask_bit(9, false)
	randomize()
	_middle_scale_extents.clear()
	_middle_scale_extents.append(rand_range(0.5*middle_scale_extent, middle_scale_extent))
	_middle_scale_extents.append(rand_range(0.5*middle_scale_extent, middle_scale_extent))
	_middle_scale_extents.append(rand_range(0.5*middle_scale_extent, middle_scale_extent))
	_middle_death_variant.material_override.emission_energy = 0
	_middle_death_back_particles.material_override.emission_energy = 0
	_middle_death_front_particles.material_override.emission_energy = 0
	_middle_death_front_particles.restart()
	_middle_death_back_particles.restart()

#from: https://easings.net/#easeOutBack
func _ease_out_back(x):
	var c1 = 1.70158;
	var c3 = c1 + 1;
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0);


func get_keyframe(delta):
	_reset_keyframes()
	if _time_since_start > _max_time:
		_stop_animation()
		_time_since_start = _max_time
	else:
		_time_since_start += delta
	
	var ratio = _time_since_start/_max_time
	var remapped_ratio = _ease_out_back(ratio)
	
	var z_front = front_extent * remapped_ratio + _default_positions[_front_pivot].z
	_keyframes[_front_pivot].origin.z = z_front
	var z_back = back_extent * remapped_ratio + _default_positions[_back_pivot].z
	_keyframes[_back_pivot].origin.z = z_back
	
	var scale = _default_scales[_middle_pivot] + Vector3(_middle_scale_extents[0]*remapped_ratio, _middle_scale_extents[1]*remapped_ratio, _middle_scale_extents[2]*remapped_ratio)
	var angle_middle = remapped_ratio * 2*PI * middle_rotation_periods
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.rotated(Vector3(0,0,1),angle_middle)
	_keyframes[_middle_pivot].basis = _keyframes[_middle_pivot].basis.scaled(scale)
	
	_middle_death_back_particles.material_override.emission_energy = remapped_ratio * emission_energy_extent
	_middle_death_front_particles.material_override.emission_energy = remapped_ratio * emission_energy_extent
	_middle_death_variant.material_override.emission_energy = remapped_ratio * emission_energy_extent
	
	return _keyframes

func _stop_animation():
	_front_pivot.visible = false
	_middle_pivot.visible = false
	_back_pivot.visible = false
	_front.set_layer_mask_bit(0, false)
	_front.set_layer_mask_bit(9, true)
	_front_variant.set_layer_mask_bit(0, false)
	_front_variant.set_layer_mask_bit(9, true)
	_middle.visible = true
	_middle_death_variant.visible = false
	_back.set_layer_mask_bit(0, false)
	_back.set_layer_mask_bit(9, true)
	_back_variant.set_layer_mask_bit(0, false)
	_back_variant.set_layer_mask_bit(9, true)
	emit_signal("animation_over")
