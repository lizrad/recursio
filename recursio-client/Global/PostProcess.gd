extends Node

var _post_process_tool_scene = preload("res://Post Processing tool/PostProcessing_tool.tscn")

var _pp

#glitch
var glitch :bool = false setget set_glitch, get_glitch
# vignette
var vignette :bool = false setget set_vignette, get_vignette
var vignette_softness: float = 1.0 setget set_vignette_softness, get_vignette_softness


func _ready():
	_pp = _post_process_tool_scene.instance()
	get_parent().call_deferred("add_child", _pp)


func set_glitch(value):
	_pp.show_glitch = glitch
	glitch = value


func get_glitch():
	return glitch


func set_vignette(value):
	_pp.show_vignette = value
	vignette = value


func get_vignette():
	return glitch


func set_vignette_softness(value):
	_pp.vignette_softness = value
	vignette_softness = value


func  get_vignette_softness():
	return vignette_softness
