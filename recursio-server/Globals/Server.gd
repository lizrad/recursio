extends Node
class_name Server

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 100
var player_amount = 0


signal peer_connected(player_id)
signal peer_disconnected(player_id)
signal player_input_data_received(player_id, input_data)
signal player_ready(player_id)
signal player_timeline_pick_received(player_id, timeline_index)


func _ready():
	start_server()


func start_server():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)

	Logger.info("Server started", "connection")

	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")


func _peer_connected(player_id):
	Logger.info("Player with id: " + str(player_id) + " connected.", "connection")
	emit_signal("peer_connected", player_id)


func _peer_disconnected(player_id):
	Logger.info("Player with id: " + str(player_id) + " disconnected.", "connection")
	emit_signal("peer_disconnected", player_id)


func spawn_player_on_client(player_id, spawn_point, team_id):
	rpc_id(player_id, "spawn_player", player_id, spawn_point, team_id)


func spawn_enemy_on_client(player_id, enemy_id, enemy_position):
	rpc_id(player_id, "spawn_enemy", enemy_id, enemy_position)


func despawn_enemy_on_client(player_id, enemy_id):
	#TODO: disconnect is not handled properly yet anyway, and this causes a crash on client
	#rpc_id(player_id, "despawn_enemy", enemy_id)
	pass


func send_player_ghost_record_to_client(player_id, timeline_index, record_data: RecordData):
	record_data.timestamp = get_server_time()
	rpc_id(player_id, "receive_player_ghost_record", timeline_index, record_data.to_array())


func send_enemy_ghost_record_to_client(player_id, timeline_index, record_data: RecordData):
	record_data.timestamp = get_server_time()
	rpc_id(player_id, "receive_enemy_ghost_record", timeline_index, record_data.to_array())


func send_phase_start(player_id, phase):
	Logger.info("Sending phase start", "server")
	rpc_id(player_id, "receive_phase_start", phase)


func get_server_time():
	return OS.get_system_time_msecs()


func send_capture_point_captured(player_id, capturing_player_id, capture_point):
	Logger.info("Sending capture point captured to client", "connection")
	rpc_id(player_id, "receive_capture_point_captured", capturing_player_id, capture_point )


func send_capture_point_team_changed(player_id, capturing_player_id, capture_point):
	Logger.info("Sending capture point team changed to client", "connection")
	rpc_id(player_id, "receive_capture_point_team_changed", capturing_player_id, capture_point )


func send_capture_point_status_changed(player_id, capturing_player_id, capture_point, capture_progress):
	Logger.info("Sending capture point status changed to client", "connection")
	rpc_id(player_id, "receive_capture_point_status_changed", capturing_player_id, capture_point, capture_progress )


func send_capture_point_capture_lost(player_id, capturing_player_id, capture_point):
	Logger.info("Sending capture point capture lost to client", "connection")
	rpc_id(player_id, "receive_capture_point_capture_lost", capturing_player_id, capture_point )


# Sends the current world state (of the players room) to the player
func send_world_state(player_id, world_state):
	Logger.debug("Send world state", "server")
	rpc_unreliable_id(player_id, "receive_world_state", world_state.to_array())


# Notifies a player that a specific round will start
# Provides the server time to counteract latency
func send_round_start_to_client(player_id, round_index):
	Logger.info("Sending round start to client", "connection")
	rpc_id(player_id, "receive_round_start", round_index, get_server_time())


# Notifies a player that a specific round has ended
func send_round_end_to_client(player_id, round_index):
	Logger.info("Sending round end to client", "connection")
	rpc_id(player_id, "receive_round_end", round_index)


func send_game_result(player_id, winning_player_id):
	Logger.info("Sending game result to client", "connection")
	rpc_id(player_id, "receive_game_result", winning_player_id)


func send_player_hit(player_id, hit_player_id):
	Logger.info("Sending player hit to client", "connection")
	rpc_id(player_id, "receive_player_hit", hit_player_id)


func send_ghost_hit(player_id, hit_ghost_player_owner, hit_ghost_id):
	Logger.info("Sending ghost hit to client", "connection")
	rpc_id(player_id, "receive_ghost_hit", hit_ghost_player_owner, hit_ghost_id)


func send_ghost_pick(player_id, player_pick, enemy_pick):
	Logger.info("Sending ghost picks", "connection")
	rpc_id(player_id, "receive_timeline_picks", player_pick, enemy_pick)

func send_wall_spawn(position, rotation, wall_index, player_id):
	Logger.info("Sending wall spawn", "connection")
	rpc_id(player_id, "receive_wall_spawn", position, rotation, wall_index)
	
remote func determine_latency(player_time):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "receive_latency", player_time)


remote func fetch_server_time(player_time):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "receive_server_time", OS.get_system_time_msecs(), player_time)


remote func receive_player_input_data(input_data):
	emit_signal("player_input_data_received", get_tree().get_rpc_sender_id(), input_data)


remote func receive_player_ready():
	emit_signal("player_ready", get_tree().get_rpc_sender_id())


remote func receive_timeline_pick(timeline_index):
	emit_signal("player_timeline_pick_received", get_tree().get_rpc_sender_id(), timeline_index)






