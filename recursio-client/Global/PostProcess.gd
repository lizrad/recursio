extends Node

var _post_process_tool_scene = preload("res://addons/PostProcessingTool/PostProcessing_tool.tscn")

var _pp

#glitch
var glitch :bool = false setget set_glitch, get_glitch
# vignette
var vignette :bool = false setget set_vignette, get_vignette
var vignette_softness: float = 1.0 setget set_vignette_softness, get_vignette_softness


func _ready():
	_pp = _post_process_tool_scene.instance()
	get_parent().call_deferred("add_child", _pp)


func animate_property(property: NodePath, initial_val, final_val, duration: float, trans_type = Tween.TRANS_LINEAR, ease_type = Tween.EASE_OUT):
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(self, property, initial_val, final_val, duration, trans_type, ease_type)
	tween.start()
	tween.connect("tween_all_completed", tween, "queue_free")


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
