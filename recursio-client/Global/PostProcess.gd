extends Node

var _post_process_tool_scene = preload("res://addons/PostProcessingTool/PostProcessing_tool.tscn")

var _pp
var _tween

#glitch
var glitch :bool = false setget set_glitch, get_glitch
# vignette
var vignette :bool = false setget set_vignette, get_vignette
var vignette_softness: float = 1.0 setget set_vignette_softness, get_vignette_softness


func _ready():
	_tween = Tween.new()
	add_child(_tween)
	_pp = _post_process_tool_scene.instance()
	get_parent().call_deferred("add_child", _pp)


func remove_animation(property: NodePath):
	_tween.remove(self, property)


func animate_property(property: NodePath, initial_val, final_val, duration: float, trans_type = Tween.TRANS_LINEAR, ease_type = Tween.EASE_OUT):
	remove_animation(property)
	_tween.interpolate_property(self, property, initial_val, final_val, duration, trans_type, ease_type)
	_tween.start()

func set_glitch(value):
	_pp.glitch_show = value
	glitch = value


func get_glitch():
	return glitch


func set_vignette(value):
	_pp.vignette_show = value
	vignette = value


func get_vignette():
	return glitch


func set_vignette_softness(value):
	_pp.vignette_softness = value
	vignette_softness = value


func  get_vignette_softness():
	return vignette_softness
