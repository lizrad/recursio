extends Node


var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909

var tickrate = 30

# Simulated latency in miliseconds
export(float) var latency = 0.0
# Simulated package loss in percentage
export(float) var package_loss = 00.0
var latency_delta : float = 0.0
var last_time_data_sent : float = 0.0

signal successfully_connected
signal spawning_enemy(enemy_id,spawn_point)
signal despawning_enemy(enemy_id)
signal spawning_player(player_id, spawn_point)
signal world_state_received(world_state)

func _ready():
	connect_to_server()
	last_time_data_sent = OS.get_system_time_msecs()


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
	# DEBUG: Network simulation code
	var time = OS.get_system_time_msecs()
	latency_delta += time - last_time_data_sent
	last_time_data_sent = time
	if latency_delta < latency:
		return
	latency_delta -= latency
	if package_loss / 100.0 >= randf():
		return
	
	rpc_unreliable_id(1, "receive_player_state",player_state)

remote func spawn_player(player_id, spawn_point):
	emit_signal("spawning_player",player_id, spawn_point)

remote func spawn_enemy(enemy_id,spawn_point):
	emit_signal("spawning_enemy",enemy_id,spawn_point)

remote func despawn_enemy(enemy_id):
	emit_signal("despawning_enemy",enemy_id)

remote func receive_world_state(world_state):
	emit_signal("world_state_received", world_state);
