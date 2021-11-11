extends Node

var network = NetworkedMultiplayerENet.new()
var use_local_server = true
var remote_server_ip = "37.252.189.118"
var local_server_ip = "127.0.0.1"
var port = 1909

var tickrate = 30

# For Clock Synchronization
var latency: int = 0
var server_clock: int = 0
var delta_latency: int = 0
var decimal_collector: float = 0.0
var latency_array = []

signal successfully_connected()
signal spawning_enemy(enemy_id, spawn_point)
signal despawning_enemy(enemy_id)
signal spawning_player(player_id, spawn_point)
signal world_state_received(world_state)
signal player_ghost_record_received(timeline_index, gameplay_record)
signal enemy_ghost_record_received(timeline_index, gameplay_record)
signal capture_point_captured(capturing_player_id, capture_point)
signal capture_point_team_changed(capturing_player_id, capture_point)
signal capture_point_status_changed(capturing_player_id, capture_point, capture_progress)
signal capture_point_capture_lost(capturing_player_id, capture_point)
signal game_result(winning_player_id)
signal player_hit(hit_player_id)
signal ghost_hit(hit_ghost_player_owner, hit_ghost_id)
signal timeline_picks(player_pick, enemy_picks)
signal wall_spawn (position, rotation, wall_index)

signal phase_switch_received(round_index,next_phase, switch_time)
signal game_start_received(start_time)


func _ready():
	set_physics_process(false)
	connect_to_server()


func _physics_process(delta):
	_run_server_clock(delta)


func connect_to_server():
	Logger.info("Connecting to server...", "connection")
	var ip = local_server_ip if use_local_server else remote_server_ip
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	var _error = get_tree().connect("connection_failed", self, "_on_connection_failed")
	_error = get_tree().connect("connected_to_server", self, "_on_connection_succeeded")

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		Logger.info("Disconnecting from server...", "connection")
		network.close_connection()
		get_tree().quit() # default behavior

func _on_connection_failed():
	Logger.info("Failed to connect to server", "connection")
	# TODO: reconnect (call create_client again and connect signals?) or shutdown...


func _on_connection_succeeded():
	Logger.info("Successfully connected", "connection")
	_start_clock_synchronization()
	emit_signal("successfully_connected")


func _start_clock_synchronization():
	Logger.debug("Start clock synchronization", "server")
	rpc_id(1, "fetch_server_time", OS.get_system_time_msecs())
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
	Logger.debug("Determine latency", "server")
	rpc_id(1, "determine_latency", OS.get_system_time_msecs())


func get_server_time():
	return server_clock


func send_player_input_data(input_data: InputData):
	Logger.debug("Send player input data", "server")
	rpc_unreliable_id(1, "receive_player_input_data", input_data.to_array())


func send_player_ready():
	Logger.debug("Send player ready", "server")
	rpc_id(1, "receive_player_ready")


func send_timeline_pick(timeline_index):
	Logger.debug("Send player timeline pick", "server")
	rpc_id(1, "receive_timeline_pick",timeline_index)


remote func spawn_player(player_id, spawn_point, team_id):
	Logger.debug("Receive spawn player", "server")
	emit_signal("spawning_player", player_id, spawn_point, team_id)


remote func spawn_enemy(enemy_id, spawn_point):
	Logger.debug("Receive spawn enemy", "server")
	emit_signal("spawning_enemy", enemy_id, spawn_point)


remote func despawn_enemy():
	Logger.debug("Receive despawn enemy", "server")
	emit_signal("despawning_enemy")


remote func receive_server_time(server_time, player_time):
	Logger.debug("Receive server time", "server")
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
	Logger.debug("Receive latency (" + str((OS.get_system_time_msecs() - player_time) / 2) + ")", "server")


remote func receive_player_ghost_record(timeline_index, record_data):
	Logger.debug("Receive player ghost record", "server")
	emit_signal("player_ghost_record_received", timeline_index, RecordData.new().from_array(record_data))


remote func receive_enemy_ghost_record(timeline_index, record_data):
	Logger.debug("Receive enemy ghost record", "server")
	emit_signal("enemy_ghost_record_received", timeline_index, RecordData.new().from_array(record_data))


# Receives the current world state of the players room
remote func receive_world_state(world_state):
	Logger.debug("Receive world starte", "server")
	emit_signal("world_state_received", WorldState.new().from_array(world_state))


remote func receive_game_start(start_time):
	Logger.info("Receive game start", "server")
	emit_signal("game_start_received", start_time)
	
remote func receive_phase_switch(round_index, next_phase, switch_time):
	Logger.info("Receive phase switch to " + str(next_phase), "server")
	emit_signal("phase_switch_received", round_index, next_phase, switch_time)


remote func receive_capture_point_captured(capturing_player_id, capture_point):
	Logger.debug("Capture point captured received", "server")
	emit_signal("capture_point_captured", capturing_player_id, capture_point)


remote func receive_capture_point_team_changed( capturing_player_id, capture_point ):
	Logger.debug("Capture point team changed received", "server")
	emit_signal("capture_point_team_changed", capturing_player_id, capture_point)


remote func receive_capture_point_status_changed( capturing_player_id, capture_point, capture_progress ):
	Logger.debug("Capture point status changed received", "server")
	emit_signal("capture_point_status_changed", capturing_player_id, capture_point, capture_progress)


remote func receive_capture_point_capture_lost( capturing_player_id, capture_point ):
	Logger.debug("Capture point capture lost received", "server")
	emit_signal("capture_point_capture_lost", capturing_player_id, capture_point)


remote func receive_game_result(winning_player_id):
	Logger.debug("Game results received", "server")
	emit_signal("game_result", winning_player_id)


remote func receive_player_hit(hit_player_id):
	Logger.debug("Player hit received: " + str(hit_player_id), "server")
	emit_signal("player_hit", hit_player_id)


remote func receive_ghost_hit(hit_ghost_player_owner, hit_ghost_id):
	Logger.debug("Ghost hit received: " + str(hit_ghost_id) + " of player " + str(hit_ghost_player_owner), "server")
	emit_signal("ghost_hit", hit_ghost_player_owner, hit_ghost_id)


remote func receive_player_action(action_player_id, action_type):
	Logger.debug("Other player action received: " + str(action_type), "server")
	emit_signal("player_action", action_player_id, action_type)


remote func receive_timeline_picks(player_pick, enemy_pick):
	Logger.debug("Ghost picks received", "server")
	emit_signal("timeline_picks",player_pick, enemy_pick)


remote func receive_wall_spawn(position, rotation, wall_index):
	Logger.info("Wall spawn received", "server")
	emit_signal("wall_spawn",position, rotation, wall_index)
