extends Node


var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909

signal successfully_connected
signal spawning_enemy(enemy_id,spawn_point)
signal spawning_player(spawn_point)

func _ready():
	connect_to_server()


func connect_to_server():
	print("Connecting to server...")
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("connected_to_server", self, "_on_connection_succeeded")


func _on_connection_failed():
	print("Failed to connect")


func _on_connection_succeeded():
	print("Successfully connected")
	emit_signal("successfully_connected")

remote func spawn_player(spawn_point):
	emit_signal("spawning_player", spawn_point)

remote func spawn_enemy(enemy_id,spawn_point):
	emit_signal("spawning_enemy",enemy_id,spawn_point)
