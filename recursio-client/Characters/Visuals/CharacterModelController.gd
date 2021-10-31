extends Node
class_name CharacterModel

signal color_scheme_changed(new_color_scheme)
export(String, "player", "enemy", "player_ghost", "enemy_ghost") var color_scheme = "player"

onready var animator = get_node("Animator")
onready var _front = get_node("RootPivot/FrontPivot/Front")
onready var _front_variant = get_node("RootPivot/FrontPivot/FrontVariant")
onready var _middle = get_node("RootPivot/MiddlePivot/Middle")
onready var _back = get_node("RootPivot/BackPivot/Back")
onready var _back_variant = get_node("RootPivot/BackPivot/BackVariant")
onready var _parent = get_parent().get_parent()
func _ready():
	#local to scene and make unique are the biggest piles of unusable trash i have ever seen, so im brute forcing this shit get at me bruh
	_front.material_override = _front.material_override.duplicate(true)
	_front_variant.material_override = _front_variant.material_override.duplicate(true)
	_middle.material_override = _middle.material_override.duplicate(true)
	_back.material_override = _back.material_override.duplicate(true)
	_back_variant.material_override = _back_variant.material_override.duplicate(true)
	_set_color_scheme(color_scheme, _parent.timeline_index)
	_set_variant(_parent.timeline_index)
	_parent.connect("action_status_changed",self,"_on_action_status_changed")
	_parent.connect("velocity_changed",self,"_on_velocity_changed")
	_parent.connect("timeline_index_changed",self,"_on_timeline_index_changed")

	
func set_shader_param(param, value):
	_front.material_override.set_shader_param(param, value)
	_front_variant.material_override.set_shader_param(param, value)
	_middle.material_override.set_shader_param(param, value)
	_back.material_override.set_shader_param(param, value)
	_back_variant.material_override.set_shader_param(param, value)

func _set_color_scheme(new_color_scheme:String, timeline_index):
	emit_signal("color_scheme_changed",new_color_scheme)
	var color_parameter = "color"
	_front.material_override.set_shader_param(color_parameter, Color(Constants.get_value("colors", new_color_scheme+"_main"))) 
	_front_variant.material_override.set_shader_param(color_parameter, Color(Constants.get_value("colors", new_color_scheme+"_main"))) 
	
	var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
	var accent_type = "primary" if wall_index != timeline_index else "secondary"
	_middle.material_override.set_shader_param(color_parameter,Color(Constants.get_value("colors", new_color_scheme+"_"+accent_type+"_accent")))
	
	_back.material_override.set_shader_param(color_parameter,Color(Constants.get_value("colors", new_color_scheme+"_main")))
	_back_variant.material_override.set_shader_param(color_parameter,Color(Constants.get_value("colors", new_color_scheme+"_main")))

func _set_variant(timeline_index):
	var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
	var variant_active = timeline_index == wall_index
	_front_variant.visible = variant_active
	_back_variant.visible = variant_active
	_front.visible = not variant_active
	_back.visible = not variant_active

func _on_action_status_changed(action_type, status):
	animator.action_status_changed(action_type, status)

func _on_velocity_changed(velocity, front_vector, right_vector):
	animator.velocity_changed(velocity, front_vector, right_vector)

func _on_timeline_index_changed(timeline_index):
	_set_color_scheme(color_scheme, timeline_index)
	_set_variant(timeline_index)
