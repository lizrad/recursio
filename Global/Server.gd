extends Node


var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909

signal successfully_connected
signal spawning_enemy(enemy_id,spawn_point)
signal despawning_enemy(enemy_id)
signal spawning_player(player_id, spawn_point)
signal world_state_received(world_state)

func _ready():
	connect_to_server()


func connect_to_server():
	print("Connecting to server...")
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("connected_to_server", self, "_on_connection_succeeded")


func _on_connection_failed(err):
	print("Failed to connect with error: "+err)


func _on_connection_succeeded():
	print("Successfully connected")
	emit_signal("successfully_connected")

func get_server_time():
	#TODO: add clock synchro here
	return OS.get_system_time_msecs()

func send_player_state(player_state):
	rpc_unreliable_id(1, "receive_player_state",player_state)

remote func spawn_player(player_id, spawn_point):
	emit_signal("spawning_player",player_id, spawn_point)

remote func spawn_enemy(enemy_id,spawn_point):
	emit_signal("spawning_enemy",enemy_id,spawn_point)

remote func despawn_enemy(enemy_id):
	emit_signal("despawning_enemy",enemy_id)

remote func receive_world_state(world_state):
	emit_signal("world_state_received",world_state);
