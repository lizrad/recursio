extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909

var tickrate = 30

# For Clock Synchronization
var latency: int = 0
var server_clock: int = 0
var delta_latency: int = 0
var decimal_collector: float = 0.0
var latency_array = []

signal successfully_connected
signal spawning_enemy(enemy_id, spawn_point)
signal despawning_enemy(enemy_id)
signal spawning_player(player_id, spawn_point)
signal world_state_received(world_state)
signal own_ghost_record_received(gameplay_record)
signal enemy_ghost_record_received(enemy_id, gameplay_record)
signal round_start_received(round_index, warm_up, server_time)
signal round_end_received(round_index)
signal capture_point_captured(capturing_player_id, capture_point)
signal capture_point_team_changed(capturing_player_id, capture_point)
signal capture_point_status_changed(capturing_player_id, capture_point, capture_progress)
signal capture_point_capture_lost(capturing_player_id, capture_point)
signal game_result(winning_player_id)
signal player_hit(hit_player_id)
signal ghost_hit(hit_ghost_player_owner, hit_ghost_id)
signal ghost_picks(player_pick, enemy_picks)
signal player_action(player_id, action_type)

func _ready():
	#set_physics_process(false)
	#connect_to_server()
	pass

var timer = 0.2
func _physics_process(delta):
	if timer >0:
		timer-=delta
		if timer<=0:
			emit_signal("spawning_player", 1, Vector3(-18,0,-3), 1)
			emit_signal("round_start_received", 0, -1)
	#_run_server_clock(delta)


func connect_to_server():
	Logger.info("Connecting to server...", "connection")
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("connected_to_server", self, "_on_connection_succeeded")


func _on_connection_failed():
	Logger.info("Failed to connect to server", "connection")
	# TODO: reconnect (call create_client again and connect signals?) or shutdown...


func _on_connection_succeeded():
	Logger.info("Successfully connected", "connection")
	emit_signal("successfully_connected")
	_start_clock_synchronization()


func _start_clock_synchronization():
	#rpc_id(1, "fetch_server_time", OS.get_system_time_msecs())
	var timer = Timer.new()
	var clock_update_per_seconds = 2.0
	timer.wait_time = (1.0 / clock_update_per_seconds)
	timer.autostart = true
	timer.connect("timeout", self, "_determine_latency")
	self.add_child(timer)


func _run_server_clock(delta):
	server_clock += int(delta * 1000) + delta_latency
	delta_latency = 0
	decimal_collector += (delta * 1000) - int(delta * 1000)
	if decimal_collector >= 1.0:
		server_clock += 1
		decimal_collector -= 1.0


func _determine_latency():
	#rpc_id(1, "determine_latency", OS.get_system_time_msecs())
	pass

func get_server_time():
	return server_clock


func send_player_input_data(input_data: InputData):
	#rpc_unreliable_id(1, "receive_player_input_data", input_data.to_array())
	pass

func send_player_ready():
	#rpc_id(1, "receive_player_ready")
	pass

func send_ghost_pick(ghost_index):
	#rpc_id(1, "receive_ghost_pick",ghost_index)
	pass


remote func spawn_player(player_id, spawn_point, game_id):
	emit_signal("spawning_player", player_id, spawn_point, game_id)


remote func spawn_enemy(enemy_id, spawn_point):
	emit_signal("spawning_enemy", enemy_id, spawn_point)


remote func despawn_enemy(enemy_id):
	emit_signal("despawning_enemy", enemy_id)


remote func receive_server_time(server_time, player_time):
	latency = (OS.get_system_time_msecs() - player_time) / 2
	server_clock = server_time + latency
	set_physics_process(true)


remote func receive_latency(player_time):
	latency_array.append((OS.get_system_time_msecs() - player_time) / 2)
	var max_latency_count = 9
	if latency_array.size() == max_latency_count:
		var total_latency = 0
		latency_array.sort()
		var mid_point = latency_array[max_latency_count / 2]
		var relevant_latency_count = 0
		for i in range(latency_array.size() - 1, -1, -1):
			if latency_array[i] > (2 * mid_point) and latency_array[i] > 28:
				pass
			else:
				total_latency += latency_array[i]
				relevant_latency_count += 1
		var new_latency = total_latency / relevant_latency_count
		delta_latency = (new_latency) - latency
		latency = new_latency
		latency_array.clear()


remote func receive_own_ghost_record(gameplay_record):
	emit_signal("own_ghost_record_received", gameplay_record)


remote func receive_enemy_ghost_record(enemy_id, gameplay_record):
	emit_signal("enemy_ghost_record_received",enemy_id, gameplay_record)


# Receives the current world state of the players room
remote func receive_world_state(world_state):
	emit_signal("world_state_received", WorldState.new().from_array(world_state))


# Receives the start of a round with the server time
remote func receive_round_start(round_index, server_time):
	emit_signal("round_start_received", round_index, server_time)


# Receives the end of a round
remote func receive_round_end(round_index):
	Logger.info("Round " + str(round_index) + " has ended", "gameplay")
	emit_signal("round_end_received", round_index)


remote func receive_capture_point_captured(capturing_player_id, capture_point):
	Logger.info("Capture point captured received", "connection")
	emit_signal("capture_point_captured", capturing_player_id, capture_point)

remote func receive_capture_point_team_changed( capturing_player_id, capture_point ):
	Logger.info("Capture point team changed received", "connection")
	emit_signal("capture_point_team_changed", capturing_player_id, capture_point)

remote func receive_capture_point_status_changed( capturing_player_id, capture_point, capture_progress ):
	Logger.info("Capture point status changed received", "connection")
	emit_signal("capture_point_status_changed", capturing_player_id, capture_point, capture_progress)

remote func receive_capture_point_capture_lost( capturing_player_id, capture_point ):
	Logger.info("Capture point capture lost received", "connection")
	emit_signal("capture_point_capture_lost", capturing_player_id, capture_point)

remote func receive_game_result(winning_player_id):
	Logger.info("Game results received", "connection")
	emit_signal("game_result", winning_player_id)

remote func receive_player_hit(hit_player_id):
	Logger.info("Player hit received: " + str(hit_player_id), "connection")
	emit_signal("player_hit", hit_player_id)

remote func receive_ghost_hit(hit_ghost_player_owner, hit_ghost_id):
	Logger.info("Ghost hit received: " + str(hit_ghost_id) + " of player " + str(hit_ghost_player_owner), "connection")
	emit_signal("ghost_hit", hit_ghost_player_owner, hit_ghost_id)

remote func receive_player_action(action_player_id, action_type):
	Logger.info("Other player action received: " + str(action_type))
	emit_signal("player_action", action_player_id, action_type)

remote func receive_ghost_picks(player_pick, enemy_picks):
	Logger.info("Ghost picks received", "connection")
	emit_signal("ghost_picks",player_pick, enemy_picks)
