extends Node

onready var _latency_text = get_node("LatencyText")
onready var _fps_text = get_node("FPSText")


func _physics_process(_delta):
	_latency_text.text = "Latency: " + str(Server.latency) + "ms"
	_fps_text.text = "FPS: " + str(Engine.get_frames_per_second())
