extends Node

var _post_process_tool_scene = preload("res://addons/PostProcessingTool/PostProcessing_tool.tscn")

var _pp

# Glitch
var glitch :bool = false setget set_glitch

# Vignette
var vignette :bool = false setget set_vignette
var vignette_softness: float = 1.0 setget set_vignette_softness

# Chromatic Aberration
var chromatic_ab_strength: float = 1.0 setget set_chromatic_ab_strength

signal shaking_camera(amount, speed)



func _ready():
	_pp = _post_process_tool_scene.instance()
	get_parent().call_deferred("add_child", _pp)


func animate_property(property: String, initial_val, final_val, duration: float, trans_type = Tween.TRANS_LINEAR, ease_type = Tween.EASE_OUT):
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(self, property, initial_val, final_val, duration, trans_type, ease_type)
	tween.start()
	tween.connect("tween_all_completed", tween, "queue_free")


func set_glitch(value):
	_pp.glitch_show = value
	glitch = value


func set_chromatic_ab_strength(value):
	_pp.chromatc_aberration_show = value != 0
	_pp.chromatc_aberration_strength = value


func set_vignette(value):
	_pp.vignette_show = value
	vignette = value


func set_vignette_softness(value):
	_pp.vignette_softness = value
	vignette_softness = value


func shake_camera(amount: float, speed: float, duration: float):
	emit_signal("shaking_camera", amount, speed, duration)
