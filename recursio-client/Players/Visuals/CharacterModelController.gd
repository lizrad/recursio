extends Node

export(String, "player", "enemy", "player_ghost", "enemy_ghost") var color_scheme = "player"

onready var animator = get_node("Animator")
onready var front = get_node("RootPivot/FrontPivot/Front")
onready var middle = get_node("RootPivot/MiddlePivot/Middle")
onready var  back = get_node("RootPivot/BackPivot/Back")

func _ready():
	set_color_scheme(color_scheme)

func set_shader_param(param, value):
	pass

func set_color_scheme(new_color_scheme:String):
	front.material_override.albedo_color = Color(Constants.get_value("colors", new_color_scheme+"_main"))
	middle.material_override.albedo_color = Color(Constants.get_value("colors", new_color_scheme+"_primary_accent"))
	back.material_override.albedo_color = Color(Constants.get_value("colors", new_color_scheme+"_main"))
	color_scheme = new_color_scheme

func on_action_status_changed(action_type, status):
	animator.action_status_changed(action_type, status)

func on_velocity_changed(velocity, front_vector, right_vector):
	animator.velocity_changed(velocity, front_vector, right_vector)
