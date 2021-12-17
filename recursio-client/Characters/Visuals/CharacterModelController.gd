extends Node
class_name CharacterModel

signal color_scheme_changed(new_color_scheme, timeline_index)
export(String, "player", "enemy", "player_ghost", "enemy_ghost") var color_scheme = "player"

onready var _animator = get_node("Animator")
onready var _front = get_node("RootPivot/FrontPivot/Front")
onready var _front_variant = get_node("RootPivot/FrontPivot/FrontVariant")
onready var _middle = get_node("RootPivot/MiddlePivot/Middle")
onready var _back_dash = get_node("RootPivot/BackPivot/BackDash")
onready var _back_dash_variant = get_node("RootPivot/BackPivot/BackDashVariant")
onready var _back = get_node("RootPivot/BackPivot/Back")
onready var _back_variant = get_node("RootPivot/BackPivot/BackVariant")
onready var _parent = get_parent().get_parent()
var _death_particles_scene = preload("res://Characters/Visuals/Particles/DeathParticles.tscn")
var _death_particles

func _ready():
	#local to scene and make unique are the biggest piles of unusable trash i have ever seen, so im brute forcing this shit get at me bruh
	_front.material_override = _front.material_override.duplicate(true)
	_front_variant.material_override = _front_variant.material_override.duplicate(true)
	_middle.material_override = _middle.material_override.duplicate(true)
	_back.material_override = _back.material_override.duplicate(true)
	_back_variant.material_override = _back_variant.material_override.duplicate(true)
	
	_death_particles = _death_particles_scene.instance()
	_parent.call_deferred("add_child",_death_particles)
	_set_color_scheme(color_scheme, _parent.timeline_index)
	_set_variant(_parent.timeline_index)
	var _error = _parent.connect("action_status_changed",self,"_on_action_status_changed")
	_error = _parent.connect("velocity_changed",self,"_on_velocity_changed")
	_error = _parent.connect("timeline_index_changed",self,"_on_timeline_index_changed")
	_error = _parent.connect("dying",self,"_on_death")
	_error = _parent.connect("spawning",self,"_on_spawn")
	_error = _parent.connect("non_vfx_spawn",self,"_on_non_vfx_spawn")
	_error = _animator.connect("death_animation_over", self, "_on_death_animation_over")
	_error = _parent.connect("animation_status_changed",self,"_on_animation_status_changed")

func set_shader_param(param, value):
	_front.material_override.set_shader_param(param, value)
	_front_variant.material_override.set_shader_param(param, value)
	_middle.material_override.set_shader_param(param, value)
	_middle.material_override.set_shader_param(param, value)
	_back.material_override.set_shader_param(param, value)
	_back_variant.material_override.set_shader_param(param, value)
	_back_dash.material_override.set_shader_param(param, value)
	_back_dash_variant.material_override.set_shader_param(param, value)


func _set_color_scheme(new_color_scheme:String, timeline_index):
	var color_parameter = "color"
	var main_color_name = new_color_scheme + "_main"
	ColorManager.color_object_by_method(main_color_name,_front.material_override, "set_shader_param", [color_parameter])
	ColorManager.color_object_by_method(main_color_name,_front_variant.material_override, "set_shader_param", [color_parameter])

	var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
	var accent_type = "primary" if wall_index != timeline_index else "secondary"
	var accent_color_name = new_color_scheme + "_"+accent_type + "_accent"
	ColorManager.color_object_by_method(accent_color_name,_middle.material_override, "set_shader_param", [color_parameter])

	ColorManager.color_object_by_method(main_color_name,_back.material_override, "set_shader_param", [color_parameter])
	ColorManager.color_object_by_method(main_color_name,_back_variant.material_override, "set_shader_param", [color_parameter])
	
	ColorManager.color_object_by_property(accent_color_name, _death_particles.material_override, "emission")
	emit_signal("color_scheme_changed", new_color_scheme, timeline_index)


func _set_variant(timeline_index):
	var wall_index = Constants.get_value("ghosts", "wall_placing_timeline_index")
	var variant_active = timeline_index == wall_index
	_front_variant.visible = variant_active
	_back_variant.visible = variant_active
	_front.visible = not variant_active
	_back.visible = not variant_active


func _on_action_status_changed(action_type, status):
	_animator.action_status_changed(action_type, status)


func _on_velocity_changed(velocity, front_vector, right_vector):
	_animator.velocity_changed(velocity, front_vector, right_vector)


func _on_timeline_index_changed(timeline_index):
	_set_color_scheme(color_scheme, timeline_index)
	_set_variant(timeline_index)

func _on_animation_status_changed(value):
	_animator.toggle_animation(value)

func _on_death():
	_death_particles.transform.origin = _parent.get_position()
	_animator.death_active()

func _on_spawn():
	_animator.spawn_active()
	
func _on_non_vfx_spawn():
	_animator.non_vfx_spawn()

func _on_death_animation_over():
	_death_particles.emitting = true
