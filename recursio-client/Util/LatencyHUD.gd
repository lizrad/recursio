extends Node

onready var _latency_text = get_node("LatencyText")


func _process(delta):
	_latency_text.text = "Latency: " + str(Server.latency) + "ms"
