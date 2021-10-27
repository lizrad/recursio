extends Node

signal color_scheme_changed(new_color_scheme)
export(String, "player", "enemy", "player_ghost", "enemy_ghost") var color_scheme = "player"

onready var animator = get_node("Animator")
onready var _front = get_node("RootPivot/FrontPivot/Front")
onready var _middle = get_node("RootPivot/MiddlePivot/Middle")
onready var  _back = get_node("RootPivot/BackPivot/Back")
onready var _parent = get_parent()
func _ready():
	#local to scene and make unique are the biggest piles of unusable trash i have ever seen, so im brute forcing this shit get at me bruh
	_front.material_override = _front.material_override.duplicate(true)
	_middle.material_override = _middle.material_override.duplicate(true)
	_back.material_override = _back.material_override.duplicate(true)
	_set_color_scheme(color_scheme, _parent.ghost_index)
	_parent.connect("action_status_changed",self,"_on_action_status_changed")
	_parent.connect("velocity_changed",self,"_on_velocity_changed")
	_parent.connect("ghost_index_changed",self,"_on_ghost_index_changed")
	
func set_shader_param(param, value):
	pass

func _set_color_scheme(new_color_scheme:String, ghost_index):
	emit_signal("color_scheme_changed",new_color_scheme)
	_front.material_override.albedo_color = Color(Constants.get_value("colors", new_color_scheme+"_main"))
	
	var wall_index = Constants.get_value("ghosts","wall_placing_ghost_index")
	var accent_type = "primary" if wall_index != ghost_index else "secondary"
	_middle.material_override.albedo_color = Color(Constants.get_value("colors", new_color_scheme+"_"+accent_type+"_accent"))
	
	_back.material_override.albedo_color = Color(Constants.get_value("colors", new_color_scheme+"_main"))

func _on_action_status_changed(action_type, status):
	animator.action_status_changed(action_type, status)

func _on_velocity_changed(velocity, front_vector, right_vector):
	animator.velocity_changed(velocity, front_vector, right_vector)

func _on_ghost_index_changed(ghost_index):
	_set_color_scheme(color_scheme, ghost_index)
